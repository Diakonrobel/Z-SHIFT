# 🐚 Z-SHIFT

<div align="center">

```text
 ███████╗      ███████╗██╗  ██╗██╗███████╗████████╗
 ╚══███╔╝      ██╔════╝██║  ██║██║██╔════╝╚══██╔══╝
   ███╔╝ █████╗███████╗███████║██║█████╗     ██║   
  ███╔╝  ╚════╝╚════██║██╔══██║██║██╔══╝     ██║   
 ███████╗      ███████╗██║  ██║██║██║        ██║   
 ╚══════╝      ╚══════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝
 ```
 **🚅 High-Performance Zsh + 🌸Gruvbox + ⚡ Zinit + Extra Goodies Installer**

</div>

------------

## 📖 Overview


**🐚 Z-SHIFT** is an automated bootstrap script designed to transform a stock Z-shell (ZSH) into a high-performance, aesthetically pleasing development environment.

It handles the heavy lifting of installing a modern plugin manager, configuring a lightning-fast prompt, and setting up the next generation of CLI tools in a single command.

[![asciicast](https://asciinema.org/a/qVjPp58itF6FGrI6.svg)](https://asciinema.org/a/qVjPp58itF6FGrI6)

------------

## ✨ Features

- ***⚡ Zinit Plugin Manager:*** Uses Turbo mode for non-blocking, rapid plugin loading. [https://github.com/zdharma-continuum/zinit]

- ***🚀 Starship Prompt:*** A minimal, blazing-fast, and infinitely customizable prompt for any shell. [https://starship.rs/]

- ***🛠 Modern CLI Arsenal:*** Automatically installs and configures:

  - **zoxide:** A smarter `cd` command that learns your habits. [https://github.com/ajeetdsouza/zoxide]

  - **eza:** A modern, maintained replacement for `ls` with colors and icons. [https://github.com/eza-community/eza]

  - **bat:** A `cat` clone with syntax highlighting and Git integration. [https://github.com/sharkdp/bat]

  - **ripgrep:** A line-oriented search tool that respects .gitignore and is faster than grep. [https://github.com/BurntSushi/ripgrep]

  - **tealdeer:** A fast implementation of `tldr;` (simplified man pages). [https://github.com/tealdeer-rs/tealdeer]

- ***⌨️ Pre-Configured Aliases:*** Includes a suite of intelligent aliases for common tasks to boost productivity immediately. You can use `alias` command to list all the aliases.

------------


## 💿 Installation

#### One-Line Install

You can set up your environment by running this command in your terminal:


```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/0xdilshan/Z-SHIFT/main/install.sh)"
``` 

***⚠️ Please log out and log back in to apply the changes. Additionally, ensure your terminal emulator's font is set to `FiraCode Nerd Font` (or any Nerd Font) so that icons and ligatures display correctly.***


#### Manual Install

If you prefer to download the script manually:

```
curl -O https://raw.githubusercontent.com/0xdilshan/Z-SHIFT/main/install.sh
chmod +x install.sh
./install.sh
```

------------

## 📦 Plugin Ecosystem

**🐚 Z-Shift** comes pre-loaded with a curated selection of the best Zsh plugins, lazy-loaded for speed:

- ### Core Libraries (OMZ)

  - **Git:** Essential git aliases and functions.
  - **History:** optimized history settings.
  - **Directories:** Navigation shortcuts and stack management.
  - **Completion:** Robust tab completion.
  - **Clipboard:** Cross-platform clipboard integration.

- ### Power Utilities

  - **extract:** One command to decompress almost any archive file (`.tar`, `.zip`, `.gz`, etc.).
  - **sudo:** Double-tap `ESC` to prepend `sudo` to the current or previous command.
  - **zsh-you-should-use:** Reminds you if there is an existing alias for the command you just typed.

------------


## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues](https://github.com/0xdilshan/Z-SHIFT/issues) page.

------------

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.