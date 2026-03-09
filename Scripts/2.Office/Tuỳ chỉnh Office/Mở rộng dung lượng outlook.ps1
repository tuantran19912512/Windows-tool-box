Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

Ghi-Log "=========================================="
Ghi-Log ">>> CẤU HÌNH MỞ RỘNG DUNG LƯỢNG OUTLOOK <<<"
Ghi-Log "=========================================="

# 1. Nhập dung lượng mong muốn (Tính bằng GB)
$InputGB = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Nhập dung lượng tối đa muốn mở rộng (Đơn vị: GB):`n(Mặc định Outlook là 50GB, bạn nên nhập 100 hoặc hơn)", 
    "MỞ RỘNG OUTLOOK", "100"
)

if ([string]::IsNullOrWhiteSpace($InputGB) -or !($InputGB -as [int])) {
    Ghi-Log "!!! Đã hủy hoặc nhập sai định dạng."
    return
}

$MaxMB = [int]$InputGB * 1024
$WarnMB = [int]($MaxMB * 0.95) # Cảnh báo khi đạt 95% dung lượng

# 2. Tự động nhận diện phiên bản Office đang cài đặt
$OfficeVersions = @{
    "16.0" = "Office 2016/2019/2021/365";
    "15.0" = "Office 2013";
    "14.0" = "Office 2010"
}

$FoundVersion = $null
foreach ($ver in $OfficeVersions.Keys) {
    $path = "HKCU:\Software\Microsoft\Office\$ver\Outlook\PST"
    if (Test-Path "HKCU:\Software\Microsoft\Office\$ver\Outlook") {
        $FoundVersion = $ver
        if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        break
    }
}

if ($null -eq $FoundVersion) {
    Ghi-Log "!!! LỖI: Không tìm thấy phiên bản Outlook phù hợp trên máy."
    [System.Windows.Forms.MessageBox]::Show("Không tìm thấy bộ cài Outlook!", "Lỗi", 0, 16)
    return
}

Ghi-Log "-> Đang cấu hình cho: $($OfficeVersions[$FoundVersion])"

# 3. Áp dụng Registry để nới rộng file .PST và .OST
try {
    $RegPath = "HKCU:\Software\Microsoft\Office\$FoundVersion\Outlook\PST"
    
    # MaxLargeFileSize: Dung lượng tối đa tuyệt đối
    Set-ItemProperty -Path $RegPath -Name "MaxLargeFileSize" -Value $MaxMB -Type DWord -Force
    # WarnLargeFileSize: Dung lượng bắt đầu hiện cảnh báo
    Set-ItemProperty -Path $RegPath -Name "WarnLargeFileSize" -Value $WarnMB -Type DWord -Force

    Ghi-Log "   + Thiết lập MaxLargeFileSize: $MaxMB MB (~$InputGB GB)"
    Ghi-Log "   + Thiết lập WarnLargeFileSize: $WarnMB MB"
    Ghi-Log ">>> THÀNH CÔNG! Đã nới rộng giới hạn Outlook."
} catch {
    Ghi-Log "   ! Lỗi Registry: $($_.Exception.Message)"
}

Ghi-Log "LƯU Ý: Bạn cần tắt hoàn toàn Outlook và mở lại để áp dụng."
[System.Windows.Forms.MessageBox]::Show("Đã mở rộng dung lượng Outlook lên $InputGB GB thành công!`nVui lòng khởi động lại Outlook.", "Thông báo")