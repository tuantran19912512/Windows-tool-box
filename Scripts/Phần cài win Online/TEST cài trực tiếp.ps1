# ==============================================================================
# VIETTOOLBOX V29 - FINAL REPAIR (FIX HANGING & PERMISSION)
# Fix lỗi: Chớp tắt WinRE, Treo boot.sdi, Sai đường dẫn WIM.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN WPF MODERN (DARK THEME) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V29 - Final Repair" Height="680" Width="640" 
        WindowStartupLocation="CenterScreen" Background="#0A0A0A">
    <Window.Resources>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="35"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="25">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,20"><TextBlock Text="VIETTOOLBOX V29" FontSize="28" FontWeight="Black" Foreground="#00adb5"/><TextBlock Text="FIX TREO COPY BOOT - UNATTENDED SYSTEM" FontSize="11" Foreground="#555"/></StackPanel>
        <StackPanel Grid.Row="1" Margin="0,0,0,12"><TextBlock Text="Tep tin Windows (.wim):" Foreground="#888"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions><TextBox Name="txtWim" Background="#111" Foreground="White" IsReadOnly="True" Height="32" Padding="8,0"/><Button Name="btnWim" Grid.Column="1" Content="CHON WIM" Style="{StaticResource ModernBtn}" Margin="10,0,0,0"/></Grid></StackPanel>
        <StackPanel Grid.Row="2" Margin="0,0,0,12"><TextBlock Text="Tep tin Cuu ho (WinRE.wim):" Foreground="#888"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions><TextBox Name="txtRe" Background="#111" Foreground="White" IsReadOnly="True" Height="32" Padding="8,0"/><Button Name="btnRe" Grid.Column="1" Content="CHON RE" Style="{StaticResource ModernBtn}" Margin="10,0,0,0" Background="#333"/></Grid></StackPanel>
        <StackPanel Grid.Row="3" Margin="0,0,0,12"><TextBlock Text="Thu muc Driver (Tuy chon):" Foreground="#888"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions><TextBox Name="txtDriver" Background="#111" Foreground="White" IsReadOnly="True" Height="32" Padding="8,0"/><Button Name="btnDriver" Grid.Column="1" Content="CHON DRV" Style="{StaticResource ModernBtn}" Margin="10,0,0,0" Background="#333"/></Grid></StackPanel>
        <Grid Grid.Row="4" Margin="0,5,0,20"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="Phien ban:" Foreground="#888"/><ComboBox Name="cmbIndex" Height="32" Width="320" HorizontalAlignment="Left" Margin="0,4,0,0"/></StackPanel>
        <StackPanel Grid.Column="1" VerticalAlignment="Bottom"><CheckBox Name="chkOOBE" Content="Bo qua OOBE" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,5"/><CheckBox Name="chkBitLocker" Content="Doi tat BitLocker" Foreground="#FFB300" IsChecked="True"/></StackPanel></Grid>
        <StackPanel Grid.Row="5"><ProgressBar Name="pgBar" Height="8" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/><TextBlock Name="lblStatus" Text="Trang thai: San sang." Foreground="#666" HorizontalAlignment="Center" FontSize="11"/></StackPanel>
        <Button Name="btnStart" Grid.Row="7" Content="KICH HOAT CAI DAT" Style="{StaticResource ModernBtn}" Height="60" Background="#D32F2F" FontSize="18"/></Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim"); $txtRe = $CuaSo.FindName("txtRe"); $btnRe = $CuaSo.FindName("btnRe")
$txtDriver = $CuaSo.FindName("txtDriver"); $btnDriver = $CuaSo.FindName("btnDriver"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$chkBitLocker = $CuaSo.FindName("chkBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE"); $pgBar = $CuaSo.FindName("pgBar"); $lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

function Refresh-UI { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

# --- EVENT HANDLERS ---
$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; if ($fd.ShowDialog()) {
        $txtWim.Text = $fd.FileName; $cmbIndex.Items.Clear()
        (Get-WindowsImage -ImagePath $fd.FileName) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
        $cmbIndex.SelectedIndex = 0; if ($txtRe.Text) { $btnStart.IsEnabled = $true }
    }
})
$btnRe.Add_Click({ $fd = New-Object Microsoft.Win32.OpenFileDialog; if ($fd.ShowDialog()) { $txtRe.Text = $fd.FileName; if ($txtWim.Text) { $btnStart.IsEnabled = $true } } })
$btnDriver.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath } })

