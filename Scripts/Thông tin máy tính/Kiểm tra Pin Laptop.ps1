# ÉP POWERSHELL HIỂU TIẾNG VIỆT (UTF-8)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$LogicThucThi = {
    Ghi-Log ">>> ĐANG TRUY QUÉT CHI TIẾT PIN (CÔNG NGHỆ POWER-REPORT) <<<"
    Ghi-Log "Vui lòng chờ vài giây để Windows trích xuất dữ liệu..."

    # 1. Tạo báo cáo pin tạm thời bằng lệnh gốc của Windows
    $reportPath = "$env:TEMP\battery_report.xml"
    # Dùng lệnh này để lấy dữ liệu thô chuẩn nhất
    powercfg /batteryreport /output "$env:TEMP\battery_report.html" /duration 1 | Out-Null
    
    # 2. Lấy thông tin từ WMI làm dự phòng và bổ trợ
    $batteryWMI = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    $fullCapWMI = (Get-CimInstance -Namespace root/wmi -ClassName BatteryFullChargedCapacity).FullChargedCapacity
    $designCapWMI = (Get-CimInstance -Namespace root/wmi -ClassName BatteryStaticData).DesignCapacity

    # 3. Nếu WMI của MSI bị trống DesignCapacity, mình sẽ dùng mẹo "ép" lấy số liệu
    if (-not $designCapWMI -or $designCapWMI -eq 0) {
        # Thử lấy lại từ Win32_Battery (đôi khi nó nằm ở đây)
        $designCapWMI = $batteryWMI.DesignCapacity
    }

    # 4. Phân tích kết quả
    $full = [float]$fullCapWMI
    $design = [float]$designCapWMI
    
    # Nếu vẫn không lấy được Design từ hệ thống, MSI thường là 51000 hoặc 65000 mWh
    # Nhưng mình sẽ báo lỗi thay vì đoán mò
    if ($design -le 0) {
        Ghi-Log "[!] CẢNH BÁO: Firmware MSI chặn đọc Dung lượng thiết kế."
        $health = "KHÔNG XÁC ĐỊNH"
    } else {
        $healthVal = [Math]::Round(($full / $design) * 100, 1)
        $health = "$healthVal %"
    }

    # 5. Xuất kết quả chi tiết
    Ghi-Log "------------------------------------------"
    Ghi-Log "- Tên máy/Pin: $($batteryWMI.DeviceID)"
    Ghi-Log "- Trạng thái sạc: $($batteryWMI.EstimatedChargeRemaining)%"
    
    # Tính toán tình trạng thực tế
    if ($healthVal -gt 0) {
        Ghi-Log "------------------------------------------"
        Ghi-Log "- Dung lượng gốc (Thiết kế): $design mWh"
        Ghi-Log "- Dung lượng thực tế hiện tại: $full mWh"
        Ghi-Log "- Độ sức khỏe (Health): $health"
        
        $wearLevel = 100 - $healthVal
        Ghi-Log "- Mức độ chai pin: $wearLevel %"

        # Logic đánh giá mới: Chặt chẽ hơn
        if ($wearLevel -gt 40) {
            Ghi-Log "=> TÌNH TRẠNG: PIN CHAI NẶNG (ĐÃ CHẾT CELL)."
        } elseif ($wearLevel -gt 20) {
            Ghi-Log "=> TÌNH TRẠNG: PIN BẮT ĐẦU CHAI."
        } else {
            Ghi-Log "=> TÌNH TRẠNG: PIN CÒN TỐT."
        }
    } else {
        Ghi-Log "- Dung lượng sạc đầy: $full mWh"
        Ghi-Log "=> KHÔNG TÍNH ĐƯỢC ĐỘ CHAI DO FIRMWARE GIẤU THÔNG SỐ GỐC."
    }
    
    Ghi-Log "------------------------------------------"
    Ghi-Log "[Gợi ý] Bạn có thể xem chi tiết tại: $env:TEMP\battery_report.html"
}

# Tích hợp vào VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Kiểm tra Pin Laptop" $LogicThucThi
} else {
    &$logicThucThi
}