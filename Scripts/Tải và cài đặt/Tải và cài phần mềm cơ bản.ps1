# ==============================================================================
# VIETTOOLBOX PRO V44.7 - BẢN HOÀN THIỆN TỐI ƯU (FIX LỖI WINGET)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Đã fix lỗi Exit Code -1978335230 của Winget, giao diện Pro.
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$script:HuyCaiDat = $false
$script:IsSelectAll = $true
$githubUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv"
$localPath = Join-Path $env:TEMP "VietToolbox_List.csv"

# --- 1. KHỞI TẠO FORM ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX PRO V44.7 - TRÌNH CÀI ĐẶT CHUYÊN NGHIỆP"
$form.Size = "1100,950"
$form.StartPosition = "CenterScreen"
$form.BackColor = "#F5F5F5"

$fontTieuDe = New-Object System.Drawing.Font("Segoe UI Bold", 14)
$fontNut = New-Object System.Drawing.Font("Segoe UI Bold", 10)
$fontList = New-Object System.Drawing.Font("Segoe UI", 10)

# Header
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "DANH SÁCH PHẦN MỀM HỆ THỐNG"
$lblHeader.Location = "20,15"; $lblHeader.Size = "500,30"; $lblHeader.Font = $fontTieuDe; $lblHeader.ForeColor = "#1A237E"

# DataGridView (Bảng danh sách)
$dgv = New-Object System.Windows.Forms.DataGridView
$dgv.Location = "20,55"; $dgv.Size = "1040,380"; $dgv.BackgroundColor = "White"
$dgv.RowHeadersVisible = $false; $dgv.AllowUserToAddRows = $false
$dgv.SelectionMode = "FullRowSelect"; $dgv.BorderStyle = "FixedSingle"
$dgv.EnableHeadersVisualStyles = $false; $dgv.ColumnHeadersHeight = 45
$dgv.ColumnHeadersDefaultCellStyle.BackColor = "#303F9F"; $dgv.ColumnHeadersDefaultCellStyle.ForeColor = "White"
$dgv.ColumnHeadersDefaultCellStyle.Font = $fontNut

[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="CHỌN";Width=60}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="TÊN PHẦN MỀM";Width=380}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Status";HeaderText="TRẠNG THÁI KIỂM TRA";Width=580}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="WID";Visible=$false}))
[void]$dgv.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="CID";Visible=$false}))

# Progress Area (Khu vực tiến độ)
$lblQuetXong = New-Object System.Windows.Forms.Label
$lblQuetXong.Text = "Sẵn sàng khởi động..."; $lblQuetXong.Location = "20,445"; $lblQuetXong.Size = "500,25"; $lblQuetXong.Font = $fontNut

$pbTotal = New-Object System.Windows.Forms.ProgressBar
$pbTotal.Location = "20,475"; $pbTotal.Size = "1040,20"; $pbTotal.Style = "Continuous"

# Log Area (Chi tiết quá trình)
$gbLog = New-Object System.Windows.Forms.GroupBox
$gbLog.Text = " CHI TIẾT QUÁ TRÌNH CÀI ĐẶT "; $gbLog.Location = "20,510"; $gbLog.Size = "1040,280"; $gbLog.Font = $fontNut

$flowHub = New-Object System.Windows.Forms.FlowLayoutPanel
$flowHub.Dock = "Fill"; $flowHub.BackColor = "White"; $flowHub.AutoScroll = $true; $flowHub.Padding = New-Object System.Windows.Forms.Padding(10)
$gbLog.Controls.Add($flowHub)

# Footer Buttons (Các nút bấm)
$btnPanel = New-Object System.Windows.Forms.TableLayoutPanel
$btnPanel.Location = "20,810"; $btnPanel.Size = "1040,75"; $btnPanel.ColumnCount = 5
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$btnPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 15)))

