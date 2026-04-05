# ==============================================================================
# VIETTOOLBOX V33 - PROFESSIONAL DEPLOYMENT SUITE (TAB-BASED GUI)
# Tính năng: Full Option, Kill BitLocker, Auto Active, Winget, Driver Injection.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN XAML (TAB CONTROL) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V33 - Professional Deployment" Height="750" Width="700" 
        WindowStartupLocation="CenterScreen" Background="#0A0A0A">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="VIETTOOLBOX V33" FontSize="32" FontWeight="Black" Foreground="#00adb5"/>
            <TextBlock Text="HỆ THỐNG TRIỂN KHAI WINDOWS TỰ ĐỘNG TOÀN DIỆN" FontSize="12" Foreground="#555"/>
        </StackPanel>

        <TabControl Grid.Row="1" Background="#111" BorderBrush="#333">
            <TabControl.Resources>
                <Style TargetType="TabItem">
                    <Setter Property="Background" Value="#222"/><Setter Property="Foreground" Value="#AAA"/>
                    <Setter Property="Padding" Value="15,8"/><Setter Property="FontWeight" Value="Bold"/>
                </Style>
            </TabControl.Resources>

            <TabItem Header="1. BỘ CÀI &amp; NGUỒN">
                <StackPanel Margin="20">
                    <TextBlock Text="Nguồn bộ cài Windows (.iso, .wim, .esd):" Foreground="#888" Margin="0,0,0,5"/>
                    <Grid Margin="0,0,0,15">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                        <TextBox Name="txtWim" Background="#000" Foreground="White" IsReadOnly="True" Height="35" Padding="10,8"/>
                        <Button Name="btnWim" Grid.Column="1" Content="CHỌN FILE" Background="#00adb5" Foreground="White" Margin="10,0,0,0"/>
                    </Grid>
                    
                    <TextBlock Text="Chọn phiên bản Windows (Index):" Foreground="#888" Margin="0,0,0,5"/>
                    <ComboBox Name="cmbIndex" Height="35" Margin="0,0,0,20" Background="#000" Foreground="White"/>
                    
                    <TextBlock Text="Ổ đĩa cài đặt (Mặc định C:):" Foreground="#888" Margin="0,0,0,5"/>
                    <ComboBox Name="cmbDrive" Height="35" Background="#000" Foreground="White">
                        <ComboBoxItem Content="C:\" IsSelected="True"/>
                    </ComboBox>
                </StackPanel>
            </TabItem>

            <TabItem Header="2. DRIVER &amp; MẠNG">
                <StackPanel Margin="20">
                    <CheckBox Name="chkWifiBackup" Content="Sao lưu &amp; Khôi phục Wi-Fi hiện tại" Foreground="#E91E63" IsChecked="True" Margin="0,0,0,10" FontSize="14"/>
                    <CheckBox Name="chkAutoDriver" Content="Tự động Export &amp; Inject Driver hệ thống" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,15" FontSize="14"/>
                    
                    <TextBlock Text="Thư mục Driver bổ sung (Tùy chọn):" Foreground="#888" Margin="0,0,0,5"/>
                    <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                        <TextBox Name="txtDriver" Background="#000" Foreground="White" IsReadOnly="True" Height="35" Padding="10,8"/>
                        <Button Name="btnDriver" Grid.Column="1" Content="CHỌN THƯ MỤC" Background="#333" Foreground="White" Margin="10,0,0,0"/>
                    </Grid>
                </StackPanel>
            </TabItem>

            <TabItem Header="3. TỰ ĐỘNG HÓA">
                <UniformGrid Columns="2" Margin="20">
                    <StackPanel Margin="5">
                        <CheckBox Name="chkKillBitLocker" Content="Vô hiệu hóa BitLocker" Foreground="#FFB300" IsChecked="True" FontWeight="Bold" Margin="0,0,0,10"/>
                        <CheckBox Name="chkOOBE" Content="Bypass OOBE / NRO" Foreground="#FFF" IsChecked="True" Margin="0,0,0,10"/>
                        <CheckBox Name="chkAnydesk" Content="Tự cài AnyDesk" Foreground="#4CAF50" IsChecked="True" Margin="0,0,0,10"/>
                    </StackPanel>
                    <StackPanel Margin="5">
                        <CheckBox Name="chkActiveWin" Content="Auto Active Windows" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,10"/>
                        <CheckBox Name="chkActiveOffice" Content="Auto Active Office" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,10"/>
                        <CheckBox Name="chkShortcut" Content="Tạo Shortcut Desktop" Foreground="#FFF" IsChecked="True"/>
                    </StackPanel>
                </UniformGrid>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="2" Margin="0,15,0,0">
            <ProgressBar Name="pgBar" Height="10" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng thực hiện." Foreground="#666" HorizontalAlignment="Center" FontSize="11" Margin="0,0,0,10"/>
            <Button Name="btnStart" Content="KÍCH HOẠT QUY TRÌNH TỰ ĐỘNG" Height="60" Background="#D32F2F" Foreground="White" FontWeight="Bold" FontSize="18" IsEnabled="False"/>
        </StackPanel>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim")
