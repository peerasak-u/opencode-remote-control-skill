#!/bin/bash
#
# remote-control-setup - Automatically configure and start OpenCode remote access
#
# This script:
#   1. Checks Tailscale (CLI, app, daemon)
#   2. Installs Tailscale if not present
#   3. Connects to Tailscale if not connected
#   4. Starts OpenCode web server if not running
#   5. Outputs the private Tailscale URL
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PORT="${OPENCODE_PORT:-4096}"

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        OpenCode Remote Control Setup                             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

# Generate ASCII QR code using qrencode if available
generate_qr_code() {
    local url="$1"
    
    if command -v qrencode &> /dev/null; then
        echo ""
        echo -e "${GREEN}  Scan this QR code with your phone:${NC}"
        echo ""
        qrencode -t ANSIUTF8 -m 2 "$url" 2>/dev/null | sed 's/^/  /'
        echo ""
        return 0
    fi
    return 1
}

get_tailscale_ip() {
    tailscale ip -4 2>/dev/null || echo ""
}

get_tailscale_hostname() {
    tailscale status --json 2>/dev/null | grep -o '"HostName":"[^"]*"' | head -1 | cut -d'"' -f4 || echo ""
}

check_tailscale_cli() {
    if command -v tailscale &> /dev/null; then
        return 0
    fi
    return 1
}

