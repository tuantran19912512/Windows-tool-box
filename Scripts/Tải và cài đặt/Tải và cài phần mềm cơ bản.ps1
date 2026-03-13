# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- KIỂM TRA QUYỀN ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Ông Tuấn ơi, chạy quyền Admin nó mới 'soi' được hết app hệ thống nhé!", "Thiếu quyền Admin")
    return
}

$LogicCaiPhanMem = {
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "DanhSachPhanMem_Local.csv"

    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX V36.1 - CÀI & TẢI FILE CÀI ĐẶT LƯU TRỮ"; $form.Size = "850,820"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"; $form.Topmost = $true
    
    # --- KHU VỰC CẤU HÌNH TẢI FILE ---
    $gbDown = New-Object System.Windows.Forms.GroupBox; $gbDown.Text = "CẤU HÌNH THƯ MỤC TẢI SETUP"; $gbDown.Location = "20,10"; $gbDown.Size = "790,65"; $gbDown.Font = $fontNoiDung
    $txtPath = New-Object System.Windows.Forms.TextBox; $txtPath.Location = "20,27"; $txtPath.Size = "600,25"; $txtPath.Text = "C:\VietToolbox_Downloads"
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "Chọn..."; $btnBrowse.Location = "630,25"; $btnBrowse.Size = "140,30"
    $gbDown.Controls.AddRange(@($txtPath, $btnBrowse))

    # --- BẢNG DANH SÁCH ---
    $lvStore = New-Object System.Windows.Forms.ListView; $lvStore.Size = "790,400"; $lvStore.Location = "20,90"; $lvStore.View = "Details"; $lvStore.CheckBoxes = $true; $lvStore.FullRowSelect = $true; $lvStore.Font = $fontNoiDung; $lvStore.BorderStyle = "FixedSingle"
    [void]$lvStore.Columns.Add("TÊN ỨNG DỤNG", 350); [void]$lvStore.Columns.Add("TRẠNG THÁI", 200); [void]$lvStore.Columns.Add("ID WINGET", 180)
    
    $lblProgress = New-Object System.Windows.Forms.Label; $lblProgress.Text = "Sẵn sàng..."; $lblProgress.Location = "20,500"; $lblProgress.Size = "790,25"; $lblProgress.Font = $fontNoiDung
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,530"; $pgBar.Size = "790,25"; $pgBar.Style = "Continuous"
    
    # --- CÁC NÚT BẤM ---
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "🔄 ĐỒNG BỘ"; $btnSync.Size = "150,55"; $btnSync.Location = "20,600"; $btnSync.BackColor = "#607D8B"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fontNut
    $btnCheck = New-Object System.Windows.Forms.Button; $btnCheck.Text = "🔍 QUÉT MÁY"; $btnCheck.Size = "160,55"; $btnCheck.Location = "180,600"; $btnCheck.BackColor = "#00796B"; $btnCheck.ForeColor = "White"; $btnCheck.FlatStyle = "Flat"; $btnCheck.Font = $fontNut
    $btnDownload = New-Object System.Windows.Forms.Button; $btnDownload.Text = "📥 TẢI FILE SETUP LƯU TRỮ"; $btnDownload.Size = "220,55"; $btnDownload.Location = "350,600"; $btnDownload.BackColor = "#2196F3"; $btnDownload.ForeColor = "White"; $btnDownload.FlatStyle = "Flat"; $btnDownload.Font = $fontNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "⚡ CÀI ĐẶT NGAY"; $btnInstall.Size = "230,55"; $btnInstall.Location = "580,600"; $btnInstall.BackColor = "#D35400"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fontNut
    
    $form.Controls.AddRange(@($gbDown, $lvStore, $lblProgress, $pgBar, $btnSync, $btnCheck, $btnDownload, $btnInstall))

    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog() -eq "OK") { $txtPath.Text = $dialog.SelectedPath }
    })

    # --- HÀM NẠP DATA ---
    function Load-Local-Data {
        $lvStore.Items.Clear()
        if (Test-Path $localPath) {
            $csvData = Import-Csv -Path $localPath -Encoding UTF8
            foreach ($row in $csvData) {
                if ($row.Name) {
                    $li = New-Object System.Windows.Forms.ListViewItem($row.Name)
                    $li.Checked = ($row.Check -match "True")
                    [void]$li.SubItems.Add("Chờ quét...")
                    [void]$li.SubItems.Add($row.ID.Trim())
                    $lvStore.Items.Add($li)
                }
            }
        }
    }

    $btnSync.Add_Click({ 
        try {
            $lblProgress.Text = "Đang tải dữ liệu từ GitHub..."
            $form.Refresh()
            # ĐÃ FIX: Đổi (Get-Date -Ticks) thành (Get-Date).Ticks
            (New-Object System.Net.WebClient).DownloadFile($rawUrl + "?t=" + (Get-Date).Ticks, $localPath)
            Load-Local-Data
            $lblProgress.Text = "Đồng bộ xong!"
        } catch { 
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Chi tiết lỗi kết nối")
            Load-Local-Data 
            $lblProgress.Text = "Đồng bộ thất bại, đang dùng dữ liệu cũ."
        }
    })

    # --- HÀM QUÉT MÁY ---
    $btnCheck.Add_Click({
        if ($lvStore.Items.Count -eq 0) { return }
        $btnCheck.Enabled = $false; $btnInstall.Enabled = $false; $btnDownload.Enabled = $false
        $pgBar.Value = 0; $pgBar.Maximum = $lvStore.Items.Count

        foreach ($item in $lvStore.Items) {
            $appID = $item.SubItems[2].Text
            $item.SubItems[1].Text = "⏳ Đang soi..."
            $lblProgress.Text = "Kiểm tra hệ thống: $($item.Text)..."
            $lvStore.Refresh(); [System.Windows.Forms.Application]::DoEvents()

            & winget list --id "$appID" --exact 2>$null
            if ($LASTEXITCODE -eq 0) {
                $item.SubItems[1].Text = "✅ Đã cài"; $item.Checked = $false; $item.ForeColor = [System.Drawing.Color]::Gray
            } else {
                & winget list --name "$($item.Text)" --exact 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $item.SubItems[1].Text = "✅ Đã cài"; $item.Checked = $false; $item.ForeColor = [System.Drawing.Color]::Gray
                } else {
                    $item.SubItems[1].Text = "❌ Chưa có"; $item.Checked = $true; $item.ForeColor = [System.Drawing.Color]::Black
                }
            }
            $pgBar.Value++
        }
        $lblProgress.Text = "Quét xong! Những app đã cài đã được bỏ tích."
        $btnCheck.Enabled = $true; $btnInstall.Enabled = $true; $btnDownload.Enabled = $true
    })

    # --- HÀM CÀI ĐẶT ---
    $btnInstall.Add_Click({
        $items = @($lvStore.CheckedItems)
        if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false
        foreach ($item in $items) {
            $appID = $item.SubItems[2].Text
            $item.SubItems[1].Text = "🚀 Đang cài..."
            $lblProgress.Text = "Tiến hành cài: $($item.Text)..."
            $lvStore.Refresh(); [System.Windows.Forms.Application]::DoEvents()

            $args = "install --id `"$appID`" --accept-package-agreements --accept-source-agreements --force"
            $process = Start-Process "winget" -ArgumentList $args -WindowStyle Normal -PassThru
            if ($process) {
                while (-not $process.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                if ($process.ExitCode -eq 0) { $item.SubItems[1].Text = "✅ Xong"; $item.Checked = $false } 
                else { $item.SubItems[1].Text = "❌ Lỗi ($($process.ExitCode))" }
            }
        }
        $btnInstall.Enabled = $true; $lblProgress.Text = "Xử lý xong danh sách cài đặt!"
    })

    # --- HÀM TẢI FILE SETUP ---
    $btnDownload.Add_Click({
        $items = @($lvStore.CheckedItems)
        if ($items.Count -eq 0) { return }
        
        $dir = $txtPath.Text
        if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory | Out-Null }
        
        $btnDownload.Enabled = $false
        foreach ($item in $items) {
            $appID = $item.SubItems[2].Text
            $item.SubItems[1].Text = "📥 Đang tải file..."
            $lblProgress.Text = "Đang tải file Setup: $($item.Text)..."
            $lvStore.Refresh(); [System.Windows.Forms.Application]::DoEvents()

            $args = "download --id `"$appID`" --download-directory `"$dir`" --accept-package-agreements"
            $process = Start-Process "winget" -ArgumentList $args -WindowStyle Normal -PassThru
            if ($process) {
                while (-not $process.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                if ($process.ExitCode -eq 0) { $item.SubItems[1].Text = "✅ Đã tải"; $item.Checked = $false } 
                else { $item.SubItems[1].Text = "❌ Lỗi ($($process.ExitCode))" }
            }
        }
        $btnDownload.Enabled = $true; $lblProgress.Text = "Tải file hoàn tất!"
        Start-Process explorer.exe $dir
    })

    # Khởi động lần đầu
    if (Test-Path $localPath) { Load-Local-Data } 
    $form.ShowDialog() | Out-Null
}

&$LogicCaiPhanMem