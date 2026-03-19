# ==============================================================================
# VIETTOOLBOX: CHẨN ĐOÁN PRO (V69.1 - FIX LỖI PROGRESS BAR)
# LƯU Ý: Vẫn phải Save As -> Encoding: UTF-8 with BOM nhé ông!
# ==============================================================================

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    break
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- 🎯 BẢNG MÀU CHUYÊN NGHIỆP (DARK THEME) ---
$Color_BG = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E") 
$Color_Box = [System.Drawing.ColorTranslator]::FromHtml("#2D2D2D") 
$Color_Text = [System.Drawing.ColorTranslator]::FromHtml("#E0E0E0") 
$Color_Sub = [System.Drawing.ColorTranslator]::FromHtml("#A0A0A0") 
$Color_Accent = [System.Drawing.ColorTranslator]::FromHtml("#0078D7") # Xanh Windows
$Color_Danger = [System.Drawing.ColorTranslator]::FromHtml("#D32F2F") # Đỏ
$Color_Success = [System.Drawing.ColorTranslator]::FromHtml("#388E3C") # Xanh lá

# Font chuẩn
$Font_Title = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$Font_Text = New-Object System.Drawing.Font("Segoe UI", 11)
$Font_Mono = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
$Font_Btn = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Ép ký tự bằng BOM & UTF32 để hiện icon thực tế
$Chu_D = [char]0x0110 # Đ
$Icon_Disk = [char]::ConvertFromUtf32(0x1F4BE) # 💾
$Icon_Proc = [char]::ConvertFromUtf32(0x1F4CA) # 📊
$Icon_Scan = [char]::ConvertFromUtf32(0x1F50D) # 🔍
$Icon_Stop = [char]::ConvertFromUtf32(0x26D4)  # ⛔
$Icon_V = [char]::ConvertFromUtf32(0x2705) # ✅
$Icon_X = [char]::ConvertFromUtf32(0x274C) # ❌
$Spinner = @("|", "/", "-", "\")

$script:ReportData = @{ SFC = ""; DISM = ""; Latency = ""; Processes = ""; Status = "OK" }
$script:CurrentTask = 0
$script:GlobalProc = $null
$script:StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$script:UserStopped = $false
$script:AnimIndex = 0
$script:ProgressValue = 0 # Biến chạy phần trăm (0 đến 100)

# --- 1. GIAO DIỆN ĐANG QUÉT ---
$diagForm = New-Object System.Windows.Forms.Form
$diagForm.Text = "VietToolbox Pro"; $diagForm.Size = "520,280"
$diagForm.StartPosition = "CenterScreen"; $diagForm.FormBorderStyle = "FixedToolWindow"
$diagForm.TopMost = $true; $diagForm.BackColor = $Color_BG

$container = New-Object System.Windows.Forms.Panel
$container.Location = "20,20"; $container.Size = "465,205"; $container.BackColor = $Color_Box
$container.BorderStyle = "FixedSingle"

$diagLabel = New-Object System.Windows.Forms.Label
$diagLabel.Text = "$Icon_Scan Đang khởi tạo..."; $diagLabel.Location = "20,20"; $diagLabel.Size = "340,30"
$diagLabel.Font = $Font_Title; $diagLabel.ForeColor = $Color_Accent

$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Text = "00:00"; $timeLabel.Location = "360,25"; $timeLabel.Size = "80,25"; $timeLabel.TextAlign = "MiddleRight"
$timeLabel.ForeColor = $Color_Accent; $timeLabel.Font = $Font_Mono

# [CÁCH CHẾ PROGRESS BAR BẰNG PANEL]
$barBg = New-Object System.Windows.Forms.Panel
$barBg.Location = "20,70"; $barBg.Size = "420,20"; $barBg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#424242")

$barFill = New-Object System.Windows.Forms.Panel
$barFill.Location = "0,0"; $barFill.Size = "0,20"; $barFill.BackColor = $Color_Accent
$barBg.Controls.Add($barFill)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "$Icon_Stop HỦY BỎ QUÉT"; $btnStop.Location = "155,110"; $btnStop.Size = "150,45"
$btnStop.BackColor = $Color_Danger; $btnStop.ForeColor = "White"; $btnStop.FlatStyle = "Flat"
$btnStop.FlatAppearance.BorderSize = 0; $btnStop.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnStop.Font = $Font_Btn
$btnStop.Add_Click({
    $script:UserStopped = $true
    if ($null -ne $script:GlobalProc) { try { $script:GlobalProc.Kill() } catch {} }
    $diagTimer.Stop(); $diagForm.Close()
})

$diagSub = New-Object System.Windows.Forms.Label
$diagSub.Text = "Tiến trình nội soi dự kiến 3 - >10 phút. Vui lòng không tắt máy."; $diagSub.Location = "10,170"; $diagSub.Size = "440,25"
$diagSub.ForeColor = $Color_Sub; $diagSub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$diagSub.TextAlign = "MiddleCenter"

$container.Controls.AddRange(@($diagLabel, $timeLabel, $barBg, $btnStop, $diagSub))
$diagForm.Controls.Add($container)

# --- 2. HÀM HIỆN BẢNG KẾT QUẢ ---
function Show-Ket-Qua-Pro {
    $resForm = New-Object System.Windows.Forms.Form
    $resForm.Text = "BÁO CÁO TÌNH TRẠNG VIETTOOLBOX"; $resForm.Size = "500,450"
    $resForm.StartPosition = "CenterScreen"; $resForm.BackColor = $Color_BG
    $resForm.FormBorderStyle = "FixedDialog"; $resForm.MaximizeBox = $false

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "KẾT QUẢ CHẨN ĐOÁN"; $title.Location = "0,20"; $title.Size = "500,40"
    $title.TextAlign = "MiddleCenter"; $title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = $Color_Accent

    $box = New-Object System.Windows.Forms.Panel
    $box.Location = "30,70"; $box.Size = "425,250"; $box.BackColor = $Color_Box; $box.BorderStyle = "FixedSingle"

    $lblSFC = New-Object System.Windows.Forms.Label
    $iconS = if ($script:ReportData.SFC -match "Tốt") { $Icon_V } else { $Icon_X }
    $lblSFC.Text = "$iconS File hệ thống: " + $script:ReportData.SFC; $lblSFC.Location = "20,30"; $lblSFC.Size = "380,30"
    $lblSFC.Font = $Font_Text; $lblSFC.ForeColor = if ($script:ReportData.SFC -match "Tốt") { $Color_Success } else { $Color_Danger }

    $lblDISM = New-Object System.Windows.Forms.Label
    $iconD = if ($script:ReportData.DISM -match "Sạch") { $Icon_V } else { $Icon_X }
    $lblDISM.Text = "$iconD Kho ảnh Windows: " + $script:ReportData.DISM; $lblDISM.Location = "20,75"; $lblDISM.Size = "380,30"
    $lblDISM.Font = $Font_Text; $lblDISM.ForeColor = if ($script:ReportData.DISM -match "Sạch") { $Color_Success } else { $Color_Danger }

    $lblLat = New-Object System.Windows.Forms.Label
    $lblLat.Text = "$Icon_Disk Độ trễ ổ cứng: " + $script:ReportData.Latency + " ms"; $lblLat.Location = "20,120"; $lblLat.Size = "380,30"
    $lblLat.Font = $Font_Text; $lblLat.ForeColor = $Color_Text

    $lblProc = New-Object System.Windows.Forms.Label
    $lblProc.Text = "$Icon_Proc Tiến trình ngầm: " + $script:ReportData.Processes + " Processes"; $lblProc.Location = "20,165"; $lblProc.Size = "380,30"
    $lblProc.Font = $Font_Text; $lblProc.ForeColor = $Color_Text

    $advice = New-Object System.Windows.Forms.Label
    $adviceText = if ($script:ReportData.Status -eq "OK") { "✅ MÁY ĐANG HOẠT ĐỘNG TỐT" } else { "⚠️ CẦN CHẠY BỘ SỬA LỖI CHUYÊN SÂU" }
    $advice.Text = $adviceText; $advice.Location = "20,210"; $advice.Size = "380,30"; $advice.TextAlign = "MiddleCenter"
    $advice.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $advice.ForeColor = if ($script:ReportData.Status -eq "OK") { $Color_Accent } else { [System.Drawing.ColorTranslator]::FromHtml("#FF9100") }

    $box.Controls.AddRange(@($lblSFC, $lblDISM, $lblLat, $lblProc, $advice))

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "ĐÃ HIỂU"; $btnOk.Location = "175,340"; $btnOk.Size = "150,45"
    $btnOk.BackColor = $Color_Accent; $btnOk.ForeColor = "White"; $btnOk.FlatStyle = "Flat"
    $btnOk.FlatAppearance.BorderSize = 0; $btnOk.Font = $Font_Btn; $btnOk.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnOk.Add_Click({ $resForm.Close() })

    $resForm.Controls.AddRange(@($title, $box, $btnOk))
    $resForm.ShowDialog()
}

# --- 3. BỘ NÃO TIMER ---
$diagTimer = New-Object System.Windows.Forms.Timer
$diagTimer.Interval = 200 
$diagTimer.Add_Tick({
    $timeLabel.Text = "{0:00}:{1:00}" -f $script:StopWatch.Elapsed.Minutes, $script:StopWatch.Elapsed.Seconds
    $script:AnimIndex++
    $spin = $Spinner[$script:AnimIndex % 4]
    $dots = "." * ($script:AnimIndex % 5)
    $taskTitle = if ($script:CurrentTask -eq 0) { "nội soi File hệ thống" } else { "quét kho ảnh Windows" }
    
    $diagLabel.Text = "[$spin] $Icon_Scan $Chu_D" + "ang $taskTitle $dots"

    if ($null -eq $script:GlobalProc) {
        if ($script:CurrentTask -eq 0) {
            $p = New-Object System.Diagnostics.ProcessStartInfo -Property @{FileName="cmd.exe"; Arguments="/c sfc /verifyonly"; WindowStyle="Hidden"; CreateNoWindow=$true}
            $script:GlobalProc = [System.Diagnostics.Process]::Start($p)
        } elseif ($script:CurrentTask -eq 1) {
            $p = New-Object System.Diagnostics.ProcessStartInfo -Property @{FileName="cmd.exe"; Arguments="/c dism /online /cleanup-image /checkhealth"; WindowStyle="Hidden"; CreateNoWindow=$true}
            $script:GlobalProc = [System.Diagnostics.Process]::Start($p)
        }
    } else {
        # Tăng phần trăm thanh giả lập
        if ($script:ProgressValue -lt 98) { $script:ProgressValue += 1 }
        
        # Cập nhật chiều dài của thanh màu Xanh
        $barFill.Width = [math]::Round(($script:ProgressValue / 100) * $barBg.Width)

        if ($script:GlobalProc.HasExited) {
            $code = $script:GlobalProc.ExitCode
            if ($script:CurrentTask -eq 0) {
                $script:ReportData.SFC = if ($code -eq 0) { "Tốt" } else { "Bị lỗi" }
                if ($code -ne 0) { $script:ReportData.Status = "FAIL" }
                $script:CurrentTask = 1; $script:ProgressValue = 50
            } elseif ($script:CurrentTask -eq 1) {
                $script:ReportData.DISM = if ($code -eq 0) { "Sạch" } else { "Bị hỏng" }
                if ($code -ne 0) { $script:ReportData.Status = "FAIL" }
                $script:CurrentTask = 2; $script:ProgressValue = 100
            }
            $script:GlobalProc = $null
        }
    }

    if ($script:CurrentTask -eq 2) {
        $diagTimer.Stop(); $script:StopWatch.Stop()
        $barFill.Width = $barBg.Width # Ép đầy thanh
        $perf = Get-Counter -Counter "\PhysicalDisk(_Total)\Avg. Disk sec/Read" -MaxSamples 1
        $script:ReportData.Latency = [int]($perf.CounterSamples[0].CookedValue * 1000)
        $script:ReportData.Processes = (Get-Process).Count
        $diagForm.Close()
    }
})

$diagForm.Add_Shown({ $diagTimer.Start() })
$diagForm.ShowDialog() | Out-Null

if ($script:CurrentTask -eq 2 -and -not $script:UserStopped) { Show-Ket-Qua-Pro }