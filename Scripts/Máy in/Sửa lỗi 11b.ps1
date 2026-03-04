Add-Type -AssemblyName System.Windows.Forms

# Hàm tự thích nghi cho VietToolbox
function GhiLog-AnToan ($VanBan) {
    if (Get-Command GhiLog -ErrorAction SilentlyContinue) { GhiLog $VanBan }
    else { Write-Host $VanBan }
}

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    GhiLog-AnToan "=========================================================="
    GhiLog-AnToan ">>> SỬA LỖI CHIA SẺ MÁY IN QUA MẠNG LAN (0x0000011b) <<<"
    GhiLog-AnToan "=========================================================="
    
    # --- CẢNH BÁO BẮT BUỘC CHẠY TRÊN MÁY CHỦ ---
    $CauHoi = "LƯU Ý QUAN TRỌNG:`n`nCông cụ này BẮT BUỘC PHẢI CHẠY TRÊN MÁY CHỦ (máy tính đang cắm trực tiếp dây cáp USB vào máy in).`n`nBạn có chắc chắn đây là máy chủ không?"
    $TraLoi = [System.Windows.Forms.MessageBox]::Show($CauHoi, "Xác nhận Máy Chủ", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($TraLoi -ne [System.Windows.Forms.DialogResult]::Yes) {
        GhiLog-AnToan "-> Đã hủy thao tác. Vui lòng mang Tool này sang MÁY CHỦ để chạy."
        [System.Windows.Forms.MessageBox]::Show("Vui lòng gọi phần mềm này sang máy chủ (máy cắm cáp USB máy in) để chạy nhé!", "Thông báo", 0, 64)
        return # Dừng toàn bộ script ngay lập tức
    }
    
    # Hang ổ cấu hình của Print Spooler
    $DuongDanPrint = "HKLM:\System\CurrentControlSet\Control\Print"
    
    GhiLog-AnToan "-> Đang can thiệp vào cấu hình bảo mật RPC của Print Spooler..."
    
    try {
        # Bơm khóa Registry RpcAuthnLevelPrivacyEnabled = 0
        if (!(Test-Path $DuongDanPrint)) { New-Item -Path $DuongDanPrint -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $DuongDanPrint -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -Force -ErrorAction Stop
        
        GhiLog-AnToan "   + Đã vô hiệu hóa tính năng RPC Auth ép buộc (Thủ phạm gây lỗi 11b)."
        
        GhiLog-AnToan "-> Đang khởi động lại dịch vụ Print Spooler để áp dụng..."
        Restart-Service -Name Spooler -Force -ErrorAction SilentlyContinue
        
        GhiLog-AnToan ">>> HOÀN TẤT: ĐÃ SỬA LỖI MÃ 0x0000011b THÀNH CÔNG!"
        [System.Windows.Forms.MessageBox]::Show("Đã sửa lỗi chia sẻ máy in mạng LAN (Mã 0x0000011b) thành công!`nBây giờ bạn có thể sang các máy con (Client) kết nối lại máy in là in được ngay.", "Thành công", 0, 64) 
    } catch {
        GhiLog-AnToan "!!! LỖI CỰC MẠNH: Không thể ghi đè vào Registry."
        [System.Windows.Forms.MessageBox]::Show("Có lỗi xảy ra khi cấu hình Registry.`nVui lòng đảm bảo bạn đang mở VietToolbox bằng quyền Quản trị viên (Run as Administrator).", "Lỗi cấp quyền", 0, 16) 
    }
}

# Chạy vào hệ thống động của VietToolbox
if (Get-Command ChayTacVu -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang Fix lỗi máy in 11b..." $LogicThucThi
} else {
    &$LogicThucThi
}