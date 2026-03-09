# ÉP POWERSHELL HIỂU TIẾNG VIỆT 100%
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- NẠP THƯ VIỆN ĐIỀU KHIỂN MULTIMEDIA ---
if (-not ([Ref].Assembly.GetType("VietToolbox.HardwareAPI"))) {
    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    namespace VietToolbox {
        public class HardwareAPI {
            [DllImport("winmm.dll")]
            public static extern int mciSendString(string command, StringBuilder buffer, int bufferSize, IntPtr hwndCallback);
            
            [DllImport("avicap32.dll")] 
            public static extern IntPtr capCreateCaptureWindowA(string lpszWindowName, int dwStyle, int x, int y, int nWidth, int nHeight, IntPtr hWndParent, int nID);
            
            [DllImport("user32.dll")] 
            public static extern bool SendMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);
        }
    }
"@
    try { Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue } catch { }
}

$LogicNgoaiVi = {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VietToolbox - Kiểm tra Webcam & Microphone"; $form.Size = "820,540"
    $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"

    $fontTieuDe = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $fontChu = New-Object System.Drawing.Font("Segoe UI", 10)

    # ==========================================
    # KHU VỰC 1: MICROPHONE (TRÁI)
    # ==========================================
    $pnlMic = New-Object System.Windows.Forms.Panel
    $pnlMic.Location = "20,20"; $pnlMic.Size = "370,450"; $pnlMic.BackColor = "#F4F5F7"
    
    $lblMic = New-Object System.Windows.Forms.Label
    $lblMic.Text = "KIỂM TRA MICROPHONE"; $lblMic.Font = $fontTieuDe; $lblMic.Location = "20,20"; $lblMic.Size = "330,30"; $lblMic.ForeColor = "#394E60"
    
    $lblMicDesc = New-Object System.Windows.Forms.Label
    $lblMicDesc.Text = "Hệ thống sẽ ghi âm 3 giây và phát lại để xác nhận thiết bị thu âm hoạt động tốt."; $lblMicDesc.Location = "20,60"; $lblMicDesc.Size = "330,40"; $lblMicDesc.ForeColor = "#666666"

    $cbMic = New-Object System.Windows.Forms.ComboBox
    $cbMic.Location = "20,110"; $cbMic.Size = "330,30"; $cbMic.DropDownStyle = "DropDownList"; $cbMic.Font = $fontChu
    
    $mics = Get-CimInstance Win32_PnPEntity | Where-Object { $_.Caption -match "Microphone" -or $_.Caption -match "Audio Input" }
    foreach ($m in $mics) { [void]$cbMic.Items.Add($m.Caption) }
    if ($cbMic.Items.Count -eq 0) { [void]$cbMic.Items.Add("Thiết bị mặc định của Windows") }
    $cbMic.SelectedIndex = 0

    $btnRecord = New-Object System.Windows.Forms.Button
    $btnRecord.Text = "GHI ÂM & PHÁT LẠI (3s)"; $btnRecord.Location = "20,160"; $btnRecord.Size = "330,45"
    $btnRecord.BackColor = "#0068FF"; $btnRecord.ForeColor = "White"; $btnRecord.FlatStyle = "Flat"; $btnRecord.Font = $fontTieuDe
    $btnRecord.FlatAppearance.BorderSize = 0

    $btnOpenSound = New-Object System.Windows.Forms.Button
    $btnOpenSound.Text = "Mở Cài đặt Âm thanh"; $btnOpenSound.Location = "20,220"; $btnOpenSound.Size = "330,35"
    $btnOpenSound.BackColor = "#E1E4E8"; $btnOpenSound.ForeColor = "#394E60"; $btnOpenSound.FlatStyle = "Flat"
    $btnOpenSound.FlatAppearance.BorderSize = 0
    $btnOpenSound.Add_Click({ Start-Process "mmsys.cpl" })

    $pnlMic.Controls.AddRange(@($lblMic, $lblMicDesc, $cbMic, $btnRecord, $btnOpenSound))
    $form.Controls.Add($pnlMic)

    # --- LOGIC GHI ÂM ---
    $btnRecord.Add_Click({
        $btnRecord.Enabled = $false
        $btnRecord.Text = "ĐANG THU ÂM... NÓI GÌ ĐÓ ĐI!"; $btnRecord.BackColor = "#E74C3C"
        $form.Refresh()
        
        [VietToolbox.HardwareAPI]::mciSendString("open new Type waveaudio Alias recsound", $null, 0, [IntPtr]::Zero) | Out-Null
        [VietToolbox.HardwareAPI]::mciSendString("record recsound", $null, 0, [IntPtr]::Zero) | Out-Null
        Start-Sleep -Seconds 3
        
        $btnRecord.Text = "ĐANG PHÁT LẠI..."; $btnRecord.BackColor = "#2ECC71"
        $form.Refresh()
        
        $tempWav = "$($env:TEMP)\viettoolbox_mic_test.wav"
        [VietToolbox.HardwareAPI]::mciSendString("save recsound $tempWav", $null, 0, [IntPtr]::Zero) | Out-Null
        [VietToolbox.HardwareAPI]::mciSendString("close recsound", $null, 0, [IntPtr]::Zero) | Out-Null
        
        if (Test-Path $tempWav) {
            $player = New-Object System.Media.SoundPlayer $tempWav; $player.PlaySync(); $player.Dispose()
            Remove-Item -Path $tempWav -Force -ErrorAction SilentlyContinue
        }

        $btnRecord.Text = "GHI ÂM & PHÁT LẠI (3s)"; $btnRecord.BackColor = "#0068FF"; $btnRecord.Enabled = $true
    })

    # ==========================================
    # KHU VỰC 2: WEBCAM (PHẢI)
    # ==========================================
    $pnlCamBg = New-Object System.Windows.Forms.Panel
    $pnlCamBg.Location = "410,20"; $pnlCamBg.Size = "370,450"; $pnlCamBg.BackColor = "#F4F5F7"
    
    $lblCam = New-Object System.Windows.Forms.Label
    $lblCam.Text = "KIỂM TRA WEBCAM"; $lblCam.Font = $fontTieuDe; $lblCam.Location = "20,20"; $lblCam.Size = "330,30"; $lblCam.ForeColor = "#394E60"

    # --- COMBOBOX CHỌN WEBCAM ---
    $cbCam = New-Object System.Windows.Forms.ComboBox
    $cbCam.Location = "20,60"; $cbCam.Size = "330,30"; $cbCam.DropDownStyle = "DropDownList"; $cbCam.Font = $fontChu
    
    $cams = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -match "Camera|Image" -or $_.Caption -match "Camera|Webcam" }
    foreach ($c in $cams) { [void]$cbCam.Items.Add($c.Caption) }
    
    $camScreen = New-Object System.Windows.Forms.Panel
    $camScreen.Location = "20,105"; $camScreen.Size = "330,260"; $camScreen.BackColor = "#1A1A1A"
    
    $btnStartCam = New-Object System.Windows.Forms.Button
    $btnStartCam.Text = "BẬT MÁY ẢNH"; $btnStartCam.Location = "20,380"; $btnStartCam.Size = "330,45"
    $btnStartCam.BackColor = "#0068FF"; $btnStartCam.ForeColor = "White"; $btnStartCam.FlatStyle = "Flat"; $btnStartCam.Font = $fontTieuDe; $btnStartCam.FlatAppearance.BorderSize = 0

    if ($cbCam.Items.Count -eq 0) { 
        [void]$cbCam.Items.Add("Không có thiết bị Webcam")
        $cbCam.Enabled = $false
        $btnStartCam.Enabled = $false
        $btnStartCam.BackColor = "#999999"
    } else {
        $cbCam.SelectedIndex = 0
    }

    $pnlCamBg.Controls.AddRange(@($lblCam, $cbCam, $camScreen, $btnStartCam))
    $form.Controls.Add($pnlCamBg)

    # --- LOGIC MỞ CAM ---
    $btnStartCam.Add_Click({
        if ($btnStartCam.Text -eq "BẬT MÁY ẢNH") {
            $idx = $cbCam.SelectedIndex
            $handle = [VietToolbox.HardwareAPI]::capCreateCaptureWindowA("Webcam", 0x50000000, 0, 0, 330, 260, $camScreen.Handle, 0)
            $btnStartCam.Tag = $handle 
            
            [VietToolbox.HardwareAPI]::SendMessage($handle, 0x40a, $idx, 0) | Out-Null
            [VietToolbox.HardwareAPI]::SendMessage($handle, 0x435, 1, 0) | Out-Null
            [VietToolbox.HardwareAPI]::SendMessage($handle, 0x432, 1, 0) | Out-Null
            
            $btnStartCam.Text = "TẮT MÁY ẢNH"; $btnStartCam.BackColor = "#E74C3C"
            $cbCam.Enabled = $false
        } else {
            $handle = $btnStartCam.Tag
            if ($null -ne $handle) { [VietToolbox.HardwareAPI]::SendMessage($handle, 0x40b, 0, 0) | Out-Null }
            $btnStartCam.Tag = $null
            $btnStartCam.Text = "BẬT MÁY ẢNH"; $btnStartCam.BackColor = "#0068FF"
            $cbCam.Enabled = $true
            $camScreen.Refresh()
        }
    })

    $form.Add_FormClosing({
        $handle = $btnStartCam.Tag
        if ($null -ne $handle) { [VietToolbox.HardwareAPI]::SendMessage($handle, 0x40b, 0, 0) | Out-Null }
        [VietToolbox.HardwareAPI]::mciSendString("close recsound", $null, 0, [IntPtr]::Zero) | Out-Null
    })

    $form.ShowDialog() | Out-Null
}

&$LogicNgoaiVi