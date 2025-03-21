# nvim.me

## Install plugins
```
git clone https://github.com/mfussenegger/nvim-jdtls.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-jdtls"
git clone https://github.com/mfussenegger/nvim-dap.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-dap"
git clone https://github.com/mfussenegger/nvim-dap-python.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-dap-python"
git clone https://github.com/nvim-neotest/nvim-nio.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-nio"
git clone https://github.com/rcarriga/nvim-dap-ui.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-dap-ui"
git clone https://github.com/williamboman/mason.nvim.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\mason.nvim"
```

## Install languager server extension
- :lua require('mason').setup()
- :MasonInstall jdtls java-debug-adapter js-debug-adapter

## Using buit-in colorscheme
shine(light), delek(light), slate, sorbet, retrobox
