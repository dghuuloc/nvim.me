-- =============================================================================
--  lua/me/preview.lua
--  Terminal-native Markdown + AsciiDoc preview for Neovim 0.12
--
--  Two layers:
--    1. INLINE RENDERING  — markview.nvim renders Markdown/AsciiDoc
--                           beautifully inside the buffer (no external tool)
--    2. FLOATING PREVIEW  — glow (Markdown) or asciidoctor + w3m (AsciiDoc)
--                           in a persistent floating window, live-reloads on save
--
--  Dependencies (all optional — each layer degrades gracefully):
--    markview.nvim        :  npm / cargo NOT required — pure Lua
--    render-markdown.nvim :  fallback inline renderer
--    glow        Windows: winget install charmbracelet.glow
--                Linux:   brew/apt install glow
--    asciidoctor Windows: gem install asciidoctor  (needs Ruby)
--                         choco install ruby  then  gem install asciidoctor
--    w3m / lynx  Windows: not available (pandoc used as fallback)
--                Linux:   apt install w3m
--    pandoc      Windows: winget install --source winget --exact --id JohnMacFarlane.Pandoc
--                         (best fallback for AsciiDoc on Windows)
-- =============================================================================
-- Markview
local ok_mkv, mkv = pcall(require, "markview")
if ok_mkv then
    mkv.setup({
        preview = {
        enable = true,
        filetypes = { "markdown", "md", "rmd", "quarto" },
        hybrid_modes = { "n" },
  },
    })
end