$txtDriver = $CuaSo.FindName("txtDriver"); $btnDriver = $CuaSo.FindName("btnDriver"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$chkBitLocker = $CuaSo.FindName("chkKillBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE")
$chkAnydesk = $CuaSo.FindName("chkAnydesk"); $chkWifiBackup = $CuaSo.FindName("chkWifiBackup")
$chkAutoDriver = $CuaSo.FindName("chkAutoDriver"); $chkActiveWin = $CuaSo.FindName("chkActiveWin")
$chkActiveOffice = $CuaSo.FindName("chkActiveOffice"); $chkShortcut = $CuaSo.FindName("chkShortcut")
$pgBar = $CuaSo.FindName("pgBar"); $lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

# --- LOGIC CHỌN FILE ---
$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "Windows Image|*.wim;*.esd;*.swm;*.iso"
    if ($fd.ShowDialog()) {
        $path = $fd.FileName; $ext = [System.IO.Path]::GetExtension($path).ToLower()
        $cmbIndex.Items.Clear()
        if ($ext -eq ".iso") {
            $lblStatus.Text = "Đang quét ISO..."; LamMoi-GiaoDien
            $m = Mount-DiskImage -ImagePath $path -PassThru; $dv = ($m | Get-Volume).DriveLetter; $w = "$dv`:\sources\install.wim"
            if (!(Test-Path $w)) { $w = "$dv`:\sources\install.esd" }
            (Get-WindowsImage -ImagePath $w) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
            Dismount-DiskImage -ImagePath $path | Out-Null
        } else {
            (Get-WindowsImage -ImagePath $path) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
        }
        $txtWim.Text = $path; if ($cmbIndex.Items.Count -gt 0) { $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true }
        $lblStatus.Text = "Đã nhận bộ cài."
    }
})

$btnDriver.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath } })

# --- THỰC THI CHÍNH ---
$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; $bootDir = "C:\VietBoot"
    if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }

    try {
        # 1. KILL BITLOCKER TRƯỚC CÀI
        $lblStatus.Text = "Đang kiểm tra BitLocker hiện tại..."; LamMoi-GiaoDien
        manage-bde -off C: | Out-Null
        while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 2 }

        # 2. BACKUP WIFI & AUTO DRIVER
        if ($chkWifiBackup.IsChecked -or $chkAutoDriver.IsChecked) {
            $lblStatus.Text = "Đang Backup Driver & Wifi..."; LamMoi-GiaoDien
            $bk = "$bootDir\Backup"; New-Item "$bk\Drivers" -ItemType Directory -Force | Out-Null
            if ($chkWifiBackup.IsChecked) {
                New-Item "$bk\Wifi" -ItemType Directory -Force | Out-Null
                cmd.exe /c "netsh wlan export profile key=clear folder=`"$bk\Wifi`"" | Out-Null
            }
            if ($chkAutoDriver.IsChecked) {
                Start-Process dism.exe "/online /export-driver /destination:`"$bk\Drivers`"" -Wait -WindowStyle Normal
            }
        }

        # 3. CHUYỂN BỘ CÀI (CHỐNG TREO)
        $wimPath = $txtWim.Text; $wimName = [System.IO.Path]::GetFileName($wimPath)
        if ($wimPath.EndsWith(".iso")) {
            $lblStatus.Text = "Đang chép ISO vào vùng an toàn..."; LamMoi-GiaoDien
            $m = Mount-DiskImage -ImagePath $wimPath -PassThru; $dv = ($m | Get-Volume).DriveLetter
            $src = "$dv`:\sources\install.wim"; if (!(Test-Path $src)) { $src = "$dv`:\sources\install.esd" }
            $wimName = [System.IO.Path]::GetFileName($src); $target = "$bootDir\$wimName"
            Start-Process cmd.exe "/c copy /Y `"$src`" `"$target`"" -Wait -WindowStyle Normal
            Dismount-DiskImage -ImagePath $wimPath | Out-Null; $wimPath = $target
        }

        # 4. TẠO CẤU HÌNH HẬU CÀI ĐẶT (SETUPCOMPLETE.CMD)
        $temp = "$bootDir\Config"; New-Item $temp -ItemType Directory -Force | Out-Null
        
        $sc = "@echo off`n"
        if ($chkBitLocker.IsChecked) { $sc += "manage-bde -off C:`n" }
        $sc += "powershell -NoProfile -Command `"Set-LocalUser -Name 'Admin' -PasswordNeverExpires `$true`"`n"
        
        # Auto Active Windows/Office (KMS/MAS One-liners)
        if ($chkActiveWin.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /HWID`n" }
        if ($chkActiveOffice.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /Ohook`n" }
        
        # Shortcut Desktop
        if ($chkShortcut.IsChecked) {
            $sc += "powershell -c `"`$s=(New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\VietToolbox.lnk');`$s.TargetPath='C:\Windows\System32\cmd.exe';`$s.Save()`"`n"
        }

        # Restore Wifi
        $sc += "if exist `"C:\Windows\Setup\Scripts\Wifi\*.xml`" (for %%f in (`"C:\Windows\Setup\Scripts\Wifi\*.xml`") do netsh wlan add profile filename=`"%%f`" user=all >nul)`n"
        $sc += "bcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$temp\SetupComplete.cmd" -Encoding ASCII

        # 5. UNATTEND.XML (ADMIN, AUTO LOGON, OOBE)
        @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE>
