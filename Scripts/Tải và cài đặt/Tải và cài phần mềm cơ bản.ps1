# ==============================================================================
# VIETTOOLBOX PRO V44.25 - BẢN TIẾNG VIỆT CÓ DẤU CHUẨN (FIX EXCEPTION)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Hỗ trợ hiển thị tiếng Việt, co giãn cửa sổ tự do, fallback 3 lớp.
# ==============================================================================

# 1. THIẾT LẬP BẢNG MÃ UTF8 VÀ GIAO DIỆN
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
$OutputEncoding = [System.Text.Encoding]::UTF8
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

# --- 1. KHỞI TẠO CỬA SỔ CHÍNH ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX PRO V44.25 - CÀI ĐẶT TỰ ĐỘNG 2026"; $form.Size = "1050,780"; $form.MinimumSize = "900,700"; $form.StartPosition = "CenterScreen"; $form.BackColor = "#F5F5F5"

$fBold = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 14); $fStd = New-Object System.Drawing.Font("Segoe UI", 10)

$lblHeader = New-Object System.Windows.Forms.Label; $lblHeader.Text = "HỆ THỐNG QUẢN LÝ PHẦN MỀM"; $lblHeader.Location = "20,15"; $lblHeader.Size = "500,30"; $lblHeader.Font = $fTitle; $lblHeader.ForeColor = "#1A237E"

# Khung trạng thái môi trường
$gbEnv = New-Object System.Windows.Forms.GroupBox; $gbEnv.Text = " TRẠNG THÁI HỆ THỐNG "; $gbEnv.Location = "20,55"; $gbEnv.Size = "990,65"; $gbEnv.Font = $fBold; $gbEnv.Anchor = "Top, Left, Right"
$lblWingetStat = New-Object System.Windows.Forms.Label; $lblWingetStat.Text = "⏳ Đang kiểm tra Winget..."; $lblWingetStat.Location = "20,30"; $lblWingetStat.Size = "450,25"
$lblChocoStat = New-Object System.Windows.Forms.Label; $lblChocoStat.Text = "⏳ Đang kiểm tra Choco..."; $lblChocoStat.Location = "480,30"; $lblChocoStat.Size = "450,25"
$gbEnv.Controls.AddRange(@($lblWingetStat, $lblChocoStat))

# Bảng danh sách App
$dgv = New-Object System.Windows.Forms.DataGridView; $dgv.Location = "20,135"; $dgv.Size = "990,200"; $dgv.BackgroundColor = "White"; $dgv.RowHeadersVisible = $false; $dgv.AllowUserToAddRows = $false; $dgv.SelectionMode = "FullRowSelect"; $dgv.Anchor = "Top, Bottom, Left, Right"; $dgv.AutoSizeColumnsMode = "Fill"
$dgv.EnableHeadersVisualStyles = $false; $dgv.ColumnHeadersHeight = 45; $dgv.ColumnHeadersDefaultCellStyle.BackColor = "#303F9F"; $dgv.ColumnHeadersDefaultCellStyle.ForeColor = "White"; $dgv.ColumnHeadersDefaultCellStyle.Font = $fBold

[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="CHỌN";Width=60;AutoSizeMode="None"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="TÊN PHẦN MỀM"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Status";HeaderText="TRẠNG THÁI";Width=200;AutoSizeMode="None"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="WID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="CID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="GID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Args";Visible=$false}))

$lblQuetXong = New-Object System.Windows.Forms.Label; $lblQuetXong.Text = "Đang nạp dữ liệu..."; $lblQuetXong.Location = "20,345"; $lblQuetXong.Size = "700,25"; $lblQuetXong.Font = $fBold; $lblQuetXong.Anchor = "Bottom, Left"
$pbTotal = New-Object System.Windows.Forms.ProgressBar; $pbTotal.Location = "20,375"; $pbTotal.Size = "990,20"; $pbTotal.Anchor = "Bottom, Left, Right"

# Khung Log cài đặt (Fix lỗi ô vuông và Exception)
$gbLog = New-Object System.Windows.Forms.GroupBox; $gbLog.Text = " NHẬT KÝ CÀI ĐẶT "; $gbLog.Location = "20,405"; $gbLog.Size = "990,220"; $gbLog.Font = $fBold; $gbLog.Anchor = "Bottom, Left, Right"
$txtLog = New-Object System.Windows.Forms.RichTextBox; $txtLog.Dock = "Fill"; $txtLog.BackColor = "White"; $txtLog.ReadOnly = $true; $txtLog.Font = $fStd; $txtLog.BorderStyle = "None"
$gbLog.Controls.Add($txtLog)

# Bảng nút bấm
$btnPanel = New-Object System.Windows.Forms.TableLayoutPanel; $btnPanel.Location = "20,640"; $btnPanel.Size = "990,70"; $btnPanel.ColumnCount = 5; $btnPanel.Anchor = "Bottom, Left, Right"
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 36)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 10)))

