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
    $form.Text = "VIETTOOLBOX V13.1 - FIX LỖI QUÉT"; $form.Size = "850,750"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"; $form.Topmost = $true
    
    $lvStore = New-Object System.Windows.Forms.ListView; $lvStore.Size = "790,400"; $lvStore.Location = "20,20"; $lvStore.View = "Details"; $lvStore.CheckBoxes = $true; $lvStore.FullRowSelect = $true; $lvStore.Font = $fontNoiDung; $lvStore.BorderStyle = "FixedSingle"
    [void]$lvStore.Columns.Add("TÊN ỨNG DỤNG", 350); [void]$lvStore.Columns.Add("TRẠNG THÁI", 200); [void]$lvStore.Columns.Add("ID WINGET", 180)
    
    $lblProgress = New-Object System.Windows.Forms.Label; $lblProgress.Text = "Sẵn sàng..."; $lblProgress.Location = "20,430"; $lblProgress.Size = "790,25"; $lblProgress.Font = $fontNoiDung
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,460"; $pgBar.Size = "790,25"; $pgBar.Style = "Continuous"
    
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "🔄 ĐỒNG BỘ"; $btnSync.Size = "150,55"; $btnSync.Location = "20,530"; $btnSync.BackColor = "#607D8B"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fontNut
    $btnCheck = New-Object System.Windows.Forms.Button; $btnCheck.Text = "🔍 QUÉT MÁY KHÁCH"; $btnCheck.Size = "220,55"; $btnCheck.Location = "180,530"; $btnCheck.BackColor = "#00796B"; $btnCheck.ForeColor = "White"; $btnCheck.FlatStyle = "Flat"; $btnCheck.Font = $fontNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "⚡ BẮT ĐẦU CÀI ĐẶT"; $btnInstall.Size = "390,55"; $btnInstall.Location = "420,530"; $btnInstall.BackColor = "#D35400"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fontNut
    
    $form.Controls.AddRange(@($lvStore, $lblProgress, $pgBar, $btnSync, $btnCheck, $btnInstall))

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

    # --- HÀM QUÉT MÁY (BẢN FIX TRIỆT ĐỂ) ---
    $btnCheck.Add_Click({
        if ($lvStore.Items.Count -eq 0) { return }
        $btnCheck.Enabled = $false; $btnInstall.Enabled = $false
        $pgBar.Value = 0; $pgBar.Maximum = $lvStore.Items.Count

        foreach ($item in $lvStore.Items) {
            $appID = $item.SubItems[2].Text
            $item.SubItems[1].Text = "⏳ Đang soi..."
            $lblProgress.Text = "Kiểm tra hệ thống: $($item.Text)..."
            $lvStore.Refresh(); [System.Windows.Forms.Application]::DoEvents()

            # FIX TẠI ĐÂY: Bỏ --source winget để quét toàn bộ máy khách
            & winget list --id "$appID" --exact 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                $item.SubItems[1].Text = "✅ Đã cài"
                $item.Checked = $false
                $item.ForeColor = [System.Drawing.Color]::Gray
            } else {
                # Thử thêm một lần nữa bằng Tên đề phòng ID trong máy khách bị lệch
                & winget list --name "$($item.Text)" --exact 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $item.SubItems[1].Text = "✅ Đã cài"
                    $item.Checked = $false
                    $item.ForeColor = [System.Drawing.Color]::Gray
                } else {
                    $item.SubItems[1].Text = "❌ Chưa có"
                    $item.Checked = $true
                    $item.ForeColor = [System.Drawing.Color]::Black
                }
            }
            $pgBar.Value++
        }
        $lblProgress.Text = "Quét xong! Những app đã cài đã được bỏ tích."
        $btnCheck.Enabled = $true; $btnInstall.Enabled = $true
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
                while (-not $process.HasExited) {
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 200
                }
                if ($process.ExitCode -eq 0) {
                    $item.SubItems[1].Text = "✅ Xong"; $item.Checked = $false
                } else {
                    $item.SubItems[1].Text = "❌ Lỗi ($($process.ExitCode))"
                }
            }
        }
        $btnInstall.Enabled = $true; $lblProgress.Text = "Xử lý xong danh sách!"
    })

    $btnSync.Add_Click({ 
        try {
            (New-Object System.Net.WebClient).DownloadFile($rawUrl + "?t=" + (Get-Date -Ticks), $localPath)
            Load-Local-Data; $lblProgress.Text = "Đồng bộ xong!"
        } catch { Load-Local-Data }
    })

    if (Test-Path $localPath) { Load-Local-Data } else { Sync-From-Cloud }
    $form.ShowDialog() | Out-Null
}

&$LogicCaiPhanMem