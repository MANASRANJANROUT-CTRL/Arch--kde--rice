#!/bin/bash

# Universal Theme Updater Installer with Kitty Transparency, Spotify + VS Code Integration

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

create_directories() {
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.config/kitty"
    mkdir -p "$HOME/Pictures/Wallpapers/wal"
}

install_script() {
    local script_path="$HOME/.local/bin/theme-update"
    cat << 'SCRIPT_EOF' > "$script_path"
#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/wal"
DEFAULT_OPACITY="0.85"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

check_dependencies() {
    local missing_deps=()
    if ! command_exists wal; then
        missing_deps+=("pywal")
    fi
    if ! command_exists walogram; then
        missing_deps+=("walogram")
    fi
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

update_pywal() {
    local image_path="$1"
    local wal_options="$2"
    print_status "Updating pywal colors..."
    wal -i "$image_path" $wal_options && print_success "Pywal colors updated" || print_error "Failed to update pywal colors"
}

update_pywalfox() {
    if command_exists pywalfox; then
        print_status "Updating pywalfox..."
        pywalfox update && print_success "Pywalfox updated" || print_warning "Failed to update pywalfox"
    fi
}

update_kitty() {
    print_status "Updating Kitty..."
    local kitty_config="$HOME/.config/kitty/kitty.conf"

    # Ensure pywal include exists
    if [ -f "$kitty_config" ] && ! grep -q "colors-kitty.conf" "$kitty_config"; then
        echo "" >> "$kitty_config"
        echo "# Include pywal colors" >> "$kitty_config"
        echo "include ~/.cache/wal/colors-kitty.conf" >> "$kitty_config"
    fi

    # Remove any existing background_opacity lines
    sed -i '/^background_opacity/d' "$kitty_config"

    # Append your transparency setting
    echo "background_opacity $DEFAULT_OPACITY" >> "$kitty_config"

    # Reload kitty if running
    if pgrep kitty >/dev/null; then
        killall -SIGUSR1 kitty
        print_success "Kitty transparency set to $DEFAULT_OPACITY and reloaded"
    fi
}

update_kotatogram() {
    print_status "Updating Kotatogram..."
    command_exists walogram && walogram && print_success "Kotatogram updated" || print_warning "Failed to update Kotatogram"
}

update_spicetify() {
    print_status "Updating Spicetify theme..."

    if command -v pywal-spicetify >/dev/null 2>&1; then
        # Generate colors for the Wal theme
        pywal-spicetify Wal

        # Apply the theme in Spicetify
        spicetify config current_theme Wal
        spicetify apply

        print_success "Spicetify theme updated successfully!"
    else
        print_warning "pywal-spicetify not installed or not found in PATH, skipping Spotify theme."
    fi
}

update_vscode() {
    print_status "Syncing VS Code theme..."
    if [ -x "$HOME/.local/bin/sync-vscode" ]; then
        "$HOME/.local/bin/sync-vscode"
        print_success "VS Code theme synced!"
    else
        print_warning "sync-vscode script not found"
    fi
}

set_wallpaper() {
    local image_path="$1"
    if command_exists feh; then
        feh --bg-fill "$image_path"
    elif command_exists nitrogen; then
        nitrogen --set-zoom-fill "$image_path"
    elif command_exists xwallpaper; then
        xwallpaper --zoom "$image_path"
    fi
}

get_random_wallpaper() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1
}

main() {
    local image_path=""
    local use_random=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--random) use_random=true; shift ;;
            *) image_path="$1"; shift ;;
        esac
    done

    check_dependencies

    if [ "$use_random" = true ]; then
        image_path=$(get_random_wallpaper)
        print_status "Using random wallpaper: $image_path"
    fi

    if [ ! -f "$image_path" ]; then
        print_error "Image not found: $image_path"
        exit 1
    fi

    update_pywal "$image_path"
    update_pywalfox
    update_kitty
    update_kotatogram
    update_spicetify
    update_vscode
    set_wallpaper "$image_path"

    print_success "All themes updated!"
}

main "$@"
SCRIPT_EOF

    chmod +x "$script_path"
    print_success "Script installed to $script_path"
}

configure_kitty() {
    local kitty_config="$HOME/.config/kitty/kitty.conf"
    if [ ! -f "$kitty_config" ]; then
        echo -e "# Kitty Configuration\ninclude ~/.cache/wal/colors-kitty.conf\nbackground_opacity 0.85\nallow_remote_control yes" > "$kitty_config"
    fi
}

add_to_path() {
    local shell_config="$HOME/.zshrc"
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$shell_config" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_config"
    fi
}

main() {
    print_status "Installing Universal Theme Updater..."
    create_directories
    install_script
    configure_kitty
    add_to_path
    print_success "Installation completed!"
    print_status "Usage: theme-update -r  (for random wallpaper)"
}

main "$@"
