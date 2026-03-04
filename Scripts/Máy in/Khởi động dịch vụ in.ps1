# ÉP POWERSHELL HIỂU TIẾNG VIỆT (UTF-8)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

# ==============================================================================
# SCRIPT: FIX LỖI KẸT MÁY IN (CLEAR PRINTER SPOOLER)
# ==============================================================================

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG XỬ LÝ LỖI KẸT MÁY IN (PRINTER SPOOLER) <<<"
    Ghi-Log "=========================================================="

    # --- BƯỚC 1: DỪNG DỊCH VỤ SPOOLER ---
    Ghi-Log "[1/3] Đang dừng dịch vụ Print Spooler..."
    try {
        $spooler = Get-Service -Name Spooler
        if ($spooler.Status -ne "Stopped") {
            Stop-Service -Name Spooler -Force -ErrorAction Stop
            Ghi-Log "   [OK] Đã dừng dịch vụ thành công."
        } else {
            Ghi-Log "   [!] Dịch vụ Spooler vốn đã dừng từ trước."
        }
    } catch {
        Ghi-Log "   !!! LỖI: Không thể dừng dịch vụ Spooler. Hãy chạy Tool với quyền Admin."
        return
    }

    # --- BƯỚC 2: XÓA CÁC FILE LỆNH IN BỊ KẸT ---
    Ghi-Log "[2/3] Đang dọn dẹp các lệnh in bị kẹt trong hệ thống..."
    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*"
    try {
        # Kiểm tra xem có file nào không
        if (Test-Path $spoolPath) {
            $files = Get-ChildItem -Path $spoolPath
            if ($files.Count -gt 0) {
                Ghi-Log "   + Tìm thấy $($files.Count) lệnh in cũ. Đang xóa..."
                Remove-Item -Path $spoolPath -Force -Recurse
                Ghi-Log "   [OK] Đã dọn dẹp sạch folder Printers."
            } else {
                Ghi-Log "   [!] Thư mục lệnh in vốn đã trống."
            }
        }
    } catch {
        Ghi-Log "   [!] Cảnh báo: Một số file đang bị khóa, không thể xóa hết."
    }

    # --- BƯỚC 3: KHỞI ĐỘNG LẠI DỊCH VỤ ---
    Ghi-Log "[3/3] Đang khởi động lại dịch vụ máy in..."
    try {
        Start-Service -Name Spooler -ErrorAction Stop
        Ghi-Log "   [OK] Dịch vụ Print Spooler đã hoạt động trở lại."
        
        # Kiểm tra chốt hạ
        $check = Get-Service -Name Spooler
        if ($check.Status -eq "Running") {
            Ghi-Log ">>> HOÀN TẤT: MÁY IN ĐÃ SẴN SÀNG ĐỂ SỬ DỤNG! <<<"
        }
    } catch {
        Ghi-Log "   !!! LỖI: Không thể khởi động lại dịch vụ Spooler."
    }

    Ghi-Log "=========================================================="
    
    [System.Windows.Forms.MessageBox]::Show("Đã sửa lỗi kẹt máy in thành công! `nBạn có thể thử in lại ngay bây giờ.", "VietToolbox", 0, 64)
}

# Tích hợp vào VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Sửa lỗi kẹt máy in..." $LogicThucThi
} else {
    &$LogicThucThi
}