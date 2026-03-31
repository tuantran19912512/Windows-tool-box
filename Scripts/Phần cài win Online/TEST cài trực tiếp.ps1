# ==============================================================================
# VIETTOOLBOX - CONG CU CAI WIN 1-CLICK (ANTI-FREEZE & FORCED BOOT)
# Phien ban: Full Toi Uu - Ho tro nap WinRE du phong tu man hinh chinh
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- KHOI TAO GIAO DIEN ---
$CuaSo = New-Object System.Windows.Forms.Form
$CuaSo.Text = "VietToolbox - Cai Win 1-Click (Phien Ban On Dinh)"
$CuaSo.Size = New-Object System.Drawing.Size(560, 500)
$CuaSo.StartPosition = "CenterScreen"
$CuaSo.FormBorderStyle = "FixedDialog"
$CuaSo.BackColor = "#1e1e1e"
$CuaSo.ForeColor = "White"

$fontTieuDe = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontThuong = New-Object System.Drawing.Font("Segoe UI", 10)

# --- CAC THANH PHAN GIAO DIEN ---
$NhanTieuDe = New-Object System.Windows.Forms.Label
$NhanTieuDe.Text = "CAI DAT WINDOWS TU DONG"; $NhanTieuDe.Font = $fontTieuDe; $NhanTieuDe.ForeColor = "#00adb5"
$NhanTieuDe.AutoSize = $true; $NhanTieuDe.Location = New-Object System.Drawing.Point(20, 20); $CuaSo.Controls.Add($NhanTieuDe)

# Chon WIM
$NhanWim = New-Object System.Windows.Forms.Label
$NhanWim.Text = "Duong dan tep .wim (Luu o o khac C):"; $NhanWim.Location = New-Object System.Drawing.Point(20, 70); $NhanWim.AutoSize = $true
$CuaSo.Controls.Add($NhanWim)

$OChonWim = New-Object System.Windows.Forms.TextBox
$OChonWim.Size = New-Object System.Drawing.Size(400, 25); $OChonWim.Location = New-Object System.Drawing.Point(20, 95); $OChonWim.ReadOnly = $true; $OChonWim.BackColor = "#333333"; $OChonWim.ForeColor = "White"
$CuaSo.Controls.Add($OChonWim)

$NutDuyetWim = New-Object System.Windows.Forms.Button
$NutDuyetWim.Text = "Duyet..."; $NutDuyetWim.Size = New-Object System.Drawing.Size(90, 27); $NutDuyetWim.Location = New-Object System.Drawing.Point(430, 94); $NutDuyetWim.BackColor = "#3a3a3a"; $NutDuyetWim.FlatStyle = "Flat"
$CuaSo.Controls.Add($NutDuyetWim)

# Chon WinRE
$NhanWinRE = New-Object System.Windows.Forms.Label
$NhanWinRE.Text = "Tep winre.wim du phong (Neu may thieu WinRE):"; $NhanWinRE.ForeColor = "#f1c40f"; $NhanWinRE.Location = New-Object System.Drawing.Point(20, 135); $NhanWinRE.AutoSize = $true
$CuaSo.Controls.Add($NhanWinRE)

$OChonWinRE = New-Object System.Windows.Forms.TextBox
$OChonWinRE.Size = New-Object System.Drawing.Size(400, 25); $OChonWinRE.Location = New-Object System.Drawing.Point(20, 160); $OChonWinRE.ReadOnly = $true; $OChonWinRE.BackColor = "#333333"; $OChonWinRE.ForeColor = "White"
$CuaSo.Controls.Add($OChonWinRE)

$NutDuyetRE = New-Object System.Windows.Forms.Button
$NutDuyetRE.Text = "Duyet..."; $NutDuyetRE.Size = New-Object System.Drawing.Size(90, 27); $NutDuyetRE.Location = New-Object System.Drawing.Point(430, 159); $NutDuyetRE.BackColor = "#3a3a3a"; $NutDuyetRE.FlatStyle = "Flat"
$CuaSo.Controls.Add($NutDuyetRE)

# Chon Index
$NhanIndex = New-Object System.Windows.Forms.Label
$NhanIndex.Text = "Chon phien ban muon cai:"; $NhanIndex.Location = New-Object System.Drawing.Point(20, 205); $NhanIndex.AutoSize = $true
$CuaSo.Controls.Add($NhanIndex)

$DanhSachIndex = New-Object System.Windows.Forms.ComboBox
$DanhSachIndex.Size = New-Object System.Drawing.Size(500, 25); $DanhSachIndex.Location = New-Object System.Drawing.Point(20, 230); $DanhSachIndex.DropDownStyle = "DropDownList"; $DanhSachIndex.BackColor = "#333333"; $DanhSachIndex.ForeColor = "White"
$CuaSo.Controls.Add($DanhSachIndex)

# Progress & Status
$ThanhTienDo = New-Object System.Windows.Forms.ProgressBar
$ThanhTienDo.Size = New-Object System.Drawing.Size(500, 25); $ThanhTienDo.Location = New-Object System.Drawing.Point(20, 285)
$CuaSo.Controls.Add($ThanhTienDo)

$NhanTrangThai = New-Object System.Windows.Forms.Label
$NhanTrangThai.Text = "Trang thai: San sang."; $NhanTrangThai.Location = New-Object System.Drawing.Point(20, 320); $NhanTrangThai.AutoSize = $true; $NhanTrangThai.ForeColor = "#888888"
$CuaSo.Controls.Add($NhanTrangThai)

$NutBatDau = New-Object System.Windows.Forms.Button
$NutBatDau.Text = "BAT DAU CAI DAT (FORCED REBOOT)"; $NutBatDau.Size = New-Object System.Drawing.Size(500, 55); $NutBatDau.Location = New-Object System.Drawing.Point(20, 365)
$NutBatDau.BackColor = "#d63031"; $NutBatDau.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $NutBatDau.FlatStyle = "Flat"; $NutBatDau.Enabled = $false
$CuaSo.Controls.Add($NutBatDau)

# --- HAM HO TRO ---
function CapNhat-UI { [System.Windows.Forms.Application]::DoEvents() }

$NutDuyetWim.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "Windows Image (*.wim)|*.wim"
    if ($fd.ShowDialog() -eq "OK") {
        $OChonWim.Text = $fd.FileName
        $DanhSachIndex.Items.Clear()
        $NhanTrangThai.Text = "Dang doc thong tin Index..."
        CapNhat-UI
        try {
            $images = Get-WindowsImage -ImagePath $fd.FileName
            foreach ($img in $images) { $DanhSachIndex.Items.Add("$($img.ImageIndex) - $($img.ImageName)") | Out-Null }
            if ($DanhSachIndex.Items.Count -gt 0) { $DanhSachIndex.SelectedIndex = 0; $NutBatDau.Enabled = $true }
            $NhanTrangThai.Text = "San sang cai dat."
        } catch { $NhanTrangThai.Text = "Loi: Khong doc duoc tep WIM!" }
    }
})

$NutDuyetRE.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "WinRE File (winre.wim)|winre.wim"
    if ($fd.ShowDialog() -eq "OK") { $OChonWinRE.Text = $fd.FileName }
})

