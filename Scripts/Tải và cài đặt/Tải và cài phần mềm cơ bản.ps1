# ==============================================================================
# VIETTOOLBOX PRO V44.12 - BẢN ÉP CÀI APP INSTALLER ĐỂ TRỊ WIN 10 CŨ
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Dùng link tĩnh không hết hạn. Ép cập nhật App Installer trước.
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$script:HuyCaiDat = $false
$script:IsSelectAll = $true
$githubUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv"
$localPath = Join-Path $env:TEMP "VietToolbox_List.csv"

# --- BIẾN GHI NHỚ TRẠNG THÁI MÔI TRƯỜNG ---
$Global:WingetReady = $false
$Global:ChocoReady = $false

# --- 1. GIẢI MÃ KEY AI ---
$EncStr = "DÁN_CHUỖI_MÃ_HÓA_CỦA_TUẤN_VÀO_ĐÂY"
try {
    $S = [Text.Encoding]::UTF8.GetBytes("VietToolbox"); $K = (New-Object Security.Cryptography.Rfc2898DeriveBytes "Admin@2512", $S, 1000).GetBytes(32); $I = (New-Object Security.Cryptography.Rfc2898DeriveBytes "Admin@2512", $S, 1000).GetBytes(16); $A = [Security.Cryptography.Aes]::Create(); $A.Key = $K; $A.IV = $I; $D = $A.CreateDecryptor(); $EB = [Convert]::FromBase64String($EncStr); $DB = $D.TransformFinalBlock($EB, 0, $EB.Length); $Global:apiKey = [Text.Encoding]::UTF8.GetString($DB); $A.Dispose()
} catch { $Global:apiKey = "" }

# --- 2. KHỞI TẠO GIAO DIỆN ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX PRO V44.12 - HỆ THỐNG CÀI ĐẶT THÔNG MINH"
$form.Size = "1050,780"; $form.MinimumSize = "900,700"; $form.StartPosition = "CenterScreen"; $form.BackColor = "#F5F5F5"

$fontTieuDe = New-Object System.Drawing.Font("Segoe UI Bold", 14)
$fontNut = New-Object System.Drawing.Font("Segoe UI Bold", 10)
$fontList = New-Object System.Drawing.Font("Segoe UI", 10)

$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "DANH SÁCH PHẦN MỀM HỆ THỐNG"
$lblHeader.Location = "20,15"; $lblHeader.Size = "500,30"; $lblHeader.Font = $fontTieuDe; $lblHeader.ForeColor = "#1A237E"

# --- KHU VỰC KIỂM TRA MÔI TRƯỜNG ---
$gbEnv = New-Object System.Windows.Forms.GroupBox
$gbEnv.Text = " TRẠNG THÁI MÔI TRƯỜNG HỆ THỐNG "; $gbEnv.Location = "20,55"; $gbEnv.Size = "990,65"
$gbEnv.Font = $fontNut; $gbEnv.Anchor = "Top, Left, Right"; $gbEnv.ForeColor = "#424242"

$lblWingetStat = New-Object System.Windows.Forms.Label
$lblWingetStat.Text = "⏳ App Installer (Winget): Đang chờ kiểm tra..."; $lblWingetStat.Location = "20,30"; $lblWingetStat.Size = "450,25"

$lblChocoStat = New-Object System.Windows.Forms.Label
$lblChocoStat.Text = "⏳ Chocolatey: Đang chờ kiểm tra..."; $lblChocoStat.Location = "480,30"; $lblChocoStat.Size = "450,25"

$gbEnv.Controls.AddRange(@($lblWingetStat, $lblChocoStat))

# --- BẢNG DANH SÁCH CHÍNH ---
$dgv = New-Object System.Windows.Forms.DataGridView
$dgv.Location = "20,135"; $dgv.Size = "990,200"; $dgv.BackgroundColor = "White"; $dgv.Anchor = "Top, Bottom, Left, Right"
$dgv.RowHeadersVisible = $false; $dgv.AllowUserToAddRows = $false
$dgv.SelectionMode = "FullRowSelect"; $dgv.BorderStyle = "FixedSingle"
$dgv.EnableHeadersVisualStyles = $false; $dgv.ColumnHeadersHeight = 45
$dgv.ColumnHeadersDefaultCellStyle.BackColor = "#303F9F"; $dgv.ColumnHeadersDefaultCellStyle.ForeColor = "White"; $dgv.ColumnHeadersDefaultCellStyle.Font = $fontNut

