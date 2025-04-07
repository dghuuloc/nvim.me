local function setup_jdtls()
    local workspace_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:h")
    local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
    local java_dap_path = vim.fn.stdpath("data") .. "/mason/packages/java-debug-adapter"

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
            "-jar", vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
            "-configuration", jdtls_path .. "/config_win",
            "-data", workspace_dir,
        },
        root_dir = vim.fs.dirname(
            vim.fs.find({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }, { upward = true })[1]
        ),
        settings = {
            java = {
                eclipse = {
                    downloadSources = true,
                },
                configuration = {
                    updateBuildConfiguration = "interactive",
                    runtimes = {
                        {
                            name = "JavaSE-17",
                            path = "C:/Program Files/Java/jdk-17",
                        },
                        {
                            name = "JavaSE-21",
                            path = "C:/Program Files/Java/jdk-21",
                        },
                    },
                },
                maven = {
                    downloadSources = true,
                },
            }
        },
        init_options = {
            bundles = {
                vim.fn.glob(java_dap_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1)
            }
        },
        on_attach = function()
            require("jdtls.dap").setup_dap()
            require("jdtls.dap").setup_dap_main_class_configs()
        end,
    }

    local status_ok, jdtls_result = pcall(require("jdtls").start_or_attach, config)
    if status_ok then
       print("Calling Java Language Server")
    else
       print("Error starting Jdtls: " .. tostring(jdtls_result))
    end 

end

vim.api.nvim_create_user_command( "JdtStart", setup_jdtls, { desc = "Start or Attatch Java Language Server" } )
vim.cmd([[ hi link javaConceptKind Type ]])
