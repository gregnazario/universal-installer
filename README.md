# universal-installer
Universal Installer Scripts for package managers across shells

## Usage

### For Unix-like systems
```sh
# For Unix-like systems
curl -sSL https://raw.githubusercontent.com/yourusername/universal-installer/main/install.sh | sh
```

Currently this supports the following package managers on macOS:
- Homebrew
- MacPorts

Currently this supports the following package managers on Linux:
- dnf
- apt-get
- apt
- pacman
- zypper
- yum
- emerge
- apk

Note, would be good to add support for more package managers on Linux.  This script is specifically built for POSIX compiliance, so it should work on any POSIX compliant shell.  

### For Windows
```powershell
# For Windows
iwr https://raw.githubusercontent.com/yourusername/universal-installer/main/install.ps1 -UseBasicP | iex
```

This supports the following package managers on Windows:
- Chocolatey
- Scoop
- Windows Package Manager (winget)
