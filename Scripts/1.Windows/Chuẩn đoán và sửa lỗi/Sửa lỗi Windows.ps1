# ==============================================================================
# VIETTOOLBOX BÁC SĨ WINDOWS (V62.4 - FIX LỖI CHỚP TẮT ĐỘT NGỘT)
# Tính năng: Thử Offline -> Thử Online -> Tắt ngay lập tức khi bấm Dừng.
# LƯU Ý: Nhớ Save As -> Encoding: UTF-8 with BOM nhé!
# ==============================================================================

# --- BƯỚC 1: ÉP QUYỀN ADMIN TRƯỚC TIÊN ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    break
}

# --- BƯỚC 2: XÁC NHẬN (Đã chuyển xuống đây để không bị hỏi 2 lần) ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$Confirm = [System.Windows.Forms.MessageBox]::Show("Tiến trình sửa lỗi chuyên sâu (30-60p) sắp bắt đầu.`n`nÔng có muốn tiếp tục không?", "VietToolbox: Xác nhận", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
if ($Confirm -eq "No") { exit }

# --- KHỞI TẠO BIẾN ---
$script:StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$script:IsStopping = $false

function Get-Time { $ts = $script:StopWatch.Elapsed; return "{0:00}:{1:00}" -f $ts.Minutes, $ts.Seconds }

function VietLog($msg, $percent = $null) {
    if ($null -ne $script:progLabel) { $script:progLabel.Text = $msg }
    if ($null -ne $percent -and $null -ne $script:progressBar) { $script:progressBar.Value = $percent }
    [System.Windows.Forms.Application]::DoEvents()
}

# --- GIAO DIỆN ---
$script:progForm = New-Object System.Windows.Forms.Form
$script:progForm.Text = "🩺 VietToolbox: Bác Sĩ Windows"; $script:progForm.Size = "520,300"
$script:progForm.StartPosition = "CenterScreen"
$script:progForm.FormBorderStyle = "FixedSingle" 
$script:progForm.MinimizeBox = $true             
$script:progForm.MaximizeBox = $false
$script:progForm.TopMost = $true; $script:progForm.BackColor = "White"

$script:progLabel = New-Object System.Windows.Forms.Label
$script:progLabel.Text = "Đang khởi tạo..."; $script:progLabel.Location = "20,20"; $script:progLabel.Size = "350,25"; $script:progLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$script:timeLabel = New-Object System.Windows.Forms.Label
$script:timeLabel.Text = "Time: 00:00"; $script:timeLabel.Location = "380,22"; $script:timeLabel.Size = "100,20"; $script:timeLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight; $script:timeLabel.ForeColor = "Gray"

$script:progressBar = New-Object System.Windows.Forms.ProgressBar
$script:progressBar.Location = "20,60"; $script:progressBar.Size = "460,30"

$groupAction = New-Object System.Windows.Forms.GroupBox
$groupAction.Text = "Sau khi xong sẽ:"; $groupAction.Location = "20,100"; $groupAction.Size = "460,70"
$rbNone = New-Object System.Windows.Forms.RadioButton
$rbNone.Text = "Để nguyên"; $rbNone.Location = "20,30"; $rbNone.Checked = $true; $rbNone.AutoSize = $true
$rbRestart = New-Object System.Windows.Forms.RadioButton
$rbRestart.Text = "Khởi động lại"; $rbRestart.Location = "160,30"; $rbRestart.AutoSize = $true
$rbShutdown = New-Object System.Windows.Forms.RadioButton
$rbShutdown.Text = "Tắt máy"; $rbShutdown.Location = "310,30"; $rbShutdown.AutoSize = $true
$groupAction.Controls.AddRange(@($rbNone, $rbRestart, $rbShutdown))

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "🛑 DỪNG LẠI"; $btnStop.Location = "180,190"; $btnStop.Size = "150,45"; $btnStop.BackColor = "#D32F2F"; $btnStop.ForeColor = "White"; $btnStop.FlatStyle = "Flat"; $btnStop.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnStop.Add_Click({ 
    $script:IsStopping = $true
    $btnStop.Text = "Đang ngắt..."
    $btnStop.Enabled = $false
    # Giết sạch tiến trình ngầm
    Start-Process cmd.exe -ArgumentList "/c taskkill /F /IM dism.exe /T 2>nul & taskkill /F /IM sfc.exe /T 2>nul" -WindowStyle Hidden
})

