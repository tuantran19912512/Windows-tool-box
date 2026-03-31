# ==============================================================================
# CONG CU CAI DAT WINDOWS TU DONG TREN NEN WINRE (1-CLICK WIM INSTALLER)
# Phien ban: Full Option - Anti-Freeze UI & Auto Recovery
# ==============================================================================

# Yeu cau quyen Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GIAO DIEN CHINH ---
$CuaSo = New-Object System.Windows.Forms.Form
$CuaSo.Text = "VietToolbox - Cai Win Tu Dong 1-Click"
$CuaSo.Size = New-Object System.Drawing.Size(550, 480)
$CuaSo.StartPosition = "CenterScreen"
$CuaSo.FormBorderStyle = "FixedDialog"
$CuaSo.BackColor = "#1e1e1e"
$CuaSo.ForeColor = "White"

$fontTieuDe = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontThuong = New-Object System.Drawing.Font("Segoe UI", 10)

# --- CAC THANH PHAN ---
$NhanTieuDe = New-Object System.Windows.Forms.Label
$NhanTieuDe.Text = "CAI DAT WINDOWS 1-CLICK"
$NhanTieuDe.Font = $fontTieuDe
$NhanTieuDe.ForeColor = "#00adb5"
$NhanTieuDe.AutoSize = $true
$NhanTieuDe.Location = New-Object System.Drawing.Point(20, 20)
$CuaSo.Controls.Add($NhanTieuDe)

# Chon WIM
$NhanWim = New-Object System.Windows.Forms.Label
$NhanWim.Text = "Duong dan tep .wim (Luu o o khac C):"
$NhanWim.Font = $fontThuong
$NhanWim.Location = New-Object System.Drawing.Point(20, 70); $NhanWim.AutoSize = $true
$CuaSo.Controls.Add($NhanWim)

$OChonWim = New-Object System.Windows.Forms.TextBox
$OChonWim.Size = New-Object System.Drawing.Size(390, 25); $OChonWim.Location = New-Object System.Drawing.Point(20, 95)
$OChonWim.ReadOnly = $true; $OChonWim.BackColor = "#333333"; $OChonWim.ForeColor = "White"
$CuaSo.Controls.Add($OChonWim)

$NutDuyetWim = New-Object System.Windows.Forms.Button
$NutDuyetWim.Text = "Duyet..."; $NutDuyetWim.Size = New-Object System.Drawing.Size(90, 27)
$NutDuyetWim.Location = New-Object System.Drawing.Point(420, 94); $NutDuyetWim.BackColor = "#3a3a3a"; $NutDuyetWim.FlatStyle = "Flat"
$CuaSo.Controls.Add($NutDuyetWim)

# Chon WinRE dự phòng
$NhanWinRE = New-Object System.Windows.Forms.Label
$NhanWinRE.Text = "Tep winre.wim du phong (Neu may thieu WinRE):"
$NhanWinRE.Font = $fontThuong; $NhanWinRE.ForeColor = "#f1c40f"
$NhanWinRE.Location = New-Object System.Drawing.Point(20, 135); $NhanWinRE.AutoSize = $true
$CuaSo.Controls.Add($NhanWinRE)

$OChonWinRE = New-Object System.Windows.Forms.TextBox
$OChonWinRE.Size = New-Object System.Drawing.Size(390, 25); $OChonWinRE.Location = New-Object System.Drawing.Point(20, 160)
$OChonWinRE.ReadOnly = $true; $OChonWinRE.BackColor = "#333333"; $OChonWinRE.ForeColor = "White"
$CuaSo.Controls.Add($OChonWinRE)

$NutDuyetRE = New-Object System.Windows.Forms.Button
$NutDuyetRE.Text = "Duyet..."; $NutDuyetRE.Size = New-Object System.Drawing.Size(90, 27)
$NutDuyetRE.Location = New-Object System.Drawing.Point(420, 159); $NutDuyetRE.BackColor = "#3a3a3a"; $NutDuyetRE.FlatStyle = "Flat"
$CuaSo.Controls.Add($NutDuyetRE)

