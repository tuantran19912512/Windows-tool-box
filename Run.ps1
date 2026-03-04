# ============================================================================
# SCRIPT TỰ ĐỘNG TẢI & CHẠY VIETTOOLBOX TỪ GITHUB
# ============================================================================
Write-Host ">>> DANG TAI VIETTOOLBOX TU GITHUB..." -ForegroundColor Cyan

# Link tải toàn bộ Repo dưới dạng file ZIP (nhánh main)
$RepoZipUrl = "https://github.com/tuantran19912512/Windows-tool-box/archive/refs/heads/main.zip"
$ZipFile = "$env:TEMP\VietToolbox_Download.zip"
$ExtractPath = "$env:TEMP\VietToolbox_Temp"

# Tải file ZIP về thư mục Temp
Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipFile -UseBasicParsing

# Dọn dẹp thư mục cũ nếu có và Giải nén
if (Test-Path $ExtractPath) { Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host ">>> DANG GIAI NEN DU LIEU..." -ForegroundColor Yellow
Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

# Tìm file main.ps1 bên trong thư mục vừa giải nén (Tên thư mục thường thêm đuôi -main)
$MainScript = "$ExtractPath\Windows-tool-box-main\main.ps1"

if (Test-Path $MainScript) {
    Write-Host ">>> DANG KHOI DONG GIAO DIEN TOOL..." -ForegroundColor Green
    # Chuyển hướng làm việc vào đúng thư mục giải nén để Tool nhận diện được mục Scripts, Data
    Set-Location (Split-Path $MainScript)
    
    # Kích hoạt Tool với quyền Bypass và ẩn cửa sổ nền đen
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$MainScript`"" -Verb RunAs
} else {
    Write-Host "!!! LOI: Khong tim thay file main.ps1. Vui long kiem tra lai cau truc GitHub." -ForegroundColor Red
}

# Dọn dẹp file ZIP rác
Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue