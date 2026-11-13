#!/bin/bash
# ========================================================
# Script khoi chay Web Server cho DragonBoy WebGL
# Chay duoc tren ca Git Bash (Windows) va Linux VPS
# ========================================================

PORT=8080
GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===================================================="
echo "    KHOI CHAY DRAGONBOY WEB SERVER (PORT $PORT)    "
echo "===================================================="
echo "Thu muc game: $GAME_DIR"

# Kiem tra Python
if command -v python3 &>/dev/null; then
    PY_CMD="python3"
elif command -v python &>/dev/null; then
    PY_CMD="python"
elif command -v py &>/dev/null; then
    PY_CMD="py"
else
    echo "[!] Khong tim thay Python tren he thong!"
    echo "    Vui long cai dat Python hoac dung Node.js: npx serve -l $PORT"
    exit 1
fi

echo "[+] Dang chay Web Server bang $PY_CMD..."
echo "[+] Truy cap Cuc bo: http://localhost:$PORT"
echo "[+] Truy cap Tu xa : http://<IP_VPS_CUA_BAN>:$PORT"
echo "----------------------------------------------------"
echo "Nhan Ctrl + C de dung Web Server."
echo "===================================================="

cd "$GAME_DIR"
$PY_CMD -m http.server $PORT
