# ==============================================================================
# VIETTOOLBOX V33.2 - TRIPLE FIX (FIX TYPO + FIX COLOR + FIX BITLOCKER)
# Tính năng: Full Giáp, Chống lóa ComboBox, Sửa lỗi "File Not Found", Auto Active.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN SIÊU TƯƠNG PHẢN (FIX LỖI CHỮ TRẮNG TRÊN NỀN TRẮNG) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V33.2 - Triple Fix Edition" Height="780" Width="720" 
        WindowStartupLocation="CenterScreen" Background="#000000">
    <Window.Resources>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#111111"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="5"/><Setter Property="BorderThickness" Value="0,0,0,1"/><Setter Property="BorderBrush" Value="#222"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#1A1A1A"/><Setter Property="Foreground" Value="#00adb5"/>
            <Setter Property="BorderBrush" Value="#333"/><Setter Property="Height" Value="38"/><Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#0A0A0A"/><Setter Property="Foreground" Value="#00adb5"/>
            <Setter Property="BorderBrush" Value="#333"/><Setter Property="VerticalContentAlignment" Value="Center"/><Setter Property="Padding" Value="10,0"/>
        </Style>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="40"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>
    
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="VIETTOOLBOX V33.2" FontSize="36" FontWeight="Black" Foreground="#00adb5"/>
            <TextBlock Text="FIX LỖI HIỂN THỊ &amp; LỖI HỆ THỐNG - FULL TỰ ĐỘNG" FontSize="12" Foreground="#888"/>
        </StackPanel>

        <TabControl Grid.Row="1" Background="#050505" BorderBrush="#222">
            <TabControl.Resources>
                <Style TargetType="TabItem">
                    <Setter Property="Background" Value="#111"/><Setter Property="Foreground" Value="#AAA"/><Setter Property="Padding" Value="20,10"/><Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="TabItem">
                                <Border Name="Border" Background="{TemplateBinding Background}" BorderThickness="0,0,0,3" BorderBrush="Transparent" Margin="2,0">
                                    <ContentPresenter ContentSource="Header" Margin="10,2"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter TargetName="Border" Property="Background" Value="#1A1A1A"/><Setter TargetName="Border" Property="BorderBrush" Value="#00adb5"/><Setter Property="Foreground" Value="#00adb5"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </TabControl.Resources>

            <TabItem Header="1. BỘ CÀI &amp; ĐÍCH">
                <StackPanel Margin="25">
                    <TextBlock Text="Nguồn Windows (.iso, .wim, .esd):" Foreground="#AAA" Margin="0,0,0,8"/>
                    <Grid Margin="0,0,0,20">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                        <TextBox Name="txtWim" IsReadOnly="True" Height="38"/>
                        <Button Name="btnWim" Grid.Column="1" Content="CHỌN FILE" Style="{StaticResource ModernBtn}" Margin="10,0,0,0"/>
                    </Grid>
                    <TextBlock Text="Phiên bản cài đặt (Index):" Foreground="#AAA" Margin="0,0,0,8"/>
                    <ComboBox Name="cmbIndex" Margin="0,0,0,20"/>
                    <TextBlock Text="Ổ đĩa đích (Mặc định C:):" Foreground="#AAA" Margin="0,0,0,8"/>
                    <ComboBox Name="cmbDrive"><ComboBoxItem Content="C:\" IsSelected="True"/></ComboBox>
                </StackPanel>
            </TabItem>

            <TabItem Header="2. DRIVER &amp; MẠNG">
                <StackPanel Margin="25">
                    <CheckBox Name="chkAutoDriver" Content="Tự động Export &amp; Inject Driver máy cũ" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,15" FontSize="14"/>
                    <CheckBox Name="chkWifiBackup" Content="Sao lưu &amp; Khôi phục cấu hình Wi-Fi" Foreground="#E91E63" IsChecked="True" Margin="0,0,0,25" FontSize="14"/>
                    <TextBlock Text="Nạp Driver từ thư mục ngoài (Tùy chọn):" Foreground="#AAA" Margin="0,0,0,8"/>
                    <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                    <TextBox Name="txtDriver" IsReadOnly="True" Height="38"/>
                    <Button Name="btnDriver" Grid.Column="1" Content="CHỌN THƯ MỤC" Style="{StaticResource ModernBtn}" Margin="10,0,0,0" Background="#333"/></Grid>
                </StackPanel>
            </TabItem>

            <TabItem Header="3. TỰ ĐỘNG HÓA">
                <Grid Margin="25"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <CheckBox Name="chkKillBitLocker" Content="Vô hiệu hóa BitLocker" Foreground="#FFB300" IsChecked="True" FontWeight="Bold" Margin="0,0,0,15"/>
                    <CheckBox Name="chkOOBE" Content="Bypass OOBE / NRO" Foreground="White" IsChecked="True" Margin="0,0,0,15"/>
                    <CheckBox Name="chkAnydesk" Content="Tự động nạp AnyDesk" Foreground="#4CAF50" IsChecked="True" Margin="0,0,0,15"/>
                    <CheckBox Name="chkShortcut" Content="Tạo Shortcut Desktop" Foreground="White" IsChecked="True"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <CheckBox Name="chkActiveWin" Content="Auto Active Windows (MAS)" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,15"/>
                    <CheckBox Name="chkActiveOffice" Content="Auto Active Office (Ohook)" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,15"/>
                    <CheckBox Name="chkAutoApps" Content="Auto cài App (Chrome, WinRAR)" Foreground="#FFF" IsChecked="True"/>
                </StackPanel></Grid>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="2" Margin="0,20,0,0">
            <ProgressBar Name="pgBar" Height="10" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,15"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng." Foreground="#666" HorizontalAlignment="Center" FontSize="11" Margin="0,0,0,15"/>
            <Button Name="btnStart" Content="KÍCH HOẠT QUY TRÌNH TỔNG LỰC" Style="{StaticResource ModernBtn}" Height="65" Background="#D32F2F" FontSize="20"/>
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
$chkAutoApps = $CuaSo.FindName("chkAutoApps"); $pgBar = $CuaSo.FindName("pgBar")
$lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "Windows Image|*.wim;*.esd;*.swm;*.iso"
    if ($fd.ShowDialog()) {
        $path = $fd.FileName; $ext = [System.IO.Path]::GetExtension($path).ToLower()
        $cmbIndex.Items.Clear()
        if ($ext -eq ".iso") {
            $lblStatus.Text = "Đang quét nội dung ISO..."; LamMoi-GiaoDien
            $m = Mount-DiskImage -ImagePath $path -PassThru; $dv = ($m | Get-Volume).DriveLetter; $w = "$dv`:\sources\install.wim"
            if (!(Test-Path $w)) { $w = "$dv`:\sources\install.esd" }
            (Get-WindowsImage -ImagePath $w) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
            Dismount-DiskImage -ImagePath $path | Out-Null
        } else {
            (Get-WindowsImage -ImagePath $path) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
        }
        $txtWim.Text = $path; $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true; $lblStatus.Text = "Đã sẵn sàng bộ cài."
    }
})

