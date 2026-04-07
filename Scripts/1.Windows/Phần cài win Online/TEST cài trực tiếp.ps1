# ==============================================================================
# VIETTOOLBOX V37.1 - THE OFFLINE BEAST (CHỌN FILE CỤC BỘ)
# Tính năng: Chọn WIM/ISO/ESD từ ổ cứng, Fix Boot, Nạp Driver, Silent OOBE.
# Tự động: Tắt BitLocker, AnyDesk, Bypass TPM/NRO, Pass Không giới hạn.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V37.1 - Offline Edition" Height="700" Width="800" 
        WindowStartupLocation="CenterScreen" Background="#050505">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="TRIỂN KHAI WINDOWS OFFLINE" FontSize="34" FontWeight="Black" Foreground="#00adb5" HorizontalAlignment="Center"/>
            <TextBlock Text="CHỌN FILE CÀI ĐẶT CÓ SẴN - TỰ ĐỘNG HÓA TỪ A ĐẾN Z" FontSize="11" Foreground="#555" HorizontalAlignment="Center"/>
        </StackPanel>

        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions><ColumnDefinition Width="1.2*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            
            <GroupBox Header=" 1. CHỌN NGUỒN CÀI ĐẶT " Foreground="#00adb5" BorderBrush="#222" Margin="0,0,10,0" FontSize="14" FontWeight="Bold">
                <StackPanel Margin="15">
                    <TextBlock Text="Đường dẫn file (.wim, .iso, .esd):" Foreground="#AAA" Margin="0,0,0,5"/>
                    <Grid Margin="0,0,0,15">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                        <TextBox Name="txtPath" IsReadOnly="True" Height="35" Background="#111" Foreground="#00adb5" VerticalContentAlignment="Center" Padding="5,0"/>
                        <Button Name="btnBrowse" Grid.Column="1" Content="CHỌN FILE" Background="#00adb5" Foreground="White" FontWeight="Bold" Margin="5,0,0,0"/>
                    </Grid>
                    <TextBlock Text="Phiên bản cài đặt (Index):" Foreground="#AAA" Margin="0,0,0,5"/>
                    <ComboBox Name="cmbIndex" Height="35" Background="#111" Foreground="#00adb5"/>
                </StackPanel>
            </GroupBox>

            <GroupBox Grid.Column="1" Header=" 2. TÙY CHỌN HẬU CÀI ĐẶT " Foreground="#E91E63" BorderBrush="#222" Margin="10,0,0,0" FontSize="14" FontWeight="Bold">
                <StackPanel Margin="20">
                    <CheckBox Name="chkDriver" Content="Tự nạp Driver máy khách" Foreground="#00adb5" IsChecked="True" FontSize="13" Margin="0,0,0,18"/>
                    <CheckBox Name="chkBitLocker" Content="Vô hiệu hóa BitLocker" Foreground="#FFB300" IsChecked="True" FontSize="13" Margin="0,0,0,18"/>
                    <CheckBox Name="chkOOBE" Content="Bypass OOBE (Tự nhập User)" Foreground="White" IsChecked="True" FontSize="13" Margin="0,0,0,18"/>
                    <CheckBox Name="chkAnydesk" Content="Cài AnyDesk &amp; Bật sẵn" Foreground="#4CAF50" IsChecked="True" FontSize="13" Margin="0,0,0,18"/>
                    <CheckBox Name="chkActive" Content="Kích hoạt Win/Office (MAS)" Foreground="#00adb5" IsChecked="True" FontSize="13"/>
                </StackPanel>
            </GroupBox>
        </Grid>

        <StackPanel Grid.Row="2" Margin="0,20,0,0">
            <ProgressBar Name="pgBar" Height="15" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Đang chờ chọn file..." Foreground="#888" HorizontalAlignment="Center" FontSize="13" FontWeight="Bold"/>
            <Button Name="btnStart" Content="KÍCH HOẠT QUY TRÌNH CÀI ĐẶT" Height="60" Background="#D32F2F" Foreground="White" FontSize="20" FontWeight="Black" Margin="0,10,0,0" IsEnabled="False"/>
        </StackPanel>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$txtPath = $CuaSo.FindName("txtPath"); $btnBrowse = $CuaSo.FindName("btnBrowse"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$lblStatus = $CuaSo.FindName("lblStatus"); $pgBar = $CuaSo.FindName("pgBar"); $btnStart = $CuaSo.FindName("btnStart")
$chkDriver = $CuaSo.FindName("chkDriver"); $chkBitLocker = $CuaSo.FindName("chkBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE")
$chkAnydesk = $CuaSo.FindName("chkAnydesk"); $chkActive = $CuaSo.FindName("chkActive")

function Update-UI { [System.Windows.Forms.Application]::DoEvents() }

# --- SỰ KIỆN CHỌN FILE ---
$btnBrowse.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "Windows Image|*.wim;*.iso;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtPath.Text = $fd.FileName
        $cmbIndex.Items.Clear()
        $lblStatus.Text = "Đang quét thông tin bộ cài..."; Update-UI
        try {
            $path = $fd.FileName
            if ($path.EndsWith(".iso")) {
                $m = Mount-DiskImage -ImagePath $path -PassThru; $dv = ($m | Get-Volume).DriveLetter
                $w = "$dv`:\sources\install.wim"; if (!(Test-Path $w)) { $w = "$dv`:\sources\install.esd" }
                (Get-WindowsImage -ImagePath $w) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
                Dismount-DiskImage -ImagePath $path | Out-Null
            } else {
                (Get-WindowsImage -ImagePath $path) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
            }
            $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true; $lblStatus.Text = "Sẵn sàng."
        } catch { [System.Windows.MessageBox]::Show("Lỗi đọc file: $_") }
    }
})

