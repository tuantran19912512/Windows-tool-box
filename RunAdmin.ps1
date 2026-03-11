Clear-Host
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [1] KIỂM TRA QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://maclife.vn/admintools | iex`"" -Verb RunAs
    exit
}

Write-Host ">>> DANG KHOI TAO MOI TRUONG ADMIN (V185) - CHONG KET FILE..." -ForegroundColor Magenta

# 🚨 CHIÊU MỚI: TẠO TÊN THƯ MỤC RIÊNG BIỆT THEO GIÂY ĐỂ KHÔNG BỊ TRÙNG
$TimeID = Get-Date -Format "HHmmss"
$RepoZipUrl = "https://github.com/tuantran19912512/Windows-tool-box/archive/refs/heads/main.zip"
$ZipFile = "$env:TEMP\VT_Admin_$TimeID.zip"
$ExtractPath = "$env:TEMP\VT_Admin_$TimeID"

# [2] TẢI VÀ GIẢI NÉN VÀO THƯ MỤC MỚI TINH
Write-Host "-> Dang tai du lieu moi..." -ForegroundColor Yellow
$webClient = New-Object System.Net.WebClient
try {
    $webClient.DownloadFile($RepoZipUrl, $ZipFile)
    # Tạo thư mục trước khi giải nén
    New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force
} catch {
    Write-Host "!!! LOI KET NOI GITHUB HOAC FILE DANG BI KHOA!" -ForegroundColor Red; pause; exit
}

# [3] TÌM VÀ CHẠY FILE ADMIN
$MainScript = Get-ChildItem -Path "$ExtractPath\main_admin.ps1" -Recurse | Select-Object -First 1

if ($MainScript) {
    Set-Location $MainScript.Directory.FullName
    Write-Host ">>> VIETTOOLBOX ADMIN DANG KICH HOAT..." -ForegroundColor Cyan
    
    # Chạy Tool
    & $MainScript.FullName
    
    # [4] DỌN DẸP SAU KHI ĐÓNG TOOL
    # Chờ 1 chút để giải phóng file ảnh trước khi xóa
    Start-Sleep -Seconds 1
    Set-Location $env:TEMP
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    Write-Host ">>> DA DON DEP SACH SE. CHAO BOSS!" -ForegroundColor Green
} else {
    Write-Host "!!! LOI: Khong tim thay main_admin.ps1!" -ForegroundColor Red; pause
}