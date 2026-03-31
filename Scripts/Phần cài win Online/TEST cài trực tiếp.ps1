# ==============================================================================
# VIETTOOLBOX - PHUONG AN C: BOOT TU THU MUC HE THONG (DIRECT BOOT)
# Dac tri: May kén Boot, bi man hinh xanh (0xED), Secure Boot kien co
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- GIAO DIEN (GIU NGUYEN NHU BAN TRUOC) ---
$CuaSo = New-Object System.Windows.Forms.Form
$CuaSo.Text = "VietToolbox - Cai Win Chuyen Sau (Direct Boot)"; $CuaSo.Size = New-Object System.Drawing.Size(560, 420)
$CuaSo.BackColor = "#1e1e1e"; $CuaSo.ForeColor = "White"; $CuaSo.StartPosition = "CenterScreen"

$fontTieuDe = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblTieuDe = New-Object System.Windows.Forms.Label
$lblTieuDe.Text = "CAI WIN TU DONG (PHUONG AN DIRECT BOOT)"; $lblTieuDe.Font = $fontTieuDe; $lblTieuDe.ForeColor = "#00adb5"
$lblTieuDe.AutoSize = $true; $lblTieuDe.Location = New-Object System.Drawing.Point(20, 20); $CuaSo.Controls.Add($lblTieuDe)

# Controls chon file
$lblWim = New-Object System.Windows.Forms.Label; $lblWim.Text = "Tep Windows (.wim):"; $lblWim.Location = New-Object System.Drawing.Point(20, 70); $CuaSo.Controls.Add($lblWim)
$txtWim = New-Object System.Windows.Forms.TextBox; $txtWim.Size = New-Object System.Drawing.Size(380, 25); $txtWim.Location = New-Object System.Drawing.Point(20, 95); $CuaSo.Controls.Add($txtWim)
$btnWim = New-Object System.Windows.Forms.Button; $btnWim.Text = "Duyet..."; $btnWim.Location = New-Object System.Drawing.Point(420, 93); $CuaSo.Controls.Add($btnWim)

$lblRe = New-Object System.Windows.Forms.Label; $lblRe.Text = "Tep WinRE.wim (Nguon Boot):"; $lblRe.Location = New-Object System.Drawing.Point(20, 130); $CuaSo.Controls.Add($lblRe)
$txtRe = New-Object System.Windows.Forms.TextBox; $txtRe.Size = New-Object System.Drawing.Size(380, 25); $txtRe.Location = New-Object System.Drawing.Point(20, 155); $CuaSo.Controls.Add($txtRe)
$btnRe = New-Object System.Windows.Forms.Button; $btnRe.Text = "Duyet..."; $btnRe.Location = New-Object System.Drawing.Point(420, 153); $CuaSo.Controls.Add($btnRe)

$cmbIndex = New-Object System.Windows.Forms.ComboBox; $cmbIndex.Size = New-Object System.Drawing.Size(490, 25); $cmbIndex.Location = New-Object System.Drawing.Point(20, 200); $cmbIndex.DropDownStyle = "DropDownList"; $CuaSo.Controls.Add($cmbIndex)
$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Chờ lệnh..."; $lblStatus.Location = New-Object System.Drawing.Point(20, 240); $lblStatus.AutoSize = $true; $CuaSo.Controls.Add($lblStatus)

$btnGo = New-Object System.Windows.Forms.Button; $btnGo.Text = "CHAY CAI DAT (DIRECT)"; $btnGo.Size = New-Object System.Drawing.Size(490, 60); $btnGo.Location = New-Object System.Drawing.Point(20, 290); $btnGo.BackColor = "#00adb5"; $btnGo.Font = $fontTieuDe; $btnGo.Enabled = $false; $CuaSo.Controls.Add($btnGo)

# --- LOGIC XU LY ---
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
    $confirm = [System.Windows.Forms.MessageBox]::Show("May se Restart va format o C. Ban da sao luu chua?", "Xac nhan", "YesNo", "Warning")
    if ($confirm -ne "Yes") { return }

    try {
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $txtWim.Text; $reSource = $txtRe.Text
        $bootDir = "D:\VietToolbox_Boot" # ĐỂ Ở D CHO AN TOÀN
        if (! (Test-Path "D:\")) { $bootDir = "C:\VietToolbox_Boot" }
        
        if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory | Out-Null }
        
        $lblStatus.Text = "Trang thai: Dang chuẩn bị file Boot..."; Refresh-UI
        Copy-Item $reSource "$bootDir\boot.wim" -Force

        # Tao file script tu dong
        $mount = "C:\MountTemp"
        if (!(Test-Path $mount)) { New-Item $mount -ItemType Directory | Out-Null }
        dism /Mount-Image /ImageFile:"$bootDir\boot.wim" /Index:1 /MountDir:$mount
        
        $cmd = @"
@echo off
wpeinit
echo DANG CAI WIN...
format C: /fs:ntfs /q /y
dism /Apply-Image /ImageFile:"$wim" /Index:$idx /ApplyDir:C:\
bcdboot C:\Windows /s C: /f ALL
echo XONG! DANG RESTART...
timeout /t 5
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force
        dism /Unmount-Image /MountDir:$mount /Commit

        $lblStatus.Text = "Trang thai: Dang dang ky Boot Menu..."; Refresh-UI
        # DÙNG RAMDISK OPTIONS ĐỂ BOOT THẲNG TỪ FILE WIM
        $ramGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $ramGuid /d "VietToolbox Ramdisk" /device | Out-Null
        bcdedit /set $ramGuid ramdisksdidevice "partition=$([System.IO.Path]::GetPathRoot($bootDir).TrimEnd('\'))" | Out-Null
        bcdedit /set $ramGuid ramdisksdipath "\VietToolbox_Boot\boot.wim" | Out-Null # Đây là bước quan trọng nhất

        $bootGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $bootGuid /d "VietToolbox Installer" /application osloader | Out-Null
        bcdedit /set $bootGuid device "ramdisk=[$([System.IO.Path]::GetPathRoot($bootDir).TrimEnd('\'))]\VietToolbox_Boot\boot.wim,$ramGuid" | Out-Null
        bcdedit /set $bootGuid osdevice "ramdisk=[$([System.IO.Path]::GetPathRoot($bootDir).TrimEnd('\'))]\VietToolbox_Boot\boot.wim,$ramGuid" | Out-Null
        bcdedit /set $bootGuid path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $bootGuid systemroot "\windows" | Out-Null
        bcdedit /set $bootGuid winpe yes | Out-Null
        bcdedit /set $bootGuid detecthal yes | Out-Null
        bcdedit /displayorder $bootGuid /addfirst | Out-Null
        bcdedit /default $bootGuid | Out-Null
        bcdedit /timeout 5 | Out-Null

        [System.Windows.Forms.MessageBox]::Show("Hoan tat! He thong se tu dong vao trinh cai dat.")
        Restart-Computer -Force
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi: $_")
    }
})

$CuaSo.ShowDialog() | Out-Null