function Quick-B($t, $c) { 
    $b = New-Object System.Windows.Forms.Button; $b.Text = $t; $b.BackColor = $c; $b.ForeColor = "White"
    $b.Font = $fontNut; $b.FlatStyle = "Flat"; $b.Dock = "Fill"; $b.Margin = New-Object System.Windows.Forms.Padding(5); $b.Cursor = "Hand"
    $b.FlatAppearance.BorderSize = 0; return $b 
}

$btnReload = Quick-B "↻ NẠP LẠI LIST" "#2E7D32"
$btnQuet   = Quick-B "🔍 QUÉT HỆ THỐNG" "#455A64"
$btnSelect = Quick-B "✓ CHỌN HẾT" "#1565C0"
$btnInstall = Quick-B "🚀 CÀI ĐẶT NGAY" "#E65100"
$btnStop    = Quick-B "🛑 DỪNG LẠI" "#C62828"

$btnPanel.Controls.AddRange(@($btnReload, $btnQuet, $btnSelect, $btnInstall, $btnStop))
$form.Controls.AddRange(@($lblHeader, $dgv, $lblQuetXong, $pbTotal, $gbLog, $btnPanel))


# --- 2. LOGIC XỬ LÝ ---
function Refresh-UI { [System.Windows.Forms.Application]::DoEvents() }

function Initialize-Env {
    param($Method)
    if ($Method -eq "Winget" -and !(Get-Command winget -ErrorAction SilentlyContinue)) {
        $lblQuetXong.Text = "🛠 Đang cài Winget cho máy khách..."; Refresh-UI
        $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $path = Join-Path $env:TEMP "winget.msixbundle"
        (New-Object System.Net.WebClient).DownloadFile($url, $path)
        Add-AppxPackage -Path $path -ErrorAction SilentlyContinue
    }
    return $true
}

function Sync-List {
    $dgv.Rows.Clear(); $lblQuetXong.Text = "🔄 Đang đồng bộ danh sách từ GitHub..."; Refresh-UI
    try {
        $wc = New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($githubUrl + "?t=" + (Get-Date).Ticks, $localPath)
        Import-Csv $localPath -Encoding UTF8 | foreach { if ($_.Name) { [void]$dgv.Rows.Add($false, $_.Name, "Chờ quét...", $_.WingetID, $_.ChocoID) } }
        $lblQuetXong.Text = "✓ Đã tìm thấy $($dgv.Rows.Count) ứng dụng có sẵn."; Refresh-UI
    } catch { $lblQuetXong.Text = "✕ Không thể kết nối Internet!"; $lblQuetXong.ForeColor = "Red" }
}

