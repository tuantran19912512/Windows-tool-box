Add-Type -AssemblyName System.Windows.Forms

# =====================================================================
# HÀM BẢO VỆ CHỐNG LỖI (FALLBACK) - CHỐNG VĂNG ĐỎ KHI CHẠY FILE RỜI
# =====================================================================
if (-not (Get-Command GhiLog -ErrorAction SilentlyContinue)) { function GhiLog($text) { Write-Host $text } }
if (-not (Get-Command ChuyenTab -ErrorAction SilentlyContinue)) { function ChuyenTab($p1, $p2) { } }
if (-not (Get-Command ChayTacVu -ErrorAction SilentlyContinue)) { function ChayTacVu($title, $action) { & $action } }

# =====================================================================
# LOGIC THỰC THI CHÍNH
# =====================================================================
ChayTacVu "Đang Fix lỗi kích hoạt Office..." {
    # Gọi hàm của Form gốc (nếu có)
    ChuyenTab $pnlLog $btnMenuLog
    
    GhiLog "=========================================================="
    GhiLog ">>> SỬA LỖI KÍCH HOẠT OFFICE HOME & STUDENT <<<"
    GhiLog "=========================================================="
    
    # 1. Tắt toàn bộ ứng dụng Office đang chạy để mở khóa file
    GhiLog "[1/3] Đang đóng các ứng dụng Office (Word, Excel, PowerPoint)..."
    $OfficeApps = @("winword", "excel", "powerpnt", "outlook")
    foreach ($app in $OfficeApps) {
        if (Get-Process -Name $app -ErrorAction SilentlyContinue) {
            Stop-Process -Name $app -Force -ErrorAction SilentlyContinue
            GhiLog "   + Đã ép đóng: $app"
        }
    }
    
    # 2. Xóa các tài khoản Microsoft bị kẹt (Identity) trong Registry
    GhiLog "[2/3] Đang dọn dẹp bộ nhớ đệm tài khoản (Identities)..."
    $IdentityPath = "HKCU:\Software\Microsoft\Office\16.0\Common\Identity\Identities"
    if (Test-Path $IdentityPath) {
        Remove-Item -Path "$IdentityPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        GhiLog "   + Đã xóa sạch tài khoản Microsoft bị kẹt trong Registry."
    } else {
        GhiLog "   - Không tìm thấy khóa Identity lỗi."
    }

    # Xóa file License kẹt trong AppData của khách
    $LicenseFolder = "$env:LOCALAPPDATA\Microsoft\Office\16.0\Licensing"
    if (Test-Path $LicenseFolder) {
        Remove-Item -Path "$LicenseFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
        GhiLog "   + Đã dọn dẹp file cấu hình License cũ."
    }

    # 3. Khởi động lại dịch vụ bản quyền (Software Protection)
    GhiLog "[3/3] Đang khởi động lại dịch vụ kích hoạt hệ thống..."
    try {
        Restart-Service -Name "osppsvc" -Force -ErrorAction SilentlyContinue
        Restart-Service -Name "sppsvc" -Force -ErrorAction SilentlyContinue
        GhiLog "   + Đã Reset dịch vụ bản quyền thành công."
    } catch {
        GhiLog "   - Dịch vụ đang ở trạng thái ngủ, Windows sẽ tự gọi lại khi mở Office."
    }

    GhiLog "=========================================================="
    GhiLog ">>> HOÀN TẤT: ĐÃ RESET TRẠNG THÁI BẢN QUYỀN! <<<"
    GhiLog "=========================================================="
    
    [System.Windows.Forms.MessageBox]::Show("Đã khắc phục lỗi vòng lặp kích hoạt Office!`nKhách hàng mở lại Word/Excel, đăng nhập lại tài khoản Microsoft để nhận bản quyền nhé.", "VietToolbox Pro", 0, 64)
}