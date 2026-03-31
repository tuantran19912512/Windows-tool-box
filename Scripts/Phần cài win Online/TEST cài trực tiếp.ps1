# ==============================================================================
# VIETTOOLBOX V23 - ULTIMATE PRO (FIX NULL PATH & MODERN UI)
# Tính năng: Tắt BitLocker - Tích hợp Driver - Tự dọn dẹp - Anti-Freeze
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# --- GIAO DIỆN WPF (XAML) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V23 - Ultimate Installer" Height="620" Width="600" 
        WindowStartupLocation="CenterScreen" Background="#0F0F0F">
    <Window.Resources>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="32"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="ModernTxt" TargetType="TextBox">
            <Setter Property="Background" Value="#1A1A1A"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#333333"/><Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Padding" Value="5,0"/>
        </Style>
    </Window.Resources>

    <Grid Margin="25">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="VIETTOOLBOX ULTIMATE" FontSize="24" FontWeight="Black" Foreground="#00adb5"/>
            <TextBlock Text="HỆ THỐNG CÀI ĐẶT WINDOWS TỰ ĐỘNG V23" FontSize="10" Foreground="#555555"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Margin="0,0,0,12">
            <TextBlock Text="Tệp tin Windows (.wim):" Foreground="#888888" Margin="0,0,0,4"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtWim" Style="{StaticResource ModernTxt}" IsReadOnly="True" Height="30"/>
                <Button Name="btnWim" Grid.Column="1" Content="Mở File" Style="{StaticResource ModernBtn}" Margin="8,0,0,0"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,12">
            <TextBlock Text="Tệp tin Cứu hộ (WinRE.wim):" Foreground="#888888" Margin="0,0,0,4"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtRe" Style="{StaticResource ModernTxt}" IsReadOnly="True" Height="30"/>
                <Button Name="btnRe" Grid.Column="1" Content="Mở File" Style="{StaticResource ModernBtn}" Margin="8,0,0,0" Background="#333333"/></Grid>
        </StackPanel>

        <StackPanel Grid.Row="3" Margin="0,0,0,12">
            <TextBlock Text="Thư mục Driver tích hợp (Tùy chọn):" Foreground="#888888" Margin="0,0,0,4"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBox Name="txtDriver" Style="{StaticResource ModernTxt}" IsReadOnly="True" Height="30"/>
                <Button Name="btnDriver" Grid.Column="1" Content="Chọn" Style="{StaticResource ModernBtn}" Margin="8,0,0,0" Background="#333333"/></Grid>
        </StackPanel>

        <Grid Grid.Row="4" Margin="0,5,0,20">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel><TextBlock Text="Phiên bản Windows:" Foreground="#888888"/><ComboBox Name="cmbIndex" Height="30" Width="320" HorizontalAlignment="Left" Margin="0,4,0,0"/></StackPanel>
            <CheckBox Name="chkBitLocker" Grid.Column="1" Content="Tắt BitLocker" Foreground="#FFB300" VerticalAlignment="Bottom" IsChecked="True"/>
        </Grid>

        <StackPanel Grid.Row="5">
            <ProgressBar Name="pgBar" Height="6" Background="#1A1A1A" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,8"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng." Foreground="#666666" HorizontalAlignment="Center" FontSize="11"/>
        </StackPanel>

        <Button Name="btnStart" Grid.Row="7" Content="BẮT ĐẦU CÀI ĐẶT" Style="{StaticResource ModernBtn}" Height="50" Background="#D32F2F" FontSize="16"/>
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

function Refresh-UI { 
    [System.Windows.Forms.Application]::DoEvents()
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

# --- XỬ LÝ SỰ KIỆN ---
$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "Windows Image|*.wim"
    if ($fd.ShowDialog()) {
        $txtWim.Text = $fd.FileName; $cmbIndex.Items.Clear()
        (Get-WindowsImage -ImagePath $fd.FileName) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
        $cmbIndex.SelectedIndex = 0; if ($txtRe.Text) { $btnStart.IsEnabled = $true }
    }
})

$btnRe.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "WinRE|*.wim"
    if ($fd.ShowDialog()) { $txtRe.Text = $fd.FileName; if ($txtWim.Text) { $btnStart.IsEnabled = $true } }
})

