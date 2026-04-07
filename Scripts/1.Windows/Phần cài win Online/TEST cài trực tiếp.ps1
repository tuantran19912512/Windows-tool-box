# ==============================================================================
# VIETTOOLBOX V37.0 - THE REBORN (RESTRUCTURED & OPTIMIZED)
# Chức năng: Master Deploy, Auto Driver, Silent OOBE, Bypass All, Network CSV.
# Tác giả: Gemini (Hỗ trợ Tuấn) - Ngôn ngữ: Tiếng Việt 100%.
# ==============================================================================

# --- KIỂM TRA QUYỀN QUẢN TRỊ ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- ĐỊNH NGHĨA GIAO DIỆN (XAML) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V37.0 - Reborn Edition" Height="750" Width="850" 
        WindowStartupLocation="CenterScreen" Background="#050505">
    <Window.Resources>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#0A0A0A"/><Setter Property="Foreground" Value="#00adb5"/><Setter Property="BorderBrush" Value="#00adb5"/><Setter Property="BorderThickness" Value="2"/><Setter Property="Margin" Value="0,0,0,15"/><Setter Property="Height" Value="60"/><Setter Property="FontSize" Value="16"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,0"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="VIETTOOLBOX V37.0" FontSize="36" FontWeight="Black" Foreground="#00adb5" HorizontalAlignment="Center"/>
            <TextBlock Text="CẤU TRÚC LẠI HOÀN TOÀN - TỐI ƯU HÓA HIỆU NĂNG" FontSize="11" Foreground="#555" HorizontalAlignment="Center"/>
        </StackPanel>
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions><ColumnDefinition Width="6*"/><ColumnDefinition Width="4*"/></Grid.ColumnDefinitions>
            <GroupBox Header=" DANH SÁCH WIM (GITHUB) " Foreground="#00adb5" BorderBrush="#222" Margin="0,0,10,0" FontSize="14" FontWeight="Bold">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="10"><StackPanel Name="DanhSachNut"/></ScrollViewer>
            </GroupBox>
            <GroupBox Grid.Column="1" Header=" TÙY CHỌN TỰ ĐỘNG HÓA " Foreground="#E91E63" BorderBrush="#222" Margin="10,0,0,0" FontSize="14" FontWeight="Bold">
                <StackPanel Margin="20">
                    <CheckBox Name="chkDriver" Content="Tự động nạp Driver máy" Foreground="#00adb5" IsChecked="True" FontSize="14" Margin="0,0,0,20" FontWeight="Bold"/>
                    <CheckBox Name="chkBitLocker" Content="Vô hiệu hóa BitLocker" Foreground="#FFB300" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkOOBE" Content="Bypass OOBE / NRO / TPM" Foreground="White" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkAnydesk" Content="Tự cài AnyDesk &amp; Bật" Foreground="#4CAF50" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkActive" Content="Kích hoạt Windows/Office" Foreground="#00adb5" IsChecked="True" FontSize="14" Margin="0,0,0,20"/>
                    <CheckBox Name="chkApps" Content="Cài Chrome &amp; WinRAR" Foreground="White" IsChecked="True" FontSize="14"/>
                </StackPanel>
            </GroupBox>
        </Grid>
        <StackPanel Grid.Row="2" Margin="0,20,0,0">
            <ProgressBar Name="pgBar" Height="12" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10" Minimum="0" Maximum="100"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Đang nạp dữ liệu..." Foreground="#888" HorizontalAlignment="Center" FontSize="13" FontWeight="Bold"/>
        </StackPanel>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$DanhSachNut = $CuaSo.FindName("DanhSachNut"); $lblStatus = $CuaSo.FindName("lblStatus"); $pgBar = $CuaSo.FindName("pgBar")
$chkDriver = $CuaSo.FindName("chkDriver"); $chkBitLocker = $CuaSo.FindName("chkBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE")
$chkAnydesk = $CuaSo.FindName("chkAnydesk"); $chkActive = $CuaSo.FindName("chkActive"); $chkApps = $CuaSo.FindName("chkApps")

function LamMoi-UI { [System.Windows.Forms.Application]::DoEvents() }

