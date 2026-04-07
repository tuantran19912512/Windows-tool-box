# ==============================================================================
# VIETTOOLBOX V36.8 - THE DRIVER INJECTOR (NẠP DRIVER TỰ ĐỘNG)
# Chức năng: Export Driver cũ, Inject vào Win mới, Fix Boot/WinRE, Silent OOBE.
# Tự động: Tắt BitLocker, AnyDesk, Bypass TPM/NRO, Full Progress Bar.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN ĐIỀU KHIỂN ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V36.8 - Driver Injector" Height="750" Width="850" 
        WindowStartupLocation="CenterScreen" Background="#000">
    <Window.Resources>
        <Style x:Key="NutCaiDat" TargetType="Button">
            <Setter Property="Background" Value="#0A0A0A"/><Setter Property="Foreground" Value="#00adb5"/><Setter Property="BorderBrush" Value="#00adb5"/><Setter Property="BorderThickness" Value="2"/><Setter Property="Margin" Value="0,0,0,15"/><Setter Property="Height" Value="60"/><Setter Property="FontSize" Value="16"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,0"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="HỆ THỐNG TRIỂN KHAI V36.8" FontSize="34" FontWeight="Black" Foreground="#00adb5" HorizontalAlignment="Center"/>
            <TextBlock Text="TỰ ĐỘNG NẠP DRIVER - FIX BOOT - BYPASS OOBE" FontSize="12" Foreground="#666" HorizontalAlignment="Center" Margin="0,5,0,0"/>
        </StackPanel>
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions><ColumnDefinition Width="6*"/><ColumnDefinition Width="4*"/></Grid.ColumnDefinitions>
            <GroupBox Header=" 1. CHỌN BỘ CÀI WIM " Foreground="#00adb5" BorderBrush="#333" Margin="0,0,10,0" FontSize="14" FontWeight="Bold">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="10"><StackPanel Name="DanhSachNut"/></ScrollViewer>
            </GroupBox>
            <GroupBox Grid.Column="1" Header=" 2. THIẾT LẬP TỰ ĐỘNG " Foreground="#E91E63" BorderBrush="#333" Margin="10,0,0,0" FontSize="14" FontWeight="Bold">
                <StackPanel Margin="20">
                    <CheckBox Name="chkDriver" Content="Tự nạp Driver (Export từ máy)" Foreground="#00adb5" IsChecked="True" FontSize="14" Margin="0,0,0,20" FontWeight="Bold"/>
                    <CheckBox Name="chkBitLocker" Content="Diệt BitLocker vĩnh viễn" Foreground="#FFB300" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkOOBE" Content="Bypass All &amp; Tự nhập User" Foreground="White" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkAnydesk" Content="Tự cài &amp; Bật AnyDesk" Foreground="#4CAF50" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkActive" Content="Tự động Active Win/Off" Foreground="#00adb5" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkApps" Content="Cài Chrome &amp; WinRAR" Foreground="White" IsChecked="True" FontSize="14"/>
                </StackPanel>
            </GroupBox>
        </Grid>
        <StackPanel Grid.Row="2" Margin="0,20,0,0">
            <ProgressBar Name="pgBar" Height="15" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10" Minimum="0" Maximum="100"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Đang chờ lệnh..." Foreground="#AAA" HorizontalAlignment="Center" FontSize="13" FontWeight="Bold"/>
        </StackPanel>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$DanhSachNut = $CuaSo.FindName("DanhSachNut"); $lblStatus = $CuaSo.FindName("lblStatus"); $pgBar = $CuaSo.FindName("pgBar")
$chkDriver = $CuaSo.FindName("chkDriver"); $chkBitLocker = $CuaSo.FindName("chkBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE")
$chkAnydesk = $CuaSo.FindName("chkAnydesk"); $chkActive = $CuaSo.FindName("chkActive"); $chkApps = $CuaSo.FindName("chkApps")

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

