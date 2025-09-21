#!/usr/bin/env bash

# GPurgeX - Clean GNOME debloating script
# Author: Zer0C0d3r (https://github.com/Zer0C0d3r)
# Version: 1.0.0

set -uo pipefail  # Removed -e to prevent early exit on package removal errors

# =============================================================================
# CONFIGURATION & CONSTANTS
# =============================================================================

# Colors for beautiful output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Package list to remove (24 packages)
readonly ALL_PACKAGES=(
    "decibels"
    "gnome-connections"
    "gnome-font-viewer"
    "gnome-calculator"
    "gnome-calendar"
    "snapshot"
    "gnome-characters"
    "gnome-clocks"
    "gnome-console"
    "gnome-contacts"
    "gnome-tour"
    "gnome-text-editor"
    "gnome-system-monitor"
    "epiphany"
    "gnome-weather"
    "totem"
    "simple-scan"
    "yelp"
    "gnome-maps"
    "gnome-music"
    "gnome-software"
    "gnome-system-monitor"
    "malcontent"
    "gnome-logs"
)

# Working package list (copy of ALL_PACKAGES)
PACKAGES=("${ALL_PACKAGES[@]}")

# Script metadata
readonly SCRIPT_NAME="gnome-debloat.sh"
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="${HOME}/.gnome-debloat.log"
readonly BACKUP_DIR="${HOME}/.config/gnome-debloat"
readonly BACKUP_FILE="${BACKUP_DIR}/backup.txt"

# Global variables
DRY_RUN=false
VERBOSE=false
RESTORE_MODE=false
INTERACTIVE=false
PACKAGE_MANAGER=""
SUDO_COMMAND=""
REMOVED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Print colored output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Print success message
print_success() {
    print_color "$GREEN" "[SUCCESS] $1"
}

# Print warning message
print_warning() {
    print_color "$YELLOW" "[WARNING] $1"
}

# Print error message
print_error() {
    print_color "$RED" "[ERROR] $1"
}

# Print info message
print_info() {
    print_color "$BLUE" "[INFO] $1"
}

# Print progress message
print_progress() {
    print_color "$CYAN" "[PROGRESS] $1"
}

# Show spinner for long operations
show_spinner() {
    local pid="$1"
    local message="$2"
    local delay=0.1
    local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

    echo -n "$message "
    while ps -p "$pid" > /dev/null 2>&1; do
        for char in "${spin_chars[@]}"; do
            echo -ne "\r$message $char"
            sleep "$delay"
        done
    done
    echo -e "\r$message ✓"
}

# Clean up on script exit
cleanup() {
    # Reset terminal colors
    echo -e "$NC"
    exit
}

# Handle Ctrl+C gracefully
handle_interrupt() {
    print_warning "Operation interrupted by user!"
    cleanup
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# ASCII ART & UI FUNCTIONS
# =============================================================================

# Display clean ASCII art banner
show_banner() {
    cat << 'EOF'
 _____ ______                    __   __
|  __ \| ___ \                   \ \ / /
| |  \/| |_/ /   _ _ __ __ _  ___ \ V /
| | __ |  __/ | | | '__/ _` |/ _ \/   \
| |_\ \| |  | |_| | | | (_| |  __/ /^\ \
 \____/\_|   \__,_|_|  \__, |\___\/   \/
                        __/ |
                       |___/

EOF
}

# Display celebration ASCII art
show_celebration() {
    cat << 'EOF'

🎉✨🎉✨🎉✨🎉✨🎉✨🎉✨🎉✨🎉✨
    GNOME DEBLOAT COMPLETE!
    Your system is lighter, faster,
    and happier! ✨🎉

    🐧 A dancing penguin salutes
       your minimalism!

    ╔══════════════════════════════╗
    ║    🎈 LIGHT & FREE! 🎈       ║
    ╚══════════════════════════════╝
🎉✨🎉✨🎉✨🎉✨🎉✨🎉✨🎉✨🎉✨

EOF
}

# Display help information
show_help() {
    cat << EOF
${CYAN}GNOME Debloat Delight v${SCRIPT_VERSION}${NC}

A modular, interactive bash script for safely debloating GNOME Desktop Environment.

${YELLOW}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS]

${YELLOW}OPTIONS:${NC}
    --dry-run          Show what would be removed without doing it
    --restore          Restore previously removed packages
    --interactive      Let user select which packages to remove
    --verbose          Show detailed output
    --help             Show this help message

${YELLOW}EXAMPLES:${NC}
    $SCRIPT_NAME                    # Run debloat
    $SCRIPT_NAME --dry-run          # Preview changes
    $SCRIPT_NAME --interactive      # Choose packages
    $SCRIPT_NAME --restore          # Restore packages

${YELLOW}PACKAGES TO BE REMOVED:${NC}
EOF

    for package in "${PACKAGES[@]}"; do
        echo "    • $package"
    done

    echo ""
    print_info "Total: ${#PACKAGES[@]} packages targeted"
}