# --- HÀM THỰC THI CHÍNH (ĐÃ ĐẬP ĐI XÂY LẠI) ---
function KhoiChay-TrienKhai($PathWim, $IdxWim, $OptDrv, $OptBit, $OptOobe, $OptAny, $OptAct, $OptApp) {
    $DanhSachNut.IsEnabled = $false
    $VietBoot = "C:\VietBoot"
    if (!(Test-Path $VietBoot)) { New-Item $VietBoot -ItemType Directory -Force | Out-Null }

    try {
        # BƯỚC 1: FIX BOOT & EFI (10%)
        $pgBar.Value = 10; $lblStatus.Text = "Đang kiểm tra phân vùng khởi động..."; LamMoi-UI
        if (!(Get-Partition | Where-Object { $_.IsSystem })) {
            $disk = Get-Disk | Where-Object { $_.Number -eq 0 }
            "select disk $($disk.Number)`nclean`nconvert gpt`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S`ncreate partition msr size=16`ncreate partition primary`nformat quick fs=ntfs label='Windows'`nassign letter=C" | diskpart | Out-Null
        }

        # BƯỚC 2: SAO LƯU DRIVER (20%)
        if ($OptDrv) {
            $pgBar.Value = 20; $lblStatus.Text = "Đang trích xuất Driver hệ thống cũ..."; LamMoi-UI
            $DPath = "$VietBoot\Drivers"; if (!(Test-Path $DPath)) { New-Item $DPath -ItemType Directory -Force | Out-Null }
            dism /online /export-driver /destination:"$DPath" | Out-Null
        }

        # BƯỚC 3: GIẢI MÃ BITLOCKER (30%)
        $pgBar.Value = 30; $lblStatus.Text = "Đang vô hiệu hóa BitLocker..."; LamMoi-UI
        manage-bde -off C: | Out-Null
        while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 1 }

        # BƯỚC 4: TẢI CÔNG CỤ XỬ LÝ (40%)
        $WimlibExe = "$VietBoot\wimlib-imagex.exe"
        if (!(Test-Path $WimlibExe)) {
            $pgBar.Value = 40; $lblStatus.Text = "Đang tải Wimlib Engine (BITS)..."; LamMoi-UI
            Start-BitsTransfer -Source "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip" -Destination "$VietBoot\w.zip"
            powershell -c "Expand-Archive '$VietBoot\w.zip' '$VietBoot\wim' -Force"
            Copy-Item "$VietBoot\wim\*\wimlib-imagex.exe" $WimlibExe -Force
            Remove-Item "$VietBoot\w.zip" -Force; Remove-Item "$VietBoot\wim" -Recurse -Force
        }

        # BƯỚC 5: XỬ LÝ BỘ CÀI WIM (60%)
        $pgBar.Value = 60; $NameWim = [System.IO.Path]::GetFileName($PathWim); $FinalWim = "$VietBoot\$NameWim"
        $lblStatus.Text = "Đang nạp bộ cài: $NameWim"; LamMoi-UI
        if ($PathWim.StartsWith("http")) { Start-BitsTransfer -Source $PathWim -Destination $FinalWim }
        else { if (!(Test-Path $FinalWim)) { Copy-Item "$PathWim" "$FinalWim" -Force } }

        # BƯỚC 6: TRÍCH XUẤT WINRE (70%)
        $pgBar.Value = 70; $lblStatus.Text = "Đang chuẩn bị lõi WinRE..."; LamMoi-UI
        $BootWim = "$VietBoot\boot.wim"; $WinREOriginal = "C:\Windows\System32\Recovery\WinRE.wim"
        if (!(Test-Path $WinREOriginal)) {
            Start-Process $WimlibExe "extract `"$FinalWim`" $IdxWim /Windows/System32/Recovery/WinRE.wim --dest-dir=`"$VietBoot`"" -Wait -WindowStyle Hidden
            if (Test-Path "$VietBoot\WinRE.wim") { Move-Item "$VietBoot\WinRE.wim" $BootWim -Force }
        } else { Copy-Item "$WinREOriginal" $BootWim -Force }

        # BƯỚC 7: TẠO KỊCH BẢN (80%)
        $pgBar.Value = 80; $lblStatus.Text = "Đang xây dựng kịch bản tự động hóa..."; LamMoi-UI
        $Conf = "$VietBoot\Conf"; New-Item $Conf -ItemType Directory -Force | Out-Null
        
        # SetupComplete
        $sc = "@echo off`nmanage-bde -off C:`nnet accounts /maxpwage:unlimited`n"
        if ($OptAct) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /HWID`npowershell -c `"irm https://get.activated.win | iex`" /Ohook`n" }
        if ($OptApp) { $sc += "winget install --id Google.Chrome --silent`nwinget install --id WinRAR.WinRAR --silent`n" }
        $sc += "bcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$Conf\SetupComplete.cmd" -Encoding ASCII

        # Unattend (Silent OOBE)
        $u = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>false</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE></component></settings></unattend>
"@
        $u | Out-File "$Conf\u.xml" -Encoding UTF8

        # Startnet (WinPE Core)
        $sn = "@echo off`nwpeinit`nfor %%i in (C D E F G H I J K L M N O P) do (if exist `"%%i:\VietBoot\$NameWim`" set `"W=%%i:\VietBoot\$NameWim`")`n"
        $sn += "for /d %%a in (C:\*) do if /i not `"%%~nxa`"==`"VietBoot`" rd /s /q `"%%a`"`ndel /f /q C:\*.*`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$IdxWim /ApplyDir:C:\`n"
        $sn += "reg load HKLM\SYS C:\Windows\System32\config\SYSTEM`nreg add HKLM\SYS\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f`nreg add HKLM\SYS\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f`nreg add HKLM\SYS\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f`nreg unload HKLM\SYS`n"
        $sn += "reg load HKLM\O_S C:\Windows\System32\config\SOFTWARE`nreg add HKLM\O_S\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f`nreg add HKLM\O_S\Policies\Microsoft\FVE /v PreventDeviceEncryption /t REG_DWORD /d 1 /f`nreg unload HKLM\O_S`n"
        if ($OptDrv) { $sn += "if exist `"C:\VietBoot\Drivers`" dism /Image:C:\ /Add-Driver /Driver:`"C:\VietBoot\Drivers`" /Recurse`n" }
        $sn += "mkdir C:\Windows\Panther >nul & copy X:\Windows\System32\u.xml C:\Windows\Panther\unattend.xml /Y`nmkdir C:\Windows\Setup\Scripts >nul & copy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y`n"
        if ($OptAny) {
            $any = "@echo off`n:check`nping 8.8.8.8 -n 1 >nul`nif errorlevel 1 timeout /t 3 >nul & goto check`ncurl.exe -L -o `"C:\Users\Public\Desktop\AnyDesk.exe`" `"https://download.anydesk.com/AnyDesk.exe`"`nstart `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`ndel `"%~f0`""
            $any | Out-File "$Conf\Any.cmd" -Encoding ASCII
            $sn += "mkdir `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup`" >nul & copy X:\Windows\System32\Any.cmd `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Any.cmd`" /Y`n"
        }
        $sn += "bcdboot C:\Windows /s C: /f ALL`nwpeutil reboot"
        $sn | Out-File "$Conf\s.cmd" -Encoding ASCII

        # BƯỚC 8: TIÊM LÕI (90%)
        $pgBar.Value = 90; $lblStatus.Text = "Đang tiêm kịch bản vào WinRE..."; LamMoi-UI
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$VietBoot\boot.sdi" -Force
        $Tiem = "$VietBoot\tiem.txt"
        "add `"$Conf\u.xml`" `"\Windows\System32\u.xml`"`nadd `"$Conf\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$Conf\s.cmd`" `"\Windows\System32\startnet.cmd`"" | Out-File $Tiem -Encoding utf8
        Start-Process $WimlibExe "update `"$BootWim`" 1 < `"$Tiem`"" -Wait -WindowStyle Hidden

        # BƯỚC 9: CẤU HÌNH BOOT & REBOOT (100%)
        $pgBar.Value = 100; $lblStatus.Text = "Hoàn tất! Khởi động lại sau 2 giây..."; LamMoi-UI
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VB" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        Start-Sleep -Seconds 2; Restart-Computer -Force
    } catch { [System.Windows.MessageBox]::Show("Lỗi tại: $($_.InvocationInfo.MyCommand) - Nội dung: $_"); $DanhSachNut.IsEnabled = $true }
}