# --- LOGIC CHINH ---
$NutBatDau.Add_Click({
    if ([System.IO.Path]::GetPathRoot($OChonWim.Text) -eq "C:\") {
        [System.Windows.Forms.MessageBox]::Show("Khong duoc de tep WIM o o C!", "Loi", "OK", "Error"); return
    }
    
    $confirm = [System.Windows.Forms.MessageBox]::Show("MAY SE MAT HET DU LIEU O O C. Xac nhan tiep tuc?", "Canh bao", "YesNo", "Warning")
    if ($confirm -ne "Yes") { return }

    $NutBatDau.Enabled = $false; $NutDuyetWim.Enabled = $false; $NutDuyetRE.Enabled = $false

    try {
        $idx = $DanhSachIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $OChonWim.Text
        $winre = "C:\Windows\System32\Recovery\winre.wim"
        $mount = "C:\MountWinRE"

        $NhanTrangThai.Text = "Trang thai: [5%] Dang chuan doan WinRE..."
        $ThanhTienDo.Value = 5; CapNhat-UI
        
        # Vo hieu hoa cu de lam sach cau truc BCD Recovery
        reagentc /disable | Out-Null

        # Phuc hoi WinRE neu may bi thieu (Nap tu o chon)
        if (!(Test-Path $winre)) {
            if (!(Test-Path $OChonWinRE.Text)) {
                [System.Windows.Forms.MessageBox]::Show("May nay mat WinRE. Vui long chon file winre.wim du phong o man hinh chinh!", "Loi He Thong", "OK", "Error")
                $NutBatDau.Enabled = $true; return
            }
            $NhanTrangThai.Text = "Trang thai: Dang bom WinRE du phong..."
            CapNhat-UI
            $recDir = "C:\Windows\System32\Recovery"
            if (!(Test-Path $recDir)) { New-Item $recDir -ItemType Directory -Force | Out-Null }
            Copy-Item $OChonWinRE.Text $winre -Force
            reagentc /setreimage /path $recDir | Out-Null
            reagentc /enable | Out-Null
            reagentc /disable | Out-Null
        }

        # Don dep & Chuan bi o dia ao
        $NhanTrangThai.Text = "Trang thai: [20%] Dang don dep o Mount bi ket..."
        $ThanhTienDo.Value = 20; CapNhat-UI
        if (Test-Path $mount) {
            $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -PassThru -WindowStyle Hidden
            while (!$p.HasExited) { CapNhat-UI; Start-Sleep -Milliseconds 200 }
            Remove-Item $mount -Force -Recurse -ErrorAction SilentlyContinue
        }
        New-Item $mount -ItemType Directory -Force | Out-Null

        # Bung nen WinRE (Fix Freezing UI)
        $NhanTrangThai.Text = "Trang thai: [40%] Dang bung nen WinRE (Theo doi o cua so den)..."
        $ThanhTienDo.Value = 40; CapNhat-UI
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:$winre /Index:1 /MountDir:$mount" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { CapNhat-UI; Start-Sleep -Milliseconds 500 }
        
        if ($p.ExitCode -ne 0) { throw "Loi Mount WinRE (Mã: $($p.ExitCode))" }

        # Viet script Startnet tu dong
        $NhanTrangThai.Text = "Trang thai: [70%] Dang nap lenh cai dat tu dong..."
        $ThanhTienDo.Value = 70; CapNhat-UI
        $cmd = @"
@echo off
wpeinit
cls
echo ========================================================
echo         TIEN TRINH CAI DAT WINDOWS 1-CLICK
echo ========================================================
echo [1/3] Dang dinh dang lai o C (NTFS)...
format C: /fs:ntfs /q /y >nul
echo [2/3] Dang Apply Image (Index $idx)...
dism /Apply-Image /ImageFile:"$wim" /Index:$idx /ApplyDir:C:\
echo [3/3] Dang tao moi bootloader...
bcdboot C:\Windows /s C: /f ALL >nul
echo HOAN TAT! May se restart sau 5 giay.
timeout /t 5 >nul
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force

        # Dong goi lai WinRE (Fix Freezing UI)
        $NhanTrangThai.Text = "Trang thai: [85%] Dang luu cau hinh he thong..."
        $ThanhTienDo.Value = 85; CapNhat-UI
        $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { CapNhat-UI; Start-Sleep -Milliseconds 500 }

        # KICH HOAT BOOT TO WINRE (CUONG CHE)
        $NhanTrangThai.Text = "Trang thai: [95%] Dang kich hoat Forced Boot..."
        $ThanhTienDo.Value = 95; CapNhat-UI
        reagentc /setreimage /path "C:\Windows\System32\Recovery" | Out-Null
        reagentc /enable | Out-Null
        
        # Ep Windows ghi nhan menu Recovery
        bcdedit /set "{current}" recoveryenabled yes | Out-Null
        reagentc /boottore | Out-Null

        $NhanTrangThai.Text = "Trang thai: [100%] HOAN TAT!"
        $ThanhTienDo.Value = 100; CapNhat-UI
        
        [System.Windows.Forms.MessageBox]::Show("Chuan bi xong! May se Restart va tu dong cai lai Windows ngay bay gio.", "Thanh Cong")
        Restart-Computer -Force

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi nghiem trong: $_", "Loi", "OK", "Error")
        $NutBatDau.Enabled = $true; $NutDuyetWim.Enabled = $true; $NutDuyetRE.Enabled = $true
    }
})

$CuaSo.ShowDialog() | Out-Null