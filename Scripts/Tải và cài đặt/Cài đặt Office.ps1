# ==========================================================
# 1. ÉP CHẠY QUYỀN ADMINISTRATOR
# ==========================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. THIẾT LẬP MÔI TRƯỜNG TỐI ƯU HÓA MẠNG (TURBO)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::UseNagleAlgorithm = $false
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Net.Http

# --- [DÁN API KEY CỦA ÔNG VÀO ĐÂY] ---
$B64_Key = "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))
$Global:LogPath = Join-Path $env:TEMP "VietToolbox_Office_Log.txt"

function Ghi-Log ($Message) {
    $Time = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    "[$Time] $Message" | Out-File -FilePath $Global:LogPath -Append -Encoding UTF8
}

$LogicCaiOfficeV172 = {
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    $fNut = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $fDash = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - OFFICE V172 (BẢN CHUỘC LỖI - FIX LỖI TỰ HỦY)"; $form.Size = "820,860"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false

    $lvOffice = New-Object System.Windows.Forms.ListView; $lvOffice.Size = "760,350"; $lvOffice.Location = "20,20"; $lvOffice.View = "Details"; $lvOffice.CheckBoxes = $true; $lvOffice.FullRowSelect = $true; $lvOffice.Font = $fStd; $lvOffice.GridLines = $true
    [void]$lvOffice.Columns.Add("PHIÊN BẢN OFFICE", 450); [void]$lvOffice.Columns.Add("TRẠNG THÁI", 280); [void]$lvOffice.Columns.Add("ID/LINK", 0)
    
    $lblPath = New-Object System.Windows.Forms.Label; $lblPath.Text = "LƯU TẠI:"; $lblPath.Location = "20,395"; $lblPath.Size = "80,25"; $lblPath.Font = $fNut
    $txtPath = New-Object System.Windows.Forms.TextBox; $txtPath.Location = "100,393"; $txtPath.Size = "510,30"; $txtPath.ReadOnly = $true; $txtPath.Font = $fStd
    $txtPath.Text = if (Test-Path "D:\" ) { "D:\VietToolbox_Office" } else { "C:\VietToolbox_Office" }
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "CHỌN THƯ MỤC"; $btnBrowse.Location = "625,391"; $btnBrowse.Size = "155,35"; $btnBrowse.FlatStyle = "Flat"; $btnBrowse.Font = $fNut
    
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,460"; $lblStatus.Size = "150,20"; $lblStatus.Font = $fStd; $lblStatus.ForeColor = "#1565C0"
    $lblSpeed = New-Object System.Windows.Forms.Label; $lblSpeed.Text = "-- MB/s | -- / -- MB | Còn lại: --:--:--"; $lblSpeed.Location = "180,460"; $lblSpeed.Size = "600,20"; $lblSpeed.TextAlign = "MiddleRight"; $lblSpeed.Font = $fDash; $lblSpeed.ForeColor = "#D84315"
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,490"; $pgBar.Size = "760,30"
    
    $btnPause = New-Object System.Windows.Forms.Button; $btnPause.Text = "TẠM DỪNG"; $btnPause.Size = "240,55"; $btnPause.Location = "20,550"; $btnPause.Enabled = $false; $btnPause.FlatStyle = "Flat"; $btnPause.Font = $fNut
    $btnResume = New-Object System.Windows.Forms.Button; $btnResume.Text = "TIẾP TỤC"; $btnResume.Size = "240,55"; $btnResume.Location = "280,550"; $btnResume.Enabled = $false; $btnResume.FlatStyle = "Flat"; $btnResume.Font = $fNut
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "HỦY LỆNH"; $btnCancel.Size = "240,55"; $btnCancel.Location = "540,550"; $btnCancel.Enabled = $false; $btnCancel.FlatStyle = "Flat"; $btnCancel.Font = $fNut

    $btnLog = New-Object System.Windows.Forms.Button; $btnLog.Text = "XEM NHẬT KÝ"; $btnLog.Size = "240,65"; $btnLog.Location = "20,630"; $btnLog.BackColor = "#607D8B"; $btnLog.ForeColor = "White"; $btnLog.FlatStyle = "Flat"; $btnLog.Font = $fNut
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "LÀM MỚI LIST"; $btnSync.Size = "240,65"; $btnSync.Location = "280,630"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "BẮT ĐẦU CÀI ĐẶT"; $btnInstall.Size = "240,65"; $btnInstall.Location = "540,630"; $btnInstall.BackColor = "#D32F2F"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fNut

    $form.Controls.AddRange(@($lvOffice, $lblPath, $txtPath, $btnBrowse, $lblStatus, $lblSpeed, $pgBar, $btnPause, $btnResume, $btnCancel, $btnLog, $btnSync, $btnInstall))

    function Download-Core ($InputSource, $DestPath) {
        $HttpClient = New-Object System.Net.Http.HttpClient
        $HttpClient.Timeout = [System.TimeSpan]::FromMinutes(30)
        $HttpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        
        $InputSource = $InputSource.Trim()
        $driveId = if ($InputSource -match "id=([a-zA-Z0-9\-_]+)") { $matches[1] } elseif ($InputSource -match "\/d\/([a-zA-Z0-9\-_]+)") { $matches[1] } else { $InputSource }

        $Url = "https://www.googleapis.com/drive/v3/files/$($driveId)?alt=media&key=$($Global:DriveApiKey)&acknowledgeAbuse=true&supportsAllDrives=true"
        
        try {
            $response = $HttpClient.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            if (-not $response.IsSuccessStatusCode) {
                $WebUrl = "https://drive.google.com/uc?export=download&id=$driveId"
                $response = $HttpClient.GetAsync($WebUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                if ($response.IsSuccessStatusCode -and $response.Content.Headers.ContentType.MediaType -match "text/html") {
                    $html = $response.Content.ReadAsStringAsync().Result
                    if ($html -match 'confirm=([a-zA-Z0-9\-_]+)') {
                        $token = $matches[1]
                        $ConfirmUrl = "https://drive.google.com/uc?export=download&id=$driveId&confirm=$token"
                        $response = $HttpClient.GetAsync($ConfirmUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                    }
                }
            }

            if (-not $response.IsSuccessStatusCode) { return "ERROR" }

            $totalBytes = $response.Content.Headers.ContentLength
            $stream = $response.Content.ReadAsStreamAsync().Result
            $fileStream = [System.IO.File]::Create($DestPath)
            
            $buffer = New-Object byte[] 4194304
            
            $totalRead = 0; $readSinceLastUpdate = 0
            $swUpdate = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                if ($script:CancelDL) { 
                    $fileStream.Close(); $stream.Close(); $HttpClient.Dispose()
                    if (Test-Path $DestPath) { Remove-Item $DestPath -Force -ErrorAction SilentlyContinue }
                    return "CANCELLED"
                }
                while ($script:PauseDL) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                
                $fileStream.Write($buffer, 0, $bytesRead)
                $totalRead += $bytesRead; $readSinceLastUpdate += $bytesRead
                
                if ($swUpdate.ElapsedMilliseconds -ge 1000) {
                    $speed = $readSinceLastUpdate / $swUpdate.Elapsed.TotalSeconds
                    $speedMB = [Math]::Round($speed / 1MB, 2)
                    $totalReadMB = [Math]::Round($totalRead / 1MB, 2)
                    $totalBytesMB = if ($totalBytes -gt 0) { [Math]::Round($totalBytes / 1MB, 2) } else { 0 }
                    
                    $etaString = "--:--:--"
                    if ($speed -gt 0 -and $totalBytes -gt 0) {
                        $remainingSecs = ($totalBytes - $totalRead) / $speed
                        $etaTime = [TimeSpan]::FromSeconds($remainingSecs)
                        $etaString = $etaTime.ToString("hh\:mm\:ss")
                    }

                    $pgBar.Value = if ($totalBytes -gt 0) { [int](($totalRead / $totalBytes) * 100) } else { 0 }
                    $lblSpeed.Text = "$speedMB MB/s  |  $totalReadMB / $totalBytesMB MB  |  Còn lại: $etaString"
                    [System.Windows.Forms.Application]::DoEvents()
                    $readSinceLastUpdate = 0; $swUpdate.Restart()
                }
            }
            $fileStream.Close(); $stream.Close(); $HttpClient.Dispose()
            return "SUCCESS"
        } catch { return "ERROR" }
    }

    $btnInstall.Add_Click({
        $items = @($lvOffice.CheckedItems); if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false; $btnCancel.Enabled = $true; $btnPause.Enabled = $true
        Ghi-Log "`n--- BẮT ĐẦU CÀI ĐẶT MỚI (V172) ---"
        
        foreach ($item in $items) {
            $script:CancelDL = $false; $script:PauseDL = $false
            $installSuccess = $false; $skipDownload = $false; $res = ""
            
            # LỌC SẠCH TÊN FILE
            $rawName = $item.SubItems[0].Text -replace '[\\/:*?"<>|()[\]\s]', '_'
            if ($rawName -notmatch "\.(exe|img|iso|zip)$") { $safeName = $rawName + ".iso" } else { $safeName = $rawName }
            
            $destFile = Join-Path $txtPath.Text $safeName
            if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory | Out-Null }
            
            $oldBadFile = Join-Path $txtPath.Text ($item.SubItems[0].Text + ".iso")
            if (Test-Path $oldBadFile) { Rename-Item -Path $oldBadFile -NewName $safeName -Force -ErrorAction SilentlyContinue }

            if (Test-Path $destFile) {
                if ((Get-Item $destFile).Length -gt 5MB) {
                    $item.SubItems[1].Text = "⏭️ Dùng file có sẵn..."
                    $lblStatus.Text = "Bỏ qua tải..."; $pgBar.Value = 100; $lblSpeed.Text = "Đã có sẵn trong máy tính!"
                    [System.Windows.Forms.Application]::DoEvents()
                    $skipDownload = $true; $res = "SUCCESS"
                } else {
                    Remove-Item $destFile -Force -ErrorAction SilentlyContinue
                }
            }

            if (-not $skipDownload) {
                $item.SubItems[1].Text = "⏳ Đang tải..."; $lblStatus.Text = "Đang tải xuống..."; [System.Windows.Forms.Application]::DoEvents()
                $res = Download-Core $item.SubItems[2].Text $destFile
            }
            
            # FIX LỖI ÉP KIỂU BẰNG CHỮ STRING
            if ($res -eq "CANCELLED") {
                $item.SubItems[1].Text = "❌ Đã hủy"; $pgBar.Value = 0; $lblSpeed.Text = "-- MB/s"; $lblStatus.Text = "Đã hủy"; break 
            } elseif ($res -eq "SUCCESS") {
                
                # ==========================================================
                # NHÁNH EXE
                # ==========================================================
                if ($destFile -match "\.exe$") {
                    $item.SubItems[1].Text = "⚙️ Đang chạy file cài đặt..."
                    $lblStatus.Text = "Đang cài đặt..."; $lblSpeed.Text = "Hệ thống đang xử lý..."; [System.Windows.Forms.Application]::DoEvents()
                    try {
                        $psiExe = New-Object System.Diagnostics.ProcessStartInfo
                        $psiExe.FileName = $destFile; $psiExe.WorkingDirectory = $txtPath.Text; $psiExe.Verb = "RunAs"
                        $exeProc = [System.Diagnostics.Process]::Start($psiExe); $exeProc.WaitForExit(); $installSuccess = $true
                    } catch { $item.SubItems[1].Text = "❌ Lỗi không mở được exe" }
                }
                # ==========================================================
                # NHÁNH ISO / IMG / ZIP (CHỈ XÀI 7-ZIP BUNG NÉN - KHÔNG MOUNT)
                # ==========================================================
                elseif ($destFile -match "\.(iso|img|zip)$") {
                    $item.SubItems[1].Text = "📦 Đang bung nén cục ISO..."
                    $lblStatus.Text = "Đang trích xuất đĩa ảo..."
                    $lblSpeed.Text = "Đang dùng 7-Zip xé tung file ISO..."
                    [System.Windows.Forms.Application]::DoEvents()
                    
                    $extractFolder = Join-Path $txtPath.Text ($safeName -replace "\.(iso|img|zip)$", "_Extracted")
                    if (-not (Test-Path $extractFolder)) { New-Item $extractFolder -ItemType Directory -Force | Out-Null }
                    
                    $isExtracted = $false
                    
                    try {
                        # TÌM 7-ZIP
                        $7zExe = "$env:ProgramFiles\7-Zip\7z.exe"
                        if (-not (Test-Path $7zExe)) { $7zExe = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
                        
                        if (Test-Path $7zExe) {
                            Ghi-Log "[EXTRACT] Tìm thấy 7-Zip! Đang ép xả nén ISO: $destFile"
                            $psi = New-Object System.Diagnostics.ProcessStartInfo
                            $psi.FileName = $7zExe
                            $psi.Arguments = "x `"$destFile`" -o`"$extractFolder`" -y"
                            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
                            $process = [System.Diagnostics.Process]::Start($psi)
                            $process.WaitForExit()
                            
                            if ($process.ExitCode -eq 0) { $isExtracted = $true }
                        } else {
                            # TRƯỜNG HỢP MÁY CHƯA CÀI 7-ZIP, DÙNG MOUNT LÀM GIẢI PHÁP DỰ PHÒNG CUỐI CÙNG
                            $item.SubItems[1].Text = "⚠️ Thiếu 7-Zip, thử Mount ảo..."
                            $lblSpeed.Text = "Máy không có 7-Zip, đang mạo hiểm Mount..."
                            [System.Windows.Forms.Application]::DoEvents()
                            
                            $mount = Mount-DiskImage -ImagePath $destFile -PassThru -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 2
                            $letter = ($mount | Get-Volume).DriveLetter
                            
                            if ($letter) {
                                $extractFolder = "$($letter):\"
                                $isExtracted = $true
                            } else {
                                $item.SubItems[1].Text = "❌ Lỗi: Cần cài 7-Zip"
                                [System.Windows.Forms.MessageBox]::Show("Máy này đã bị hỏng tính năng Mount đĩa ảo của Windows. Ông vui lòng cài đặt phần mềm 7-Zip để Tool có thể bung nén file ISO trực tiếp nhé!", "Thông báo Hệ Thống")
                                continue
                            }
                        }
                        
                        # CHẠY SETUP
                        if ($isExtracted) {
                            $item.SubItems[1].Text = "🔍 Đang tìm file setup..."
                            [System.Windows.Forms.Application]::DoEvents()
                            
                            $batPath = Get-ChildItem -Path $extractFolder -Filter "setup.bat" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                            $setupPath = Get-ChildItem -Path $extractFolder -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                            $otpPath = Get-ChildItem -Path $extractFolder -Filter "Office Tool Plus.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                            
                            $lblStatus.Text = "Đang cài đặt Office..."
                            $lblSpeed.Text = "Vui lòng không đóng cửa sổ đen CMD..."
                            [System.Windows.Forms.Application]::DoEvents()

                            if ($batPath) {
                                $item.SubItems[1].Text = "⚙️ Đang chạy setup.bat (Admin)..."
                                $psiBat = New-Object System.Diagnostics.ProcessStartInfo
                                $psiBat.FileName = "cmd.exe"; $psiBat.Arguments = "/c `"$($batPath.FullName)`""
                                $psiBat.WorkingDirectory = $batPath.DirectoryName; $psiBat.Verb = "RunAs"
                                $psiBat.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
                                $batProc = [System.Diagnostics.Process]::Start($psiBat); $batProc.WaitForExit() 
                                $installSuccess = $true
                            } elseif ($otpPath) {
                                $item.SubItems[1].Text = "⚙️ Đang chạy Office Tool Plus..."
                                Start-Process $otpPath.FullName -Wait; $installSuccess = $true
                            } elseif ($setupPath) {
                                $item.SubItems[1].Text = "⚙️ Đang chạy setup.exe..."
                                Start-Process $setupPath.FullName -Wait; $installSuccess = $true
                            } else {
                                $item.SubItems[1].Text = "❌ Lỗi: ISO rỗng"
                            }
                            
                            # Nếu dùng Mount dự phòng thì Unmount
                            if ($extractFolder -match "^[a-zA-Z]:\\$") { Dismount-DiskImage -ImagePath $destFile | Out-Null }
                        }
                    } catch {
                        $item.SubItems[1].Text = "❌ Lỗi hệ thống"
                    }
                }
                
                # DỌN DẸP
                if ($installSuccess) {
                    $item.SubItems[1].Text = "🧹 Đang dọn rác..."; $lblStatus.Text = "Đang dọn dẹp..."; $lblSpeed.Text = "Đang xóa bộ cài tạm..."
                    [System.Windows.Forms.Application]::DoEvents()
                    if (Test-Path $destFile) { Remove-Item $destFile -Force -ErrorAction SilentlyContinue }
                    if ($extractFolder -match "_Extracted$" -and (Test-Path $extractFolder)) { Remove-Item $extractFolder -Recurse -Force -ErrorAction SilentlyContinue }
                    $item.SubItems[1].Text = "✅ Hoàn tất"; $lblStatus.Text = "Xong!"; $lblSpeed.Text = "Quá trình cài đặt thành công!"
                }
            } else { 
                $item.SubItems[1].Text = "❌ Lỗi mạng" 
            }
        }
        $btnInstall.Enabled = $true; $btnCancel.Enabled = $false; $btnPause.Enabled = $false
        $pgBar.Value = 0
    })

    $btnCancel.Add_Click({ $script:CancelDL = $true; $lblStatus.Text = "Đang hủy..."; [System.Windows.Forms.Application]::DoEvents() })
    $btnPause.Add_Click({ $script:PauseDL = $true; $btnPause.Enabled = $false; $btnResume.Enabled = $true; $lblStatus.Text = "Tạm dừng" })
    $btnResume.Add_Click({ $script:PauseDL = $false; $btnResume.Enabled = $false; $btnPause.Enabled = $true; $lblStatus.Text = "Tiếp tục" })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath } })
    $btnLog.Add_Click({ if (Test-Path $Global:LogPath) { Start-Process "notepad.exe" $Global:LogPath } else { [System.Windows.Forms.MessageBox]::Show("Chưa có nhật ký!", "Thông báo") } })
    $btnSync.Add_Click({ try { Invoke-WebRequest -Uri ($rawUrl + "?t=" + (Get-Date -UFormat %s)) -OutFile $localPath -UseBasicParsing; Load-Local-Data; $lblStatus.Text = "Đã làm mới!" } catch {} })

    function Load-Local-Data {
        if (Test-Path $localPath) {
            $lvOffice.Items.Clear(); $csv = Import-Csv -Path $localPath -Encoding UTF8
            foreach ($row in $csv) { if ($row.Name) { $li = New-Object System.Windows.Forms.ListViewItem($row.Name); [void]$li.SubItems.Add("Sẵn sàng"); [void]$li.SubItems.Add($row.ID); $lvOffice.Items.Add($li) } }
        }
    }
    Load-Local-Data
    $form.ShowDialog() | Out-Null
}
&$LogicCaiOfficeV172