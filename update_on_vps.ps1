[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CAP NHAT DRAGONBOY WEBGL BAN MOI NHAT LEN VPS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Dừng các tiến trình cũ
Write-Host "[1/4] Dung cac tien trinh cu dang chay..." -ForegroundColor Yellow
Get-Process DragonProxy -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Tải bản mới nhất từ GitHub
$zipPath = "$env:TEMP\nroweb_latest.zip"
$extractTemp = "$env:TEMP\nroweb_extract_temp"
$destDir = "C:\nroweb123"

Write-Host "[2/4] Dang tai ban build moi nhat tu GitHub..." -ForegroundColor Yellow
if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue }

Invoke-WebRequest -Uri "https://github.com/ducdm1508/nroweb123/archive/refs/heads/main.zip" -OutFile $zipPath

# 3. Giải nén và ghi đè
Write-Host "[3/4] Dang giai nen va cap nhat file..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}
Copy-Item "$extractTemp\nroweb123-main\*" -Destination $destDir -Recurse -Force

# Dọn dẹp temp
Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# 4. Khởi động lại Server
Write-Host "[4/4] KHOI DONG LAI SERVER TRANG WEB (8080) VA PROXY (8081)..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ">> DA CAP NHAT THANH CONG BAN MOI NHAT!" -ForegroundColor Green
Write-Host ">> Link truy cap: http://47.129.2.246:8080/" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green

Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd /d C:\nroweb123 && start_server.bat"
