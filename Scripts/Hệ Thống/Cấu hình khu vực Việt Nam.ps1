Add-Type -AssemblyName System.Windows.Forms

Ghi-Log ">>> ĐANG CẤU HÌNH ĐỊNH DẠNG NGÀY GIỜ & SỐ CHUẨN VIỆT NAM..."

# 1. Đặt Quốc gia (Location) là Việt Nam (GeoID của VN là 244)
try {
    Set-WinHomeLocation -GeoId 244
    Ghi-Log "-> Đã chuyển vùng hệ thống (Location) về Việt Nam."
} catch {
    Ghi-Log "   ! Không thể đặt Location: $($_.Exception.Message)"
}

# 2. Đặt Culture là vi-VN (Tiếng Việt)
try {
    Set-Culture vi-VN
    Ghi-Log "-> Đã thiết lập ngôn ngữ hiển thị (Culture) là Tiếng Việt."
} catch {
    Ghi-Log "   ! Lỗi đặt Culture: $($_.Exception.Message)"
}

# 3. Can thiệp sâu vào Registry để ép định dạng theo ý muốn
Ghi-Log "-> Đang tinh chỉnh định dạng số và ngày tháng trong Registry..."

$RegPath = "HKCU:\Control Panel\International"

function Fix-Reg($Name, $Value) {
    Set-ItemProperty -Path $RegPath -Name $Name -Value $Value -Force
    Ghi-Log "   [Registry] $Name -> $Value"
}

# Chỉnh định dạng Ngày/Tháng/Năm
Fix-Reg "sShortDate" "dd/MM/yyyy"
Fix-Reg "sLongDate" "dd MMMM yyyy"

# Chỉnh định dạng Số (Dấu . cho hàng nghìn, dấu , cho thập phân)
Fix-Reg "sDecimal" ","      # Dấu phân cách thập phân (VD: 10,5)
Fix-Reg "sThousand" "."     # Dấu phân cách hàng nghìn (VD: 1.000)
Fix-Reg "sList" ";"         # Dấu phân cách trong danh sách (thường là ;)
Fix-Reg "iCountry" "84"     # Mã quốc gia Việt Nam

# 4. Cập nhật thay đổi ngay lập tức (Refresh Settings)
Ghi-Log "-> Đang yêu cầu Windows cập nhật thay đổi..."
# Một số ứng dụng cần khởi động lại để thấy thay đổi, nhưng Registry đã được lưu.

Ghi-Log ">>> HOÀN TẤT CẤU HÌNH REGIONAL VIỆT NAM."
Ghi-Log "LƯU Ý: Một số phần mềm (như Excel) có thể cần khởi động lại để nhận định dạng mới."

[System.Windows.Forms.MessageBox]::Show("Đã cấu hình định dạng Ngày tháng (dd/MM/yyyy) và Số (1.000,00) chuẩn Việt Nam thành công!", "Thông báo")