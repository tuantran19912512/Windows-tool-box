Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Thiet lap giao dien chinh (Form)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Cong Cu Phuc Hoi He Thong 1-Click"
$form.Size = New-Object System.Drawing.Size(550, 420)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.BackColor = "#1e1e1e"
$form.ForeColor = "White"

# 2. Cac thanh phan giao dien (Controls)
$fontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontNormal = New-Object System.Drawing.Font("Segoe UI", 10)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "CAI DAT WINDOWS TU DONG"
$lblTitle.Font = $fontTitle
$lblTitle.ForeColor = "#00adb5"
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($lblTitle)

$lblWim = New-Object System.Windows.Forms.Label
$lblWim.Text = "Duong dan tep .wim (Khong de tren o C):"
$lblWim.Font = $fontNormal
$lblWim.AutoSize = $true
$lblWim.Location = New-Object System.Drawing.Point(20, 70)
$form.Controls.Add($lblWim)

$txtWim = New-Object System.Windows.Forms.TextBox
$txtWim.Size = New-Object System.Drawing.Size(390, 25)
$txtWim.Location = New-Object System.Drawing.Point(20, 95)
$txtWim.Font = $fontNormal
$txtWim.ReadOnly = $true # Khoa chi cho phep chon qua nut Duyet
$form.Controls.Add($txtWim)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Duyet..."
$btnBrowse.Size = New-Object System.Drawing.Size(90, 27)
$btnBrowse.Location = New-Object System.Drawing.Point(420, 94)
$btnBrowse.BackColor = "#3a3a3a"
$btnBrowse.FlatStyle = "Flat"
$form.Controls.Add($btnBrowse)

$lblIndex = New-Object System.Windows.Forms.Label
$lblIndex.Text = "Chon phien ban Windows muon cai:"
$lblIndex.Font = $fontNormal
$lblIndex.AutoSize = $true
$lblIndex.Location = New-Object System.Drawing.Point(20, 135)
$form.Controls.Add($lblIndex)

# Thay the TextBox thanh ComboBox (Danh sach tha xuong)
$cmbIndex = New-Object System.Windows.Forms.ComboBox
$cmbIndex.Size = New-Object System.Drawing.Size(490, 25)
$cmbIndex.Location = New-Object System.Drawing.Point(20, 160)
$cmbIndex.Font = $fontNormal
$cmbIndex.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbIndex.BackColor = "#3f3f3f"
$cmbIndex.ForeColor = "White"
$form.Controls.Add($cmbIndex)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(490, 25)
$progressBar.Location = New-Object System.Drawing.Point(20, 210)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Trang thai: San sang."
$lblStatus.Font = $fontNormal
$lblStatus.AutoSize = $true
$lblStatus.ForeColor = "#aaaaaa"
$lblStatus.Location = New-Object System.Drawing.Point(20, 245)
$form.Controls.Add($lblStatus)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "TIEN HANH CAI DAT"
$btnStart.Size = New-Object System.Drawing.Size(490, 50)
$btnStart.Location = New-Object System.Drawing.Point(20, 290)
$btnStart.BackColor = "#d63031"
$btnStart.ForeColor = "White"
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnStart.FlatStyle = "Flat"
$btnStart.Enabled = $false # Khoa nut nay cho den khi chon dung file WIM
$form.Controls.Add($btnStart)

