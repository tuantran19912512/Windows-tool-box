# ==========================================================
# 1. KIỂM TRA VÀ ÉP CHẠY QUYỀN ADMINISTRATOR
# ==========================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

# 2. THIẾT LẬP MÔI TRƯỜNG
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicCaiOfficeV26 = {
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    
    # Biến điều khiển tải
    $script:CancelDL = $false
    $script:PauseDL = $false

    # --- KHỞI TẠO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - OFFICE V26 (FULL CONTROL & ADMIN)"; $form.Size = "800,800"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lvOffice = New-Object System.Windows.Forms.ListView; $lvOffice.Size = "740,280"; $lvOffice.Location = "20,20"; $lvOffice.View = "Details"; $lvOffice.CheckBoxes = $true; $lvOffice.FullRowSelect = $true; $lvOffice.Font = New-Object System.Drawing.Font("Segoe UI", 10); $lvOffice.BorderStyle = "FixedSingle"
    [void]$lvOffice.Columns.Add("PHIÊN BẢN OFFICE", 450); [void]$lvOffice.Columns.Add("TRẠNG THÁI", 250); [void]$lvOffice.Columns.Add("LINK/ID", 0)

    # --- CHỌN Ổ ĐĨA & DUNG LƯỢNG ---
    $txtPath = New-Object System.Windows.Forms.TextBox; $txtPath.Location = "100,312"; $txtPath.Size = "420,25"; $txtPath.ReadOnly = $true
    $bestDrive = Get-PSDrive -PSProvider FileSystem | Sort-Object Free -Descending | Select-Object -First 1
    $txtPath.Text = Join-Path $bestDrive.Root "VietToolbox_Temp"
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "CHỌN THƯ MỤC"; $btnBrowse.Location = "530,310"; $btnBrowse.Size = "110,30"; $btnBrowse.FlatStyle = "Flat"
    $lblDiskSpace = New-Object System.Windows.Forms.Label; $lblDiskSpace.Location = "650,315"; $lblDiskSpace.Size = "120,20"; $lblDiskSpace.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng (Quyền Admin)..."; $lblStatus.Location = "20,360"; $lblStatus.Size = "740,20"; $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,385"; $pgBar.Size = "740,25"

    # --- CỤM NÚT ĐIỀU KHIỂN (ĐÃ QUAY TRỞ LẠI) ---
    $btnPause = New-Object System.Windows.Forms.Button; $btnPause.Text = "TẠM DỪNG"; $btnPause.Size = "150,40"; $btnPause.Location = "20,430"; $btnPause.Enabled = $false; $btnPause.FlatStyle = "Flat"; $btnPause.BackColor = "#FFF9C4"
    $btnResume = New-Object System.Windows.Forms.Button; $btnResume.Text = "TIẾP TỤC"; $btnResume.Size = "150,40"; $btnResume.Location = "180,430"; $btnResume.Enabled = $false; $btnResume.FlatStyle = "Flat"; $btnResume.BackColor = "#E8F5E9"
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "HỦY TẢI"; $btnCancel.Size = "150,40"; $btnCancel.Location = "340,430"; $btnCancel.Enabled = $false; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = "#FFEBEE"

    # --- NÚT CHÍNH ---
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "BẮT ĐẦU CÀI ĐẶT"; $btnInstall.Size = "330,60"; $btnInstall.Location = "430,650"; $btnInstall.BackColor = "#D32F2F"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11)
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "LÀM MỚI"; $btnSync.Size = "150,60"; $btnSync.Location = "260,650"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"

    $form.Controls.AddRange(@($lvOffice, $txtPath, $btnBrowse, $lblDiskSpace, $lblStatus, $pgBar, $btnPause, $btnResume, $btnCancel, $btnSync, $btnInstall))

    function Update-DiskInfo {
        param($Path)
        try {
            $drive = Get-PSDrive ([System.IO.Path]::GetPathRoot($Path).Substring(0,1))
            $free = [Math]::Round($drive.Free / 1GB, 1)
            $lblDiskSpace.Text = "Trống: $free GB"; $lblDiskSpace.ForeColor = if ($free -lt 5) { "Red" } else { "DarkGreen" }
        } catch {}
    }

    # --- HÀM TẢI FILE MAX SPEED + SPEED MONITOR ---
    function Start-V26Download ($Url, $DestPath) {
        $script:CancelDL = $false; $script:PauseDL = $false
        $wc = New-Object System.Net.WebClient
        try {
            $stream = $wc.OpenRead($Url); $total = [int64]$wc.ResponseHeaders["Content-Length"]
            if (Test-Path $DestPath) { if ((Get-Item $DestPath).Length -eq $total) { return "Success" } }

            $fileStream = New-Object System.IO.FileStream($DestPath, [System.IO.FileMode]::Create)
            $buffer = New-Object byte[] 1048576; $current = 0
            $sw = [System.Diagnostics.Stopwatch]::StartNew(); $lastBytes = 0

            while (($bytes = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                if ($script:CancelDL) { $fileStream.Close(); $stream.Close(); return "Canceled" }
                while ($script:PauseDL) { $sw.Stop(); [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                if (-not $sw.IsRunning) { $sw.Start() }
                $fileStream.Write($buffer, 0, $bytes); $current += $bytes
                if ($sw.ElapsedMilliseconds -ge 800) {
                    $speed = [Math]::Round(($current - $lastBytes) / 1024 / 1024 / ($sw.ElapsedMilliseconds / 1000), 2)
                    $pgBar.Value = [int](($current / $total) * 100)
                    $lblStatus.Text = "Tiến độ: $($pgBar.Value)% | Tốc độ: $speed MB/s | ($([Math]::Round($current/1MB,1)) MB / $([Math]::Round($total/1MB,1)) MB)"
                    $lastBytes = $current; $sw.Restart()
                }
                [System.Windows.Forms.Application]::DoEvents()
            }
            $fileStream.Close(); $stream.Close(); return "Success"
        } catch { return $_.Exception.Message } finally { $wc.Dispose() }
    }

    $btnInstall.Add_Click({
        $items = @($lvOffice.CheckedItems)
        if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false; $btnPause.Enabled = $true; $btnCancel.Enabled = $true

        foreach ($item in $items) {
            $cleanName = $item.Text -replace '[^a-zA-Z0-9]', '_'
            $dest = Join-Path $txtPath.Text "$($cleanName).img"
            $item.SubItems[1].Text = "⏳ Đang xử lý..."; [System.Windows.Forms.Application]::DoEvents()
            
            if ((Start-V26Download $item.SubItems[2].Text $dest) -eq "Success") {
                $item.SubItems[1].Text = "✅ Đang Mount..."
                try {
                    $mount = Mount-DiskImage -ImagePath $dest -PassThru
                    $setupPath = $null
                    for ($i = 1; $i -le 15; $i++) {
                        $lblStatus.Text = "Đợi Windows nạp ổ ảo... ($i/15s)"
                        [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Seconds 1
                        $letter = (Get-DiskImage -ImagePath $dest | Get-Volume).DriveLetter
                        if ($letter) {
                            $setupPath = Get-ChildItem -Path "${letter}:\" -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue | Select -First 1
                            if ($setupPath) { Start-Sleep -Seconds 2; break }
                        }
                    }
                    if ($setupPath) {
                        $item.SubItems[1].Text = "✅ Đang cài..."
                        Start-Process -FilePath $setupPath.FullName -WorkingDirectory $setupPath.DirectoryName -Wait
                        $item.SubItems[1].Text = "✅ Hoàn tất"
                    } else { $item.SubItems[1].Text = "❌ Không tìm thấy Setup" }
                    Dismount-DiskImage -ImagePath $dest | Out-Null
                } catch { $item.SubItems[1].Text = "❌ Lỗi hệ thống" }
            }
        }
        $btnInstall.Enabled = $true; $btnPause.Enabled = $false; $btnCancel.Enabled = $false
    })

    $btnPause.Add_Click({ $script:PauseDL = $true; $btnPause.Enabled = $false; $btnResume.Enabled = $true; $lblStatus.Text = "Đã tạm dừng tải." })
    $btnResume.Add_Click({ $script:PauseDL = $false; $btnPause.Enabled = $true; $btnResume.Enabled = $false; $lblStatus.Text = "Tiếp tục tải..." })
    $btnCancel.Add_Click({ $script:CancelDL = $true })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath; Update-DiskInfo $fb.SelectedPath } })
    $btnSync.Add_Click({ (New-Object System.Net.WebClient).DownloadFile($rawUrl + "?t=" + (Get-Date -UFormat %s), $localPath); Load-Data })
    function Load-Data { $lvOffice.Items.Clear(); if (Test-Path $localPath) { Import-Csv $localPath | foreach { $li = New-Object System.Windows.Forms.ListViewItem($_.Name); [void]$li.SubItems.Add("Sẵn sàng"); [void]$li.SubItems.Add($_.ID); $lvOffice.Items.Add($li) } } }
    
    Update-DiskInfo $txtPath.Text; Load-Data; $form.ShowDialog() | Out-Null
}

&$LogicCaiOfficeV26