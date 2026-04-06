# ==============================================================================
# VIETTOOLBOX CLOUD DEPLOYMENT - WINTOHDD + GDRIVE API + ANYDESK
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# ---------------------------------------------------------
# [1] CƠ SỞ DỮ LIỆU TỪ NGƯỜI DÙNG
# ---------------------------------------------------------
$List_Base64_Keys = @(
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR",
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v",
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv",
    "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR",
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
)

$ID_WintoHDD = "1vSF9E01LdZcbogjq-G38Vtu_8Zp34VBG"
$ID_Windows  = "1PKIcsxouFraj1LNeAHfTshvWR7vi0-Xb"
$OS_Edition  = "Windows 11 Home Single Language" # Tên chính xác trong file WIM

$TempDir = "C:\VietCloud"
if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory -Force | Out-Null }

# ---------------------------------------------------------
# [2] HÀM TẢI FILE TỪ GOOGLE DRIVE (BYPASS SCAN VIRUS)
# ---------------------------------------------------------
function Download-GDrive {
    param ($FileID, $SavePath)
    $RandomKey = $List_Base64_Keys[(Get-Random -Minimum 0 -Maximum $List_Base64_Keys.Count)]
    $Key = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($RandomKey))
    
    Write-Host "[+] Dang tai ID: $FileID..." -ForegroundColor Cyan
    $Url = "https://www.googleapis.com/drive/v3/files/$FileID`?alt=media&key=$Key"
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $SavePath -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        Write-Host "[!] Loi tai file, dang thu lai voi Key khac..." -ForegroundColor Red
        return $false
    }
}

# ---------------------------------------------------------
# [3] THỰC THI QUY TRÌNH
# ---------------------------------------------------------
Write-Host ">>> KHOI CHAY QUY TRINH CAI WIN ONLINE <<<" -ForegroundColor Green

# 1. Tải WinToHDD
$WTH_Path = "$TempDir\WintoHDD_Setup.exe"
if (!(Download-GDrive -FileID $ID_WintoHDD -SavePath $WTH_Path)) { exit }

# 2. Cài đặt WinToHDD ngầm
Write-Host "[+] Dang cai dat WinToHDD..." -ForegroundColor Yellow
Start-Process $WTH_Path -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES" -Wait

# 3. Tải Windows Image
$WinFile = "$TempDir\install.wim"
Write-Host "[+] Dang tai Windows 11 HSL (Dung luong lon, vui long doi)..." -ForegroundColor Yellow
Download-GDrive -FileID $ID_Windows -SavePath $WinFile

# 4. Tạo script AnyDesk tự chạy (SetupComplete)
$ScriptPath = "$TempDir\SetupComplete.cmd"
@"
@echo off
:net
ping 8.8.8.8 -n 1 >nul
if errorlevel 1 (timeout /t 5 >nul & goto net)
curl -L -o "%public%\Desktop\AnyDesk.exe" "https://download.anydesk.com/AnyDesk.exe"
start "" "%public%\Desktop\AnyDesk.exe"
rd /s /q "C:\VietCloud"
del "%~f0"
"@ | Out-File $ScriptPath -Encoding ASCII

# 5. Tiêm AnyDesk vào file WIM (Yêu cầu Windows có sẵn DISM)
Write-Host "[+] Dang inject AnyDesk vao Image..." -ForegroundColor Magenta
$Mount = "$TempDir\Mount"
New-Item $Mount -ItemType Directory -Force | Out-Null
Mount-WindowsImage -ImagePath $WinFile -Index 1 -Path $Mount | Out-Null
$TargetDir = "$Mount\Windows\Setup\Scripts"
if (!(Test-Path $TargetDir)) { New-Item $TargetDir -ItemType Directory -Force | Out-Null }
Copy-Item $ScriptPath -Destination "$TargetDir\SetupComplete.cmd" -Force
Dismount-WindowsImage -Path $Mount -Save | Out-Null

# 6. Ra lệnh cho WinToHDD cài máy
Write-Host ">>> MOI THU DA SAN SANG. KHOI DONG WINTOHDD..." -ForegroundColor Green
$WTH_Exe = "C:\Program Files\Hasleo\WinToHDD\bin\WinToHDD_x64.exe"
if (!(Test-Path $WTH_Exe)) { $WTH_Exe = "C:\Program Files\Hasleo\WinToHDD\bin\WinToHDD.exe" }

# Lệnh Reinstall: /i (file nguồn), /v (phiên bản), /b (tự động boot), /r (tự khởi động lại)
Start-Process $WTH_Exe -ArgumentList "/m Reinstall /i `"$WinFile`" /v `"$OS_Edition`" /b /r"

Write-Host "Script ket thuc. May se restart sau giay lat." -ForegroundColor White