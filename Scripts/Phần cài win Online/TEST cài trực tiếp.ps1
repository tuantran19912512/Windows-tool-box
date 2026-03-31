# ==============================================================================
# VIETTOOLBOX V28 - ULTIMATE FULL OPTIONS (WINTOHDD ARCHITECTURE)
# Tính năng: Auto-Unattend (Bỏ qua OOBE), Silent Boot, Driver Inject, BitLocker Fix
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN WPF MODERN ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V28 - Ultimate Edition" Height="680" Width="640" 
        WindowStartupLocation="CenterScreen" Background="#0A0A0A">
    <Window.Resources>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="35"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
        <Style x:Key="ModernTxt" TargetType="TextBox">
            <Setter Property="Background" Value="#111"/><Setter Property="Foreground" Value="White"/><Setter Property="BorderBrush" Value="#333"/><Setter Property="VerticalContentAlignment" Value="Center"/><Setter Property="Padding" Value="8,0"/>
        </Style>
    </Window.Resources>

    <Grid Margin="25">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="VIETTOOLBOX ULTIMATE V28" FontSize="28" FontWeight="Black" Foreground="#00adb5"/>
            <TextBlock Text="CONG CU CAI DAT TU DONG - UNATTENDED SYSTEM" FontSize="11" Foreground="#555"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Margin="0,0,0,12">
            <TextBlock Text="Tep tin Windows (.wim):" Foreground="#888" Margin="0,0,0,4"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                <TextBox Name="txtWim" Style="{StaticResource ModernTxt}" IsReadOnly="True" Height="32"/>
                <Button Name="btnWim" Grid.Column="1" Content="CHON WIM" Style="{StaticResource ModernBtn}" Margin="10,0,0,0"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,12">
            <TextBlock Text="Tep tin Cuu ho (WinRE.wim):" Foreground="#888" Margin="0,0,0,4"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                <TextBox Name="txtRe" Style="{StaticResource ModernTxt}" IsReadOnly="True" Height="32"/>
                <Button Name="btnRe" Grid.Column="1" Content="CHON RE" Style="{StaticResource ModernBtn}" Margin="10,0,0,0" Background="#333"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="3" Margin="0,0,0,12">
            <TextBlock Text="Thu muc Driver (Tuy chon):" Foreground="#888" Margin="0,0,0,4"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                <TextBox Name="txtDriver" Style="{StaticResource ModernTxt}" IsReadOnly="True" Height="32"/>
                <Button Name="btnDriver" Grid.Column="1" Content="CHON DRV" Style="{StaticResource ModernBtn}" Margin="10,0,0,0" Background="#333"/></Grid>
        </StackPanel>

        <Grid Grid.Row="4" Margin="0,5,0,20">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel><TextBlock Text="Phien ban muon cai:" Foreground="#888"/><ComboBox Name="cmbIndex" Height="32" Width="320" HorizontalAlignment="Left" Margin="0,4,0,0"/></StackPanel>
            <StackPanel Grid.Column="1" VerticalAlignment="Bottom">
                <CheckBox Name="chkOOBE" Content="Bo qua chao mung (OOBE)" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,5"/>
                <CheckBox Name="chkBitLocker" Content="Doi tat BitLocker" Foreground="#FFB300" IsChecked="True"/>
            </StackPanel>
        </Grid>

        <StackPanel Grid.Row="5">
            <ProgressBar Name="pgBar" Height="8" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/>
            <TextBlock Name="lblStatus" Text="Trang thai: San sang." Foreground="#666" HorizontalAlignment="Center" FontSize="11"/>
        </StackPanel>

        <Button Name="btnStart" Grid.Row="7" Content="BAT DAU CAI DAT (FULL OPTIONS)" Style="{StaticResource ModernBtn}" Height="60" Background="#D32F2F" FontSize="18"/>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim"); $txtRe = $CuaSo.FindName("txtRe"); $btnRe = $CuaSo.FindName("btnRe")
$txtDriver = $CuaSo.FindName("txtDriver"); $btnDriver = $CuaSo.FindName("btnDriver"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$chkBitLocker = $CuaSo.FindName("chkBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE"); $pgBar = $CuaSo.FindName("pgBar"); $lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

$btnStart.IsEnabled = $false

function Refresh-UI { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

# --- LOGIC SELECTION ---
$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; if ($fd.ShowDialog()) {
        $txtWim.Text = $fd.FileName; $cmbIndex.Items.Clear()
        (Get-WindowsImage -ImagePath $fd.FileName) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
        $cmbIndex.SelectedIndex = 0; if ($txtRe.Text) { $btnStart.IsEnabled = $true }
    }
})
$btnRe.Add_Click({ $fd = New-Object Microsoft.Win32.OpenFileDialog; if ($fd.ShowDialog()) { $txtRe.Text = $fd.FileName; if ($txtWim.Text) { $btnStart.IsEnabled = $true } } })
$btnDriver.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath } })

