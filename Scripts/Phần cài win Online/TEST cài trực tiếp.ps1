# ==============================================================================
# VIETTOOLBOX V21 - PRO EDITION (FIXED XAML & NO-NAME UI)
# Tinh nang: Tat BitLocker - Tich hop Driver - Tu dong don dep Menu Boot
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# --- GIAO DIỆN WPF (MODERN DARK UI) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V21 - Pro Installer" Height="620" Width="620" 
        WindowStartupLocation="CenterScreen" Background="#121212">
    <Window.Resources>
        <Style x:Key="RoundedButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Height" Value="35"/>
            <Setter Property="Cursor" Value="Hand"/>
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
        <Style x:Key="ModernTextBox" TargetType="TextBox">
            <Setter Property="Background" Value="#1E1E1E"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#333333"/><Setter Property="Padding" Value="5"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="VIETTOOLBOX PRO V21" FontSize="26" FontWeight="ExtraBold" Foreground="#00adb5"/>
            <TextBlock Text="PHIEN BAN CHUYEN NGHIEP - MODERN INSTALLER" FontSize="10" Foreground="#666666"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Margin="0,0,0,10">
            <TextBlock Text="Tep tin Windows (.wim):" Foreground="#888888" Margin="0,0,0,3"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtWim" Style="{StaticResource ModernTextBox}" IsReadOnly="True" Height="30"/>
                <Button Name="btnWim" Grid.Column="1" Content="Duyet" Style="{StaticResource RoundedButtonStyle}" Margin="5,0,0,0"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,10">
            <TextBlock Text="Tep tin Cuu ho (WinRE.wim):" Foreground="#888888" Margin="0,0,0,3"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtRe" Style="{StaticResource ModernTextBox}" IsReadOnly="True" Height="30"/>
                <Button Name="btnRe" Grid.Column="1" Content="Duyet" Style="{StaticResource RoundedButtonStyle}" Margin="5,0,0,0" Background="#444444"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="3" Margin="0,0,0,10">
            <TextBlock Text="Thu muc Driver muon tich hop (Tuy chon):" Foreground="#888888" Margin="0,0,0,3"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtDriver" Style="{StaticResource ModernTextBox}" IsReadOnly="True" Height="30"/>
                <Button Name="btnDriver" Grid.Column="1" Content="Chon" Style="{StaticResource RoundedButtonStyle}" Margin="5,0,0,0" Background="#444444"/></Grid>
        </StackPanel>

        <Grid Grid.Row="4" Margin="0,5,0,15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel>
                <TextBlock Text="Phien ban cai dat:" Foreground="#888888" Margin="0,0,0,3"/>
                <ComboBox Name="cmbIndex" Height="30" Width="350" HorizontalAlignment="Left" Background="#1E1E1E" Foreground="Black"/>
            </StackPanel>
            <CheckBox Name="chkBitLocker" Grid.Column="1" Content="Tu dong tat BitLocker" Foreground="#ffab00" VerticalAlignment="Bottom" Margin="0,0,0,5" IsChecked="True"/>
        </Grid>

        <StackPanel Grid.Row="5" VerticalAlignment="Center">
            <ProgressBar Name="pgBar" Height="8" Background="#1E1E1E" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,5"/>
            <TextBlock Name="lblStatus" Text="San sang." Foreground="#666666" HorizontalAlignment="Center" FontSize="11"/>
        </StackPanel>

        <Button Name="btnStart" Grid.Row="7" Content="TIEN HANH CAI DAT NGAY" Style="{StaticResource RoundedButtonStyle}" 
                Height="50" Background="#d63031" FontSize="15"/>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

# Ánh xạ Controls
$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim")
$txtRe = $CuaSo.FindName("txtRe"); $btnRe = $CuaSo.FindName("btnRe")
$txtDriver = $CuaSo.FindName("txtDriver"); $btnDriver = $CuaSo.FindName("btnDriver")
$cmbIndex = $CuaSo.FindName("cmbIndex"); $chkBitLocker = $CuaSo.FindName("chkBitLocker")
$pgBar = $CuaSo.FindName("pgBar"); $lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

$btnStart.IsEnabled = $false

function CapNhat-UI { 
    [System.Windows.Forms.Application]::DoEvents()
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

# --- SỰ KIỆN NÚT BẤM ---
$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "Windows Image (*.wim)|*.wim"
    if ($fd.ShowDialog()) {
        $txtWim.Text = $fd.FileName; $cmbIndex.Items.Clear()
        (Get-WindowsImage -ImagePath $fd.FileName) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
        $cmbIndex.SelectedIndex = 0
        if ($txtRe.Text) { $btnStart.IsEnabled = $true }
    }
})

