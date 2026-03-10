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

Write-Host ">>> DANG KHOI TAO MOI TRUONG ADMIN (VIETTOOLBOX PRO)..." -ForegroundColor Magenta

# Cấu hình đường dẫn tạm
$RepoZipUrl = "https://github.com/tuantran19912512/Windows-tool-box/archive/refs/heads/main.zip"
$ZipFile = "$env:TEMP\VietToolbox_Admin_Download.zip"
$ExtractPath = "$env:TEMP\VietToolbox_Admin_Temp"

# [4] DỌN DẸP RÁC CŨ NẾU CÓ
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }

# [5] TẢI FILE
Write-Host "-> Dang tai du lieu he thong..." -ForegroundColor Yellow
$webClient = New-Object System.Net.WebClient
try {
    $webClient.DownloadFile($RepoZipUrl, $ZipFile)
} catch {
    Write-Host "!!! LOI: Khong the ket noi Github. Kiem tra mang!" -ForegroundColor Red
    pause
    exit
}

# [6] GIAI NÉN VÀ CHẠY BẢN ADMIN
Write-Host "-> Dang giai nen va nap quyen Admin..." -ForegroundColor Yellow
Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

# 🚨 CHỖ THAY ĐỔI QUAN TRỌNG NHẤT: Tìm file main_admin.ps1 thay vì main.ps1
$MainScript = Get-ChildItem -Path "$ExtractPath\main_admin.ps1" -Recurse | Select-Object -First 1

if ($MainScript) {
    Set-Location $MainScript.Directory.FullName
    
    # Chạy bản Admin và chờ thoát
    Write-Host ">>> DANG MO BANG DIEU KHIEN ADMIN. VUI LONG CHO..." -ForegroundColor Cyan
    $ToolProcess = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MainScript.FullName)`"" -PassThru
    
    Write-Host ">>> VIETTOOLBOX ADMIN DANG CHAY..." -ForegroundColor Magenta
    $ToolProcess.WaitForExit()
    
    # [7] DỌN DẸP
    Write-Host "-> Dang xoa du lieu tam..." -ForegroundColor Cyan
    Set-Location $env:TEMP
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    Write-Host ">>> DA DON DEP. TAM BIET BOSS TUAN!" -ForegroundColor Green
    Start-Sleep -Seconds 2
} else {
    Write-Host "!!! LOI: Khong tim thay file main_admin.ps1 trong Repo!" -ForegroundColor Red
    pause
}