$btnDriver.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath } })

$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; $bootDir = "C:\VietBoot"
    if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }

    try {
        # 1. BITLOCKER PRE-CHECK
        $lblStatus.Text = "Đang giải mã BitLocker hiện tại..."; LamMoi-GiaoDien
        manage-bde -off C: | Out-Null
        while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 2 }

        # 2. BACKUP
        $lblStatus.Text = "Đang thực hiện sao lưu..."; LamMoi-GiaoDien
        $bk = "$bootDir\Backup"; New-Item "$bk\Drivers" -ItemType Directory -Force | Out-Null
        if ($chkWifiBackup.IsChecked) { New-Item "$bk\Wifi" -ItemType Directory -Force | Out-Null; cmd.exe /c "netsh wlan export profile key=clear folder=`"$bk\Wifi`"" | Out-Null }
        if ($chkAutoDriver.IsChecked) { Start-Process dism.exe "/online /export-driver /destination:`"$bk\Drivers`"" -Wait -WindowStyle Normal }
        if (![string]::IsNullOrEmpty($txtDriver.Text)) { Copy-Item -Path "$($txtDriver.Text)\*" -Destination "$bk\Drivers" -Recurse -Force }

        # 3. ISO COPY (CHỐNG TREO)
        $wimPath = $txtWim.Text; $wimName = [System.IO.Path]::GetFileName($wimPath)
        if ($wimPath.EndsWith(".iso")) {
            $lblStatus.Text = "Đang chép bộ cài vào vùng an toàn..."; LamMoi-GiaoDien
            $m = Mount-DiskImage -ImagePath $wimPath -PassThru; $dv = ($m | Get-Volume).DriveLetter
            $src = "$dv`:\sources\install.wim"; if (!(Test-Path $src)) { $src = "$dv`:\sources\install.esd" }
            $wimName = "install_viet.wim"; $target = "$bootDir\$wimName"
            $pCopy = Start-Process cmd.exe "/c copy /Y `"$src`" `"$target`"" -PassThru -WindowStyle Normal
            while (!$pCopy.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 500 }
            Dismount-DiskImage -ImagePath $wimPath | Out-Null; $wimPath = $target
        }

        # 4. CONFIG FILES
        $temp = "$bootDir\Conf"; New-Item $temp -ItemType Directory -Force | Out-Null
        $sc = "@echo off`n"
        if ($chkKillBitLocker.IsChecked) { $sc += "manage-bde -off C:`n" }
        $sc += "powershell -c `"Set-LocalUser -Name 'Admin' -PasswordNeverExpires `$true`"`n"
        if ($chkActiveWin.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /HWID`n" }
        if ($chkActiveOffice.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /Ohook`n" }
        if ($chkAutoApps.IsChecked) { $sc += "winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements`nwinget install --id WinRAR.WinRAR --silent`n" }
        if ($chkShortcut.IsChecked) { $sc += "powershell -c `"`$s=(New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\VietToolbox.lnk');`$s.TargetPath='C:\Windows\System32\cmd.exe';`$s.Save()`"`n" }
        $sc += "if exist `"C:\Windows\Setup\Scripts\Wifi\*.xml`" (for %%f in (`"C:\Windows\Setup\Scripts\Wifi\*.xml`") do netsh wlan add profile filename=`"%%f`" user=all >nul)`nbcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$temp\SetupComplete.cmd" -Encoding ASCII

        if ($chkAnydesk.IsChecked) { "@echo off`n:check`nping 8.8.8.8 -n 1 >nul`nif errorlevel 1 timeout /t 3 >nul & goto check`ncurl.exe -L -o `"C:\Users\Public\Desktop\AnyDesk.exe`" `"https://download.anydesk.com/AnyDesk.exe`"`nstart `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`ndel `"%~f0`"" | Out-File "$temp\Any.cmd" -Encoding ASCII }
        
        @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE>
<UserAccounts><LocalAccounts><LocalAccount action="Add"><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts>
<AutoLogon><Enabled>true</Enabled><Username>Admin</Username></AutoLogon></component></settings></unattend>
"@ | Out-File "$temp\u.xml" -Encoding UTF8

        # 5. STARTNET (WINPE ENGINE)
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $sn = @"
@echo off
wpeinit
for %%i in (C D E F G H I J K L M N O P) do (if exist "%%i:\VietBoot\$wimName" set "W=%%i:\VietBoot\$wimName")
for /d %%a in (C:\*) do if /i not "%%~nxa"=="VietBoot" rd /s /q "%%a"
del /f /q C:\*.*
dism /Apply-Image /ImageFile:"%W%" /Index:$idx /ApplyDir:C:\
reg load HKLM\O_S C:\Windows\System32\config\SOFTWARE
reg add HKLM\O_S\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
reg add HKLM\O_S\Policies\Microsoft\FVE /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
reg unload HKLM\O_S
mkdir C:\Windows\Panther >nul & copy X:\Windows\System32\u.xml C:\Windows\Panther\unattend.xml /Y
mkdir C:\Windows\Setup\Scripts >nul & copy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y
if exist "C:\VietBoot\Backup\Wifi" (mkdir C:\Windows\Setup\Scripts\Wifi >nul & xcopy "C:\VietBoot\Backup\Wifi\*.xml" "C:\Windows\Setup\Scripts\Wifi\" /Y)
if exist X:\Windows\System32\Any.cmd (mkdir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" >nul & copy X:\Windows\System32\Any.cmd "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Any.cmd" /Y)
if exist "C:\VietBoot\Backup\Drivers" dism /Image:C:\ /Add-Driver /Driver:"C:\VietBoot\Backup\Drivers" /Recurse
bcdboot C:\Windows /s C: /f ALL
wpeutil reboot
"@
        $sn | Out-File "$temp\s.cmd" -Encoding ASCII

        # 6. NHÚNG LÕI WIMLIB (FIX LỖI TYPO CHI MẠNG)
        $lblStatus.Text = "Đang nhúng kịch bản tự động hóa..."; LamMoi-GiaoDien
        Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" "$bootDir\boot.wim" -Force
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$bootDir\boot.sdi" -Force
        
        $exeWimlib = "$bootDir\wimlib-imagex.exe"
        if (!(Test-Path $exeWimlib)) {
            $lblStatus.Text = "Đang tải Wimlib Engine..."; LamMoi-GiaoDien
            curl.exe -L -o "$bootDir\w.zip" "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip"
            powershell -c "Expand-Archive '$bootDir\w.zip' '$bootDir\wim' -f"
            Copy-Item "$bootDir\wim\*\wimlib-imagex.exe" $exeWimlib -Force
        }

        # FIX TYPO: Đảm bảo tên file trùng khớp 100%
        $fileTiem = "$bootDir\tiem_lenh.txt"
        $noiDungTiem = "add `"$temp\u.xml`" `"\Windows\System32\u.xml`"`nadd `"$temp\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$temp\s.cmd`" `"\Windows\System32\startnet.cmd`""
        if ($chkAnydesk.IsChecked) { $noiDungTiem += "`nadd `"$temp\Any.cmd`" `"\Windows\System32\Any.cmd`"" }
        $noiDungTiem | Out-File $fileTiem -Encoding utf8
        
        # Dùng CMD /C để thực thi lệnh nhúng có dấu ngoặc kép và redirection (<) chuẩn xác
        $cmdNhung = "`"$exeWimlib`" update `"$bootDir\boot.wim`" 1 < `"$fileTiem`""
        Start-Process cmd.exe -ArgumentList "/c $cmdNhung" -Wait -WindowStyle Hidden

        # 7. BOOT SETUP
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VB" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        
        $lblStatus.Text = "XONG! Khởi động lại sau 3s..."; LamMoi-GiaoDien
        Start-Sleep -Seconds 3; Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $_"); $btnStart.IsEnabled = $true }
})

$CuaSo.ShowDialog() | Out-Null