$script:progForm.Controls.AddRange(@($script:progLabel, $script:timeLabel, $script:progressBar, $groupAction, $btnStop))
$script:progForm.Show()

# --- HÀM CHẠY TIẾN TRÌNH (ĐÃ FIX LỖI TỪ KHÓA CẤM) ---
function Run-Task($TaskCmd, $TaskArgs, $startVal, $endVal) {
    if ($script:IsStopping) { throw "USER_STOPPED" }
    
    # Dùng đúng tên biến, không dùng chữ cấm $args
    $proc = Start-Process -FilePath $TaskCmd -ArgumentList $TaskArgs -WindowStyle Hidden -PassThru
    
    if ($null -ne $proc) {
        try { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch {}
        $val = $startVal
        while (-not $proc.HasExited) {
            if ($script:IsStopping) { throw "USER_STOPPED" } 
            if ($val -lt $endVal) { $val += 0.05; $script:progressBar.Value = [int]$val }
            $script:timeLabel.Text = "Time: $(Get-Time)"
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 150
        }
        return $proc.ExitCode
    }
    return -1
}

# --- THỰC THI CHÍNH ---
try {
    VietLog "🧹 Đang tối ưu nhanh..." 10
    Run-Task "dism.exe" "/Online /Cleanup-Image /StartComponentCleanup" 10 25 | Out-Null

    # TẦNG 1: THỬ OFFLINE
    VietLog "🚀 Đang sửa lỗi hệ thống (Tầng 1: Offline)..." 25
    $code = Run-Task "dism.exe" "/Online /Cleanup-Image /RestoreHealth /LimitAccess" 25 35
    
    $FinalFail = $false
    if ($code -ne 0) {
        # TẦNG 2: THỬ ONLINE
        VietLog "⚠️ Tầng 1 thất bại. Đang thử Tầng 2 (Online)..." 35
        Run-Task "dism.exe" "/Online /Cleanup-Image /RestoreHealth" 35 70 | Out-Null
        
        # Kiểm tra lại lần cuối
        VietLog "⚠️ Đang kiểm tra lại tình trạng..." 70
        $checkAgain = Run-Task "dism.exe" "/Online /Cleanup-Image /CheckHealth" 70 75
        if ($checkAgain -ne 0) { $FinalFail = $true }
    } else {
        VietLog "✅ Đã sửa xong bằng file nội bộ!" 75
        $script:progressBar.Value = 75
    }

    # TẦNG 3: PHÁN QUYẾT
    if ($FinalFail) {
        VietLog "❌ LỖI NẶNG: Không thể sửa lỗi!" 100
        [System.Windows.Forms.MessageBox]::Show("CẢNH BÁO: Hệ điều hành Windows bị hỏng quá nặng!`n`nCác công cụ sửa chữa tự động không thể phục hồi. Khuyên ông nên SAO LƯU DỮ LIỆU và CÀI LẠI WINDOWS mới để đảm bảo ổn định.", "VietToolbox: Phán Quyết", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } else {
        VietLog "🔍 Đang chốt hạ file hệ thống (SFC)..." 75
        Run-Task "sfc.exe" "/scannow" 75 99 | Out-Null
        VietLog "🏁 HOÀN TẤT TRONG $(Get-Time)!" 100
        
        Start-Sleep -Seconds 3
        if ($rbRestart.Checked) { Restart-Computer -Force }
        elseif ($rbShutdown.Checked) { Stop-Computer -Force }
    }
} catch {
    if ($_.Exception.Message -match "USER_STOPPED") {
        VietLog "⛔ ĐÃ HỦY THEO YÊU CẦU!"
        Start-Sleep -Seconds 1
    } else {
        # Nếu có lỗi lạ khác, nó sẽ hiện lên bảng báo chứ không tự sát im lặng nữa!
        [System.Windows.Forms.MessageBox]::Show("Có lỗi xảy ra: " + $_.Exception.Message, "VietToolbox Lỗi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
} finally {
    if ($null -ne $script:progForm) { $script:progForm.Close() }
}