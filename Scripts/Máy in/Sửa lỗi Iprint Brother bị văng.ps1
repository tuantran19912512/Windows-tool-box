Add-Type -AssemblyName System.Windows.Forms

# Hàm tự thích nghi
function GhiLog-AnToan ($text) {
    if (Get-Command GhiLog -ErrorAction SilentlyContinue) { GhiLog $text }
    else { Write-Host $text }
}

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    GhiLog-AnToan "=========================================================="
    GhiLog-AnToan ">>> FIX LỖI SCAN BROTHER (CRASH / BỊ VĂNG APP) <<<"
    GhiLog-AnToan "=========================================================="
    
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    
    GhiLog-AnToan "-> Đang khôi phục đường dẫn thư mục Documents (Personal)..."
    
    # Dùng -Type ExpandString cực kỳ quan trọng vì giá trị chứa biến môi trường %USERPROFILE%
    Set-ItemProperty -Path $key -Name "Personal" -Value "%USERPROFILE%\Documents" -Type ExpandString -ErrorAction SilentlyContinue
    
    GhiLog-AnToan "   + Đã Reset đường dẫn 'Personal' về mặc định hệ thống."
    GhiLog-AnToan ">>> HOÀN TẤT QUY TRÌNH SỬA LỖI BROTHER."
    
    [System.Windows.Forms.MessageBox]::Show("Đã Reset đường dẫn User Shell Folders thành công.`nVui lòng Log out (Đăng xuất) hoặc Khởi động lại máy để hệ thống nhận đường dẫn mới.", "Thành công", 0, 64) 
}

# Chạy vào hệ thống động của VietToolbox
if (Get-Command ChayTacVu -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang Fix lỗi Scan Brother..." $LogicThucThi
} else {
    &$LogicThucThi
}