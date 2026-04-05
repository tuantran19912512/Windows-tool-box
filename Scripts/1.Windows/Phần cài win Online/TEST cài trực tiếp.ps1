# ==============================================================================
# VIETTOOLBOX V33.4 - TURBO EDITION (ROBOCOPY ENGINE + REAL-TIME PROGRESS)
# Tính năng: Chép file tốc độ bàn thờ với Robocopy /J, Không treo GUI, Full Giáp.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN SIÊU TƯƠNG PHẢN ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V33.4 - Turbo Edition" Height="780" Width="720" 
        WindowStartupLocation="CenterScreen" Background="#000000">
    <Window.Resources>
        <Style TargetType="ComboBoxItem"><Setter Property="Background" Value="#111"/><Setter Property="Foreground" Value="White"/><Setter Property="Padding" Value="8"/></Style>
        <Style TargetType="ComboBox"><Setter Property="Background" Value="#1A1A1A"/><Setter Property="Foreground" Value="#00adb5"/><Setter Property="Height" Value="38"/></Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="#0A0A0A"/><Setter Property="Foreground" Value="#00adb5"/><Setter Property="Padding" Value="10,0"/></Style>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="40"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,20"><TextBlock Text="VIETTOOLBOX V33.4" FontSize="36" FontWeight="Black" Foreground="#00adb5"/><TextBlock Text="TURBO ENGINE: ROBOCOPY /J - TỐC ĐỘ BÀN THỜ" FontSize="12" Foreground="#888"/></StackPanel>
        <TabControl Grid.Row="1" Background="#050505" BorderBrush="#222">
            <TabControl.Resources><Style TargetType="TabItem"><Setter Property="Background" Value="#111"/><Setter Property="Foreground" Value="#AAA"/><Setter Property="Padding" Value="20,10"/><Setter Property="FontWeight" Value="Bold"/></Style></TabControl.Resources>
            <TabItem Header="1. BỘ CÀI &amp; ĐÍCH">
                <StackPanel Margin="25">
                    <TextBlock Text="Nguồn Windows (.iso, .wim, .esd):" Foreground="#AAA" Margin="0,0,0,8"/><Grid Margin="0,0,0,20"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions><TextBox Name="txtWim" IsReadOnly="True" Height="38"/><Button Name="btnWim" Grid.Column="1" Content="CHỌN FILE" Style="{StaticResource ModernBtn}" Margin="10,0,0,0"/></Grid>
                    <TextBlock Text="Phiên bản cài đặt:" Foreground="#AAA" Margin="0,0,0,8"/><ComboBox Name="cmbIndex" Margin="0,0,0,20"/><TextBlock Text="Ổ đĩa đích:" Foreground="#AAA" Margin="0,0,0,8"/><ComboBox Name="cmbDrive"><ComboBoxItem Content="C:\" IsSelected="True"/></ComboBox>
                </StackPanel>
            </TabItem>
            <TabItem Header="2. TỰ ĐỘNG HÓA">
                <Grid Margin="25"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <CheckBox Name="chkKillBitLocker" Content="Vô hiệu hóa BitLocker" Foreground="#FFB300" IsChecked="True" FontWeight="Bold" Margin="0,0,0,15"/>
                    <CheckBox Name="chkOOBE" Content="Bypass OOBE / NRO" Foreground="White" IsChecked="True" Margin="0,0,0,15"/>
                    <CheckBox Name="chkAnydesk" Content="Tự động nạp AnyDesk" Foreground="#4CAF50" IsChecked="True"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <CheckBox Name="chkActiveWin" Content="Auto Active Win/Office" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,15"/>
                    <CheckBox Name="chkAutoApps" Content="Auto cài Chrome/WinRAR" Foreground="#FFF" IsChecked="True"/>
                </StackPanel></Grid>
            </TabItem>
        </TabControl>
        <StackPanel Grid.Row="2" Margin="0,20,0,0">
            <ProgressBar Name="pgBar" Height="12" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,15"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng." Foreground="#666" HorizontalAlignment="Center" FontSize="11" Margin="0,0,0,15"/>
            <Button Name="btnStart" Content="KÍCH HOẠT TURBO DEPLOY" Style="{StaticResource ModernBtn}" Height="65" Background="#D32F2F" FontSize="20" IsEnabled="False"/>
        </StackPanel>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$chkBitLocker = $CuaSo.FindName("chkKillBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE")
$chkAnydesk = $CuaSo.FindName("chkAnydesk"); $chkActiveWin = $CuaSo.FindName("chkActiveWin")
$chkAutoApps = $CuaSo.FindName("chkAutoApps"); $pgBar = $CuaSo.FindName("pgBar")
$lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog()) {
        $path = $fd.FileName; $ext = [System.IO.Path]::GetExtension($path).ToLower()
        $cmbIndex.Items.Clear()
        if ($ext -eq ".iso") {
            $m = Mount-DiskImage -ImagePath $path -PassThru; $dv = ($m | Get-Volume).DriveLetter; $w = "$dv`:\sources\install.wim"
            if (!(Test-Path $w)) { $w = "$dv`:\sources\install.esd" }
            (Get-WindowsImage -ImagePath $w) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
            Dismount-DiskImage -ImagePath $path | Out-Null
        } else { (Get-WindowsImage -ImagePath $path) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") } }
        $txtWim.Text = $path; $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true
    }
})