# =============================================================================
# PACKAGE MANAGEMENT FUNCTIONS
# =============================================================================

# Detect package manager
detect_package_manager() {
    if command_exists apt; then
        PACKAGE_MANAGER="apt"
        SUDO_COMMAND="sudo"
    elif command_exists dnf; then
        PACKAGE_MANAGER="dnf"
        SUDO_COMMAND="sudo"
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        SUDO_COMMAND="sudo"
    elif command_exists pkg; then
        PACKAGE_MANAGER="pkg"
        SUDO_COMMAND="sudo"
    elif command_exists pkg_add; then
        PACKAGE_MANAGER="pkg_add"
        SUDO_COMMAND="sudo"
    else
        print_error "No supported package manager found"
        print_info "Supported systems: Ubuntu/Debian (apt), Fedora/RHEL (dnf), Arch (pacman), FreeBSD (pkg), OpenBSD (pkg_add)"
        exit 1
    fi

    print_info "Detected package manager: $PACKAGE_MANAGER"
}

# Check if package is installed
is_package_installed() {
    local package="$1"

    case "$PACKAGE_MANAGER" in
        "apt")
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        "dnf")
            rpm -q "$package" >/dev/null 2>&1
            ;;
        "pacman")
            pacman -Qi "$package" >/dev/null 2>&1
            ;;
        "pkg")
            pkg info "$package" >/dev/null 2>&1
            ;;
        "pkg_add")
            pkg_info "$package" >/dev/null 2>&1
            ;;
    esac
}

# Test package detection for debugging
test_package_detection() {
    if [[ "$VERBOSE" == "true" ]]; then
        print_info "Testing package detection..."
        for package in "${PACKAGES[@]}"; do
            if is_package_installed "$package"; then
                print_info "INSTALLED: $package"
            else
                print_info "NOT INSTALLED: $package"
            fi
        done
    fi
}

# Get package install size (for space calculation)
get_package_size() {
    local package="$1"

    case "$PACKAGE_MANAGER" in
        "apt")
            dpkg-query -Wf '${Installed-Size}' "$package" 2>/dev/null || echo "0"
            ;;
        "dnf"|"pacman")
            # Simplified - could be enhanced with more complex queries
            echo "0"
            ;;
    esac
}

# Uninstall package quietly
uninstall_package_quietly() {
    local package="$1"

    case "$PACKAGE_MANAGER" in
        "apt")
            $SUDO_COMMAND apt remove -y "$package" >/dev/null 2>&1
            ;;
        "dnf")
            $SUDO_COMMAND dnf remove -y "$package" >/dev/null 2>&1
            ;;
        "pacman")
            # Try normal removal first
            if ! $SUDO_COMMAND pacman -R --noconfirm "$package" >/dev/null 2>&1; then
                # If normal removal fails, try with dependencies
                if $SUDO_COMMAND pacman -R --noconfirm --cascade "$package" >/dev/null 2>&1; then
                    print_warning "Removed $package with dependencies (--cascade)"
                else
                    # If cascade also fails, try force removal
                    if $SUDO_COMMAND pacman -R --noconfirm --nodeps "$package" >/dev/null 2>&1; then
                        print_warning "Force removed $package (dependencies ignored)"
                    else
                        return 1
                    fi
                fi
            fi
            ;;
    esac
}

# Check sudo access
check_sudo() {
    if ! $SUDO_COMMAND -n true 2>/dev/null; then
        print_warning "Sudo access required. You may be prompted for your password."
        if ! $SUDO_COMMAND true; then
            print_error "Failed to obtain sudo access"
            exit 1
        fi
    fi
    print_success "Sudo access confirmed"
}

