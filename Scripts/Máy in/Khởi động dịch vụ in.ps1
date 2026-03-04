Add-Type -AssemblyName System.Windows.Forms

Ghi-Log "=========================================================="
Ghi-Log ">>> CÔNG CỤ ĐẶC TRỊ LỖI KẸT LỆNH MÁY IN (SPOOLER) <<<"
Ghi-Log "=========================================================="

# 1. Dừng dịch vụ Print Spooler
Ghi-Log "[1/3] Đang đóng băng dịch vụ máy in (Print Spooler)..."
try {
    Stop-Service -Name "Spooler" -Force -ErrorAction Stop
    Ghi-Log "   + Đã dừng dịch vụ thành công."
} catch {
    Ghi-Log "   - Dịch vụ đang ở trạng thái dừng hoặc có lỗi (bỏ qua)."
}

# 2. Xóa các file rác/kẹt trong thư mục PRINTERS
Ghi-Log "[2/3] Đang tiêu diệt các lệnh in bị kẹt cứng trong hệ thống..."
$SpoolFolder = "C:\Windows\System32\spool\PRINTERS"
if (Test-Path $SpoolFolder) {
    try {
        # Xóa tất cả các file (.SHD và .SPL) nằm trong thư mục này
        Get-ChildItem -Path $SpoolFolder -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Ghi-Log "   + Đã dọn sạch hàng đợi máy in."
    } catch {
        Ghi-Log "!!! LỖI: Không thể xóa file. Có thể một tiến trình khác đang giữ file."
    }
} else {
    Ghi-Log "   - Thư mục PRINTERS không tồn tại, bỏ qua."
}

# 3. Khởi động lại dịch vụ Print Spooler
Ghi-Log "[3/3] Đang kích hoạt lại dịch vụ máy in..."
try {
    Start-Service -Name "Spooler" -ErrorAction Stop
    Ghi-Log "   + Đã khởi động lại dịch vụ thành công."
} catch {
    Ghi-Log "!!! LỖI CỰC MẠNH: Không thể bật lại Spooler."
}

# 4. Kiểm tra chốt hạ
$svc = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
if ($null -ne $svc -and $svc.Status -eq 'Running') {
    Ghi-Log "=========================================================="
    Ghi-Log ">>> HOÀN TẤT: MÁY IN ĐÃ SẴN SÀNG HOẠT ĐỘNG <<<"
    Ghi-Log "=========================================================="
    [System.Windows.Forms.MessageBox]::Show("Đã sửa lỗi kẹt máy in thành công! Khách hàng có thể in lại bình thường.", "VietToolbox Pro", 0, 64)
} else {
    Ghi-Log "=========================================================="
    Ghi-Log "!!! THẤT BẠI: DỊCH VỤ MÁY IN KHÔNG THỂ CHẠY !!!"
    Ghi-Log "=========================================================="
    [System.Windows.Forms.MessageBox]::Show("Lỗi khởi động hệ thống in ấn của Windows! Vui lòng kiểm tra lại dịch vụ Spooler trong services.msc.", "Lỗi hệ thống", 0, 16)
}