# Chon Index
$NhanIndex = New-Object System.Windows.Forms.Label
$NhanIndex.Text = "Chon phien ban muon cai:"
$NhanIndex.Font = $fontThuong; $NhanIndex.Location = New-Object System.Drawing.Point(20, 200); $NhanIndex.AutoSize = $true
$CuaSo.Controls.Add($NhanIndex)

$DanhSachIndex = New-Object System.Windows.Forms.ComboBox
$DanhSachIndex.Size = New-Object System.Drawing.Size(490, 25); $DanhSachIndex.Location = New-Object System.Drawing.Point(20, 225)
$DanhSachIndex.DropDownStyle = "DropDownList"; $DanhSachIndex.BackColor = "#333333"; $DanhSachIndex.ForeColor = "White"
$CuaSo.Controls.Add($DanhSachIndex)

# Progress & Status
$ThanhTienDo = New-Object System.Windows.Forms.ProgressBar
$ThanhTienDo.Size = New-Object System.Drawing.Size(490, 25); $ThanhTienDo.Location = New-Object System.Drawing.Point(20, 275)
$CuaSo.Controls.Add($ThanhTienDo)

$NhanTrangThai = New-Object System.Windows.Forms.Label
$NhanTrangThai.Text = "Trang thai: San sang."
$NhanTrangThai.Font = $fontThuong; $NhanTrangThai.Location = New-Object System.Drawing.Point(20, 310); $NhanTrangThai.AutoSize = $true; $NhanTrangThai.ForeColor = "#888888"
$CuaSo.Controls.Add($NhanTrangThai)

$NutBatDau = New-Object System.Windows.Forms.Button
$NutBatDau.Text = "BAT DAU CAI DAT NGAY"
$NutBatDau.Size = New-Object System.Drawing.Size(490, 50); $NutBatDau.Location = New-Object System.Drawing.Point(20, 355)
$NutBatDau.BackColor = "#d63031"; $NutBatDau.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$NutBatDau.FlatStyle = "Flat"; $NutBatDau.Enabled = $false
$CuaSo.Controls.Add($NutBatDau)

# --- LOGIC XU LY ---

function CapNhat-GiaoDien { [System.Windows.Forms.Application]::DoEvents() }

$NutDuyetWim.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "Windows Image (*.wim)|*.wim"
    if ($fd.ShowDialog() -eq "OK") {
        $OChonWim.Text = $fd.FileName
        $DanhSachIndex.Items.Clear()
        $NhanTrangThai.Text = "Dang doc thong tin WIM..."
        CapNhat-GiaoDien
        try {
            $images = Get-WindowsImage -ImagePath $fd.FileName
            foreach ($img in $images) { $DanhSachIndex.Items.Add("$($img.ImageIndex) - $($img.ImageName)") | Out-Null }
            if ($DanhSachIndex.Items.Count -gt 0) { $DanhSachIndex.SelectedIndex = 0; $NutBatDau.Enabled = $true }
            $NhanTrangThai.Text = "Da doc xong tep WIM."
        } catch { $NhanTrangThai.Text = "Loi doc tep WIM!" }
    }
})

$NutDuyetRE.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "WinRE File (winre.wim)|winre.wim"
    if ($fd.ShowDialog() -eq "OK") { $OChonWinRE.Text = $fd.FileName }
})

