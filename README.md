# nvim.me
---

## Prerequisites
* Neovim: `>= 0.12.0` (`nightly` right now).

* [git](https://git-scm.com/)

* Install [MSYS2](https://www.msys2.org/) or [winstall](https://winstall.app/apps/MartinStorsjo.LLVM-MinGW.MSVCRT) or [clang](https://rust-lang.github.io/rust-bindgen/requirements.html?highlight=LIB)- A C compiler is required to compile the parsers needed for nvim-treesitter and so on. Find out more at [here](https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support)


### Install LLVM (recommend)

```shell
winget install LLVM.LLVM
```
Then search for `libclang.dll`
```shell
Get-ChildItem "C:\Program Files\LLVM" `
    -Filter "libclang.dll" `
    -Recurse `
    -ErrorAction SilentlyContinue
```

Typically you'll get something under:

```
C:\Program Files\LLVM\bin
```

Then setup environment variable to `PATH`. Restart PowerShell and verify:

```shell
clang --version
```

### Install tree-sitter-cli

```shell
cargo install tree-sitter-cli --locked
```

<!-- ```shell -->
<!-- $ pacman -Syu -->
<!-- $ pacman -Su -->
<!-- $ pacman -S --needed base-devel mingw-w64-ucrt-x86_64-toolchain -->
<!-- ``` -->

* Setup `make`

* [fd](https://github.com/sharkdp/fd) - is a program to find entries in your filesystem. On Windows,
```
$ winget install sharkdp.fd
```

* [fzf](https://github.com/junegunn/fzf) - is a general-purpose command-line fuzzy finder. On Windows,

```
$ winget install fzf
```

* [ripgrep](https://github.com/BurntSushi/ripgrep) - is a line-oriented search tool that recursively searches the current directory for a regex pattern. On Windows,

```
$ $ winget install BurntSushi.ripgrep.MSVC
```

**Optional Install:**
* [jq](https://jqlang.github.io/jq/download/) - is a lightweight and flexible command-line JSON processor. On Windows,

```
$ winget install jqlang.jq
```

* [xmllint](https://gist.github.com/cbmeeks/8317048) - Fast Tool to Format, Beautify, and Validate XML

---
## Recommended Fonts
A [Nerd Fonts](https://www.nerdfonts.com/font-downloads) is required to see all the icons inside neovim. Here, I'm using [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip) for Windows Terminal Settings

```
Color scheme:        One Half Dark
Font face:           JetBrainsMonoNL Nerd Font
Font-size:           11
```

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

---
### Install Recipes
#### Linux
* Uninstall
```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.local/share/nvim
```

* To install on Linux/Mac, open terminal and then run the command below
```bash
git clone --recursive https://github.com/dghuuloc/nvim.me.git ~/.config/nvim
```

#### Windows
* Uninstall
```shell
rm -r -fo $env:LOCALAPPDATA/nvim
rm -r -fo $env:LOCALAPPDATA/nvim-data
```

* Install
```shell
git clone --recursive https://github.com/dghuuloc/nvim.me.git $env:LOCALAPPDATA/nvim
rm -r -fo $env:LOCALAPPDATA/nvim/.git
```

---
### Install plugins
```
git clone https://github.com/dghuuloc/fexptr.nvim.git "$env:LOCALAPPDATA\nvim-data\site\pack\plugins\start\fexptr.nvim"
```

---
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

## Action

Inside NeoVim:

```
Ctrl-Space   completion
gra          code action / missing import
gd           go to definition
gr           references
K            hover docs
<leader>f    format
<leader>oi   organize imports
F5           debug
<leader>pt   pytest current file
<leader>pa   pytest all
```

## References
* [Vim Cheat Sheet](https://vim.rtorr.com/)
* [Whats new in neovim 0.12](https://dotfiles.substack.com/p/whats-new-in-neovim-012)
