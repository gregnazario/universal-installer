# Universal Package Installer/Uninstaller

A cross-platform package management tool that supports multiple package managers and provides a unified interface for installing and uninstalling packages.

## Features

- Supports multiple package managers:
  - Linux: apt, apt-get, yum, dnf, pacman, apk, zypper, emerge, xbps
  - macOS: Homebrew, MacPorts
  - Windows: Chocolatey, Scoop, Winget
- Auto-detection of available package managers
- Package override system with JSON configuration
- Cross-platform shell and PowerShell implementations

## Installation

1. Download the latest release from GitHub
2. Extract the zip file
3. Add the `scripts` directory to your PATH

## Usage

### Shell Version (Linux/macOS)

Install packages:
```bash
./install_pkg.sh [OPTIONS] <package> [package...]
```

Uninstall packages:
```bash
./uninstall_pkg.sh [OPTIONS] <package> [package...]
```

### PowerShell Version (Windows)

Install packages:
```powershell
.\install_pkg.ps1 [OPTIONS] <package> [package...]
```

Uninstall packages:
```powershell
.\uninstall_pkg.ps1 [OPTIONS] <package> [package...]
```

### Options

- `-h, --help`: Show help message
- `-v, --version`: Show version information
- `-s, --skip-overrides`: Skip checking package overrides
- `-p, --package-manager <manager>`: Specify package manager

## Package Overrides

Create JSON files in the `overrides` directory to control package installation/uninstallation. Each package should have its own JSON file named after the package.

```
overrides/
  ├── build-essential.json
  ├── vim.json
  └── git.json
```

Example override file (build-essential.json):
```json
{
  "install": false,
  "exists": true,
  "reason": "Package is already installed via system package manager"
}
```

For uninstallation overrides, use the `uninstall` key instead:
```json
{
  "uninstall": false,
  "exists": false,
  "reason": "Package is required by the system"
}
```

The override files support the following keys:
- `install`: Set to `false` to skip installation
- `uninstall`: Set to `false` to skip uninstallation
- `exists`: Set to `true` if the package exists, `false` if it doesn't
- `reason`: Optional message explaining why the operation is being skipped

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
