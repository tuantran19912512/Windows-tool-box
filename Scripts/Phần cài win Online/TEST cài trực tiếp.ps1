# ==============================================================================
# VIETTOOLBOX - PHUONG AN B: TAO BOOT AO TAM THOI (VHD BOOT)
# Dac tri: May lỳ, bi vang khoi WinRE, Secure Boot gat gao
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- GIAO DIEN ---
$CuaSo = New-Object System.Windows.Forms.Form
$CuaSo.Text = "VietToolbox - Cai Win Phuong An B (VHD Boot)"; $CuaSo.Size = New-Object System.Drawing.Size(560, 400)
$CuaSo.BackColor = "#121212"; $CuaSo.ForeColor = "White"; $CuaSo.StartPosition = "CenterScreen"

$fontTieuDe = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$fontChuan = New-Object System.Drawing.Font("Segoe UI", 10)

$lblTieuDe = New-Object System.Windows.Forms.Label
$lblTieuDe.Text = "CAI WIN TU DONG (PHUONG AN BOOT AO)"; $lblTieuDe.Font = $fontTieuDe; $lblTieuDe.ForeColor = "#ff4d4d"
$lblTieuDe.AutoSize = $true; $lblTieuDe.Location = New-Object System.Drawing.Point(20, 20); $CuaSo.Controls.Add($lblTieuDe)

# Chon WIM
$lblWim = New-Object System.Windows.Forms.Label
$lblWim.Text = "Tep Windows (.wim):"; $lblWim.Location = New-Object System.Drawing.Point(20, 70); $CuaSo.Controls.Add($lblWim)
$txtWim = New-Object System.Windows.Forms.TextBox; $txtWim.Size = New-Object System.Drawing.Size(380, 25); $txtWim.Location = New-Object System.Drawing.Point(20, 95); $txtWim.ReadOnly = $true; $CuaSo.Controls.Add($txtWim)
$btnWim = New-Object System.Windows.Forms.Button; $btnWim.Text = "Duyet..."; $btnWim.Location = New-Object System.Drawing.Point(420, 93); $CuaSo.Controls.Add($btnWim)

# Chon WinRE.wim (Lam nguon cho Boot ao)
$lblRe = New-Object System.Windows.Forms.Label
$lblRe.Text = "Tep WinRE.wim (Bat buoc phai co):"; $lblRe.Location = New-Object System.Drawing.Point(20, 130); $CuaSo.Controls.Add($lblRe)
$txtRe = New-Object System.Windows.Forms.TextBox; $txtRe.Size = New-Object System.Drawing.Size(380, 25); $txtRe.Location = New-Object System.Drawing.Point(20, 155); $txtRe.ReadOnly = $true; $CuaSo.Controls.Add($txtRe)
$btnRe = New-Object System.Windows.Forms.Button; $btnRe.Text = "Duyet..."; $btnRe.Location = New-Object System.Drawing.Point(420, 153); $CuaSo.Controls.Add($btnRe)

$cmbIndex = New-Object System.Windows.Forms.ComboBox; $cmbIndex.Size = New-Object System.Drawing.Size(490, 25); $cmbIndex.Location = New-Object System.Drawing.Point(20, 200); $cmbIndex.DropDownStyle = "DropDownList"; $CuaSo.Controls.Add($cmbIndex)
$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "San sang."; $lblStatus.Location = New-Object System.Drawing.Point(20, 240); $lblStatus.AutoSize = $true; $CuaSo.Controls.Add($lblStatus)

$btnGo = New-Object System.Windows.Forms.Button; $btnGo.Text = "TAO BOOT AO & CAI WIN"; $btnGo.Size = New-Object System.Drawing.Size(490, 50); $btnGo.Location = New-Object System.Drawing.Point(20, 280); $btnGo.BackColor = "#ff4d4d"; $btnGo.Font = $fontTieuDe; $btnGo.Enabled = $false; $CuaSo.Controls.Add($btnGo)

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
    if ([System.IO.Path]::GetPathRoot($txtWim.Text) -eq "C:\") { [System.Windows.Forms.MessageBox]::Show("Tep WIM phai de o o khac C!"); return }
    
    try {
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $txtWim.Text; $reSource = $txtRe.Text
        $vhdPath = "D:\VietToolboxBoot.vhd" # Luu tam o o khac C de tranh bi format xoa mat
        if (! (Test-Path "D:\")) { $vhdPath = "E:\VietToolboxBoot.vhd" } # Phong do may chia o dia khac
        
        $lblStatus.Text = "Trang thai: Dang tao o dia ao (VHD)..."; Refresh-UI
        $vhdScript = @"
create vdisk file="$vhdPath" maximum=1024 type=fixed
select vdisk file="$vhdPath"
attach vdisk
create partition primary
format fs=ntfs quick label="VT_BOOT"
assign letter=Z
"@
        $vhdScript | diskpart | Out-Null

        $lblStatus.Text = "Trang thai: Dang nap WinRE vao o ao..."; Refresh-UI
        $mount = "C:\MountPE"
        if (!(Test-Path $mount)) { New-Item $mount -ItemType Directory | Out-Null }
        dism /Mount-Image /ImageFile:$reSource /Index:1 /MountDir:$mount

        # Nap script tu dong cai win
        $cmd = @"
@echo off
wpeinit
echo DANG PHAN VUNG & CAI WIN...
format C: /fs:ntfs /q /y
dism /Apply-Image /ImageFile:"$wim" /Index:$idx /ApplyDir:C:\
bcdboot C:\Windows /s C: /f ALL
echo XONG! RESTART...
timeout /t 5
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force
        
        dism /Unmount-Image /MountDir:$mount /Commit
        Copy-Item "$reSource" "Z:\boot.wim" -Force # Day thuc chat la file WinRE da sua
        
        $lblStatus.Text = "Trang thai: Dang tao Menu Boot moi..."; Refresh-UI
        # Dung bcdedit de tao dong boot tu file WIM trong o ảo
        $guid = ([guid]::NewGuid()).ToString("B")
        bcdedit /create $guid /d "VietToolbox Installer" /application osloader | Out-Null
        bcdedit /set $guid device ramdisk="[Z:]\boot.wim,{ramdiskoptions}" | Out-Null
        bcdedit /set $guid osdevice ramdisk="[Z:]\boot.wim,{ramdiskoptions}" | Out-Null
        bcdedit /set $guid path \windows\system32\boot\winload.efi | Out-Null
        bcdedit /set $guid systemroot \windows | Out-Null
        bcdedit /set $guid winpe yes | Out-Null
        bcdedit /set $guid detecthal yes | Out-Null
        bcdedit /displayorder $guid /addfirst | Out-Null
        bcdedit /default $guid | Out-Null
        bcdedit /timeout 5 | Out-Null

        [System.Windows.Forms.MessageBox]::Show("Da tao xong phan vung Boot ao! May se Restart vao trinh cai dat ngay.")
        Restart-Computer -Force
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi: $_")
    }
})

$CuaSo.ShowDialog() | Out-Null