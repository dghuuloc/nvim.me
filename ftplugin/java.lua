-- :MasonInstall jdtls java-debug-adapter java-test
vim.bo.shiftwidth = 4; vim.bo.tabstop = 4; vim.bo.softtabstop = 4

local api = vim.api
local P   = require("util.platform")

-- ── Root dir ──────────────────────────────────────────────────────────────────
local root_dir = vim.fs.root(0, {
  "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", ".git",
}) or assert(vim.uv.cwd(), "Could not determine working directory")

-- ── Build tool ────────────────────────────────────────────────────────────────
local function build_tool()
  if vim.uv.fs_stat(root_dir .. "/pom.xml") then return "maven" end
  if vim.uv.fs_stat(root_dir .. "/build.gradle") or vim.uv.fs_stat(root_dir .. "/build.gradle.kts") then
    return "gradle"
  end
  return "unknown"
end

local function mvn_cmd()
  if P.is_win then
    for _,w in ipairs({root_dir.."/mvnw.cmd",root_dir.."/mvnw"}) do
      if vim.uv.fs_stat(w) then return P.path(w) end
    end
  else
    local w=root_dir.."/mvnw"
    if vim.uv.fs_stat(w) then vim.fn.system("chmod +x "..vim.fn.shellescape(w)); return w end
  end
  return vim.fn.executable("mvn")==1 and "mvn" or nil
end

local function gradle_cmd()
  if P.is_win then
    for _,w in ipairs({root_dir.."/gradlew.bat",root_dir.."/gradlew"}) do
      if vim.uv.fs_stat(w) then return P.path(w) end
    end
  else
    local w=root_dir.."/gradlew"
    if vim.uv.fs_stat(w) then vim.fn.system("chmod +x "..vim.fn.shellescape(w)); return w end
  end
  return vim.fn.executable("gradle")==1 and "gradle" or nil
end

-- ── Collect java-debug + vscode-java-test jars ────────────────────────────────
local bundles = {}
-- java-debug
local debug_jar = vim.fn.glob(P.join(P.mason_dir,"packages",
    "java-debug-adapter","extension","server","com.microsoft.java.debug.plugin-*.jar"))
if debug_jar ~="" then
    table.insert(bundles, (P.path(debug_jar)))
end
-- vscode-java-test
local java_test_bundles = vim.split(
    vim.fn.glob(P.join(P.mason_dir,"packages","java-test","extension","server","*.jar")),
        "\n",
    { trimempty = true }
)
local excluded = {
    "com.microsoft.java.test.runner-jar-with-dependencies.jar",
    "jacocoagent.jar",
}
for _, java_test_jar in ipairs(java_test_bundles) do
    local fname = vim.fn.fnamemodify(java_test_jar, ":t")
    if not vim.tbl_contains(excluded, fname) then
        table.insert(bundles, java_test_jar)
    end
end

-- fernflower decompiler
-- local decompiler = vim.fn.glob(P.data_dir .. "/dev/dgileadi/vscode-java-decompiler/server/*.jar")
-- for _, jar in ipairs(vim.split(decompiler, "\n")) do
--     if jar ~= "" then table.insert(bundles, jar) end
-- end

-- ── JDK command ────────────────────────────────────────────────────────────
local jdk = P.find_java_home()
if not jdk then
  vim.notify("No JDK found", vim.log.levels.ERROR,{title="Java LSP"}); return
end
local java_exe = P.join(jdk,"bin",P.is_win and "java.exe" or "java")
if not vim.uv.fs_stat(java_exe) then
  vim.notify("java not found: " .. java_exe,vim.log.levels.ERROR, { title = "Java LSP" }); return
end

-- ── Build jdtls command ───────────────────────────────────────────────────────
local cmd = {
  java_exe,
  "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  "-Dosgi.bundles.defaultStartLevel=4",
  "-Declipse.product=org.eclipse.jdt.ls.core.product",
  "-Dlog.protocol=true",
  "-Dlog.level=ALL",
  "-XX:+AlwaysPreTouch",
  "-XX:+UseStringDeduplication",
  "-Xmx4g",
  -- "-XX:+UseG1GC",
  -- "-XX:GCTimeRatio=4",
  -- "-XX:AdaptiveSizePolicyWeight=90",
  -- "-Dsun.zip.disableMemoryMapping=true",
  "--add-modules=ALL-SYSTEM",
  "--add-opens", "java.base/java.util=ALL-UNNAMED",
  "--add-opens", "java.base/java.lang=ALL-UNNAMED",
}

