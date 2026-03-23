# ==============================================================================
# SCRIPT MODULE: KIỂM TRA SỨC KHỎE HDD & SSD (BẢN CHUẨN POWERSHELL 5.1)
# ==============================================================================

function Xuat-NhatKy($msg, $color = "Black") {
    if (Get-Command "Ghi-Log" -ErrorAction SilentlyContinue) {
        Ghi-Log $msg $color
    } else {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $msg"
    }
}

Xuat-NhatKy "=======================================" "Blue"
Xuat-NhatKy "[*] ĐANG PHÂN TÍCH HỆ THỐNG LƯU TRỮ..." "Orange"

try {
    $disks = Get-PhysicalDisk | Where-Object { $_.BusType -ne "USB" }

    foreach ($disk in $disks) {
        $stats = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
        $tenO = $disk.FriendlyName
        $loaiO = $disk.MediaType
        
        Xuat-NhatKy "---------------------------------------" "Gray"
        Xuat-NhatKy "Ổ CỨNG: $tenO ($loaiO)" "Blue"

        # 1. Xử lý sức khỏe (%) cho SSD
        if ($loaiO -eq "SSD" -and $null -ne $stats.Wear) {
            $sucKhoe = 100 - $stats.Wear
            $colorSK = "Green"
            if ($sucKhoe -lt 80) { $colorSK = "Orange" }
            if ($sucKhoe -lt 50) { $colorSK = "Red" }
            Xuat-NhatKy "[+] Sức khỏe SSD: $sucKhoe %" $colorSK
        } else {
            # Với HDD, kiểm tra trạng thái sức khỏe từ hệ thống
            $status = $disk.HealthStatus
            $colorH = if ($status -eq "Healthy") { "Green" } else { "Red" }
            Xuat-NhatKy "[+] Trạng thái: $status" $colorH
        }

        # 2. Xử lý nhiệt độ (Tách riêng để tránh lỗi cú pháp)
        if ($null -ne $stats.Temperature -and $stats.Temperature -gt 0) {
            $colorTemp = "Black"
            if ($stats.Temperature -gt 50) { $colorTemp = "Red" }
            Xuat-NhatKy "[+] Nhiệt độ: $($stats.Temperature) °C" $colorTemp
        }

        # 3. Xử lý thời gian chạy
        if ($null -ne $stats.PowerOnHours) {
            Xuat-NhatKy "[+] Đã chạy: $($stats.PowerOnHours) giờ" "Black"
        }

        # 4. Kiểm tra tổng quát
        if ($disk.OperationalStatus -eq "OK") {
            Xuat-NhatKy "[✓] Phần cứng: Hoạt động tốt" "Green"
        } else {
            Xuat-NhatKy "[⚠️] CẢNH BÁO: Phát hiện lỗi S.M.A.R.T!" "Red"
        }
    }
} catch {
    Xuat-NhatKy "[❌] Lỗi hệ thống: $($_.Exception.Message)" "Red"
}

Xuat-NhatKy "=======================================" "Blue"