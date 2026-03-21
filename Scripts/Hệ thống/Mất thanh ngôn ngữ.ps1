# ==============================================================================
# SCRIPT MODULE: SỬA LỖI MẤT THANH NGÔN NGỮ (CTFMON)
# ==============================================================================

# --- HÀM GIAO TIẾP VỚI MAIN.PS1 ---
function Xuat-NhatKy($msg, $color = "Black") {
    # Kiểm tra xem hàm Ghi-Log của main.ps1 có đang tồn tại trong bộ nhớ không
    if (Get-Command "Ghi-Log" -ErrorAction SilentlyContinue) {
        Ghi-Log $msg $color
    } else {
        # Nếu chạy lẻ script này bên ngoài, tự đổi màu in ra Console
        $consoleColor = switch ($color) {
            "Red" { "Red" }
            "Green" { "Green" }
            "Blue" { "Cyan" }
            "Orange" { "Yellow" }
            "Gray" { "DarkGray" }
            default { "White" }
        }
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $msg" -ForegroundColor $consoleColor
    }
}

# --- BẮT ĐẦU XỬ LÝ ---
Xuat-NhatKy "=======================================" "Blue"
Xuat-NhatKy "[*] ĐANG XỬ LÝ LỖI MẤT THANH NGÔN NGỮ..." "Orange"

try {
    # 1. Khôi phục Registry cho ctfmon
    Xuat-NhatKy "[*] Đang nạp lại cấu hình khởi động vào Registry..." "Gray"
    $duongDanReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $duongDanReg -Name "ctfmon" -Value '"ctfmon.exe"' -Type String -ErrorAction Stop

    # 2. Tắt tiến trình ctfmon bị treo ẩn (nếu có)
    Xuat-NhatKy "[*] Đang dọn dẹp tiến trình ctfmon bị treo..." "Gray"
    Stop-Process -Name "ctfmon" -Force -ErrorAction SilentlyContinue

    # 3. Khởi động lại dịch vụ hiển thị
    Xuat-NhatKy "[*] Đang kích hoạt lại thanh ngôn ngữ..." "Gray"
    Start-Process "ctfmon.exe"

    Xuat-NhatKy "[OK] Đã sửa lỗi thành công! Góc phải màn hình đã hiện chữ VIE/ENG." "Green"
    Xuat-NhatKy "=======================================" "Blue"

} catch {
    Xuat-NhatKy "[❌] Lỗi: Không thể can thiệp Registry. Kiểm tra quyền Admin hoặc Antivirus!" "Red"
}