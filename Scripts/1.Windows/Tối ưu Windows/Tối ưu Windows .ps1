Add-Type -AssemblyName System.Windows.Forms

Ghi-Log "=========================================================="
Ghi-Log ">>> ĐANG ÁP DỤNG BỘ CẤU HÌNH TỐI ƯU <<<"
Ghi-Log "=========================================================="

# --- HÀM PHỤ TRỢ ---
function Chay-Reg($Path, $Name, $Value, $Type = "DWord") {
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
    [System.Windows.Forms.Application]::DoEvents()
}

# 1. QUYỀN RIÊNG TƯ & THEO DÕI (PRIVACY & TELEMETRY)
Ghi-Log "[1/3] Đang khóa các tiến trình theo dõi và thu thập dữ liệu..."
$RegPrivacy = @(
    # Activity Feed & User Activity
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\System", "EnableActivityFeed", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\System", "PublishUserActivities", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\System", "UploadUserActivities", 0),
    # Consumer Features (Cloud Content)
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent", "DisableWindowsConsumerFeatures", 1),
    # Advertising & Privacy
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo", "Enabled", 0),
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy", "TailoredExperiencesWithDiagnosticDataEnabled", 0),
    @("HKCU:\Software\Microsoft\InputPersonalization", "RestrictImplicitInkCollection", 1),
    @("HKCU:\Software\Microsoft\InputPersonalization", "RestrictImplicitTextCollection", 1)
)

foreach ($item in $RegPrivacy) {
    Chay-Reg $item[0] $item[1] $item[2]
    Ghi-Log "   + Đã chỉnh: $($item[1])"
}

# 2. TỐI ƯU HÓA DỊCH VỤ (SERVICES OPTIMIZATION)
Ghi-Log "[2/3] Đang tinh chỉnh hàng loạt dịch vụ hệ thống (CTT List)..."

# Nhóm các dịch vụ cần VÔ HIỆU HÓA (Disabled)
$DisabledSvcs = @("DiagTrack", "dmwappushservice", "RemoteRegistry", "RemoteAccess", "UevAgentService", "AssignedAccessManagerSvc", "ssh-agent")
foreach ($s in $DisabledSvcs) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service -Name $s -StartupType Disabled
        Ghi-Log "   [-] Đã khóa: $s"
    }
}

# Nhóm các dịch vụ chuyển sang THỦ CÔNG (Manual) để tiết kiệm tài nguyên
$ManualSvcs = @("WbioSrvc", "WebClient", "WerSvc", "WSearch", "MapsBroker", "XblAuthManager", "XblGameSave", "XboxGipSvc", "wuauserv", "UsoSvc")
foreach ($s in $ManualSvcs) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Set-Service -Name $s -StartupType Manual
        Ghi-Log "   [/] Manual: $s"
    }
}

# ==========================================================================
# CƠ CHẾ DỌN DẸP SÂU BẰNG POWERSHELL NATIVE (KHÔNG DÙNG CLEANMGR)
# ==========================================================================
Ghi-Log "[3/3] Đang dọn dẹp rác hệ thống chuyên sâu (PowerShell Core)..."

# 1. Danh sách các "ổ rác" khét tiếng nhất của Windows
$CacO_Rac = @(
    $env:TEMP,                                  # Rác phần mềm của User
    "C:\Windows\Temp",                          # Rác của hệ thống Windows
    "C:\Windows\Prefetch",                      # Cache rác mở ứng dụng cũ
    "C:\Windows\SoftwareDistribution\Download"  # Rác file cài đặt Windows Update cũ
)

