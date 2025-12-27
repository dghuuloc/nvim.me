# nvim.me
---

## Recommended Fonts
A [Nerd Fonts](https://www.nerdfonts.com/font-downloads) is required to see all the icons inside neovim. Here, I'm using [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip) for Windows Terminal Settings

```
Color scheme:        One Half Dark
Font face:           JetBrainsMonoNL Nerd Font
Font-size:           11
```

## How do I install a package in Neovim without a package manager?
In Neovim, we can install plugins into `~/.config/nvim/pack/FOOBAR/start/` (replacing `FOOBAR` with any directory name you choose), similarly to how we can use [Vim 8.0's native support for packages](https://vi.stackexchange.com/questions/9522/what-is-the-vim8-package-feature-and-how-should-i-use-it).

Alternatively, we can also install plugins into ~/.local/share/nvim/site/pack/FOOBAR/start/ (replacing FOOBAR with any directory name you choose).

To find the full list of places where you we put a package, run `:set packpath?` . We can install packages in the `pack/FOOBAR/start/` subdirectory of each one of these directories listed by that command, replacing `FOOBAR` with any directory name you like. (If we've [configured Neovim to load Vim configuration](https://neovim.io/doc/user/nvim.html#nvim-from-vim), then we will probably find ~/.vim in the list of directories, which means we can also put plugins in ~/.vim/pack/FOOBAR/start/ , just like for Vim.)

---
## Installation
### Post installation
Below you can find OS specific install instructions for Neovim and dependencies.
#### Windows Installation
<details open><summary>Windows with gcc/make using chocolatey</summary>
Install gcc and make which don't require changing the config, the easiest way is to use choco:

1. install [chocolatey](https://chocolatey.org/install)
either follow the instructions on the page or use winget,
run in cmd as **admin**:
```
winget install --accept-source-agreements chocolatey.chocolatey
```

2. install all requirements using choco, exit the previous cmd and
open a new one so that choco path is set, and run in cmd as **admin**:
```
choco install -y neovim git ripgrep wget fd unzip gzip mingw make
```
</details>

### Install Recipes
- __To install on Linux/Mac, open terminal and then run the command below__
```shell
git clone --recursive https://github.com/dghuuloc/Neovim.Config.git ~/.config/nvim
```
- __Windows__
```shell
rm -r -fo $env:LOCALAPPDATA/nvim
rm -r -fo $env:LOCALAPPDATA/nvim-data
git clone --recursive https://github.com/dghuuloc/Neovim.Config.git $env:LOCALAPPDATA/nvim
rm -r -fo $env:LOCALAPPDATA/nvim/.git
```

---
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
- :MasonInstall jdtls java-debug-adapter js-debug-adapter java-test


## [Vim Cheat Sheet](https://vim.rtorr.com/)
