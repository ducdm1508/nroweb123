[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CAP NHAT DRAGONBOY WEBGL BAN MOI NHAT LEN VPS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Dừng các tiến trình cũ
Write-Host "[1/5] Dung cac tien trinh cu tren port 8080 va 8081..." -ForegroundColor Yellow
Get-Process DragonProxy -ErrorAction SilentlyContinue | Stop-Process -Force
try {
    Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
} catch { }

# 2. Tải bản mới nhất từ GitHub
$zipPath = "$env:TEMP\nroweb_latest.zip"
$extractTemp = "$env:TEMP\nroweb_extract_temp"
$destDir = "C:\nroweb123"

Write-Host "[2/5] Dang tai ban build moi nhat tu GitHub..." -ForegroundColor Yellow
if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue }

Invoke-WebRequest -Uri "https://github.com/ducdm1508/nroweb123/archive/refs/heads/main.zip" -OutFile $zipPath

# 3. Giải nén và ghi đè
Write-Host "[3/5] Dang giai nen va cap nhat file..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}
Copy-Item "$extractTemp\nroweb123-main\*" -Destination $destDir -Recurse -Force

# Unblock tat ca cac file tai ve
Get-ChildItem -Path $destDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

# Dọn dẹp temp
Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# 4. Biên dịch DragonProxy.exe trực tiếp trên VPS
Write-Host "[4/5] Kiem tra va bien dich DragonProxy tren VPS..." -ForegroundColor Yellow
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}
if (Test-Path $csc) {
    & $csc /nologo /out:"$destDir\DragonProxy.exe" "$destDir\DragonProxy.cs"
}

# Cau hinh Firewall va URL ACL
netsh advfirewall firewall add rule name="DragonBoy Web Port 8080" dir=in action=allow protocol=TCP localport=8080 >$null 2>&1
netsh advfirewall firewall add rule name="DragonBoy Proxy Port 8081" dir=in action=allow protocol=TCP localport=8081 >$null 2>&1
netsh http delete urlacl url=http://*:8081/ >$null 2>&1
netsh http add urlacl url=http://*:8081/ user=Everyone >$null 2>&1

# 5. Khởi động lại Server
Write-Host "[5/5] KHOI DONG LAI SERVER TRANG WEB (8080) VA PROXY (8081)..." -ForegroundColor Green
Start-Process -FilePath "$destDir\DragonProxy.exe" -ArgumentList "8081" -WorkingDirectory $destDir
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$destDir\web_server.ps1`" -port 8080" -WorkingDirectory $destDir

Start-Sleep -Seconds 3
$p8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
$p8081 = Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue

Write-Host "==========================================================" -ForegroundColor Green
Write-Host ">> DA CAP NHAT THANH CONG BAN MOI NHAT!" -ForegroundColor Green
if ($p8080) {
    Write-Host ">> [OK] Server Web (Port 8080): DANG CHAY (PID: $($p8080.OwningProcess))" -ForegroundColor Green
} else {
    Write-Host ">> [CANH BAO] Server Web (Port 8080): CHUA KHOI DONG DUOC" -ForegroundColor Red
}
if ($p8081) {
    Write-Host ">> [OK] Proxy WebSocket (Port 8081): DANG CHAY (PID: $($p8081.OwningProcess))" -ForegroundColor Green
} else {
    Write-Host ">> [CANH BAO] Proxy WebSocket (Port 8081): CHUA KHOI DONG DUOC" -ForegroundColor Red
}
Write-Host ">> Link truy cap: http://47.129.2.246:8080/" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