$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; $lblStatus.Text = "Dang chuan bi..."; Refresh-UI

    try {
        if ($chkBitLocker.IsChecked) {
            $lblStatus.Text = "Dang giai ma BitLocker..."; Refresh-UI
            manage-bde -off C: | Out-Null
            while ($true) {
                $st = manage-bde -status C:
                if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }
                Start-Sleep -Seconds 2; Refresh-UI
            }
        }

        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wimPathHost = $txtWim.Text
        $wimFileName = [System.IO.Path]::GetFileName($wimPathHost)
        $reSource = $txtRe.Text
        $bootDir = "C:\VietBoot"
        if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
        
        # --- FIX TREO SDI (CƯỠNG CHẾ QUYỀN) ---
        $lblStatus.Text = "Dang xu ly boot.sdi..."; Refresh-UI
        $sdiPaths = @("C:\Windows\Boot\EFI\boot.sdi", "C:\Windows\Boot\PCAT\boot.sdi")
        $foundSdi = $false
        foreach ($path in $sdiPaths) {
            if (Test-Path $path) {
                takeown /f $path /a | Out-Null
                icacls $path /grant Administrators:F | Out-Null
                Copy-Item $path "$bootDir\boot.sdi" -Force -ErrorAction SilentlyContinue
                $foundSdi = $true; break
            }
        }
        if (!$foundSdi) { throw "Khong tim thay boot.sdi!" }

        $lblStatus.Text = "Dang Mount WinRE..."; $pgBar.Value = 20; Refresh-UI
        $mount = "C:\MountTemp"
        if (Test-Path $mount) { Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -Wait -WindowStyle Hidden }
        New-Item $mount -ItemType Directory -Force | Out-Null
        Copy-Item $reSource "$bootDir\boot.wim" -Force
        
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mount" -PassThru -WindowStyle Hidden
        while (!$p.HasExited) { Refresh-UI; Start-Sleep -Milliseconds 500 }

        # --- TẠO SCRIPT STARTNET.CMD (FIX LỖI %WIM_PATH%) ---
        $driverCmd = ""
        if (![string]::IsNullOrEmpty($txtDriver.Text)) { 
            Copy-Item -Path "$($txtDriver.Text)\*" -Destination "$bootDir\Drivers" -Recurse -Force
            $driverCmd = "echo [3/4] Dang nap Driver...`ndism /Image:C:\ /Add-Driver /Driver:X:\VietBoot\Drivers /Recurse >nul"
        }

        $unattend = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE>
<UserAccounts><LocalAccounts><LocalAccount action="Add"><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts>
<AutoLogon><Enabled>true</Enabled><Username>Admin</Username></AutoLogon></component></settings></unattend>
"@
        # Script này sẽ chạy khi boot vào RE
        $cmd = @"
@echo off
wpeinit
set "WIM_NAME=$wimFileName"
set "WIM_PATH="
echo Dang tim file: %WIM_NAME%...
for %%i in (C D E F G H I J K L M N O P) do (
    if exist "%%i:\%WIM_NAME%" set "WIM_PATH=%%i:\%WIM_NAME%"
    if exist "%%i:\VietBoot\%WIM_NAME%" set "WIM_PATH=%%i:\VietBoot\%WIM_NAME%"
)
if not defined WIM_PATH (
    echo [LOI] Khong tim thay file Windows Image!
    pause & exit
)
echo [1/4] Dang format o C...
format C: /fs:ntfs /q /y >nul
echo [2/4] Dang Apply Windows (Index $idx)...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\
$driverCmd
mkdir C:\Windows\Panther >nul
echo $unattend > C:\Windows\Panther\unattend.xml
echo [4/4] Dang tao bootloader...
bcdboot C:\Windows /s C: /f ALL
mkdir C:\Windows\Setup\Scripts >nul
(echo @echo off
echo bcdedit /timeout 0
echo rd /s /q "C:\VietBoot"
echo del %%0)>C:\Windows\Setup\Scripts\SetupComplete.cmd
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force
        "[LaunchApps]`ncmd.exe, /c %SYSTEMROOT%\System32\startnet.cmd" | Out-File "$mount\Windows\System32\winpeshl.ini" -Encoding ASCII -Force

        $lblStatus.Text = "Dang Save WinRE..."; $pgBar.Value = 80; Refresh-UI
        $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -PassThru -WindowStyle Hidden
        while (!$p.HasExited) { Refresh-UI; Start-Sleep -Milliseconds 500 }

        # --- ĐĂNG KÝ BCD ---
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

        $lblStatus.Text = "HOAN TAT! Dang Restart..."; $pgBar.Value = 100; Refresh-UI
        Restart-Computer -Force
    } catch { 
        [System.Windows.MessageBox]::Show("Loi: $_") 
        $btnStart.IsEnabled = $true
        $lblStatus.Text = "Loi: Khong the thuc hien."
    }
})

$CuaSo.ShowDialog() | Out-Null