$NutBatDau.Add_Click({
    if ([System.IO.Path]::GetPathRoot($OChonWim.Text) -eq "C:\") {
        [System.Windows.Forms.MessageBox]::Show("Tep .wim khong duoc de o o C!", "Loi", "OK", "Error")
        return
    }
    if ($null -eq $DanhSachIndex.SelectedItem) { return }
    
    $confirm = [System.Windows.Forms.MessageBox]::Show("May se khoi dong lai va MAT HET DU LIEU o o C. Tiep tuc?", "Canh bao", "YesNo", "Warning")
    if ($confirm -ne "Yes") { return }

    $NutBatDau.Enabled = $false; $NutDuyetWim.Enabled = $false; $NutDuyetRE.Enabled = $false
    
    try {
        $idx = $DanhSachIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $OChonWim.Text
        $winre = "C:\Windows\System32\Recovery\winre.wim"
        $mount = "C:\MountWinRE"

        $NhanTrangThai.Text = "Trang thai: [5%] Dang kiem tra WinRE..."
        $ThanhTienDo.Value = 5; CapNhat-GiaoDien
        reagentc /disable | Out-Null

        # Phuc hoi WinRE neu thieu
        if (!(Test-Path $winre)) {
            if (!(Test-Path $OChonWinRE.Text)) {
                [System.Windows.Forms.MessageBox]::Show("May thieu WinRE. Vui long chon file winre.wim du phong o ngoai man hinh!", "Loi", "OK", "Error")
                $NutBatDau.Enabled = $true; return
            }
            $NhanTrangThai.Text = "Trang thai: Dang nap WinRE du phong..."
            CapNhat-GiaoDien
            $recDir = "C:\Windows\System32\Recovery"
            if (!(Test-Path $recDir)) { New-Item $recDir -ItemType Directory -Force | Out-Null }
            Copy-Item $OChonWinRE.Text $winre -Force
            reagentc /setreimage /path $recDir | Out-Null
            reagentc /enable | Out-Null; reagentc /disable | Out-Null
        }

        # Don dep truoc khi chay
        $NhanTrangThai.Text = "Trang thai: [15%] Dang don dep moi truong..."
        $ThanhTienDo.Value = 15; CapNhat-GiaoDien
        if (Test-Path $mount) {
            $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -PassThru -WindowStyle Hidden
            while (!$p.HasExited) { CapNhat-GiaoDien; Start-Sleep -Milliseconds 200 }
            Remove-Item $mount -Force -Recurse -ErrorAction SilentlyContinue
        }
        New-Item $mount -ItemType Directory -Force | Out-Null

        # Mount WinRE (Fix Freeze UI)
        $NhanTrangThai.Text = "Trang thai: [30%] Dang bung nen WinRE (Cua so den dang chay)..."
        $ThanhTienDo.Value = 30; CapNhat-GiaoDien
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:$winre /Index:1 /MountDir:$mount" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { CapNhat-GiaoDien; Start-Sleep -Milliseconds 500 }

        if ($p.ExitCode -ne 0) { throw "Loi Mount DISM: $($p.ExitCode)" }

        # Tich hop script tu dong
        $NhanTrangThai.Text = "Trang thai: [60%] Dang cau hinh lenh tu dong..."
        $ThanhTienDo.Value = 60; CapNhat-GiaoDien
        $cmd = @"
@echo off
wpeinit
cls
echo DANG DINH DANG O C...
format C: /fs:ntfs /q /y >nul
echo DANG CAI DAT WINDOWS (INDEX $idx)...
dism /Apply-Image /ImageFile:"$wim" /Index:$idx /ApplyDir:C:\
echo DANG CAU HINH KHOI DONG...
bcdboot C:\Windows >nul
echo HOAN TAT! KHOI DONG LAI SAU 5 GIAY.
timeout /t 5 >nul
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force

        # Unmount (Fix Freeze UI)
        $NhanTrangThai.Text = "Trang thai: [85%] Dang dong goi he thong..."
        $ThanhTienDo.Value = 85; CapNhat-GiaoDien
        $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { CapNhat-GiaoDien; Start-Sleep -Milliseconds 500 }

        $NhanTrangThai.Text = "Trang thai: [95%] Dang kich hoat che do cai dat..."
        $ThanhTienDo.Value = 95; CapNhat-GiaoDien
        reagentc /enable | Out-Null
        reagentc /boottore | Out-Null

        $NhanTrangThai.Text = "Trang thai: [100%] HOAN TAT!"
        $ThanhTienDo.Value = 100
        [System.Windows.Forms.MessageBox]::Show("Chuan bi xong! May se restart de cai Win.", "Thanh Cong")
        Restart-Computer -Force

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi: $_", "Loi", "OK", "Error")
        $NutBatDau.Enabled = $true; $NutDuyetWim.Enabled = $true; $NutDuyetRE.Enabled = $true
    }
})

$CuaSo.ShowDialog() | Out-Null