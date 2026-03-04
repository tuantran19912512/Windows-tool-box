Add-Type -AssemblyName System.Windows.Forms
Ghi-Log "-> Đang tìm Key OEM để kích hoạt lại..."

# Thử lấy Key bằng mọi cách
$OEMKey = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
if (!$OEMKey) { $OEMKey = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey }

if ($OEMKey) {
    Ghi-Log "-> Đã tìm thấy Key BIOS: $OEMKey. Đang tiến hành nạp..."
    # Nạp Key vào máy
    cscript //nologo $env:windir\system32\slmgr.vbs /ipk $OEMKey
    # Lệnh kích hoạt online
    cscript //nologo $env:windir\system32\slmgr.vbs /ato
    Ghi-Log "   + Đã chạy lệnh kích hoạt."
    [System.Windows.Forms.MessageBox]::Show("Đã nạp Key $OEMKey và gửi lệnh kích hoạt tới Microsoft!", "Thành công")
} else {
    Ghi-Log "!!! LỖI: Không tìm thấy Key OEM trong bảng ACPI của BIOS."
    [System.Windows.Forms.MessageBox]::Show("Không tìm thấy Key BIOS! Có thể máy này là máy lắp ráp (PC) hoặc không có bản quyền đi kèm máy.", "Lỗi", 0, 16)
}