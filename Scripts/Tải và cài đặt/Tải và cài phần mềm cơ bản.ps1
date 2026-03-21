# ==============================================================================
# VIETTOOLBOX PRO V44.22 - GIAO DIỆN CO GIÃN & FIX LỖI FONT (Ô VUÔNG)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- BIẾN CẤU HÌNH ---
$script:HuyCaiDat = $false
$script:IsSelectAll = $true
$githubUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv"
$localPath = Join-Path $env:TEMP "VietToolbox_List.csv"
$Global:WingetReady = $false
$Global:ChocoReady = $false

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents() }

# --- 1. KHỞI TẠO FORM CO GIÃN ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX PRO V44.22 - HE THONG CAI DAT TU DONG"
$form.Size = "1050,780"; $form.MinimumSize = "900,700"; $form.StartPosition = "CenterScreen"; $form.BackColor = "#F5F5F5"

$fBold = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 14); $fStd = New-Object System.Drawing.Font("Segoe UI", 10)

# Tiêu đề - Luôn ở trên cùng bên trái
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "DANH SACH PHAN MEM HE THONG"
$lblHeader.Location = "20,15"; $lblHeader.Size = "500,30"; $lblHeader.Font = $fTitle; $lblHeader.ForeColor = "#1A237E"

# Khung trạng thái môi trường - Co giãn theo chiều ngang (Top, Left, Right)
$gbEnv = New-Object System.Windows.Forms.GroupBox
$gbEnv.Text = " TRANG THAI HE THONG "; $gbEnv.Location = "20,55"; $gbEnv.Size = "990,65"; $gbEnv.Font = $fBold; $gbEnv.Anchor = "Top, Left, Right"
$lblWingetStat = New-Object System.Windows.Forms.Label; $lblWingetStat.Text = "Checking Winget..."; $lblWingetStat.Location = "20,30"; $lblWingetStat.Size = "450,25"
$lblChocoStat = New-Object System.Windows.Forms.Label; $lblChocoStat.Text = "Checking Choco..."; $lblChocoStat.Location = "480,30"; $lblChocoStat.Size = "450,25"
$gbEnv.Controls.AddRange(@($lblWingetStat, $lblChocoStat))

# Bảng danh sách App - Co giãn đa chiều (Top, Bottom, Left, Right)
$dgv = New-Object System.Windows.Forms.DataGridView
$dgv.Location = "20,135"; $dgv.Size = "990,200"; $dgv.BackgroundColor = "White"; $dgv.RowHeadersVisible = $false; $dgv.AllowUserToAddRows = $false
$dgv.SelectionMode = "FullRowSelect"; $dgv.BorderStyle = "FixedSingle"; $dgv.Anchor = "Top, Bottom, Left, Right"
$dgv.AutoSizeColumnsMode = "Fill" # Tu dong gian cot theo cua so
$dgv.EnableHeadersVisualStyles = $false; $dgv.ColumnHeadersHeight = 45; $dgv.ColumnHeadersDefaultCellStyle.BackColor = "#303F9F"; $dgv.ColumnHeadersDefaultCellStyle.ForeColor = "White"; $dgv.ColumnHeadersDefaultCellStyle.Font = $fBold

[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="CHON";Width=60;AutoSizeMode="None"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="TEN UNG DUNG"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Status";HeaderText="TRANG THAI";Width=200;AutoSizeMode="None"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="WID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="CID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="GID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Args";Visible=$false}))

# Thanh tien do & Thong bao - Bam vao day cua so (Bottom, Left, Right)
$lblQuetXong = New-Object System.Windows.Forms.Label; $lblQuetXong.Text = "Dang tai du lieu..."; $lblQuetXong.Location = "20,345"; $lblQuetXong.Size = "700,25"; $lblQuetXong.Font = $fBold; $lblQuetXong.Anchor = "Bottom, Left"
$pbTotal = New-Object System.Windows.Forms.ProgressBar; $pbTotal.Location = "20,375"; $pbTotal.Size = "990,20"; $pbTotal.Anchor = "Bottom, Left, Right"

# Khung Log - Co gian theo chieu ngang (Bottom, Left, Right)
$gbLog = New-Object System.Windows.Forms.GroupBox; $gbLog.Text = " CHI TIET CAI DAT "; $gbLog.Location = "20,405"; $gbLog.Size = "990,220"; $gbLog.Font = $fBold; $gbLog.Anchor = "Bottom, Left, Right"
$flowHub = New-Object System.Windows.Forms.FlowLayoutPanel; $flowHub.Dock = "Fill"; $flowHub.BackColor = "White"; $flowHub.AutoScroll = $true; $flowHub.Padding = New-Object System.Windows.Forms.Padding(10)
$gbLog.Controls.Add($flowHub)

# Bang nut bam - Bam vao day (Bottom, Left, Right)
$btnPanel = New-Object System.Windows.Forms.TableLayoutPanel; $btnPanel.Location = "20,640"; $btnPanel.Size = "990,70"; $btnPanel.ColumnCount = 5; $btnPanel.Anchor = "Bottom, Left, Right"
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 36)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 10)))

