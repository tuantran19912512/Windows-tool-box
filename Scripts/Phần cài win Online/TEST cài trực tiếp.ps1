# ==============================================================================
# VIETTOOLBOX V22 - SILENT STRIKE (FIX AUTO-RUN & KEYBOARD UI)
# Tinh nang: Auto-startnet, No Keyboard UI, BitLocker Off, Add Drivers
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# --- GIAO DIỆN WPF MODERN ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V22 - Silent Installer" Height="600" Width="620" 
        WindowStartupLocation="CenterScreen" Background="#121212">
    <Window.Resources>
        <Style x:Key="RoundedBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="35"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="VIETTOOLBOX PRO V22" FontSize="26" FontWeight="ExtraBold" Foreground="#00adb5"/>
            <TextBlock Text="PHAN PHOI BOI ADMIN - AUTOMATED INSTALLER" FontSize="10" Foreground="#666666"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Margin="0,0,0,10">
            <TextBlock Text="Tep tin Windows (.wim):" Foreground="#888888" Margin="0,0,0,3"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtWim" Background="#1E1E1E" Foreground="White" IsReadOnly="True" Height="30"/>
                <Button Name="btnWim" Grid.Column="1" Content="Duyet" Style="{StaticResource RoundedBtn}" Margin="5,0,0,0"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,10">
            <TextBlock Text="Tep tin Cuu ho (WinRE.wim):" Foreground="#888888" Margin="0,0,0,3"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtRe" Background="#1E1E1E" Foreground="White" IsReadOnly="True" Height="30"/>
                <Button Name="btnRe" Grid.Column="1" Content="Duyet" Style="{StaticResource RoundedBtn}" Margin="5,0,0,0" Background="#444444"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="3" Margin="0,0,0,10">
            <TextBlock Text="Thu muc Driver (Tuy chon):" Foreground="#888888" Margin="0,0,0,3"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtDriver" Background="#1E1E1E" Foreground="White" IsReadOnly="True" Height="30"/>
                <Button Name="btnDriver" Grid.Column="1" Content="Chon" Style="{StaticResource RoundedBtn}" Margin="5,0,0,0" Background="#444444"/></Grid>
        </StackPanel>

        <Grid Grid.Row="4" Margin="0,5,0,15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel><TextBlock Text="Phien ban cai dat:" Foreground="#888888"/><ComboBox Name="cmbIndex" Height="30" Width="300" HorizontalAlignment="Left"/></StackPanel>
            <CheckBox Name="chkBitLocker" Grid.Column="1" Content="Tu dong tat BitLocker" Foreground="#ffab00" VerticalAlignment="Bottom" IsChecked="True"/>
        </Grid>

        <StackPanel Grid.Row="5">
            <ProgressBar Name="pgBar" Height="8" Background="#1E1E1E" Foreground="#00adb5" Margin="0,0,0,5"/>
            <TextBlock Name="lblStatus" Text="San sang." Foreground="#666666" HorizontalAlignment="Center" FontSize="11"/>
        </StackPanel>

        <Button Name="btnStart" Grid.Row="7" Content="TIEN HANH CAI DAT NGAY" Style="{StaticResource RoundedBtn}" Height="50" Background="#d63031"/>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim")
$txtRe = $CuaSo.FindName("txtRe"); $btnRe = $CuaSo.FindName("btnRe")
$txtDriver = $CuaSo.FindName("txtDriver"); $btnDriver = $CuaSo.FindName("btnDriver")
$cmbIndex = $CuaSo.FindName("cmbIndex"); $chkBitLocker = $CuaSo.FindName("chkBitLocker")
$pgBar = $CuaSo.FindName("pgBar"); $lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")
$btnStart.IsEnabled = $false

function Refresh-UI { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

# --- EVENT HANDLERS ---
$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; if ($fd.ShowDialog()) {
        $txtWim.Text = $fd.FileName; $cmbIndex.Items.Clear()
        (Get-WindowsImage -ImagePath $fd.FileName) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
        $cmbIndex.SelectedIndex = 0; if ($txtRe.Text) { $btnStart.IsEnabled = $true }
    }
})

$btnRe.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; if ($fd.ShowDialog()) { $txtRe.Text = $fd.FileName; if ($txtWim.Text) { $btnStart.IsEnabled = $true } }
})