<UserAccounts><LocalAccounts><LocalAccount action="Add"><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts>
<AutoLogon><Enabled>true</Enabled><Username>Admin</Username></AutoLogon></component></settings></unattend>
"@ | Out-File "$temp\unattend.xml" -Encoding UTF8

        # 6. STARTNET.CMD (LOGIC TRONG WINPE)
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $startnet = @"
@echo off
wpeinit
set "WIM_NAME=$wimName"
for %%i in (C D E F G H I J K L M N O P) do (if exist "%%i:\VietBoot\%WIM_NAME%" set "W_PATH=%%i:\VietBoot\%WIM_NAME%")
echo [LOG] Dang xoa rac o C...
for /d %%a in (C:\*) do if /i not "%%~nxa"=="VietBoot" rd /s /q "%%a"
del /f /q C:\*.*
echo [LOG] Dang bung file WIM...
dism /Apply-Image /ImageFile:"%W_PATH%" /Index:$idx /ApplyDir:C:\
echo [LOG] Injecting Driver & Registry...
reg load HKLM\Off_Soft C:\Windows\System32\config\SOFTWARE
reg add HKLM\Off_Soft\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
reg add HKLM\Off_Soft\Policies\Microsoft\FVE /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
reg unload HKLM\Off_Soft
mkdir C:\Windows\Panther >nul
copy X:\Windows\System32\unattend.xml C:\Windows\Panther\unattend.xml /Y
mkdir C:\Windows\Setup\Scripts >nul
copy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y
if exist "C:\VietBoot\Backup\Wifi" (
    mkdir C:\Windows\Setup\Scripts\Wifi >nul
    xcopy "C:\VietBoot\Backup\Wifi\*.xml" "C:\Windows\Setup\Scripts\Wifi\" /Y >nul
)
if exist "C:\VietBoot\Backup\Drivers" dism /Image:C:\ /Add-Driver /Driver:"C:\VietBoot\Backup\Drivers" /Recurse
bcdboot C:\Windows /s C: /f ALL
wpeutil reboot
"@
        $startnet | Out-File "$temp\startnet.cmd" -Encoding ASCII

        # 7. NHÚNG KỊCH BẢN VÀO WINRE
        $lblStatus.Text = "Đang nhúng lõi tự động hóa..."; LamMoi-GiaoDien
        Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" "$bootDir\boot.wim" -Force
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$bootDir\boot.sdi" -Force
        
        # Tải Wimlib nếu chưa có
        if (!(Test-Path "$bootDir\wimlib-imagex.exe")) {
            curl.exe -L -o "$bootDir\wimlib.zip" "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip"
            powershell -NoProfile -Command "Expand-Archive -Path '$bootDir\wimlib.zip' -DestinationPath '$bootDir\wimlib' -Force"
            Copy-Item "$bootDir\wimlib\*\wimlib-imagex.exe" "$bootDir\wimlib-imagex.exe" -Force
        }

        "add `"$temp\unattend.xml`" `"\Windows\System32\unattend.xml`"`nadd `"$temp\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$temp\startnet.cmd`" `"\Windows\System32\startnet.cmd`"" | Out-File "$bootDir\tiem.txt" -Encoding utf8
        Start-Process "$bootDir\wimlib-imagex.exe" "update `"$bootDir\boot.wim`" 1 < `"$bootDir\tiem.txt`"" -Wait -WindowStyle Hidden

        # 8. THIẾT LẬP BOOT & REBOOT
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VietBoot" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietToolbox Installer" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        
        $lblStatus.Text = "HOÀN TẤT! Khởi động lại sau 3 giây..."; LamMoi-GiaoDien
        Start-Sleep -Seconds 3
        Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $_"); $btnStart.IsEnabled = $true }
})

$CuaSo.ShowDialog() | Out-Null