# Đảm bảo thư viện WinForms được nạp để hiện thông báo cuối cùng
Add-Type -AssemblyName System.Windows.Forms

Ghi-Log ">>> ĐANG KIỂM TRA VÀ SỬA LỖI MÁY IN & LAN..."

# 1. Bật SMB 1.0
Ghi-Log "-> Đang kích hoạt SMB 1.0..."
try {
    # Hứng dữ liệu từ lệnh hệ thống bằng Out-String
    $res = Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop 2>&1 | Out-String
    if ($res) { Ghi-Log $res.Trim() }
    Ghi-Log "   + SMB 1.0 đã được xử lý."
} catch {
    Ghi-Log "   ! Lỗi bật SMB 1.0: $($_.Exception.Message)"
}
# ==============================================================================
# BƯỚC 2: CẤU HÌNH HỆ THỐNG (FIX LAN, RPC, PRINTNIGHTMARE)
# ==============================================================================
Ghi-Log "-> Đang bắt đầu cấu hình hệ thống (Fix LAN & PrintNightmare)..."

# --- Hàm phụ hỗ trợ ghi Log cho lệnh hệ thống ---
function Chay-Lenh($moTa, $lenh) {
    Ghi-Log "   + $moTa"
    $ketQua = Invoke-Expression "$lenh 2>&1" | Out-String
    if ($ketQua) { Ghi-Log "     [Kết quả]: $($ketQua.Trim())" }
}

# 1. Cấu hình Guest Authentication (Cho phép truy cập máy in không mật khẩu)
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force | Out-Null
    Ghi-Log "   + Đã kích hoạt AllowInsecureGuestAuth (Guest LAN)."
} catch {
    Ghi-Log "   ! Lỗi cấu hình GuestAuth: $($_.Exception.Message)"
}

# 2. Sao lưu Registry hiện tại (Phòng trường hợp cần khôi phục)
$backupDir = "C:\Tool_Backups"
if (!(Test-Path $backupDir)) { 
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null 
    Ghi-Log "   + Đã tạo thư mục sao lưu tại $backupDir"
}
Chay-Lenh "Đang sao lưu Registry máy in..." "reg export `"HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers`" `"$backupDir\Printers_Policies.reg`" /y"

# 3. Fix lỗi kết nối RPC & PrintNightmare (Lỗi 0x0000011b, 0x00000709...)
Ghi-Log "-> Đang nạp các bản vá Registry cho máy in..."
Chay-Lenh "Cấu hình RPC Named Pipe..." "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC`" /v RpcUseNamedPipeProtocol /t REG_DWORD /d 1 /f"
Chay-Lenh "Cấu hình cổng RPC TCP..." "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC`" /v RpcTcpPort /t REG_DWORD /d 0 /f"
Chay-Lenh "Cấu hình xác thực RPC..." "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC`" /v RpcAuthentication /t REG_DWORD /d 0 /f"
Chay-Lenh "Cấu hình quyền Admin cho Driver..." "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint`" /v RestrictDriverInstallationToAdministrators /t REG_DWORD /d 1 /f"
Chay-Lenh "Fix lỗi Privacy (0x11b)..." "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Print`" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f"

# 4. Cấu hình bảo mật LSA (Hỗ trợ máy cũ truy cập LAN)
Chay-Lenh "Cấu hình LSA Blank Password..." "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Lsa`" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f"
Chay-Lenh "Cấu hình LSA Anonymous..." "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Lsa`" /v EveryoneIncludesAnonymous /t REG_DWORD /d 1 /f"

# 5. Cấu hình SMB Signing (Tăng tốc độ và tương thích mạng LAN)
Ghi-Log "-> Đang tối ưu hóa SMB Client và Server..."
try {
    Set-SmbClientConfiguration -RequireSecuritySignature $false -Force -Confirm:$false 2>&1 | Out-Null
    Set-SmbServerConfiguration -RequireSecuritySignature $false -Force -Confirm:$false 2>&1 | Out-Null
    Ghi-Log "   + Đã tắt yêu cầu chữ ký số SMB (Tăng tốc LAN)."
} catch {
    Ghi-Log "   ! Lỗi cấu hình SMB: $($_.Exception.Message)"
}

Ghi-Log ">>> HOÀN TẤT CẤU HÌNH HỆ THỐNG BƯỚC 2."

# 3. Reset Spooler
Ghi-Log "-> Đang khởi động lại dịch vụ Print Spooler..."
try {
    Restart-Service -Name Spooler -Force -ErrorAction Stop
    Ghi-Log "   + Dịch vụ Spooler đã chạy lại thành công."
} catch {
    Ghi-Log "   ! Không thể khởi động Spooler: $($_.Exception.Message)"
}

Ghi-Log ">>> HOÀN TẤT QUY TRÌNH SỬA LỖI."

# Hiện thông báo kết thúc
[System.Windows.Forms.MessageBox]::Show("Đã sửa lỗi LAN & Máy in xong!`nVui lòng khởi động lại máy tính.", "Thông báo")