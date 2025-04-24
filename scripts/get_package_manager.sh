#!/bin/sh

# Enable basic error handling
set -e

# System information
INSTALL_OS=`uname -s`

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
        FreeBSD)
            if has_command pkg; then
                PACKAGE_MANAGER="pkg"
            else
                die "Missing package manager pkg (https://www.freebsd.org/ports/)"
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

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --version       Show version information"
    echo
    echo "Examples:"
    echo "  $0"
}

# Main script execution
if [ $# -gt 1 ]; then
    show_usage
    exit 1
elif [ $# -eq 1 ]; then
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            echo "Version: 0.1.0"
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
else
    get_package_manager
    echo "$PACKAGE_MANAGER"
    exit 0
fi