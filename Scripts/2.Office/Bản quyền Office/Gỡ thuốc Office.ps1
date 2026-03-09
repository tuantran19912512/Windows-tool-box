Add-Type -AssemblyName System.Windows.Forms

# --- Hàm hỗ trợ tìm file OSPP.VBS ---
function Tim-OSPP {
    $Paths = @(
        "${env:ProgramFiles}\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles}\Microsoft Office\Office15\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OSPP.VBS"
    )
    foreach ($p in $Paths) { if (Test-Path $p) { return $p } }
    return $null
}

# --- Giao diện xác nhận ---
$XacNhan = [System.Windows.Forms.MessageBox]::Show("Bạn có chắc chắn muốn xóa sạch bản quyền Office hiện tại (KMS, Crack) để nạp Key mới không?", "Xác nhận dọn dẹp", "YesNo", "Warning")

if ($XacNhan -eq "Yes") {
    Global:Ghi-Log "=========================================="
    Global:Ghi-Log ">>> BẮT ĐẦU DỌN DẸP BẢN QUYỀN CRACK <<<"
    Global:Ghi-Log "=========================================="

    $v = Tim-OSPP
    if ($v) {
        # 1. Xóa máy chủ KMS ảo
        Global:Ghi-Log "1. Đang xóa cấu hình máy chủ KMS ảo..."
        cscript //nologo "$v" /remhst | Out-Null
        cscript //nologo "$v" /ckms-domain | Out-Null

        # 2. Xóa các tác vụ Crack chạy ngầm (ĐÃ FIX: BỎ CÁC TASK CHÍNH CHỦ CỦA WINDOWS)
        Global:Ghi-Log "2. Đang dọn dẹp các Scheduled Task rác của phần mềm Crack..."
        $Tasks = @("AutoKMS", "AutoPico", "KMSAuto", "KMSPico", "SppExtComObjHook")
        foreach ($t in $Tasks) {
            Get-ScheduledTask -TaskName "*$t*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        }

        # 3. Quét và gỡ toàn bộ Product Key hiện tại
        Global:Ghi-Log "3. Đang quét danh sách Key cài đặt..."
        $status = cscript //nologo "$v" /dstatus | Out-String
        $regex = "Last 5 characters of installed product key: (.{5})"
        $keys = [regex]::Matches($status, $regex) | ForEach-Object { $_.Groups[1].Value }

        if ($keys) {
            foreach ($key in $keys) {
                Global:Ghi-Log " -> Đang gỡ Key có đuôi: $key"
                cscript //nologo "$v" /unpkey:$key | Out-Null
            }
        } else {
            Global:Ghi-Log " -> Không tìm thấy Key nào để gỡ."
        }

        # 4. Làm sạch Registry KMS
        Global:Ghi-Log "4. Làm sạch Registry rác của KMS..."
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        Remove-ItemProperty -Path $regPath -Name "KeyManagementServiceName" -ErrorAction SilentlyContinue

        # 5. Khôi phục trạng thái mặc định (Rearm) và khởi động lại Dịch vụ (QUAN TRỌNG)
        Global:Ghi-Log "5. Đang Reset lại trạng thái bản quyền (Rearm) và làm mới hệ thống..."
        cscript //nologo "$v" /rearm | Out-Null
        
        # Khởi động lại dịch vụ cấp phép của Office để nhận diện trạng thái mới
        Restart-Service -Name "osppsvc" -Force -ErrorAction SilentlyContinue

        Global:Ghi-Log ">>> HOÀN TẤT! Office đã về trạng thái nguyên bản."
        [System.Windows.Forms.MessageBox]::Show("Đã gỡ sạch bản quyền Crack!`nOffice đã trở về trạng thái chưa kích hoạt (Zin) và sẵn sàng nạp Key mới.", "Thành công")
    } else {
        Global:Ghi-Log "LỖI: Không tìm thấy file OSPP.VBS. Vui lòng kiểm tra lại bộ cài Office."
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy công cụ OSPP.VBS!", "Lỗi", 0, 16)
    }
}