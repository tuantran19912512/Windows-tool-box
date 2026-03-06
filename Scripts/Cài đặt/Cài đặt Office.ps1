# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- KIỂM TRA QUYỀN ADMINISTRATOR ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Vui lòng Chuột phải chọn 'Run as Administrator'!", "Yêu cầu quyền Admin")
    return
}

$LogicCaiOfficeClient = {
    # --- CẤU HÌNH LINK CLOUD CỦA TOÀN ---
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"

    # --- FONT UI ---
    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - CÀI ĐẶT OFFICE TỰ ĐỘNG"; $form.Size = "800,700"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lvOffice = New-Object System.Windows.Forms.ListView; $lvOffice.Size = "740,400"; $lvOffice.Location = "20,20"; $lvOffice.View = "Details"; $lvOffice.CheckBoxes = $true; $lvOffice.FullRowSelect = $true; $lvOffice.Font = $fontNoiDung; $lvOffice.BorderStyle = "FixedSingle"
    [void]$lvOffice.Columns.Add("PHIÊN BẢN OFFICE", 450); [void]$lvOffice.Columns.Add("TRẠNG THÁI", 250); [void]$lvOffice.Columns.Add("ID", 0)
    
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,430"; $lblStatus.Size = "500,20"; $lblStatus.Font = $fontNho; $lblStatus.ForeColor = "Gray"
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,455"; $pgBar.Size = "740,20"
    
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "LÀM MỚI DANH SÁCH"; $btnSync.Size = "220,55"; $btnSync.Location = "210,510"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fontNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "BẮT ĐẦU CÀI ĐẶT"; $btnInstall.Size = "330,55"; $btnInstall.Location = "430,510"; $btnInstall.BackColor = "#D32F2F"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fontNut
    $form.Controls.AddRange(@($lvOffice, $lblStatus, $pgBar, $btnSync, $btnInstall))

    # --- HÀM 1: ĐỌC DỮ LIỆU ---
    function Load-Local-Data {
        $lvOffice.Items.Clear()
        if (Test-Path $localPath) {
            $csv = Import-Csv -Path $localPath -Encoding UTF8
            foreach ($row in $csv) {
                if ($row.Name) {
                    $li = New-Object System.Windows.Forms.ListViewItem($row.Name); [void]$li.SubItems.Add("Sẵn sàng"); [void]$li.SubItems.Add($row.ID); $lvOffice.Items.Add($li)
                }
            }
        }
    }

    # --- HÀM 2: ĐỒNG BỘ TỪ GITHUB ---
    function Sync-From-Cloud {
        $lblStatus.Text = "Đang kết nối Cloud..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            # Thêm Cache-Buster để GitHub không trả về file cũ
            $finalLink = $rawUrl + "?t=" + (Get-Date -Format "yyyyMMddHHmmss")
            
            $web = New-Object System.Net.WebClient
            $web.Headers.Add("User-Agent", "Mozilla/5.0")
            $web.DownloadFile($finalLink, $localPath)
            
            Load-Local-Data
            $lblStatus.Text = "Đồng bộ thành công!"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi kết nối link mới: " + $_.Exception.Message)
        }
    }

    # --- HÀM 3: LOGIC CÀI ĐẶT ---
    function Start-Install-Process ($driveId, $officeName) {
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Chọn thư mục lưu bộ cài tạm (Yêu cầu > 4GB)"
        if ($folderBrowser.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $false }
        
        $destFile = Join-Path $folderBrowser.SelectedPath "Office_Setup.img"
        
        try {
            $lblStatus.Text = "Đang tải $officeName từ Google Drive..."; [System.Windows.Forms.Application]::DoEvents()
            $dlUrl = "https://drive.google.com/uc?export=download&id=$driveId"
            (New-Object System.Net.WebClient).DownloadFile($dlUrl, $destFile)

            $lblStatus.Text = "Đang Mount ổ ảo..."; [System.Windows.Forms.Application]::DoEvents()
            $mount = Mount-DiskImage -ImagePath $destFile -PassThru
            $letter = ($mount | Get-Volume).DriveLetter

            $lblStatus.Text = "Đang chạy Setup..."; [System.Windows.Forms.Application]::DoEvents()
            Start-Process -FilePath "$($letter):\setup.exe" -Wait

            $lblStatus.Text = "Đang dọn dẹp..."; [System.Windows.Forms.Application]::DoEvents()
            Dismount-DiskImage -ImagePath $destFile
            if (Test-Path $destFile) { Remove-Item $destFile -Force }
            return $true
        } catch { return $false }
    }

    # --- SỰ KIỆN NÚT BẤM ---
    $btnSync.Add_Click({ Sync-From-Cloud })

    $btnInstall.Add_Click({
        $items = @($lvOffice.CheckedItems)
        if ($items.Count -eq 0) { return }

        $btnInstall.Enabled = $false; $pgBar.Maximum = $items.Count; $pgBar.Value = 0

        foreach ($item in $items) {
            $item.SubItems[1].Text = "⏳ Đang xử lý..."; [System.Windows.Forms.Application]::DoEvents()
            $res = Start-Install-Process $item.SubItems[2].Text $item.Text
            $item.SubItems[1].Text = if ($res) { "✅ Hoàn tất" } else { "⚠️ Lỗi" }
            $pgBar.Value++
        }
        $btnInstall.Enabled = $true; $lblStatus.Text = "Hoàn tất!"
    })

    if (Test-Path $localPath) { Load-Local-Data } else { Sync-From-Cloud }
    $form.ShowDialog() | Out-Null
}

&$LogicCaiOfficeClient