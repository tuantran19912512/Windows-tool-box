clear
# [1] TẮT THANH TIẾN TRÌNH ĐỂ TĂNG TỐC TẢI GẤP 10 LẦN
$ProgressPreference = 'SilentlyContinue'

# [2] ÉP DÙNG TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [3] KIỂM TRA QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host ">>> Dang khoi tao moi truong lam viec vui long doi..." -ForegroundColor Cyan

# Cấu hình đường dẫn tạm
$RepoZipUrl = "https://github.com/tuantran19912512/Windows-tool-box/archive/refs/heads/main.zip"
$ZipFile = "$env:TEMP\VietToolbox_Download.zip"
$ExtractPath = "$env:TEMP\VietToolbox_Temp"

# [4] DỌN DẸP RÁC CŨ NẾU CÓ
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }

# [5] TẢI FILE VỚI TỐC ĐỘ TỐI ĐA (DÙNG WEBCLIENT CHO NHẸ)
Write-Host "-> Dang tai du lieu (3.5MB)..." -ForegroundColor Yellow
$webClient = New-Object System.Net.WebClient
try {
    $webClient.DownloadFile($RepoZipUrl, $ZipFile)
} catch {
    Write-Host "!!! LOI: Khong the ket noi may chu. Kiem tra Internet!" -ForegroundColor Red
    pause
    exit
}

# [6] GIAI NÉN VÀ CHẠY TOOL
Write-Host "-> Dang giai nen va cau hinh..." -ForegroundColor Yellow
Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

$MainScript = Get-ChildItem -Path "$ExtractPath\main.ps1" -Recurse | Select-Object -First 1

if ($MainScript) {
    Set-Location $MainScript.Directory.FullName
    
    # Chạy Tool và chờ cho đến khi đóng Tool mới dọn dẹp
    $ToolProcess = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MainScript.FullName)`"" -PassThru
    
    Write-Host ">>> VIETTOOLBOX DANG CHAY. VUI LONG KHONG DONG CUA SO NAY..." -ForegroundColor Green
    $ToolProcess.WaitForExit()
    
    # [7] DỌN DẸP SAU KHI THOÁT
    Write-Host "-> Dang don dep rac he thong..." -ForegroundColor Cyan
    Set-Location $env:TEMP
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    Write-Host ">>> DA DON DEP SACH SE. TAM BIET!" -ForegroundColor Green
    Start-Sleep -Seconds 2
} else {
    Write-Host "!!! LOI: Khong tim thay file main.ps1 trong bo tai ve!" -ForegroundColor Red
    pause
}