# --- QUY TRÌNH THỰC THI OFFLINE ---
$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; $VietBoot = "C:\VietBoot"; if (!(Test-Path $VietBoot)) { New-Item $VietBoot -ItemType Directory -Force | Out-Null }
    $SelPath = $txtPath.Text; $SelIdx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()

    try {
        # 1. FIX BOOT (10%)
        $pgBar.Value = 10; $lblStatus.Text = "[1/10] Kiểm tra phân vùng Boot..."; Update-UI
        if (!(Get-Partition | Where-Object { $_.IsSystem })) {
            $disk = Get-Disk | Where-Object { $_.Number -eq 0 }
            "select disk $($disk.Number)`nclean`nconvert gpt`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S`ncreate partition msr size=16`ncreate partition primary`nformat quick fs=ntfs label='Windows'`nassign letter=C" | diskpart | Out-Null
        }

        # 2. DRIVER EXPORT (20%)
        if ($chkDriver.IsChecked) {
            $lblStatus.Text = "[2/10] Đang trích xuất Driver máy..."; Update-UI
            $DPath = "$VietBoot\Drivers"; if (!(Test-Path $DPath)) { New-Item $DPath -ItemType Directory -Force | Out-Null }
            dism /online /export-driver /destination:"$DPath" | Out-Null
        }
        $pgBar.Value = 20; Update-UI

        # 3. BITLOCKER (30%)
        $lblStatus.Text = "[3/10] Đang giải mã BitLocker..."; Update-UI
        manage-bde -off C: | Out-Null
        while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 1 }
        $pgBar.Value = 30; Update-UI

        # 4. WIMLIB ENGINE (40%)
        $WimlibExe = "$VietBoot\wimlib-imagex.exe"
        if (!(Test-Path $WimlibExe)) {
            $lblStatus.Text = "[4/10] Đang nạp lõi xử lý..."; Update-UI
            Start-BitsTransfer -Source "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip" -Destination "$VietBoot\w.zip"
            powershell -c "Expand-Archive '$VietBoot\w.zip' '$VietBoot\wim' -Force"
            Copy-Item "$VietBoot\wim\*\wimlib-imagex.exe" $WimlibExe -Force
        }
        $pgBar.Value = 40; Update-UI

        # 5. XỬ LÝ FILE CÀI (70%)
        $lblStatus.Text = "[5/10] Đang nạp bộ cài vào vùng đệm..."; Update-UI
        $FinalWim = ""; $WimName = ""
        if ($SelPath.EndsWith(".iso")) {
            $m = Mount-DiskImage -ImagePath $SelPath -PassThru; $dv = ($m | Get-Volume).DriveLetter
            $src = "$dv`:\sources\install.wim"; if (!(Test-Path $src)) { $src = "$dv`:\sources\install.esd" }
            $WimName = [System.IO.Path]::GetFileName($src); $FinalWim = "$VietBoot\$WimName"
            Copy-Item $src $FinalWim -Force; Dismount-DiskImage -ImagePath $SelPath | Out-Null
        } else {
            $WimName = [System.IO.Path]::GetFileName($SelPath); $FinalWim = "$VietBoot\$WimName"
            if (!(Test-Path $FinalWim)) { Copy-Item $SelPath $FinalWim -Force }
        }
        $pgBar.Value = 70; Update-UI

        # 6. WINRE & KỊCH BẢN (90%)
        $lblStatus.Text = "[6/10] Tiêm kịch bản tự động hóa..."; Update-UI
        $BootWim = "$VietBoot\boot.wim"; Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" $BootWim -Force
        $Conf = "$VietBoot\Conf"; New-Item $Conf -ItemType Directory -Force | Out-Null
        
        # SetupComplete
        $sc = "@echo off`nmanage-bde -off C:`nnet accounts /maxpwage:unlimited`n"
        if ($chkActive.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /HWID`n" }
        $sc += "bcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$Conf\SetupComplete.cmd" -Encoding ASCII

        # Unattend (Silent OOBE)
        $u = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>false</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE></component></settings></unattend>
"@
        $u | Out-File "$Conf\u.xml" -Encoding UTF8

        # Startnet (Lõi WinPE)
        $sn = "@echo off`nwpeinit`nfor %%i in (C D E F G H I J K L M N O P) do (if exist `"%%i:\VietBoot\$WimName`" set `"W=%%i:\VietBoot\$WimName`")`n"
        $sn += "for /d %%a in (C:\*) do if /i not `"%%~nxa`"==`"VietBoot`" rd /s /q `"%%a`"`ndel /f /q C:\*.*`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$SelIdx /ApplyDir:C:\`n"
        $sn += "reg load HKLM\O_S C:\Windows\System32\config\SOFTWARE`nreg add HKLM\O_S\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f`nreg add HKLM\O_S\Policies\Microsoft\FVE /v PreventDeviceEncryption /t REG_DWORD /d 1 /f`nreg unload HKLM\O_S`n"
        if ($chkDriver.IsChecked) { $sn += "if exist `"C:\VietBoot\Drivers`" dism /Image:C:\ /Add-Driver /Driver:`"C:\VietBoot\Drivers`" /Recurse`n" }
        $sn += "mkdir C:\Windows\Panther >nul & copy X:\Windows\System32\u.xml C:\Windows\Panther\unattend.xml /Y`nmkdir C:\Windows\Setup\Scripts >nul & copy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y`n"
        if ($chkAnydesk.IsChecked) {
            "@echo off`ncurl.exe -L -o `"C:\Users\Public\Desktop\AnyDesk.exe`" `"https://download.anydesk.com/AnyDesk.exe`"`nstart `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`ndel `"%~f0`"" | Out-File "$Conf\Any.cmd" -Encoding ASCII
            $sn += "mkdir `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup`" >nul & copy X:\Windows\System32\Any.cmd `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Any.cmd`" /Y`n"
        }
        $sn += "bcdboot C:\Windows /s C: /f ALL`nwpeutil reboot"
        $sn | Out-File "$Conf\s.cmd" -Encoding ASCII

        # Tiêm lõi bằng Wimlib
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$VietBoot\boot.sdi" -Force
        $T = "$VietBoot\t.txt"
        "add `"$Conf\u.xml`" `"\Windows\System32\u.xml`"`nadd `"$Conf\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$Conf\s.cmd`" `"\Windows\System32\startnet.cmd`"" | Out-File $T -Encoding utf8
        Start-Process $WimlibExe "update `"$BootWim`" 1 < `"$T`"" -Wait -WindowStyle Hidden

        # 7. BOOT & REBOOT (100%)
        $pgBar.Value = 100; $lblStatus.Text = "Hoàn tất! Đang khởi động lại..."; Update-UI
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VB" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        Start-Sleep -Seconds 2; Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $_"); $btnStart.IsEnabled = $true }
})

$CuaSo.ShowDialog() | Out-Null