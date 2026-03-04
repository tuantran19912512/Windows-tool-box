# ÉP POWERSHELL HIỂU TIẾNG VIỆT (UTF-8)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

# ==============================================================================
# SCRIPT: CẤU HÌNH NGÀY GIỜ + RESET EXPLORER (CẬP NHẬT TỨC THÌ 100%)
# ==============================================================================

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG CẤU HÌNH THỜI GIAN (FORCED UPDATE) <<<"
    Ghi-Log "=========================================================="

    # --- BƯỚC 1: LẤY LỰA CHỌN ---
    $CauHoi = "Toàn muốn dùng kiểu giờ nào?`n`n- Chọn YES cho kiểu 24 Giờ (14:30)`n- Chọn NO cho kiểu 12 Giờ (02:30 PM)"
    $UserChoice = [System.Windows.Forms.MessageBox]::Show($CauHoi, "VietToolbox", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

    # --- BƯỚC 2: CHỈNH MÚI GIỜ & ĐỒNG BỘ ---
    Ghi-Log "-> Đang đồng bộ múi giờ +7 (Hà Nội) & Giờ hệ thống..."
    tzutil /s "SE Asia Standard Time"
    Start-Service w32time -ErrorAction SilentlyContinue
    w32tm /resync /force | Out-Null

    # --- BƯỚC 3: GHI REGISTRY ---
    Ghi-Log "-> Đang ghi cấu hình định dạng Ngày/Tháng/Năm..."
    $RegPath = "HKCU:\Control Panel\International"
    Set-ItemProperty -Path $RegPath -Name "sShortDate" -Value "dd/MM/yyyy"
    Set-ItemProperty -Path $RegPath -Name "sDate" -Value "/"
    
    if ($UserChoice -eq [System.Windows.Forms.DialogResult]::Yes) {
        Set-ItemProperty -Path $RegPath -Name "sTimeFormat" -Value "HH:mm:ss"
        Set-ItemProperty -Path $RegPath -Name "sShortTime" -Value "HH:mm"
        Ghi-Log "   [+] Đã chọn chế độ: 24 Giờ."
    } else {
        Set-ItemProperty -Path $RegPath -Name "sTimeFormat" -Value "h:mm:ss tt"
        Set-ItemProperty -Path $RegPath -Name "sShortTime" -Value "h:mm tt"
        Ghi-Log "   [+] Đã chọn chế độ: 12 Giờ."
    }

    # --- BƯỚC 4: KHỞI ĐỘNG LẠI EXPLORER ĐỂ CẬP NHẬT GIAO DIỆN ---
    Ghi-Log "-> Đang khởi động lại Explorer để áp dụng thay đổi ngay..."
    Ghi-Log "   (Màn hình sẽ chớp nhẹ trong giây lát)"

    try {
        # Tắt tiến trình Explorer
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 1
        # Explorer thường tự khởi động lại, nhưng lệnh này để chắc chắn 100%
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer.exe
        }
        Ghi-Log "   [OK] Đã làm mới giao diện hệ thống."
    } catch {
        Ghi-Log "   [!] Lỗi khi reset Explorer. Toàn hãy tự khởi động lại máy."
    }

    Ghi-Log "=========================================================="
    Ghi-Log ">>> HOÀN TẤT! ĐỒNG HỒ ĐÃ ĐƯỢC CẬP NHẬT <<<"
    Ghi-Log "=========================================================="
    
    [System.Windows.Forms.MessageBox]::Show("Đã đồng bộ và cập nhật đồng hồ thành công!", "VietToolbox", 0, 64)
}

# Tích hợp vào VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Cập nhật Ngày Giờ..." $LogicThucThi
} else {
    &$LogicThucThi
}