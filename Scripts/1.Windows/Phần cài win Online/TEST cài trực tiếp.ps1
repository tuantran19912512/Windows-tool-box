# ==============================================================================
# VIETTOOLBOX V33.8 - THE GHOST CALLER (ANYDESK AUTO-EXECUTE)
# Tính năng: Full Option, Turbo Robocopy, Auto Active, AnyDesk Call, Smart Bypass.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN BLACKOUT SIÊU TƯƠNG PHẢN ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V33.8 - The Ghost Caller" Height="780" Width="720" 
        WindowStartupLocation="CenterScreen" Background="#000000">
    <Window.Resources>
        <Style TargetType="ComboBoxItem"><Setter Property="Background" Value="#111"/><Setter Property="Foreground" Value="White"/><Setter Property="Padding" Value="10"/></Style>
        <Style TargetType="ComboBox"><Setter Property="Background" Value="#1A1A1A"/><Setter Property="Foreground" Value="#00adb5"/><Setter Property="Height" Value="38"/></Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="#0A0A0A"/><Setter Property="Foreground" Value="#00adb5"/><Setter Property="VerticalContentAlignment" Value="Center"/><Setter Property="Padding" Value="10,0"/></Style>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="40"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="VIETTOOLBOX V33.8" FontSize="36" FontWeight="Black" Foreground="#00adb5"/>
            <TextBlock Text="BẢN ANYDESK AUTO-CALL - TURBO ROBOCPY ENGINE" FontSize="12" Foreground="#888"/>
        </StackPanel>
        <TabControl Grid.Row="1" Background="#050505" BorderBrush="#222">
            <TabItem Header="1. BỘ CÀI &amp; ĐÍCH">
                <StackPanel Margin="25">
                    <TextBlock Text="Nguồn Windows (.iso, .wim, .esd):" Foreground="#AAA" Margin="0,0,0,5"/><Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions><TextBox Name="txtWim" IsReadOnly="True" Height="38"/><Button Name="btnWim" Grid.Column="1" Content="CHỌN FILE" Style="{StaticResource ModernBtn}" Margin="10,0,0,0"/></Grid>
                    <TextBlock Text="Phiên bản cài đặt (Index):" Foreground="#AAA" Margin="0,0,0,5"/><ComboBox Name="cmbIndex" Margin="0,0,0,15"/><TextBlock Text="Ổ đĩa đích:" Foreground="#AAA" Margin="0,0,0,5"/><ComboBox Name="cmbDrive"><ComboBoxItem Content="C:\" IsSelected="True"/></ComboBox>
                </StackPanel>
            </TabItem>
            <TabItem Header="2. DRIVER &amp; WIFI">
                <StackPanel Margin="25">
                    <CheckBox Name="chkAutoDriver" Content="Tự động Export &amp; Inject Driver máy cũ" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,12" FontSize="14"/>
                    <CheckBox Name="chkWifiBackup" Content="Sao lưu &amp; Khôi phục cấu hình Wi-Fi" Foreground="#E91E63" IsChecked="True" Margin="0,0,0,20" FontSize="14"/>
                    <TextBlock Text="Nạp Driver từ thư mục ngoài (Tùy chọn):" Foreground="#AAA" Margin="0,0,0,5"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions><TextBox Name="txtDriver" IsReadOnly="True" Height="38"/><Button Name="btnDriver" Grid.Column="1" Content="CHỌN FOLDER" Style="{StaticResource ModernBtn}" Margin="10,0,0,0" Background="#333"/></Grid>
                </StackPanel>
            </TabItem>
            <TabItem Header="3. TỰ ĐỘNG HÓA">
                <Grid Margin="20"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <CheckBox Name="chkKillBitLocker" Content="Vô hiệu hóa BitLocker" Foreground="#FFB300" IsChecked="True" FontWeight="Bold" Margin="0,0,0,12"/>
                    <CheckBox Name="chkOOBE" Content="Bypass OOBE / NRO" Foreground="White" IsChecked="True" Margin="0,0,0,12"/>
                    <CheckBox Name="chkAnydesk" Content="Tự cài &amp; Bật AnyDesk" Foreground="#4CAF50" IsChecked="True" Margin="0,0,0,12"/>
                    <CheckBox Name="chkShortcut" Content="Tạo Shortcut Desktop" Foreground="White" IsChecked="True"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <CheckBox Name="chkActiveWin" Content="Auto Active Windows (MAS)" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,12"/>
                    <CheckBox Name="chkActiveOffice" Content="Auto Active Office (Ohook)" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,12"/>
                    <CheckBox Name="chkAutoApps" Content="Cài Chrome + WinRAR" Foreground="#FFF" IsChecked="True"/>
                </StackPanel></Grid>
            </TabItem>
        </TabControl>
        <StackPanel Grid.Row="2" Margin="0,15,0,0">
            <ProgressBar Name="pgBar" Height="12" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng." Foreground="#666" HorizontalAlignment="Center" FontSize="11" Margin="0,0,0,10"/>
            <Button Name="btnStart" Content="KÍCH HOẠT QUY TRÌNH MASTER" Style="{StaticResource ModernBtn}" Height="65" Background="#D32F2F" FontSize="20" IsEnabled="False"/>
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

