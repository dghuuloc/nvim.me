-- :MasonInstall jdtls java-debug-adapter java-test

vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.softtabstop = 4

local api = vim.api
local P = require("util.platform")

local root_dir = vim.fs.root(0, {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    ".git",
}) or assert(vim.uv.cwd(), "Could not determine working directory")

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
            if vim.uv.fs_stat(w) then return P.path(w) end end
    else
        local w=root_dir.."/mvnw"
        if vim.uv.fs_stat(w) then vim.fn.system("chmod +x "..vim.fn.shellescape(w)); return w end
    end
    return vim.fn.executable("mvn")==1 and "mvn" or nil
end

local function gradle_cmd()
    if P.is_win then
        for _,w in ipairs({root_dir.."/gradlew.bat",root_dir.."/gradlew"}) do
            if vim.uv.fs_stat(w) then return P.path(w) end end
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
    vim.notify("No JDK found. Set $JDK21 or $JAVA_HOME.\nwinget install EclipseAdoptium.Temurin.21.JDK",
    vim.log.levels.ERROR,{title="Java LSP"});
    return
end

local java_exe = P.join(jdk,"bin",P.is_win and "java.exe" or "java")
if not vim.uv.fs_stat(java_exe) then
    vim.notify("java not found: "..java_exe,vim.log.levels.ERROR,{title="Java LSP"});
    return
end

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

local platform_cfg = P.is_win and "config_win" or (P.is_mac and "config_mac" or "config_linux")

-- ── Locate jdtls launcher jar ────────────────────────────────────────────────
-- for _,d in ipairs({ P.join(P.mason_dir,"packages","jdtls","plugins")}) do
--     local g = vim.fn.glob(d .. "/org.eclipse.equinox.launcher_*.jar")
--     if g ~= "" then
--         launcher = P.path(g)
--         local base = d:match("(.+)/plugins$")
--         vim.list_extend(cmd,{
--             "-jar",launcher,
--             "-configuration", P.join(base,platform_cfg)
--         })
--         vim.print(launcher)
--         break
--     end
-- end

local local_launcher = vim.fn.glob(
    P.join(P.mason_dir,"packages","jdtls","plugins","org.eclipse.equinox.launcher_*.jar")
)
if vim.uv.fs_stat(local_launcher) then
    vim.list_extend(cmd,{
        "-jar", local_launcher,
        "-configuration", P.join(P.mason_dir,"packages","jdtls",platform_cfg),
    })
else
    local sys = vim.fn.glob("/usr/share/java/jdtls/plugins/org.eclipse.equinox.launcher_*.jar")
    if sys == "" then
        sys = vim.fn.glob(P.home .. "/apps/jdtls/plugins/org.eclipse.equinox.launcher_*.jar")
    end
    vim.list_extend(cmd, {
        "-Dosgi.checkConfiguration=true",
        "-Dosgi.sharedConfiguration.area=/usr/share/java/jdtls/config_linux/",
        "-Dosgi.sharedConfiguration.area.readOnly=true",
        "-Dosgi.configuration.cascaded=true",
        "-jar", sys,
    })
end

-- Per-project workspace cache
local datadir = P.join(P.cache_dir,"jdtls","projects",vim.fn.sha256(root_dir))
P.mkdir(datadir)
vim.list_extend(cmd, { "-data", datadir })

-- ── Extended capabilities ────────────────────────────────────────────────────
---@type any
local ok_jdtls,jdtls = pcall(require,"jdtls")
if not ok_jdtls then
    vim.notify("nvim-jdtls not installed. \nRun plugin install and restart.", vim.log.levels.WARN)
    return
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
      extCaps.inferSelectionSupport = { "extractMethod","extractVariable","extractField" }