[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="CHỌN";Width=60;AutoSizeMode="None"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="TÊN PHẦN MỀM";AutoSizeMode="Fill"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Status";HeaderText="TRẠNG THÁI KIỂM TRA";AutoSizeMode="Fill"}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="WID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="CID";Visible=$false}))

$lblQuetXong = New-Object System.Windows.Forms.Label
$lblQuetXong.Text = "Hệ thống đang khởi động..."; $lblQuetXong.Location = "20,345"; $lblQuetXong.Size = "700,25"; $lblQuetXong.Font = $fontNut; $lblQuetXong.Anchor = "Bottom, Left"

$pbTotal = New-Object System.Windows.Forms.ProgressBar
$pbTotal.Location = "20,375"; $pbTotal.Size = "990,20"; $pbTotal.Style = "Continuous"; $pbTotal.Anchor = "Bottom, Left, Right"

$gbLog = New-Object System.Windows.Forms.GroupBox
$gbLog.Text = " CHI TIẾT QUÁ TRÌNH CÀI ĐẶT "; $gbLog.Location = "20,405"; $gbLog.Size = "990,220"; $gbLog.Font = $fontNut; $gbLog.Anchor = "Bottom, Left, Right"

$flowHub = New-Object System.Windows.Forms.FlowLayoutPanel
$flowHub.Dock = "Fill"; $flowHub.BackColor = "White"; $flowHub.AutoScroll = $true; $flowHub.Padding = New-Object System.Windows.Forms.Padding(10)
$gbLog.Controls.Add($flowHub)

$btnPanel = New-Object System.Windows.Forms.TableLayoutPanel
$btnPanel.Location = "20,640"; $btnPanel.Size = "990,70"; $btnPanel.ColumnCount = 5; $btnPanel.Anchor = "Bottom, Left, Right"
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 15)))

function Nhan-NutNhanh($t, $c) { 
    $b = New-Object System.Windows.Forms.Button; $b.Text = $t; $b.BackColor = $c; $b.ForeColor = "White"
    $b.Font = $fontNut; $b.FlatStyle = "Flat"; $b.Dock = "Fill"; $b.Margin = New-Object System.Windows.Forms.Padding(5); $b.Cursor = "Hand"
    $b.FlatAppearance.BorderSize = 0; return $b 
}

$btnReload = Nhan-NutNhanh "↻ NẠP LẠI DANH SÁCH" "#2E7D32"; $btnQuet = Nhan-NutNhanh "🔍 QUÉT HỆ THỐNG" "#455A64"
$btnSelect = Nhan-NutNhanh "✓ CHỌN TẤT CẢ" "#1565C0"; $btnInstall = Nhan-NutNhanh "🚀 CÀI ĐẶT NGAY" "#E65100"
$btnStop = Nhan-NutNhanh "🛑 DỪNG LẠI" "#C62828"

$btnInstall.Enabled = $false # KHÓA NÚT CHỜ MÔI TRƯỜNG SETUP XONG
$btnPanel.Controls.AddRange(@($btnReload, $btnQuet, $btnSelect, $btnInstall, $btnStop))
$form.Controls.AddRange(@($lblHeader, $gbEnv, $dgv, $lblQuetXong, $pbTotal, $gbLog, $btnPanel))

# --- 3. LOGIC XỬ LÝ: CHUẨN BỊ MÔI TRƯỜNG ---
function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents() }

