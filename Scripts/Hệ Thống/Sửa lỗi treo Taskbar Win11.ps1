Add-Type -AssemblyName System.Windows.Forms

# Hàm tự thích nghi cho VietToolbox
function GhiLog-AnToan ($VanBan) {
    if (Get-Command GhiLog -ErrorAction SilentlyContinue) { GhiLog $VanBan }
    else { Write-Host $VanBan }
}

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    GhiLog-AnToan "=========================================================="
    GhiLog-AnToan ">>> SỬA LỖI TREO TASKBAR & NÚT START TRÊN WINDOWS 11 <<<"
    GhiLog-AnToan "=========================================================="
    
    # 1. Tiêu diệt các tiến trình giao diện bị kẹt cứng
    GhiLog-AnToan "[1/4] Đang đóng băng và tiêu diệt các tiến trình UI bị treo..."
    $TienTrinhLoi = @("StartMenuExperienceHost", "ShellExperienceHost", "SearchHost", "explorer")
    
    foreach ($TienTrinh in $TienTrinhLoi) {
        if (Get-Process -Name $TienTrinh -ErrorAction SilentlyContinue) {
            Stop-Process -Name $TienTrinh -Force -ErrorAction SilentlyContinue
            GhiLog-AnToan "   + Đã kết liễu: $TienTrinh"
        }
    }
    
    # 2. Xóa bộ nhớ đệm Iris Service (Thủ phạm khét tiếng làm treo Win 11)
    GhiLog-AnToan "[2/4] Đang dọn dẹp rác Registry của Iris Service..."
    $IrisPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\IrisService"
    if (Test-Path $IrisPath) {
        Remove-Item -Path $IrisPath -Recurse -Force -ErrorAction SilentlyContinue
        GhiLog-AnToan "   + Đã xóa thành công cache Iris Service."
    } else {
        GhiLog-AnToan "   - Không tìm thấy khóa Iris Service (bỏ qua)."
    }
    
    # 3. Nạp lại gói hệ thống Start Menu (Chỉ nạp gói cần thiết để tiết kiệm thời gian)
    GhiLog-AnToan "[3/4] Đang phục hồi gói ứng dụng Start Menu & Taskbar..."
    try {
        Get-AppxPackage Microsoft.Windows.ShellExperienceHost | Foreach-Object {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"} -ErrorAction SilentlyContinue
        Get-AppxPackage Microsoft.Windows.StartMenuExperienceHost | Foreach-Object {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"} -ErrorAction SilentlyContinue
        GhiLog-AnToan "   + Đã đăng ký lại (Re-register) các gói UI thành công."
    } catch {
        GhiLog-AnToan "   - Lỗi nhẹ khi nạp gói AppX, tiếp tục quy trình..."
    }

    # 4. Kích hoạt lại Windows Explorer
    GhiLog-AnToan "[4/4] Đang khởi động lại giao diện Windows Explorer..."
    Start-Sleep -Seconds 2 # Chờ 2 giây cho hệ thống dọn dẹp RAM
    Start-Process explorer.exe
    GhiLog-AnToan "   + Giao diện đã được kích hoạt lại."

    GhiLog-AnToan "=========================================================="
    GhiLog-AnToan ">>> HOÀN TẤT: TASKBAR VÀ START MENU ĐÃ SẴN SÀNG! <<<"
    GhiLog-AnToan "=========================================================="
    
    [System.Windows.Forms.MessageBox]::Show("Đã khắc phục lỗi treo Taskbar và Start Menu Win 11!`nBạn có thể click lại vào nút Windows để kiểm tra.", "Thành công", 0, 64)
}

# Chạy vào hệ thống động của VietToolbox
if (Get-Command ChayTacVu -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang Fix lỗi treo Taskbar Win 11..." $LogicThucThi
} else {
    &$LogicThucThi
}