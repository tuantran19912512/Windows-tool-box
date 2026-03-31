# ==============================================================================
# CONG CU CAI DAT WINDOWS TU DONG TREN NEN WINRE (1-CLICK WIM INSTALLER)
# Tinh nang: Chuan doan WinRE, Chong ket dia ao DISM, Giao dien Dark Mode
# ==============================================================================

# Yeu cau chay bang quyen Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Thiet lap giao dien chinh (Form)
$CuaSo = New-Object System.Windows.Forms.Form
$CuaSo.Text = "Cong Cu Phuc Hoi He Thong 1-Click"
$CuaSo.Size = New-Object System.Drawing.Size(550, 420)
$CuaSo.StartPosition = "CenterScreen"
$CuaSo.FormBorderStyle = "FixedDialog"
$CuaSo.BackColor = "#1e1e1e"
$CuaSo.ForeColor = "White"

# 2. Cac thanh phan giao dien (Controls)
$fontTieuDe = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontThuong = New-Object System.Drawing.Font("Segoe UI", 10)

$NhanTieuDe = New-Object System.Windows.Forms.Label
$NhanTieuDe.Text = "CAI DAT WINDOWS TU DONG"
$NhanTieuDe.Font = $fontTieuDe
$NhanTieuDe.ForeColor = "#00adb5"
$NhanTieuDe.AutoSize = $true
$NhanTieuDe.Location = New-Object System.Drawing.Point(20, 20)
$CuaSo.Controls.Add($NhanTieuDe)

$NhanWim = New-Object System.Windows.Forms.Label
$NhanWim.Text = "Duong dan tep .wim (Khong de tren o C):"
$NhanWim.Font = $fontThuong
$NhanWim.AutoSize = $true
$NhanWim.Location = New-Object System.Drawing.Point(20, 70)
$CuaSo.Controls.Add($NhanWim)

$OChonWim = New-Object System.Windows.Forms.TextBox
$OChonWim.Size = New-Object System.Drawing.Size(390, 25)
$OChonWim.Location = New-Object System.Drawing.Point(20, 95)
$OChonWim.Font = $fontThuong
$OChonWim.ReadOnly = $true
$CuaSo.Controls.Add($OChonWim)

$NutDuyet = New-Object System.Windows.Forms.Button
$NutDuyet.Text = "Duyet..."
$NutDuyet.Size = New-Object System.Drawing.Size(90, 27)
$NutDuyet.Location = New-Object System.Drawing.Point(420, 94)
$NutDuyet.BackColor = "#3a3a3a"
$NutDuyet.FlatStyle = "Flat"
$CuaSo.Controls.Add($NutDuyet)

$NhanIndex = New-Object System.Windows.Forms.Label
$NhanIndex.Text = "Chon phien ban Windows muon cai:"
$NhanIndex.Font = $fontThuong
$NhanIndex.AutoSize = $true
$NhanIndex.Location = New-Object System.Drawing.Point(20, 135)
$CuaSo.Controls.Add($NhanIndex)

$DanhSachIndex = New-Object System.Windows.Forms.ComboBox
$DanhSachIndex.Size = New-Object System.Drawing.Size(490, 25)
$DanhSachIndex.Location = New-Object System.Drawing.Point(20, 160)
$DanhSachIndex.Font = $fontThuong
$DanhSachIndex.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$DanhSachIndex.BackColor = "#3f3f3f"
$DanhSachIndex.ForeColor = "White"
$CuaSo.Controls.Add($DanhSachIndex)

$ThanhTienDo = New-Object System.Windows.Forms.ProgressBar
$ThanhTienDo.Size = New-Object System.Drawing.Size(490, 25)
$ThanhTienDo.Location = New-Object System.Drawing.Point(20, 210)
$ThanhTienDo.Style = "Continuous"
$CuaSo.Controls.Add($ThanhTienDo)

$NhanTrangThai = New-Object System.Windows.Forms.Label
$NhanTrangThai.Text = "Trang thai: San sang."
$NhanTrangThai.Font = $fontThuong
$NhanTrangThai.AutoSize = $true
$NhanTrangThai.ForeColor = "#aaaaaa"
$NhanTrangThai.Location = New-Object System.Drawing.Point(20, 245)
$CuaSo.Controls.Add($NhanTrangThai)

$NutBatDau = New-Object System.Windows.Forms.Button
$NutBatDau.Text = "TIEN HANH CAI DAT"
$NutBatDau.Size = New-Object System.Drawing.Size(490, 50)
$NutBatDau.Location = New-Object System.Drawing.Point(20, 290)
$NutBatDau.BackColor = "#d63031"
$NutBatDau.ForeColor = "White"
$NutBatDau.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$NutBatDau.FlatStyle = "Flat"
$NutBatDau.Enabled = $false
$CuaSo.Controls.Add($NutBatDau)

