# ==============================================================================
# VIETTOOLBOX V29 - FINAL REPAIR (ĐỈNH CAO TỰ ĐỘNG HÓA - BẢN MAX OPTIMIZE)
# Tính năng: Bất tử trước OOBE 25H2+, Tự Backup Wi-Fi, Tự tải AnyDesk, Local Admin.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN WPF MODERN (DARK THEME) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V29 - Tự Động Hóa 100%" Height="680" Width="640" 
        WindowStartupLocation="CenterScreen" Background="#0A0A0A">
    <Window.Resources>
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Background" Value="#00adb5"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/><Setter Property="Height" Value="35"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="25">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="VIETTOOLBOX V29" FontSize="28" FontWeight="Black" Foreground="#00adb5"/>
            <TextBlock Text="AUTO GHOST - BẤT TỬ OOBE (25H2) - BACKUP WIFI - ANYDESK" FontSize="11" Foreground="#555"/>
        </StackPanel>
        
        <StackPanel Grid.Row="1" Margin="0,0,0,12"><TextBlock Text="Tệp tin Windows (.wim / .esd / .iso):" Foreground="#888"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions><TextBox Name="txtWim" Background="#111" Foreground="White" IsReadOnly="True" Height="32" Padding="8,0"/><Button Name="btnWim" Grid.Column="1" Content="CHỌN FILE" Style="{StaticResource ModernBtn}" Margin="10,0,0,0"/></Grid></StackPanel>
        
        <StackPanel Grid.Row="2" Margin="0,0,0,12"><TextBlock Text="Thư mục Driver thêm (Tùy chọn):" Foreground="#888"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions><TextBox Name="txtDriver" Background="#111" Foreground="White" IsReadOnly="True" Height="32" Padding="8,0"/><Button Name="btnDriver" Grid.Column="1" Content="CHỌN DRV" Style="{StaticResource ModernBtn}" Margin="10,0,0,0" Background="#333"/></Grid></StackPanel>
        
        <Grid Grid.Row="3" Margin="0,5,0,20"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel><TextBlock Text="Phiên bản cài đặt:" Foreground="#888"/><ComboBox Name="cmbIndex" Height="32" Width="320" HorizontalAlignment="Left" Margin="0,4,0,0"/></StackPanel>
            <StackPanel Grid.Column="1" VerticalAlignment="Bottom">
                <CheckBox Name="chkOOBE" Content="Bỏ qua OOBE &amp; Bypass Mạng" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,5"/>
                <CheckBox Name="chkBitLocker" Content="Đòi tắt BitLocker" Foreground="#FFB300" IsChecked="True" Margin="0,0,0,5"/>
                <CheckBox Name="chkAnydesk" Content="Tự động tải &amp; chạy AnyDesk" Foreground="#4CAF50" IsChecked="True" Margin="0,0,0,5"/>
                <CheckBox Name="chkWifiBackup" Content="Sao lưu &amp; Khôi phục Driver + Wi-Fi" Foreground="#E91E63" IsChecked="True"/>
            </StackPanel>
        </Grid>
        
        <StackPanel Grid.Row="4"><ProgressBar Name="pgBar" Height="8" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/><TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng. (Lưu ý: Không để bộ cài ở ổ C)" Foreground="#666" HorizontalAlignment="Center" FontSize="11"/></StackPanel>
        
        <Button Name="btnStart" Grid.Row="6" Content="KÍCH HOẠT CÀI ĐẶT" Style="{StaticResource ModernBtn}" Height="60" Background="#D32F2F" FontSize="18" IsEnabled="False"/>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim")
