# nvim.me
---

## How do I install a package in Neovim without a package manager?
In Neovim, we can install plugins into `~/.config/nvim/pack/FOOBAR/start/` (replacing `FOOBAR` with any directory name you choose), similarly to how we can use [Vim 8.0's native support for packages](https://vi.stackexchange.com/questions/9522/what-is-the-vim8-package-feature-and-how-should-i-use-it).

Alternatively, we can also install plugins into ~/.local/share/nvim/site/pack/FOOBAR/start/ (replacing FOOBAR with any directory name you choose).

To find the full list of places where you we put a package, run `:set packpath?` . We can install packages in the `pack/FOOBAR/start/` subdirectory of each one of these directories listed by that command, replacing `FOOBAR` with any directory name you like. (If we've [configured Neovim to load Vim configuration](https://neovim.io/doc/user/nvim.html#nvim-from-vim), then we will probably find ~/.vim in the list of directories, which means we can also put plugins in ~/.vim/pack/FOOBAR/start/ , just like for Vim.)

### Install plugins
```
git clone https://github.com/mfussenegger/nvim-jdtls.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-jdtls"
git clone https://github.com/mfussenegger/nvim-dap.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-dap"
git clone https://github.com/mfussenegger/nvim-dap-python.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-dap-python"
git clone https://github.com/nvim-neotest/nvim-nio.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-nio"
git clone https://github.com/rcarriga/nvim-dap-ui.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-dap-ui"
git clone https://github.com/williamboman/mason.nvim.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\mason.nvim"
git clone https://github.com/nvim-tree/nvim-tree.lua.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\nvim-tree.lua"
```

### Install Recipes
- __To install on Linux/Mac, open terminal and then run the command below__
```shell
git clone --recursive https://github.com/dghuuloc/nvim.me.git ~/.config/nvim
```
- __Windows__
```shell
rm -r -fo $env:LOCALAPPDATA/nvim
rm -r -fo $env:LOCALAPPDATA/nvim-data
git clone --recursive https://github.com/dghuuloc/nvim.me.git $env:LOCALAPPDATA/nvim
rm -r -fo $env:LOCALAPPDATA/nvim/.git
```
---
### __Install Java Debug Server and Test Runner for Java (optional)__
- __Insatall Java Debug Server on Windows__
```shell
git clone --recursive https://github.com/microsoft/java-debug.git $env:LOCALAPPDATA/nvim-data
```

- __Insatall Test Runner for Java on Windows__
```shell
git clone --recursive https://github.com/microsoft/vscode-java-test.git $env:LOCALAPPDATA/nvim-data
```

### __Install Python Debug Server via `pip` (optional)__
```shell
python -m pip install debugpy
```

## Install languager server extension
- :lua require('mason').setup()
- :MasonInstall jdtls java-debug-adapter js-debug-adapter

## [Vim Cheat Sheet](https://vim.rtorr.com/)
