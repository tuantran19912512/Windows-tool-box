Add-Type -AssemblyName System.Windows.Forms
Ghi-Log "-> Đang truy tìm Key bản quyền (Deep Scan)..."

# Cách 1: Quét từ SoftwareLicensingService (Chuẩn nhất cho Win 10/11)
$OEMKey = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey

# Cách 2: Nếu cách 1 hụt, quét từ Win32_ComputerSystemProduct
if (!$OEMKey) { 
    $OEMKey = (Get-CimInstance Win32_ComputerSystemProduct).OA3xOriginalProductKey 
}

# Cách 3: Quét trực tiếp từ bảng ACPI (Dùng lược đồ WMI cổ điển)
if (!$OEMKey) {
    $OEMKey = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
}

# Lấy Key đang cài trong Windows (Registry)
$InstalledKey = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform").BackupProductKeyDefault

Ghi-Log "   + Key trong máy: $(if($InstalledKey){$InstalledKey}else{'Không thấy'})"
Ghi-Log "   + Key BIOS: $(if($OEMKey){$OEMKey}else{'Không tìm thấy trong BIOS'})"

$msg = "🔑 KEY ĐANG CÀI: `n$InstalledKey`n`n🏆 KEY GỐC BIOS (OEM): `n$(if($OEMKey){$OEMKey}else{'Máy này không có Key dính BIOS'})"
[System.Windows.Forms.MessageBox]::Show($msg, "Kết quả kiểm tra")