function Q-Btn($t, $c) { 
    $b = New-Object System.Windows.Forms.Button; $b.Text = $t; $b.BackColor = $c; $b.ForeColor = "White"; $b.Font = $fBold
    $b.FlatStyle = "Flat"; $b.Dock = "Fill"; $b.Margin = New-Object System.Windows.Forms.Padding(5); $b.FlatAppearance.BorderSize = 0; return $b 
}

$btnReload = Q-Btn "[REFRESH] NAP LIST" "#2E7D32"
$btnQuet = Q-Btn "[QUET] KIEM TRA" "#455A64"
$btnSelect = Q-Btn "[CHECK] CHON HET" "#1565C0"
$btnInstall = Q-Btn "BAT DAU CAI DAT" "#E65100"
$btnStop = Q-Btn "STOP" "#C62828"

$btnInstall.Enabled = $false; $btnPanel.Controls.AddRange(@($btnReload, $btnQuet, $btnSelect, $btnInstall, $btnStop))
$form.Controls.AddRange(@($lblHeader, $gbEnv, $dgv, $lblQuetXong, $pbTotal, $gbLog, $btnPanel))

# --- 2. HAM XU LY (TAM DAI HOP NHAT) ---

function Tao-Shortcut {
    param($TenApp)
    try {
        $Desktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
        $Sm = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs")
        $lnk = Get-ChildItem -Path $Sm -Filter "*$TenApp*.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (!$lnk) { $prefix = ($TenApp -split ' ')[0]; if ($prefix.Length -gt 2) { $lnk = Get-ChildItem -Path $Sm -Filter "*$prefix*.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 } }
        if ($lnk) { Copy-Item $lnk.FullName (Join-Path $Desktop $lnk.Name) -Force -ErrorAction SilentlyContinue }
    } catch {}
}

function CaiDat-MoiTruong {
    $wc = New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent", "Mozilla/5.0")
    # Winget
    if ((Get-Command winget -ErrorAction SilentlyContinue)) { $lblWingetStat.Text = "OK: Winget san sang"; $Global:WingetReady = $true }
    else {
        try {
            $lblWingetStat.Text = "Installing App Installer..."; LamMoi-GiaoDien
            $pathWg = Join-Path $env:TEMP "wg.msixbundle"
            $wc.DownloadFile("https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", $pathWg)
            Add-AppxPackage -Path $pathWg -ErrorAction Stop
            $lblWingetStat.Text = "OK: Winget san sang"; $Global:WingetReady = $true
        } catch { $lblWingetStat.Text = "Loi Winget!"; $lblWingetStat.ForeColor = "Red" }
    }
    # Choco
    if (Get-Command choco -ErrorAction SilentlyContinue) { $lblChocoStat.Text = "OK: Choco san sang"; $Global:ChocoReady = $true }
    else {
        try {
            iex ($wc.DownloadString('https://community.chocolatey.org/install.ps1'))
            $lblChocoStat.Text = "OK: Choco san sang"; $Global:ChocoReady = $true
        } catch { $lblChocoStat.Text = "Loi Choco!"; $lblChocoStat.ForeColor = "Red" }
    }
    $btnInstall.Enabled = $true; $lblQuetXong.Text = "He thong san sang!"
}

function Tai-DanhSach {
    $dgv.Rows.Clear(); try {
        $wc = New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($githubUrl + "?t=" + (Get-Date).Ticks, $localPath)
        Import-Csv $localPath -Encoding UTF8 | foreach { if ($_.Name) { [void]$dgv.Rows.Add($false, $_.Name, "Cho check...", $_.WingetID, $_.ChocoID, $_.GDriveID, $_.SilentArgs) } }
    } catch { $lblQuetXong.Text = "Loi tai list!"; $lblQuetXong.ForeColor = "Red" }
}