# --- QUY TRÌNH MASTER V36.8 ---
function ThucThi-CaiDat($Url, $Idx, $vDrv, $vBit, $vOOBE, $vAny, $vAct, $vApp) {
    $DanhSachNut.IsEnabled = $false; $bootDir = "C:\VietBoot"; if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
    try {
        # 1. FIX BOOT (10%)
        $pgBar.Value = 5; $lblStatus.Text = "[1/11] Đang kiểm tra hạ tầng Boot..."; LamMoi-GiaoDien
        if (!(Get-Partition | Where-Object { $_.IsSystem })) {
            $disk = Get-Disk | Where-Object { $_.Number -eq 0 }
            "select disk $($disk.Number)`nclean`nconvert gpt`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S`ncreate partition msr size=16`ncreate partition primary`nformat quick fs=ntfs label='Windows'`nassign letter=C" | diskpart | Out-Null
        }
        $pgBar.Value = 10; LamMoi-GiaoDien

        # 2. EXPORT DRIVER (MỚI - 15%)
        if ($vDrv) {
            $lblStatus.Text = "[2/11] Đang sao lưu Driver từ máy cũ (Vui lòng chờ)..."; LamMoi-GiaoDien
            $drvPath = "$bootDir\Drivers"; if (!(Test-Path $drvPath)) { New-Item $drvPath -ItemType Directory -Force | Out-Null }
            dism /online /export-driver /destination:"$drvPath" | Out-Null
        }
        $pgBar.Value = 15; LamMoi-GiaoDien

        # 3. BITLOCKER (20%)
        $lblStatus.Text = "[3/11] Đang giải mã BitLocker..."; LamMoi-GiaoDien
        manage-bde -off C: | Out-Null
        while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 1 }
        $pgBar.Value = 20; LamMoi-GiaoDien

        # 4. TẢI CÔNG CỤ (30%)
        $exeW = "$bootDir\wimlib-imagex.exe"
        if (!(Test-Path $exeW)) {
            $lblStatus.Text = "[4/11] Đang tải công cụ Wimlib..."; LamMoi-GiaoDien
            Start-BitsTransfer -Source "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip" -Destination "$bootDir\w.zip"
            powershell -c "Expand-Archive '$bootDir\w.zip' '$bootDir\wim' -Force"; Copy-Item "$bootDir\wim\*\wimlib-imagex.exe" $exeW -Force
        }
        $pgBar.Value = 30; LamMoi-GiaoDien

        # 5. CHUẨN BỊ WIM (70%)
        $wimName = [System.IO.Path]::GetFileName($Url); $wimPath = "$bootDir\$wimName"
        $lblStatus.Text = "[5/11] Đang chuẩn bị tệp bộ cài..."; LamMoi-GiaoDien
        if ($Url.StartsWith("http")) { Start-BitsTransfer -Source $Url -Destination $wimPath } 
        else { if (!(Test-Path $wimPath)) { Copy-Item $Url $wimPath -Force } }
        $pgBar.Value = 70; LamMoi-GiaoDien

        # 6. FIX WINRE (75%)
        $lblStatus.Text = "[6/11] Phục hồi WinRE..."; LamMoi-GiaoDien
        $reWim = "$bootDir\boot.wim"
        if (!(Test-Path "C:\Windows\System32\Recovery\WinRE.wim")) {
            Start-Process $exeW "extract `"$wimPath`" $Idx /Windows/System32/Recovery/WinRE.wim --dest-dir=`"$bootDir`"" -Wait -WindowStyle Hidden
            if (Test-Path "$bootDir\WinRE.wim") { Move-Item "$bootDir\WinRE.wim" $reWim -Force }
        } else { Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" $reWim -Force }
        $pgBar.Value = 75; LamMoi-GiaoDien

        # 7. KỊCH BẢN TỰ ĐỘNG (80%)
        $lblStatus.Text = "[7/11] Tạo kịch bản tự động hóa..."; LamMoi-GiaoDien
        $temp = "$bootDir\Conf"; New-Item $temp -ItemType Directory -Force | Out-Null
        $sc = "@echo off`nmanage-bde -off C:`nnet accounts /maxpwage:unlimited`n"
        if ($vAct) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /HWID`npowershell -c `"irm https://get.activated.win | iex`" /Ohook`n" }
        if ($vApp) { $sc += "winget install --id Google.Chrome --silent`nwinget install --id WinRAR.WinRAR --silent`n" }
        $sc += "bcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$temp\SetupComplete.cmd" -Encoding ASCII
        
        $u = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>false</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE></component></settings></unattend>
"@
        $u | Out-File "$temp\u.xml" -Encoding UTF8
        $pgBar.Value = 80; LamMoi-GiaoDien

        # 8. STARTNET & INJECT DRIVER (85%)
        $lblStatus.Text = "[8/11] Cấu hình kịch bản WinPE..."; LamMoi-GiaoDien
        $sn = "@echo off`nwpeinit`nfor %%i in (C D E F G H I J K L M N O P) do (if exist `"%%i:\VietBoot\$wimName`" set `"W=%%i:\VietBoot\$wimName`")`nfor /d %%a in (C:\*) do if /i not `"%%~nxa`"==`"VietBoot`" rd /s /q `"%%a`"`ndel /f /q C:\*.*`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$Idx /ApplyDir:C:\`n"
        $sn += "reg load HKLM\SYS C:\Windows\System32\config\SYSTEM`nreg add HKLM\SYS\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f`nreg add HKLM\SYS\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f`nreg add HKLM\SYS\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f`nreg unload HKLM\SYS`nreg load HKLM\O_S C:\Windows\System32\config\SOFTWARE`nreg add HKLM\O_S\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f`nreg add HKLM\O_S\Policies\Microsoft\FVE /v PreventDeviceEncryption /t REG_DWORD /d 1 /f`nreg unload HKLM\O_S`n"
        # Lệnh nạp Driver
        if ($vDrv) { $sn += "if exist `"C:\VietBoot\Drivers`" dism /Image:C:\ /Add-Driver /Driver:`"C:\VietBoot\Drivers`" /Recurse`n" }
        $sn += "mkdir C:\Windows\Panther >nul & copy X:\Windows\System32\u.xml C:\Windows\Panther\unattend.xml /Y`nmkdir C:\Windows\Setup\Scripts >nul & copy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y`n"
        if ($vAny) {
            $any = "@echo off`n:check`nping 8.8.8.8 -n 1 >nul`nif errorlevel 1 timeout /t 3 >nul & goto check`ncurl.exe -L -o `"C:\Users\Public\Desktop\AnyDesk.exe`" `"https://download.anydesk.com/AnyDesk.exe`"`nstart `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`ndel `"%~f0`""
            $any | Out-File "$temp\Any.cmd" -Encoding ASCII
            $sn += "mkdir `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup`" >nul & copy X:\Windows\System32\Any.cmd `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Any.cmd`" /Y`n"
        }
        $sn += "bcdboot C:\Windows /s C: /f ALL`nwpeutil reboot"
        $sn | Out-File "$temp\s.cmd" -Encoding ASCII
        $pgBar.Value = 85; LamMoi-GiaoDien

        # 9. TIÊM KỊCH BẢN (90%)
        $lblStatus.Text = "[9/11] Đang tiêm kịch bản vào lõi WinRE..."; LamMoi-GiaoDien
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$bootDir\boot.sdi" -Force
        "add `"$temp\u.xml`" `"\Windows\System32\u.xml`"`nadd `"$temp\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$temp\s.cmd`" `"\Windows\System32\startnet.cmd`"" | Out-File "$bootDir\t.txt" -Encoding utf8
        Start-Process $exeW "update `"$reWim`" 1 < `"$bootDir\t.txt`"" -Wait -WindowStyle Hidden
        $pgBar.Value = 90; LamMoi-GiaoDien

        # 10. BCD (95%)
        $lblStatus.Text = "[10/11] Cấu hình Boot..."; LamMoi-GiaoDien
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VB" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        $pgBar.Value = 95; LamMoi-GiaoDien

        # 11. REBOOT (100%)
        $lblStatus.Text = "[11/11] XONG! Khởi động lại sau 2 giây..."; LamMoi-GiaoDien
        $pgBar.Value = 100; LamMoi-GiaoDien
        Start-Sleep -Seconds 2; Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $_"); $DanhSachNut.IsEnabled = $true }
}

# --- LOAD DANH SÁCH CSV ---
try {
    $url = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"
    $csv = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content | ConvertFrom-Csv
    foreach ($row in $csv) {
        $p = if ($row.Path) { $row.Path } else { $row.URL }; $idx = if ($row.Index) { $row.Index } else { "1" }
        $match = $false; foreach($prop in $row.PSObject.Properties) { if ($prop.Value -match "WIM") { $match = $true } }
        if ($p -match "\.wim" -or $match) {
            $btn = New-Object System.Windows.Controls.Button
            $btn.Style = $CuaSo.FindResource("NutCaiDat")
            $btn.Content = if ($row.Name) { $row.Name } else { "Bản Windows WIM" }
            $btn.Tag = @{ p=$p; i=$idx }
            $btn.Add_Click({
                $d = $this.Tag; ThucThi-CaiDat $d.p $d.i $chkDriver.IsChecked $chkBitLocker.IsChecked $chkOOBE.IsChecked $chkAnydesk.IsChecked $chkActive.IsChecked $chkApps.IsChecked
            })
            $DanhSachNut.Children.Add($btn) | Out-Null
        }
    }
    $lblStatus.Text = "Sẵn sàng. Danh sách đã được nạp."; LamMoi-GiaoDien
} catch { $lblStatus.Text = "Lỗi nạp danh sách!"; [System.Windows.MessageBox]::Show("Lỗi: $_") }

$CuaSo.ShowDialog() | Out-Null