# --- TIẾN TRÌNH THỰC THI ---
$btnStart.Add_Click({
    if ([System.Windows.MessageBox]::Show("Toan bo du lieu o C se bi xoa. Tiep tuc?", "Xac nhan", 4, 48) -ne 'Yes') { return }
    $btnStart.IsEnabled = $false

    try {
        # 1. BitLocker Check (Giống WinToHDD Legacy Mode)
        if ($chkBitLocker.IsChecked) {
            $lblStatus.Text = "Dang giai ma BitLocker (Tranh loi 0xED)..."; Refresh-UI
            manage-bde -off C: | Out-Null
            while ($true) {
                $st = manage-bde -status C:
                if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }
                Start-Sleep -Seconds 3; Refresh-UI
            }
        }

        # 2. Tạo cấu trúc thư mục
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $txtWim.Text; $reSource = $txtRe.Text; $tenWim = [System.IO.Path]::GetFileName($wim)
        $bootDir = "C:\VietBoot"; if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
        
        $lblStatus.Text = "Dang copy tep moi Boot..."; Refresh-UI
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$bootDir\boot.sdi" -Force -ErrorAction SilentlyContinue

        $mount = "C:\MountTemp"; if (Test-Path $mount) { Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -Wait -WindowStyle Hidden }
        New-Item $mount -ItemType Directory -Force | Out-Null
        Copy-Item $reSource "$bootDir\boot.wim" -Force
        
        $lblStatus.Text = "Dang Mount WinRE de thiet lap Unattended..."; $pgBar.Value = 30; Refresh-UI
        Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mount" -Wait -WindowStyle Hidden
        
        # --- BƯỚC 3: TẠO FILE UNATTEND.XML (BỎ QUA OOBE) ---
        $unattendContent = ""
        if ($chkOOBE.IsChecked) {
            $unattendContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount action="Add">
                        <Password><Value></Value><PlainText>true</PlainText></Password>
                        <Description>Admin</Description>
                        <DisplayName>Admin</DisplayName>
                        <Group>Administrators</Group>
                        <Name>Admin</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password><Value></Value><PlainText>true</PlainText></Password>
                <Enabled>true</Enabled>
                <Username>Admin</Username>
            </AutoLogon>
        </component>
    </settings>
</unattend>
"@
        }

        # --- BƯỚC 4: TẠO STARTNET.CMD (GIỐNG WINTOHDD LOADER) ---
        $driverCmd = ""
        if (![string]::IsNullOrEmpty($txtDriver.Text)) { 
            Copy-Item -Path "$($txtDriver.Text)\*" -Destination "$bootDir\Drivers" -Recurse -Force
            $driverCmd = "dism /Image:C:\ /Add-Driver /Driver:X:\VietBoot\Drivers /Recurse >nul"
        }

        $oobeCmd = if ($chkOOBE.IsChecked) { "echo $unattendContent > C:\Windows\Panther\unattend.xml" } else { "" }

        $cmd = @"
@echo off
wpeinit
cls
echo DANG TIM TEP $tenWim...
for %%i in (C D E F G H I J K L M N O P Q R S T U V) do (if exist "%%i:\$tenWim" (set WIM_PATH=%%i:\$tenWim))
echo [1/4] Dang format o C...
format C: /fs:ntfs /q /y >nul
echo [2/4] Dang bung anh Windows...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\
echo [3/4] Dang tich hop Driver va Unattend...
$driverCmd
mkdir C:\Windows\Panther >nul
$oobeCmd
echo [4/4] Dang tao bootloader...
bcdboot C:\Windows /s C: /f ALL
echo HOAN TAT! TU DONG DON DEP...
mkdir C:\Windows\Setup\Scripts >nul
(echo @echo off
echo for /f "tokens=2 delims={}" %%%%g in ('bcdedit /enum all ^^| findstr /i "VietToolbox"') do (bcdedit /delete {%%%%g} /f)
echo bcdedit /timeout 0
echo rd /s /q "C:\VietBoot"
echo del %%0)>C:\Windows\Setup\Scripts\SetupComplete.cmd
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force

        # --- BỊT MIỆNG BÀN PHÍM (THE WINTOHDD STYLE) ---
        $ini = "[LaunchApps]`nwpeinit.exe`ncmd.exe, /c %SYSTEMROOT%\System32\startnet.cmd"
        $ini | Out-File "$mount\Windows\System32\winpeshl.ini" -Encoding ASCII -Force

        $lblStatus.Text = "Dang luu WinRE (Commit)..."; $pgBar.Value = 80; Refresh-UI
        Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -Wait -WindowStyle Hidden

        # Đăng ký BCD
        $ramGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $ramGuid /d "VietToolbox Options" /device | Out-Null
        bcdedit /set $ramGuid ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ramGuid ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $bootGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $bootGuid /d "VietToolbox Ghost Installer" /application osloader | Out-Null
        bcdedit /set $bootGuid device "ramdisk=[C:]\VietBoot\boot.wim,$ramGuid" | Out-Null
        bcdedit /set $bootGuid osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ramGuid" | Out-Null
        bcdedit /set $bootGuid path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $bootGuid systemroot "\windows" | Out-Null
        bcdedit /set $bootGuid winpe yes | Out-Null
        bcdedit /set $bootGuid detecthal yes | Out-Null
        bcdedit /displayorder $bootGuid /addfirst | Out-Null
        bcdedit /default $bootGuid | Out-Null
        bcdedit /timeout 5 | Out-Null

        $lblStatus.Text = "Xong! Dang Restart..."; $pgBar.Value = 100; Refresh-UI
        Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Loi: $_") }
})

$CuaSo.ShowDialog() | Out-Null