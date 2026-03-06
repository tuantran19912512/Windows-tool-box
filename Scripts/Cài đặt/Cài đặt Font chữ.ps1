# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- KIỂM TRA QUYỀN ADMINISTRATOR ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show("Vui lòng Chuột phải chọn 'Run as Administrator' để cài Font!", "Thông báo")
    return
}

$LogicSieuThiFont = {
    # --- CẤU HÌNH ID GOOGLE DRIVE ---
    $ID_CO_BAN    = "1FvJOK41gP3Ic16I6xiv6L_R1CDcwgjZM" 
    $ID_TIEU_HOC  = "17h7c2jKVY3HPW8Qhe0Azz1uFgd4yIYcI"   # Thay ID của ông vào đây
    $ID_THIET_KE  = "16oSUuUnIstzf4-ibBtrDT-dN3dOiZ_iq"   # Thay ID của ông vào đây

    # --- ĐỊNH NGHĨA FONT & MÀU SẮC ---
    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontTieuDe  = New-Object System.Drawing.Font("Segoe UI Semibold", 14)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    # --- KHỞI TẠO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - KHO FONT CHỮ CLOUD"; $form.Size = "500,550"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lblHeader = New-Object System.Windows.Forms.Label; $lblHeader.Text = "CHỌN BỘ FONT CẦN CÀI ĐẶT"; $lblHeader.Location = "0,30"; $lblHeader.Size = "500,30"; $lblHeader.TextAlign = "MiddleCenter"; $lblHeader.Font = $fontTieuDe; $lblHeader.ForeColor = "#0D47A1"
    
    # Nút Font Cơ Bản
    $btnCoBan = New-Object System.Windows.Forms.Button; $btnCoBan.Text = "FONT CƠ BẢN (VNI, UTM...)"; $btnCoBan.Location = "75,100"; $btnCoBan.Size = "350,60"; $btnCoBan.BackColor = "#2196F3"; $btnCoBan.ForeColor = "White"; $btnCoBan.FlatStyle = "Flat"; $btnCoBan.Font = $fontNut
    
    # Nút Font Tiểu Học
    $btnTieuHoc = New-Object System.Windows.Forms.Button; $btnTieuHoc.Text = "FONT TIỂU HỌC (TẬP VIẾT)"; $btnTieuHoc.Location = "75,180"; $btnTieuHoc.Size = "350,60"; $btnTieuHoc.BackColor = "#4CAF50"; $btnTieuHoc.ForeColor = "White"; $btnTieuHoc.FlatStyle = "Flat"; $btnTieuHoc.Font = $fontNut
    
    # Nút Font Thiết Kế
    $btnThietKe = New-Object System.Windows.Forms.Button; $btnThietKe.Text = "FONT THIẾT KẾ (VIỆT HÓA)"; $btnThietKe.Location = "75,260"; $btnThietKe.Size = "350,60"; $btnThietKe.BackColor = "#FF9800"; $btnThietKe.ForeColor = "White"; $btnThietKe.FlatStyle = "Flat"; $btnThietKe.Font = $fontNut

    # Trạng thái và Progress
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Trạng thái: Sẵn sàng..."; $lblStatus.Location = "20,360"; $lblStatus.Size = "450,20"; $lblStatus.Font = $fontNho; $lblStatus.ForeColor = "Gray"
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,385"; $pgBar.Size = "445,15"
    
    $form.Controls.AddRange(@($lblHeader, $btnCoBan, $btnTieuHoc, $btnThietKe, $lblStatus, $pgBar))

    # --- HÀM XỬ LÝ CÀI ĐẶT ---
    function Start-FontInstall ($driveId, $categoryName) {
        if ($driveId -match "ID_CUA_BO") { 
            [System.Windows.Forms.MessageBox]::Show("Toàn ơi, ông chưa nhập ID Google Drive cho bộ $categoryName!"); return 
        }

        $btnCoBan.Enabled = $false; $btnTieuHoc.Enabled = $false; $btnThietKe.Enabled = $false
        $tempZip = Join-Path $env:TEMP "vt_fonts_download.zip"; $extractPath = Join-Path $env:TEMP "vt_extract_fonts"

        try {
            $lblStatus.Text = "Đang tải $categoryName từ Google Drive..."; [System.Windows.Forms.Application]::DoEvents()
            $url = "https://drive.google.com/uc?export=download&id=$driveId"
            
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
            $webClient.DownloadFile($url, $tempZip)
            
            $lblStatus.Text = "Đang giải nén bộ $categoryName..."; [System.Windows.Forms.Application]::DoEvents()
            if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
            Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
            
            $fontFiles = Get-ChildItem -Path $extractPath -Recurse -Include *.ttf, *.otf
            if ($fontFiles.Count -eq 0) { throw "Không tìm thấy file .ttf hoặc .otf trong file Zip!" }
            
            $pgBar.Maximum = $fontFiles.Count; $pgBar.Value = 0
            
            foreach ($file in $fontFiles) {
                $lblStatus.Text = "Đang cài đặt: $($file.Name)..."; [System.Windows.Forms.Application]::DoEvents()
                
                # Copy vào thư mục Font Windows
                $targetPath = Join-Path $env:windir "Fonts\$($file.Name)"
                Copy-Item $file.FullName $targetPath -Force
                
                # Đăng ký Registry
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                $type = if ($file.Extension -eq ".otf") { "(OpenType)" } else { "(TrueType)" }
                New-ItemProperty -Path $regPath -Name "$($file.BaseName) $type" -Value $file.Name -PropertyType String -Force | Out-Null
                
                $pgBar.Value++
            }

            # Dọn dẹp
            if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
            if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
            
            [System.Windows.Forms.MessageBox]::Show("Tuyệt vời! Đã cài xong bộ $categoryName.", "VietToolbox")
            $lblStatus.Text = "Hoàn tất cài đặt bộ $categoryName."
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi: " + $_.Exception.Message)
            $lblStatus.Text = "Lỗi trong quá trình cài đặt."
        }
        $btnCoBan.Enabled = $true; $btnTieuHoc.Enabled = $true; $btnThietKe.Enabled = $true; $pgBar.Value = 0
    }

    # --- SỰ KIỆN NÚT BẤM ---
    $btnCoBan.Add_Click({ Start-FontInstall $ID_CO_BAN "Font Cơ Bản" })
    $btnTieuHoc.Add_Click({ Start-FontInstall $ID_TIEU_HOC "Font Tiểu Học" })
    $btnThietKe.Add_Click({ Start-FontInstall $ID_THIET_KE "Font Thiết Kế" })

    $form.ShowDialog() | Out-Null
}

&$LogicSieuThiFont