$btnQuet.Add_Click({
    $apps = (Get-ItemProperty @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") -ErrorAction SilentlyContinue).DisplayName
    foreach ($r in $dgv.Rows) {
        if ($apps -match [regex]::Escape($r.Cells['Name'].Value)) { $r.Cells['Status'].Value = "Da co"; $r.Cells['Check'].Value = $false; $r.DefaultCellStyle.ForeColor = "Gray" }
        else { $r.Cells['Status'].Value = "Chua co"; $r.Cells['Check'].Value = $true; $r.DefaultCellStyle.ForeColor = "Black" }
    }
    $lblQuetXong.Text = "Da quet xong!"; LamMoi-GiaoDien
})

$btnInstall.Add_Click({
    $selected = $dgv.Rows | Where-Object { $_.Cells['Check'].Value -eq $true }
    if ($selected.Count -eq 0) { return }; $btnInstall.Enabled = $false; $flowHub.Controls.Clear(); $done = 0; $script:HuyCaiDat = $false

    foreach ($row in $selected) {
        if ($script:HuyCaiDat) { break }
        $name = $row.Cells['Name'].Value; $wId = $row.Cells['WID'].Value; $cId = $row.Cells['CID'].Value; $gId = $row.Cells['GID'].Value; $args = $row.Cells['Args'].Value
        
        $p = New-Object System.Windows.Forms.Panel; $p.Size = "$($flowHub.Width - 40),45"; $p.BackColor = "White"; $p.Margin = New-Object System.Windows.Forms.Padding(0,0,0,5)
        $l = New-Object System.Windows.Forms.Label; $l.Text = $name; $l.Location = "10,12"; $l.Size = "200,20"; $l.Font = $fStd
        $b = New-Object System.Windows.Forms.ProgressBar; $b.Location = "220,12"; $b.Size = "450,20"; $b.Value = 10
        $s = New-Object System.Windows.Forms.Label; $s.Text = "Dang cai..."; $s.Location = "680,12"; $s.Size = "250,20"
        $p.Controls.AddRange(@($l, $b, $s)); $flowHub.Controls.Add($p); $flowHub.ScrollControlIntoView($p); LamMoi-GiaoDien

        $success = $false; $lastErr = ""
        # 1. Winget
        if ($wId -and $Global:WingetReady) {
            $proc = Start-Process "winget" -ArgumentList "install --id `"$wId`" -e --silent --accept-package-agreements --accept-source-agreements --force" -PassThru -WindowStyle Hidden
            while (!$proc.HasExited) { if ($b.Value -lt 40) { $b.Value += 2 }; LamMoi-GiaoDien; Start-Sleep -ms 200 }
            if ($proc.ExitCode -eq 0) { $success = $true } else { $lastErr = "WG-$($proc.ExitCode)" }
        }
        # 2. Choco
        if (-not $success -and $cId -and $Global:ChocoReady) {
            $proc = Start-Process "choco" -ArgumentList "install `"$cId`" -y --force --silent" -PassThru -WindowStyle Hidden
            while (!$proc.HasExited) { if ($b.Value -lt 70) { $b.Value += 2 }; LamMoi-GiaoDien; Start-Sleep -ms 200 }
            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { $success = $true } else { $lastErr = "CC-$($proc.ExitCode)" }
        }
        # 3. GDrive
        if (-not $success -and $gId) {
            try {
                $tmp = Join-Path $env:TEMP "$name.exe"
                (New-Object System.Net.WebClient).DownloadFile("https://docs.google.com/uc?export=download&id=$gId", $tmp)
                $proc = Start-Process $tmp -ArgumentList $args -PassThru -Wait -WindowStyle Hidden
                $success = $true
            } catch { $lastErr = "GDRIVE_ERR" }
        }

        if ($success) { $b.Value = 100; $s.Text = "THANH CONG"; $s.ForeColor = "Green"; $row.Cells['Status'].Value = "Cai xong"; Tao-Shortcut $name }
        else { $b.Value = 100; $s.Text = "LOI: $lastErr"; $s.ForeColor = "Red" }
        $done++; $pbTotal.Value = [int](($done / $selected.Count) * 100); LamMoi-GiaoDien
    }
    $btnInstall.Enabled = $true; $lblQuetXong.Text = "HOAN TAT!"; LamMoi-GiaoDien
})

$btnReload.Add_Click({ Tai-DanhSach })
$btnSelect.Add_Click({ foreach ($r in $dgv.Rows) { if ($r.Cells['Status'].Value -ne "Da co") { $r.Cells['Check'].Value = $script:IsSelectAll } }; $script:IsSelectAll = !$script:IsSelectAll })
$btnStop.Add_Click({ $script:HuyCaiDat = $true; $lblQuetXong.Text = "Dang dung..." })

$form.Add_Shown({ Tai-DanhSach; CaiDat-MoiTruong })
$form.ShowDialog() | Out-Null