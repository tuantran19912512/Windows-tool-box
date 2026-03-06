# ==========================================================
# 1. ÉP CHẠY QUYỀN ADMINISTRATOR
# ==========================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. THIẾT LẬP MÔI TRƯỜNG
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicCaiOfficeV63 = {
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    # --- ĐỊNH NGHĨA FONT XỊN (TO & RÕ) ---
    $fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 12)
    $fBtn = New-Object System.Drawing.Font("Segoe UI Bold", 11)
    $fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    $fItalic = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)

    # --- KHỞI TẠO GIAO DIỆN ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - OFFICE V63 (BIG FONT EDITION)"; $form.Size = "880,950"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    # 1. Danh sách ListView (Size to)
    $lvOffice = New-Object System.Windows.Forms.ListView
    $lvOffice.Size = "820,250"; $lvOffice.Location = "20,20"; $lvOffice.View = "Details"; $lvOffice.CheckBoxes = $true; $lvOffice.FullRowSelect = $true; $lvOffice.Font = $fStd; $lvOffice.BorderStyle = "FixedSingle"
    [void]$lvOffice.Columns.Add("PHIÊN BẢN OFFICE", 550); [void]$lvOffice.Columns.Add("TRẠNG THÁI", 250)

    # 2. Quản lý Thư mục (Nới rộng nhãn 180px - KHÔNG CẮT CHỮ)
    $lblPath = New-Object System.Windows.Forms.Label
    $lblPath.Text = "THƯ MỤC TẠM:"; $lblPath.Location = "20,285"; $lblPath.Size = "180,25"; $lblPath.Font = $fBtn
    
    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = "200,283"; $txtPath.Size = "250,30"; $txtPath.ReadOnly = $true; $txtPath.Font = $fStd; $txtPath.BorderStyle = "FixedSingle"
    $bestDrive = Get-PSDrive -PSProvider FileSystem | Sort-Object Free -Descending | Select-Object -First 1
    $txtPath.Text = Join-Path $bestDrive.Root "VietToolbox_Temp"
    
    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "CHỌN LẠI"; $btnBrowse.Location = "460,282"; $btnBrowse.Size = "130,35"; $btnBrowse.FlatStyle = "Flat"; $btnBrowse.BackColor = "#E0E0E0"; $btnBrowse.Font = $fBtn
    
    $btnOpenDir = New-Object System.Windows.Forms.Button
    $btnOpenDir.Text = "MỞ THƯ MỤC"; $btnOpenDir.Location = "600,282"; $btnOpenDir.Size = "160,35"; $btnOpenDir.FlatStyle = "Flat"; $btnOpenDir.BackColor = "#E0E0E0"; $btnOpenDir.Font = $fBtn
    
    $lblDiskSpace = New-Object System.Windows.Forms.Label
    $lblDiskSpace.Location = "770,288"; $lblDiskSpace.Size = "100,25"; $lblDiskSpace.Font = $fBtn; $lblDiskSpace.ForeColor = "DarkGreen"

    # 3. Tiến độ Tải xuống
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,370"; $lblStatus.Size = "500,25"; $lblStatus.Font = $fItalic
    $lblSpeed = New-Object System.Windows.Forms.Label; $lblSpeed.Text = "0 MB/s | Còn: 0s"; $lblSpeed.Location = "560,370"; $lblSpeed.Size = "280,25"; $lblSpeed.Font = $fBtn; $lblSpeed.ForeColor = "Blue"; $lblSpeed.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight 
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,400"; $pgBar.Size = "820,25"

    # 4. Tiến độ Cài đặt
    $lblInstallStatus = New-Object System.Windows.Forms.Label; $lblInstallStatus.Text = "Chờ lệnh cài đặt..."; $lblInstallStatus.Location = "20,480"; $lblInstallStatus.Size = "820,25"; $lblInstallStatus.Font = $fItalic
    $pgInstall = New-Object System.Windows.Forms.ProgressBar; $pgInstall.Location = "20,510"; $pgInstall.Size = "820,25"

    # 5. Bộ nút điều khiển (THẲNG HÀNG Y=580)
    $btnPause = New-Object System.Windows.Forms.Button; $btnPause.Text = "TẠM DỪNG"; $btnPause.Size = "200,55"; $btnPause.Location = "20,580"; $btnPause.Enabled = $false; $btnPause.BackColor = "#FFF9C4"; $btnPause.FlatStyle = "Flat"; $btnPause.Font = $fBtn
    $btnResume = New-Object System.Windows.Forms.Button; $btnResume.Text = "TIẾP TỤC"; $btnResume.Size = "200,55"; $btnResume.Location = "230,580"; $btnResume.Enabled = $false; $btnResume.BackColor = "#E8F5E9"; $btnResume.FlatStyle = "Flat"; $btnResume.Font = $fBtn
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "HỦY LỆNH"; $btnCancel.Size = "200,55"; $btnCancel.Location = "440,580"; $btnCancel.Enabled = $false; $btnCancel.BackColor = "#FFEBEE"; $btnCancel.FlatStyle = "Flat"; $btnCancel.Font = $fBtn

    # 6. Nút chính dưới cùng
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "LÀM MỚI DANH SÁCH"; $btnSync.Size = "260,70"; $btnSync.Location = "20,800"; $btnSync.FlatStyle = "Flat"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.Font = $fBtn
    $btnInstallAct = New-Object System.Windows.Forms.Button; $btnInstallAct.Text = "BẮT ĐẦU CÀI ĐẶT"; $btnInstallAct.Size = "550,70"; $btnInstallAct.Location = "290,800"; $btnInstallAct.FlatStyle = "Flat"; $btnInstallAct.BackColor = "#D32F2F"; $btnInstallAct.ForeColor = "White"; $btnInstallAct.Font = $fTitle

    # NẠP LINH KIỆN
    $form.Controls.AddRange(@($lvOffice, $lblPath, $txtPath, $btnBrowse, $btnOpenDir, $lblDiskSpace, $lblStatus, $lblSpeed, $pgBar, $lblInstallStatus, $pgInstall, $btnPause, $btnResume, $btnCancel, $btnSync, $btnInstallAct))

    # --- HÀM CẬP NHẬT DUNG LƯỢNG ---
    function Update-DiskSpace {
        param($Path)
        try {
            $drive = Get-PSDrive $Path.Substring(0,1)
            $free = [Math]::Round($drive.Free / 1GB, 1)
            $lblDiskSpace.Text = "$free GB"; $lblDiskSpace.ForeColor = if ($free -lt 5) { "Red" } else { "DarkGreen" }
        } catch {}
    }

    # --- HÀM TẢI DANH SÁCH ---
    function Load-Data {
        $lvOffice.Items.Clear()
        if (Test-Path $localPath) {
            Import-Csv $localPath | foreach {
                $li = New-Object System.Windows.Forms.ListViewItem($_.Name)
                [void]$li.SubItems.Add("Sẵn sàng")
                $li.Tag = $_.ID # Lưu link vào Tag để bốc cho chuẩn
                $lvOffice.Items.Add($li)
            }
        }
    }

    # --- HÀM TẠO SHORTCUT ---
    function Create-Shortcuts {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $roots = @("${env:ProgramFiles}\Microsoft Office\root\Office16", "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16")
        $apps = @{ "Word" = "WINWORD.EXE"; "Excel" = "EXCEL.EXE"; "PowerPoint" = "POWERPNT.EXE" }
        $wsh = New-Object -ComObject WScript.Shell
        foreach ($r in $roots) { if (Test-Path $r) { foreach ($k in $apps.Keys) { $exe = Join-Path $r $apps[$k]; if (Test-Path $exe) { $s = $wsh.CreateShortcut((Join-Path $desktop "$k.lnk")); $s.TargetPath = $exe; $s.IconLocation = "$exe, 0"; $s.Save() } }; break } }
    }

    # --- HÀM TẢI FILE TURBO ---
    function Start-TurboDownload ($Url, $DestPath) {
        $wc = New-Object System.Net.WebClient
        try {
            $stream = $wc.OpenRead($Url); $total = [int64]$wc.ResponseHeaders["Content-Length"]
            $fileStream = New-Object System.IO.FileStream($DestPath, [System.IO.FileMode]::Create)
            $buffer = New-Object byte[] 4194304; $current = 0; $sw = [System.Diagnostics.Stopwatch]::StartNew(); $lastBytes = 0
            while (($bytes = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                if ($script:CancelDL) { $fileStream.Close(); $stream.Close(); return "Canceled" }
                while ($script:PauseDL) { $sw.Stop(); [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                if (-not $sw.IsRunning) { $sw.Start() }
                $fileStream.Write($buffer, 0, $bytes); $current += $bytes
                if ($sw.ElapsedMilliseconds -ge 1000) {
                    $speed = [Math]::Round(($current - $lastBytes) / 1024 / 1024, 2); $rem = if ($speed -gt 0) { [int](($total - $current) / 1024 / 1024 / $speed) } else { 0 }
                    $pgBar.Value = [int](($current / $total) * 100); $lblSpeed.Text = "$speed MB/s | Còn: $rem s"; $lblStatus.Text = "Tiến độ: $($pgBar.Value)% | ($([Math]::Round($current/1GB,2)) / $([Math]::Round($total/1GB,2)) GB)"
                    $lastBytes = $current; $sw.Restart()
                }
                [System.Windows.Forms.Application]::DoEvents()
            }
            $fileStream.Close(); $stream.Close(); return "Success"
        } catch { return $_.Exception.Message } finally { $wc.Dispose() }
    }

    # --- SỰ KIỆN CÀI ĐẶT ---
    $btnInstallAct.Add_Click({
        $items = @($lvOffice.CheckedItems)
        if ($items.Count -eq 0) { return }
        $btnInstallAct.Enabled = $false; $btnPause.Enabled = $true; $btnCancel.Enabled = $true
        foreach ($item in $items) {
            $dest = Join-Path $txtPath.Text (($item.Text -replace '[^a-zA-Z0-9]', '_') + ".img")
            $item.SubItems[1].Text = "⏳ Đang tải..."; [System.Windows.Forms.Application]::DoEvents()
            $res = Start-TurboDownload $item.Tag $dest
            if ($res -eq "Success") {
                $item.SubItems[1].Text = "✅ Đang cài Silent..."; $pgInstall.Style = "Marquee"
                try {
                    Mount-DiskImage -ImagePath $dest -PassThru | Out-Null; Start-Sleep -Seconds 5
                    $letter = (Get-DiskImage -ImagePath $dest | Get-Volume).DriveLetter
                    if ($letter) {
                        $setup = Get-ChildItem -Path "${letter}:\" -Filter "setup.exe" -Recurse | Select -First 1
                        if ($setup) {
                            $xml = Join-Path $env:TEMP "silent.xml"
                            "<Configuration><Add OfficeClientEdition='64'><Product ID='O365ProPlusRetail'><Language ID='vi-vn'/></Product></Add><Display Level='None' AcceptEULA='TRUE'/></Configuration>" | Out-File $xml -Encoding UTF8
                            $lblInstallStatus.Text = "Đang chạy Setup Office ngầm..."; [System.Windows.Forms.Application]::DoEvents()
                            Start-Process -FilePath $setup.FullName -ArgumentList "/configure `"$xml`"" -WorkingDirectory $setup.DirectoryName -Wait
                        }
                    }
                    Dismount-DiskImage -ImagePath $dest | Out-Null; if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
                    Create-Shortcuts
                    $item.SubItems[1].Text = "✅ Xong"
                    $pgInstall.Style = "Blocks"; $pgInstall.Value = 100; $lblInstallStatus.Text = "Cài đặt hoàn tất!"
                } catch { $item.SubItems[1].Text = "❌ Lỗi" }
            }
        }
        $btnInstallAct.Enabled = $true; $btnPause.Enabled = $false; $btnCancel.Enabled = $false
    })

    $btnPause.Add_Click({ $script:PauseDL = $true; $btnPause.Enabled = $false; $btnResume.Enabled = $true })
    $btnResume.Add_Click({ $script:PauseDL = $false; $btnPause.Enabled = $true; $btnResume.Enabled = $false })
    $btnCancel.Add_Click({ $script:CancelDL = $true })
    $btnOpenDir.Add_Click({ if (Test-Path $txtPath.Text) { Start-Process $txtPath.Text } })
    $btnSync.Add_Click({ (New-Object System.Net.WebClient).DownloadFile($rawUrl + "?t=" + (Get-Date -UFormat %s), $localPath); Load-Data })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath; Update-DiskSpace $fb.SelectedPath } })

    Update-DiskSpace $txtPath.Text; Load-Data; $form.ShowDialog() | Out-Null
}
&$LogicCaiOfficeV63