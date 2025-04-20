#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Packages,

    [Parameter()]
    [ValidateSet('choco', 'scoop', 'winget')]
    [string]$PackageManager = 'auto'
)

# Script configuration
$SCRIPT_VERSION = "1.0.0"
$SCRIPT_NAME = $MyInvocation.MyCommand.Name

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

# Check if package is already installed
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

# Install a package
function Install-Package {
    param (
        [string]$Package,
        [string]$Manager
    )
    
    if (-not (Test-ValidPackageName $Package)) {
        Write-ErrorAndExit "Invalid package name: $Package"
    }

    if (Test-PackageInstalled $Package $Manager) {
        Write-Host "Package $Package is already installed"
        return
    }

    Write-Host "Installing $Package using $Manager..."
    try {
        switch ($Manager) {
            'choco' {
                choco install $Package -y --no-progress
                if ($LASTEXITCODE -ne 0) {
                    Write-ErrorAndExit "Failed to install package: $Package"
                }
            }
            'scoop' {
                scoop install $Package
                if ($LASTEXITCODE -ne 0) {
                    Write-ErrorAndExit "Failed to install package: $Package"
                }
            }
            'winget' {
                winget install --id $Package --accept-source-agreements --accept-package-agreements
                if ($LASTEXITCODE -ne 0) {
                    Write-ErrorAndExit "Failed to install package: $Package"
                }
            }
        }
    }
    catch {
        Write-ErrorAndExit "Error installing package $Package : $_"
    }
}

# Show usage information
function Show-Usage {
    Write-Host "Usage: $SCRIPT_NAME [OPTIONS] <package> [package...]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -h, --help     Show this help message"
    Write-Host "  -v, --version  Show version information"
    Write-Host "  --package-manager <manager>  Specify package manager (choco, scoop, winget)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  $SCRIPT_NAME vim"
    Write-Host "  $SCRIPT_NAME git curl wget"
    Write-Host "  $SCRIPT_NAME --package-manager winget vim"
}

# Main script execution
try {
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
            { $_ -eq "--package-manager" } {
                # Skip the next argument as it's the package manager name
                continue
            }
            default {
                Install-Package $arg $selectedManager
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