# --- CHỌN FILE ---
$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog()) {
        $path = $fd.FileName; $ext = [System.IO.Path]::GetExtension($path).ToLower()
        $cmbIndex.Items.Clear()
        if ($ext -eq ".iso") {
            $lblStatus.Text = "Đang quét ISO..."; LamMoi-GiaoDien
            $m = Mount-DiskImage -ImagePath $path -PassThru; $dv = ($m | Get-Volume).DriveLetter; $w = "$dv`:\sources\install.wim"
            if (!(Test-Path $w)) { $w = "$dv`:\sources\install.esd" }
            (Get-WindowsImage -ImagePath $w) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
            Dismount-DiskImage -ImagePath $path | Out-Null
        } else { (Get-WindowsImage -ImagePath $path) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") } }
        $txtWim.Text = $path; $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true; $lblStatus.Text = "Sẵn sàng."
    }
})

$btnDriver.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath } })

# --- THỰC THI ---
$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; $bootDir = "C:\VietBoot"; if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }

    try {
        # 1. KILL BITLOCKER HIỆN TẠI
        $lblStatus.Text = "Đang kiểm tra BitLocker hiện tại..."; LamMoi-GiaoDien
        manage-bde -off C: | Out-Null
        while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 2 }

        # 2. SAO LƯU HỆ THỐNG
        $lblStatus.Text = "Đang sao lưu hệ thống..."; $pgBar.Value = 5; LamMoi-GiaoDien
        $bk = "$bootDir\Backup"; New-Item "$bk\Drivers" -ItemType Directory -Force | Out-Null
        if ($chkWifiBackup.IsChecked) { New-Item "$bk\Wifi" -ItemType Directory -Force | Out-Null; cmd.exe /c "netsh wlan export profile key=clear folder=`"$bk\Wifi`"" | Out-Null }
        if ($chkAutoDriver.IsChecked) { Start-Process dism.exe "/online /export-driver /destination:`"$bk\Drivers`"" -Wait -WindowStyle Normal }
        if (![string]::IsNullOrEmpty($txtDriver.Text)) { Copy-Item -Path "$($txtDriver.Text)\*" -Destination "$bk\Drivers" -Recurse -Force }

        # 3. SMART TURBO COPY
        $wimPath = $txtWim.Text; $wimName = [System.IO.Path]::GetFileName($wimPath)
        $isISO = $wimPath.EndsWith(".iso"); $onC = $wimPath.Substring(0,1).ToLower() -eq "c"

        if ($isISO) {
            $m = Mount-DiskImage -ImagePath $wimPath -PassThru; $dv = ($m | Get-Volume).DriveLetter
            $srcPath = "$dv`:\sources"; $srcFile = "install.wim"; if (!(Test-Path "$srcPath\install.wim")) { $srcFile = "install.esd" }
            $wimName = "install_turbo.wim"; $target = "$bootDir\$wimName"; $srcFull = "$srcPath\$srcFile"; $srcSize = (Get-Item $srcFull).Length
            $lblStatus.Text = "Đang Turbo Copy bộ cài (Robocopy /J)..."; LamMoi-GiaoDien
            Start-Process robocopy.exe -ArgumentList "`"$srcPath`" `"$bootDir`" $srcFile /J /IS /IT /MT:16 /NJH /NJS" -WindowStyle Hidden
            while ($true) {
                if (Test-Path $target) {
                    $curSize = (Get-Item $target).Length; $percent = [math]::Round(($curSize / $srcSize) * 100)
                    $pgBar.Value = 10 + ($percent * 0.7); $lblStatus.Text = "Chép bộ cài: $percent%"; LamMoi-GiaoDien
                    if ($curSize -ge $srcSize) { break }
                }
                Start-Sleep -Milliseconds 400
                if (!(Get-Process "robocopy" -ErrorAction SilentlyContinue)) { break }
            }
            Dismount-DiskImage -ImagePath $wimPath | Out-Null; $wimPath = $target
        } elseif (!$onC) {
            $lblStatus.Text = "Bộ cài ổ khác. Chạy thẳng!"; LamMoi-GiaoDien; Start-Sleep -Seconds 1
        } else {
            if ($wimPath -notlike "C:\VietBoot\*") { $lblStatus.Text = "Bảo vệ bộ cài..."; $target = "$bootDir\$wimName"; Copy-Item $wimPath $target -Force }
        }

        # 4. CHUẨN BỊ KỊCH BẢN (FIX ANYDESK AUTO-CALL)
        $temp = "$bootDir\Conf"; New-Item $temp -ItemType Directory -Force | Out-Null
        
        # SetupComplete.cmd
        $sc = "@echo off`n"
        if ($chkBitLocker.IsChecked) { $sc += "manage-bde -off C:`n" }
        $sc += "powershell -c `"Set-LocalUser -Name 'Admin' -PasswordNeverExpires `$true`"`n"
        if ($chkActiveWin.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /HWID`n" }
        if ($chkActiveOffice.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /Ohook`n" }
        if ($chkAutoApps.IsChecked) { $sc += "winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements`nwinget install --id WinRAR.WinRAR --silent`n" }
        if ($chkShortcut.IsChecked) { $sc += "powershell -c `"`$s=(New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\VietToolbox.lnk');`$s.TargetPath='C:\Windows\System32\cmd.exe';`$s.Save()`"`n" }
        $sc += "if exist `"C:\Windows\Setup\Scripts\Wifi\*.xml`" (for %%f in (`"C:\Windows\Setup\Scripts\Wifi\*.xml`") do netsh wlan add profile filename=`"%%f`" user=all >nul)`nbcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$temp\SetupComplete.cmd" -Encoding ASCII

        # Any.cmd - Tải và Tự động Bật AnyDesk
        if ($chkAnydesk.IsChecked) {
            $any = "@echo off`ntitle Cai dat AnyDesk`n:check`nping 8.8.8.8 -n 1 >nul`nif errorlevel 1 timeout /t 3 >nul & goto check`ncurl.exe -L -o `"C:\Users\Public\Desktop\AnyDesk.exe`" `"https://download.anydesk.com/AnyDesk.exe`"`necho Dang bat AnyDesk...`nstart `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`ndel `"%~f0`""
            $any | Out-File "$temp\Any.cmd" -Encoding ASCII
        }

        # Unattend.xml
        @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE><UserAccounts><LocalAccounts><LocalAccount action="Add"><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts><AutoLogon><Enabled>true</Enabled><Username>Admin</Username></AutoLogon></component></settings></unattend>
"@ | Out-File "$temp\u.xml" -Encoding UTF8

        # 5. STARTNET (WINPE ENGINE)
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $sn = @"
@echo off
wpeinit
for %%i in (C D E F G H I J K L M N O P) do (if exist "%%i:\VietBoot\$wimName" set "W=%%i:\VietBoot\$wimName" & if exist "%%i:\$wimName" set "W=%%i:\$wimName")
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

        # 6. NHÚNG KỊCH BẢN (WIMLIB)
        $lblStatus.Text = "Đang nhúng kịch bản tự động..."; $pgBar.Value = 90; LamMoi-GiaoDien
        Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" "$bootDir\boot.wim" -Force
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$bootDir\boot.sdi" -Force
        if (!(Test-Path "$bootDir\wimlib-imagex.exe")) {
            curl.exe -L -o "$bootDir\w.zip" "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip"
            powershell -c "Expand-Archive '$bootDir\w.zip' '$bootDir\wim' -f"; Copy-Item "$bootDir\wim\*\wimlib-imagex.exe" "$bootDir\wimlib-imagex.exe" -Force
        }
        $tiem = "add `"$temp\u.xml`" `"\Windows\System32\u.xml`"`nadd `"$temp\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$temp\s.cmd`" `"\Windows\System32\startnet.cmd`""
        if ($chkAnydesk.IsChecked) { $tiem += "`nadd `"$temp\Any.cmd`" `"\Windows\System32\Any.cmd`"" }
        $tiem | Out-File "$bootDir\t.txt" -Encoding utf8
        Start-Process "$bootDir\wimlib-imagex.exe" "update `"$bootDir\boot.wim`" 1 < `"$bootDir\t.txt`"" -Wait -WindowStyle Hidden

        # 7. BOOT SETUP & REBOOT
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VB" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        $lblStatus.Text = "XONG! Khởi động lại sau 2s..."; $pgBar.Value = 100; LamMoi-GiaoDien
        Start-Sleep -Seconds 2; Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $_"); $btnStart.IsEnabled = $true }
})

$CuaSo.ShowDialog() | Out-Null