check_tailscale_app_macos() {
    local locations=(
        "/Applications/Tailscale.app"
        "$HOME/Applications/Tailscale.app"
    )
    
    for loc in "${locations[@]}"; do
        if [[ -d "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done
    return 1
}

check_tailscale_daemon_macos() {
    if pgrep -x "Tailscale" &> /dev/null || pgrep -f "Tailscale.app" &> /dev/null; then
        return 0
    fi
    return 1
}

check_tailscale_daemon_linux() {
    if systemctl is-active --quiet tailscaled 2>/dev/null; then
        return 0
    fi
    if pgrep -x "tailscaled" &> /dev/null; then
        return 0
    fi
    return 1
}

check_tailscale_cli_in_app() {
    local app_cli="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    if [[ -x "$app_cli" ]]; then
        echo "$app_cli"
        return 0
    fi
    return 1
}

link_tailscale_cli_from_app() {
    local app_cli
    app_cli=$(check_tailscale_cli_in_app)
    if [[ -z "$app_cli" ]]; then
        return 1
    fi
    
    local target="/usr/local/bin/tailscale"
    
    if [[ -e "$target" ]]; then
        print_ok "CLI already linked at $target"
        return 0
    fi
    
    print_info "Creating symlink: $target -> $app_cli"
    
    if [[ ! -d "/usr/local/bin" ]]; then
        sudo mkdir -p /usr/local/bin
    fi
    
    sudo ln -sf "$app_cli" "$target"
    
    if command -v tailscale &> /dev/null; then
        print_ok "Tailscale CLI linked successfully"
        return 0
    fi
    
    return 1
}

install_tailscale_cli_macos() {
    print_step "Setting up Tailscale CLI..."
    
    # First, try to link from existing app (App Store version)
    local app_path
    app_path=$(check_tailscale_app_macos)
    if [[ -n "$app_path" ]]; then
        print_info "Found Tailscale app at: $app_path"
        
        if link_tailscale_cli_from_app; then
            return 0
        fi
        
        print_warn "Could not auto-link CLI from app"
    fi
    
    # Fall back to Homebrew
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found"
        echo ""
        echo -e "  ${YELLOW}To manually link CLI from Tailscale app, run:${NC}"
        echo "    sudo ln -s /Applications/Tailscale.app/Contents/MacOS/Tailscale /usr/local/bin/tailscale"
        echo ""
        echo -e "  ${YELLOW}Or install Homebrew:${NC}"
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    
    print_info "Installing via Homebrew..."
    brew install tailscale
    print_ok "Tailscale CLI installed via Homebrew"
}

install_tailscale_full_macos() {
    print_step "Installing Tailscale..."
    
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found"
        print_info "Download from: https://tailscale.com/download/mac"
        return 1
    fi
    
    brew install --cask tailscale
    print_ok "Tailscale installed via Homebrew"
    
    open -a Tailscale 2>/dev/null || true
    print_info "Tailscale app launched. Complete setup in the menu bar."
}

install_tailscale_linux() {
    print_step "Installing Tailscale..."
    
    curl -fsSL https://tailscale.com/install.sh | sh
    print_ok "Tailscale installed"
    
    sudo systemctl enable --now tailscaled 2>/dev/null || true
}

run_tailscale_diagnostics() {
    print_step "Running Tailscale diagnostics..."
    echo ""
    
    local has_cli=false
    local has_app=false
    local has_daemon=false
    local is_connected=false
    
    # Check CLI
    if check_tailscale_cli; then
        has_cli=true
        print_ok "Tailscale CLI available"
    else
        print_warn "Tailscale CLI not found"
    fi
    
    # Check app (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local app_path
        if app_path=$(check_tailscale_app_macos); then
            has_app=true
            print_ok "Tailscale app installed: $app_path"
        else
            print_warn "Tailscale app not found"
        fi
        
        if check_tailscale_daemon_macos; then
            has_daemon=true
            print_ok "Tailscale daemon running"
        else
            print_warn "Tailscale daemon not running"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if check_tailscale_daemon_linux; then
            has_daemon=true
            print_ok "Tailscale daemon running"
        else
            print_warn "Tailscale daemon not running"
        fi
    fi
    
    # Check connection status (requires CLI)
    if $has_cli; then
        local status
        status=$(tailscale status --json 2>/dev/null || echo '{"BackendState":"NoState"}')
        local state
        state=$(echo "$status" | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4)
        
        if [[ "$state" == "Running" ]]; then
            is_connected=true
            print_ok "Tailscale connected"
            local ts_ip
            ts_ip=$(get_tailscale_ip)
            if [[ -n "$ts_ip" ]]; then
                print_info "Tailscale IP: $ts_ip"
            fi
        else
            print_warn "Tailscale state: ${state:-Unknown}"
        fi
    fi
    
    echo ""
    
    # Determine what action to take
    if $is_connected; then
        return 0
    fi
    
    if ! $has_cli && ! $has_app && ! $has_daemon; then
        print_warn "Tailscale not installed"
        return 1
    fi
    
    if ! $has_cli && $has_app; then
        print_warn "Tailscale app installed but CLI not in PATH"
        print_info "Will attempt to link CLI from app"
        return 2
    fi
    
    if $has_cli && ! $has_daemon; then
        print_warn "CLI available but daemon not running"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            print_info "Open Tailscale app or run: open -a Tailscale"
        else
            print_info "Start daemon: sudo systemctl start tailscaled"
        fi
        return 3
    fi
    
    if $has_cli && $has_daemon && ! $is_connected; then
        print_warn "Not connected to tailnet"
        return 4
    fi
    
    return 5
}

connect_tailscale() {
    print_step "Connecting to Tailscale..."
    
    local status
    status=$(tailscale status --json 2>/dev/null || echo '{"BackendState":"NoState"}')
    local state
    state=$(echo "$status" | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4)
    
    case "$state" in
        Running)
            print_ok "Already connected"
            return 0
            ;;
        NeedsLogin|NeedsMachineAuth|Stopped|NoState)
            print_warn "Authentication required"
            echo ""
            echo -e "  ${YELLOW}A browser window will open for Tailscale login.${NC}"
            echo -e "  ${YELLOW}Complete authentication, then press Enter to continue.${NC}"
            echo ""
            
            tailscale up 2>&1 &
            local pid=$!
            sleep 3
            
            read -r
            
            for i in {1..30}; do
                local new_state
                new_state=$(tailscale status --json 2>/dev/null | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4)
                if [[ "$new_state" == "Running" ]]; then
                    print_ok "Connected to Tailscale"
                    return 0
                fi
                sleep 1
            done
            
            print_error "Connection timeout"
            print_info "Run 'tailscale up' manually and try again"
            return 1
            ;;
        *)
            print_warn "State: $state - attempting to connect..."
            tailscale up || true
            sleep 3
            if tailscale status &> /dev/null; then
                print_ok "Connected"
                return 0
            fi
            return 1
            ;;
    esac
}

