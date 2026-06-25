#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="$HOME/.local/share/lyrics-on-panel"
SERVICE_NAME="Universal-Mpris-LyricServer"
WIDGET_ID="lyrics-on-panel-plasma6-v3"

echo -e "${RED}"
echo "  Lyrics-on-Panel v3 — Uninstaller"
echo -e "${NC}"

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run as root.${NC}"
    exit 1
fi

# ─── Stop & disable systemd service ─────────────────────────────────────────
echo -e "${YELLOW}[1/3] Stopping backend service...${NC}"
if systemctl --user is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
    systemctl --user stop "${SERVICE_NAME}"
    echo -e "  Service stopped."
fi

if systemctl --user is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
    systemctl --user disable "${SERVICE_NAME}"
    echo -e "  Service disabled."
fi

if [ -f "$HOME/.config/systemd/user/${SERVICE_NAME}.service" ]; then
    rm "$HOME/.config/systemd/user/${SERVICE_NAME}.service"
    systemctl --user daemon-reload
    echo -e "  Service file removed."
fi

# ─── Remove KDE widget ────────────────────────────────────────────────────────
echo -e "\n${YELLOW}[2/3] Removing KDE widget...${NC}"
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "${WIDGET_ID}"; then
    kpackagetool6 -t Plasma/Applet -r "${WIDGET_ID}"
    echo -e "  Widget removed."
else
    echo -e "  Widget not found, skipping."
fi

# ─── Remove backend files ─────────────────────────────────────────────────────
echo -e "\n${YELLOW}[3/3] Removing backend files...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "  Removed: $INSTALL_DIR"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Uninstallation complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo ""
echo -e "  The widget and all backend files have been removed."
echo -e "  You may need to ${YELLOW}restart your panel${NC} for changes to take effect:"
echo -e "  ${YELLOW}killall plasmashell; kstart plasmashell${NC}"
echo ""
