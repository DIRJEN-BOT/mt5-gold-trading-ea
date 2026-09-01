#!/bin/bash
# Vilona Brand HUD + Pet - Installer for Linux/Wine

set -e

echo "=========================================="
echo " Vilona Brand HUD + Pet - Installation"
echo "=========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUND=0

# Find Wine MT5 data folders
for d in "$HOME/.wine/drive_c/users/"*/AppData/Roaming/MetaQuotes/Terminal/*/; do
    if [ -d "$d/MQL5/Experts" ]; then
        echo "Found MT5 terminal: $d"
        cp "$SCRIPT_DIR/Vilona_Brand_HUD.ex5" "$d/MQL5/Experts/"
        echo "  [OK] Copied Vilona_Brand_HUD.ex5 to Experts"
        FOUND=1
    fi
done

if [ "$FOUND" -eq 0 ]; then
    echo
    echo "[WARNING] No MT5 terminal data folder found under Wine."
    echo
    echo "Manual install:"
    echo "  1. Open MT5 -> File -> Open Data Folder"
    echo "  2. Navigate to MQL5/Experts/"
    echo "  3. Copy Vilona_Brand_HUD.ex5 there"
    echo
    echo "Or search manually:"
    echo "  ~/.wine/drive_c/users/*/AppData/Roaming/MetaQuotes/Terminal/*/MQL5/Experts/"
    echo
else
    echo
    echo "[SUCCESS] Installation complete!"
fi

echo
echo "=========================================="
echo "  HOW TO USE"
echo "=========================================="
echo
echo "1. Restart MetaTrader 5 (or right-click Navigator -> Refresh)"
echo "2. Drag Vilona_Brand_HUD onto any chart"
echo "3. Set these parameters:"
echo "   - InpBrandHUDOnly = true   (required -- disables trading)"
echo "   - InpPetEnabled   = true   (enables the Prabowo pet)"
echo "   - InpSoundEnabled = true   (enables entry/exit sounds)"
echo
echo "4. The HUD panel appears top-left of the chart"
echo "   showing equity, balance, margin, signal, sparkline + pet"
echo
echo "=========================================="
echo "  Bundle contents:"
echo "    Vilona_Brand_HUD.ex5     - The EA (just HUD, no trading)"
echo "    Vilona_Brand_HUD.mq5     - Open source (MQL5 source code)"
echo "    sounds/entry.wav         - Entry alert sound (copy to MQL5/Files/ as tgdh_open.wav/tgdh_tp.wav)"
echo "    sounds/exit.wav          - Exit alert sound (copy to MQL5/Files/ as tgdh_sl.wav/tgdh_profit.wav)"
echo "    screenshot.png           - What it looks like"
echo "=========================================="
echo
echo "Want the full Vilona trading strategy too?"
echo "Contact: Telegram @codergaboets / WhatsApp +6285732740006"
echo