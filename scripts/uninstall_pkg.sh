#!/bin/sh

# Enable basic error handling
set -e

# System information
INSTALL_OS=`uname -s`
INSTALL_USER=`whoami`

# Configuration
OVERRIDES_DIR="overrides"
SKIP_OVERRIDES=false
PACKAGE_MANAGER="auto"

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Error handling
die() {
    echo "Error: $1" 1>&2
    exit 1
}

# Warning message
warn() {
    echo "Warning: $1" 1>&2
}

# Install jq if not present
install_jq() {
    if has_command jq; then
        return 0
    fi
    
    echo "jq not found. Attempting to install..."
    
    SKIP_OVERRIDES=true
    install_pkg jq
    
    if ! has_command jq; then
        die "Failed to install jq. Please install it manually."
    fi
    SKIP_OVERRIDES=false
}

# Check package overrides
check_package_override() {
    if [ "$SKIP_OVERRIDES" = "true" ]; then
        return 1
    fi
    
    package="$1"
    pm="$2"
    
    # Check for package-specific override
    override_file="$OVERRIDES_DIR/$package.json"
    
    if [ ! -f "$override_file" ]; then
        return 1
    fi
    
    # Check if package should be skipped
    if [ "$(jq -r ".uninstall" "$override_file")" = "false" ]; then
        reason="$(jq -r ".reason // \"No reason specified\"" "$override_file")"
        warn "Skipping uninstall of $package: $reason"
        return 0
    fi
    
    # Check if package exists
    if [ "$(jq -r ".exists" "$override_file")" = "false" ]; then
        return 0
    fi
    
    return 1
}

# Determine the package manager
get_package_manager() {
    case "$INSTALL_OS" in
        Darwin)
            # Check for Brew or MacPorts
            if has_command brew; then
                PACKAGE_MANAGER="brew"
            elif has_command port; then
                PACKAGE_MANAGER="port"
            else
                die "Missing package manager Homebrew (https://brew.sh/) or MacPorts (https://www.macports.org/)"
            fi
            ;;
        Linux)
            if has_command dnf; then
                PACKAGE_MANAGER="dnf"
            elif has_command yum; then
                PACKAGE_MANAGER="yum"
            elif has_command pacman; then
                PACKAGE_MANAGER="pacman"
            elif has_command apk; then
                PACKAGE_MANAGER="apk"
            elif has_command apt-get; then
                PACKAGE_MANAGER="apt-get"
            elif has_command zypper; then
                PACKAGE_MANAGER="zypper"
            elif has_command emerge; then
                PACKAGE_MANAGER="emerge"
            elif has_command xbps-install; then
                PACKAGE_MANAGER="xbps"
            else
                die "Unable to find supported package manager (yum, dnf, pacman, apk, apt-get, zypper, emerge, or xbps)"
            fi
            ;;
        *)
            die "Unsupported OS: $INSTALL_OS"
            ;;
    esac
}

# Check if package is installed
is_package_installed() {
    package="$1"
    pm="$2"
    
    case "$pm" in
        yum|dnf)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        apt|apt-get)
            dpkg -l "$package" 2>/dev/null | grep '^ii' >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        apk)
            apk info -e "$package" >/dev/null 2>&1
            ;;
        brew)
            brew list "$package" >/dev/null 2>&1
            ;;
        port)
            port installed "$package" >/dev/null 2>&1
            ;;
        xbps)
            xbps-query "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Uninstall a package
uninstall_pkg() {
    package="$1"
    
    get_package_manager
    
    # Check package overrides first
    if check_package_override "$package" "$PACKAGE_MANAGER"; then
        return 0
    fi
    
    # Check if package is installed
    if ! is_package_installed "$package" "$PACKAGE_MANAGER"; then
        echo "Package $package is not installed"
        return 0
    fi

    PRE_COMMAND=""
    if [ "$INSTALL_USER" != 'root' ]; then
        PRE_COMMAND="sudo"
    fi

    echo "Uninstalling $package using $PACKAGE_MANAGER..."
    case "$PACKAGE_MANAGER" in
        yum)
            if ! $PRE_COMMAND yum remove "$package" -y; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        apt-get)
            if ! $PRE_COMMAND apt-get remove "$package" -y; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        apt)
            if ! $PRE_COMMAND apt remove "$package" -y; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        zypper)
            if ! $PRE_COMMAND zypper remove "$package" -y; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        emerge)
            if ! $PRE_COMMAND emerge --unmerge "$package"; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        port)
            if ! port uninstall "$package"; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        brew)
            if ! brew uninstall "$package"; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        pacman)
            if ! $PRE_COMMAND pacman -R "$package" --noconfirm; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        apk)
            if ! $PRE_COMMAND apk del "$package"; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        dnf)
            if ! $PRE_COMMAND dnf remove "$package" -y; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        xbps)
            if ! $PRE_COMMAND xbps-remove -y "$package"; then
                die "Failed to uninstall package: $package"
            fi
            ;;
        *)
            die "Unsupported package manager: $PACKAGE_MANAGER"
            ;;
    esac
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS] <package> [package...]"
    echo
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --version       Show version information"
    echo "  -s, --skip-overrides  Skip checking package overrides"
    echo "  -p, --package-manager <manager> Specify package manager"
    echo
    echo "Examples:"
    echo "  $0 vim"
    echo "  $0 git curl wget"
    echo "  $0 --skip-overrides vim"
    echo "  $0 -p apt vim"
    echo "  $0 --package-manager apt vim"
}

# Main script execution
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

# Parse options
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            echo "Version: 0.1.0"
            exit 0
            ;;
        -s|--skip-overrides)
            SKIP_OVERRIDES=true
            shift
            ;;
        -p|--package-manager)
            if [ -z "$2" ]; then
                die "Package manager not specified"
            fi
            PACKAGE_MANAGER="$2"
            shift 2
            ;;
        *)
            # Install jq if needed (unless skipping overrides)
            if [ "$SKIP_OVERRIDES" = "false" ]; then
                install_jq
            fi
            uninstall_pkg "$1"
            shift
            ;;
    esac
done 