# 3. Xu ly su kien nut Duyet
$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Windows Image (*.wim)|*.wim"
    
    if ($dialog.ShowDialog() -eq "OK") {
        $txtWim.Text = $dialog.FileName
        $cmbIndex.Items.Clear()
        $btnStart.Enabled = $false
        
        $lblStatus.Text = "Trang thai: Dang doc thong tin phien ban tu tep WIM..."
        [System.Windows.Forms.Application]::DoEvents()
        
        try {
            # Dung lenh Get-WindowsImage de doc file WIM
            $imageInfo = Get-WindowsImage -ImagePath $txtWim.Text
            
            foreach ($img in $imageInfo) {
                # Noi so Index va Ten vao cung 1 dong (VD: "1 - Windows 10 Pro")
                $itemText = "$($img.ImageIndex) - $($img.ImageName)"
                $cmbIndex.Items.Add($itemText) | Out-Null
            }
            
            if ($cmbIndex.Items.Count -gt 0) {
                $cmbIndex.SelectedIndex = 0 # Tu dong chon dong dau tien
                $btnStart.Enabled = $true
                $lblStatus.Text = "Trang thai: Da doc xong. San sang cai dat."
            } else {
                $lblStatus.Text = "Trang thai: Tep WIM trong hoac bi loi."
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Khong the doc tep WIM. Kiem tra xem ban co dang chay bang quyen Administrator khong.", "Loi doc tep", "OK", "Error")
            $lblStatus.Text = "Trang thai: Loi doc du lieu."
        }
    }
})