$btnDriver.Add_Click({
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath }
})

$btnStart.Add_Click({
    if ([System.Windows.MessageBox]::Show("Xác nhận Format ổ C và cài lại Windows?", "Cảnh báo", 4, 48) -ne 'Yes') { return }
    $btnStart.IsEnabled = $false; $lblStatus.Text = "Đang khởi động..."; Refresh-UI

    try {
        # Fix lỗi BitLocker
        if ($chkBitLocker.IsChecked) {
            $lblStatus.Text = "Đang kiểm tra và tắt BitLocker..."; Refresh-UI
            manage-bde -off C: | Out-Null
        }

        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $wim = $txtWim.Text; $reSource = $txtRe.Text; $tenWim = [System.IO.Path]::GetFileName($wim)
        $bootDir = "C:\VietBoot"; if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
        
        # --- FIX LỖI PATH NULL (Ảnh 3c4f20) ---
        $hasDriver = $false
        if (![string]::IsNullOrEmpty($txtDriver.Text) -and (Test-Path $txtDriver.Text)) {
            $lblStatus.Text = "Đang sao chép Driver..."; Refresh-UI
            $driDir = "$bootDir\Drivers"
            if (!(Test-Path $driDir)) { New-Item $driDir -ItemType Directory | Out-Null }
            Copy-Item -Path "$($txtDriver.Text)\*" -Destination $driDir -Recurse -Force
            $hasDriver = $true
        }

        $lblStatus.Text = "Đang Mount WinRE..."; $pgBar.Value = 30; Refresh-UI
        $sdi = "C:\Windows\Boot\EFI\boot.sdi"; if (!(Test-Path $sdi)) { $sdi = "C:\Windows\Boot\DVD\EFI\boot.sdi" }
        Copy-Item $sdi "$bootDir\boot.sdi" -Force
        
        $mount = "C:\MountTemp"; if (Test-Path $mount) { Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -Wait -WindowStyle Hidden }
        New-Item $mount -ItemType Directory -Force | Out-Null
        Copy-Item $reSource "$bootDir\boot.wim" -Force
        
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mount" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { Refresh-UI; Start-Sleep -Milliseconds 500 }

        # --- Tạo Startnet.cmd chuẩn chỉ ---
        $driverCmd = if ($hasDriver) { "echo [3/4] Dang nap Driver...`ndism /Image:C:\ /Add-Driver /Driver:X:\VietBoot\Drivers /Recurse >nul" } else { "" }
        $cmd = @"
@echo off
wpeinit
cls
echo DANG TIM TEP $tenWim...
for %%i in (C D E F G H I J K L M N O P Q R S T U V) do (if exist "%%i:\$tenWim" (set WIM_PATH=%%i:\$tenWim))
echo [1/3] Dang format o C...
format C: /fs:ntfs /q /y >nul
echo [2/3] Dang bung anh he thong...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\
$driverCmd
echo [3/3] Dang tao boot...
bcdboot C:\Windows /s C: /f ALL
echo DANG TAO LENH TU DON DEP...
mkdir C:\Windows\Setup\Scripts >nul
(echo @echo off
echo for /f "tokens=2 delims={}" %%%%g in ('bcdedit /enum all ^^| findstr /i "VietToolbox"') do (bcdedit /delete {%%%%g} /f)
echo bcdedit /timeout 0
echo rd /s /q "C:\VietBoot"
echo del %%0)>C:\Windows\Setup\Scripts\SetupComplete.cmd
wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force
        
        # File INI gọi Startnet
        $ini = "[LaunchApps]`nwpeinit`ncmd.exe, /c %SYSTEMROOT%\System32\startnet.cmd"
        $ini | Out-File "$mount\Windows\System32\winpeshl.ini" -Encoding ASCII -Force

        $lblStatus.Text = "Đang đóng gói hệ thống..."; $pgBar.Value = 80; Refresh-UI
        $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -PassThru -WindowStyle Normal
        while (!$p.HasExited) { Refresh-UI; Start-Sleep -Milliseconds 500 }

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

        $lblStatus.Text = "Hoàn tất! Máy sẽ khởi động lại..."; $pgBar.Value = 100; Refresh-UI
        Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $_") }
})

$CuaSo.ShowDialog() | Out-Null