function Q-Btn($t, $c) { $b = New-Object System.Windows.Forms.Button; $b.Text = $t; $b.BackColor = $c; $b.ForeColor = "White"; $b.Font = $fBold; $b.FlatStyle = "Flat"; $b.Dock = "Fill"; $b.Margin = New-Object System.Windows.Forms.Padding(5); $b.FlatAppearance.BorderSize = 0; $b.Cursor = "Hand"; return $b }
$btnReload = Q-Btn "NẠP DANH SÁCH" "#2E7D32"; $btnQuet = Q-Btn "QUÉT HỆ THỐNG" "#455A64"; $btnSelect = Q-Btn "CHỌN TẤT CẢ" "#1565C0"; $btnInstall = Q-Btn "BẮT ĐẦU CÀI ĐẶT" "#E65100"; $btnStop = Q-Btn "🛑" "#C62828"
$btnInstall.Enabled = $false; $btnPanel.Controls.AddRange(@($btnReload, $btnQuet, $btnSelect, $btnInstall, $btnStop))

$form.Controls.AddRange(@($lblHeader, $gbEnv, $dgv, $lblQuetXong, $pbTotal, $gbLog, $btnPanel))

# --- 2. HÀM XỬ LÝ LOGIC ---

function Ghi-Log($msg, $color = "Black") {
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionColor = $color
    $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
    $txtLog.ScrollToCaret()
    LamMoi-GiaoDien
}

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
    # Check Winget
    if ((Get-Command winget -ErrorAction SilentlyContinue)) { 
        $lblWingetStat.Text = "✅ Winget: Sẵn sàng"; $Global:WingetReady = $true 
    } else { $lblWingetStat.Text = "❌ Winget: Không tìm thấy!"; $lblWingetStat.ForeColor = "Red" }
    # Check Choco
    if (Get-Command choco -ErrorAction SilentlyContinue) { 
        $lblChocoStat.Text = "✅ Chocolatey: Sẵn sàng"; $Global:ChocoReady = $true 
    } else {
        try { 
            $lblChocoStat.Text = "⚙️ Đang cài Chocolatey..."; LamMoi-GiaoDien
            iex ($wc.DownloadString('https://community.chocolatey.org/install.ps1'))
            $lblChocoStat.Text = "✅ Chocolatey: OK"; $Global:ChocoReady = $true 
        } catch { $lblChocoStat.Text = "❌ Choco: Lỗi!"; $lblChocoStat.ForeColor = "Red" }
    }
    $btnInstall.Enabled = $true; $lblQuetXong.Text = "✓ Hệ thống đã sẵn sàng làm việc!"
}

function Tai-DanhSach {
    $dgv.Rows.Clear(); try {
        $wc = New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($githubUrl + "?t=" + (Get-Date).Ticks, $localPath)
        Import-Csv $localPath -Encoding UTF8 | foreach { if ($_.Name) { [void]$dgv.Rows.Add($false, $_.Name, "Chờ quét...", $_.WingetID, $_.ChocoID, $_.GDriveID, $_.SilentArgs) } }
        Ghi-Log "Đã nạp danh sách phần mềm từ GitHub." "Green"
    } catch { Ghi-Log "Lỗi: Không thể tải danh sách phần mềm!" "Red" }
}

