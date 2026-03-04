Add-Type -AssemblyName System.Windows.Forms

# Hàm tự thích nghi cho VietToolbox
function GhiLog-AnToan ($VanBan) {
    if (Get-Command GhiLog -ErrorAction SilentlyContinue) { GhiLog $VanBan }
    else { Write-Host $VanBan }
}

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    GhiLog-AnToan "=========================================================="
    GhiLog-AnToan ">>> SỬA LỖI TRÙNG CỔNG USB CHO TẤT CẢ MÁY IN <<<"
    GhiLog-AnToan "=========================================================="
    
    # Truy cập vào hang ổ quản lý máy in của Windows
    $DuongDanMayIn = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
    $DaSuaLoi = $false
    
    GhiLog-AnToan "-> Đang quét toàn bộ cấu hình máy in trên hệ thống..."
    
    # Lấy danh sách tất cả các máy in
    $DanhSachMayIn = Get-ChildItem -Path $DuongDanMayIn -ErrorAction SilentlyContinue
    
    if ($DanhSachMayIn) {
        foreach ($MayIn in $DanhSachMayIn) {
            $TenMayIn = $MayIn.PSChildName
            $CongKetNoi = (Get-ItemProperty -Path $MayIn.PSPath -Name "Port" -ErrorAction SilentlyContinue).Port
            
            # Bỏ qua nếu máy in không có thông tin cổng
            if ([string]::IsNullOrWhiteSpace($CongKetNoi)) { continue }
            
            # Kiểm tra xem cổng có bị gộp bằng dấu phẩy và liên quan đến USB không
            if ($CongKetNoi -match "," -and $CongKetNoi -match "USB") {
                GhiLog-AnToan "   ! PHÁT HIỆN LỖI: [$TenMayIn] đang bị gán đè cổng ($CongKetNoi)"
                
                # Tách chuỗi theo dấu phẩy để lấy danh sách các cổng bị kẹp
                $CacCong = $CongKetNoi -split ","
                $CongMoi = ""
                
                # Lọc lấy cổng USB đầu tiên làm cổng chính
                foreach ($Cong in $CacCong) {
                    if ($Cong.Trim() -match "^USB") {
                        $CongMoi = $Cong.Trim()
                        break
                    }
                }
                
                # Phương án dự phòng nếu không lọc được chữ USB
                if ($CongMoi -eq "") {
                    $CongMoi = $CacCong[0].Trim()
                }
                
                GhiLog-AnToan "   -> Đang gỡ kẹt, ép thiết bị về 1 cổng chuẩn: $CongMoi"
                Set-ItemProperty -Path $MayIn.PSPath -Name "Port" -Value $CongMoi -Force
                
                $DaSuaLoi = $true
            }
        }
        
        if ($DaSuaLoi) {
            GhiLog-AnToan "-> Đang khởi động lại dịch vụ Print Spooler để áp dụng thay đổi..."
            Restart-Service -Name Spooler -Force -ErrorAction SilentlyContinue
            
            GhiLog-AnToan ">>> HOÀN TẤT: ĐÃ SỬA LỖI KẸT CỔNG MÁY IN THÀNH CÔNG!"
            [System.Windows.Forms.MessageBox]::Show("Đã gỡ lỗi trùng cổng USB cho máy in thành công!`nVui lòng nhắc khách tắt công tắc nguồn máy in, bật lại và in thử.", "Thành công", 0, 64) 
        } else {
            GhiLog-AnToan ">>> TÌNH TRẠNG CÁC CỔNG MÁY IN ĐỀU BÌNH THƯỜNG."
            [System.Windows.Forms.MessageBox]::Show("Toàn bộ máy in USB hiện đang ở trạng thái bình thường, không bị trùng cổng.", "Thông báo", 0, 64) 
        }
        
    } else {
        GhiLog-AnToan "!!! LỖI: Không tìm thấy máy in nào trên máy này."
        [System.Windows.Forms.MessageBox]::Show("Hệ thống chưa cài đặt máy in nào.", "Lỗi hệ thống", 0, 16) 
    }
}

# Chạy vào hệ thống động của VietToolbox
if (Get-Command ChayTacVu -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang Fix lỗi trùng cổng USB..." $LogicThucThi
} else {
    &$LogicThucThi
}