# --- NẠP DANH SÁCH CSV TỪ GITHUB ---
try {
    $url = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"
    $csv = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content | ConvertFrom-Csv
    foreach ($row in $csv) {
        $p = if ($row.Path) { $row.Path } else { $row.URL }; $idx = if ($row.Index) { $row.Index } else { "1" }
        $match = $false; foreach($prop in $row.PSObject.Properties) { if ($prop.Value -match "WIM") { $match = $true } }
        if ($p -match "\.wim" -or $match) {
            $btn = New-Object System.Windows.Controls.Button
            $btn.Style = $CuaSo.FindResource("ModernBtn")
            $btn.Content = if ($row.Name) { $row.Name } else { "Bản Windows WIM" }
            $btn.Tag = @{ p=$p; i=$idx }
            $btn.Add_Click({
                $d = $this.Tag; KhoiChay-TrienKhai $d.p $d.i $chkDriver.IsChecked $chkBitLocker.IsChecked $chkOOBE.IsChecked $chkAnydesk.IsChecked $chkActive.IsChecked $chkApps.IsChecked
            })
            $DanhSachNut.Children.Add($btn) | Out-Null
        }
    }
    $lblStatus.Text = "Nạp danh sách thành công."; LamMoi-UI
} catch { $lblStatus.Text = "Lỗi kết nối!"; [System.Windows.MessageBox]::Show("Lỗi tải CSV: $_") }

$CuaSo.ShowDialog() | Out-Null