# 4. Xu ly su kien nut Tien Hanh
$btnStart.Add_Click({
    $drive = [System.IO.Path]::GetPathRoot($txtWim.Text)
    if ($drive -eq "C:\") {
        [System.Windows.Forms.MessageBox]::Show("Tep .wim khong duoc luu tai o C. Qua trinh cai dat se xoa sach o C nen se lam mat tep tin cua ban.", "Loi vi tri", "OK", "Error")
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show("He thong se tu dong khoi dong lai, xoa sach o C va tien hanh cai dat. Ban da xac nhan sao luu du lieu chua?", "Canh bao nguy hiem", "YesNo", "Warning")
    if ($confirm -ne "Yes") { return }

    # Khoa cac thao tac tren giao dien
    $btnStart.Enabled = $false
    $btnBrowse.Enabled = $false
    $cmbIndex.Enabled = $false

    function Update-UI { [System.Windows.Forms.Application]::DoEvents() }

    try {
        $selectedIndexNumber = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wimPath = $txtWim.Text
        $winrePath = "C:\Windows\System32\Recovery\winre.wim"

        $lblStatus.Text = "Trang thai: [5%] Dang kiem tra moi truong cuu ho (WinRE)..."
        $progressBar.Value = 5
        Update-UI

        # Tắt WinRE tạm thời để nhả file về ổ C (nếu đang ở phân vùng ẩn)
        reagentc /disable | Out-Null

        # ====================================================================
        # CHỨC NĂNG MỚI: TỰ ĐỘNG NẠP WINRE NẾU BỊ MẤT
        # ====================================================================
        if (!(Test-Path $winrePath)) {
            $hoiNapFile = [System.Windows.Forms.MessageBox]::Show("May tinh nay bi mat he thong cuu ho (WinRE). Ban co muon chon tep winre.wim du phong de cong cu tu dong nap lai khong?", "Thieu thanh phan he thong", "YesNo", "Question")
            
            if ($hoiNapFile -eq "Yes") {
                $chonWinRE = New-Object System.Windows.Forms.OpenFileDialog
                $chonWinRE.Filter = "Windows RE File (winre.wim)|winre.wim"
                $chonWinRE.Title = "Chon tep winre.wim de phuc hoi"
                
                if ($chonWinRE.ShowDialog() -eq "OK") {
                    $lblStatus.Text = "Trang thai: Dang bom tep winre.wim vao he thong..."
                    Update-UI
                    
                    # Tu dong tao thu muc neu chua co va copy file vao
                    $thuMucRecovery = "C:\Windows\System32\Recovery"
                    if (!(Test-Path $thuMucRecovery)) { New-Item -ItemType Directory -Path $thuMucRecovery -Force | Out-Null }
                    Copy-Item -Path $chonWinRE.FileName -Destination $winrePath -Force
                    
                    # Kich hoat lai
                    reagentc /setreimage /path $thuMucRecovery | Out-Null
                    reagentc /enable | Out-Null
                    reagentc /disable | Out-Null # Tat lai de chuan bi mount
                } else {
                    $lblStatus.Text = "Trang thai: Da huy cai dat do thieu WinRE."
                    $btnStart.Enabled = $true; $btnBrowse.Enabled = $true; $cmbIndex.Enabled = $true
                    return
                }
            } else {
                $lblStatus.Text = "Trang thai: Da huy cai dat do thieu WinRE."
                $btnStart.Enabled = $true; $btnBrowse.Enabled = $true; $cmbIndex.Enabled = $true
                return
            }
        }
        # ====================================================================

        $lblStatus.Text = "Trang thai: [20%] Dang don dep o dia ao bi ket (Neu co)..."
        $progressBar.Value = 20
        Update-UI
        Start-Process -FilePath "dism.exe" -ArgumentList "/cleanup-wim" -Wait -WindowStyle Hidden

        $lblStatus.Text = "Trang thai: [30%] Dang chuan bi moi truong ao..."
        $progressBar.Value = 30
        Update-UI
        $mountDir = "C:\MountWinRE"
        if (!(Test-Path $mountDir)) { New-Item -ItemType Directory -Path $mountDir | Out-Null }
        
        # BẬT CỬA SỔ CMD (Normal) ĐỂ THEO DÕI TIẾN TRÌNH DISM
        $tienTrinhMount = Start-Process -FilePath "dism.exe" -ArgumentList "/Mount-Image /ImageFile:$winrePath /Index:1 /MountDir:$mountDir" -Wait -PassThru -WindowStyle Normal
        
        if ($tienTrinhMount.ExitCode -ne 0) {
            [System.Windows.Forms.MessageBox]::Show("DISM bao loi khi mo tep WinRE! Ma loi: $($tienTrinhMount.ExitCode). Vui long khoi dong lai may va thu lai.", "Loi DISM", "OK", "Error")
            $btnStart.Enabled = $true; $btnBrowse.Enabled = $true; $cmbIndex.Enabled = $true
            return
        }

        $lblStatus.Text = "Trang thai: [60%] Dang tich hop cau lenh tu dong..."
        $progressBar.Value = 60
        Update-UI
        
        $startnetPath = "$mountDir\Windows\System32\startnet.cmd"

        $cmdContent = @"
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
echo [2/3] Dang ap dung phien ban so $selectedIndexNumber tu tep WIM...
echo Tien trinh (%):
dism /Apply-Image /ImageFile:"$wimPath" /Index:$selectedIndexNumber /ApplyDir:C:\

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
        $cmdContent | Out-File -FilePath $startnetPath -Encoding ASCII -Force

        $lblStatus.Text = "Trang thai: [80%] Dang dong goi lai he thong..."
        $progressBar.Value = 80
        Update-UI
        Start-Process -FilePath "dism.exe" -ArgumentList "/Unmount-Image /MountDir:$mountDir /Commit" -Wait -WindowStyle Normal
        Remove-Item -Path $mountDir -Force -Recurse

        $lblStatus.Text = "Trang thai: [95%] Dang cau hinh khoi dong lai..."
        $progressBar.Value = 95
        Update-UI
        reagentc /enable | Out-Null
        reagentc /boottore | Out-Null

        $lblStatus.Text = "Trang thai: [100%] Hoan thanh! Chuan bi khoi dong lai."
        $progressBar.Value = 100
        Update-UI
        
        [System.Windows.Forms.MessageBox]::Show("Qua trinh chuan bi hoan tat! May tinh se khoi dong lai ngay bay gio de tien hanh cai dat.", "Thanh cong", "OK", "Information")
        Restart-Computer -Force

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Co loi xay ra trong qua trinh chuan bi: $_", "Loi", "OK", "Error")
        $btnStart.Enabled = $true
        $btnBrowse.Enabled = $true
        $cmbIndex.Enabled = $true
    }
})

$form.ShowDialog() | Out-Null