$btnQuet.Add_Click({
    $lblQuetXong.Text = "🔍 Đang đối chiếu phần mềm trên máy..."; Refresh-UI
    $installed = (Get-ItemProperty @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") -ErrorAction SilentlyContinue).DisplayName
    foreach ($row in $dgv.Rows) {
        if ($installed -match [regex]::Escape($row.Cells['Name'].Value)) {
            $row.Cells['Status'].Value = "✓ Đã cài đặt trên máy này"; $row.Cells['Check'].Value = $false; $row.DefaultCellStyle.ForeColor = "Gray"
        } else {
            $row.Cells['Status'].Value = "✕ Chưa phát hiện"; $row.Cells['Check'].Value = $true; $row.DefaultCellStyle.ForeColor = "Black"
        }
        Refresh-UI
    }
    $lblQuetXong.Text = "✓ Đã quét xong!"; Refresh-UI
})

$btnInstall.Add_Click({
    $selected = $dgv.Rows | Where-Object { $_.Cells['Check'].Value -eq $true }
    if ($selected.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Tuấn chưa chọn phần mềm nào để cài cả!", "Thông báo"); return }
    
    $script:HuyCaiDat = $false; $btnInstall.Enabled = $false; $flowHub.Controls.Clear(); $done = 0

    foreach ($row in $selected) {
        if ($script:HuyCaiDat) { break }
        $name = $row.Cells['Name'].Value; $wId = $row.Cells['WID'].Value; $cId = $row.Cells['CID'].Value
        
        $p = New-Object System.Windows.Forms.Panel; $p.Size = "1000,50"; $p.BackColor = "White"; $p.Margin = New-Object System.Windows.Forms.Padding(0,0,0,5)
        $l = New-Object System.Windows.Forms.Label; $l.Text = $name; $l.Location = "15,15"; $l.Size = "200,20"; $l.Font = $fontList
        $b = New-Object System.Windows.Forms.ProgressBar; $b.Location = "230,15"; $b.Size = "550,20"; $b.Value = 10
        $s = New-Object System.Windows.Forms.Label; $s.Text = "Đang khởi tạo..."; $s.Location = "800,15"; $s.Size = "180,20"
        $p.Controls.AddRange(@($l, $b, $s)); $flowHub.Controls.Add($p); $flowHub.ScrollControlIntoView($p); Refresh-UI

        try {
            $method = if ($wId) { "Winget" } elseif ($cId) { "Choco" } else { "Skip" }
            Initialize-Env -Method $method
            $s.Text = "🚀 Cài qua $method..."; Refresh-UI
            
            $proc = $null
            if ($method -eq "Winget") {
                # FIX BỰ Ở ĐÂY: Thêm -e (Exact), --accept-source-agreements và --force
                $arg = "install --id `"$wId`" -e --silent --accept-package-agreements --accept-source-agreements --force"
                $proc = Start-Process "winget" -ArgumentList $arg -PassThru -WindowStyle Hidden
            } elseif ($method -eq "Choco") {
                $arg = "install `"$cId`" -y --force --silent"
                $proc = Start-Process "choco" -ArgumentList $arg -PassThru -WindowStyle Hidden
            }

            if ($proc) { 
                # Chờ tiến trình chạy xong
                while (!$proc.HasExited) { 
                    if ($b.Value -lt 95) { $b.Value += 2 }
                    Refresh-UI; Start-Sleep -Milliseconds 200 
                } 
                
                # Check mã ExitCode, 0 là cài đặt hoàn hảo
                if ($proc.ExitCode -eq 0) { 
                    $b.Value = 100
                    $s.Text = "✓ Thành công"; $s.ForeColor = "Green"
                    $row.Cells['Status'].Value = "✓ Cài thành công" 
                } else { 
                    $b.Value = 100
                    $s.Text = "✕ Lỗi Code: $($proc.ExitCode)"; $s.ForeColor = "Red"
                    $row.Cells['Status'].Value = "✕ Lỗi mã $($proc.ExitCode)" 
                }
            }
        } catch { 
            $s.Text = "✕ Lỗi hệ thống" 
        }
        $done++; $pbTotal.Value = [int](($done / $selected.Count) * 100); Refresh-UI
    }
    $btnInstall.Enabled = $true; $lblQuetXong.Text = "✓ HOÀN TẤT TẤT CẢ NHIỆM VỤ!"; Refresh-UI
})

$btnReload.Add_Click({ Sync-List })
$btnSelect.Add_Click({
    foreach ($row in $dgv.Rows) { if ($row.Cells['Status'].Value -ne "✓ Đã cài đặt trên máy này") { $row.Cells['Check'].Value = $script:IsSelectAll } }
    $script:IsSelectAll = !$script:IsSelectAll; $btnSelect.Text = if ($script:IsSelectAll) { "✓ CHỌN HẾT" } else { "✕ BỎ CHỌN" }
})
$btnStop.Add_Click({ $script:HuyCaiDat = $true; $lblQuetXong.Text = "🛑 Đang ngắt tiến trình..." })

# Tự động nạp khi mở
$form.Add_Shown({ Sync-List })
$form.ShowDialog() | Out-Null