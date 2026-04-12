---@type vim.lsp.Config
return {
    root_markers = { "pom.xml","build.gradle","build.gradle.kts","settings.gradle",".git" },
    filetypes    = { "java" },
    settings = {
        java = {
            autobuild           = { enabled = false },
            maxConcurrentBuilds = 8,
            eclipse             = { downloadSources = true },
            maven               = { downloadSources = true, updateSnapshots = true },
            gradle              = { enabled = true },
            signatureHelp       = { enabled = true, description = { enabled = true } },
            contentProvider     = { preferred = "fernflower" },
            saveActions         = { organizeImports = true },
            completion = {
                enabled              = true,
                guessMethodArguments = true,
                favoriteStaticMembers = {
                    "org.assertj.core.api.Assertions.assertThat",
                    "org.assertj.core.api.Assertions.assertThatThrownBy",
                    "java.util.Objects.requireNonNull",
                    "org.mockito.Mockito.mock",
                    "org.mockito.Mockito.when",
                    "org.mockito.Mockito.verify",
                    "org.springframework.test.web.servlet.result.MockMvcResultMatchers.status",
                    "org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath",
                },
                filteredTypes = { "com.sun.*","java.awt.*","jdk.internal.*","sun.*" },
                importOrder   = { "java","javax","jakarta","org","com","#" },
            },
            sources          = { organizeImports = { starThreshold=5, staticStarThreshold=3 } },
            codeGeneration   = {
                toString       = { template="${object.className}{${member.name()}=${member.value}, ${otherMembers}}" },
                hashCodeEquals = { useJava7Objects=false, useInstanceOf=true },
                useBlocks      = true,
            },
            inlayHints       = { parameterNames = { enabled="literals" } },
            referencesCodeLens      = { enabled = true },
            implementationsCodeLens = { enabled = true },
            format           = { enabled = true },
            nullAnalysis     = { mode = "automatic" },
        },
    },
}
