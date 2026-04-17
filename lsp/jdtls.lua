---@type vim.lsp.Config
return {
  root_markers = {
    "pom.xml","build.gradle","build.gradle.kts",
    "settings.gradle","settings.gradle.kts",".git"
  },
  filetypes    = { "java" },
  settings = {
    java = {
      autobuild           = { enabled = false },
      maxConcurrentBuilds = 8,
      eclipse             = { downloadSources = true },
      maven               = { downloadSources = true, updateSnapshots = true },
      gradle              = { enabled = true, wrapper = { enabled = true } },
      signatureHelp       = { enabled = true, description = { enabled = true } },
      contentProvider     = { preferred = "fernflower" },
      saveActions         = { organizeImports = false },
      completion = {
        enabled               = true,
        guessMethodArguments  = true,
        overwrite             = false,
        favoriteStaticMembers = {
          "org.assertj.core.api.Assertions.*",
          "org.assertj.core.api.Assertions.assertThat",
          "org.assertj.core.api.Assertions.assertThatThrownBy",
          "org.assertj.core.api.Assertions.catchThrowable",
          "org.mockito.Mockito.*","org.mockito.Mockito.mock",
          "org.mockito.Mockito.when","org.mockito.Mockito.verify",
          "org.mockito.Mockito.verifyNoInteractions",
          "org.mockito.ArgumentMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.junit.jupiter.params.provider.Arguments.arguments",
          "org.springframework.test.web.servlet.result.MockMvcResultMatchers.status",
          "org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath",
          "org.springframework.test.web.servlet.result.MockMvcResultMatchers.content",
          "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
          "org.springframework.http.HttpStatus.*",
          "org.springframework.http.MediaType.*",
          "org.hamcrest.Matchers.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "java.util.Collections.*",
          "java.util.stream.Collectors.*",
        },
        filteredTypes = {
          "com.sun.*","java.awt.*","jdk.internal.*","sun.*",
          "javax.swing.*","javax.accessibility.*",
        },
        importOrder = { "java","javax","jakarta","org","com","io","#" },
      },
      sources          = {
        organizeImports = { starThreshold=5, staticStarThreshold=3 }
      },
      codeGeneration   = {
        toString       = {
          template  = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
          codeStyle = "STRING_CONCATENATION",
        },
        hashCodeEquals = { useJava7Objects=false, useInstanceOf=true },
        useBlocks      = true,
      },
      inlayHints       = {
        parameterNames = { enabled="literals" }
      },
      referencesCodeLens      = { enabled = true },
      implementationsCodeLens = { enabled = true },
      format           = { enabled = true },
      nullAnalysis     = { mode = "automatic" },
      diagnostics  = { enabled = true },
      import = {
        gradle = { enabled = true, wrapper = { enabled = true } },
        maven  = { enabled = true },
        exclusions = {
          "**/node_modules/**","**/.metadata/**",
          "**/archetype-resources/**","**/META-INF/maven/**",
        },
      },
      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = (function()
          local P = require("util.platform"); local out = {}
          local jdks = {
            { name = "JavaSE-21",env = "JDK21", fb = "C:/Program Files/java/jdk-21" },
            { name = "JavaSE-17",env = "JDK17", fb = "C:/Program Files/java/jdk-17" },
            { name = "JavaSE-11",env = "JDK11", fb = "C:/Program Files/java/jdk-11" },
          }
          for _, j in ipairs(jdks) do
            local p = os.getenv(j.env) or j.fb
            if p and p ~= "" and vim.uv.fs_stat(p) then
              table.insert(out, { name = j.name, path = P.path(p) }) end end
          return out
        end)(),
      },
    },
  },
}
