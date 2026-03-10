# [1] DÒNG TRÊN LÀ KHOẢNG TRẮNG ĐỂ NÉ LỖI KÝ TỰ LẠ
Clear-Host
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [2] KIỂM TRA QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://maclife.vn/admintools | iex`"" -Verb RunAs
    exit
}

Write-Host ">>> DANG KHOI TAO MOI TRUONG ADMIN (VIETTOOLBOX PRO)..." -ForegroundColor Magenta

# Cấu hình đường dẫn tạm
$RepoZipUrl = "https://github.com/tuantran19912512/Windows-tool-box/archive/refs/heads/main.zip"
$ZipFile = "$env:TEMP\VT_Admin.zip"
$ExtractPath = "$env:TEMP\VT_Admin_Ext"

# [3] DỌN DẸP RÁC CŨ
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recit -Force -ErrorAction SilentlyContinue }

# [4] TẢI VÀ GIẢI NÉN
Write-Host "-> Dang tai va giai nen du lieu..." -ForegroundColor Yellow
$webClient = New-Object System.Net.WebClient
try {
    $webClient.DownloadFile($RepoZipUrl, $ZipFile)
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force
} catch {
    Write-Host "!!! LOI KET NOI GITHUB!" -ForegroundColor Red; pause; exit
}

# [5] TÌM VÀ CHẠY FILE ADMIN
$MainScript = Get-ChildItem -Path "$ExtractPath\main_admin.ps1" -Recurse | Select-Object -First 1

if ($MainScript) {
    Set-Location $MainScript.Directory.FullName
    Write-Host ">>> VIETTOOLBOX ADMIN DANG KICH HOAT..." -ForegroundColor Cyan
    & $MainScript.FullName
    
    # [6] DỌN DẸP SAU KHI ĐÓNG
    Set-Location $env:TEMP
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    Write-Host ">>> DA DON DEP. TAM BIET BOSS TUAN!" -ForegroundColor Green
} else {
    Write-Host "!!! LOI: Khong tim thay main_admin.ps1!" -ForegroundColor Red; pause
}