# =============================================================================
# LOGGING & BACKUP FUNCTIONS
# =============================================================================

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$BACKUP_DIR"
}

# Log uninstall history
log_uninstall_history() {
    local package="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] REMOVED: $package (via $PACKAGE_MANAGER)" >> "$LOG_FILE"
}

# Create backup of removed packages
create_backup() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')

    {
        echo "# GNOME Debloat Backup - $timestamp"
        echo "# Removed packages: $REMOVED_COUNT"
        echo "# Script version: $SCRIPT_VERSION"
        echo ""
        for package in "${PACKAGES[@]}"; do
            echo "$package"
        done
    } > "${BACKUP_FILE}.${timestamp}"
}

# Restore packages
restore_packages() {
    if [[ ! -f "$BACKUP_FILE" ]]; then
        print_error "No backup file found at $BACKUP_FILE"
        exit 1
    fi

    print_info "Restoring packages from backup..."
    local restored=0

    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue

        if ! is_package_installed "$package"; then
            print_progress "Restoring $package..."
            case "$PACKAGE_MANAGER" in
                "apt")
                    $SUDO_COMMAND apt install -y "$package" >/dev/null 2>&1
                    ;;
                "dnf")
                    $SUDO_COMMAND dnf install -y "$package" >/dev/null 2>&1
                    ;;
                "pacman")
                    $SUDO_COMMAND pacman -S --noconfirm "$package" >/dev/null 2>&1
                    ;;
            esac
            ((restored++))
        else
            print_warning "$package is already installed"
        fi
    done < "$BACKUP_FILE"

    print_success "Restored $restored packages"
}

# =============================================================================
# INTERACTIVE FUNCTIONS
# =============================================================================