# 2. Tiến hành càng quét từng thư mục
foreach ($ThuMuc in $CacO_Rac) {
    if (Test-Path $ThuMuc) {
        Ghi-Log "   -> Đang dọn dẹp: $ThuMuc"
        # Xóa toàn bộ file và thư mục con bên trong. 
        # Lệnh SilentlyContinue giúp bỏ qua các file đang được hệ thống sử dụng mà không báo lỗi đỏ.
        Get-ChildItem -Path $ThuMuc -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 3. Dọn sạch Thùng rác (Recycle Bin) của tất cả các ổ đĩa
Ghi-Log "   -> Đang làm sạch Thùng rác (Recycle Bin)..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

Ghi-Log "   + Đã tiêu diệt xong toàn bộ rác rưởi trên máy!"
# ==========================================================================
# 4. TỐI ƯU HÓA HIỆU SUẤT CHƠI GAME (GAMING & PERFORMANCE BOOST)
# ==========================================================================
Ghi-Log "[4/4] Đang kích hoạt chế độ Gaming và Bung hiệu năng tối đa..."

# 1. Ép hệ thống dùng Power Plan "High Performance" (Mã ID chuẩn của Microsoft)
try {
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Ghi-Log "   + Đã ép xung hệ thống: High Performance Power Plan."
} catch {
    Ghi-Log "   - Lỗi: Không thể chuyển Power Plan."
}

# 2. Bộ Registry tối ưu Game
$RegGameBoost = @(
    # Bật Game Mode
    @("HKCU:\Software\Microsoft\GameBar", "AutoGameModeEnabled", 1),
    
    # Tắt triệt để Game DVR và Xbox Game Bar (Chống tụt FPS, giật lag)
    @("HKCU:\System\GameConfigStore", "GameDVR_Enabled", 0),
    @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR", "AllowGameDVR", 0),
    
    # Tối ưu mạng cho Game Online (Tắt Network Throttling, giảm Ping)
    # Giá trị 4294967295 tương đương FFFFFFFF (Vô hiệu hóa giới hạn)
    @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "NetworkThrottlingIndex", 4294967295),
    
    # Ưu tiên dồn 100% tài nguyên CPU/RAM cho Game (System Responsiveness = 0)
    @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "SystemResponsiveness", 0)
)

foreach ($item in $RegGameBoost) {
    # Gọi hàm Chay-Reg ở đầu file của Tuấn
    Chay-Reg $item[0] $item[1] $item[2]
    Ghi-Log "   + Đã tối ưu Gaming: $($item[1])"
}
# ==========================================================================
# 5. TỐI ƯU HÓA TRÌNH DUYỆT WEB (CHROME & EDGE)
# ==========================================================================
Ghi-Log "[5/5] Đang tối ưu hóa trình duyệt Web (Giải phóng RAM, chặn theo dõi)..."

$RegBrowserOpt = @(
    # --- TỐI ƯU MICROSOFT EDGE ---
    # 1. Tắt tính năng chạy ngầm (Background Mode) tốn RAM khi đã đóng Edge
    @("HKLM:\SOFTWARE\Policies\Microsoft\Edge", "BackgroundModeEnabled", 0),
    
    # 2. Tắt Startup Boost (Ngăn Edge tự chạy ngầm lúc vừa khởi động máy tính)
    @("HKLM:\SOFTWARE\Policies\Microsoft\Edge", "StartupBoostEnabled", 0),
    
    # 3. Tắt gửi dữ liệu chẩn đoán và lướt web về máy chủ Microsoft
    @("HKLM:\SOFTWARE\Policies\Microsoft\Edge", "MetricsReportingEnabled", 0),
    
    # 4. Tắt đề xuất quảng cáo linh tinh trên giao diện Edge
    @("HKLM:\SOFTWARE\Policies\Microsoft\Edge", "PersonalizationReportingEnabled", 0),

    # --- TỐI ƯU GOOGLE CHROME ---
    # 1. Tắt tính năng chạy ngầm của Chrome (Cực kỳ quan trọng để giải phóng RAM)
    @("HKLM:\SOFTWARE\Policies\Google\Chrome", "BackgroundModeEnabled", 0),
    
    # 2. Tắt gửi dữ liệu thống kê, crash report về Google
    @("HKLM:\SOFTWARE\Policies\Google\Chrome", "MetricsReportingEnabled", 0)
)

foreach ($item in $RegBrowserOpt) {
    # Vẫn dùng hàm Chay-Reg xịn sò của Tuấn để ép khóa Registry
    Chay-Reg $item[0] $item[1] $item[2]
    Ghi-Log "   + Đã tối ưu Web: $($item[1])"
}

# Xóa bộ nhớ đệm phân giải tên miền (DNS Cache) giúp lướt web tải trang nhanh hơn
Clear-DnsClientCache -ErrorAction SilentlyContinue
Ghi-Log "   + Đã dọn dẹp DNS Cache (Tăng tốc độ nhận diện trang web)."

[System.Windows.Forms.MessageBox]::Show("Đã xong tối ưu vui lòng khởi động máy lại!", "Thông báo")