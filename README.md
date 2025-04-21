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

## Release Guide

### Creating a New Release

1. Update the version number in `version.txt`
2. Commit the version change:
   ```bash
   git add version.txt
   git commit -m "Bump version to X.Y.Z"
   ```
3. Create and push a version tag:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

The GitHub Actions workflow will automatically:
- Read the version from `version.txt`
- Update version numbers in all scripts
- Create a release package (`universal-installer.zip`)
- Generate a SHA-256 checksum file
- Create a GitHub release with both files

### Release Package Contents

The release package (`universal-installer.zip`) contains:
- All installation and uninstallation scripts
- Package manager detection scripts
- README.md and LICENSE files
- Version information

### Verifying the Release

1. Download the release package and checksum file
2. Verify the checksum:
   ```bash
   sha256sum -c universal-installer.zip.sha256
   ```
3. Extract the package and verify the contents
4. Test the scripts on your target platform

### Release Checklist

- [ ] Update version in `version.txt`
- [ ] Verify all scripts are working
- [ ] Test on all supported platforms
- [ ] Update documentation if needed
- [ ] Create and push version tag
- [ ] Verify GitHub release is created
- [ ] Test the release package
- [ ] Announce the release

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