start_opencode_server() {
    print_step "Starting OpenCode web server..."
    
    if lsof -i :$PORT -sTCP:LISTEN &> /dev/null; then
        print_ok "Server already running on port $PORT"
        return 0
    fi
    
    opencode web --hostname 0.0.0.0 --port $PORT &
    local pid=$!
    
    for i in {1..15}; do
        if lsof -i :$PORT -sTCP:LISTEN &> /dev/null; then
            print_ok "Server started on port $PORT"
            return 0
        fi
        sleep 1
    done
    
    print_error "Server failed to start"
    return 1
}

print_connection_info() {
    local ts_ip
    local ts_hostname
    
    ts_ip=$(get_tailscale_ip)
    ts_hostname=$(get_tailscale_hostname)
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Remote Access Ready!                                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -n "$ts_ip" ]]; then
        echo -e "  ${BLUE}Tailscale IP:${NC}    $ts_ip"
        echo -e "  ${BLUE}Hostname:${NC}       $ts_hostname"
        echo ""
        echo -e "  ${GREEN}Access from any device on your tailnet:${NC}"
        echo ""
        echo -e "    ${CYAN}http://$ts_ip:$PORT${NC}"
        if [[ -n "$ts_hostname" ]]; then
            echo -e "    ${CYAN}http://$ts_hostname:$PORT${NC}"
        fi
        
        generate_qr_code "http://$ts_ip:$PORT" || true
    else
        echo -e "  ${RED}Could not determine Tailscale IP${NC}"
    fi
    echo ""
    echo -e "  ${BLUE}Tip:${NC} Install Tailscale on your phone/tablet and sign in to"
    echo -e "        the same account to access OpenCode remotely."
    echo ""
}

main() {
    print_header
    
    # Run diagnostics first
    run_tailscale_diagnostics
    local diag_result=$?
    
    # Handle based on diagnostic result
    case $diag_result in
        0)
            print_ok "All Tailscale checks passed"
            ;;
        1)
            print_warn "Installing Tailscale..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                install_tailscale_full_macos || exit 1
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                install_tailscale_linux || exit 1
            else
                print_error "Please install from: https://tailscale.com/download"
                exit 1
            fi
            echo ""
            run_tailscale_diagnostics
            diag_result=$?
            ;;
        2)
            print_warn "Setting up Tailscale CLI..."
            install_tailscale_cli_macos || exit 1
            echo ""
            run_tailscale_diagnostics
            diag_result=$?
            ;;
        3)
            print_warn "Starting Tailscale daemon..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open -a Tailscale
                sleep 3
            else
                sudo systemctl start tailscaled
            fi
            echo ""
            run_tailscale_diagnostics
            diag_result=$?
            ;;
        4)
            connect_tailscale || exit 2
            ;;
        *)
            print_error "Unknown Tailscale state"
            exit 1
            ;;
    esac
    
    # If still not connected after fixes, try to connect
    if [[ $diag_result -ne 0 ]]; then
        if check_tailscale_cli; then
            connect_tailscale || exit 2
        else
            print_error "Cannot proceed without Tailscale CLI"
            exit 1
        fi
    fi
    
    echo ""
    
    # Start OpenCode server
    start_opencode_server || exit 3
    echo ""
    
    # Print connection info
    print_connection_info
}

main "$@"
