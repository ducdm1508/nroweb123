@echo off
title DragonBoy WebGL - Server Launcher (Port 8080 & 8081)
cd /d "%~dp0"

echo ==========================================================
echo        DRAGONBOY WEBGL - SERVER LAUNCHER
echo ==========================================================
echo [*] Dang don dep cac tien trinh cu tren port 8080 va 8081...

:: Dung cac tien trinh cu
taskkill /f /im DragonProxy.exe >nul 2>&1
powershell -Command "try { Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1
powershell -Command "try { Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1

:: Kiem tra va bien dich DragonProxy.exe neu chua co
if not exist "%~dp0DragonProxy.exe" (
    echo [*] Dang bien dich DragonProxy.exe...
    set CSC_PATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
    if not exist "!CSC_PATH!" set CSC_PATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe
    %CSC_PATH% /nologo /out:"%~dp0DragonProxy.exe" "%~dp0DragonProxy.cs"
)

:: Cau hinh Firewall va URL ACL
echo [*] Cau hinh Firewall va cap quyen URL ACL...
netsh advfirewall firewall add rule name="DragonBoy Web Port 8080" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
netsh advfirewall firewall add rule name="DragonBoy Proxy Port 8081" dir=in action=allow protocol=TCP localport=8081 >nul 2>&1
netsh http delete urlacl url=http://*:8081/ >nul 2>&1
netsh http add urlacl url=http://*:8081/ user=Everyone >nul 2>&1

:: Khoi dong Proxy WebSocket (Port 8081)
echo [*] Dang khoi dong Proxy WebSocket tren Port 8081...
start "DragonBoy WebSocket Proxy (Port 8081)" "%~dp0DragonProxy.exe" 8081

:: Khoi dong Web Server (Port 8080)
echo [*] Dang khoi dong Web Server tren Port 8080...
start "DragonBoy Web Server (Port 8080)" powershell -ExecutionPolicy Bypass -NoExit -File "%~dp0web_server.ps1" -port 8080

timeout /t 2 /nobreak >nul

echo ==========================================================
echo [OK] DA KHOI DONG THANH CONG CAC DICH VU:
echo  - Web Game : http://47.129.2.246:8080/
echo  - WS Proxy : ws://47.129.2.246:8081/
echo ==========================================================
echo Luu y: Giu 2 cua so Proxy va Web Server chay ngam de nguoi choi ket noi.
echo Nhan phim bat ky de thoat bang dieu khien nay (cac server van tiep tuc chay).
pause >nul
