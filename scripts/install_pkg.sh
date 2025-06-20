#!/bin/sh
###### Universal installer script
# install_pkg.sh v0.1.0
######

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
    if [ "$(jq -r ".install" "$override_file")" = "false" ]; then
        reason="$(jq -r ".reason // \"No reason specified\"" "$override_file")"
        warn "Skipping $package: $reason"
        return 0
    fi
    
    # Check if package exists
    if [ "$(jq -r ".exists" "$override_file")" = "true" ]; then
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
            elif has_command apt-get; then
                PACKAGE_MANAGER="apt-get"
            elif has_command pacman; then
                PACKAGE_MANAGER="pacman"
            elif has_command apk; then
                PACKAGE_MANAGER="apk"
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
        OpenBSD)
            if has_command doas; then
              PACKAGE_MANAGER="doas"
            else
              die "Missing package manager doas (https://www.openbsd.org/ports.html)"
            fi
            ;;
        NetBSD)
            if has_command pkgin; then
              PACKAGE_MANAGER="pkgin"
            elif has_command pkg_add; then
              PACKAGE_MANAGER="pkg_add"
            else
              die "Missing package manager pkgin or pkg_add (https://www.netbsd.org/docs/pkgsrc/)"
            fi
            ;;
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
        xbps)
            xbps-query "$package" >/dev/null 2>&1
            ;;
        pkg)
            pkg info "$package" >/dev/null 2>&1
            ;;
        emerge)
            emerge -q "$package" >/dev/null 2>&1
            ;;
        zypper)
            zypper se -i "$package" >/dev/null 2>&1
            ;;
        doas)
            doas pkg info "$package" >/dev/null 2>&1
            ;;
        pkgin)
            pkgin -Q "$package" >/dev/null 2>&1
            ;;
        pkg_add)
            pkg_add -I "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Install a package
install_pkg() {
    package="$1"
    
    get_package_manager
    
    # Check package overrides first
    if check_package_override "$package" "$PACKAGE_MANAGER"; then
        return 0
    fi
    
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
            if ! $PRE_COMMAND zypper install -y "$package"; then
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
        xbps)
            if ! $PRE_COMMAND xbps-install -y "$package"; then
                die "Failed to install package: $package"
            fi
            ;;
        pkg)
            if ! $PRE_COMMAND pkg install -y "$package"; then
                die "Failed to install package: $package"
            fi
            ;;
        doas)
            if ! $PRE_COMMAND doas pkg_add "$package"; then
          die "Failed to install package: $package"
            fi
            ;;
        pkgin)
            if ! $PRE_COMMAND pkgin install "$package"; then
          die "Failed to install package: $package"
            fi
            ;;
        pkg_add)
            if ! $PRE_COMMAND pkg_add "$package"; then
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
            install_pkg "$1"
            shift
            ;;
    esac
done
