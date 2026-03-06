Add-Type -AssemblyName System.Windows.Forms

# 1. Cấu hình đường dẫn Gist của Bạn và file tạm
$Url = "https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd"
$TempFile = Join-Path $env:TEMP "Ohook_Activation.cmd"

Ghi-Log "=========================================="
Ghi-Log ">>> KÍCH HOẠT OFFICE OHOOK (CHẠY NGẦM) <<<"
Ghi-Log "=========================================="

# 2. Ép hệ thống dùng TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$FinalUrl = "$Url`?t=$((Get-Date).Ticks)"

# 3. Kiểm tra kết nối Internet
Ghi-Log "-> Đang kiểm tra kết nối Internet..."
if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue) {
    Ghi-Log "   + Internet: OK"
} else {
    Ghi-Log "!!! LỖI: Không có kết nối mạng."
    [System.Windows.Forms.MessageBox]::Show("Bạn ơi, máy khách không có mạng! Vui lòng kết nối Internet trước khi chạy thuốc nhé.", "Lỗi kết nối", 0, 16)
    exit
}

# 4. Tải file thuốc từ Gist và Xử lý lỗi LF/CRLF
try {
    Ghi-Log "-> Đang tải file Ohook từ Gist của Bạn..."
    
    $RawContent = Invoke-RestMethod -Uri $FinalUrl -UseBasicParsing
    
    $RawContent = $RawContent -replace "`r`n", "`n" -replace "`n", "`r`n"
    $RawContent += "`r`n`r`n"

    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($TempFile, $RawContent, $Utf8NoBom)
    
    Ghi-Log "   + Tải và xử lý định dạng file thành công."
} catch {
    Ghi-Log "!!! LỖI: Không thể tải file. Link Gist có thể bị chặn."
    [System.Windows.Forms.MessageBox]::Show("Lỗi tải file thuốc từ Gist! Bạn kiểm tra lại mạng nhé.", "Lỗi tải file", 0, 16)
    exit
}

# 5. Thực thi file thuốc chạy ngầm với quyền Admin
if (Test-Path $TempFile) {
    Ghi-Log "-> Đang khởi chạy Ohook ở chế độ ngầm (Silent Mode)..."
    try {
        # CHỖ SỬA LÀ ĐÂY: Thêm tham số /Ohook và -WindowStyle Hidden
        Start-Process cmd.exe -ArgumentList "/c `"$TempFile`" /Ohook" -WindowStyle Hidden -Verb RunAs -Wait
        
        Ghi-Log "   + Đã thực hiện xong quy trình Ohook."
        [System.Windows.Forms.MessageBox]::Show("Kích hoạt Ohook ngầm hoàn tất! Bạn mở Office lên kiểm tra nhé.", "Thành công")
    } catch {
        Ghi-Log "!!! LỖI: Không thể chạy file (Khách bấm 'No' khi hỏi Admin)."
    } finally {
        if (Test-Path $TempFile) { Remove-Item $TempFile -Force -ErrorAction SilentlyContinue }
    }
}