# ==============================================================================
# SCRIPT MODULE: SỬA LỖI BIỂU TƯỢNG & THUMBNAIL (BẢN ÉP XÓA)
# ==============================================================================

function Xuat-NhatKy($msg, $color = "Black") {
    if (Get-Command "Ghi-Log" -ErrorAction SilentlyContinue) {
        Ghi-Log $msg $color
    } else {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $msg"
    }
}

Xuat-NhatKy "=======================================" "Blue"
Xuat-NhatKy "[*] ĐANG ÉP DỌN DẸP CACHE BIỂU TƯỢNG & THUMBNAIL..." "Orange"

try {
    # 1. Diệt sạch Explorer và các tiến trình liên quan
    Xuat-NhatKy "[*] Đang cưỡng chế dừng Explorer..." "Gray"
    taskkill /f /im explorer.exe | Out-Null
    Start-Sleep -Seconds 1

    $explorerPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"

    # 2. Dùng lệnh CMD để xóa (Lệnh này ép xóa tốt hơn PowerShell)
    Xuat-NhatKy "[*] Đang quét sạch kho lưu trữ Cache..." "Gray"
    
    # Xóa IconCache cũ
    if (Test-Path "$env:LOCALAPPDATA\IconCache.db") {
        cmd /c "del /f /q `"$env:LOCALAPPDATA\IconCache.db`""
    }

    # Xóa toàn bộ file cache trong thư mục Explorer
    cmd /c "del /f /s /q /a `"$explorerPath\iconcache_*.db`""
    cmd /c "del /f /s /q /a `"$explorerPath\thumbcache_*.db`""

    # 3. Khởi động lại giao diện
    Xuat-NhatKy "[*] Đang khởi động lại giao diện mới..." "Gray"
    start explorer.exe

    Xuat-NhatKy "[OK] Đã ép xóa và làm mới thành công!" "Green"
    Xuat-NhatKy "=======================================" "Blue"

} catch {
    Xuat-NhatKy "[❌] LỖI CỰC NẶNG: Không thể xóa file ngay cả khi ép buộc!" "Red"
    start explorer.exe
}