-- Lombok: inject as javaagent if present
local lombok = P.join(P.mason_dir,"packages","jdtls","lombok.jar")
if vim.uv.fs_stat(lombok) then
    table.insert(cmd,2,"-javaagent:"..lombok)
    table.insert(cmd,3,"-Xbootclasspath/a:"..lombok)
end

-- Find jdtls launcher jar
local platform_cfg = P.is_win and "config_win" or (P.is_mac and "config_mac" or "config_linux")

local local_launcher = vim.fn.glob(
  P.join(P.mason_dir,"packages","jdtls","plugins","org.eclipse.equinox.launcher_*.jar")
)
if vim.uv.fs_stat(local_launcher) then
  vim.list_extend(cmd,{
    "-jar", local_launcher,
    "-configuration", P.join(P.mason_dir,"packages","jdtls",platform_cfg),
  })
else
  vim.notify("jdtls not found\n" ..
    "Or: :MasonInstall jdtls", vim.log.levels.WARN, { title = "Java LSP" }); return
end

-- Per-project workspace cache
local ws = P.join(P.cache_dir,"jdtls","projects",vim.fn.sha256(root_dir))
P.mkdir(ws)
vim.list_extend(cmd, { "-data", ws })

-- ── Start jdtls ───────────────────────────────────────────────────────────────
---@type any
local ok_jdtls,jdtls = pcall(require,"jdtls")
if not ok_jdtls then
  vim.notify("nvim-jdtls not installed\n"..
    "Run plugin install and restart.", vim.log.levels.WARN); return
end

-- ── Extended capabilities ─────────────────────────────────────────────────
---@diagnostic disable-next-line: undefined-field
local extCaps = jdtls.extendedClientCapabilities
  extCaps.onCompletionItemSelectedCommand      = "editor.action.triggerParameterHints"
  extCaps.resolveAdditionalTextEditsSupport    = true
  extCaps.classFileContentsSupport             = true
  extCaps.generateToStringPromptSupport        = true
  extCaps.hashCodeEqualsPromptSupport          = true
  extCaps.advancedOrganizeImportsSupport       = true
  extCaps.generateConstructorsPromptSupport    = true
  extCaps.generateDelegateMethodsPromptSupport = true
  extCaps.moveRefactoringSupport               = true
  extCaps.overrideMethodsPromptSupport         = true
  extCaps.inferSelectionSupport = { "extractMethod", "extractVariable", "extractField" }

