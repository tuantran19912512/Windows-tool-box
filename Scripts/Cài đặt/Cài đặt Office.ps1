# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- KIỂM TRA QUYỀN ADMINISTRATOR ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Toàn ơi, hãy chạy bằng quyền Administrator để Mount ổ ảo nhé!", "Yêu cầu quyền Admin")
    return
}

$LogicCaiOfficeIMG = {
    # --- CẤU HÌNH ID FILE GOOGLE DRIVE ---
    $driveId = "1FvJOK41gP3Ic16I6xiv6L_R1CDcwgjZM" # Thay bằng ID file .img của ông
    
    # --- ĐỊNH NGHĨA FONT UI ---
    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    # --- GIAO DIỆN CHÍNH ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - CÀI ĐẶT OFFICE (IMG)"; $form.Size = "500,350"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lblTitle = New-Object System.Windows.Forms.Label; $lblTitle.Text = "CÀI ĐẶT OFFICE HOME 2024 RETAIL"; $lblTitle.Location = "20,30"; $lblTitle.Size = "450,30"; $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 12); $lblTitle.ForeColor = "#D32F2F"
    
    $lblDesc = New-Object System.Windows.Forms.Label; $lblDesc.Text = "Hệ thống sẽ cho phép bạn chọn vị trí lưu bộ cài, sau đó tự động tải, Mount ổ ảo và cài đặt."; $lblDesc.Location = "20,70"; $lblDesc.Size = "450,50"; $lblDesc.Font = $fontNoiDung
    
    $btnAction = New-Object System.Windows.Forms.Button; $btnAction.Text = "CHỌN NƠI LƯU & CÀI ĐẶT"; $btnAction.Location = "125,140"; $btnAction.Size = "250,60"; $btnAction.BackColor = "#1976D2"; $btnAction.ForeColor = "White"; $btnAction.FlatStyle = "Flat"; $btnAction.Font = $fontNut
    
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Trạng thái: Sẵn sàng..."; $lblStatus.Location = "20,240"; $lblStatus.Size = "450,20"; $lblStatus.Font = $fontNho; $lblStatus.ForeColor = "Gray"
    
    $form.Controls.AddRange(@($lblTitle, $lblDesc, $btnAction, $lblStatus))

    # --- XỬ LÝ KHI BẤM NÚT ---
    $btnAction.Add_Click({
        # 1. Chọn thư mục lưu
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Chọn thư mục để tải bộ cài Office (Yêu cầu trống > 4GB)"
        
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selectedPath = $folderBrowser.SelectedPath
            $finalImgPath = Join-Path $selectedPath "Office_Setup_VietToolbox.img"
            
            $btnAction.Enabled = $false
            $lblStatus.Text = "Đang kết nối tới Google Drive..."
            [System.Windows.Forms.Application]::DoEvents()

            try {
                # 2. Xử lý tải file lớn từ Google Drive
                $downloadUrl = "https://drive.google.com/uc?export=download&id=$driveId"
                $lblStatus.Text = "Đang tải file (4GB) về: $selectedPath..."
                [System.Windows.Forms.Application]::DoEvents()

                # Dùng WebClient để tải file
                $web = New-Object System.Net.WebClient
                $web.Headers.Add("User-Agent", "Mozilla/5.0")
                $web.DownloadFile($downloadUrl, $finalImgPath)

                # 3. Mount ổ ảo
                $lblStatus.Text = "Đang Mount bộ cài thành ổ đĩa ảo..."
                [System.Windows.Forms.Application]::DoEvents()
                $mountResult = Mount-DiskImage -ImagePath $finalImgPath -PassThru
                $driveLetter = ($mountResult | Get-Volume).DriveLetter

                # 4. Chạy Setup
                $lblStatus.Text = "Đang khởi chạy bộ cài Office..."
                $setupExe = "$($driveLetter):\setup.exe"
                if (Test-Path $setupExe) {
                    $p = Start-Process -FilePath $setupExe -Wait -PassThru
                    [System.Windows.Forms.MessageBox]::Show("Quá trình cài đặt đã hoàn tất!", "VietToolbox")
                } else {
                    throw "Không tìm thấy file setup.exe trong ổ đĩa ảo!"
                }

                # 5. Dọn dẹp sạch sẽ
                $lblStatus.Text = "Đang dọn dẹp hệ thống..."
                Dismount-DiskImage -ImagePath $finalImgPath
                if (Test-Path $finalImgPath) { Remove-Item $finalImgPath -Force }
                
                $lblStatus.Text = "Hoàn tất! Hệ thống đã được dọn sạch."
                [System.Windows.Forms.MessageBox]::Show("Đã xóa bộ cài tạm và nhả ổ ảo thành công.", "Dọn dẹp xong")

            } catch {
                [System.Windows.Forms.MessageBox]::Show("Lỗi: " + $_.Exception.Message)
                $lblStatus.Text = "Lỗi cài đặt."
            }
            $btnAction.Enabled = $true
        }
    })

    $form.ShowDialog() | Out-Null
}

&$LogicCaiOfficeIMG