$txtDriver = $CuaSo.FindName("txtDriver"); $btnDriver = $CuaSo.FindName("btnDriver"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$chkBitLocker = $CuaSo.FindName("chkBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE")
$chkAnydesk = $CuaSo.FindName("chkAnydesk"); $chkWifiBackup = $CuaSo.FindName("chkWifiBackup")
$pgBar = $CuaSo.FindName("pgBar"); $lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents(); [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

$btnWim.Add_Click({
    $fd = New-Object Microsoft.Win32.OpenFileDialog; 
    $fd.Filter = "Windows Image|*.wim;*.esd;*.swm;*.iso"
    if ($fd.ShowDialog()) {
        $duongDanFile = $fd.FileName
        if ($duongDanFile.StartsWith("C:\", [System.StringComparison]::OrdinalIgnoreCase)) {
            [System.Windows.MessageBox]::Show("CẢNH BÁO: Không được để file bộ cài trên ổ C vì ổ C sẽ bị format khi cài đặt. Vui lòng di chuyển file sang ổ khác!", "Cảnh báo an toàn", 0, 48)
            return
        }

        $duoiFile = [System.IO.Path]::GetExtension($duongDanFile).ToLower()
        $cmbIndex.Items.Clear()
        $btnStart.IsEnabled = $false

        if ($duoiFile -eq ".iso") {
            $lblStatus.Text = "Đang đọc nội dung file ISO..."
            LamMoi-GiaoDien
            try {
                $mountKetQua = Mount-DiskImage -ImagePath $duongDanFile -PassThru -NoDriveLetter:$false
                $oDiaAao = ($mountKetQua | Get-Volume).DriveLetter
                $duongDanWimTrongIso = "$oDiaAao`:\sources\install.wim"
                if (!(Test-Path $duongDanWimTrongIso)) { $duongDanWimTrongIso = "$oDiaAao`:\sources\install.esd" }
                
                if (Test-Path $duongDanWimTrongIso) {
                    $txtWim.Text = $duongDanFile
                    (Get-WindowsImage -ImagePath $duongDanWimTrongIso) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
                    if ($cmbIndex.Items.Count -gt 0) { $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true }
                } else {
                    [System.Windows.MessageBox]::Show("Không tìm thấy thư mục sources chứa install.wim hoặc install.esd!")
                }
                Dismount-DiskImage -ImagePath $duongDanFile | Out-Null
                $lblStatus.Text = "Trạng thái: Sẵn sàng."
            } catch {
                [System.Windows.MessageBox]::Show("Lỗi khi đọc file ISO: $_"); $lblStatus.Text = "Trạng thái: Lỗi đọc ISO."
            }
        } else {
            $txtWim.Text = $duongDanFile
            (Get-WindowsImage -ImagePath $duongDanFile) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
            if ($cmbIndex.Items.Count -gt 0) { $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true }
        }
    }
})

$btnDriver.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtDriver.Text = $fb.SelectedPath } })

