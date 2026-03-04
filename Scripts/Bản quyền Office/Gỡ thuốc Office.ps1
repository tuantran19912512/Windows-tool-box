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
    Ghi-Log "=========================================="
    Ghi-Log ">>> BẮT ĐẦU DỌN DẸP BẢN QUYỀN CRACK <<<"
    Ghi-Log "=========================================="

    $v = Tim-OSPP
    if ($v) {
        # 1. Xóa máy chủ KMS ảo
        Ghi-Log "1. Đang xóa máy chủ KMS và Domain..."
        cscript //nologo "$v" /remhst | Out-Null
        cscript //nologo "$v" /ckms-domain | Out-Null

        # 2. Xóa các tác vụ Crack chạy ngầm
        Ghi-Log "2. Đang xóa các Scheduled Task (AutoKMS, Pico...)"
        $Tasks = "AutoKMS", "AutoPico", "KMS", "OfficeSoftwareProtection"
        foreach ($t in $Tasks) {
            Get-ScheduledTask -TaskName "*$t*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        }

        # 3. Quét và gỡ toàn bộ Product Key hiện tại
        Ghi-Log "3. Đang quét danh sách Key cài đặt..."
        $status = cscript //nologo "$v" /dstatus | Out-String
        $regex = "Last 5 characters of installed product key: (.{5})"
        $keys = [regex]::Matches($status, $regex) | ForEach-Object { $_.Groups[1].Value }

        if ($keys) {
            foreach ($key in $keys) {
                Ghi-Log " -> Đang gỡ Key đuôi: $key"
                cscript //nologo "$v" /unpkey:$key | Out-Null
            }
        } else {
            Ghi-Log " -> Không tìm thấy Key nào để gỡ."
        }

        # 4. Làm sạch Registry
        Ghi-Log "4. Làm sạch Registry SoftwareProtectionPlatform..."
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        Remove-ItemProperty -Path $regPath -Name "KeyManagementServiceName" -ErrorAction SilentlyContinue

        Ghi-Log ">>> HOÀN TẤT! Office đã về trạng thái sạch (Zin)."
        [System.Windows.Forms.MessageBox]::Show("Đã gỡ sạch bản quyền Crack! Office đã sẵn sàng để nạp Key mới.", "Thành công")
    } else {
        Ghi-Log "LỖI: Không tìm thấy file OSPP.VBS. Vui lòng kiểm tra lại bộ cài Office."
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy công cụ OSPP.VBS!", "Lỗi", 0, 16)
    }
}