$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; $bootDir = "C:\VietBoot"; if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
    try {
        # 1. GIẢI MÃ BITLOCKER
        $lblStatus.Text = "Đang giải mã BitLocker..."; LamMoi-GiaoDien
        manage-bde -off C: | Out-Null
        while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 2 }

        # 2. CHÉP ISO BẰNG TURBO ENGINE (ROBOCOPY /J)
        $wimPath = $txtWim.Text; $wimName = [System.IO.Path]::GetFileName($wimPath)
        if ($wimPath.EndsWith(".iso")) {
            $m = Mount-DiskImage -ImagePath $wimPath -PassThru; $dv = ($m | Get-Volume).DriveLetter
            $srcPath = "$dv`:\sources"; $srcFile = "install.wim"; if (!(Test-Path "$srcPath\install.wim")) { $srcFile = "install.esd" }
            $wimName = "install_turbo.wim"; $target = "$bootDir\$wimName"
            $srcFull = "$srcPath\$srcFile"
            $srcSize = (Get-Item $srcFull).Length

            # Dùng Robocopy với tham số /J (Unbuffered I/O) cho tốc độ tối đa
            $lblStatus.Text = "Đang kích hoạt TURBO COPY (Robocopy /J)..."; LamMoi-GiaoDien
            Start-Process robocopy.exe -ArgumentList "`"$srcPath`" `"$bootDir`" $srcFile /J /IS /IT /MT:16 /R:0 /W:0 /NJH /NJS" -WindowStyle Hidden
            
            # Theo dõi Progress thời gian thực
            while ($true) {
                if (Test-Path $target) {
                    $curSize = (Get-Item $target).Length
                    $percent = [math]::Round(($curSize / $srcSize) * 100)
                    $pgBar.Value = $percent; $lblStatus.Text = "TURBO COPY: $([math]::Round($curSize/1GB, 2))GB / $([math]::Round($srcSize/1GB, 2))GB ($percent%)"; LamMoi-GiaoDien
                    if ($curSize -ge $srcSize) { break }
                }
                Start-Sleep -Milliseconds 300
                if (!(Get-Process "robocopy" -ErrorAction SilentlyContinue)) { break }
            }
            Dismount-DiskImage -ImagePath $wimPath | Out-Null; $wimPath = $target
        }

        # 3. NHÚNG KỊCH BẢN & REBOOT (Giữ nguyên các chức năng full của ông)
        $lblStatus.Text = "Đang chuẩn bị kịch bản khởi động..."; LamMoi-GiaoDien
        $temp = "$bootDir\Conf"; New-Item $temp -ItemType Directory -Force | Out-Null
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        
        # Tạo tệp lệnh WinPE
        $sn = "@echo off`nwpeinit`nfor %%i in (C D E F G H I J K L M N) do (if exist `"%%i:\VietBoot\$wimName`" set `"W=%%i:\VietBoot\$wimName`")`nfor /d %%a in (C:\*) do if /i not `"%%~nxa`"==`"VietBoot`" rd /s /q `"%%a`"`ndel /f /q C:\*.*`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$idx /ApplyDir:C:\`nreg load HKLM\O_S C:\Windows\System32\config\SOFTWARE`nreg add HKLM\O_S\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f`nreg add HKLM\O_S\Policies\Microsoft\FVE /v PreventDeviceEncryption /t REG_DWORD /d 1 /f`nreg unload HKLM\O_S`nmkdir C:\Windows\Setup\Scripts >nul`ncopy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y`nbcdboot C:\Windows /s C: /f ALL`nwpeutil reboot"
        $sn | Out-File "$temp\s.cmd" -Encoding ASCII

        # SetupComplete để Active Win/Office
        $sc = "@echo off`nmanage-bde -off C:`npowershell -c `"irm https://get.activated.win | iex`" /HWID`npowershell -c `"irm https://get.activated.win | iex`" /Ohook`nbcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$temp\SetupComplete.cmd" -Encoding ASCII

        # Tiêm bằng Wimlib
        Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" "$bootDir\boot.wim" -Force
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$bootDir\boot.sdi" -Force
        if (!(Test-Path "$bootDir\wimlib-imagex.exe")) {
            curl.exe -L -o "$bootDir\w.zip" "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip"
            powershell -c "Expand-Archive '$bootDir\w.zip' '$bootDir\wim' -f"; Copy-Item "$bootDir\wim\*\wimlib-imagex.exe" "$bootDir\wimlib-imagex.exe" -Force
        }
        "add `"$temp\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$temp\s.cmd`" `"\Windows\System32\startnet.cmd`"" | Out-File "$bootDir\t.txt" -Encoding utf8
        Start-Process "$bootDir\wimlib-imagex.exe" "update `"$bootDir\boot.wim`" 1 < `"$bootDir\t.txt`"" -Wait -WindowStyle Hidden

        # Boot & Go
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VB" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $_"); $btnStart.IsEnabled = $true }
})

$CuaSo.ShowDialog() | Out-Null