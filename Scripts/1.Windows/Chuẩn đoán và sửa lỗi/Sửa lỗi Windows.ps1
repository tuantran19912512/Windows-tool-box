# ==============================================================================
# VIETTOOLBOX BÁC SĨ WINDOWS (V62.0 - CHỐT HẠ)
# Tính năng: Thử Offline -> Thử Online -> Nếu tạch thì báo Cài Lại Win.
# ==============================================================================

# --- BƯỚC 0: XÁC NHẬN ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$Confirm = [System.Windows.Forms.MessageBox]::Show("Tiến trình sửa lỗi chuyên sâu (30-60p) sắp bắt đầu.`n`nÔng có muốn tiếp tục không?", "VietToolbox: Xác nhận", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
if ($Confirm -eq "No") { exit }

# --- BƯỚC 1: ADMIN ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    break
}

$script:StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$script:IsStopping = $false

function Get-Time { $ts = $script:StopWatch.Elapsed; return "{0:00}:{1:00}" -f $ts.Minutes, $ts.Seconds }

function VietLog($msg, $percent = $null) {
    if (Get-Command "Ghi-Log" -ErrorAction SilentlyContinue) { Ghi-Log "Bác Sĩ: $msg" }
    if ($null -ne $script:progLabel) { $script:progLabel.Text = $msg }
    if ($null -ne $percent -and $null -ne $script:progressBar) { $script:progressBar.Value = $percent }
    [System.Windows.Forms.Application]::DoEvents()
}

# --- GIAO DIỆN ---
$script:progForm = New-Object System.Windows.Forms.Form
$script:progForm.Text = "🩺 VietToolbox: Bác Sĩ Windows"; $script:progForm.Size = "520,300"
$script:progForm.StartPosition = "CenterScreen"; $script:progForm.FormBorderStyle = "FixedToolWindow"; $script:progForm.TopMost = $true; $script:progForm.BackColor = "White"

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
$btnStop.Text = "🛑 DỪNG LẠI"; $btnStop.Location = "180,190"; $btnStop.Size = "150,45"; $btnStop.BackColor = "#D32F2F"; $btnStop.ForeColor = "White"; $btnStop.FlatStyle = "Flat"
$btnStop.Add_Click({ $script:IsStopping = $true; $btnStop.Text = "Đang dừng..."; $btnStop.Enabled = $false })

$script:progForm.Controls.AddRange(@($script:progLabel, $script:timeLabel, $script:progressBar, $groupAction, $btnStop))
$script:progForm.Show()

function Run-Task-Silent($FileName, $TaskArgs) {
    $p = Start-Process -FilePath $FileName -ArgumentList $TaskArgs -PassThru -WindowStyle Hidden -Wait
    return $p.ExitCode
}

function Run-Task-Visual($FileName, $TaskArgs, $BaseP, $MaxP) {
    if ($script:IsStopping) { return }
    $proc = Start-Process -FilePath $FileName -ArgumentList $TaskArgs -PassThru -WindowStyle Hidden
    if ($null -ne $proc) {
        try { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch {}
        $val = $BaseP
        while (!$proc.HasExited) {
            if ($script:IsStopping) { try { Stop-Process -Id $proc.Id -Force } catch {}; return }
            if ($val -lt $MaxP) { $val += 0.2; $script:progressBar.Value = [int]$val }
            $script:timeLabel.Text = "Time: $(Get-Time)"; [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 150
        }
    }
}

# --- THỰC THI ---
try {
    VietLog "🧹 Đang tối ưu nhanh..." 10
    Run-Task-Visual "dism.exe" "/Online /Cleanup-Image /StartComponentCleanup" 10 25

    # TẦNG 1: THỬ OFFLINE
    VietLog "🚀 Đang sửa lỗi hệ thống (Tầng 1: Offline)..." 25
    $code = Run-Task-Silent "dism.exe" "/Online /Cleanup-Image /RestoreHealth /LimitAccess"
    
    $FinalFail = $false
    if ($code -ne 0) {
        # TẦNG 2: THỬ ONLINE
        VietLog "⚠️ Tầng 1 thất bại. Đang thử Tầng 2 (Online)..." 30
        Run-Task-Visual "dism.exe" "/Online /Cleanup-Image /RestoreHealth" 30 70
        
        # Kiểm tra lại lần cuối sau khi thử Online
        $checkAgain = Run-Task-Silent "dism.exe" "/Online /Cleanup-Image /CheckHealth"
        if ($checkAgain -ne 0) { $FinalFail = $true }
    } else {
        VietLog "✅ Đã sửa xong bằng file nội bộ!" 70
    }

    # TẦNG 3: PHÁN QUYẾT
    if ($FinalFail) {
        VietLog "❌ LỖI NẶNG: Không thể sửa lỗi!" 100
        [System.Windows.Forms.MessageBox]::Show("CẢNH BÁO: Hệ điều hành Windows bị hỏng quá nặng!`n`nCác công cụ sửa chữa tự động không thể phục hồi. Khuyên ông nên SAO LƯU DỮ LIỆU và CÀI LẠI WINDOWS mới để đảm bảo ổn định.", "VietToolbox: Phán Quyết", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } else {
        # Nếu DISM ổn thì mới chạy SFC cho trọn bộ
        VietLog "🔍 Đang chốt hạ file hệ thống (SFC)..." 70
        Run-Task-Visual "sfc.exe" "/scannow" 70 95
        VietLog "🏁 HOÀN TẤT TRONG $(Get-Time)!" 100
    }

    Start-Sleep -Seconds 3
    if ($rbRestart.Checked) { Restart-Computer -Force }
    elseif ($rbShutdown.Checked) { Stop-Computer -Force }

} catch {
    VietLog "Đã dừng."
} finally {
    if ($null -ne $script:progForm) { $script:progForm.Close() }
}