# Interactive package selection
interactive_selection() {
    print_info "Select packages to remove (use space to toggle, enter to confirm):"

    local selected_packages=()
    local temp_file
    temp_file=$(mktemp)

    # Create temporary selection file
    for package in "${PACKAGES[@]}"; do
        echo "off $package" >> "$temp_file"
    done

    # Use dialog if available, otherwise fallback to simple menu
    if command_exists dialog; then
        dialog --checklist "Choose packages to remove:" 20 60 15 \
            --file "$temp_file" 2>/dev/null | tr ' ' '\n' > "${temp_file}.selected"
    else
        print_warning "dialog not available, using simple text menu"
        echo "Available packages:"
        local i=1
        for package in "${PACKAGES[@]}"; do
            echo "[$i] $package"
            ((i++))
        done
        echo ""
        read -p "Enter package numbers to remove (comma-separated): " selection

        # Parse selection (simplified)
        IFS=',' read -ra numbers <<< "$selection"
        for num in "${numbers[@]}"; do
            num=$(echo "$num" | tr -d ' ')
            if [[ "$num" =~ ^[0-9]+$ ]] && ((num > 0 && num <= ${#PACKAGES[@]})); then
                local package="${PACKAGES[$((num-1))]}"
                echo "$package" >> "${temp_file}.selected"
            fi
        done
    fi

    # Read selected packages
    if [[ -f "${temp_file}.selected" ]]; then
        mapfile -t selected_packages < "${temp_file}.selected"
    fi

    # Cleanup
    rm -f "$temp_file" "${temp_file}.selected"

    # Update PACKAGES array
    if (( ${#selected_packages[@]} > 0 )); then
        PACKAGES=("${selected_packages[@]}")
        print_success "Selected ${#PACKAGES[@]} packages for removal"
    else
        print_warning "No packages selected"
        exit 0
    fi
}

# Confirmation prompt
confirm_action() {
    local message="$1"
    echo ""
    read -p "$message (y/N): " response
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            print_info "Operation cancelled"
            exit 0
            ;;
    esac
}

# =============================================================================
# CORE DEBLOAT FUNCTIONS
# =============================================================================

# Main debloat function
run_debloat() {
    print_info "${#PACKAGES[@]} packages targeted for silent removal"
    echo ""

    local total_size=0
    local removed_packages=()

    for package in "${PACKAGES[@]}"; do
        # Debug: Show which package we're checking
        if [[ "$VERBOSE" == "true" ]]; then
            print_info "Checking: $package"
        fi

        if ! is_package_installed "$package"; then
            print_warning "SKIPPED: $package — already uninstalled!"
            ((SKIPPED_COUNT++))
            continue
        fi

        # Debug: Show if package is installed
        if [[ "$VERBOSE" == "true" ]]; then
            print_info "FOUND: $package is installed"
        fi

        # Special warning for gnome-console
        if [[ "$package" == "gnome-console" ]]; then
            print_warning "WARNING: gnome-console is GNOME's default terminal emulator!"
            print_warning "Removing it will delete your terminal. Ensure you have another terminal installed."
            if [[ "$DRY_RUN" != "true" ]]; then
                read -p "Continue with gnome-console removal? (y/N): " confirm
                if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
                    print_info "Skipping gnome-console removal"
                    ((SKIPPED_COUNT++))
                    continue
                fi
            fi
        fi

        # Get package size for reporting
        local size
        size=$(get_package_size "$package")
        total_size=$((total_size + size))

        if [[ "$DRY_RUN" == "true" ]]; then
            print_progress "Would remove $package... (dry run)"
        else
            print_progress "Removing $package..."

            # Show spinner while uninstalling
            (
                if uninstall_package_quietly "$package"; then
                    log_uninstall_history "$package"
                    removed_packages+=("$package")
                    ((REMOVED_COUNT++))
                    print_success "$package removed successfully"
                else
                    print_error "Failed to remove $package"
                    ((ERROR_COUNT++))
                fi
            ) &
            local pid=$!
            show_spinner "$pid" "Removing $package..."
        fi
    done

    # Wait for any background processes
    wait

    echo ""
    print_summary "$total_size" "${removed_packages[@]}"
}

# Print summary
print_summary() {
    local total_size="$1"
    shift
    local removed_packages=("$@")

    echo ""
    print_info "=== DEBLOAT SUMMARY ==="

    if (( REMOVED_COUNT > 0 )); then
        print_success "Removed: $REMOVED_COUNT packages"
        if (( total_size > 0 )); then
            local size_mb=$((total_size / 1024))
            print_info "Space freed: ~${size_mb} MB"
        fi
    fi

    if (( SKIPPED_COUNT > 0 )); then
        print_warning "Skipped: $SKIPPED_COUNT packages (already removed)"
    fi

    if (( ERROR_COUNT > 0 )); then
        print_error "Errors: $ERROR_COUNT packages failed to remove"
    fi

    if (( REMOVED_COUNT == 0 && SKIPPED_COUNT == 0 )); then
        print_success "Nothing to debloat! GNOME is already minimal. Nice!"
    fi

    # Save log and backup
    if (( REMOVED_COUNT > 0 )); then
        create_backup
        print_info "Log saved to $LOG_FILE"
        print_info "Backup saved to $BACKUP_DIR"
    fi
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --restore)
                RESTORE_MODE=true
                shift
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main script execution
main() {
    # Trap signals for cleanup
    trap cleanup EXIT
    trap handle_interrupt INT

    # Parse arguments
    parse_args "$@"

    # Show banner
    show_banner

    # Initialize logging
    init_logging

    # Handle restore mode
    if [[ "$RESTORE_MODE" == "true" ]]; then
        confirm_action "Restore previously removed packages?"
        detect_package_manager
        check_sudo
        restore_packages
        show_celebration
        exit 0
    fi

    # Handle interactive mode
    if [[ "$INTERACTIVE" == "true" ]]; then
        detect_package_manager
        interactive_selection
    else
        detect_package_manager
    fi

    # Check sudo access
    check_sudo

    # Test package detection if verbose
    test_package_detection

    # Confirmation for non-dry-run
    if [[ "$DRY_RUN" != "true" ]]; then
        confirm_action "Start GNOME debloating process?"
    fi

    # Run debloat
    run_debloat

    # Celebrate success
    if (( REMOVED_COUNT > 0 )) || [[ "$DRY_RUN" == "true" ]]; then
        show_celebration

        # Optional: Play victory sound
        if command_exists paplay; then
            echo -e "\a" # System bell
        fi
    fi

    # Exit with appropriate code
    if (( ERROR_COUNT > 0 )); then
        exit 1
    fi
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Run main function with all arguments
main "$@"