$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; LamMoi-GiaoDien

    try {
        if ($chkBitLocker.IsChecked) {
            $lblStatus.Text = "Đang kiểm tra và giải mã BitLocker..."; LamMoi-GiaoDien
            manage-bde -off C: | Out-Null
            while ($true) {
                $st = manage-bde -status C:
                if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }
                Start-Sleep -Seconds 2; LamMoi-GiaoDien
            }
        }

        $thuMucChuaIso = [System.IO.Path]::GetDirectoryName($txtWim.Text)
        
        # --- BƯỚC SAO LƯU DRIVER VÀ WI-FI ---
        if ($chkWifiBackup.IsChecked) {
            $lblStatus.Text = "Đang sao lưu Driver & cấu hình Wi-Fi (Sẽ mất 1-3 phút)..."; $pgBar.Value = 5; LamMoi-GiaoDien
            $thuMucBackup = "$thuMucChuaIso\VietBoot_WifiBackup"
            if (!(Test-Path "$thuMucBackup\Drivers")) { New-Item "$thuMucBackup\Drivers" -ItemType Directory -Force | Out-Null }
            if (!(Test-Path "$thuMucBackup\Profiles")) { New-Item "$thuMucBackup\Profiles" -ItemType Directory -Force | Out-Null }
            
            cmd.exe /c "netsh wlan export profile key=clear folder=`"$thuMucBackup\Profiles`"" | Out-Null
            Start-Process dism.exe "/online /export-driver /destination:`"$thuMucBackup\Drivers`"" -Wait -WindowStyle Hidden
        }

        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $bootDir = "C:\VietBoot"
        if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }

        $duoiFileDauVao = [System.IO.Path]::GetExtension($txtWim.Text).ToLower()
        $wimPathHost = $txtWim.Text
        $wimFileName = [System.IO.Path]::GetFileName($txtWim.Text)

        if ($duoiFileDauVao -eq ".iso") {
            $lblStatus.Text = "Đang trích xuất file bộ cài từ ISO..."; $pgBar.Value = 10; LamMoi-GiaoDien
            $mountKetQua = Mount-DiskImage -ImagePath $txtWim.Text -PassThru -NoDriveLetter:$false
            $oDiaAao = ($mountKetQua | Get-Volume).DriveLetter
            $duongDanWimTrongIso = "$oDiaAao`:\sources\install.wim"
            $duoiXuat = ".wim"
            if (!(Test-Path $duongDanWimTrongIso)) { 
                $duongDanWimTrongIso = "$oDiaAao`:\sources\install.esd"
                $duoiXuat = ".esd"
            }
            
            $wimFileName = "install_extracted$duoiXuat"
            $wimPathHost = "$thuMucChuaIso\$wimFileName"
            Copy-Item $duongDanWimTrongIso $wimPathHost -Force
            Dismount-DiskImage -ImagePath $txtWim.Text | Out-Null
        }
        
        $lblStatus.Text = "Đang thiết lập môi trường WinRE tự động..."; $pgBar.Value = 20; LamMoi-GiaoDien
        $timThayRe = $false
        $danhSachRe = @("C:\Windows\System32\Recovery\WinRE.wim", "C:\Recovery\WindowsRE\WinRE.wim")

        foreach ($duongDan in $danhSachRe) {
            if (Test-Path $duongDan -Force) {
                attrib -h -s $duongDan | Out-Null
                Copy-Item $duongDan "$bootDir\boot.wim" -Force
                $timThayRe = $true
                break
            }
        }

        if (!$timThayRe) {
            $mountGoc = "C:\MountGoc"
            if (Test-Path $mountGoc) { Start-Process dism.exe "/Unmount-Image /MountDir:$mountGoc /Discard" -Wait -WindowStyle Hidden }
            New-Item $mountGoc -ItemType Directory -Force | Out-Null
            
            $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$wimPathHost`" /Index:$idx /MountDir:$mountGoc /ReadOnly" -PassThru -WindowStyle Hidden
            while (!$p.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 500 }

            $wimReDauVao = "$mountGoc\Windows\System32\Recovery\WinRE.wim"
            if (Test-Path $wimReDauVao -Force) { Copy-Item $wimReDauVao "$bootDir\boot.wim" -Force; $timThayRe = $true }

            Start-Process dism.exe "/Unmount-Image /MountDir:$mountGoc /Discard" -Wait -WindowStyle Hidden
        }

        if (!$timThayRe) { throw "Không thể tìm thấy WinRE!" }

        $sdiSearchList = @("C:\Windows\Boot\EFI\boot.sdi", "C:\Windows\Boot\PCAT\boot.sdi", "C:\Windows\System32\Recovery\boot.sdi")
        $foundSdi = $false
        foreach ($path in $sdiSearchList) {
            if (Test-Path $path) {
                takeown /f $path /a | Out-Null; icacls $path /grant Administrators:F | Out-Null
                Copy-Item $path "$bootDir\boot.sdi" -Force -ErrorAction SilentlyContinue
                $foundSdi = $true; break
            }
        }
        if (!$foundSdi) { throw "Thiếu file boot.sdi thiết yếu!" }

        $lblStatus.Text = "Đang nhúng kịch bản cấu hình sâu vào WinRE..."; $pgBar.Value = 40; LamMoi-GiaoDien
        $mount = "C:\MountTemp"
        if (Test-Path $mount) { Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Discard" -Wait -WindowStyle Hidden }
        New-Item $mount -ItemType Directory -Force | Out-Null
        
        $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mount" -PassThru -WindowStyle Hidden
        while (!$p.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 500 }

        $driverCmd = ""
        if (![string]::IsNullOrEmpty($txtDriver.Text)) { 
            Copy-Item -Path "$($txtDriver.Text)\*" -Destination "$bootDir\Drivers" -Recurse -Force
            $driverCmd = "echo Dang nap thu muc Driver tuy chon...`ndism /Image:C:\ /Add-Driver /Driver:X:\VietBoot\Drivers /Recurse >nul"
        }

        $anydeskCmd = ""
        if ($chkAnydesk.IsChecked) {
            $anydeskCmd = @"
echo Dang thiet lap Auto Download AnyDesk...
mkdir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" >nul 2>nul
(echo @echo off
echo title Setup AnyDesk
echo color 0B
echo echo ===================================================
echo echo   DANG KIEM TRA KET NOI MANG...
echo echo ===================================================
echo :checknet
echo ping 8.8.8.8 -n 1 ^>nul
echo if errorlevel 1 timeout /t 3 ^>nul ^& goto checknet
echo cls
echo echo ===================================================
echo echo   DA CO MANG! DANG TAI ANYDESK VE DESKTOP...
echo echo ===================================================
echo powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe' -UseBasicParsing"
echo start """" "C:\Users\Public\Desktop\AnyDesk.exe"
echo del "%%~f0"
)>"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\AutoAnyDesk.cmd"
"@
        }

        # KỊCH BẢN UNATTEND CẮT ĐỨT TOÀN BỘ GIAO DIỆN MẠNG & MICROSOFT ACCOUNT
        $unattend = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE>
<UserAccounts><LocalAccounts><LocalAccount action="Add"><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts>
<AutoLogon><Enabled>true</Enabled><Username>Admin</Username></AutoLogon></component></settings></unattend>
"@
        
        $cmd = @"
@echo off
wpeinit
set "WIM_NAME=$wimFileName"
set "WIM_PATH="
echo Dang tim file: %WIM_NAME%...
for %%i in (D E F G H I J K L M N O P) do (
    if exist "%%i:\%WIM_NAME%" set "WIM_PATH=%%i:\%WIM_NAME%"
    if exist "%%i:\VietBoot\%WIM_NAME%" set "WIM_PATH=%%i:\VietBoot\%WIM_NAME%"
    if exist "%%i:\*\%WIM_NAME%" for /d %%d in (%%i:\*) do if exist "%%d\%WIM_NAME%" set "WIM_PATH=%%d\%WIM_NAME%"
)
if not defined WIM_PATH (
    echo [LOI] Khong tim thay file $wimFileName. Dam bao ban khong de file o o C!
    pause & exit
)

for %%A in ("%WIM_PATH%") do set "WIM_DIR=%%~dpA"

echo Dang format o C...
format C: /fs:ntfs /q /y >nul

echo Dang Apply Windows (Index $idx) tu %WIM_PATH%...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\

$driverCmd

if exist "%WIM_DIR%VietBoot_WifiBackup\Drivers" (
    echo Dang khoi phuc Driver mang va he thong tu ban sao luu...
    dism /Image:C:\ /Add-Driver /Driver:"%WIM_DIR%VietBoot_WifiBackup\Drivers" /Recurse >nul
)

if exist "%WIM_DIR%VietBoot_WifiBackup\Profiles\*.xml" (
    echo Dang sao chep ho so ket noi Wi-Fi...
    mkdir C:\Windows\Setup\Scripts\WifiProfiles >nul 2>nul
    xcopy "%WIM_DIR%VietBoot_WifiBackup\Profiles\*.xml" "C:\Windows\Setup\Scripts\WifiProfiles\" /Y >nul
)

echo Dang nhung khao sat Offline Registry de triet tieu Windows 11 25H2+...
reg load HKLM\OfflineOOBE C:\Windows\System32\config\SOFTWARE >nul
reg add HKLM\OfflineOOBE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f >nul
reg add HKLM\OfflineOOBE\Microsoft\Windows\CurrentVersion\OOBE /v DisablePrivacyExperience /t REG_DWORD /d 1 /f >nul
reg add HKLM\OfflineOOBE\Microsoft\Windows\CurrentVersion\OOBE /v ProtectYourPC /t REG_DWORD /d 3 /f >nul
reg unload HKLM\OfflineOOBE >nul

mkdir C:\Windows\Panther >nul
echo $unattend > C:\Windows\Panther\unattend.xml

echo Dang tao bootloader...
bcdboot C:\Windows /s C: /f ALL

$anydeskCmd

echo Dang don dep Menu Boot truoc khi thoat...
bcdedit /delete %bootGuid% /f
bcdedit /delete %ramGuid% /f
bcdedit /timeout 0

mkdir C:\Windows\Setup\Scripts >nul
(echo @echo off
echo powershell -NoProfile -Command "Set-LocalUser -Name 'Admin' -PasswordNeverExpires `$true"
echo if exist "C:\Windows\Setup\Scripts\WifiProfiles\*.xml" ^(
echo     for %%%%f in ^("C:\Windows\Setup\Scripts\WifiProfiles\*.xml"^) do netsh wlan add profile filename="%%%%f" user=all ^>nul
echo     rd /s /q "C:\Windows\Setup\Scripts\WifiProfiles"
echo ^)
echo bcdedit /timeout 0
echo rd /s /q "C:\VietBoot"
echo del %%0)>C:\Windows\Setup\Scripts\SetupComplete.cmd

wpeutil reboot
"@
        $cmd | Out-File "$mount\Windows\System32\startnet.cmd" -Encoding ASCII -Force
        "[LaunchApps]`ncmd.exe, /c %SYSTEMROOT%\System32\startnet.cmd" | Out-File "$mount\Windows\System32\winpeshl.ini" -Encoding ASCII -Force

        $lblStatus.Text = "Đang lưu lại cấu hình WinRE..."; $pgBar.Value = 80; LamMoi-GiaoDien
        $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mount /Commit" -PassThru -WindowStyle Hidden
        while (!$p.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 500 }

        $lblStatus.Text = "Đang cấu hình phân vùng khởi động..."; LamMoi-GiaoDien
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

        $lblStatus.Text = "HOÀN TẤT! Đang khởi động lại..."; $pgBar.Value = 100; LamMoi-GiaoDien
        Start-Sleep -Seconds 2
        Restart-Computer -Force
    } catch { 
        [System.Windows.MessageBox]::Show("Lỗi hệ thống: $_") 
        $btnStart.IsEnabled = $true
        $lblStatus.Text = "Lỗi: Không thể thực hiện cài đặt."
    }
})

$CuaSo.ShowDialog() | Out-Null