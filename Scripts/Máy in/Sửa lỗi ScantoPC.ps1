# ==============================================================================
# CHỨC NĂNG: FIX LỖI MÁY IN/SCAN BROTHER (OPEN UDP PORTS)
# KẾT NỐI LOG VỚI VIETTOOLBOX MAIN
# ==============================================================================

# 1. HÀM LOG KẾT NỐI VỚI BẢNG NHẬT KÝ CỦA MAIN.PS1
function VietLog($msg) {
    if (Get-Command "Ghi-Log" -ErrorAction SilentlyContinue) {
        Ghi-Log "Firewall: $msg"
    } else {
        Write-Host "[Firewall] $msg" -ForegroundColor Cyan
    }
}

# 2. CẤU HÌNH THÔNG SỐ
$RuleName = "Brother"
$Ports = @("54925", "54926", "137", "161")
$Protocol = "UDP"

VietLog "--- Đang bắt đầu cấu hình Firewall cho Brother ---"

try {
    # 3. KIỂM TRA QUYỀN ADMIN (BẮT BUỘC ĐỂ ĐỤNG VÀO FIREWALL)
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        VietLog "❌ LỖI: Script chưa có quyền Admin!"
        return
    }

    # 4. XÓA LUẬT CŨ NẾU CÓ ĐỂ TRÁNH TRÙNG LẶP
    if (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue) {
        VietLog "⚠️ Phát hiện luật '$RuleName' cũ, đang tiến hành dọn dẹp..."
        Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
    }

    # 5. TẠO LUẬT MỚI (INBOUND RULE)
    # - Port: UDP 54925, 54926, 137, 161
    # - Action: Allow (Cho phép)
    # - Profile: Any (Áp dụng cho tất cả mạng Domain, Private, Public)
    VietLog "🛠️ Đang mở các Port UDP: $($Ports -join ', ')..."
    
    New-NetFirewallRule -DisplayName $RuleName `
                        -Direction Inbound `
                        -Action Allow `
                        -Protocol $Protocol `
                        -LocalPort $Ports `
                        -Profile Any `
                        -Description "VietToolbox: Cho phép kết nối máy in/scan Brother" `
                        -ErrorAction Stop

    VietLog "✅ ĐÃ FIX XONG! Máy in Brother đã có thể kết nối mạng."
    
} catch {
    VietLog "❌ THẤT BẠI: $($_.Exception.Message)"
}

# Tự động đóng sau 3 giây để khách không phải bấm
VietLog "Đang hoàn tất..."
Start-Sleep -Seconds 3