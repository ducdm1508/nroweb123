param([int]$port = 8080)

# Allow firewall
try {
    New-NetFirewallRule -DisplayName "NRO Web Server $port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
} catch {}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".data" = "application/octet-stream"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".ico"  = "image/x-icon"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:$port/")
try {
    $listener.Start()
} catch {
    Write-Host "Loi khoi dong HttpListener: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Thu chay PowerShell duoi quyen Administrator." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " NRO WEB SERVER DANG CHAY TAI PORT $port !" -ForegroundColor Cyan
Write-Host " Truy cap tu may khac: http://47.129.2.246:$port" -ForegroundColor Yellow
Write-Host " Nhan Ctrl+C de dung server." -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Green

$rootDir = $PSScriptRoot
if (-not $rootDir) { $rootDir = (Get-Location).Path }

try {
    while ($listener.IsListening) {
        $context = $null
        try {
            $context = $listener.GetContext()
        } catch {
            if (-not $listener.IsListening) { break }
            continue
        }

        try {
            $request = $context.Request
            $response = $context.Response

            $rawUrl = [System.Uri]::UnescapeDataString($request.Url.LocalPath)
            if ($rawUrl -eq "/" -or $rawUrl -eq "") { $rawUrl = "/index.html" }
            $filePath = Join-Path $rootDir ($rawUrl.TrimStart("/").Replace("/", "\"))

            if (Test-Path $filePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $mime = "application/octet-stream"
                if ($mimeTypes.ContainsKey($ext)) { $mime = $mimeTypes[$ext] }

                $response.ContentType = $mime
                $response.AddHeader("Access-Control-Allow-Origin", "*")
                $response.AddHeader("Cache-Control", "no-cache")

                $fs = [System.IO.File]::OpenRead($filePath)
                try {
                    $response.ContentLength64 = $fs.Length
                    $buffer = New-Object byte[] 65536
                    while (($read = $fs.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $response.OutputStream.Write($buffer, 0, $read)
                    }
                } finally {
                    $fs.Close()
                }
                try { $response.Close() } catch {}
            } else {
                $response.StatusCode = 404
                try { $response.Close() } catch {}
            }
        } catch {
            # Client connection cancelled or aborted - do not crash server
            try { if ($context -and $context.Response) { $context.Response.Abort() } } catch {}
        }
    }
} finally {
    try { $listener.Stop() } catch {}
}
