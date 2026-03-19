[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$OutlookToolV1_2 = {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "OUTLOOK QUICK CONFIG V1.2 - VIETTOOLBOX"; $form.Size = "500,450"; $form.BackColor = "#1E1E1E"; $form.StartPosition = "CenterScreen"
    $fNut = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fChu = New-Object System.Drawing.Font("Segoe UI", 9)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "HỖ TRỢ CẤU HÌNH OUTLOOK NHANH"
    $lblTitle.ForeColor = "#00D4FF"; $lblTitle.Font = $fNut; $lblTitle.Size = "440,30"; $lblTitle.Location = "20,20"
    $lblTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    # --- NÚT 1: MỞ CẤU HÌNH (THUẬT TOÁN DÒ TÌM) ---
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "1. MỞ CẤU HÌNH ACCOUNT (THỬ LẠI)"; $btnAdd.Location = "50,70"; $btnAdd.Size = "380,45"; $btnAdd.BackColor = "#2980B9"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"
    $btnAdd.Add_Click({
        # Cách 1: Thử gọi lệnh chuẩn của Control Panel
        $proc = Start-Process "control.exe" -ArgumentList "mlcfg32.cpl" -PassThru -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        
        # Cách 2: Nếu cách 1 không hiện (Process thoát sớm), thử tìm đường dẫn trực tiếp
        if ($proc.HasExited -or !$proc) {
            $paths = @(
                "C:\Program Files\Microsoft Office\root\Office16\MLCFG32.CPL",
                "C:\Program Files (x86)\Microsoft Office\root\Office16\MLCFG32.CPL",
                "C:\Program Files\Microsoft Office\Office16\MLCFG32.CPL",
                "C:\Program Files (x86)\Microsoft Office\Office16\MLCFG32.CPL"
            )
            $found = $false
            foreach ($p in $paths) {
                if (Test-Path $p) {
                    Start-Process "control.exe" -ArgumentList "`"$p`""
                    $found = $true; break
                }
            }
            
            # Cách 3: Nếu vẫn không thấy file CPL, dùng lệnh của chính Outlook
            if (-not $found) {
                Start-Process "outlook.exe" -ArgumentList "/profiles" -ErrorAction SilentlyContinue
            }
        }
    })

    # --- NÚT 2: FIX AUTODISCOVER (GIỮ NGUYÊN) ---
    $btnFix = New-Object System.Windows.Forms.Button; $btnFix.Text = "2. FIX LỖI AUTODISCOVER (O365)"; $btnFix.Location = "50,130"; $btnFix.Size = "380,45"; $btnFix.BackColor = "#D35400"; $btnFix.ForeColor = "White"; $btnFix.FlatStyle = "Flat"
    $btnFix.Add_Click({
        $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\AutoDiscover"
        if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "ExcludeHttpsRootDomain" -Value 1
        Set-ItemProperty -Path $regPath -Name "ExcludeHttpsLookupDomain" -Value 1
        Set-ItemProperty -Path $regPath -Name "ExcludeSrvRecord" -Value 1
        [System.Windows.Forms.MessageBox]::Show("Đã nạp Registry Fix AutoDiscover!")
    })

    # --- NÚT 3: DỌN CACHE ---
    $btnClean = New-Object System.Windows.Forms.Button; $btnClean.Text = "3. DỌN SẠCH CACHE & TEMP"; $btnClean.Location = "50,190"; $btnClean.Size = "380,45"; $btnClean.BackColor = "#27AE60"; $btnClean.ForeColor = "White"; $btnClean.FlatStyle = "Flat"
    $btnClean.Add_Click({
        $path = "$env:LOCALAPPDATA\Microsoft\Outlook"
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Include *.dat, *.tmp -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
            [System.Windows.Forms.MessageBox]::Show("Đã dọn sạch Cache!")
        }
    })

    # --- NÚT 4: RESET PROFILE ---
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "4. RESET PROFILE (LÀM LẠI TỪ ĐẦU)"; $btnReset.Location = "50,250"; $btnReset.Size = "380,45"; $btnReset.BackColor = "#C0392B"; $btnReset.ForeColor = "White"; $btnReset.FlatStyle = "Flat"
    $btnReset.Add_Click({
        $msg = [System.Windows.Forms.MessageBox]::Show("Việc này sẽ xóa hết Profile hiện tại, ông có chắc không?", "Cảnh báo", 4)
        if ($msg -eq "Yes") {
            Remove-Item -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\*" -Recurse -Force -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show("Đã reset! Hãy mở Outlook để tạo Profile mới.")
        }
    })

    $btnClose = New-Object System.Windows.Forms.Button; $btnClose.Text = "THOÁT"; $btnClose.Location = "180,340"; $btnClose.Size = "120,35"; $btnClose.BackColor = "#333"; $btnClose.ForeColor = "White"; $btnClose.FlatStyle = "Flat"
    $btnClose.Add_Click({ $form.Close() })

    $form.Controls.AddRange(@($lblTitle, $btnAdd, $btnFix, $btnClean, $btnReset, $btnClose))
    $form.ShowDialog() | Out-Null
}

&$OutlookToolV1_2