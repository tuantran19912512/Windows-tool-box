Add-Type -AssemblyName System.Windows.Forms

# Khai báo thư mục backup (Tránh lỗi biến $backupDir bị rỗng)
$backupDir = Join-Path $env:TEMP "VietToolbox_Backup"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

# Hàm tự thích nghi (chống lỗi báo đỏ nếu tách file ra chạy riêng)
function GhiLog-AnToan ($text) {
    if (Get-Command GhiLog -ErrorAction SilentlyContinue) { GhiLog $text }
    else { Write-Host $text }
}

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    GhiLog-AnToan "=========================================================="
    GhiLog-AnToan ">>> BẮT ĐẦU FIX LỖI 3e3 (MÁY IN EPSON LQ-310) <<<"
    GhiLog-AnToan "=========================================================="
    
    $basePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3"
    $driverFound = $null
    
    if (Test-Path "$basePath\Epson LQ-310 ESC") { $driverFound = "Epson LQ-310 ESC" } 
    elseif (Test-Path "$basePath\Epson LQ-310 ESC/P2") { $driverFound = "Epson LQ-310 ESC/P2" }
    
    if ($driverFound) { 
        GhiLog-AnToan "   - Tìm thấy driver: $driverFound"
        
        GhiLog-AnToan "   - Đang sao lưu Registry để phòng hờ..."
        reg export "$basePath\$driverFound" "$backupDir\Epson_Backup.reg" /y 2>&1 | Out-Null
        
        GhiLog-AnToan "   - Đang ghi đè thuộc tính Driver (Attributes = 1)..."
        Set-ItemProperty -Path "$basePath\$driverFound" -Name "PrinterDriverAttributes" -Value 1 -Force
        
        GhiLog-AnToan "   - Đang khởi động lại Print Spooler..."
        Restart-Service -Name Spooler -Force -ErrorAction SilentlyContinue
        
        GhiLog-AnToan ">>> ĐÃ FIX XONG! Vui lòng in thử từ máy Client."
        [System.Windows.Forms.MessageBox]::Show("Đã sửa lỗi chia sẻ Epson 3e3 thành công!`nHãy in thử qua mạng LAN để kiểm tra.", "Thông báo", 0, 64) 
    } else { 
        GhiLog-AnToan "!!! LỖI: Không tìm thấy Driver Epson LQ-310 trên máy này."
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy Driver Epson LQ-310.`nVui lòng cài Driver bản quyền chuẩn trước khi chạy Fix.", "Lỗi hệ thống", 0, 16) 
    } 
}

# Chạy vào hệ thống động của VietToolbox
if (Get-Command ChayTacVu -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang Fix lỗi Epson 3e3..." $LogicThucThi
} else {
    &$LogicThucThi
}