function CaiDat-MoiTruong {
    $wc = New-Object System.Net.WebClient
    
    # 1. KIỂM TRA VÀ CÀI ĐẶT APP INSTALLER (CHỨA WINGET)
    $wgPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if ((Get-Command winget -ErrorAction SilentlyContinue) -or (Test-Path $wgPath)) {
        $lblWingetStat.Text = "✅ App Installer: Đã sẵn sàng"; $lblWingetStat.ForeColor = "Green"; $Global:WingetReady = $true
    } else {
        $lblWingetStat.Text = "⚙️ Đang ép cập nhật App Installer..."; $lblWingetStat.ForeColor = "#E65100"; LamMoi-GiaoDien
        try {
            # Tải thư viện VCLibs
            $vcPath = Join-Path $env:TEMP "vclibs.appx"
            $wc.DownloadFile("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", $vcPath)
            Add-AppxPackage -Path $vcPath -ErrorAction SilentlyContinue
            
            # Tải thư viện UI.Xaml
            $uiPath = Join-Path $env:TEMP "uixaml.appx"
            $wc.DownloadFile("https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx", $uiPath)
            Add-AppxPackage -Path $uiPath -ErrorAction SilentlyContinue
            
            # Tải App Installer (Link tĩnh chính chủ Microsoft, không bao giờ hết hạn)
            $appInstallerUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $appInstallerPath = Join-Path $env:TEMP "AppInstaller.msixbundle"
            $wc.DownloadFile($appInstallerUrl, $appInstallerPath)
            Add-AppxPackage -Path $appInstallerPath -ErrorAction Stop
            
            $lblWingetStat.Text = "✅ App Installer: Cập nhật thành công"; $lblWingetStat.ForeColor = "Green"; $Global:WingetReady = $true
        } catch {
            $lblWingetStat.Text = "❌ App Installer: Máy không hỗ trợ. Chuyển sang Choco!"; $lblWingetStat.ForeColor = "Red"
        }
    }

    # 2. KIỂM TRA VÀ CÀI ĐẶT CHOCOLATEY
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $lblChocoStat.Text = "✅ Chocolatey: Đã sẵn sàng"; $lblChocoStat.ForeColor = "Green"; $Global:ChocoReady = $true
    } else {
        $lblChocoStat.Text = "⚙️ Đang tải và cài đặt Chocolatey..."; $lblChocoStat.ForeColor = "#E65100"; LamMoi-GiaoDien
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ($wc.DownloadString('https://community.chocolatey.org/install.ps1'))
            $lblChocoStat.Text = "✅ Chocolatey: Cài đặt thành công"; $lblChocoStat.ForeColor = "Green"; $Global:ChocoReady = $true
        } catch {
            $lblChocoStat.Text = "❌ Chocolatey: Lỗi cài đặt!"; $lblChocoStat.ForeColor = "Red"
        }
    }

    # Mở khóa nút cài đặt
    $btnInstall.Enabled = $true
    $lblQuetXong.Text = "✓ Đã chuẩn bị xong môi trường! Sẵn sàng làm việc."
}

function Tai-DanhSach {
    $dgv.Rows.Clear(); LamMoi-GiaoDien
    try {
        $wc = New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($githubUrl + "?t=" + (Get-Date).Ticks, $localPath)
        Import-Csv $localPath -Encoding UTF8 | foreach { if ($_.Name) { [void]$dgv.Rows.Add($false, $_.Name, "Đang chờ kiểm tra...", $_.WingetID, $_.ChocoID) } }
    } catch { $lblQuetXong.Text = "✕ Không thể kết nối Internet!"; $lblQuetXong.ForeColor = "Red" }
}

