-------------------------------------------------------------------------------------------------
-- #REGION FOR CUSTOMIZE JDTLS LANGUAGE SERVER 
-------------------------------------------------------------------------------------------------
local workspace_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:h")
local jdtls_path = require("mason-registry").get_package("jdtls"):get_install_path()
local java_dap_path = require("mason-registry").get_package("java-debug-adapter"):get_install_path()

local config = {
    cmd = {
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-javaagent:" .. jdtls_path .. "/lombok.jar",
        "-Xms1g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        "-jar",
        vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
        "-configuration", jdtls_path .. "/config_win",
        "-data", workspace_dir,
    },

    root_dir = vim.fs.dirname(
        vim.fs.find({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }, { upward = true })[1]
    ),
    -- Configure settings in the JDTLS server
    settings = {
        java = {
            eclipse = {
                downloadSources = true,
            },
            configuration = {
                updateBuildConfiguration = "interactive",
                runtimes = {
                    {
                        name = "JavaSE-11",
                        path = "C:\\Program Files\\Java\\jdk-11",
                    },
                    {
                        name = "JavaSE-17",
                        path = "C:\\Program Files\\Java\\jdk-17",
                    },
                    {
                        name = "JavaSE-21",
                        path = "C:\\Program Files\\Java\\jdk-21",
                    },
                },
            },

            maven = {
                downloadSources = true,
            },
            referencesCodeLens = {
                enabled = true,
            },
            references = {
                includeDecompiledSources = true,
            },
            contentProvider = {
                preferred = "fernflower",
            },
            signatureHelp = {
                enabled = true,
            },
            inlayHints = {
                parameterNames = {
                    enabled = "all",
                },
            },
            compile = {
                nullAnalysis = {
                    nonnull = {
                        "lombok.NonNull",
                        "javax.annotation.Nonnull",
                        "org.eclipse.jdt.annotation.NonNull",
                        "org.springframework.lang.NonNull",
                    },
                },
            },
            completion = {
                favoriteStaticMembers = {
                    "org.hamcrest.MatcherAssert.assertThat",
                    "org.hamcrest.Matchers.*",
                    "org.hamcrest.CoreMatchers.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                    "java.util.Objects.requireNonNullElse",
                    "org.mockito.Mockito.*",
                },
                filteredTypes = {
                    "com.sun.*",
                    "io.micrometer.shaded.*",
                    "java.awt.*",
                    "jdk.*",
                    "sun.*",
                },
                importOrder = {
                    "java",
                    "jakarta",
                    "javax",
                    "com",
                    "org",
                },
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                },
            },
            codeGeneration = {
                toString = {
                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                },
                hashCodeEquals = {
                    useJava7Objects = true,
                },
                useBlocks = true,
            },
        },
    },
    init_options = {
        bundles = {
            vim.fn.glob(java_dap_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1)
        }
    },
    -- Function that will be ran once the language server is attached
    on_attach = function()
        vim.keymap.set("n", "Jei", "<Cmd> lua require('jdtls').organize_imports()<CR>",{ desc = "Java extract imports" })
        -- Setup the java debug adapter of the JDTLS server
        require("jdtls.dap").setup_dap()
        require("jdtls.dap").setup_dap_main_class_configs()
        -- Enable jdtls commands to be used in Neovim
        require("jdtls.setup").add_commands()
    end,
}

-- require("jdtls").start_or_attach(config)

vim.api.nvim_create_user_command("JdtServiceStart",
    function()
        local status_ok, jdtls_result = pcall(require("jdtls").start_or_attach, config)

        -- JDTLS commands
        vim.cmd([[command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)]])
        vim.cmd([[command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()]])
        vim.cmd([[command! -buffer JdtBytecode lua require('jdtls').javap()]])
        vim.cmd([[command! -buffer JdtJshell lua require('jdtls').jshell()]])

        if status_ok then
           print("Jdtls Service starting...")
        else
           print("Error starting Jdtls: " .. tostring(jdtls_result))
        end 

    end,
    
   { desc = "Start or Attatch Jdtls Language Server" }
)

