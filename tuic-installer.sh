#!/bin/bash

# ============================================================
#  TUIC v5 One-Click Installer
#  https://github.com/ccj241/tuic-v5-installer
#
#  Supports: Ubuntu / Debian / CentOS (x86_64 / aarch64)
#  Usage:
#    Interactive:     bash tuic-installer.sh
#    Non-interactive: bash tuic-installer.sh --auto
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

INSTALL_DIR="/root/tuic"
SERVICE_FILE="/etc/systemd/system/tuic.service"
CONFIG_FILE="$INSTALL_DIR/config.json"

# -------------------- Utilities --------------------

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root. Use: sudo bash $0"
    fi
}

# -------------------- Dependencies --------------------

install_dependencies() {
    info "Installing dependencies..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq >/dev/null 2>&1
        apt-get install -y -qq curl jq openssl uuid-runtime wget >/dev/null 2>&1
    elif command -v yum &>/dev/null; then
        yum install -y -q curl jq openssl util-linux wget >/dev/null 2>&1
    elif command -v dnf &>/dev/null; then
        dnf install -y -q curl jq openssl util-linux wget >/dev/null 2>&1
    else
        error "Unsupported package manager. Please install: curl jq openssl wget uuid-runtime"
    fi
    info "Dependencies installed."
}

# -------------------- Architecture --------------------

detect_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64)  echo "x86_64-unknown-linux-gnu" ;;
        i686)    echo "i686-unknown-linux-gnu" ;;
        aarch64) echo "aarch64-unknown-linux-gnu" ;;
        armv7l)  echo "armv7-unknown-linux-gnueabi" ;;
        *)       error "Unsupported architecture: $arch" ;;
    esac
}

# -------------------- Download --------------------

download_tuic() {
    local server_arch="$1"

    info "Fetching latest release version..."
    local latest

    # Primary: our own mirror repo
    latest=$(curl -sL "https://api.github.com/repos/ccj241/tuic-v5-installer/releases/latest" \
        | jq -r '.tag_name' 2>/dev/null)

    # Fallback: upstream repo (may redirect)
    if [ -z "$latest" ] || [ "$latest" = "null" ]; then
        latest=$(curl -sL "https://api.github.com/repos/EAimTY/tuic/releases" \
            | jq -r '[.[] | select(.tag_name | startswith("tuic-server"))][0].tag_name' 2>/dev/null)
    fi

    if [ -z "$latest" ] || [ "$latest" = "null" ]; then
        warn "Failed to fetch version from API, using fallback version."
        latest="tuic-server-1.0.0"
    fi
    info "Latest version: $latest"

    info "Downloading tuic-server..."
    mkdir -p "$INSTALL_DIR"

    # Try download sources in order: own mirror -> upstream
    local downloaded=false
    local urls=(
        "https://github.com/ccj241/tuic-v5-installer/releases/download/$latest/$latest-$server_arch"
        "https://github.com/EAimTY/tuic/releases/download/$latest/$latest-$server_arch"
        "https://github.com/tuic-protocol/tuic/releases/download/$latest/$latest-$server_arch"
    )

    for url in "${urls[@]}"; do
        if curl -sL -o "$INSTALL_DIR/tuic-server" --fail "$url" 2>/dev/null; then
            downloaded=true
            break
        fi
    done

    if [ "$downloaded" = false ]; then
        error "Failed to download tuic-server. Tried all sources."
    fi
    chmod 755 "$INSTALL_DIR/tuic-server"
    info "Download complete."
}

# -------------------- Certificates --------------------

generate_certs() {
    info "Generating self-signed certificates..."
    openssl ecparam -genkey -name prime256v1 -out "$INSTALL_DIR/ca.key" 2>/dev/null
    openssl req -new -x509 -days 36500 -key "$INSTALL_DIR/ca.key" \
        -out "$INSTALL_DIR/ca.crt" -subj "/CN=bing.com" 2>/dev/null
    info "Certificates generated."
}

# -------------------- Configuration --------------------

generate_config() {
    local port="$1"
    local password="$2"
    local uuid="$3"

    cat > "$CONFIG_FILE" <<EOF
{
  "server": "[::]:$port",
  "users": {
    "$uuid": "$password"
  },
  "certificate": "$INSTALL_DIR/ca.crt",
  "private_key": "$INSTALL_DIR/ca.key",
  "congestion_control": "bbr",
  "alpn": ["h3", "spdy/3.1"],
  "udp_relay_ipv6": true,
  "zero_rtt_handshake": false,
  "dual_stack": true,
  "auth_timeout": "3s",
  "task_negotiation_timeout": "3s",
  "max_idle_time": "10s",
  "max_external_packet_size": 1500,
  "gc_interval": "3s",
  "gc_lifetime": "15s",
  "log_level": "warn"
}
EOF
    info "Configuration saved to $CONFIG_FILE"
}

# -------------------- Systemd Service --------------------

setup_service() {
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=TUIC v5 Server
Documentation=https://github.com/EAimTY/tuic
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=$INSTALL_DIR
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=$INSTALL_DIR/tuic-server -c $CONFIG_FILE
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable tuic >/dev/null 2>&1
    systemctl start tuic
    info "Systemd service created and started."
}

