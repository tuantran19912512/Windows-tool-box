Add-Type -AssemblyName System.Windows.Forms

# ==============================================================================
# SCRIPT: CẤU HÌNH DNS GOOGLE (8.8.8.8 | 8.8.4.4)
# ==============================================================================

$LogicThucThi = {
    # Chuyển sang Tab Log để khách theo dõi
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG CẤU HÌNH DNS GOOGLE CHO HỆ THỐNG <<<"
    Ghi-Log "=========================================================="

    try {
        # Lấy danh sách các Card mạng đang hoạt động (Status = Up)
        $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        if (-not $Adapters) {
            Ghi-Log "!!! CẢNH BÁO: Không tìm thấy Card mạng nào đang kết nối."
            return
        }

        foreach ($Adapter in $Adapters) {
            Ghi-Log "-> Đang xử lý Card mạng: $($Adapter.Name)"
            Ghi-Log "   [+] Trạng thái: $($Adapter.Status)"
            Ghi-Log "   [+] Tốc độ: $($Adapter.LinkSpeed)"
            
            # Thực hiện gán DNS Google
            Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ServerAddresses ("8.8.8.8", "8.8.4.4") -ErrorAction Stop
            
            Ghi-Log "   [OK] Đã gán DNS 8.8.8.8 và 8.8.4.4 thành công."
        }

        Ghi-Log "----------------------------------------------------------"
        Ghi-Log ">>> TẤT CẢ CARD MẠNG ĐÃ ĐƯỢC CẬP NHẬT DNS GOOGLE <<<"
        
        # Flush DNS để áp dụng ngay lập tức
        Ghi-Log "-> Đang làm mới bộ nhớ đệm DNS (ipconfig /flushdns)..."
        ipconfig /flushdns | Out-Null
        Ghi-Log "   [OK] Hoàn tất làm mới DNS."

    } catch {
        Ghi-Log "!!! LỖI: $($_.Exception.Message)"
        Ghi-Log "-> Vui lòng đảm bảo bạn đang chạy Tool với quyền Administrator."
    }

    Ghi-Log "=========================================================="
    
    [System.Windows.Forms.MessageBox]::Show("Đã gán DNS Google cho các card mạng đang hoạt động!", "VietToolbox", 0, 64)
}

# Tích hợp vào hệ thống VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang gán DNS Google..." $LogicThucThi
} else {
    &$LogicThucThi
}