-- ── on_attach: all Java keymaps ───────────────────────────────────────────────
---@diagnostic disable: undefined-field
local function on_attach(client, bufnr)
    local opts = { silent = true, buffer = bufnr }
    local set  = vim.keymap.set

    -- compile helper auto-save + build workspace)
    local function compile(ms)
        if vim.bo.modified then vim.cmd("w") end
        client:request_sync("java/buildWorkspace", false, ms or 5000, bufnr )
    end
    local function wc(fn)
        return function() compile(); fn() end
    end

    local function run_build(goals)
        local tool = build_tool()
        local exe = tool == "maven" and mvn_cmd() or gradle_cmd()
        if not exe then
            vim.notify("No build tool", vim.log.levels.WARN);
            return
        end
        local args=vim.split(goals," "); table.insert(args,1,exe)
        vim.g.java_build_status = " building..."
        vim.fn.jobstart(args, {
            cwd = root_dir,
            on_exit=function(_,code)
                vim.schedule(function()
                    vim.g.java_build_status=code==0 and " " or " FAILED"
                    vim.notify("Build "..(code==0 and "succeeded" or "FAILED"),
                        code==0 and vim.log.levels.INFO or vim.log.levels.ERROR,
                        {title="Java Build"})
                end)
            end
        })
    end

    -- ── Imports & organisation ──────────────────────────────────────────────
    set("n", "<A-o>", jdtls.organize_imports, opts)

    -- ── Refactoring  (<leader>jr…) ─────────────────────────────────────────
    set("n", "<leader>jrv", jdtls.extract_variable_all, opts)
    set("v", "<leader>jrv", "<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>", opts)
    set("v", "<leader>jrm", "<ESC><CMD>lua require('jdtls').extract_method(true)<CR>", opts)
    set("n", "<leader>jrc", jdtls.extract_constant, opts)
    set("n","<leader>jri", jdtls.organize_imports, opts)

    -- ── Code generation  (<leader>jc…) ────────────────────────────────────
    local function gen(k)
        return function()
            local ctx = { only = { k } }

            ---@cast ctx any
            vim.lsp.buf.code_action({
                context = ctx,
                apply = true,
            })
        end
    end
    set("n", "<leader>jco", gen("source.generate.toStringMethod"), opts)
    set("n", "<leader>jce", gen("source.generate.hashCodeEqualsMethod"), opts)
    set("n", "<leader>jcc", gen("source.generate.constructor"), opts)
    set("n", "<leader>jcd", gen("source.generate.delegateMethods"), opts)
    set("n", "<leader>jca", gen("source.generate.accessors"), opts)
    set("n", "<leader>jcg", function() jdtls.generate() end, opts)

    -- ── Tests  (<leader>jt…) ──────────────────────────────────────────────
    local conf = {
        stepFilters = { skipClasses = { "$JDK","junit.*","org.junit.*" }, skipSynthetics = true }
    }
    set("n", "<leader>jtc", function() if vim.bo.modified then vim.cmd("w") end
        jdtls.test_class({config_overrides=conf}) end, opts)
    set("n", "<leader>jtn", function() if vim.bo.modified then vim.cmd("w") end
        jdtls.test_nearest_method({config_overrides=conf}) end, opts)
    set("n", "<leader>jtd", function() if vim.bo.modified then vim.cmd("w") end
        require("jdtls.dap").pick_test() end, opts)

    set("n","<leader>jbb", function()
        run_build(build_tool()=="maven" and "clean package -DskipTests" or "clean build -x test")
    end, opts)
    set("n", "<leader>jbt", function() run_build("clean test") end, opts)
    set("n", "<leader>jbc", function() run_build("clean") end, opts)
    set("n", "<leader>jbr", function()
        vim.ui.select({ "clean package -DskipTests", "clean test", "spring-boot:run" },
            { prompt = "Build goal:" }, function(c) if c then run_build(c) end end) end, opts)

    set("n", "<leader>jsr", function()
        run_build(build_tool() == "maven" and "spring-boot:run" or "bootRun") end, opts)
    set("n", "<leader>jsR", function()
        local jvm = "-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005"
        run_build(build_tool() == "maven"
            and ( "spring-boot:run -Dspring-boot.run.jvmArguments="..vim.fn.shellescape(jvm) )
            or  "bootRun --debug-jvm")
        vim.defer_fn(function()
            require("dap").run({type="java",name="Attach Spring Boot",
                request="attach",hostName="localhost",port=5005})
        end, 2500)
    end, opts)

    -- set("n", "<leader>jsm", function()
    --   require("telescope.builtin").live_grep({
    --     prompt_title = "Request Mappings",
    --     search = "@(GetMapping|PostMapping|PutMapping|DeleteMapping|RequestMapping)",
    --     use_regex = true, type_filter = "java" }) end, opts)

    set("n","<leader>jsc",function()
        for _,f in ipairs({root_dir.."/src/main/resources/application.yml",
            root_dir.."/src/main/resources/application.properties"}) do
            if vim.uv.fs_stat(f) then vim.cmd.edit(f); return end
        end
    end,opts)

    -- :A → alternate file (test ↔ production)
    api.nvim_buf_create_user_command(bufnr, "A", function()
        require("jdtls.tests").goto_subjects()
    end, { desc = "goto alternate (test ↔ src)" })

    -- Update build-tool status shown in lualine
    vim.g.java_build_status = build_tool() == "maven" and " mvn" or
                              build_tool() == "gradle" and "gradle" or ""
end

-- ── Start jdtls ───────────────────────────────────────────────────────────────
---@diagnostic disable-next-line: undefined-field
jdtls.start_or_attach({
    cmd       = cmd,
    root_dir  = root_dir,
    on_attach = on_attach,
    init_options = {
        bundles                    = bundles,
        extendedClientCapabilities = extCaps,
    },
    handlers = {
        ["language/status"] = function() end,
        ["$/progress"]      = function() end,
    },
    settings = (vim.lsp.config["jdtls"] or {}).settings or {},
})
