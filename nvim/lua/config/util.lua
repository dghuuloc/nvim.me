local M = {} -- The module to export

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--#region for Java
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
function M.maven_new_project()
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

    -- main format for commands execution from terminal
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

-- Maven Run Project
function M.maven_run_project()
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

-- Maven Run Project
function M.maven_task_project()
    local mvnTask = nil

    local taskMaster, canceled_task = get_maven_project_info("Enter Maven Task: ", "")
    
    if taskMaster == "tree" then
        mvnTask = "mvn dependency:tree"
    elseif taskMaster == "analyze" then
        mvnTask = "mvn dependency:analyze"
    elseif taskMaster == "validate" then
        mvnTask = "mvn clean validate"
    elseif taskMaster == "compile" then
        mvnTask = "mvn clean compile"
    elseif taskMaster == "test" then
        mvnTask = "mvn clean test"
    elseif taskMaster == "package" then
        mvnTask = "mvn clean package"
    elseif taskMaster == "verify" then
        mvnTask = "mvn clean verify"
    elseif taskMaster == "install" then
        mvnTask = "mvn clean install"
    else
        return mvnTask
    end

    -- Execute commands
    execute_command(mvnTask)

end

-- Create Java Class
function M.create_java_class()
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

-- Create Java Interface
function M.create_java_interface()
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

-- Java Run Project
function M.java_run_project()
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--#region for Java
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- START TESTING AREA
local function hello(name)
    print("Hello " .. name)
end

vim.keymap.set("n", "<leader>hl", 
    function ()
        -- local lines = vim.fn.readfile(vim.fn.getcwd() .. "\\.project") 
        -- for linenum, line in ipairs(lines) do
        --     if line:match("<name>JavaEcVim</name>") then
        --         print(line)

        --     end
        -- end
    end
, { desc = 'How to call '})
-- END TESTING AREA
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- We want to be able to access utils in all our configuration files
-- so we add the module to the _G global variable.
_G.utils = M
return M --Export the module
