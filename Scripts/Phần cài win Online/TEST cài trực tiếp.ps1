# ==============================================================================
# VIETTOOLBOX - PHUONG AN E: NATIVE RAMDISK (FIX LOI 0x7B & 0xED)
# Dac tri: Win 11 ban quyen, Secure Boot, thieu file moi boot.sdi
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- GIAO DIEN ---
$CuaSo = New-Object System.Windows.Forms.Form
$CuaSo.Text = "VietToolbox V16 - Native Boot (Giai Phap Cuoi)"; $CuaSo.Size = New-Object System.Drawing.Size(560, 480)
$CuaSo.BackColor = "#121212"; $CuaSo.ForeColor = "White"; $CuaSo.StartPosition = "CenterScreen"

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "CAI WIN 1-CLICK (NATIVE RAMDISK)"; $lblTitle.Font = $fontTitle; $lblTitle.ForeColor = "#00adb5"
$lblTitle.AutoSize = $true; $lblTitle.Location = New-Object System.Drawing.Point(20, 20); $CuaSo.Controls.Add($lblTitle)

# Controls chon file
$lblWim = New-Object System.Windows.Forms.Label; $lblWim.Text = "Tep Windows (.wim):"; $lblWim.Location = New-Object System.Drawing.Point(20, 70); $CuaSo.Controls.Add($lblWim)
$txtWim = New-Object System.Windows.Forms.TextBox; $txtWim.Size = New-Object System.Drawing.Size(380, 25); $txtWim.Location = New-Object System.Drawing.Point(20, 95); $CuaSo.Controls.Add($txtWim)
$btnWim = New-Object System.Windows.Forms.Button; $btnWim.Text = "Duyet..."; $btnWim.Location = New-Object System.Drawing.Point(420, 93); $CuaSo.Controls.Add($btnWim)

$lblRe = New-Object System.Windows.Forms.Label; $lblRe.Text = "Tep WinRE.wim (Bat buoc):"; $lblRe.Location = New-Object System.Drawing.Point(20, 130); $lblRe.ForeColor = "#f1c40f"; $CuaSo.Controls.Add($lblRe)
$txtRe = New-Object System.Windows.Forms.TextBox; $txtRe.Size = New-Object System.Drawing.Size(380, 25); $txtRe.Location = New-Object System.Drawing.Point(20, 155); $CuaSo.Controls.Add($txtRe)
$btnRe = New-Object System.Windows.Forms.Button; $btnRe.Text = "Duyet..."; $btnRe.Location = New-Object System.Drawing.Point(420, 153); $CuaSo.Controls.Add($btnRe)

$cmbIndex = New-Object System.Windows.Forms.ComboBox; $cmbIndex.Size = New-Object System.Drawing.Size(490, 25); $cmbIndex.Location = New-Object System.Drawing.Point(20, 200); $cmbIndex.DropDownStyle = "DropDownList"; $CuaSo.Controls.Add($cmbIndex)
$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Kiem tra BitLocker truoc khi chay!"; $lblStatus.Location = New-Object System.Drawing.Point(20, 240); $lblStatus.AutoSize = $true; $lblStatus.ForeColor = "#ff4d4d"; $CuaSo.Controls.Add($lblStatus)

$btnGo = New-Object System.Windows.Forms.Button; $btnGo.Text = "KICH HOAT CAI DAT"; $btnGo.Size = New-Object System.Drawing.Size(490, 60); $btnGo.Location = New-Object System.Drawing.Point(20, 300); $btnGo.BackColor = "#00adb5"; $btnGo.Font = $fontTitle; $btnGo.Enabled = $false; $CuaSo.Controls.Add($btnGo)

# --- LOGIC ---
function Refresh-UI { [System.Windows.Forms.Application]::DoEvents() }

$btnWim.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "WIM File|*.wim"
    if ($fd.ShowDialog() -eq "OK") {
        $txtWim.Text = $fd.FileName; $cmbIndex.Items.Clear()
        $imgs = Get-WindowsImage -ImagePath $fd.FileName
        foreach ($i in $imgs) { $cmbIndex.Items.Add("$($i.ImageIndex) - $($i.ImageName)") | Out-Null }
        $cmbIndex.SelectedIndex = 0; if ($txtRe.Text) { $btnGo.Enabled = $true }
    }
})

$btnRe.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "WinRE File|*.wim"
    if ($fd.ShowDialog() -eq "OK") { $txtRe.Text = $fd.FileName; if ($txtWim.Text) { $btnGo.Enabled = $true } }
})

