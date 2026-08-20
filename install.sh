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
            echo -e "  ${GREEN}Arch/CachyOS/Manjaro detected${NC}"
            sudo pacman -S --needed --noconfirm git curl dbus glib2 pkgconf base-devel plasma-sdk python3
            ;;
        apt)
            echo -e "  ${GREEN}Debian/Ubuntu/Kubuntu detected${NC}"
            sudo apt update -qq
            sudo apt install -y git curl libdbus-1-dev libglib2.0-dev pkg-config build-essential python3-dev python3-venv plasma-workspace-dev
            ;;
        dnf)
            echo -e "  ${GREEN}Fedora detected${NC}"
            sudo dnf install -y git curl dbus-devel glib2-devel pkgconf base-devel plasma-workspace python3-devel python3-dbus
            ;;
        zypper)
            echo -e "  ${GREEN}openSUSE detected${NC}"
            sudo zypper install -y git curl dbus-1-devel glib2-devel pkg-config plasma6-workspace-devel python3-devel python3-dbus-python
            ;;
        *)
            echo -e "${RED}  Unknown distro. Please manually install:${NC}"
            echo -e "    - git, curl"
            echo -e "    - dbus development libraries"
            echo -e "    - glib2 development libraries"
            echo -e "    - Python 3 development libraries"
            echo -e "    - KDE Plasma workspace development tools"
            exit 1
            ;;
    esac
    
    # Verify kpackagetool is available
    if ! command -v kpackagetool6 &>/dev/null && ! command -v kpackagetool5 &>/dev/null; then
        echo -e "${RED}  Error: kpackagetool not found after installing dependencies.${NC}"
        echo -e "  This usually means KDE Plasma is not installed."
        echo -e "  Please install KDE Plasma first, then run this script again."
        exit 1
    fi
}

install_deps

# ─── Install uv (Python package manager) ────────────────────────────────────
echo -e "\n${YELLOW}[2/4] Setting up Python environment (uv)...${NC}"
if ! command -v uv &>/dev/null; then
    echo -e "  Installing uv (Python package manager)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Verify uv is now available
if ! command -v uv &>/dev/null; then
    echo -e "${RED}  Error: Failed to install uv. Please install it manually:${NC}"
    echo -e "    curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo -e "    Then run this script again."
    exit 1
fi

echo -e "${GREEN}  ✓ uv: $(uv --version)${NC}"

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
KPACKAGETOOL=""
if command -v kpackagetool6 &>/dev/null; then
    KPACKAGETOOL="kpackagetool6"
elif command -v kpackagetool5 &>/dev/null; then
    KPACKAGETOOL="kpackagetool5"
else
    echo -e "${RED}  Error: kpackagetool not found. Please install plasma-workspace-dev or plasma-sdk.${NC}"
    exit 1
fi

if $KPACKAGETOOL -t Plasma/Applet -l 2>/dev/null | grep -q "$WIDGET_ID"; then
    $KPACKAGETOOL -t Plasma/Applet -u "$INSTALL_DIR/kde/v3"
    echo -e "${GREEN}  Widget updated.${NC}"
else
    $KPACKAGETOOL -t Plasma/Applet -i "$INSTALL_DIR/kde/v3"
    echo -e "${GREEN}  Widget installed.${NC}"
fi

# ─── Python venv + dependencies ──────────────────────────────────────────────
echo -e "\n${YELLOW}[4/4] Setting up Python backend...${NC}"
cd "$INSTALL_DIR/backend"

# Update uv
uv self update -q 2>/dev/null || true

# Detect Python version
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo -e "  Detected Python: ${PYTHON_VERSION}"

# Create virtual environment - try with detected version first, fallback to system default
echo -e "  Creating virtual environment..."
if ! uv venv --python "$PYTHON_VERSION" 2>/dev/null; then
    echo -e "  ${YELLOW}Trying with system Python...${NC}"
    if ! uv venv 2>/dev/null; then
        echo -e "${RED}  Error: Could not create virtual environment${NC}"
        echo -e "  Please ensure python3-venv is installed:"
        echo -e "    sudo apt install python3-venv  (Debian/Ubuntu)"
        echo -e "    sudo pacman -S python-virtualenv  (Arch)"
        exit 1
    fi
fi

# Install Python dependencies
echo -e "  Installing Python dependencies..."
if ! uv pip install -q websockets==15.0.1 dbus-python==1.4.0; then
    echo -e "${RED}  Error: Failed to install Python dependencies${NC}"
    echo -e "  This usually means dbus-python compilation failed."
    echo -e "  Please ensure dbus development libraries are installed:"
    echo -e "    sudo apt install libdbus-1-dev libglib2.0-dev  (Debian/Ubuntu)"
    echo -e "    sudo pacman -S dbus glib2  (Arch)"
    exit 1
fi

echo -e "${GREEN}  ✓ Python environment ready${NC}"

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
if command -v kquitapp6 &>/dev/null; then
    kquitapp6 plasmashell 2>/dev/null || true
elif command -v kquitapp5 &>/dev/null; then
    kquitapp5 plasmashell 2>/dev/null || true
fi
sleep 1
if command -v kstart6 &>/dev/null; then
    kstart6 plasmashell &>/dev/null &
elif command -v kstart &>/dev/null; then
    kstart plasmashell &>/dev/null &
else
    plasmashell &>/dev/null &
fi
echo -e "${GREEN}Plasma shell restarted. The widget is now available.${NC}"
echo ""
