# ==============================================================================
# VIETTOOLBOX V31.5 - BẢN HIỆN HÌNH (SHOW ALL LOGS)
# Tính năng: Bật cửa sổ Console cho mọi tiến trình nặng để dễ dàng theo dõi.
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN WPF MODERN (DARK THEME) ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V31.5 - Bản Hiện Hình Console" Height="680" Width="640" 
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
            <TextBlock Text="VIETTOOLBOX V31.5" FontSize="28" FontWeight="Black" Foreground="#00adb5"/>
            <TextBlock Text="SMART WIPE - LÕI C/C++ - HIỂN THỊ MỌI TIẾN TRÌNH" FontSize="11" Foreground="#555"/>
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
        
        <StackPanel Grid.Row="4"><ProgressBar Name="pgBar" Height="8" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/><TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng." Foreground="#666" HorizontalAlignment="Center" FontSize="11"/></StackPanel>
        
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
    $fd = New-Object Microsoft.Win32.OpenFileDialog; $fd.Filter = "Windows Image|*.wim;*.esd;*.swm;*.iso"
    if ($fd.ShowDialog()) {
        $duongDanFile = $fd.FileName
        $duoiFile = [System.IO.Path]::GetExtension($duongDanFile).ToLower()
        $cmbIndex.Items.Clear(); $btnStart.IsEnabled = $false

        if ($duoiFile -eq ".iso") {
            $lblStatus.Text = "Đang đọc nội dung file ISO..."; LamMoi-GiaoDien
            try {
                $mountKetQua = Mount-DiskImage -ImagePath $duongDanFile -PassThru -NoDriveLetter:$false
                $oDiaAao = ($mountKetQua | Get-Volume).DriveLetter
                $duongDanWimTrongIso = "$oDiaAao`:\sources\install.wim"
                if (!(Test-Path $duongDanWimTrongIso)) { $duongDanWimTrongIso = "$oDiaAao`:\sources\install.esd" }
                if (Test-Path $duongDanWimTrongIso) {
                    $txtWim.Text = $duongDanFile
                    (Get-WindowsImage -ImagePath $duongDanWimTrongIso) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
                    if ($cmbIndex.Items.Count -gt 0) { $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true }
                }
                Dismount-DiskImage -ImagePath $duongDanFile | Out-Null
                $lblStatus.Text = "Trạng thái: Sẵn sàng."
            } catch { [System.Windows.MessageBox]::Show("Lỗi: $_") }
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
            $lblStatus.Text = "Đang giải mã BitLocker..."; LamMoi-GiaoDien
            manage-bde -off C: | Out-Null
            while ($true) { $st = manage-bde -status C:; if ($st -like "*Fully Decrypted*" -or $st -like "*None*") { break }; Start-Sleep -Seconds 2 }
        }

        $bootDir = "C:\VietBoot"
        if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
        
        if (![string]::IsNullOrEmpty($txtDriver.Text)) {
            $lblStatus.Text = "Đang chép Driver tùy chọn vào vùng an toàn..."; LamMoi-GiaoDien
            Copy-Item -Path "$($txtDriver.Text)\*" -Destination "$bootDir\VietBoot_CustomDrivers" -Recurse -Force
        }

        if ($chkWifiBackup.IsChecked) {
            $lblStatus.Text = "Đang mở cửa sổ sao lưu Driver & cấu hình Wi-Fi..."; $pgBar.Value = 10; LamMoi-GiaoDien
            $thuMucBackup = "$bootDir\VietBoot_WifiBackup"
            New-Item "$thuMucBackup\Drivers" -ItemType Directory -Force | Out-Null
            New-Item "$thuMucBackup\Profiles" -ItemType Directory -Force | Out-Null
            cmd.exe /c "netsh wlan export profile key=clear folder=`"$thuMucBackup\Profiles`"" | Out-Null
            # Chạy DISM ở chế độ Cửa sổ (WindowStyle Normal)
            Start-Process dism.exe "/online /export-driver /destination:`"$thuMucBackup\Drivers`"" -Wait -WindowStyle Normal
        }

        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()

        # --- CHUẨN BỊ WIMLIB C/C++ ---
        $thuMucWimlib = "C:\VietBoot\wimlib"
        $fileExeWimlib = "$thuMucWimlib\wimlib-1.14.5-windows-x86_64-bin\wimlib-imagex.exe"
        $fileWimlibLocal = "$PSScriptRoot\wimlib-imagex.exe"

        if (Test-Path $fileWimlibLocal) {
            if (!(Test-Path $thuMucWimlib)) { New-Item $thuMucWimlib -ItemType Directory -Force | Out-Null }
            $fileExeWimlib = "$thuMucWimlib\wimlib-imagex.exe"
            Copy-Item $fileWimlibLocal $fileExeWimlib -Force
        }
        elseif (!(Test-Path $fileExeWimlib)) {
            $lblStatus.Text = "Đang bật cửa sổ tải lõi Wimlib 1.14.5..."; $pgBar.Value = 15; LamMoi-GiaoDien
            if (!(Test-Path $thuMucWimlib)) { New-Item $thuMucWimlib -ItemType Directory -Force | Out-Null }
            $lenhTai = "powershell -NoProfile -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip' -OutFile 'C:\VietBoot\wimlib.zip' -UseBasicParsing -TimeoutSec 10`"; powershell -NoProfile -Command `"if (Test-Path 'C:\VietBoot\wimlib.zip') { Expand-Archive -Path 'C:\VietBoot\wimlib.zip' -DestinationPath 'C:\VietBoot\wimlib' -Force }`""
            # Bật Console tải file (Normal)
            $tienTrinh = Start-Process cmd.exe -ArgumentList "/c $lenhTai" -PassThru -WindowStyle Normal
            while (!$tienTrinh.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 200 }
        }

        $suDungWimlib = (Test-Path $fileExeWimlib)

        $duoiFileDauVao = [System.IO.Path]::GetExtension($txtWim.Text).ToLower()
        $wimPathHost = $txtWim.Text
        $wimFileName = [System.IO.Path]::GetFileName($txtWim.Text)

        if ($duoiFileDauVao -eq ".iso") {
            $lblStatus.Text = "Đang kéo bộ cài từ ISO vào vùng an toàn (Sẽ mất vài phút)..."; $pgBar.Value = 20; LamMoi-GiaoDien
            $mountKetQua = Mount-DiskImage -ImagePath $txtWim.Text -PassThru -NoDriveLetter:$false
            $oDiaAao = ($mountKetQua | Get-Volume).DriveLetter
            $duongDanWimTrongIso = "$oDiaAao`:\sources\install.wim"
            $duoiXuat = ".wim"
            if (!(Test-Path $duongDanWimTrongIso)) { $duongDanWimTrongIso = "$oDiaAao`:\sources\install.esd"; $duoiXuat = ".esd" }
            $wimFileName = "install_extracted$duoiXuat"
            $wimPathHost = "$bootDir\$wimFileName"
            Copy-Item $duongDanWimTrongIso $wimPathHost -Force
            Dismount-DiskImage -ImagePath $txtWim.Text | Out-Null
        }
        
        $lblStatus.Text = "Đang tìm WinRE trên hệ thống cục bộ..."; $pgBar.Value = 30; LamMoi-GiaoDien
        $timThayRe = $false
        foreach ($duongDan in @("C:\Windows\System32\Recovery\WinRE.wim", "C:\Recovery\WindowsRE\WinRE.wim")) {
            if (Test-Path $duongDan) { attrib -h -s $duongDan | Out-Null; Copy-Item $duongDan "$bootDir\boot.wim" -Force; $timThayRe = $true; break }
        }

        if (!$timThayRe) {
            # --- TRÍCH XUẤT WINRE SIÊU TỐC BẰNG WIMLIB ---
            if ($suDungWimlib) {
                $lblStatus.Text = "Đang bật CMD trích xuất WinRE bằng lõi C/C++..."; LamMoi-GiaoDien
                $lenhExtract = "/c `"`"$fileExeWimlib`" extract `"$wimPathHost`" $idx `"\Windows\System32\Recovery\WinRE.wim`" --dest-dir=`"$bootDir`" --no-acls`""
                # Bật Console Extract (Normal)
                $p = Start-Process cmd.exe -ArgumentList $lenhExtract -PassThru -WindowStyle Normal
                while (!$p.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 200 }
                
                if (Test-Path "$bootDir\WinRE.wim") { 
                    Rename-Item -Path "$bootDir\WinRE.wim" -NewName "boot.wim" -Force
                    $timThayRe = $true 
                }
            } 
            # --- NẾU WIMLIB XỊT THÌ MỚI QUAY LẠI CÁI MÁNG LỢN DISM ---
            else {
                $lblStatus.Text = "Đang bật cửa sổ DISM trích xuất (Có thể mất 5-10 phút)..."; LamMoi-GiaoDien
                $mountGoc = "C:\MountGoc"; if (!(Test-Path $mountGoc)) { New-Item $mountGoc -ItemType Directory -Force | Out-Null }
                # Bật Console DISM Mount (Normal)
                $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$wimPathHost`" /Index:$idx /MountDir:$mountGoc /ReadOnly" -PassThru -WindowStyle Normal
                while (!$p.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 500 }
                
                if (Test-Path "$mountGoc\Windows\System32\Recovery\WinRE.wim") { Copy-Item "$mountGoc\Windows\System32\Recovery\WinRE.wim" "$bootDir\boot.wim" -Force; $timThayRe = $true }
                # Bật Console DISM Unmount (Normal)
                Start-Process dism.exe "/Unmount-Image /MountDir:$mountGoc /Discard" -Wait -WindowStyle Normal
            }
        }

        if (!$timThayRe) { throw "Lỗi nghiêm trọng: File cài đặt này đã bị lược bỏ mất WinRE bên trong!" }

        $sdiSearchList = @("C:\Windows\Boot\EFI\boot.sdi", "C:\Windows\Boot\PCAT\boot.sdi", "C:\Windows\System32\Recovery\boot.sdi")
        $foundSdi = $false
        foreach ($path in $sdiSearchList) {
            if (Test-Path $path) { takeown /f $path /a | Out-Null; icacls $path /grant Administrators:F | Out-Null; Copy-Item $path "$bootDir\boot.sdi" -Force -ErrorAction SilentlyContinue; $foundSdi = $true; break }
        }

        # --- CHUẨN BỊ FILE CẤU HÌNH ---
        $lblStatus.Text = "Đang chuẩn bị kịch bản tiêm bộ nhớ..."; $pgBar.Value = 40; LamMoi-GiaoDien
        $thuMucTam = "C:\VietBoot\TempConf"; New-Item $thuMucTam -ItemType Directory -Force | Out-Null
        
        "[LaunchApps]`ncmd.exe, /c %SYSTEMROOT%\System32\startnet.cmd" | Out-File "$thuMucTam\winpeshl.ini" -Encoding ASCII
        
        @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE>
<UserAccounts><LocalAccounts><LocalAccount action="Add"><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts>
<AutoLogon><Enabled>true</Enabled><Username>Admin</Username></AutoLogon></component></settings></unattend>
"@ | Out-File "$thuMucTam\unattend.xml" -Encoding UTF8

        @"
@echo off
powershell -NoProfile -Command "Set-LocalUser -Name 'Admin' -PasswordNeverExpires `$true"
if exist "C:\Windows\Setup\Scripts\WifiProfiles\*.xml" (
    for %%f in ("C:\Windows\Setup\Scripts\WifiProfiles\*.xml") do netsh wlan add profile filename="%%f" user=all >nul
    rd /s /q "C:\Windows\Setup\Scripts\WifiProfiles"
)
bcdedit /timeout 0
rd /s /q "C:\VietBoot"
del "%~f0"
"@ | Out-File "$thuMucTam\SetupComplete.cmd" -Encoding ASCII

        @"
@echo off
title Setup AnyDesk
color 0B
echo ===================================================
echo   DANG KIEM TRA KET NOI MANG...
echo ===================================================
:checknet
ping 8.8.8.8 -n 1 >nul
if errorlevel 1 timeout /t 3 >nul & goto checknet
cls
echo ===================================================
echo   DA CO MANG! DANG TAI ANYDESK VE DESKTOP...
echo ===================================================
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe' -UseBasicParsing"
start "" "C:\Users\Public\Desktop\AnyDesk.exe"
del "%~f0"
"@ | Out-File "$thuMucTam\AutoAnyDesk.cmd" -Encoding ASCII

        $anyDeskLichTrinh = ""
        if ($chkAnydesk.IsChecked) {
            $anyDeskLichTrinh = @"
if exist X:\Windows\System32\AutoAnyDesk.cmd (
    mkdir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" >nul 2>nul
    copy X:\Windows\System32\AutoAnyDesk.cmd "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\AutoAnyDesk.cmd" /Y >nul
)
"@
        }

        # KỊCH BẢN SMART WIPE
        @"
@echo off
wpeinit
set "WIM_NAME=$wimFileName"
set "WIM_PATH="
echo Dang tim file: %WIM_NAME%...
for %%i in (C D E F G H I J K L M N O P) do (
    if exist "%%i:\%WIM_NAME%" set "WIM_PATH=%%i:\%WIM_NAME%"
    if exist "%%i:\VietBoot\%WIM_NAME%" set "WIM_PATH=%%i:\VietBoot\%WIM_NAME%"
    if exist "%%i:\*\%WIM_NAME%" for /d %%d in (%%i:\*) do if exist "%%d\%WIM_NAME%" set "WIM_PATH=%%d\%WIM_NAME%"
)
if not defined WIM_PATH ( echo [LOI] Khong tim thay file $wimFileName. & pause & exit )

echo Dang don dep o C (Khong Format - Bao toan vung an toan VietBoot)...
for /d %%i in (C:\*) do (
    if /i not "%%~nxi"=="VietBoot" rd /s /q "%%i" >nul 2>&1
)
del /f /q /a C:\*.* >nul 2>&1

echo Dang Apply Windows (Index $idx) tu %WIM_PATH%...
dism /Apply-Image /ImageFile:"%WIM_PATH%" /Index:$idx /ApplyDir:C:\

if exist "C:\VietBoot\VietBoot_CustomDrivers" (
    echo Dang nap Driver tuy chon...
    dism /Image:C:\ /Add-Driver /Driver:"C:\VietBoot\VietBoot_CustomDrivers" /Recurse >nul
)

if exist "C:\VietBoot\VietBoot_WifiBackup\Drivers" (
    echo Dang khoi phuc Driver mang sao luu...
    dism /Image:C:\ /Add-Driver /Driver:"C:\VietBoot\VietBoot_WifiBackup\Drivers" /Recurse >nul
)

if exist "C:\VietBoot\VietBoot_WifiBackup\Profiles\*.xml" (
    mkdir C:\Windows\Setup\Scripts\WifiProfiles >nul 2>nul
    xcopy "C:\VietBoot\VietBoot_WifiBackup\Profiles\*.xml" "C:\Windows\Setup\Scripts\WifiProfiles\" /Y >nul
)

echo Dang nhung khao sat Offline Registry de triet tieu Windows 11...
reg load HKLM\OfflineOOBE C:\Windows\System32\config\SOFTWARE >nul
reg add HKLM\OfflineOOBE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f >nul
reg add HKLM\OfflineOOBE\Microsoft\Windows\CurrentVersion\OOBE /v DisablePrivacyExperience /t REG_DWORD /d 1 /f >nul
reg add HKLM\OfflineOOBE\Microsoft\Windows\CurrentVersion\OOBE /v ProtectYourPC /t REG_DWORD /d 3 /f >nul
reg unload HKLM\OfflineOOBE >nul

mkdir C:\Windows\Panther >nul 2>nul
copy X:\Windows\System32\unattend.xml C:\Windows\Panther\unattend.xml /Y >nul

mkdir C:\Windows\Setup\Scripts >nul 2>nul
copy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y >nul

$anyDeskLichTrinh

echo Dang tao bootloader...
bcdboot C:\Windows /s C: /f ALL

bcdedit /delete %bootGuid% /f >nul 2>nul
bcdedit /delete %ramGuid% /f >nul 2>nul
bcdedit /timeout 0

wpeutil reboot
"@ | Out-File "$thuMucTam\startnet.cmd" -Encoding ASCII


        # --- TIÊM DỮ LIỆU ---
        if ($suDungWimlib) {
            $lblStatus.Text = "Đang mở cửa sổ tiêm dữ liệu vào WinRE bằng lõi WimLib..."; $pgBar.Value = 70; LamMoi-GiaoDien
            $lenhUpdate = @(
                "add `"$thuMucTam\winpeshl.ini`" `"\Windows\System32\winpeshl.ini`"",
                "add `"$thuMucTam\unattend.xml`" `"\Windows\System32\unattend.xml`"",
                "add `"$thuMucTam\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"",
                "add `"$thuMucTam\startnet.cmd`" `"\Windows\System32\startnet.cmd`""
            )
            if ($chkAnydesk.IsChecked) { $lenhUpdate += "add `"$thuMucTam\AutoAnyDesk.cmd`" `"\Windows\System32\AutoAnyDesk.cmd`"" }
            
            $lenhUpdate -join "`r`n" | Out-File "$thuMucTam\wimlib_update.txt" -Encoding utf8
            $lenhTiem = "/c `"`"$fileExeWimlib`" update `"$bootDir\boot.wim`" 1 < `"$thuMucTam\wimlib_update.txt`"`""
            # Bật Console Update (Normal)
            Start-Process cmd.exe -ArgumentList $lenhTiem -Wait -WindowStyle Normal
        } else {
            $lblStatus.Text = "Đang mở cửa sổ DISM Native để chèn dữ liệu..."; $pgBar.Value = 70; LamMoi-GiaoDien
            $mountTiem = "C:\MountTiem"
            if (!(Test-Path $mountTiem)) { New-Item $mountTiem -ItemType Directory -Force | Out-Null }
            
            # Bật Console DISM Mount (Normal)
            $p = Start-Process dism.exe "/Mount-Image /ImageFile:`"$bootDir\boot.wim`" /Index:1 /MountDir:$mountTiem" -PassThru -WindowStyle Normal
            while (!$p.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 500 }
            
            Copy-Item "$thuMucTam\winpeshl.ini" "$mountTiem\Windows\System32\winpeshl.ini" -Force
            Copy-Item "$thuMucTam\unattend.xml" "$mountTiem\Windows\System32\unattend.xml" -Force
            Copy-Item "$thuMucTam\SetupComplete.cmd" "$mountTiem\Windows\System32\SetupComplete.cmd" -Force
            Copy-Item "$thuMucTam\startnet.cmd" "$mountTiem\Windows\System32\startnet.cmd" -Force
            if ($chkAnydesk.IsChecked) { Copy-Item "$thuMucTam\AutoAnyDesk.cmd" "$mountTiem\Windows\System32\AutoAnyDesk.cmd" -Force }
            
            $lblStatus.Text = "Đang mở cửa sổ lưu cấu hình DISM..."; LamMoi-GiaoDien
            # Bật Console DISM Commit (Normal)
            $p = Start-Process dism.exe "/Unmount-Image /MountDir:$mountTiem /Commit" -PassThru -WindowStyle Normal
            while (!$p.HasExited) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 500 }
        }

        # --- ĐĂNG KÝ BCD ---
        $lblStatus.Text = "Đang cấu hình phân vùng khởi động..."; $pgBar.Value = 90; LamMoi-GiaoDien
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