
$RepoZipUrl = "https://github.com/tuantran19912512/Windows-tool-box/archive/refs/heads/main.zip"
$ZipFile = "$env:TEMP\VietToolbox_Download.zip"
$ExtractPath = "$env:TEMP\VietToolbox_Temp"

# 1. Tải và Giải nén
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipFile -UseBasicParsing
Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

$MainScript = "$ExtractPath\Windows-tool-box-main\main.ps1"

if (Test-Path $MainScript) {
    Set-Location (Split-Path $MainScript)
    
    # 2. Chạy Tool và gán vào một biến Process để theo dõi
    # Bỏ -WindowStyle Hidden để Toàn dễ debug, khi nào xong thì thêm lại sau
    $ToolProcess = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$MainScript`"" -Verb RunAs -PassThru
    
    Write-Host ">>> VIETTOOLBOX DANG CHAY. DUNG DONG CUA SO NAY DE TU DONG DON DEP KHI THOAT." -ForegroundColor Cyan
    
    # 3. Đợi cho đến khi Toàn đóng giao diện Tool
    $ToolProcess.WaitForExit()
    
    # 4. Sau khi đóng Tool -> Bắt đầu dọn dẹp sạch sẽ
    Write-Host ">>> DANG XOA CACHE VA SCRIPT TAM..." -ForegroundColor Yellow
    Set-Location $env:TEMP
    Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue
    
    Write-Host ">>> DA DON DEP SACH SE. CAM ON BAN DA SU DUNG!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}