-- ── on_attach: all Java keymaps ───────────────────────────────────────────────
---@diagnostic disable: undefined-field
local function on_attach(client, bufnr)
  local opts = { silent = true, buffer = bufnr }
  local set  = vim.keymap.set

  -- ── Notify: jdtls attached (fires before indexing finishes) ─────────────
  vim.notify(
    "jdtls attached — indexing " .. vim.fn.fnamemodify(root_dir, ":t") .. " …",
    vim.log.levels.INFO,
    { title = "Java LSP", timeout = 2000 })
  vim.g.java_lsp_status = " Indexing…"
  vim.cmd.redrawstatus()

  -- ── Register DAP adapter via setup_dap (replaces old execute_command) ───
  -- Must be called after jdtls attaches. hotcodereplace reloads changed
  -- classes during a debug session without restarting the JVM.
  require("jdtls").setup_dap({ hotcodereplace = "auto" })

  -- ── Build helpers ────────────────────────────────────────────────────────
  local function  save_if_dirty()
    if vim.bo[bufnr].modified then vim.cmd("w") end
  end

  local function run_build(goals, notify_title)
    local tool = build_tool()
    local exe  = tool == "maven" and mvn_cmd() or gradle_cmd()
    if not exe then vim.notify("No build tool found", vim.log.levels.WARN); return end
    local args = vim.split(goals, " ", { plain = true, trimempty = true })
    table.insert(args, 1, exe)
    vim.g.java_build_status = " building..."
    vim.fn.jobstart(args, {
      cwd     = root_dir,
      on_exit = function(_, code)
        vim.schedule(function()
          local ok2 = code == 0
          vim.g.java_build_status = ok2 and " " or " FAILED"
          vim.notify(
            (notify_title or "Build") .. " " .. (ok2 and "✔  succeeded" or "✗ FAILED"),
            ok2 and vim.log.levels.INFO or vim.log.levels.ERROR,
            { title = "Java" }
          )
        end)
      end,
    })
  end

  -- ── Imports ──────────────────────────────────────────────
  set("n", "<A-o>", jdtls.organize_imports, opts)

  -- ── Refactoring  (<leader>jr…) ─────────────────────────────────────────
  set("n", "<leader>jrv", jdtls.extract_variable_all, opts)
  set("v", "<leader>jrv", "<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>", opts)
  set("v", "<leader>jrm", "<ESC><CMD>lua require('jdtls').extract_method(true)<CR>", opts)
  set("n", "<leader>jrc", jdtls.extract_constant, opts)
  set("n", "<leader>jri", jdtls.organize_imports, opts)

  -- Move class / safe delete / change signature
  local function ca(kind) return function()
    vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} }, apply = false })
  end end
  set("n", "<leader>jrM", ca("refactor.move"),       opts) -- F6 equivalent
  set("n", "<leader>jrD", ca("refactor.safeDelete"),  opts) -- Alt+Delete
  set("n", "<leader>jrS", ca("refactor.rewrite"),     opts) -- change signature

  -- Rename — native vim.ui.input (inc-rename.nvim is not installed)
  set("n", "<F2>", function()
    local old = vim.fn.expand("<cword>")
    vim.ui.input({ prompt = "Rename: ", default = old }, function(new)
      if new and new ~= "" and new ~= old then
        vim.lsp.buf.rename(new)
      end
    end)
  end, vim.tbl_extend("force", opts, { desc = "rename symbol (F2)" }))

  -- ── Code generation  (<leader>jc…) ────────────────────────────────────
  local function gen(kind)
      return function()
          local ctx = { only = { kind } }
          ---@cast ctx any
          vim.lsp.buf.code_action({ context = ctx, apply = true })
      end
  end
  set("n", "<leader>jco", gen("source.generate.toStringMethod"),        opts)
  set("n", "<leader>jce", gen("source.generate.hashCodeEqualsMethod"),  opts)
  set("n", "<leader>jcc", gen("source.generate.constructor"),           opts)
  set("n", "<leader>jcd", gen("source.generate.delegateMethods"),       opts)
  set("n", "<leader>jca", gen("source.generate.accessors"),             opts)
  set("n", "<leader>jcg", function() jdtls.generate() end,              opts)

  -- ── Tests  (<leader>jt…) ──────────────────────────────────────────────
  local conf = {
    stepFilters = {
      skipClasses = { "$JDK","junit.*","org.junit.*","sun.*" },
      skipSynthetics = true,
    },
    vmArgs = "-ea --add-modules jdk.incubator.vector",
  }
  set("n", "<leader>jtc", function()
    save_if_dirty(); jdtls.test_class({ config_overrides = conf }) end, opts)
  set("n", "<leader>jtn", function()
    save_if_dirty(); jdtls.test_nearest_method({ config_overrides = conf }) end, opts)
  set("n", "<leader>jtd", function()
    save_if_dirty(); require("jdtls.dap").pick_test() end, opts)
  set("n", "<leader>jtl", function() require("dap").run_last() end, opts)

  -- ── Build (<leader>jb…) ───────────────────────────────────────────────────
  set("n", "<leader>jbb", function()
    run_build(build_tool() == "maven" and "clean package -DskipTests" or "clean build -x test", "Build") end, opts)
  set("n", "<leader>jbt", function()
    run_build(build_tool() == "maven" and "clean verify" or "clean test","Test") end, opts)
  set("n", "<leader>jbc", function()
    run_build("clean","Clean") end, opts)
  set("n","<leader>jbi",function()
    run_build(build_tool() == "maven" and "clean install -DskipTests" or "clean build -x test publishToMavenLocal","Install") end,opts)
  set("n","<leader>jbr",function()
    local goals = build_tool() == "maven" and {
      "clean package -DskipTests",
      "clean verify",
      "clean install -DskipTests",
      "clean test",
      "clean",
      "dependency:tree",
      "dependency:analyze",
      "spring-boot:run",
      "spring-boot:build-image",
    } or {
      "clean build -x test",
      "clean test",
      "clean build",
      "dependencies",
      "bootRun",
      "bootBuildImage",
    }
    vim.ui.select(goals,{prompt=" Maven/Gradle goal:"},function(c)
      if c then run_build(c,"Build") end end)
  end,opts)

  -- ── Spring Boot (<leader>js…) ─────────────────────────────────────────────
  set("n", "<leader>jsr", function()
    save_if_dirty()
    run_build(build_tool() == "maven" and "spring-boot:run" or "bootRun","Spring Boot")
  end, opts)

  set("n", "<leader>jsR", function()
    save_if_dirty()
    local jvm = "-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=*:5005"
    run_build(
      build_tool() == "maven"
        and ("spring-boot:run -Dspring-boot.run.jvmArguments=" .. vim.fn.shellescape(jvm))
        or  "bootRun --debug-jvm",
      "Spring Boot (debug)")

    vim.notify(
      "Waiting for JVM on :5005 …\nSet breakpoints now, then press <F5> to continue.",
      vim.log.levels.INFO, { title = "Spring Boot", timeout = 10000 })

    local attempts = 0
    local function try_attach()
      attempts = attempts + 1
      local tcp = vim.uv.new_tcp()
      if not tcp then
          vim.notify("Failed to create TCP handled", vim.log.levels.ERROR, { title = "Spring Boot" })
          return
      end
      tcp:connect("127.0.0.1", 5005, function(err)
        if not err then
          tcp:close()
          vim.schedule(function()
            vim.notify(
              "JVM ready — attaching debugger…",
              vim.log.levels.INFO, { title = "Spring Boot" })
            -- require("dap").run({
            --   type     = "java",
            --   name     = "Attach Spring Boot",
            --   request  = "attach",
            --   hostName = "localhost",
            --   port     = 5005,
            --   timeout  = 30000,
            -- })
            require("dap").continue()
          end)
        elseif attempts < 40 then
          tcp:close()
          vim.defer_fn(try_attach, 500)
        else
          tcp:close()
          vim.schedule(function()
            vim.notify(
              "Timed out waiting for JVM on :5005",
              vim.log.levels.ERROR, { title = "Spring Boot" })
          end)
        end
      end)
    end
    vim.defer_fn(try_attach, 2000)
  end, opts)

  -- ── Spring Boot (<leader>js…) ─────────────────────────────────────────────
  set("n", "<leader>jsd", function()
    -- Trigger Spring Boot DevTools live reload via actuator
    local url = "http://localhost:8080/actuator/restart"
    vim.fn.jobstart({ "curl", "-s", "-X", "POST", url }, {
      on_exit = function(_, code)
        vim.schedule(function()
          vim.notify(code == 0 and "Spring: restarted" or "Spring actuator not available",
            code == 0 and vim.log.levels.INFO or vim.log.levels.WARN, { title = "Spring Boot" })
        end)
    end })
  end, opts)

  set("n", "<leader>jsc", function()
      for _, f in ipairs({
        root_dir.."/src/main/resources/application.yml",
        root_dir.."/src/main/resources/application.yaml",
        root_dir.."/src/main/resources/application.properties",
        root_dir.."/src/main/resources/bootstrap.yml",
      }) do if vim.uv.fs_stat(f) then vim.cmd.edit(f); return end end
      vim.notify("No application config found", vim.log.levels.WARN)
  end, opts)

  -- ── Diagnostics  ──────────────────────────────────────────────────────────
  set("n", "<leader>jxe", function()
    vim.diagnostic.setqflist({ title = "Java Errors",
      severity = vim.diagnostic.severity.ERROR, open = true })
  end, opts)
  set("n", "<leader>jxw", function()
    vim.diagnostic.setqflist({ title = "Java Warnings",
      severity = vim.diagnostic.severity.WARN, open = true })
  end, opts)

  -- ── Alternate file ────────────────────────────────────────────────────────
  -- :A → alternate file (test ↔ production)
  api.nvim_buf_create_user_command(bufnr, "A", function()
    require("jdtls.tests").goto_subjects()
  end, { desc = "goto alternate (test ↔ src)" })

  api.nvim_buf_create_user_command(bufnr, "AS", function()
    require("jdtls.tests").goto_subjects()
  end,{ desc = "goto subjects (all alternates)" })

  -- ── Status ────────────────────────────────────────────────────────────────
  vim.g.java_build_status = build_tool() == "maven" and " mvn" or
                            build_tool() == "gradle" and "gradle" or ""
end

-- ── Start jdtls ───────────────────────────────────────────────────────────────
---@diagnostic disable-next-line: undefined-field
local capabilities = vim.tbl_deep_extend("force",
  vim.lsp.protocol.make_client_capabilities(),
  {
    workspace = {
      didChangeWatchedFiles = { dynamicRegistration = true },
    },
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport      = true,   -- required: jdtls returns full JDK completions
          resolveSupport      = {
            properties = { "documentation", "detail", "additionalTextEdits" },
          },
          documentationFormat = { "markdown", "plaintext" },
          deprecatedSupport   = true,
          preselectSupport    = true,
        },
      },
      foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
    },
  })

-- ── Start jdtls ───────────────────────────────────────────────────────────────
jdtls.start_or_attach({
    cmd       = cmd,
    root_dir  = root_dir,
    on_attach = on_attach,
    capabilities = capabilities,   -- this is what makes String/int/List/Map appear
    init_options = {
        bundles                    = bundles,
        extendedClientCapabilities = extCaps,
    },
    handlers = {
      ["language/status"] = function(_, result)
        if not result or not result.message then return end
        local msg = result.message

        if msg:find("Starting") then
          vim.g.java_lsp_status = " Starting…"

        elseif msg:find("Indexing") then
          local pct = msg:match("(%d+)%%")
          vim.g.java_lsp_status = pct
            and (" Indexing " .. pct .. "%%")
            or  " Indexing…"
          vim.cmd.redrawstatus()

        elseif msg:find("ServiceReady") or msg:find("Ready") then
          vim.g.java_lsp_status = " Ready"
          vim.cmd.redrawstatus()
          vim.notify(
            "jdtls is ready — " .. vim.fn.fnamemodify(root_dir, ":t"),
            vim.log.levels.INFO,
            { title = "Java LSP", timeout = 3000 })

        elseif msg:find("[Ee]rror") then
          vim.g.java_lsp_status = " Error"
          vim.cmd.redrawstatus()
          vim.notify(
            "jdtls error: " .. msg,
            vim.log.levels.ERROR,
            { title = "Java LSP" })
        end
      end,

      ["$/progress"] = function(_, result)
        if not result then return end
        local value = result.value or {}

        if value.kind == "begin" then
          vim.g.java_lsp_status = " " .. (value.title or "Working…")
          vim.cmd.redrawstatus()

        elseif value.kind == "report" then
          local pct = value.percentage
          local msg = value.message or value.title or ""
          vim.g.java_lsp_status = pct
            and string.format(" %s %d%%", msg ~= "" and msg or "Indexing", pct)
            or  (" " .. (msg ~= "" and msg or "Working…"))
          vim.cmd.redrawstatus()

        elseif value.kind == "end" then
          vim.defer_fn(function()
            if vim.g.java_lsp_status ~= " Ready" then
              vim.g.java_lsp_status = " Ready"
              vim.cmd.redrawstatus()
            end
          end, 500)
        end
      end,
    },
    settings = (vim.lsp.config["jdtls"] or {}).settings or {},
})

