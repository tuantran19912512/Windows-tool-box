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
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Net.Http

# --- [DÁN API KEY CỦA ÔNG VÀO ĐÂY] ---
$B64_Key = "QUl6YVN5QzlDT01WamxfZEU3enhPQ190eEF4RFhLUEotSjdXMjlR"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))
$Global:LogPath = Join-Path $env:TEMP "VietToolbox_Office_Log.txt"

# --- HÀM GHI LOG ---
function Ghi-Log ($Message) {
    $Time = Get-Date -Format "HH:mm:ss"
    "[$Time] $Message" | Out-File -FilePath $Global:LogPath -Append -Encoding UTF8
}

$LogicCaiOfficeV147 = {
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    $fNut = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 10)

    # --- KHỞI TẠO GIAO DIỆN ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - OFFICE V147 (FIX HỦY LỆNH)"; $form.Size = "820,860"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false

    # --- UI COMPONENTS (GIỮ NGUYÊN VỊ TRÍ CHUẨN) ---
    $lvOffice = New-Object System.Windows.Forms.ListView; $lvOffice.Size = "760,350"; $lvOffice.Location = "20,20"; $lvOffice.View = "Details"; $lvOffice.CheckBoxes = $true; $lvOffice.FullRowSelect = $true; $lvOffice.Font = $fStd; $lvOffice.GridLines = $true
    [void]$lvOffice.Columns.Add("PHIÊN BẢN OFFICE", 450); [void]$lvOffice.Columns.Add("TRẠNG THÁI", 280); [void]$lvOffice.Columns.Add("ID/LINK", 0)
    
    $lblPath = New-Object System.Windows.Forms.Label; $lblPath.Text = "LƯU TẠI:"; $lblPath.Location = "20,395"; $lblPath.Size = "80,25"; $lblPath.Font = $fNut
    $txtPath = New-Object System.Windows.Forms.TextBox; $txtPath.Location = "100,393"; $txtPath.Size = "510,30"; $txtPath.ReadOnly = $true; $txtPath.Font = $fStd
    $txtPath.Text = if (Test-Path "D:\" ) { "D:\VietToolbox_Office" } else { "C:\VietToolbox_Office" }
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "CHỌN THƯ MỤC"; $btnBrowse.Location = "625,391"; $btnBrowse.Size = "155,35"; $btnBrowse.FlatStyle = "Flat"; $btnBrowse.Font = $fNut
    
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,460"; $lblStatus.Size = "400,20"
    $lblSpeed = New-Object System.Windows.Forms.Label; $lblSpeed.Text = "0 MB/s"; $lblSpeed.Location = "450,460"; $lblSpeed.Size = "330,20"; $lblSpeed.TextAlign = "MiddleRight"; $lblSpeed.Font = $fNut
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,490"; $pgBar.Size = "760,30"
    
    $btnPause = New-Object System.Windows.Forms.Button; $btnPause.Text = "TẠM DỪNG"; $btnPause.Size = "240,55"; $btnPause.Location = "20,550"; $btnPause.Enabled = $false; $btnPause.FlatStyle = "Flat"; $btnPause.Font = $fNut
    $btnResume = New-Object System.Windows.Forms.Button; $btnResume.Text = "TIẾP TỤC"; $btnResume.Size = "240,55"; $btnResume.Location = "280,550"; $btnResume.Enabled = $false; $btnResume.FlatStyle = "Flat"; $btnResume.Font = $fNut
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "HỦY LỆNH"; $btnCancel.Size = "240,55"; $btnCancel.Location = "540,550"; $btnCancel.Enabled = $false; $btnCancel.FlatStyle = "Flat"; $btnCancel.Font = $fNut

    $btnLog = New-Object System.Windows.Forms.Button; $btnLog.Text = "XEM NHẬT KÝ"; $btnLog.Size = "240,65"; $btnLog.Location = "20,630"; $btnLog.BackColor = "#607D8B"; $btnLog.ForeColor = "White"; $btnLog.FlatStyle = "Flat"; $btnLog.Font = $fNut
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "LÀM MỚI LIST"; $btnSync.Size = "240,65"; $btnSync.Location = "280,630"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "BẮT ĐẦU CÀI ĐẶT"; $btnInstall.Size = "240,65"; $btnInstall.Location = "540,630"; $btnInstall.BackColor = "#D32F2F"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fNut

    $form.Controls.AddRange(@($lvOffice, $lblPath, $txtPath, $btnBrowse, $lblStatus, $lblSpeed, $pgBar, $btnPause, $btnResume, $btnCancel, $btnLog, $btnSync, $btnInstall))

    # --- HÀM TẢI CÓ XỬ LÝ HỦY ---
    function Download-Core ($InputSource, $DestPath) {
        $HttpClient = New-Object System.Net.Http.HttpClient
        $Url = if ($InputSource -notmatch "^http" -or $InputSource -match "drive.google.com") {
            $driveId = if ($InputSource -match "id=([a-zA-Z0-9\-_]+)") { $matches[1] } elseif ($InputSource -match "\/d\/([a-zA-Z0-9\-_]+)") { $matches[1] } else { $InputSource }
            "https://www.googleapis.com/drive/v3/files/$($driveId)?alt=media&key=$($Global:DriveApiKey)&acknowledgeAbuse=true"
        } else { $InputSource }

        try {
            $response = $HttpClient.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            if (-not $response.IsSuccessStatusCode) { return $false }
            $totalBytes = $response.Content.Headers.ContentLength
            $stream = $response.Content.ReadAsStreamAsync().Result
            $fileStream = [System.IO.File]::Create($DestPath)
            $buffer = New-Object byte[] 102400
            $totalRead = 0; $sw = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                if ($script:CancelDL) { 
                    $fileStream.Close(); $stream.Close(); $HttpClient.Dispose()
                    # --- ÉP XÓA FILE TẠI ĐÂY ---
                    if (Test-Path $DestPath) { Remove-Item $DestPath -Force -ErrorAction SilentlyContinue }
                    return "CANCELLED"
                }
                while ($script:PauseDL) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                
                $fileStream.Write($buffer, 0, $bytesRead); $totalRead += $bytesRead
                if ($sw.ElapsedMilliseconds -ge 800) {
                    $pgBar.Value = if ($totalBytes -gt 0) { [int](($totalRead / $totalBytes) * 100) } else { 0 }
                    $lblSpeed.Text = "$([Math]::Round(($totalRead / $sw.Elapsed.TotalSeconds) / 1MB, 2)) MB/s"
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            $fileStream.Close(); $stream.Close(); $HttpClient.Dispose()
            return $true
        } catch { return $false }
    }

    # --- SỰ KIỆN CÀI ĐẶT ---
    $btnInstall.Add_Click({
        $items = @($lvOffice.CheckedItems); if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false; $btnCancel.Enabled = $true; $btnPause.Enabled = $true
        
        foreach ($item in $items) {
            $script:CancelDL = $false; $script:PauseDL = $false
            $destFile = Join-Path $txtPath.Text "Office_Setup.img"
            if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory | Out-Null }
            
            $item.SubItems[1].Text = "⏳ Đang tải..."; [System.Windows.Forms.Application]::DoEvents()
            
            $res = Download-Core $item.SubItems[2].Text $destFile
            
            if ($res -eq "CANCELLED") {
                $item.SubItems[1].Text = "❌ Đã hủy"; 
                Ghi-Log "Người dùng đã hủy lệnh tải.";
                # --- RESET UI ---
                $pgBar.Value = 0; $lblSpeed.Text = "0 MB/s"; $lblStatus.Text = "Đã dừng!";
                break # Thoát khỏi vòng lặp cài đặt luôn
            } elseif ($res -eq $true) {
                $item.SubItems[1].Text = "💿 Đang cài..."; [System.Windows.Forms.Application]::DoEvents()
                $mount = Mount-DiskImage -ImagePath $destFile -PassThru
                $letter = ($mount | Get-Volume).DriveLetter
                if ($letter) {
                    Start-Process "$($letter):\setup.exe" -Wait
                    Dismount-DiskImage -ImagePath $destFile | Out-Null
                    if (Test-Path $destFile) { Remove-Item $destFile -Force -ErrorAction SilentlyContinue }
                    $item.SubItems[1].Text = "✅ Hoàn tất"
                }
            } else { $item.SubItems[1].Text = "❌ Lỗi tải" }
        }
        $btnInstall.Enabled = $true; $btnCancel.Enabled = $false; $btnPause.Enabled = $false
        $pgBar.Value = 0; $lblSpeed.Text = "0 MB/s"
    })

    # --- SỰ KIỆN HỦY ---
    $btnCancel.Add_Click({ 
        $script:CancelDL = $true; 
        $lblStatus.Text = "Đang dọn dẹp..."; 
        [System.Windows.Forms.Application]::DoEvents()
    })

    $btnPause.Add_Click({ $script:PauseDL = $true; $btnPause.Enabled = $false; $btnResume.Enabled = $true; $lblStatus.Text = "Tạm dừng" })
    $btnResume.Add_Click({ $script:PauseDL = $false; $btnResume.Enabled = $false; $btnPause.Enabled = $true; $lblStatus.Text = "Tiếp tục" })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath } })
    $btnLog.Add_Click({ if (Test-Path $Global:LogPath) { Start-Process "notepad.exe" $Global:LogPath } })
    $btnSync.Add_Click({ try { Invoke-WebRequest -Uri ($rawUrl + "?t=" + (Get-Date -UFormat %s)) -OutFile $localPath -UseBasicParsing; Load-Local-Data; $lblStatus.Text = "Đã làm mới!" } catch {} })

    function Load-Local-Data {
        if (Test-Path $localPath) {
            $lvOffice.Items.Clear()
            $csv = Import-Csv -Path $localPath -Encoding UTF8
            foreach ($row in $csv) { if ($row.Name) { $li = New-Object System.Windows.Forms.ListViewItem($row.Name); [void]$li.SubItems.Add("Sẵn sàng"); [void]$li.SubItems.Add($row.ID); $lvOffice.Items.Add($li) } }
        }
    }
    Load-Local-Data
    $form.ShowDialog() | Out-Null
}
&$LogicCaiOfficeV147