$btnQuet.Add_Click({
    $lblQuetXong.Text = "🔍 Đang quét hệ thống..."; LamMoi-GiaoDien
    $apps = (Get-ItemProperty @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") -ErrorAction SilentlyContinue).DisplayName
    foreach ($r in $dgv.Rows) {
        if ($apps -match [regex]::Escape($r.Cells['Name'].Value)) { $r.Cells['Status'].Value = "Đã có sẵn"; $r.Cells['Check'].Value = $false; $r.DefaultCellStyle.ForeColor = "Gray" }
        else { $r.Cells['Status'].Value = "Chưa cài đặt"; $r.Cells['Check'].Value = $true; $r.DefaultCellStyle.ForeColor = "Black" }
    }
    $lblQuetXong.Text = "✓ Quét xong!"; LamMoi-GiaoDien
})

$btnInstall.Add_Click({
    $selected = $dgv.Rows | Where-Object { $_.Cells['Check'].Value -eq $true }
    if ($selected.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Hãy chọn ít nhất một phần mềm!"); return }
    $btnInstall.Enabled = $false; $txtLog.Clear(); $done = 0; $script:HuyCaiDat = $false

    foreach ($row in $selected) {
        if ($script:HuyCaiDat) { Ghi-Log "DỪNG CÀI ĐẶT THEO YÊU CẦU!" "Red"; break }
        $name = $row.Cells['Name'].Value; $wId = $row.Cells['WID'].Value; $cId = $row.Cells['CID'].Value; $gId = $row.Cells['GID'].Value; $args = $row.Cells['Args'].Value
        
        Ghi-Log "Đang xử lý: $name..." "Blue"
        $success = $false; $lastErr = ""

        try {
            # 1. Thử Winget
            if ($wId -and $Global:WingetReady) {
                Ghi-Log "  -> Thử cài bằng Winget..."
                $proc = Start-Process "winget" -ArgumentList "install --id `"$wId`" -e --silent --accept-package-agreements --accept-source-agreements --force" -PassThru -WindowStyle Hidden
                $proc.WaitForExit(); if ($proc.ExitCode -eq 0) { $success = $true } else { $lastErr = "WG-$($proc.ExitCode)" }
            }
            # 2. Thử Choco
            if (-not $success -and $cId -and $Global:ChocoReady) {
                Ghi-Log "  -> Thử cài bằng Chocolatey..." "Brown"
                $proc = Start-Process "choco" -ArgumentList "install `"$cId`" -y --force --silent" -PassThru -WindowStyle Hidden
                $proc.WaitForExit(); if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { $success = $true } else { $lastErr = "CC-$($proc.ExitCode)" }
            }
            # 3. Thử GDrive
            if (-not $success -and $gId) {
                Ghi-Log "  -> Tải file từ Google Drive..." "DarkCyan"
                $tmp = Join-Path $env:TEMP "$name.exe"
                (New-Object System.Net.WebClient).DownloadFile("https://docs.google.com/uc?export=download&id=$gId", $tmp)
                Ghi-Log "  -> Đang chạy file cài đặt..."
                $proc = Start-Process $tmp -ArgumentList $args -PassThru -Wait -WindowStyle Hidden
                $success = $true
            }

            if ($success) { Ghi-Log "  => THÀNH CÔNG!" "Green"; $row.Cells['Status'].Value = "Hoàn tất"; Tao-Shortcut $name }
            else { Ghi-Log "  => THẤT BẠI: $lastErr" "Red" }
        } catch { Ghi-Log "  => LỖI HỆ THỐNG: $($_.Exception.Message)" "Red" }
        
        $done++; $pbTotal.Value = [int](($done / $selected.Count) * 100); LamMoi-GiaoDien
    }
    $btnInstall.Enabled = $true; $lblQuetXong.Text = "✓ HOÀN TẤT!"; LamMoi-GiaoDien
})

$btnReload.Add_Click({ Tai-DanhSach })
$btnSelect.Add_Click({ 
    foreach ($r in $dgv.Rows) { if ($r.Cells['Status'].Value -ne "Đã có sẵn") { $r.Cells['Check'].Value = $script:IsSelectAll } }
    $script:IsSelectAll = !$script:IsSelectAll; $btnSelect.Text = if ($script:IsSelectAll) { "CHỌN TẤT CẢ" } else { "BỎ CHỌN" }
})
$btnStop.Add_Click({ $script:HuyCaiDat = $true; Ghi-Log "ĐANG DỪNG QUY TRÌNH..." "Red" })

$form.Add_Shown({ Tai-DanhSach; CaiDat-MoiTruong })
$form.ShowDialog() | Out-Null