# -------------------- Show Result --------------------

show_result() {
    local port="$1"
    local password="$2"
    local uuid="$3"

    local public_ip
    public_ip=$(curl -sL https://api.ipify.org 2>/dev/null || curl -sL https://ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

    sleep 2
    if systemctl is-active --quiet tuic; then
        echo ""
        echo -e "${GREEN}======================================${NC}"
        echo -e "${GREEN}   TUIC v5 Installation Complete!     ${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo -e "  Server:     ${CYAN}$public_ip${NC}"
        echo -e "  Port:       ${CYAN}$port${NC}"
        echo -e "  UUID:       ${CYAN}$uuid${NC}"
        echo -e "  Password:   ${CYAN}$password${NC}"
        echo -e "  Congestion: ${CYAN}bbr${NC}"
        echo -e "  ALPN:       ${CYAN}h3,spdy/3.1${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo ""
        echo -e "${YELLOW}Client URL (NekoBox / v2rayN / Clash Meta):${NC}"
        echo -e "${CYAN}tuic://$uuid:$password@$public_ip:$port/?congestion_control=bbr&alpn=h3,spdy/3.1&udp_relay_mode=native&allow_insecure=1${NC}"
        echo ""
    else
        error "TUIC service failed to start. Check: systemctl status tuic"
    fi
}

# -------------------- Uninstall --------------------

uninstall_tuic() {
    warn "Uninstalling TUIC..."
    systemctl stop tuic 2>/dev/null || true
    systemctl disable tuic 2>/dev/null || true
    rm -rf "$INSTALL_DIR"
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    info "TUIC has been uninstalled."
}

# -------------------- Modify --------------------

modify_tuic() {
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Config file not found. Is TUIC installed?"
    fi

    local current_port
    current_port=$(jq -r '.server' "$CONFIG_FILE" | sed 's/\[::\]://')

    echo ""
    read -rp "New port (current: $current_port, press Enter to keep): " new_port
    [ -z "$new_port" ] && new_port="$current_port"

    local current_uuid
    current_uuid=$(jq -r '.users | keys[0]' "$CONFIG_FILE")
    local current_password
    current_password=$(jq -r ".users.\"$current_uuid\"" "$CONFIG_FILE")

    read -rp "New password (current: $current_password, press Enter to keep): " new_password
    [ -z "$new_password" ] && new_password="$current_password"

    jq ".server = \"[::]:$new_port\"" "$CONFIG_FILE" > /tmp/tuic_tmp.json && mv /tmp/tuic_tmp.json "$CONFIG_FILE"
    jq ".users = {\"$current_uuid\": \"$new_password\"}" "$CONFIG_FILE" > /tmp/tuic_tmp.json && mv /tmp/tuic_tmp.json "$CONFIG_FILE"

    systemctl restart tuic
    show_result "$new_port" "$new_password" "$current_uuid"
}

# -------------------- Main --------------------

main() {
    check_root

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     TUIC v5 One-Click Installer      ║${NC}"
    echo -e "${CYAN}║     github.com/ccj241                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""

    # If already installed, show management menu
    if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/tuic-server" ]; then
        warn "TUIC is already installed."
        echo ""
        echo "  1) Reinstall"
        echo "  2) Modify (port/password)"
        echo "  3) Uninstall"
        echo "  4) Show connection info"
        echo "  0) Exit"
        echo ""
        read -rp "Choose an option [0-4]: " choice
        case $choice in
            1) uninstall_tuic ;;
            2) modify_tuic; exit 0 ;;
            3) uninstall_tuic; exit 0 ;;
            4)
                local port uuid password
                port=$(jq -r '.server' "$CONFIG_FILE" | sed 's/\[::\]://')
                uuid=$(jq -r '.users | keys[0]' "$CONFIG_FILE")
                password=$(jq -r ".users.\"$uuid\"" "$CONFIG_FILE")
                show_result "$port" "$password" "$uuid"
                exit 0
                ;;
            0) exit 0 ;;
            *) error "Invalid option." ;;
        esac
    fi

    # Fresh install
    local auto_mode=false
    if [ "$1" = "--auto" ] || [ "$1" = "-a" ]; then
        auto_mode=true
    fi

    install_dependencies

    local server_arch
    server_arch=$(detect_arch)
    info "Detected architecture: $server_arch"

    download_tuic "$server_arch"
    generate_certs

    # Port & password
    local port password uuid

    if [ "$auto_mode" = true ]; then
        port=$((RANDOM % 55001 + 10000))
        password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 12 | head -n 1)
    else
        echo ""
        read -rp "Enter port (press Enter for random): " port
        [ -z "$port" ] && port=$((RANDOM % 55001 + 10000))
        read -rp "Enter password (press Enter for random): " password
        [ -z "$password" ] && password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 12 | head -n 1)
    fi

    uuid=$(uuidgen)
    if [ -z "$uuid" ]; then
        error "Failed to generate UUID."
    fi

    generate_config "$port" "$password" "$uuid"
    setup_service
    show_result "$port" "$password" "$uuid"
}

main "$@"
