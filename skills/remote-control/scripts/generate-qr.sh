#!/bin/bash
#
# generate-qr - Generate QR code for a URL
#
# Usage: generate-qr.sh <url>
#
# Requires: qrencode (falls back to URL display if not available)
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_qrencode() {
    if command -v qrencode &> /dev/null; then
        return 0
    fi
    return 1
}

install_qrencode_macos() {
    if ! command -v brew &> /dev/null; then
        return 1
    fi
    brew install qrencode
}

install_qrencode_linux() {
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y qrencode
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y qrencode
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm qrencode
    else
        return 1
    fi
}

print_qr_ascii() {
    local url="$1"
    
    if check_qrencode; then
        echo ""
        echo -e "${GREEN}  Scan this QR code with your phone/tablet:${NC}"
        echo ""
        qrencode -t ANSIUTF8 -m 2 "$url"
        echo ""
    fi
}

print_qr_terminal() {
    local url="$1"
    
    if check_qrencode; then
        qrencode -t UTF8 -m 2 "$url" 2>/dev/null && return 0
        qrencode -t ASCII -m 2 "$url" 2>/dev/null && return 0
        print_qr_ascii "$url"
    fi
}

main() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}Error: No URL provided${NC}"
        echo "Usage: $0 <url>"
        exit 1
    fi
    
    if ! check_qrencode; then
        echo ""
        echo -e "${YELLOW}  qrencode not found. Install it to generate QR codes:${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "    brew install qrencode"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "    sudo apt install qrencode  # Debian/Ubuntu"
            echo "    sudo dnf install qrencode  # Fedora"
        fi
        echo ""
        echo -e "  ${BLUE}URL:${NC} $url"
        echo ""
        exit 0
    fi
    
    print_qr_terminal "$url"
}

main "$@"
