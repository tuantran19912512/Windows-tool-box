# ==============================================================================
# VIETTOOLBOX: SIÊU TỐI ƯU (V64.0 - PROCESS REDUCER)
# Chức năng: Chặn App chạy ngầm, Gỡ rác, Tắt Service thừa, Giảm Handle.
# ==============================================================================

# --- BƯỚC 0: XÁC NHẬN ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$Confirm = [System.Windows.Forms.MessageBox]::Show("Tiến trình SIÊU TỐI ƯU (giảm giật lag) sắp bắt đầu.`n`nQuá trình này sẽ gỡ app rác và tắt các tiến trình thừa.`nÔng có muốn tiếp tục không?", "VietToolbox: Xác nhận", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
if ($Confirm -eq "No") { exit }

# --- BƯỚC 1: QUYỀN ADMIN ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    break
}

# --- HÀM PHỤ TRỢ ---
function Ghi-Log-Internal($msg) {
    if (Get-Command "Ghi-Log" -ErrorAction SilentlyContinue) { Ghi-Log "Tối Ưu: $msg" }
    Write-Host "[Optimize] $msg" -ForegroundColor Cyan
}

function Chay-Reg($Path, $Name, $Value, $Type = "DWord") {
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
}

Ghi-Log-Internal "=========================================================="
Ghi-Log-Internal ">>> ĐANG GIẢM TẢI HỆ THỐNG & TRIỆT TIÊU TIẾN TRÌNH <<<"
Ghi-Log-Internal "=========================================================="

# 1. CHẶN APP CHẠY NGẦM (QUAN TRỌNG NHẤT ĐỂ GIẢM PROCESS)
Ghi-Log-Internal "[1/6] Đang chặn toàn bộ ứng dụng chạy ngầm trái phép..."
Chay-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
Chay-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0 # Tắt Search Box nặng nề
Chay-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0

# 2. QUYỀN RIÊNG TƯ & THEO DÕI
Ghi-Log-Internal "[2/6] Đang khóa các tiến trình Telemetry (Theo dõi)..."
$RegPrivacy = @(
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\System", "EnableActivityFeed", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\System", "PublishUserActivities", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent", "DisableWindowsConsumerFeatures", 1),
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo", "Enabled", 0)
)
foreach ($item in $RegPrivacy) { Chay-Reg $item[0] $item[1] $item[2] }

# 3. VÔ HIỆU HÓA DỊCH VỤ THỪA (GIẢM HANDLES)
Ghi-Log-Internal "[3/6] Đang khai tử các dịch vụ rác..."
$DisabledSvcs = @("DiagTrack", "dmwappushservice", "RemoteRegistry", "UevAgentService", "SysMain", "WSearch", "MapsBroker", "XblAuthManager", "XblGameSave", "XboxGipSvc")
foreach ($s in $DisabledSvcs) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service -Name $s -StartupType Disabled
        Ghi-Log-Internal "  [-] Đã khóa: $s"
    }
}

# 4. GỠ BỎ APPX RÁC (BLOATWARE)
Ghi-Log-Internal "[4/6] Đang quét sạch App rác (Bloatware)..."
$BloatApps = @("*MicrosoftEdge*", "*YourPhone*", "*GetHelp*", "*ZuneVideo*", "*BingNews*", "*BingWeather*", "*SkypeApp*", "*Office.OneNote*", "*MixedReality.Portal*")
foreach ($app in $BloatApps) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# 5. DỌN DẸP RÁC HỆ THỐNG
Ghi-Log-Internal "[5/6] Đang dọn dẹp các ổ rác tạm thời..."
$CacO_Rac = @($env:TEMP, "C:\Windows\Temp", "C:\Windows\Prefetch")
foreach ($ThuMuc in $CacO_Rac) {
    if (Test-Path $ThuMuc) {
        Get-ChildItem -Path $ThuMuc -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# 6. TỐI ƯU GAMING & POWER
Ghi-Log-Internal "[6/6] Đang bung hiệu năng Power High Performance..."
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Chay-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0

# --- KẾT THÚC ---
Ghi-Log-Internal "🏁 TỐI ƯU HOÀN TẤT!"

$FinishMsg = "Hệ thống đã được tối ưu!`n`n- Đã chặn App chạy ngầm.`n- Đã gỡ Bloatware.`n- Đã tắt Service thừa.`n`nVui lòng khởi động lại máy để áp dụng!"
[System.Windows.Forms.MessageBox]::Show($FinishMsg, "VietToolbox: Xong!")