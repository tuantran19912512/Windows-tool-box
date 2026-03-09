# ÉP POWERSHELL HIỂU TIẾNG VIỆT (UTF-8)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$LogicThucThi = {
    Ghi-Log ">>> ĐANG TRUY QUÉT CHI TIẾT PIN (CÔNG NGHỆ POWER-REPORT) <<<"
    
    # 1. KIỂM TRA PHẦN CỨNG: PHÂN BIỆT MÁY BÀN (PC) VÀ LAPTOP
    $batteryWMI = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    
    if (-not $batteryWMI) {
        Ghi-Log "------------------------------------------"
        Ghi-Log "[!] HỆ THỐNG BÁO CÁO: Bạn đang dùng Máy bàn (PC) hoặc thiết bị không có pin."
        Ghi-Log "=> Đã bỏ qua bước kiểm tra Pin."
        Ghi-Log "------------------------------------------"
        return # Dừng script tại đây luôn, không chạy các lệnh bên dưới nữa
    }

    Ghi-Log "Hệ thống nhận diện đây là Laptop. Vui lòng đợi trích xuất dữ liệu..."

    # 2. Tạo báo cáo pin tạm thời bằng lệnh gốc của Windows (HTML)
    $reportPath = "$env:TEMP\battery_report.html"
    powercfg /batteryreport /output $reportPath /duration 1 | Out-Null
    
    # 3. Quét thông số thực tế & thiết kế (Hỗ trợ Vét cạn mọi dòng máy)
    $fullCapWMI = (Get-CimInstance -Namespace root/wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue).FullChargedCapacity
    $designCapWMI = (Get-CimInstance -Namespace root/wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue).DesignCapacity

    # Fallback (Dự phòng): Nếu WMI gốc bị khóa, tìm trong Win32_Battery
    if (-not $designCapWMI -or $designCapWMI -le 0) {
        $designCapWMI = $batteryWMI.DesignCapacity
    }
    if (-not $fullCapWMI -or $fullCapWMI -le 0) {
        $fullCapWMI = $batteryWMI.FullChargeCapacity
    }

    # 4. Phân tích kết quả
    $full = [float]$fullCapWMI
    $design = [float]$designCapWMI
    
    Ghi-Log "------------------------------------------"
    Ghi-Log "- Tên pin / Mã thiết bị: $($batteryWMI.DeviceID)"
    Ghi-Log "- Lượng pin hiện tại: $($batteryWMI.EstimatedChargeRemaining)%"
    
    # Đảm bảo cả 2 thông số đều có số liệu thật mới tính toán
    if ($design -gt 0 -and $full -gt 0) {
        $healthVal = [Math]::Round(($full / $design) * 100, 1)
        $wearLevel = [Math]::Round(100 - $healthVal, 1)
        
        # Sửa lỗi hiển thị pin "ảo" (Máy mới mua, dung lượng thực tế > dung lượng thiết kế)
        if ($wearLevel -lt 0) { $wearLevel = 0; $healthVal = 100 }

        Ghi-Log "------------------------------------------"
        Ghi-Log "- Dung lượng gốc (Thiết kế): $design mWh"
        Ghi-Log "- Dung lượng thực tế hiện tại: $full mWh"
        Ghi-Log "- Độ sức khỏe (Health): $healthVal %"
        Ghi-Log "- Mức độ chai pin: $wearLevel %"

        # Logic đánh giá tình trạng
        if ($wearLevel -gt 40) {
            Ghi-Log "=> TÌNH TRẠNG: PIN CHAI NẶNG (NÊN THAY THẾ)."
        } elseif ($wearLevel -gt 20) {
            Ghi-Log "=> TÌNH TRẠNG: PIN BẮT ĐẦU CHAI (BÌNH THƯỜNG)."
        } else {
            Ghi-Log "=> TÌNH TRẠNG: PIN CÒN TỐT."
        }
    } else {
        Ghi-Log "------------------------------------------"
        if ($full -gt 0) { Ghi-Log "- Dung lượng sạc đầy: $full mWh" }
        Ghi-Log "=> [!] KHÔNG THỂ TÍNH ĐỘ CHAI DO FIRMWARE MÁY ẨN THÔNG SỐ GỐC."
    }
    
    Ghi-Log "------------------------------------------"
    Ghi-Log "[Gợi ý] Bạn có thể xem báo cáo chuẩn của Windows tại: $reportPath"
}

# Tích hợp vào VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Kiểm tra Pin Laptop" $LogicThucThi
} else {
    &$LogicThucThi
}