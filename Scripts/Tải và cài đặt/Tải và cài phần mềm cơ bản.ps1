# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicVietToolboxClientV376 = {
    # Biến cờ hiệu để bắt tín hiệu Dừng
    $script:HuyCaiDat = $false

    # --- CẤU HÌNH NGUỒN DỮ LIỆU ---
    $githubUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
    $localPath = Join-Path $env:TEMP "VietToolbox_Client_List.csv"
    $fontNut   = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontList  = New-Object System.Drawing.Font("Segoe UI", 9)

    # --- KHỞI TẠO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX V37.6 - CÀI ĐẶT TỔNG LỰC (CÓ PHANH KHẨN CẤP)"; $form.Size = "950,800"; $form.StartPosition = "CenterScreen"; $form.BackColor = "White"

    # --- 1. CHỌN KÊNH CÀI ĐẶT ---
    $gbChannel = New-Object System.Windows.Forms.GroupBox; $gbChannel.Text = "CHỌN NGUỒN TẢI & CÀI"; $gbChannel.Location = "20,10"; $gbChannel.Size = "890,70"; $gbChannel.Font = $fontList
    $rbWinget = New-Object System.Windows.Forms.RadioButton; $rbWinget.Text = "Winget (Microsoft)"; $rbWinget.Location = "30,25"; $rbWinget.Checked = $true; $rbWinget.Width = 150
    $rbChoco = New-Object System.Windows.Forms.RadioButton; $rbChoco.Text = "Chocolatey (Community)"; $rbChoco.Location = "250,25"; $rbChoco.Width = 180
    $rbDrive = New-Object System.Windows.Forms.RadioButton; $rbDrive.Text = "Google Drive (Kho của ông)"; $rbDrive.Location = "500,25"; $rbDrive.Width = 220
    $gbChannel.Controls.AddRange(@($rbWinget, $rbChoco, $rbDrive))

    # --- 2. BẢNG DANH SÁCH ---
    $lv = New-Object System.Windows.Forms.ListView; $lv.Size = "890,450"; $lv.Location = "20,90"; $lv.View = "Details"; $lv.CheckBoxes = $true; $lv.FullRowSelect = $true; $lv.Font = $fontList
    [void]$lv.Columns.Add("TÊN PHẦN MỀM", 240); [void]$lv.Columns.Add("TRẠNG THÁI", 120); [void]$lv.Columns.Add("WINGET ID", 150); [void]$lv.Columns.Add("CHOCO ID", 150); [void]$lv.Columns.Add("GDRIVE ID", 150)

    # --- 3. THANH TRẠNG THÁI & PROGRESS BAR ---
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Đang chuẩn bị..."; $lblStatus.Location = "20,550"; $lblStatus.Size = "890,20"; $lblStatus.Font = $fontList
    $pbStatus = New-Object System.Windows.Forms.ProgressBar; $pbStatus.Location = "20,575"; $pbStatus.Size = "890,15"; $pbStatus.Style = "Continuous"

    # --- 4. NÚT BẤM ĐIỀU KHIỂN ---
    $btnCheck = New-Object System.Windows.Forms.Button; $btnCheck.Text = "🔍 QUÉT MÁY"; $btnCheck.Size = "220,60"; $btnCheck.Location = "20,600"; $btnCheck.BackColor = "#607D8B"; $btnCheck.ForeColor = "White"; $btnCheck.Font = $fontNut; $btnCheck.FlatStyle = "Flat"
    
    # Cắt ngắn nút Cài Đặt để nhét nút Dừng
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "⚡ TIẾN HÀNH CÀI ĐẶT"; $btnInstall.Size = "450,60"; $btnInstall.Location = "260,600"; $btnInstall.BackColor = "#D35400"; $btnInstall.ForeColor = "White"; $btnInstall.Font = $fontNut; $btnInstall.FlatStyle = "Flat"
    
    # [MỚI] NÚT DỪNG CÀI ĐẶT
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "🛑 DỪNG LẠI"; $btnCancel.Size = "180,60"; $btnCancel.Location = "730,600"; $btnCancel.BackColor = "#E74C3C"; $btnCancel.ForeColor = "White"; $btnCancel.Font = $fontNut; $btnCancel.FlatStyle = "Flat"; $btnCancel.Enabled = $false

    $form.Controls.AddRange(@($gbChannel, $lv, $lblStatus, $pbStatus, $btnCheck, $btnInstall, $btnCancel))

    # --- HÀM TẢI GDRIVE ---
    function Download-GDrive($id, $out) {
        $url = "https://docs.google.com/uc?export=download&id=$id"
        $wc = New-Object System.Net.WebClient
        $resp = $wc.DownloadString($url)
        if ($resp -match 'confirm=([0-9A-Za-z_]+)') { $url += "&confirm=$($matches[1])" }
        $wc.DownloadFile($url, $out)
    }

    # --- HÀM CÀI MỒI CHOCO ---
    function Install-ChocoMoi {
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            $lblStatus.Text = "Đang cài mồi Chocolatey..."; $form.Refresh()
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
    }

    # --- HÀM CHỜ TIẾN TRÌNH THÔNG MINH (CHỐNG ĐƠ GUI) ---
    function Wait-ProcessSmart($process) {
        while ($process -and -not $process.HasExited) {
            [System.Windows.Forms.Application]::DoEvents() # Bơm oxy cho giao diện
            Start-Sleep -Milliseconds 200
        }
    }

    # --- NẠP DATA & QUÉT MÁY (Giữ nguyên như bản 37.5) ---
    function Sync-Data {
        $lv.Items.Clear()
        try {
            (New-Object System.Net.WebClient).DownloadFile($githubUrl + "?t=" + (Get-Date).Ticks, $localPath)
            $csv = Import-Csv $localPath
            foreach ($row in $csv) {
                if ($row.Name) {
                    $li = New-Object System.Windows.Forms.ListViewItem($row.Name)
                    [void]$li.SubItems.Add("Chờ quét..."); [void]$li.SubItems.Add($row.WingetID); [void]$li.SubItems.Add($row.ChocoID); [void]$li.SubItems.Add($row.GDriveID)
                    $li.Tag = $row.SilentArgs
                    $lv.Items.Add($li)
                }
            }
            $lblStatus.Text = "Đã đồng bộ danh sách! Vui lòng bấm Quét Máy."
        } catch { $lblStatus.Text = "Lỗi đồng bộ! Đang dùng dữ liệu cũ." }
    }

    # --- NÚT QUÉT MÁY (BẢN V37.7 - HYBRID QUÉT CỰC CHUẨN) ---
    $btnCheck.Add_Click({
        $btnCheck.Enabled = $false; $btnInstall.Enabled = $false
        $lblStatus.Text = "Đang gom dữ liệu Registry hệ thống (1 lần duy nhất)..."; $form.Refresh()

        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        $installedApps = Get-ItemProperty $regPaths -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName -ErrorAction SilentlyContinue | Where-Object { $_ -ne $null -and $_.Trim() -ne "" }
        
        $totalItems = $lv.Items.Count
        $pbStatus.Maximum = $totalItems
        $pbStatus.Value = 0
        $i = 0

        foreach ($item in $lv.Items) {
            $i++
            $pbStatus.Value = $i
            $percent = [math]::Round(($i / $totalItems) * 100)
            
            $name = $item.Text
            $lblStatus.Text = "Đang quét [$i/$totalItems] ($percent%) - Tìm: $name"
            $item.SubItems[1].Text = "⏳ Đang soi..."
            $form.Refresh() 

            # --- CƠ CHẾ QUÉT HYBRID (THÔNG MINH & LINH HOẠT) ---
            $found = $false
            # Cắt bỏ đuôi '...' nếu lỡ copy dính từ danh sách Winget
            $nameClean = $name -replace "\.\.\.$", "" 
            $nameClean = $nameClean.Trim()
            
            # [MẸO IT] Đặc cách riêng cho ông nội Visual C++ vì tên Winget và Windows luôn chỏi nhau
            if ($nameClean -match "Visual C\+\+") {
                $pattern = "(?i)Microsoft Visual C\+\+" 
            }
            # Nếu tên ngắn (<= 4 ký tự, ví dụ: Git, OBS) -> Quét khắt khe để chống nhận vơ
            elseif ($nameClean.Length -le 4) {
                $escapedName = [regex]::Escape($nameClean)
                $pattern = "(?i)(^|\W)$escapedName(\W|$)"
            } 
            # Tên dài -> Quét lỏng (Loose Match) để dễ bắt dính hơn
            else {
                $escapedName = [regex]::Escape($nameClean)
                $pattern = "(?i)$escapedName"
            }

            foreach ($appName in $installedApps) {
                if ($appName -match $pattern) {
                    $found = $true; break
                }
            }

            if ($found) {
                $item.SubItems[1].Text = "✅ Đã có"; $item.Checked = $false; $item.ForeColor = [System.Drawing.Color]::Gray
            } else {
                $item.SubItems[1].Text = "❌ Chưa có"; $item.Checked = $true; $item.ForeColor = [System.Drawing.Color]::Black
            }
        }
        $lblStatus.Text = "Quét xong 100%! Đã tự động chọn các phần mềm còn thiếu."
        $pbStatus.Value = $totalItems
        $btnCheck.Enabled = $true; $btnInstall.Enabled = $true
    })

    # --- SỰ KIỆN BẤM NÚT DỪNG ---
    $btnCancel.Add_Click({
        $script:HuyCaiDat = $true
        $lblStatus.Text = "Đã nhận lệnh DỪNG! Đang đợi hoàn tất app hiện tại..."
        $btnCancel.Text = "⏳ ĐANG DỪNG..."
        $btnCancel.Enabled = $false
    })

    # --- NÚT CÀI ĐẶT (CÓ TÍNH NĂNG DỪNG) ---
    $btnInstall.Add_Click({
        $checked = @($lv.CheckedItems)
        $totalChecked = $checked.Count
        if ($totalChecked -eq 0) { return }
        
        # Reset trạng thái
        $script:HuyCaiDat = $false
        $btnCheck.Enabled = $false; $btnInstall.Enabled = $false; $btnCancel.Enabled = $true
        $btnCancel.Text = "🛑 DỪNG LẠI"
        
        if ($rbChoco.Checked) { Install-ChocoMoi }

        $pbStatus.Maximum = $totalChecked; $pbStatus.Value = 0; $i = 0

        foreach ($item in $checked) {
            # KIỂM TRA XEM CÓ LỆNH DỪNG KHÔNG
            if ($script:HuyCaiDat) {
                $item.SubItems[1].Text = "⏹️ Đã hủy"
                continue # Bỏ qua không cài app này nữa
            }

            $i++; $pbStatus.Value = $i; $percent = [math]::Round(($i / $totalChecked) * 100)
            $name = $item.Text; $item.SubItems[1].Text = "🚀 Đang cài..."; $lblStatus.Text = "Đang cài đặt [$i/$totalChecked] ($percent%) - App: $name"; $form.Refresh()

            try {
                $proc = $null
                if ($rbWinget.Checked) {
                    $id = $item.SubItems[2].Text
                    if ($id) { $proc = Start-Process "winget" -ArgumentList "install --id `"$id`" --accept-package-agreements --force" -PassThru -WindowStyle Hidden }
                } 
                elseif ($rbChoco.Checked) {
                    $id = $item.SubItems[3].Text
                    if ($id) { $proc = Start-Process "choco" -ArgumentList "install $id -y --accept-license" -PassThru -WindowStyle Normal }
                }
                else { # Google Drive
                    $id = $item.SubItems[4].Text; $sArgs = $item.Tag
                    if ($id) {
                        $temp = Join-Path $env:TEMP "$name.exe"
                        Download-GDrive -id $id -out $temp
                        $proc = Start-Process $temp -ArgumentList $sArgs -PassThru
                    }
                }

                # Đợi cài đặt nhưng không làm đơ giao diện
                if ($proc) { Wait-ProcessSmart $proc }

                if (-not $script:HuyCaiDat) {
                    $item.SubItems[1].Text = "✅ Xong"; $item.Checked = $false
                }
            } catch { $item.SubItems[1].Text = "❌ Lỗi" }
        }

        # Xử lý thông báo sau khi xong (Hoặc bị hủy)
        if ($script:HuyCaiDat) {
            $lblStatus.Text = "Đã hủy cài đặt giữa chừng!"
            [System.Windows.Forms.MessageBox]::Show("Đã dừng quá trình cài đặt theo yêu cầu của ông!", "VietToolbox", 0, 48)
        } else {
            $lblStatus.Text = "Hoàn tất cài đặt toàn bộ $totalChecked phần mềm thành công!"
            [System.Windows.Forms.MessageBox]::Show("Xong việc rồi sếp! Đã cài đủ $totalChecked app.", "VietToolbox", 0, 64)
        }

        # Trả lại nút
        $pbStatus.Value = $totalChecked
        $btnCheck.Enabled = $true; $btnInstall.Enabled = $true; $btnCancel.Enabled = $false
        $btnCancel.Text = "🛑 DỪNG LẠI"
    })

    # Chạy lần đầu
    Sync-Data; $form.ShowDialog() | Out-Null
}

&$LogicVietToolboxClientV376