-- ── Start Java Dap ───────────────────────────────────────────────────────────────
local ok_dap, dap = pcall(require, "dap"); if not ok_dap then return end

if not ok_dap then return end

dap.configurations.java = {
  -- ── Attach to running JVM ───────────────────────────────────────────
  {
    name     = " Attach (5005)",
    type     = "java",
    request  = "attach",
    hostName = "localhost",
    port     = 5005,
    timeout  = 30000,
  },
  -- Attach with a custom port (ports on lauch)
  {
    name     = " Attach (custom port)",
    type     = "java",
    request  = "attach",
    hostName = "localhost",
    port     = function()
      return tonumber(vim.fn.input({ prompt = "Debug port: ", default = "5005" })) or 5005
    end,
    timeout  = 30000,
  },
  -- ── Spring Boot ─────────────────────────────────────────────────────
  -- Used b <leader> jsR (auto-attach via port polling)
  {
    name     = "🍃 Spring Boot: attach (5005)",
    type     = "java",
    request  = "attach",
    hostName = "localhost",
    port     = 5005,
    projectName = function()
      return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    end,
  },
  -- Spring Boot running inside Dcoker
  {
    name     = "🍃 Spring Boot: attach (Docker)",
    type     = "java",
    request  = "attach",
    hostName = function()
      return vim.fn.input({ prompt = "Docker host: ", default = "localhost" })
    end,
    port     = function()
      return tonumber(vim.fn.input({ prompt = "Port: ", default = "5005" })) or 5005
    end,
    timeout  = 30000,
  },
  -- ── Generic Remote JVM ──────────────────────────────────────────────────────────
  {
    name     = "☁  Remote (custom host:port)",
    type     = "java",
    request  = "attach",
    hostName = function()
      return vim.fn.input({ prompt = "Remote host: ", default = "localhost"})
    end,
    port     = function()
      return tonumber(vim.fn.input({ prompt = "Remote port: ", default = "5005" })) or 5005
    end,
    timeout  = 30000,
  },
  -- ── Kubernetes port-forward ──────────────────────────────────────────
  -- run kubectl port-forward pod/,nam> 5005:5005 first
  {
    name     = "⎈  Kubernetes (port-forward 5005)",
    type     = "java",
    request  = "attach",
    hostName = "127.0.0.1",
    port     = 5005,
    timeout  = 30000,
  },
}


