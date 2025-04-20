#!/bin/sh

# Enable basic error handling
set -e

# System information
INSTALL_OS=`uname -s`
INSTALL_USER=`whoami`

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Error handling
die() {
    echo "Error: $1" 1>&2
    exit 1
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
            if has_command yum; then
                PACKAGE_MANAGER="yum"
            elif has_command dnf; then
                echo "WARNING: dnf package manager support is experimental" 1>&2
                PACKAGE_MANAGER="dnf"
            elif has_command pacman; then
                PACKAGE_MANAGER="pacman"
            elif has_command apk; then
                PACKAGE_MANAGER="apk"
            elif has_command apt-get; then
                PACKAGE_MANAGER="apt-get"
            elif has_command apt; then
                PACKAGE_MANAGER="apt"
            elif has_command zypper; then
                PACKAGE_MANAGER="zypper"
            elif has_command emerge; then
                PACKAGE_MANAGER="emerge"
            else
                die "Unable to find supported package manager (yum, dnf, pacman, apk, apt, apt-get, zypper, or emerge)"
            fi
            ;;
        # TODO: Add support for other OSes
        #windows)
        #    PACKAGE_MANAGER="choco"
        #    ;;
        *)
            die "Unsupported OS: $INSTALL_OS"
            ;;
    esac
}

# Check if package is already installed
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
        *)
            return 1
            ;;
    esac
}

# Install a package
install_pkg() {
    package="$1"
    
    # Validate package name
    if ! echo "$package" | grep '^[a-zA-Z0-9._-]\+$' >/dev/null 2>&1; then
        die "Invalid package name: $package"
    fi

    get_package_manager
    
    # Check if package is already installed
    if is_package_installed "$package" "$PACKAGE_MANAGER"; then
        echo "Package $package is already installed"
        return 0
    fi

    PRE_COMMAND=""
    if [ "$INSTALL_USER" != 'root' ]; then
        PRE_COMMAND="sudo"
    fi

    echo "Installing $package using $PACKAGE_MANAGER..."
    case "$PACKAGE_MANAGER" in
        yum)
            if ! $PRE_COMMAND yum install "$package" -y; then
                die "Failed to install package: $package"
            fi
            ;;
        apt-get)
            if ! $PRE_COMMAND apt-get install "$package" --no-install-recommends -y; then
                die "Failed to install package: $package"
            fi
            ;;
        apt)
            if ! $PRE_COMMAND apt install "$package" --no-install-recommends -y; then
                die "Failed to install package: $package"
            fi
            ;;
        zypper)
            if ! $PRE_COMMAND zypper install "$package" -y; then
                die "Failed to install package: $package"
            fi
            ;;
        emerge)
            if ! $PRE_COMMAND emerge "$package"; then
                die "Failed to install package: $package"
            fi
            ;;
        port)
            if ! port install "$package"; then
                die "Failed to install package: $package"
            fi
            ;;
        brew)
            if ! brew install "$package"; then
                die "Failed to install package: $package"
            fi
            ;;
        pacman)
            if ! $PRE_COMMAND pacman -Syu "$package" --noconfirm; then
                die "Failed to install package: $package"
            fi
            ;;
        apk)
            if ! $PRE_COMMAND apk --update add --no-cache "$package"; then
                die "Failed to install package: $package"
            fi
            ;;
        dnf)
            if ! $PRE_COMMAND dnf install "$package" -y; then
                die "Failed to install package: $package"
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
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version information"
    echo
    echo "Examples:"
    echo "  $0 vim"
    echo "  $0 git curl wget"
}

# Main script execution
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            echo "Version: 1.0.0"
            exit 0
            ;;
        *)
            install_pkg "$arg"
            ;;
    esac
done