$btnRe.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "WinRE (*.wim)|*.wim"
    if ($fd.ShowDialog()) { $txtRe.Text = $fd.FileName; if ($txtWim.Text) { $btnStart.IsEnabled = $true } }
})

$btnDriver.Add_Click({
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath }
})

$btnStart.Add_Click({
    $confirm = [System.Windows.MessageBox]::Show("Toan bo du lieu o C se bi xoa. Tiep tuc?", "Xac nhan", 4, 48)
    if ($confirm -ne 'Yes') { return }

    $btnStart.IsEnabled = $false; $lblStatus.Text = "Dang khoi dong..."; CapNhat-UI

    try {
        if ($chkBitLocker.IsChecked) {
            $lblStatus.Text = "Dang giai ma BitLocker o C..."; CapNhat-UI
            manage-bde -off C: | Out-Null
        }

        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $txtWim.Text; $reSource = $txtRe.Text; $tenWim = [System.IO.Path]::GetFileName($wim)
        $bootDir = "C:\VietBoot"; if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
        
        $hasDriver = $false
        if ($txtDriver.Text -and (Test-Path $txtDriver.Text)) {
            $lblStatus.Text = "Dang copy Driver..."; CapNhat-UI
            $driDir = "$bootDir\Drivers"
            if (!(Test-Path $driDir)) { New-Item $driDir -ItemType Directory | Out-Null }
            Copy-Item -Path "$($txtDriver.Text)\*" -Destination $driDir -Recurse -Force
            $hasDriver = $true
        }

        $lblStatus.Text = "Dang Mount WinRE..."; $pgBar.Value = 30; CapNhat-UI
        $sdi = "C:\Windows\Boot\EFI\boot.sdi"; if (!(Test-Path $sdi)) { $sdi = "C:\Windows\Boot\DVD\EFI\boot.sdi" }
        Copy-Item $sdi "$bootDir\boot.sdi" -Force
        
        $mount = "C:\MountTemp"; if (Test-Path $mount) { Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -Wait -WindowStyle Hidden }
        New-Item $mount -ItemType Directory -Force | Out-Null
        Copy-Item $reSource "$bootDir\boot.wim" -Force
        
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mount" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { CapNhat-UI; Start-Sleep -Milliseconds 500 }

        $driverLogic = if ($hasDriver) { "echo [3/4] Dang nap Driver...`ndism /Image:C:\ /Add-Driver /Driver:X:\VietBoot\Drivers /Recurse >nul" } else { "echo [3/4] Bo qua nap Driver." }

        $cmd = @"
@echo off
wpeinit
cls
echo DANG TIM TEP $tenWim...
for %%i in (C D E F G H I J K L M N O P Q R S T U V) do (if exist "%%i:\$tenWim" (set WIM_PATH=%%i:\$tenWim))
echo [1/4] Dang format o C...
format C: /fs:ntfs /q /y >nul
echo [2/4] Dang Apply Image...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\
$driverLogic
echo [4/4] Dang tao boot...
bcdboot C:\Windows /s C: /f ALL
echo DANG TAO LENH DON DEP...
mkdir C:\Windows\Setup\Scripts >nul
(echo @echo off
echo for /f "tokens=2 delims={}" %%%%g in ('bcdedit /enum all ^^| findstr /i "VietToolbox"') do (bcdedit /delete {%%%%g} /f)
echo bcdedit /timeout 0
echo rd /s /q "C:\VietBoot"
echo del %%0)>C:\Windows\Setup\Scripts\SetupComplete.cmd
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force
        $ini = "[LaunchApp]`nAppPath = %SYSTEMROOT%\System32\cmd.exe`nCommandLine = `"/c %SYSTEMROOT%\System32\startnet.cmd`""
        $ini | Out-File "$mount\Windows\System32\winpeshl.ini" -Encoding ASCII -Force

        $lblStatus.Text = "Dang Unmount..."; $pgBar.Value = 80; CapNhat-UI
        $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { CapNhat-UI; Start-Sleep -Milliseconds 500 }

        # Đăng ký BCD
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

        $lblStatus.Text = "Hoan thanh!"; $pgBar.Value = 100; CapNhat-UI
        Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Loi: $_") }
})

$CuaSo.ShowDialog() | Out-Null