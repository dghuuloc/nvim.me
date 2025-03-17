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
require("jdtls").start_or_attach(config)

-- JDTLS commands
vim.cmd([[command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)]])
vim.cmd([[command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()]])
vim.cmd([[command! -buffer JdtBytecode lua require('jdtls').javap()]])
vim.cmd([[command! -buffer JdtJshell lua require('jdtls').jshell()]])

-------------------------------------------------------------------------------------------------
-- #REGION FOR CUSTOMIZE JAVA'S USER 
-------------------------------------------------------------------------------------------------
-- Get Maven Project Info from User_Input
local function get_maven_project_info(prompt, default_value)
   vim.fn.inputsave()
   local result = vim.fn.input(prompt, default_value)
   vim.fn.inputrestore()

   if result == "" then
       return result, true
   end

   return result, false
end

-- Execute commands
local function execute_command(command)
    vim.cmd("new")
    vim.cmd("term " .. command)
    vim.fn.feedkeys("a")
end

-- Check Default Package 
local function get_default_package()
    local path = vim.fn.expand("%:p:h")
    local project_root = vim.fn.getcwd()
    local relative_path = path:sub(#project_root + 1)

    local uname = vim.loop.os_uname().sysname
    if uname == "Windows_NT" then
        relative_path = relative_path:gsub("src\\main\\java\\", "")
        relative_path = relative_path:gsub("\\", ".")
    else
        relative_path = relative_path:gsub("src/main/java/", "")
        relative_path = relative_path:gsub("/", ".")
    end

    return relative_path:sub(2)

end

-- Create Maven New Project
local function maven_new_project()
    -- Initialize values for Maven New Project Info
    local artifact_id, canceled_artifactId = get_maven_project_info("Enter project name: ", "")
    if canceled_artifactId then return end

    local project_dir = string.format(
        [[%s\%s]],
        vim.fn.getcwd(),
        artifact_id
    )

    if vim.fn.mkdir(project_dir, "p") == 0 then
        vim.notify("Failed to create project directory")
        return
    end

    local group_id, canceled_group = get_maven_project_info("Enter groupId: ", "com.example.app")
    if canceled_group then return end

    local archetype_artifact_id, canceled_archetype = get_maven_project_info("Enter archetypeArtifactId: ", "maven-archetype-quickstart")
    if canceled_archetype then return end

    local archetype_version, canceled_version = get_maven_project_info("Enter archetypeVersion: ", "1.5")
    if canceled_version then return end

    local interactive_mode, canceled_interactive = get_maven_project_info("Enter interactiveMode (true/false): ","false")
    if canceled_interactive then return end

    -- Main format for commands execution from terminal
    local commands = string.format(
        [[mvn archetype:generate "-DgroupId=%s" "-DartifactId=%s" "-DarchetypeArtifactId=%s" "-DarchetypeVersion=%s" "-DinteractiveMode=%s"]],
        group_id,
        artifact_id,
        archetype_artifact_id,
        archetype_version,
        interactive_mode
    )

    -- Execute final_commands
    vim.cmd("redraw | echo")
    vim.notify(string.format("Wait a moment for creating %s new project!", artifact_id))
    local output = vim.fn.system(commands)
    if vim.v.shell_error ~= 0 then
        vim.notify("Error when running " .. output)
    else
        print(output)
        local ch_dir = string.format("cd %s", project_dir)
        vim.fn.system(ch_dir)
        vim.fn.chdir(project_dir)
    end

end

-- Create Java Class with Maven project
local function create_java_class()
    local package_name, canceled_package = get_maven_project_info("Enter Package Name: ", get_default_package())
    if canceled_package then return end

    local class_name, canceled_class = get_maven_project_info("Enter Class Name: ", "")
    if canceled_class then return end

    local package_dir = nil
    if package_name then
        package_dir = string.format("src/main/java/%s", package_name:gsub("%.", "/"))

        if vim.fn.isdirectory(package_dir) == 0 then
            vim.fn.mkdir(package_dir, "p")
        end
    else
        vim.notify("Invalid package name: " .. package_name)
        return
    end

    local file_path = string.format("%s/%s.java", package_dir, class_name)
    if vim.fn.filereadable(file_path) == 1 then
        vim.notify("Class already exists: " .. file_path)
        return
    end

    -- Initialize content of Java Class
    local class_content = string.format(
[[
package %s;

public class %s {

}
]],
        package_name,
        class_name
    )
    
    local file = io.open(file_path, "w")
    if file then
        file:write(class_content)
        file:close()
    end

    vim.cmd(":edit " .. file_path)
    vim.cmd("redraw | echo")
    vim.notify("Java class created: " .. file_path)

end

-- Create Java Interface with Maven project
local function create_java_interface()
    local package_name, canceled_package = get_maven_project_info("Enter Package Name: ", get_default_package())
    if canceled_package then return end

    local interface_name, canceled_interface = get_maven_project_info("Enter Interface Name: ", "")
    if canceled_interface then return end

    local package_dir = nil
    if package_name then
        package_dir = string.format("src/main/java/%s", package_name:gsub("%.", "/"))

        if vim.fn.isdirectory(package_dir) == 0 then
            vim.fn.mkdir(package_dir, "p")
        end
    else
        vim.notify("Invalid package name: " .. package_name)
        return
    end

    local file_path = string.format("%s/%s.java", package_dir, interface_name)
    if vim.fn.filereadable(file_path) == 1 then
        vim.notify("Interface already exists: " .. file_path)
        return
    end

    -- Initialize content of Java Interface
    local interface_content = string.format(
[[
package %s;

public interface %s {

}

]],
        package_name,
        interface_name
    )
    
    local file = io.open(file_path, "w")
    if file then
        file:write(interface_content)
        file:close()
    end

    vim.cmd(":edit " .. file_path)
    vim.cmd("redraw | echo")
    vim.notify("Java interface created: " .. file_path)

end

-- Maven Run Project
local function maven_run_project()
    local group_id = vim.fn.expand('%')
    group_id = group_id:gsub("\\", ".")
    group_id = group_id:gsub("src.main.java.", ""):gsub(vim.fn.expand('%:t'), "")

    local cmdRun = string.format(
        [[mvn -q exec:java "-Dexec.mainClass=%s%s"]],
        group_id,
        vim.fn.expand('%:t:r')

    )
    -- Execute commands
    execute_command(cmdRun)

end

-- Java Run Project
local function java_run_project()
    local group_package = vim.fn.expand('%')
    group_package = group_package:gsub("\\", ".")
    group_package = group_package:gsub("src.", ""):gsub(vim.fn.expand('%:t'), "")

    local javaRun = string.format(
        [[java -classpath bin %s%s]],
        group_package,
        vim.fn.expand('%:t:r')

    )
    -- Execute commands
    execute_command(javaRun)

end

-------------------------------------------------------------------------------------------------
-- #CREATE JAVA'S USER COMMANDS 
-------------------------------------------------------------------------------------------------
vim.api.nvim_create_user_command("MavenNewProject", maven_new_project, { desc = "Create New Maven Project" })
vim.api.nvim_create_user_command("MavenRun", maven_run_project, { desc = "Run Maven Project" })
vim.api.nvim_create_user_command("MavenNewClass", create_java_class, { desc = "Create Java Class" })
vim.api.nvim_create_user_command("MavenNewInterface", create_java_interface, { desc = "Create Java Interface" })
vim.api.nvim_create_user_command("JavaRun", java_run_project, { desc = "Run Java Project" })
