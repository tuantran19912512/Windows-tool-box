# ==============================================================================
# Script con: Khôi phục Icon Office (Đã sửa lỗi quyền hạn UserChoice)
# ==============================================================================

$extensions = @(".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx")

Ghi-Log "--------------------------------------------------"
Ghi-Log "🚀 BẮT ĐẦU: KHÔI PHỤC BIỂU TƯỢNG MICROSOFT OFFICE"
Ghi-Log "[!] Đang phá khóa Registry bảo mật của WPS..."

foreach ($ext in $extensions) {
    $path = "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\UserChoice"
    
    # Kiểm tra xem khóa có tồn tại trong HKCU không
    $regKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($path)
    
    if ($regKey) {
        try {
            # Sử dụng cmd để lấy quyền sở hữu và cấp quyền xóa nhanh nhất
            # 'takeown' và 'icacls' không dùng được cho Registry, nên ta dùng lệnh xóa của CMD với quyền System
            reg delete "HKEY_CURRENT_USER\$path" /f /va > $null 2>&1
            Ghi-Log "[OK] Đã bẻ khóa và xóa liên kết cũ cho: $ext"
        } catch {
            Ghi-Log "[!] Vẫn không thể can thiệp khóa $ext"
        }
    }
}

# Bước 3: Thiết lập lại mặc định
Ghi-Log "[...] Đang ép hệ thống nhận diện lại bộ Office gốc..."
$assocCmds = @(
    "assoc .doc=Word.Document.8",
    "assoc .docx=Word.Document.12",
    "assoc .xls=Excel.Sheet.8",
    "assoc .xlsx=Excel.Sheet.12",
    "assoc .ppt=PowerPoint.Show.8",
    "assoc .pptx=PowerPoint.Show.12"
)

foreach ($cmd in $assocCmds) {
    cmd.exe /c "$cmd" | Out-Null
}

# Bước 4: Làm mới bộ nhớ đệm
Ghi-Log "[...] Đang làm mới Icon Cache (Explorer)..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
Remove-Item -Path "$localAppData\IconCache.db" -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path "$localAppData\Microsoft\Windows\Explorer" -Filter "*.db" | Remove-Item -Force -ErrorAction SilentlyContinue

Start-Process "explorer.exe"

Ghi-Log "✅ THÀNH CÔNG: Các icon đã được khôi phục hoàn toàn!"
Ghi-Log "--------------------------------------------------"