$btnGo.Add_Click({
    try {
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $txtWim.Text; $reSource = $txtRe.Text
        $bootDir = "C:\VietBoot"
        if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }

        $lblStatus.Text = "Trang thai: Dang lay file moi boot.sdi..."; Refresh-UI
        # Tim file boot.sdi xịn trong máy để làm mồi
        $sdiSource = "C:\Windows\Boot\DVD\EFI\boot.sdi"
        if (!(Test-Path $sdiSource)) { $sdiSource = "C:\Windows\Boot\EFI\boot.sdi" }
        Copy-Item $sdiSource "$bootDir\boot.sdi" -Force

        $lblStatus.Text = "Trang thai: Dang Mount WinRE de nap script..."; Refresh-UI
        $mount = "C:\MountTemp"
        if (Test-Path $mount) { Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -Wait -WindowStyle Hidden }
        New-Item $mount -ItemType Directory -Force | Out-Null
        
        Copy-Item $reSource "$bootDir\boot.wim" -Force
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mount" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { Refresh-UI; Start-Sleep -Milliseconds 500 }

        $cmd = @"
@echo off
wpeinit
cls
echo ========================================================
echo         TIEN TRINH CAI DAT WINDOWS TU DONG
echo ========================================================

echo [1/3] Dang tim kiem tep tin $tenFileWim...
set WIM_PATH=
for %%i in (C D E F G H I J K L M N O P Q R S T U V) do (
    if exist "%%i:\$tenFileWim" (
        set WIM_PATH=%%i:\$tenFileWim
        echo Da tim thay tep tai: %%i:\$tenFileWim
    )
)

if "%WIM_PATH%"=="" (
    echo [LOI] Khong tim thay tep $tenFileWim tren bat ky o dia nao!
    echo Vui long kiem tra lai va restart.
    pause
    exit
)

echo.
echo [2/3] Dang dinh dang lai o dia he thong (C:)...
echo Chu y: WinPE se tu xac dinh o C la o cai Win.
format C: /fs:ntfs /q /y >nul

echo.
echo [3/3] Dang bung anh he thong (Apply Image)...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\

echo.
echo [4/4] Dang tao bo khoi dong (Bootloader)...
bcdboot C:\Windows /s C: /f ALL

echo ========================================================
echo        HOAN TAT! May se Restart sau 10 giay.
echo ========================================================
timeout /t 10
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force
        dism /Unmount-Image /MountDir:$mount /Commit

        $lblStatus.Text = "Trang thai: Dang don dep Menu Boot cu..."; Refresh-UI
        # Xóa hết các dòng boot rác mang tên VietToolbox
        $list = bcdedit /enum all
        $oldGuids = $list | Select-String "{.*}" -AllMatches | ForEach-Object { $_.Matches.Value } | Select-Object -Unique
        foreach ($g in $oldGuids) {
            $info = bcdedit /enum $g
            if ($info -like "*VietToolbox*") { bcdedit /delete $g /cleanup | Out-Null }
        }

        $lblStatus.Text = "Trang thai: Dang dang ky Ramdisk chuẩn..."; Refresh-UI
        # Tạo Ramdisk Options chuẩn
        $ramdiskGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $ramdiskGuid /d "VietToolbox Ramdisk Options" /device | Out-Null
        bcdedit /set $ramdiskGuid ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ramdiskGuid ramdisksdipath "\VietBoot\boot.sdi" | Out-Null

        # Tạo Loader Boot
        $bootGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $bootGuid /d "VietToolbox Installer" /application osloader | Out-Null
        bcdedit /set $bootGuid device "ramdisk=[C:]\VietBoot\boot.wim,$ramdiskGuid" | Out-Null
        bcdedit /set $bootGuid osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ramdiskGuid" | Out-Null
        bcdedit /set $bootGuid path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $bootGuid systemroot "\windows" | Out-Null
        bcdedit /set $bootGuid winpe yes | Out-Null
        bcdedit /set $bootGuid detecthal yes | Out-Null
        bcdedit /displayorder $bootGuid /addfirst | Out-Null
        bcdedit /default $bootGuid | Out-Null
        bcdedit /timeout 5 | Out-Null

        [System.Windows.Forms.MessageBox]::Show("Hoan tat! Neu may van văng, hay kiem tra BitLocker da TAT chua.")
        Restart-Computer -Force
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi: $_")
    }
})

$CuaSo.ShowDialog() | Out-Null