# ==============================================================================
# SCRIPT MODULE: CHẨN ĐOÁN THÔNG MINH + BẢN ĐỒ NHIỆT LỖI (V4.1 - FIXED)
# Tác giả: Tuấn Kỹ Thuật Máy Tính - VietToolbox Pro
# ==============================================================================

function Xuat-NhatKy($msg, $color = "Black") {
    if (Get-Command "Ghi-Log" -ErrorAction SilentlyContinue) {
        Ghi-Log $msg $color
    } else {
        # Nếu chạy độc lập không có VietToolbox thì dùng Write-Host
        $prefix = "[$((Get-Date).ToString('HH:mm:ss'))]"
        Write-Host "$prefix $msg" -ForegroundColor $color
    }
}

# --- BỘ NÃO DỮ LIỆU LỖI (Dictionary - Tuấn có thể thêm mã mới vào đây) ---
$DataLoi = @{
    "41"    = "NGUỒN YẾU/SẬP ĐIỆN: Máy bị ngắt điện đột ngột. Check PSU hoặc tụ Main.";
    "6008"  = "TẮT MÁY BẤT THƯỜNG: Máy bị treo cứng hoặc khách đè nút nguồn tắt ngang.";
    "7"     = "BAD SECTOR: Ổ cứng hỏng vật lý. Nên sao lưu dữ liệu và thay ổ ngay!";
    "11"    = "LỖI CONTROLLER: Cáp SATA lỗi hoặc Driver chipset không ổn định.";
    "153"   = "NGHẼN TRUY XUẤT: Ổ cứng phản hồi quá chậm (I/O Timeout). Gây đơ máy.";
    "1001"  = "MÀN HÌNH XANH: Hệ thống vừa bị Dump. Check RAM hoặc Driver mới.";
    "18"    = "LỖI CPU/BUS: WHEA Error. CPU quá nhiệt hoặc lỗi phần cứng nặng.";
    "4101"  = "DRIVER VGA TREO: Card màn hình bị reset. Check Driver hoặc Card yếu.";
    "10016" = "LỖI DCOM: Lỗi hệ thống Windows thường gặp, không gây treo máy.";
    "7043"  = "DỊCH VỤ TREO: Ứng dụng không chịu tắt khi Shutdown.";
    "1801"  = "LỖI TPM: Chip bảo mật không phản hồi. Có thể bỏ qua nếu Win chạy ổn.";
}

Xuat-NhatKy "=======================================" "Blue"
Xuat-NhatKy "[*] ĐANG PHÂN TÍCH BẢN ĐỒ NHIỆT LỖI (24H QUA)..." "Orange"

try {
    # Lấy dữ liệu 24h qua
    $ThoiGian = (Get-Date).AddDays(-1)
    $RawLogs = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=$ThoiGian} -ErrorAction SilentlyContinue

    if ($null -eq $RawLogs) {
        Xuat-NhatKy "[✓] Chúc mừng Tuấn! Hệ thống sạch bóng quân thù (Không có lỗi)." "Green"
    } else {
        # --- BƯỚC 1: THỐNG KÊ TẦN SUẤT (HEATMAP) ---
        $ThongKe = $RawLogs | Group-Object Id | Sort-Object Count -Descending | Select-Object -First 5
        
        Xuat-NhatKy "[>] TOP 5 LỖI XUẤT HIỆN NHIỀU NHẤT:" "Black"
        foreach ($item in $ThongKe) {
            $idHienTai = $item.Name
            $soLan = $item.Count
            $mauSac = "Black"
            
            # Phân loại độ nặng dựa trên tần suất
            if ($soLan -gt 10) { $mauSac = "Orange" }
            if ($soLan -gt 30) { $mauSac = "Red" }
            
            Xuat-NhatKy " -> Mã ID [$idHienTai]: Xuất hiện $soLan lần" $mauSac
        }

        Xuat-NhatKy "---------------------------------------" "Gray"
        Xuat-NhatKy "[*] CHI TIẾT CHẨN ĐOÁN CÁC CA NẶNG NHẤT:" "Orange"

        # --- BƯỚC 2: GIẢI MÃ CHI TIẾT ---
        foreach ($item in $ThongKe) {
            $idStr = $item.Name
            if ($DataLoi.ContainsKey($idStr)) {
                $NoiDung = $DataLoi[$idStr]
                # FIX: Dùng ${idStr} để tránh lỗi dấu hai chấm
                Xuat-NhatKy "[!] ID ${idStr}: $NoiDung" "Red"
            } else {
                # Nếu mã lạ, bốc mô tả gốc của Win
                $LogMau = $RawLogs | Where-Object { $_.Id -eq $idStr } | Select-Object -First 1
                $MsgGoc = $LogMau.Message.Split(".")[0]
                Xuat-NhatKy "[?] ID ${idStr} (Lạ): $MsgGoc" "Black"
            }
        }
        
        # --- BƯỚC 3: CẢNH BÁO "BỆNH NỀN" ---
        $LoiDisk = $ThongKe | Where-Object { $_.Name -eq "153" -or $_.Name -eq "7" }
        if ($null -ne $LoiDisk) {
            Xuat-NhatKy "[⚠️] CẢNH BÁO: Ổ cứng có dấu hiệu hỏng vật lý hoặc nghẽn!" "Red"
        }
    }
} catch {
    Xuat-NhatKy "[❌] Lỗi hệ thống: Không thể đọc nhật ký Event Log." "Red"
}

Xuat-NhatKy "=======================================" "Blue"