$btnDriver.Add_Click({
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath }
})

$btnStart.Add_Click({
    if ([System.Windows.MessageBox]::Show("Toan bo o C se bi xoa. Tiep tuc?", "Xac nhan", 4, 48) -ne 'Yes') { return }
    $btnStart.IsEnabled = $false; $lblStatus.Text = "Dang chuan bi..."; Refresh-UI

    try {
        if ($chkBitLocker.IsChecked) { manage-bde -off C: | Out-Null }

        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $txtWim.Text; $reSource = $txtRe.Text; $tenWim = [System.IO.Path]::GetFileName($wim)
        $bootDir = "C:\VietBoot"; if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
        
        $hasDriver = $false
        if ($txtDriver.Text -and (Test-Path $txtDriver.Text)) {
            $driDir = "$bootDir\Drivers"; if (!(Test-Path $driDir)) { New-Item $driDir -ItemType Directory | Out-Null }
            Copy-Item -Path "$($txtDriver.Text)\*" -Destination $driDir -Recurse -Force; $hasDriver = $true
        }

        Copy-Item (Get-ChildItem -Path "C:\Windows\Boot\EFI\boot.sdi" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName "$bootDir\boot.sdi" -Force
        
        $mount = "C:\MountTemp"; if (Test-Path $mount) { Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -Wait -WindowStyle Hidden }
        New-Item $mount -ItemType Directory -Force | Out-Null
        Copy-Item $reSource "$bootDir\boot.wim" -Force
        
        $lblStatus.Text = "Dang Mount WinRE (Vui long doi)..."; $pgBar.Value = 30; Refresh-UI
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mount" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { Refresh-UI; Start-Sleep -Milliseconds 500 }

        # --- BƯỚC 1: STARTNET.CMD (Silent & Auto-find) ---
        $driverLogic = if ($hasDriver) { "echo Dang nap Driver...`ndism /Image:C:\ /Add-Driver /Driver:X:\VietBoot\Drivers /Recurse >nul" } else { "" }
        $cmd = @"
@echo off
wpeinit
cls
echo DANG TIM TEP $tenWim...
set WIM_PATH=
for %%i in (C D E F G H I J K L M N O P Q R S T U V) do (if exist "%%i:\$tenWim" (set WIM_PATH=%%i:\$tenWim))
if "%WIM_PATH%"=="" (echo KHONG TIM THAY TEP WIM! & pause & exit)
echo [1/3] Dang dinh dang lai o C...
format C: /fs:ntfs /q /y >nul
echo [2/3] Dang cai Windows (Index $idx)...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\
$driverLogic
echo [3/3] Dang tao bootloader...
bcdboot C:\Windows /s C: /f ALL
echo HOAN TAT! DANG TAO SCRIPT DON DEP...
mkdir C:\Windows\Setup\Scripts >nul
(echo @echo off
echo for /f "tokens=2 delims={}" %%%%g in ('bcdedit /enum all ^^| findstr /i "VietToolbox"') do (bcdedit /delete {%%%%g} /f)
echo bcdedit /timeout 0
echo rd /s /q "C:\VietBoot"
echo del %%0)>C:\Windows\Setup\Scripts\SetupComplete.cmd
echo KET THUC. RESTART SAU 5S...
timeout /t 5
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force

        # --- BƯỚC 2: WINPESHL.INI (ÉP CHẠY KHÔNG CẦN HỎI) ---
        # Sửa cấu trúc Plural [LaunchApps] để hỗ trợ nhiều dòng lệnh
        $ini = @"
[LaunchApps]
wpeinit
cmd.exe, /c %SYSTEMROOT%\System32\startnet.cmd
"@
        $ini | Out-File "$mount\Windows\System32\winpeshl.ini" -Encoding ASCII -Force

        $lblStatus.Text = "Dang dong goi (Commit)..."; $pgBar.Value = 80; Refresh-UI
        $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { Refresh-UI; Start-Sleep -Milliseconds 500 }

        # --- ĐĂNG KÝ BCD ---
        $ramGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $ramGuid /d "VietToolbox Options" /device | Out-Null
        bcdedit /set $ramGuid ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ramGuid ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $bootGuid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $bootGuid /d "VietToolbox Installer" /application osloader | Out-Null
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