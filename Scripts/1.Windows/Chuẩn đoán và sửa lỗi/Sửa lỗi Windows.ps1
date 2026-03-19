# ==============================================================================
# VIETTOOLBOX BÁC SĨ WINDOWS (V59.0 - FIX TREO DISM)
# Châm ngôn: "Không để khách đợi, không để máy treo"
# ==============================================================================

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    break
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
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
$script:progForm.Text = "🩺 Sửa Lỗi Siêu Tốc (Anti-Hang)"; $script:progForm.Size = "520,220"
$script:progForm.StartPosition = "CenterScreen"; $script:progForm.FormBorderStyle = "FixedToolWindow"; $script:progForm.TopMost = $true; $script:progForm.BackColor = "White"

$script:progLabel = New-Object System.Windows.Forms.Label
$script:progLabel.Text = "Đang khởi tạo..."; $script:progLabel.Location = "20,20"; $script:progLabel.Size = "350,25"; $script:progLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$script:timeLabel = New-Object System.Windows.Forms.Label
$script:timeLabel.Text = "Time: 00:00"; $script:timeLabel.Location = "380,22"; $script:timeLabel.Size = "100,20"; $script:timeLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight; $script:timeLabel.ForeColor = "Gray"

$script:progressBar = New-Object System.Windows.Forms.ProgressBar
$script:progressBar.Location = "20,60"; $script:progressBar.Size = "460,30"

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "🛑 DỪNG NGAY"; $btnStop.Location = "180,110"; $btnStop.Size = "150,45"; $btnStop.BackColor = "#D32F2F"; $btnStop.ForeColor = "White"; $btnStop.FlatStyle = "Flat"
$btnStop.Add_Click({ $script:IsStopping = $true; $btnStop.Text = "Đang dừng..."; $btnStop.Enabled = $false })

$script:progForm.Controls.AddRange(@($script:progLabel, $script:timeLabel, $script:progressBar, $btnStop))
$script:progForm.Show()

function Run-Task-Turbo($FileName, $TaskArgs, $BaseP, $MaxP) {
    if ($script:IsStopping) { return }
    $proc = Start-Process -FilePath $FileName -ArgumentList $TaskArgs -PassThru -WindowStyle Hidden
    if ($null -ne $proc) {
        try { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch {}
        $val = $BaseP
        while (!$proc.HasExited) {
            if ($script:IsStopping) { try { Stop-Process -Id $proc.Id -Force } catch {}; return }
            if ($val -lt $MaxP) { $val += 0.4; $script:progressBar.Value = [int]$val }
            $script:timeLabel.Text = "Time: $(Get-Time)"; [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 150
        }
    }
}

# --- THỰC THI TURBO V2 ---
try {
    # BƯỚC 0: "THÔNG CỐNG" DỊCH VỤ (Chống treo nửa đường)
    VietLog "⚙️ Đang dọn đường cho DISM..." 5
    net stop wuauserv /y | Out-Null
    net start wuauserv | Out-Null
    
    # BƯỚC 1: DỌN RÁC KHO ẢNH (Giúp RestoreHealth chạy nhanh hơn gấp đôi)
    VietLog "🧹 Đang dọn dẹp kho ảnh (Cleanup)..." 10
    Run-Task-Turbo "dism.exe" "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" 10 30

    # BƯỚC 2: RESTOREHEALTH (Bản nâng cấp)
    VietLog "🚀 Đang sửa lỗi hệ thống (RestoreHealth)..." 35
    # Thêm LimitAccess để ưu tiên file nội bộ, tránh treo mạng
    Run-Task-Turbo "dism.exe" "/Online /Cleanup-Image /RestoreHealth /LimitAccess" 35 70
    if ($script:IsStopping) { throw "Dừng tool." }

    # BƯỚC 3: SFC (Chốt hạ)
    VietLog "🔍 Đang sửa lỗi file thực thi (SFC)..." 70
    Run-Task-Turbo "sfc.exe" "/scannow" 70 95

    VietLog "🏁 XONG! Tổng thời gian: $(Get-Time)" 100
    Start-Sleep -Seconds 2

} catch {
    VietLog "Đã dừng tiến trình."
} finally {
    if ($null -ne $script:progForm) { $script:progForm.Close() }
}