# 3. Xu ly su kien nut Duyet
$NutDuyet.Add_Click({
    $HopThoai = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoai.Filter = "Windows Image (*.wim)|*.wim"
    
    if ($HopThoai.ShowDialog() -eq "OK") {
        $OChonWim.Text = $HopThoai.FileName
        $DanhSachIndex.Items.Clear()
        $NutBatDau.Enabled = $false
        
        $NhanTrangThai.Text = "Trang thai: Dang doc thong tin phien ban tu tep WIM..."
        [System.Windows.Forms.Application]::DoEvents()
        
        try {
            $ThongTinAnh = Get-WindowsImage -ImagePath $OChonWim.Text
            foreach ($Anh in $ThongTinAnh) {
                $ChuoiHienThi = "$($Anh.ImageIndex) - $($Anh.ImageName)"
                $DanhSachIndex.Items.Add($ChuoiHienThi) | Out-Null
            }
            if ($DanhSachIndex.Items.Count -gt 0) {
                $DanhSachIndex.SelectedIndex = 0
                $NutBatDau.Enabled = $true
                $NhanTrangThai.Text = "Trang thai: Da doc xong. San sang cai dat."
            } else {
                $NhanTrangThai.Text = "Trang thai: Tep WIM trong hoac bi loi."
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Khong the doc tep WIM. Kiem tra xem ban co dang chay bang quyen Administrator khong.", "Loi doc tep", "OK", "Error")
            $NhanTrangThai.Text = "Trang thai: Loi doc du lieu."
        }
    }
})

# 4. Xu ly su kien nut Tien Hanh
$NutBatDau.Add_Click({
    $O_Dia = [System.IO.Path]::GetPathRoot($OChonWim.Text)
    if ($O_Dia -eq "C:\") {
        [System.Windows.Forms.MessageBox]::Show("Tep .wim khong duoc luu tai o C. Qua trinh cai dat se xoa sach o C nen se lam mat tep tin cua ban.", "Loi vi tri", "OK", "Error")
        return
    }

    $XacNhan = [System.Windows.Forms.MessageBox]::Show("He thong se tu dong khoi dong lai, xoa sach o C va tien hanh cai dat. Ban da xac nhan sao luu du lieu chua?", "Canh bao nguy hiem", "YesNo", "Warning")
    if ($XacNhan -ne "Yes") { return }

    $NutBatDau.Enabled = $false
    $NutDuyet.Enabled = $false
    $DanhSachIndex.Enabled = $false

    function CapNhat-GiaoDien { [System.Windows.Forms.Application]::DoEvents() }

    try {
        # CHOT CHAN 1: Chong loi Null khi chua chon Index
        if ($null -eq $DanhSachIndex.SelectedItem) {
            [System.Windows.Forms.MessageBox]::Show("Vui long chon mot phien ban Windows (Index) truoc khi bat dau!", "Thieu thong tin", "OK", "Warning")
            $NutBatDau.Enabled = $true; $NutDuyet.Enabled = $true; $DanhSachIndex.Enabled = $true
            return
        }

        $SoIndexDaChon = $DanhSachIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $DuongDanWim = $OChonWim.Text
        $DuongDanWinRE = "C:\Windows\System32\Recovery\winre.wim"

        $NhanTrangThai.Text = "Trang thai: [5%] Dang kiem tra moi truong cuu ho (WinRE)..."
        $ThanhTienDo.Value = 5
        CapNhat-GiaoDien

        reagentc /disable | Out-Null

        # CHOT CHAN 2: Tu dong nap winre.wim neu he thong bi mat
        if (!(Test-Path $DuongDanWinRE)) {
            $HoiNapFile = [System.Windows.Forms.MessageBox]::Show("May tinh nay bi mat he thong cuu ho (WinRE). Ban co muon chon tep winre.wim du phong de cong cu tu dong nap lai khong?", "Thieu thanh phan he thong", "YesNo", "Question")
            
            if ($HoiNapFile -eq "Yes") {
                $ChonWinRE = New-Object System.Windows.Forms.OpenFileDialog
                $ChonWinRE.Filter = "Windows RE File (winre.wim)|winre.wim"
                $ChonWinRE.Title = "Chon tep winre.wim de phuc hoi"
                
                if ($ChonWinRE.ShowDialog() -eq "OK") {
                    $NhanTrangThai.Text = "Trang thai: Dang bom tep winre.wim vao he thong..."
                    CapNhat-GiaoDien
                    
                    $ThuMucRecovery = "C:\Windows\System32\Recovery"
                    if (!(Test-Path $ThuMucRecovery)) { New-Item -ItemType Directory -Path $ThuMucRecovery -Force | Out-Null }
                    Copy-Item -Path $ChonWinRE.FileName -Destination $DuongDanWinRE -Force
                    
                    reagentc /setreimage /path $ThuMucRecovery | Out-Null
                    reagentc /enable | Out-Null
                    reagentc /disable | Out-Null
                } else {
                    $NhanTrangThai.Text = "Trang thai: Da huy cai dat do thieu WinRE."
                    $NutBatDau.Enabled = $true; $NutDuyet.Enabled = $true; $DanhSachIndex.Enabled = $true
                    return
                }
            } else {
                $NhanTrangThai.Text = "Trang thai: Da huy cai dat do thieu WinRE."
                $NutBatDau.Enabled = $true; $NutDuyet.Enabled = $true; $DanhSachIndex.Enabled = $true
                return
            }
        }

        $NhanTrangThai.Text = "Trang thai: [20%] Dang don dep o dia ao bi ket (Neu co)..."
        $ThanhTienDo.Value = 20
        CapNhat-GiaoDien
        Start-Process -FilePath "dism.exe" -ArgumentList "/cleanup-wim" -Wait -WindowStyle Hidden

        $NhanTrangThai.Text = "Trang thai: [30%] Dang chuan bi moi truong ao..."
        $ThanhTienDo.Value = 30
        CapNhat-GiaoDien
        
        # CHOT CHAN 3: Xoa thu muc Mount cu de tri loi -1052638937
        $ThuMucMount = "C:\MountWinRE"
        if (Test-Path $ThuMucMount) { 
            Start-Process -FilePath "dism.exe" -ArgumentList "/Unmount-Image /MountDir:$ThuMucMount /Discard" -Wait -WindowStyle Hidden
            Remove-Item -Path $ThuMucMount -Force -Recurse -ErrorAction SilentlyContinue 
        }
        New-Item -ItemType Directory -Path $ThuMucMount | Out-Null
        
        $TienTrinhMount = Start-Process -FilePath "dism.exe" -ArgumentList "/Mount-Image /ImageFile:$DuongDanWinRE /Index:1 /MountDir:$ThuMucMount" -Wait -PassThru -WindowStyle Normal
        
        if ($TienTrinhMount.ExitCode -ne 0) {
            [System.Windows.Forms.MessageBox]::Show("DISM bao loi khi mo tep WinRE! Ma loi: $($TienTrinhMount.ExitCode). Vui long khoi dong lai may va thu lai.", "Loi DISM", "OK", "Error")
            $NutBatDau.Enabled = $true; $NutDuyet.Enabled = $true; $DanhSachIndex.Enabled = $true
            return
        }

        $NhanTrangThai.Text = "Trang thai: [60%] Dang tich hop cau lenh tu dong..."
        $ThanhTienDo.Value = 60
        CapNhat-GiaoDien
        
        $DuongDanStartnet = "$ThuMucMount\Windows\System32\startnet.cmd"

        $NoiDungLenh = @"
@echo off
color 0B
wpeinit
cls
echo ========================================================
echo         TIEN TRINH CAI DAT WINDOWS TU DONG
echo ========================================================
echo.
echo [1/3] Dang dinh dang lai o dia he thong...
format C: /fs:ntfs /q /y >nul

echo.
echo [2/3] Dang ap dung phien ban so $SoIndexDaChon tu tep WIM...
echo Tien trinh (%):
dism /Apply-Image /ImageFile:"$DuongDanWim" /Index:$SoIndexDaChon /ApplyDir:C:\

echo.
echo [3/3] Dang cau hinh bo khoi dong...
bcdboot C:\Windows >nul

echo.
echo ========================================================
echo       HOAN TAT! He thong se khoi dong lai ngay.
echo ========================================================
timeout /t 5 >nul
wpeutil reboot
"@
        $NoiDungLenh | Out-File -FilePath $DuongDanStartnet -Encoding ASCII -Force

        $NhanTrangThai.Text = "Trang thai: [80%] Dang dong goi lai he thong..."
        $ThanhTienDo.Value = 80
        CapNhat-GiaoDien
        Start-Process -FilePath "dism.exe" -ArgumentList "/Unmount-Image /MountDir:$ThuMucMount /Commit" -Wait -WindowStyle Normal
        Remove-Item -Path $ThuMucMount -Force -Recurse

        $NhanTrangThai.Text = "Trang thai: [95%] Dang cau hinh khoi dong lai..."
        $ThanhTienDo.Value = 95
        CapNhat-GiaoDien
        reagentc /enable | Out-Null
        reagentc /boottore | Out-Null

        $NhanTrangThai.Text = "Trang thai: [100%] Hoan thanh! Chuan bi khoi dong lai."
        $ThanhTienDo.Value = 100
        CapNhat-GiaoDien
        
        [System.Windows.Forms.MessageBox]::Show("Qua trinh chuan bi hoan tat! May tinh se khoi dong lai ngay bay gio de tien hanh cai dat.", "Thanh cong", "OK", "Information")
        Restart-Computer -Force

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Co loi xay ra trong qua trinh chuan bi: $_", "Loi", "OK", "Error")
        $NutBatDau.Enabled = $true
        $NutDuyet.Enabled = $true
        $DanhSachIndex.Enabled = $true
    }
})

$CuaSo.ShowDialog() | Out-Null