# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicVietToolboxClientV375 = {
    # --- CẤU HÌNH NGUỒN DỮ LIỆU ---
    $githubUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
    $localPath = Join-Path $env:TEMP "VietToolbox_Client_List.csv"
    $fontNut   = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontList  = New-Object System.Drawing.Font("Segoe UI", 9)

    # --- KHỞI TẠO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX V37.5 - CÀI ĐẶT TỔNG LỰC"; $form.Size = "950,800"; $form.StartPosition = "CenterScreen"; $form.BackColor = "White"

    # --- 1. CHỌN KÊNH CÀI ĐẶT ---
    $gbChannel = New-Object System.Windows.Forms.GroupBox; $gbChannel.Text = "CHỌN NGUỒN TẢI & CÀI"; $gbChannel.Location = "20,10"; $gbChannel.Size = "890,70"; $gbChannel.Font = $fontList
    $rbWinget = New-Object System.Windows.Forms.RadioButton; $rbWinget.Text = "Winget (Microsoft)"; $rbWinget.Location = "30,25"; $rbWinget.Checked = $true; $rbWinget.Width = 150
    $rbChoco = New-Object System.Windows.Forms.RadioButton; $rbChoco.Text = "Chocolatey (Community)"; $rbChoco.Location = "250,25"; $rbChoco.Width = 180
    $rbDrive = New-Object System.Windows.Forms.RadioButton; $rbDrive.Text = "Google Drive (Kho của ông)"; $rbDrive.Location = "500,25"; $rbDrive.Width = 220
    $gbChannel.Controls.AddRange(@($rbWinget, $rbChoco, $rbDrive))

    # --- 2. BẢNG DANH SÁCH (CẬP NHẬT THEO ADMIN V116) ---
    $lv = New-Object System.Windows.Forms.ListView; $lv.Size = "890,450"; $lv.Location = "20,90"; $lv.View = "Details"; $lv.CheckBoxes = $true; $lv.FullRowSelect = $true; $lv.Font = $fontList
    [void]$lv.Columns.Add("TÊN PHẦN MỀM", 240); [void]$lv.Columns.Add("TRẠNG THÁI", 120); [void]$lv.Columns.Add("WINGET ID", 150); [void]$lv.Columns.Add("CHOCO ID", 150); [void]$lv.Columns.Add("GDRIVE ID", 150)

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Đang đồng bộ dữ liệu..."; $lblStatus.Location = "20,550"; $lblStatus.Size = "890,25"
    
    # --- 3. NÚT BẤM ĐIỀU KHIỂN ---
    $btnCheck = New-Object System.Windows.Forms.Button; $btnCheck.Text = "🔍 QUÉT MÁY"; $btnCheck.Size = "220,60"; $btnCheck.Location = "20,600"; $btnCheck.BackColor = "#607D8B"; $btnCheck.ForeColor = "White"; $btnCheck.Font = $fontNut; $btnCheck.FlatStyle = "Flat"
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "⚡ TIẾN HÀNH CÀI ĐẶT TỰ ĐỘNG"; $btnInstall.Size = "650,60"; $btnInstall.Location = "260,600"; $btnInstall.BackColor = "#D35400"; $btnInstall.ForeColor = "White"; $btnInstall.Font = $fontNut; $btnInstall.FlatStyle = "Flat"

    $form.Controls.AddRange(@($gbChannel, $lv, $lblStatus, $btnCheck, $btnInstall))

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

    # --- HÀM NẠP DATA (FIX LỖI NULL) ---
    function Sync-Data {
        $lv.Items.Clear()
        try {
            (New-Object System.Net.WebClient).DownloadFile($githubUrl + "?t=" + (Get-Date).Ticks, $localPath)
            $csv = Import-Csv $localPath
            foreach ($row in $csv) {
                if ($row.Name) {
                    $li = New-Object System.Windows.Forms.ListViewItem($row.Name)
                    [void]$li.SubItems.Add("Chờ quét...")
                    [void]$li.SubItems.Add($row.WingetID)
                    [void]$li.SubItems.Add($row.ChocoID)
                    [void]$li.SubItems.Add($row.GDriveID)
                    $li.Tag = $row.SilentArgs # Lưu tham số cài ẩn vào Tag
                    $lv.Items.Add($li)
                }
            }
            $lblStatus.Text = "Đã đồng bộ xong danh sách mới nhất!"
        } catch { $lblStatus.Text = "Lỗi đồng bộ! Đang dùng dữ liệu cũ." }
    }

    # --- NÚT QUÉT MÁY ---
    $btnCheck.Add_Click({
        $lblStatus.Text = "Đang kiểm tra hệ thống..."
        foreach ($item in $lv.Items) {
            $name = $item.Text
            $item.SubItems[1].Text = "⏳ Đang soi..."
            $found = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$name*" }
            if ($found) {
                $item.SubItems[1].Text = "✅ Đã có"; $item.Checked = $false; $item.ForeColor = [System.Drawing.Color]::Gray
            } else {
                $item.SubItems[1].Text = "❌ Chưa có"; $item.Checked = $true; $item.ForeColor = [System.Drawing.Color]::Black
            }
        }
        $lblStatus.Text = "Quét xong! Những app thiếu đã được tích sẵn."
    })

    # --- NÚT CÀI ĐẶT ---
    $btnInstall.Add_Click({
        $checked = @($lv.CheckedItems)
        if ($checked.Count -eq 0) { return }
        if ($rbChoco.Checked) { Install-ChocoMoi }

        foreach ($item in $checked) {
            $name = $item.Text
            $item.SubItems[1].Text = "🚀 Đang cài..."
            $lblStatus.Text = "Đang xử lý: $name..."; $form.Refresh()

            try {
                if ($rbWinget.Checked) {
                    $id = $item.SubItems[2].Text
                    if ($id) { Start-Process "winget" -ArgumentList "install --id `"$id`" --accept-package-agreements --force" -Wait -WindowStyle Hidden }
                } 
                elseif ($rbChoco.Checked) {
                    $id = $item.SubItems[3].Text
                    if ($id) { Start-Process "choco" -ArgumentList "install $id -y --accept-license" -Wait -WindowStyle Normal }
                }
                else { # Google Drive
                    $id = $item.SubItems[4].Text
                    $sArgs = $item.Tag
                    if ($id) {
                        $temp = Join-Path $env:TEMP "$name.exe"
                        Download-GDrive -id $id -out $temp
                        Start-Process $temp -ArgumentList $sArgs -Wait
                    }
                }
                $item.SubItems[1].Text = "✅ Xong"; $item.Checked = $false
            } catch { $item.SubItems[1].Text = "❌ Lỗi" }
        }
        $lblStatus.Text = "Hoàn tất cài đặt danh sách đã chọn!"
    })

    # Chạy lần đầu
    Sync-Data; $form.ShowDialog() | Out-Null
}

&$LogicVietToolboxClientV375