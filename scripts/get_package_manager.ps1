#Requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$PackageManager = "auto"
)

# Script configuration
$SCRIPT_VERSION = "0.1.0"
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

# Determine the package manager
function Get-PackageManager {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $version = [version]$os.Version
    $build = $os.BuildNumber
    
    # Windows 11 is build 22000 or higher
    if ($build -lt 22000) {
        Write-ErrorAndExit "This script requires Windows 11 or newer. Current Windows version: $($os.Caption) (Build $build)"
    }

    # Check for package managers
    if (Test-Command 'choco') {
        return 'choco'
    }
    elseif (Test-Command 'scoop') {
        return 'scoop'
    }
    elseif (Test-Command 'winget') {
        return 'winget'
    }
    else {
        Write-ErrorAndExit "No package manager found. Please install one of: Chocolatey, Scoop, or Winget"
    }
}

# Show usage information
function Show-Usage {
    Write-Host "Universal Package Manager Detector - PowerShell Version"
    Write-Host "Version: $SCRIPT_VERSION"
    Write-Host ""
    Write-Host "Usage: $SCRIPT_NAME [OPTIONS]"
    Write-Host ""
    Write-Host "Description:"
    Write-Host "  Detects and returns the available package manager on the system."
    Write-Host "  Supports Chocolatey, Scoop, and Winget on Windows."
    Write-Host ""
    Write-Host "System Requirements:"
    Write-Host "  - Windows 11 or newer"
    Write-Host "  - PowerShell 5.1 or newer"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -h, --help          Show this help message"
    Write-Host "  -v, --version       Show version information"
    Write-Host ""
    Write-Host "Package Manager Priority:"
    Write-Host "  1. Chocolatey (choco)"
    Write-Host "  2. Winget"
    Write-Host "  3. Scoop"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  # Detect package manager"
    Write-Host "  $SCRIPT_NAME"
    Write-Host ""
    Write-Host "  # Show help"
    Write-Host "  $SCRIPT_NAME --help"
    Write-Host ""
    Write-Host "  # Show version"
    Write-Host "  $SCRIPT_NAME --version"
}

# Main script execution
try {
    # Process arguments
    switch ($PackageManager) {
        { $_ -eq "-h" -or $_ -eq "--help" } {
            Show-Usage
            exit 0
        }
        { $_ -eq "-v" -or $_ -eq "--version" } {
            Write-Host "$SCRIPT_NAME version $SCRIPT_VERSION"
            exit 0
        }
        default {
            $pm = Get-PackageManager
            Write-Host $pm
            exit 0
        }
    }
}
catch {
    Write-ErrorAndExit "Script execution failed: $_"
} 