# ==========================================================
# VIETTOOLBOX - OFFICE V180 (FULL OPTION - DEDICATED STATUS LABEL)
# ==========================================================

# 1. ÉP CHẠY QUYỀN ADMINISTRATOR
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. THIẾT LẬP TURBO (TỐI ƯU MẠNG & UTF8)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::UseNagleAlgorithm = $false
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Net.Http

# --- CẤU HÌNH API DRIVE ---
$B64_Key = "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))
$Global:LogPath = Join-Path $env:TEMP "VietToolbox_Office_Log.txt"

function Ghi-Log ($Message) {
    $Time = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    "[$Time] $Message" | Out-File -FilePath $Global:LogPath -Append -Encoding UTF8
}

$LogicCaiOfficeV180 = {
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    $fNut = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $fDash = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - OFFICE V180 (BẢN TRÙM CUỐI - FULL OPTION)"; $form.Size = "820,860"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false

    # --- [DANH SÁCH OFFICE] ---
    $lvOffice = New-Object System.Windows.Forms.ListView; $lvOffice.Size = "760,350"; $lvOffice.Location = "20,20"; $lvOffice.View = "Details"; $lvOffice.CheckBoxes = $true; $lvOffice.FullRowSelect = $true; $lvOffice.Font = $fStd; $lvOffice.GridLines = $true
    [void]$lvOffice.Columns.Add("PHIÊN BẢN OFFICE", 450); [void]$lvOffice.Columns.Add("TRẠNG THÁI", 280); [void]$lvOffice.Columns.Add("ID/LINK", 0)
    
    # --- [LABEL TRẠNG THÁI HỆ THỐNG - MỚI] ---
    $lbl7Check = New-Object System.Windows.Forms.Label; $lbl7Check.Text = "🔍 Đang kiểm tra hệ thống..."; $lbl7Check.Location = "20,375"; $lbl7Check.Size = "760,20"; $lbl7Check.Font = $fStd; $lbl7Check.ForeColor = "Orange"

    # --- [CHỌN THƯ MỤC LƯU] ---
    $lblPath = New-Object System.Windows.Forms.Label; $lblPath.Text = "LƯU TẠI:"; $lblPath.Location = "20,405"; $lblPath.Size = "80,25"; $lblPath.Font = $fNut
    $txtPath = New-Object System.Windows.Forms.TextBox; $txtPath.Location = "100,403"; $txtPath.Size = "510,30"; $txtPath.ReadOnly = $true; $txtPath.Font = $fStd
    $txtPath.Text = if (Test-Path "D:\" ) { "D:\VietToolbox_Office" } else { "C:\VietToolbox_Office" }
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "CHỌN THƯ MỤC"; $btnBrowse.Location = "625,401"; $btnBrowse.Size = "155,35"; $btnBrowse.FlatStyle = "Flat"; $btnBrowse.Font = $fNut
    
    # --- [PROGRESS & TỐC ĐỘ] ---
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,460"; $lblStatus.Size = "150,20"; $lblStatus.Font = $fStd; $lblStatus.ForeColor = "#1565C0"
    $lblSpeed = New-Object System.Windows.Forms.Label; $lblSpeed.Text = "-- MB/s | -- / -- MB"; $lblSpeed.Location = "180,460"; $lblSpeed.Size = "600,20"; $lblSpeed.TextAlign = "MiddleRight"; $lblSpeed.Font = $fDash; $lblSpeed.ForeColor = "#D84315"
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,490"; $pgBar.Size = "760,30"
    
    # --- [NÚT BẤM CHỨC NĂNG] ---
    $btnPause = New-Object System.Windows.Forms.Button; $btnPause.Text = "TẠM DỪNG"; $btnPause.Size = "240,55"; $btnPause.Location = "20,550"; $btnPause.Enabled = $false; $btnPause.FlatStyle = "Flat"; $btnPause.Font = $fNut
    $btnResume = New-Object System.Windows.Forms.Button; $btnResume.Text = "TIẾP TỤC"; $btnResume.Size = "240,55"; $btnResume.Location = "280,550"; $btnResume.Enabled = $false; $btnResume.FlatStyle = "Flat"; $btnResume.Font = $fNut
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "HỦY LỆNH"; $btnCancel.Size = "240,55"; $btnCancel.Location = "540,550"; $btnCancel.Enabled = $false; $btnCancel.FlatStyle = "Flat"; $btnCancel.Font = $fNut

    $btnLog = New-Object System.Windows.Forms.Button; $btnLog.Text = "NHẬT KÝ"; $btnLog.Size = "240,65"; $btnLog.Location = "20,630"; $btnLog.BackColor = "#607D8B"; $btnLog.ForeColor = "White"; $btnLog.FlatStyle = "Flat"; $btnLog.Font = $fNut
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "LÀM MỚI LIST"; $btnSync.Size = "240,65"; $btnSync.Location = "280,630"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "CÀI ĐẶT NGAY"; $btnInstall.Size = "240,65"; $btnInstall.Location = "540,630"; $btnInstall.BackColor = "#D32F2F"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fNut

    $form.Controls.AddRange(@($lvOffice, $lbl7Check, $lblPath, $txtPath, $btnBrowse, $lblStatus, $lblSpeed, $pgBar, $btnPause, $btnResume, $btnCancel, $btnLog, $btnSync, $btnInstall))

    # --- [LOGIC TỰ ĐỘNG KIỂM TRA 7-ZIP KHI MỞ] ---
    $form.Add_Shown({
        $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
        if (-not (Test-Path $7zPath)) { $7zPath = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
        
        if (-not (Test-Path $7zPath)) {
            $lbl7Check.Text = "⚠️ Thiếu 7-Zip! Đang tự động tải và cài đặt..."; $lbl7Check.ForeColor = "Red"
            $form.Refresh()
            
            $url7z = "https://www.7-zip.org/a/7z2408-x64.exe"
            $path7z = Join-Path $env:TEMP "7z_setup.exe"
            try {
                (New-Object System.Net.WebClient).DownloadFile($url7z, $path7z)
                Start-Process $path7z -ArgumentList "/S" -Wait -PassThru | Out-Null
                $lbl7Check.Text = "✅ Đã tự cài 7-Zip thành công!"; $lbl7Check.ForeColor = "Green"
            } catch {
                $lbl7Check.Text = "❌ Lỗi cài 7-Zip! Vui lòng cài thủ công."; $lbl7Check.ForeColor = "Red"
            }
        } else {
            $lbl7Check.Text = "✅ Hệ thống: 7-Zip đã sẵn sàng!"; $lbl7Check.ForeColor = "Green"
        }
    })

    # --- [HÀM DOWNLOAD DRIVE CORE] ---
    function Download-Core ($InputSource, $DestPath) {
        $HttpClient = New-Object System.Net.Http.HttpClient
        $driveId = if ($InputSource -match "id=([a-zA-Z0-9\-_]+)") { $matches[1] } else { $InputSource }
        $Url = "https://www.googleapis.com/drive/v3/files/$($driveId)?alt=media&key=$($Global:DriveApiKey)"
        try {
            $response = $HttpClient.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            if (-not $response.IsSuccessStatusCode) { return "ERROR" }
            $totalBytes = $response.Content.Headers.ContentLength
            $stream = $response.Content.ReadAsStreamAsync().Result
            $fileStream = [System.IO.File]::Create($DestPath)
            $buffer = New-Object byte[] 4194304
            $totalRead = 0; $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                if ($script:CancelDL) { 
                    $fileStream.Dispose(); $stream.Dispose(); $HttpClient.Dispose()
                    if (Test-Path $DestPath) { Remove-Item $DestPath -Force -ErrorAction SilentlyContinue }
                    return "CANCELLED" 
                }
                while ($script:PauseDL) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                $fileStream.Write($buffer, 0, $bytesRead)
                $totalRead += $bytesRead
                if ($sw.ElapsedMilliseconds -ge 1000) {
                    $speedMB = [Math]::Round(($totalRead / $sw.Elapsed.TotalSeconds) / 1MB, 2)
                    $pgBar.Value = if ($totalBytes -gt 0) { [int](($totalRead / $totalBytes) * 100) } else { 0 }
                    $lblSpeed.Text = "$speedMB MB/s | $([Math]::Round($totalRead/1MB,1)) MB"
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            $fileStream.Dispose(); $stream.Dispose(); return "SUCCESS"
        } catch { return "ERROR" }
    }

    $btnInstall.Add_Click({
        $items = @($lvOffice.CheckedItems); if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false; $btnCancel.Enabled = $true; $btnPause.Enabled = $true

        foreach ($item in $items) {
            $script:CancelDL = $false; $script:PauseDL = $false
            $safeName = ($item.SubItems[0].Text -replace '[\\/:*?"<>|()[\]\s]', '_') + ".iso"
            $destFile = Join-Path $txtPath.Text $safeName
            if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory | Out-Null }

            $item.SubItems[1].Text = "⏳ Đang tải..."; [System.Windows.Forms.Application]::DoEvents()
            $res = Download-Core $item.SubItems[2].Text $destFile

            if ($res -eq "SUCCESS") {
                $item.SubItems[1].Text = "📦 Đang bung nén..."
                $7z = "$env:ProgramFiles\7-Zip\7z.exe"; if (-not (Test-Path $7z)) { $7z = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
                
                if (Test-Path $7z) {
                    $extDir = $destFile + "_Ext"
                    $psi = New-Object System.Diagnostics.ProcessStartInfo -Property @{FileName=$7z; Arguments="x `"$destFile`" -o`"$extDir`" -y"; WindowStyle="Hidden"}
                    [System.Diagnostics.Process]::Start($psi).WaitForExit()

                    $setup = Get-ChildItem -Path $extDir -Filter "*.bat" -Recurse | Select-Object -First 1
                    if (-not $setup) { $setup = Get-ChildItem -Path $extDir -Filter "setup.exe" -Recurse | Select-Object -First 1 }

                    if ($setup) {
                        $item.SubItems[1].Text = "⚙️ Đang cài..."
                        Start-Process $setup.FullName -WorkingDirectory $setup.DirectoryName -Wait
                        $item.SubItems[1].Text = "✅ Hoàn tất"
                        Remove-Item $destFile -Force; Remove-Item $extDir -Recurse -Force -ErrorAction SilentlyContinue
                    } else { $item.SubItems[1].Text = "❌ Không thấy Setup" }
                } else { $item.SubItems[1].Text = "❌ Thiếu 7-Zip" }
            } elseif ($res -eq "CANCELLED") { $item.SubItems[1].Text = "🛑 Đã hủy"; break }
        }
        $btnInstall.Enabled = $true; $btnCancel.Enabled = $false; $btnPause.Enabled = $false
    })

    # --- [SỰ KIỆN NÚT PHỤ] ---
    $btnLog.Add_Click({ if (Test-Path $Global:LogPath) { Start-Process "notepad.exe" $Global:LogPath } })
    $btnSync.Add_Click({ Invoke-WebRequest ($rawUrl + "?t=" + (Get-Date).Ticks) -OutFile $localPath; Load-Local-Data; $lblStatus.Text = "Đã cập nhật!" })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtPath.Text = $fb.SelectedPath } })
    $btnCancel.Add_Click({ $script:CancelDL = $true; $lblStatus.Text = "Hủy lệnh..." })
    $btnPause.Add_Click({ $script:PauseDL = $true; $btnPause.Enabled = $false; $btnResume.Enabled = $true; $lblStatus.Text = "Tạm dừng" })
    $btnResume.Add_Click({ $script:PauseDL = $false; $btnResume.Enabled = $false; $btnPause.Enabled = $true; $lblStatus.Text = "Đang tải tiếp..." })

    function Load-Local-Data {
        if (Test-Path $localPath) {
            $lvOffice.Items.Clear(); $csv = Import-Csv $localPath -Encoding UTF8
            foreach ($r in $csv) { if ($r.Name) { $li = New-Object System.Windows.Forms.ListViewItem($r.Name); [void]$li.SubItems.Add("Sẵn sàng"); [void]$li.SubItems.Add($r.ID); $lvOffice.Items.Add($li) } }
        }
    }
    Load-Local-Data; $form.ShowDialog() | Out-Null
}

&$LogicCaiOfficeV180