@echo off
title DragonBoy WebGL - Full Server Launcher (Port 8080 & 8081)
cd /d "%~dp0"

echo ==========================================================
echo       DRAGONBOY WEBGL SERVER + WEBSOCKET PROXY
echo ==========================================================
echo [1/3] Adding Firewall rules for Port 8080 and 8081...
netsh advfirewall firewall add rule name="DragonBoy Web Port 8080" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
netsh advfirewall firewall add rule name="DragonBoy Proxy Port 8081" dir=in action=allow protocol=TCP localport=8081 >nul 2>&1
netsh http add urlacl url=http://*:8081/ user=Everyone >nul 2>&1

echo [2/3] Starting WebSocket-to-TCP Proxy on Port 8081...
start "DragonBoy Proxy (Port 8081)" "%~dp0DragonProxy.exe" 8081

echo [3/3] Starting Web Server on Port 8080...
powershell -ExecutionPolicy Bypass -File "%~dp0web_server.ps1" -port 8080
pause
