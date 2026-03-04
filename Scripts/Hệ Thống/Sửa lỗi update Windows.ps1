Add-Type -AssemblyName System.Windows.Forms

Ghi-Log "=========================================================="
Ghi-Log ">>> CÔNG CỤ RESET & SỬA LỖI WINDOWS UPDATE <<<"
Ghi-Log "=========================================================="

# 1. Khai báo 4 dịch vụ tử huyệt của Windows Update
$UpdateServices = @("wuauserv", "bits", "cryptsvc", "msiserver")

# 2. Ép dừng các dịch vụ để mở khóa file
Ghi-Log "[1/3] Đang đóng băng các dịch vụ Windows Update & BITS..."
foreach ($svc in $UpdateServices) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Ghi-Log "   + Đã dừng dịch vụ: $svc"
    }
}

# 3. Quét sạch thư mục Cache chứa file lỗi/kẹt
Ghi-Log "[2/3] Đang dọn dẹp hang ổ chứa file Update bị lỗi..."

$Dir_SD = "C:\Windows\SoftwareDistribution"
$Dir_Cat = "C:\Windows\System32\catroot2"

if (Test-Path $Dir_SD) {
    Ghi-Log "   -> Đang làm sạch: SoftwareDistribution (DataStore & Download)"
    # Chỉ xóa ruột bên trong, giữ lại vỏ thư mục
    Remove-Item -Path "$Dir_SD\DataStore\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$Dir_SD\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Ghi-Log "   + Đã xóa cache tải về của Windows."
}

if (Test-Path $Dir_Cat) {
    Ghi-Log "   -> Đang làm sạch: catroot2 (Chữ ký điện tử)"
    Remove-Item -Path "$Dir_Cat\*" -Recurse -Force -ErrorAction SilentlyContinue
    Ghi-Log "   + Đã reset kho chữ ký số cập nhật."
}

# 4. Kích hoạt lại các dịch vụ
Ghi-Log "[3/3] Đang mồi lại các dịch vụ hệ thống..."
foreach ($svc in $UpdateServices) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Ghi-Log "   + Đã khởi chạy lại: $svc"
    }
}

Ghi-Log "=========================================================="
Ghi-Log ">>> HOÀN TẤT: HỆ THỐNG UPDATE ĐÃ ĐƯỢC LÀM MỚI <<<"
Ghi-Log "=========================================================="
[System.Windows.Forms.MessageBox]::Show("Đã sửa lỗi Windows Update thành công!`nKhách hàng có thể vào Settings -> Check for updates để tải lại từ đầu.", "VietToolbox Pro", 0, 64)