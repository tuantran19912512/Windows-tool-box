# ==========================================================
# ISO CLIENT V135 - FIX LỖI 403 BẰNG ACKNOWLEDGE ABUSE
# ==========================================================
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -AssemblyName System.Net.Http

$B64_Key = "QUl6YVN5QzlDT01WamxfZEU3enhPQ190eEF4RFhLUEotSjdXMjlR"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))

$LogicIsoClientV135 = {
    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    # --- [2] GIAO DIỆN FULL NÚT ---
    $fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 12)
    $fBtn = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 10)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - ISO V135 (BYPASS VIRUS SCAN)"; $form.Size = "880,920"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false

    # Danh sách
    $lv = New-Object System.Windows.Forms.ListView; $lv.Size = "820,350"; $lv.Location = "25,20"; $lv.View = "Details"; $lv.CheckBoxes = $true; $lv.FullRowSelect = $true; $lv.Font = $fStd; $lv.GridLines = $true
    [void]$lv.Columns.Add("TÊN PHIÊN BẢN WINDOWS", 550); [void]$lv.Columns.Add("TRẠNG THÁI", 240); $form.Controls.Add($lv)

    # Khung chọn Thư mục
    $lblPath = New-Object System.Windows.Forms.Label; $lblPath.Text = "LƯU TẠI:"; $lblPath.Location = "25,395"; $lblPath.Size = "80,25"; $lblPath.Font = $fBtn; $form.Controls.Add($lblPath)
    $txtPath = New-Object System.Windows.Forms.TextBox; $txtPath.Location = "110,393"; $txtPath.Size = "580,30"; $txtPath.ReadOnly = $true; $txtPath.Font = $fStd; $form.Controls.Add($txtPath)
    $txtPath.Text = Join-Path (Get-PSDrive -PSProvider FileSystem | Sort Free -Descending | Select -First 1).Root "VietToolbox_ISO"
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "CHỌN THƯ MỤC"; $btnBrowse.Location = "710,391"; $btnBrowse.Size = "135,35"; $btnBrowse.FlatStyle = "Flat"; $btnBrowse.Font = $fBtn; $form.Controls.Add($btnBrowse)

    # Đồng hồ
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "25,460"; $lblStatus.Size = "500,25"; $form.Controls.Add($lblStatus)
    $lblSpeed = New-Object System.Windows.Forms.Label; $lblSpeed.Text = "0 MB/s"; $lblSpeed.Location = "565,460"; $lblSpeed.Size = "280,25"; $lblSpeed.Font = $fBtn; $lblSpeed.TextAlign = "MiddleRight"; $form.Controls.Add($lblSpeed)
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "25,490"; $pgBar.Size = "820,35"; $form.Controls.Add($pgBar)

    # Nút điều khiển
    $btnPause = New-Object System.Windows.Forms.Button; $btnPause.Text = "TẠM DỪNG"; $btnPause.Size = "260,55"; $btnPause.Location = "25,560"; $btnPause.Enabled = $false; $btnPause.FlatStyle = "Flat"; $btnPause.Font = $fBtn; $form.Controls.Add($btnPause)
    $btnResume = New-Object System.Windows.Forms.Button; $btnResume.Text = "TIẾP TỤC"; $btnResume.Size = "260,55"; $btnResume.Location = "305,560"; $btnResume.Enabled = $false; $btnResume.FlatStyle = "Flat"; $btnResume.Font = $fBtn; $form.Controls.Add($btnResume)
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "HỦY LỆNH"; $btnCancel.Size = "260,55"; $btnCancel.Location = "585,560"; $btnCancel.Enabled = $false; $btnCancel.FlatStyle = "Flat"; $btnCancel.Font = $fBtn; $form.Controls.Add($btnCancel)
    
    $btnDownload = New-Object System.Windows.Forms.Button; $btnDownload.Text = "BẮT ĐẦU TẢI (FAST API)"; $btnDownload.Size = "820,75"; $btnDownload.Location = "25,660"; $btnDownload.BackColor = "#007ACC"; $btnDownload.ForeColor = "White"; $btnDownload.Font = $fTitle; $form.Controls.Add($btnDownload)

    # --- [3] LOGIC TẢI ---
    # --- [3] LOGIC TẢI ---
    $btnDownload.Add_Click({
        $items = @($lv.CheckedItems); if ($items.Count -eq 0) { return }
        if ([string]::IsNullOrWhiteSpace($Global:DriveApiKey) -or $Global:DriveApiKey -match "DÁN_API") {
            [System.Windows.Forms.MessageBox]::Show("Chưa dán API Key ở đầu Script!"); return
        }

        $btnDownload.Enabled = $false; $btnCancel.Enabled = $true; $btnPause.Enabled = $true
        $script:CancelDL = $false; $script:PauseDL = $false
        
        $HttpClient = New-Object System.Net.Http.HttpClient
        
        foreach ($item in $items) {
            $dest = Join-Path $txtPath.Text ($item.Text.Replace(" ", "_") + ".iso")
            if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory | Out-Null }
            
            $url = "https://www.googleapis.com/drive/v3/files/$($item.Tag)?alt=media&key=$($Global:DriveApiKey)&acknowledgeAbuse=true"
            $item.SubItems[1].Text = "⏳ Đang kết nối..."; [System.Windows.Forms.Application]::DoEvents()

            try {
                $response = $HttpClient.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                
                if (-not $response.IsSuccessStatusCode) {
                    $errorMsg = $response.Content.ReadAsStringAsync().Result
                    $item.SubItems[1].Text = "❌ Lỗi: $($response.StatusCode)"
                    [System.Windows.Forms.MessageBox]::Show("API báo lỗi: $($response.StatusCode)`n`nChi tiết: $errorMsg", "Lỗi mạng")
                    continue
                }

                $totalBytes = $response.Content.Headers.ContentLength
                $stream = $response.Content.ReadAsStreamAsync().Result
                $fileStream = [System.IO.File]::Create($dest)
                $buffer = New-Object byte[] 102400
                
                # SỬA LỖI LOGIC: Tách riêng biến tổng ($totalRead) và biến nhịp tốc độ ($chunkRead)
                $totalRead = 0; $chunkRead = 0; $sw = [System.Diagnostics.Stopwatch]::StartNew()

                while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    if ($script:CancelDL) { break } # Thoát vòng lặp tải nếu bấm Hủy
                    while ($script:PauseDL) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                    if (-not $sw.IsRunning) { $sw.Start() }

                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalRead += $bytesRead
                    $chunkRead += $bytesRead

                    if ($sw.ElapsedMilliseconds -ge 800) {
                        $pgBar.Value = [math]::Min(100, [int](($totalRead / $totalBytes) * 100))
                        $lblSpeed.Text = "$([Math]::Round(($chunkRead / $sw.Elapsed.TotalSeconds) / 1MB, 2)) MB/s"
                        $lblStatus.Text = "Đang tải: $([Math]::Round($totalRead/1GB, 2)) / $([Math]::Round($totalBytes/1GB, 2)) GB"
                        $sw.Restart(); $chunkRead = 0; [System.Windows.Forms.Application]::DoEvents()
                    }
                }
                
                # --- XỬ LÝ ĐÓNG LUỒNG MẠNG VÀ TỆP TIN TRƯỚC KHI XÓA ---
                $fileStream.Close(); $fileStream.Dispose()
                $stream.Close(); $stream.Dispose()
                
                if ($script:CancelDL) { 
                    $item.SubItems[1].Text = "❌ Đã hủy"
                    # Xóa file (ép buộc)
                    if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
                    
                    # --- RESET GIAO DIỆN ---
                    $pgBar.Value = 0
                    $lblSpeed.Text = "0 MB/s"
                    $lblStatus.Text = "Đã hủy lệnh. Xóa tệp rác thành công!"
                    
                    break # Lệnh này rất quan trọng: Thoát luôn vòng lặp foreach, không tải tiếp file sau nữa
                } else { 
                    $item.SubItems[1].Text = "✅ Xong"
                    $lblStatus.Text = "Hoàn tất tải file!" 
                }
                
            } catch { 
                $item.SubItems[1].Text = "❌ Lỗi mạng"
                $lblStatus.Text = "Lỗi kết nối!" 
            }
        }
        
        # Reset tổng thể khi xong (hoặc hủy)
        $HttpClient.Dispose()
        $btnDownload.Enabled = $true; $btnCancel.Enabled = $false
        $btnPause.Enabled = $false; $btnResume.Enabled = $false
        $pgBar.Value = 0; $lblSpeed.Text = "0 MB/s"
    })

    # Sự kiện nút (Giữ nguyên)
    $btnPause.Add_Click({ $script:PauseDL = $true; $btnPause.Enabled = $false; $btnResume.Enabled = $true; $lblStatus.Text = "Đã tạm dừng..." })
    $btnResume.Add_Click({ $script:PauseDL = $false; $btnResume.Enabled = $false; $btnPause.Enabled = $true; $lblStatus.Text = "Tiếp tục tải..." })
    $btnCancel.Add_Click({ $script:CancelDL = $true; $lblStatus.Text = "Đang hủy lệnh..." })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath } })

    try {
        $csv = Invoke-WebRequest -Uri $RawUrl -UseBasicParsing | ConvertFrom-Csv
        foreach ($r in $csv) {
            $li = New-Object System.Windows.Forms.ListViewItem($r.Name); $li.Tag = $r.FileID; [void]$li.SubItems.Add("Sẵn sàng"); $lv.Items.Add($li)
        }
    } catch {}

    $form.ShowDialog() | Out-Null
}
&$LogicIsoClientV135