#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/bogeta329/lyrics-on-panel-v3"
INSTALL_DIR="$HOME/.local/share/lyrics-on-panel"
SERVICE_NAME="Universal-Mpris-LyricServer"
WIDGET_ID="lyrics-on-panel-plasma6-v3"

echo -e "${BLUE}"
echo "  ██╗     ██╗   ██╗██████╗ ██╗ ██████╗███████╗"
echo "  ██║     ╚██╗ ██╔╝██╔══██╗██║██╔════╝██╔════╝"
echo "  ██║      ╚████╔╝ ██████╔╝██║██║     ███████╗"
echo "  ██║       ╚██╔╝  ██╔══██╗██║██║     ╚════██║"
echo "  ███████╗   ██║   ██║  ██║██║╚██████╗███████║"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝"
echo -e "${NC}"
echo -e "${GREEN}  Lyrics-on-Panel v3 — One-click Installer${NC}"
echo -e "  ${YELLOW}Tested on: CachyOS (Arch-based) + KDE Plasma 6.7.1${NC}"
echo ""

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run as root.${NC}"
    exit 1
fi

# ─── Detect package manager ─────────────────────────────────────────────────
detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)

install_deps() {
    echo -e "\n${YELLOW}[1/4] Installing system dependencies...${NC}"
    case "$PKG_MANAGER" in
        pacman)
            sudo pacman -S --needed --noconfirm git curl dbus glib2 pkgconf base-devel plasma-sdk
            ;;
        apt)
            echo -e "${YELLOW}  ⚠ Debian/Ubuntu detected — untested. Trying anyway...${NC}"
            sudo apt update -qq
            sudo apt install -y git curl libdbus-1-dev libglib2.0-dev pkg-config build-essential plasma-sdk python3-dev
            ;;
        dnf)
            echo -e "${YELLOW}  ⚠ Fedora detected — untested. Trying anyway...${NC}"
            sudo dnf install -y git curl dbus-devel glib2-devel pkgconf base-devel plasma-sdk python3-devel
            ;;
        zypper)
            echo -e "${YELLOW}  ⚠ openSUSE detected — untested. Trying anyway...${NC}"
            sudo zypper install -y git curl dbus-1-devel glib2-devel pkg-config plasma-sdk python3-devel
            ;;
        *)
            echo -e "${RED}  Unknown distro. Please manually install: git, curl, dbus-dev, plasma-sdk, python3-dev${NC}"
            exit 1
            ;;
    esac
}

install_deps

# ─── Install uv (Python package manager) ────────────────────────────────────
echo -e "\n${YELLOW}[2/4] Setting up Python environment (uv)...${NC}"
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi
echo -e "${GREEN}  uv: $(uv --version)${NC}"

# ─── Clone / update repo ─────────────────────────────────────────────────────
echo -e "\n${YELLOW}[3/4] Setting up files...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "  Existing installation found, updating..."
    git -C "$INSTALL_DIR" pull --ff-only
else
    rm -rf "$INSTALL_DIR"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# ─── Install KDE widget ───────────────────────────────────────────────────────
echo -e "\n  Installing KDE widget..."
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$WIDGET_ID"; then
    kpackagetool6 -t Plasma/Applet -u "$INSTALL_DIR/kde/v3"
    echo -e "${GREEN}  Widget updated.${NC}"
else
    kpackagetool6 -t Plasma/Applet -i "$INSTALL_DIR/kde/v3"
    echo -e "${GREEN}  Widget installed.${NC}"
fi

# ─── Python venv + dependencies ──────────────────────────────────────────────
echo -e "\n${YELLOW}[4/4] Setting up Python backend...${NC}"
cd "$INSTALL_DIR/backend"
uv self update -q
uv venv --python 3.13 2>/dev/null || uv venv
uv pip install -q websockets==15.0.1 dbus-python==1.4.0

# Create launcher
cat > "$INSTALL_DIR/backend/run.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
exec python src/server.py
EOF
chmod +x "$INSTALL_DIR/backend/run.sh"

# ─── Systemd service ─────────────────────────────────────────────────────────
echo -e "\n  Setting up systemd service..."
mkdir -p "$HOME/.config/systemd/user"

cat > "$HOME/.config/systemd/user/${SERVICE_NAME}.service" << EOF
[Unit]
Description=Lyrics-on-Panel MPRIS2 Backend
After=graphical-session.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/backend/run.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now "${SERVICE_NAME}.service"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Installation complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo ""
echo -e "  Next step: right-click your panel → ${YELLOW}Add Widgets${NC}"
echo -e "  Search for: ${YELLOW}lyrics-on-panel-plasma6-v3${NC}"
echo ""
echo -e "  Backend status: ${BLUE}systemctl --user status ${SERVICE_NAME}${NC}"
echo -e "  Live logs:      ${BLUE}journalctl --user -u ${SERVICE_NAME} -f${NC}"
echo ""

# ─── Restart plasma shell ─────────────────────────────────────────────────────
echo -e "${YELLOW}Restarting KDE Plasma shell...${NC}"
kquitapp6 plasmashell 2>/dev/null || true
sleep 1
kstart plasmashell &>/dev/null &
echo -e "${GREEN}Plasma shell restarted. The widget is now available.${NC}"
echo ""