$btnQuet.Add_Click({
    $lblQuetXong.Text = "🔍 Đang quét phần mềm trên máy..."; LamMoi-GiaoDien
    $installed = (Get-ItemProperty @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") -ErrorAction SilentlyContinue).DisplayName
    foreach ($row in $dgv.Rows) {
        if ($installed -match [regex]::Escape($row.Cells['Name'].Value)) {
            $row.Cells['Status'].Value = "✓ Đã có sẵn trên máy"; $row.Cells['Check'].Value = $false; $row.DefaultCellStyle.ForeColor = "Gray"
        } else {
            $row.Cells['Status'].Value = "✕ Chưa được cài đặt"; $row.Cells['Check'].Value = $true; $row.DefaultCellStyle.ForeColor = "Black"
        }
        LamMoi-GiaoDien
    }
    $lblQuetXong.Text = "✓ Đã quét xong hệ thống!"
})

$btnInstall.Add_Click({
    $selected = $dgv.Rows | Where-Object { $_.Cells['Check'].Value -eq $true }
    if ($selected.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Bạn chưa chọn phần mềm nào để cài đặt!", "Thông báo"); return }
    
    $script:HuyCaiDat = $false; $btnInstall.Enabled = $false; $flowHub.Controls.Clear(); $done = 0

    foreach ($row in $selected) {
        if ($script:HuyCaiDat) { break }
        $name = $row.Cells['Name'].Value; $wId = $row.Cells['WID'].Value; $cId = $row.Cells['CID'].Value
        
        $p = New-Object System.Windows.Forms.Panel; $p.Size = "$($flowHub.Width - 30),45"; $p.BackColor = "White"; $p.Margin = New-Object System.Windows.Forms.Padding(0,0,0,5)
        $l = New-Object System.Windows.Forms.Label; $l.Text = $name; $l.Location = "10,12"; $l.Size = "200,20"; $l.Font = $fontList
        $b = New-Object System.Windows.Forms.ProgressBar; $b.Location = "220,12"; $b.Size = "450,20"; $b.Value = 10; $b.Anchor = "Left, Right, Top"
        $s = New-Object System.Windows.Forms.Label; $s.Text = "Đang chuẩn bị..."; $s.Location = "$($p.Width - 190),12"; $s.Size = "180,20"; $s.Anchor = "Right, Top"
        $p.Controls.AddRange(@($l, $b, $s)); $flowHub.Controls.Add($p); $flowHub.ScrollControlIntoView($p); LamMoi-GiaoDien

        try {
            $method = if ($wId) { "Winget" } elseif ($cId) { "Choco" } else { "Skip" }
            
            # CƠ CHẾ BẺ LÁI NẾU MÔI TRƯỜNG CHẾT
            if ($method -eq "Winget" -and -not $Global:WingetReady) {
                if ($cId -and $Global:ChocoReady) { 
                    $method = "Choco" 
                } else { 
                    throw "Không có môi trường cài đặt!" 
                }
            } elseif ($method -eq "Choco" -and -not $Global:ChocoReady) {
                throw "Chocolatey chưa sẵn sàng!"
            }

            $s.Text = "🚀 Cài qua $method..."; LamMoi-GiaoDien
            $proc = $null
            
            $wgPath = if (Get-Command winget -ErrorAction SilentlyContinue) { "winget" } else { "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe" }

            if ($method -eq "Winget") {
                $arg = "install --id `"$wId`" -e --silent --accept-package-agreements --accept-source-agreements --force"
                $proc = Start-Process $wgPath -ArgumentList $arg -PassThru -WindowStyle Hidden
            } elseif ($method -eq "Choco") {
                $arg = "install `"$cId`" -y --force --silent"
                $proc = Start-Process "choco" -ArgumentList $arg -PassThru -WindowStyle Hidden
            }

            if ($proc) { 
                while (!$proc.HasExited) { if ($b.Value -lt 95) { $b.Value += 2 }; LamMoi-GiaoDien; Start-Sleep -Milliseconds 200 } 
                if ($proc.ExitCode -eq 0) { 
                    $b.Value = 100; $s.Text = "✓ Thành công"; $s.ForeColor = "Green"
                    $row.Cells['Status'].Value = "✓ Cài đặt thành công" 
                } else { 
                    $b.Value = 100; $s.Text = "✕ Lỗi mã: $($proc.ExitCode)"; $s.ForeColor = "Red"
                    $row.Cells['Status'].Value = "✕ Cài đặt thất bại" 
                }
            }
        } catch { 
            $s.Text = "✕ Lỗi: $($_.Exception.Message)"; $s.ForeColor = "Red"
            $row.Cells['Status'].Value = "✕ Bỏ qua"
        }
        $done++; $pbTotal.Value = [int](($done / $selected.Count) * 100); LamMoi-GiaoDien
    }
    $btnInstall.Enabled = $true; $lblQuetXong.Text = "✓ ĐÃ HOÀN TẤT TOÀN BỘ QUÁ TRÌNH!"; LamMoi-GiaoDien
})

$btnReload.Add_Click({ Tai-DanhSach })
$btnSelect.Add_Click({
    foreach ($row in $dgv.Rows) { if ($row.Cells['Status'].Value -ne "✓ Đã có sẵn trên máy") { $row.Cells['Check'].Value = $script:IsSelectAll } }
    $script:IsSelectAll = !$script:IsSelectAll; $btnSelect.Text = if ($script:IsSelectAll) { "✓ CHỌN TẤT CẢ" } else { "✕ BỎ CHỌN" }
})
$btnStop.Add_Click({ $script:HuyCaiDat = $true; $lblQuetXong.Text = "🛑 Đang ngắt tiến trình cài đặt..." })

# SỰ KIỆN KHI MỞ FORM
$form.Add_Shown({ 
    Tai-DanhSach
    CaiDat-MoiTruong
})

$form.ShowDialog() | Out-Null