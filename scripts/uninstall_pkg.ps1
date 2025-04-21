#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Packages,

    [Parameter()]
    [Alias('p')]
    [ValidateSet('choco', 'scoop', 'winget')]
    [string]$PackageManager = 'auto',

    [Parameter()]
    [switch]$SkipOverrides
)

# Script configuration
$SCRIPT_VERSION = "0.1.0"
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$OVERRIDES_DIR = "overrides"

# Check Windows version
function Test-WindowsVersion {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $version = [version]$os.Version
    $build = $os.BuildNumber
    
    # Windows 11 is build 22000 or higher
    if ($build -lt 22000) {
        Write-ErrorAndExit "This script requires Windows 11 or newer. Current Windows version: $($os.Caption) (Build $build)"
    }
}

# Error handling
function Write-ErrorAndExit {
    param (
        [string]$Message
    )
    Write-Error $Message
    exit 1
}

# Check if a command exists
function Test-Command {
    param (
        [string]$Command
    )
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Check if any package manager is installed
function Test-PackageManagerInstalled {
    param (
        [string]$Manager
    )
    switch ($Manager) {
        'choco' { return Test-Command 'choco' }
        'scoop' { return Test-Command 'scoop' }
        'winget' { return Test-Command 'winget' }
        default { return $false }
    }
}

# Get available package managers
function Get-AvailablePackageManagers {
    $managers = @()
    if (Test-PackageManagerInstalled 'choco') { $managers += 'choco' }
    if (Test-PackageManagerInstalled 'scoop') { $managers += 'scoop' }
    if (Test-PackageManagerInstalled 'winget') { $managers += 'winget' }
    return $managers
}

# Determine the best package manager to use
function Get-BestPackageManager {
    if ($PackageManager -ne 'auto') {
        if (Test-PackageManagerInstalled $PackageManager) {
            return $PackageManager
        }
        Write-ErrorAndExit "Specified package manager '$PackageManager' is not installed"
    }

    $available = Get-AvailablePackageManagers
    if ($available.Count -eq 0) {
        Write-ErrorAndExit "No package manager found. Please install one of: Chocolatey, Scoop, or Winget"
    }

    # Prefer Chocolatey, then Winget, then Scoop
    if ($available -contains 'choco') { return 'choco' }
    if ($available -contains 'winget') { return 'winget' }
    return 'scoop'
}

# Validate package name
function Test-ValidPackageName {
    param (
        [string]$Package
    )
    return $Package -match '^[a-zA-Z0-9._-]+$'
}

# Check package overrides
function Test-PackageOverride {
    param (
        [string]$Package,
        [string]$Manager
    )
    
    if ($SkipOverrides) {
        return $false
    }
    
    $overrideFile = Join-Path $OVERRIDES_DIR "$Manager/$Package.json"
    if (-not (Test-Path $overrideFile)) {
        return $false
    }
    
    try {
        $override = Get-Content $overrideFile -Raw | ConvertFrom-Json
        
        # Check if package should be skipped
        if ($override.uninstall -eq $false) {
            $reason = if ($override.reason) { $override.reason } else { "No reason specified" }
            Write-Warning "Skipping uninstall of $Package : $reason"
            return $true
        }
        
        # Check if package exists
        if ($override.exists -eq $false) {
            return $true
        }
    }
    catch {
        Write-Warning "Error parsing override file for $Package : $_"
        return $false
    }
    
    return $false
}

# Check if package is installed
function Test-PackageInstalled {
    param (
        [string]$Package,
        [string]$Manager
    )
    switch ($Manager) {
        'choco' {
            $installed = choco list --local-only $Package
            return $installed -match "^$Package "
        }
        'scoop' {
            $installed = scoop list
            return $installed -match "^$Package "
        }
        'winget' {
            $installed = winget list --name $Package
            return $installed -match "^$Package\s"
        }
    }
    return $false
}

# Uninstall a package
function Uninstall-Package {
    param (
        [string]$Package,
        [string]$Manager
    )
    
    if (-not (Test-ValidPackageName $Package)) {
        Write-ErrorAndExit "Invalid package name: $Package"
    }

    # Check package overrides first
    if (Test-PackageOverride $Package $Manager) {
        return
    }

    if (-not (Test-PackageInstalled $Package $Manager)) {
        Write-Host "Package $Package is not installed"
        return
    }

    Write-Host "Uninstalling $Package using $Manager..."
    try {
        switch ($Manager) {
            'choco' {
                choco uninstall $Package -y
                if ($LASTEXITCODE -ne 0) {
                    Write-ErrorAndExit "Failed to uninstall package: $Package"
                }
            }
            'scoop' {
                scoop uninstall $Package
                if ($LASTEXITCODE -ne 0) {
                    Write-ErrorAndExit "Failed to uninstall package: $Package"
                }
            }
            'winget' {
                winget uninstall --id $Package --accept-source-agreements
                if ($LASTEXITCODE -ne 0) {
                    Write-ErrorAndExit "Failed to uninstall package: $Package"
                }
            }
        }
    }
    catch {
        Write-ErrorAndExit "Error uninstalling package $Package : $_"
    }
}

# Show usage information
function Show-Usage {
    Write-Host "Universal Package Uninstaller - PowerShell Version"
    Write-Host "Version: $SCRIPT_VERSION"
    Write-Host ""
    Write-Host "Usage: $SCRIPT_NAME [OPTIONS] <package> [package...]"
    Write-Host ""
    Write-Host "Description:"
    Write-Host "  Uninstalls packages using the available package manager (Chocolatey, Scoop, or Winget)."
    Write-Host "  Automatically detects the best available package manager if not specified."
    Write-Host "  Supports package overrides through JSON files in the 'overrides' directory."
    Write-Host ""
    Write-Host "System Requirements:"
    Write-Host "  - Windows 11 or newer"
    Write-Host "  - Administrator privileges"
    Write-Host "  - PowerShell 5.1 or newer"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -h, --help                 Show this help message"
    Write-Host "  -v, --version              Show version information"
    Write-Host "  -p, --package-manager <manager> Specify package manager (choco, scoop, winget)"
    Write-Host "  --skip-overrides           Skip checking package overrides"
    Write-Host ""
    Write-Host "Package Manager Priority:"
    Write-Host "  1. Chocolatey (choco)"
    Write-Host "  2. Winget"
    Write-Host "  3. Scoop"
    Write-Host ""
    Write-Host "Override Files:"
    Write-Host "  Override files should be placed in: overrides/<manager>/<package>.json"
    Write-Host "  Example: overrides/choco/vim.json"
    Write-Host "  JSON structure:"
    Write-Host "    {"
    Write-Host "      `"uninstall`": false,"
    Write-Host "      `"exists`": false,"
    Write-Host "      `"reason`": `"Optional reason for skipping`""
    Write-Host "    }"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  # Uninstall a single package"
    Write-Host "  $SCRIPT_NAME vim"
    Write-Host ""
    Write-Host "  # Uninstall multiple packages"
    Write-Host "  $SCRIPT_NAME git curl wget"
    Write-Host ""
    Write-Host "  # Use specific package manager"
    Write-Host "  $SCRIPT_NAME -p winget vim"
    Write-Host "  $SCRIPT_NAME --package-manager winget vim"
    Write-Host ""
    Write-Host "  # Skip override checks"
    Write-Host "  $SCRIPT_NAME --skip-overrides vim"
    Write-Host ""
    Write-Host "  # Combine options"
    Write-Host "  $SCRIPT_NAME -p choco --skip-overrides git curl wget"
    Write-Host ""
    Write-Host "Note: This script requires administrator privileges to uninstall packages."
}

# Main script execution
try {
    # Check Windows version
    Test-WindowsVersion

    # Get the best package manager
    $selectedManager = Get-BestPackageManager
    Write-Host "Using package manager: $selectedManager"

    # Process arguments
    foreach ($arg in $Packages) {
        switch ($arg) {
            { $_ -eq "-h" -or $_ -eq "--help" } {
                Show-Usage
                exit 0
            }
            { $_ -eq "-v" -or $_ -eq "--version" } {
                Write-Host "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0
            }
            { $_ -eq "-p" -or $_ -eq "--package-manager" } {
                # Skip the next argument as it's the package manager name
                continue
            }
            { $_ -eq "--skip-overrides" } {
                $SkipOverrides = $true
                continue
            }
            default {
                Uninstall-Package $arg $selectedManager
            }
        }
    }
}
catch {
    Write-ErrorAndExit "Script execution failed: $_"
}
finally {
    # Cleanup if needed
} 