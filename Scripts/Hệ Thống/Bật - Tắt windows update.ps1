Add-Type -AssemblyName System.Windows.Forms

$LuaChon = [Microsoft.VisualBasic.Interaction]::MsgBox(
    "CHẾ ĐỘ KHÓA WINDOWS UPDATE CHUYÊN SÂU`n`n" +
    "[YES]: TẮT VÀ CHẶN Update tự bật lại (Hard Disable)`n" +
    "[NO]: KHÔI PHỤC lại trạng thái mặc định`n" +
    "[CANCEL]: Thoát", 
    "YesNoCancel,Critical", "QUẢN LÝ UPDATE VĨNH VIỄN"
)

# Hàm thực thi lệnh Registry và ghi Log
function Chay-Reg-Update($lenh) {
    $kq = Invoke-Expression "$lenh 2>&1" | Out-String
    if ($kq) { Ghi-Log "   [Registry]: $($kq.Trim())" }
}

if ($LuaChon -eq "Yes") {
    Ghi-Log ">>> ĐANG TIẾN HÀNH KHÓA VĨNH VIỄN WINDOWS UPDATE..."

    # 1. Dừng và Vô hiệu hóa các dịch vụ cốt lõi
    Ghi-Log "-> Bước 1: Vô hiệu hóa các dịch vụ hệ thống..."
    $Services = @("wuauserv", "UsoSvc", "bits", "dosvc")
    foreach ($svc in $Services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Ghi-Log "   + Đã khóa dịch vụ: $svc"
    }

    # 2. Can thiệp sâu vào Medic Service (Thứ chuyên tự bật lại Update)
    Ghi-Log "-> Bước 2: Khóa Windows Update Medic Service..."
    Chay-Reg-Update 'reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaasMedicSvc" /v Start /t REG_DWORD /d 4 /f'

    # 3. Cấu hình Registry để chặn tự động tải (NoAutoUpdate)
    Ghi-Log "-> Bước 3: Thiết lập chính sách NoAutoUpdate..."
    Chay-Reg-Update 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f'
    Chay-Reg-Update 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f'

    # 4. Vô hiệu hóa Task Scheduler (Lịch trình tự động quét Update)
    Ghi-Log "-> Bước 4: Vô hiệu hóa các tác vụ tự động quét Update..."
    $Tasks = @(
        "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
        "\Microsoft\Windows\UpdateOrchestrator\Report policies",
        "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    )
    foreach ($task in $Tasks) {
        $kqTask = schtasks /change /tn "$task" /disable 2>&1 | Out-String
        Ghi-Log "   + Task $($task.Split('\')[-1]): $($kqTask.Trim())"
    }

    Ghi-Log ">>> ĐÃ KHÓA CHẶT WINDOWS UPDATE. HỆ THỐNG SẼ KHÔNG TỰ BẬT LẠI."
    [System.Windows.Forms.MessageBox]::Show("Đã KHÓA Windows Update vĩnh viễn thành công!", "Thông báo")
} 

elseif ($LuaChon -eq "No") {
    Ghi-Log ">>> ĐANG KHÔI PHỤC LẠI WINDOWS UPDATE..."

    # 1. Mở lại dịch vụ
    "wuauserv", "UsoSvc", "bits", "dosvc" | ForEach-Object {
        Set-Service -Name $_ -StartupType Manual -ErrorAction SilentlyContinue
        Ghi-Log "   + Đã mở lại: $_"
    }

    # 2. Mở lại Medic Service
    Chay-Reg-Update 'reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaasMedicSvc" /v Start /t REG_DWORD /d 3 /f'

    # 3. Xóa chính sách chặn
    Chay-Reg-Update 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f'
    
    # 4. Mở lại Task Scheduler
    schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /enable | Out-Null
    
    Ghi-Log ">>> ĐÃ KHÔI PHỤC TRẠNG THÁI UPDATE MẶC ĐỊNH."
    [System.Windows.Forms.MessageBox]::Show("Đã khôi phục Windows Update về mặc định!", "Thông báo")
}