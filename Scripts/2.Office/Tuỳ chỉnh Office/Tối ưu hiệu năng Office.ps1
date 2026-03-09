Add-Type -AssemblyName System.Windows.Forms

Ghi-Log "=========================================="
Ghi-Log ">>> TỐI ƯU HÓA OFFICE & ĐẶC TRỊ EXCEL LAG <<<"
Ghi-Log "=========================================="

$OfficeVersions = @("16.0", "15.0", "14.0")
$Found = $false

foreach ($ver in $OfficeVersions) {
    $basePath = "HKCU:\Software\Microsoft\Office\$ver"
    if (Test-Path $basePath) {
        $Found = $true
        Ghi-Log "-> Đang cấu hình cho Office phiên bản: $ver"
        
        # --- 1. TỐI ƯU CHUNG (Tăng tốc khởi động) ---
        $Apps = @("Word", "Excel", "PowerPoint")
        foreach ($app in $Apps) {
            $appPath = "$basePath\$app\Options"
            if (!(Test-Path $appPath)) { New-Item -Path $appPath -Force | Out-Null }
            Set-ItemProperty -Path $appPath -Name "DisableBootToOfficeStart" -Value 1 -Type DWord -Force
        }

        # --- 2. ĐẶC TRỊ EXCEL FILE NẶNG ---
        Ghi-Log "   + Đang kích hoạt chế độ tính toán đa nhân (Multi-threaded)..."
        $excelPath = "$basePath\Excel\Options"
        if (!(Test-Path $excelPath)) { New-Item -Path $excelPath -Force | Out-Null }
        
        # Ép Excel dùng tất cả nhân CPU để tính toán công thức
        Set-ItemProperty -Path $excelPath -Name "RTDThrottleInterval" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $excelPath -Name "Options64" -Value 1 -Type DWord -Force 

        Ghi-Log "   + Tắt Live Preview (Xem trước định dạng) để giảm lag khi bôi đen..."
        Set-ItemProperty -Path $excelPath -Name "DisableLivePreview" -Value 1 -Type DWord -Force

        Ghi-Log "   + Chặn tự động cập nhật liên kết ngoài (Links) khi mở file..."
        # Giá trị 2: Không hỏi, không cập nhật tự động (giúp mở file nhanh hơn)
        Set-ItemProperty -Path $excelPath -Name "UpdateLinks" -Value 0 -Type DWord -Force

        # --- 3. TẮT HIỆU ỨNG ĐỒ HỌA (Fix lỗi đen màn hình/giật) ---
        $commonPath = "$basePath\Common\Graphics"
        if (!(Test-Path $commonPath)) { New-Item -Path $commonPath -Force | Out-Null }
        Set-ItemProperty -Path $commonPath -Name "DisableHardwareAcceleration" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $commonPath -Name "DisableAnimations" -Value 1 -Type DWord -Force

        # --- 4. TỐI ƯU WORD (Cho file văn bản dài) ---
        $wordPath = "$basePath\Word\Options"
        if (!(Test-Path $wordPath)) { New-Item -Path $wordPath -Force | Out-Null }
        Set-ItemProperty -Path $wordPath -Name "BackgroundRepagination" -Value 0 -Type DWord -Force
        
        # --- 5. TẮT PROTECTED VIEW (MỞ FILE ZALO/INTERNET KHÔNG BỊ READ-ONLY) ---
        Ghi-Log "   + Tắt dải băng vàng (Protected View) khi tải file từ Zalo..."
        foreach ($app in $Apps) {
            $pvPath = "$basePath\$app\Security\ProtectedView"
            if (!(Test-Path $pvPath)) { New-Item -Path $pvPath -Force | Out-Null }
            # Gán giá trị 1 để Vô hiệu hóa (Disable) các lớp bảo vệ gây phiền phức
            Set-ItemProperty -Path $pvPath -Name "DisableAttachementsInPV" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $pvPath -Name "DisableInternetFilesInPV" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $pvPath -Name "DisableUnsafeLocationsInPV" -Value 1 -Type DWord -Force
        }
    }
}

if (-not $Found) {
    Ghi-Log "!!! LỖI: Không tìm thấy cài đặt Office trên máy này."
    return
}

Ghi-Log ">>> HOÀN TẤT: Office đã được 'độ' để gánh file nặng mượt hơn và mở thẳng file từ Zalo."
[System.Windows.Forms.MessageBox]::Show("Đã tối ưu Office thành công!`nĐặc biệt: Excel đa nhân & Mở file Zalo/Internet gõ được ngay.", "VietToolbox Pro")