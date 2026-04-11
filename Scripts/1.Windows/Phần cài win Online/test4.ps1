<#
.SYNOPSIS
    CÔNG CỤ TRIỂN KHAI WINDOWS TỰ ĐỘNG - V7 (TÍCH HỢP UNATTEND.XML TRỊ TẬN GỐC OOBE)
#>

# ==========================================
# 1. YÊU CẦU QUYỀN ADMIN & ÉP LUỒNG STA
# ==========================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ==========================================
# 2. BIẾN ĐỒNG BỘ TOÀN CỤC
# ==========================================
$Global:TrangThaiHethong = [hashtable]::Synchronized(@{
    TienDo = 0; Log = ""; TrangThai = "Sẵn sàng"; DangChay = $false; KetThuc = $false; Loi = ""
})

# ==========================================
# 3. GIAO DIỆN WPF (XAML)
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Zero-Touch Deployment V7 (Trị Tận Gốc OOBE Win 10/11)" 
        Width="780" Height="880" WindowStartupLocation="CenterScreen" Background="#F8FAFC">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="HỆ THỐNG TRIỂN KHAI WINDOWS TỰ ĐỘNG" FontSize="24" FontWeight="Bold" Foreground="#0F172A" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#E2E8F0" BorderThickness="1">
            <StackPanel>
                <TextBlock Text="1. Nguồn dữ liệu (Hỗ trợ ISO, WIM, ESD):" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                    <TextBox Name="HopFileBoCai" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0" BorderBrush="#CBD5E1"/>
                    <Button Name="NutChonFile" Grid.Column="1" Content="📂 Chọn ISO/WIM" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                </Grid>
                <ComboBox Name="DanhSachBanWin" Height="32" Margin="0,0,0,8" VerticalContentAlignment="Center" BorderBrush="#CBD5E1">
                    <ComboBoxItem Content="Chưa tải bộ cài..." IsSelected="True"/>
                </ComboBox>
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                    <TextBox Name="HopThuMucDriver" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0" BorderBrush="#CBD5E1"/>
                    <Button Name="NutChonDriver" Grid.Column="1" Content="🖨️ Chọn Driver" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                </Grid>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#E2E8F0" BorderThickness="1">
            <StackPanel>
                <TextBlock Text="2. Cấu hình Windows (Zero-Touch):" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid Margin="0,0,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <TextBlock Text="Tên Tài Khoản:" VerticalAlignment="Center" FontWeight="Bold" Foreground="#475569"/>
                    <TextBox Name="TxtTenUser" Grid.Column="1" Height="32" VerticalContentAlignment="Center" Text="Admin" FontWeight="Bold" Padding="10,0" BorderBrush="#CBD5E1"/>
                </Grid>
                <CheckBox Name="ChkOOBE" Content="Sử dụng Unattend.xml tiêu diệt OOBE 100% (Cho cả Win 10 &amp; 11)" IsChecked="True" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,8"/>
                <CheckBox Name="ChkLogon" Content="Tự động đăng nhập thẳng vào Desktop" IsChecked="True" FontWeight="Bold" Foreground="#0F172A"/>
            </StackPanel>
        </Border>

        <Border Grid.Row="3" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#E2E8F0" BorderThickness="1">
            <StackPanel>
                <TextBlock Text="3. Tùy chọn Module Mở rộng:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <UniformGrid Columns="2">
                    <CheckBox Name="ChkBackupDriver" Content="Rút Driver hiện hành (LAN, Wi-Fi...)" IsChecked="True" Foreground="#10B981" FontWeight="Bold" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkWifi" Content="Sao lưu Mật khẩu Wi-Fi" IsChecked="True" Foreground="#334155" FontWeight="Bold" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkBitLocker" Content="Tắt BitLocker ổ C" IsChecked="True" Foreground="#334155" FontWeight="Bold" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkTPM" Content="Bypass TPM 2.0 &amp; CPU" IsChecked="True" Foreground="#E11D48" FontWeight="Bold" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkAnyDesk" Content="Tải &amp; Bật AnyDesk" IsChecked="True" Foreground="#0284C7" FontWeight="Bold"/>
                </UniformGrid>
            </StackPanel>
        </Border>

        <Border Grid.Row="4" Background="#0F172A" CornerRadius="8" Margin="0,0,0,15" Padding="10">
            <TextBox Name="HopNhatKy" Background="Transparent" Foreground="#10B981" FontFamily="Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
        </Border>

        <StackPanel Grid.Row="5" Margin="0,0,0,15">
            <Grid Margin="0,0,0,5">
                <TextBlock Name="TxtTrangThai" Text="Sẵn sàng" FontWeight="Bold" Foreground="#0F172A"/>
                <TextBlock Name="TxtPhanTram" Text="0%" FontWeight="Bold" Foreground="#0284C7" HorizontalAlignment="Right"/>
            </Grid>
            <ProgressBar Name="ThanhTienDo" Height="18" Foreground="#0EA5E9" Background="#E2E8F0" BorderThickness="0"/>
        </StackPanel>

        <Button Name="NutKichHoat" Grid.Row="6" Content="🚀 BẮT ĐẦU TRIỂN KHAI HỆ THỐNG" Height="55" Background="#E11D48" Foreground="White" FontSize="18" FontWeight="Bold" BorderThickness="0"/>
    </Grid>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML); $UI = [Windows.Markup.XamlReader]::Load($TrinhDoc)
$HopFileBoCai = $UI.FindName("HopFileBoCai"); $NutChonFile = $UI.FindName("NutChonFile"); $DanhSachBanWin = $UI.FindName("DanhSachBanWin")
$HopThuMucDriver = $UI.FindName("HopThuMucDriver"); $NutChonDriver = $UI.FindName("NutChonDriver"); $TxtTenUser = $UI.FindName("TxtTenUser")
$ChkOOBE = $UI.FindName("ChkOOBE"); $ChkLogon = $UI.FindName("ChkLogon"); $ChkBitLocker = $UI.FindName("ChkBitLocker")
$ChkWifi = $UI.FindName("ChkWifi"); $ChkTPM = $UI.FindName("ChkTPM"); $ChkAnyDesk = $UI.FindName("ChkAnyDesk")
$ChkBackupDriver = $UI.FindName("ChkBackupDriver"); $HopNhatKy = $UI.FindName("HopNhatKy"); $TxtTrangThai = $UI.FindName("TxtTrangThai")
$TxtPhanTram = $UI.FindName("TxtPhanTram"); $ThanhTienDo = $UI.FindName("ThanhTienDo"); $NutKichHoat = $UI.FindName("NutKichHoat")

# ==========================================
# 4. TIMER ĐỒNG BỘ GIAO DIỆN CHỐNG ĐƠ
# ==========================================
$DongHoTimer = New-Object System.Windows.Threading.DispatcherTimer
$DongHoTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$DongHoTimer.Add_Tick({
    if ($Global:TrangThaiHethong.Log) { $HopNhatKy.AppendText($Global:TrangThaiHethong.Log); $HopNhatKy.ScrollToEnd(); $Global:TrangThaiHethong.Log = "" }
    $ThanhTienDo.Value = $Global:TrangThaiHethong.TienDo; $TxtPhanTram.Text = "$($Global:TrangThaiHethong.TienDo)%"; $TxtTrangThai.Text = $Global:TrangThaiHethong.TrangThai
    if ($Global:TrangThaiHethong.KetThuc) {
        $DongHoTimer.Stop()
        if ($Global:TrangThaiHethong.Loi) {
            [System.Windows.Forms.MessageBox]::Show($Global:TrangThaiHethong.Loi, "CÓ LỖI XẢY RA", 0, 16)
            $NutKichHoat.IsEnabled = $true; $UI.Cursor = [System.Windows.Input.Cursors]::Arrow
        } else {
            $TxtTrangThai.Text = "✅ Hoàn tất! Máy sẽ tự khởi động lại."
            $HopNhatKy.AppendText("`n[$((Get-Date).ToString('HH:mm:ss'))] 🚀 KẾT THÚC! HỆ THỐNG ĐANG RESET...")
            $HopNhatKy.ScrollToEnd()
            Restart-Computer -Force
        }
        $Global:TrangThaiHethong.DangChay = $false; $Global:TrangThaiHethong.KetThuc = $false
    }
})

# ==========================================
# 5. CÁC HÀM XỬ LÝ
# ==========================================
function Quet-ISO_WIM {
    $File = $HopFileBoCai.Text; if (-not (Test-Path $File)) { return }
    $DanhSachBanWin.Items.Clear(); $DanhSachBanWin.Items.Add("⏳ Đang quét danh sách..."); $DanhSachBanWin.SelectedIndex = 0
    $HopNhatKy.AppendText("`n[$((Get-Date).ToString('HH:mm:ss'))] 🔍 Đang phân tích: $File"); $UI.Cursor = [System.Windows.Input.Cursors]::Wait
    $Khung = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke("Background", [Action]{ $Khung.Continue = $false }) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($Khung)
    $FileWim = $File; $Mount = $false
    try {
        if ($File -match '(?i)\.iso$') {
            Mount-DiskImage -ImagePath $File -PassThru | Out-Null; Start-Sleep 1
            $KyTu = (Get-DiskImage -ImagePath $File | Get-Volume).DriveLetter[0]
            $FileWim = "$($KyTu):\sources\install.wim"; if (-not (Test-Path $FileWim)) { $FileWim = "$($KyTu):\sources\install.esd" }
            $Mount = $true
        }
        if (Test-Path $FileWim) {
            $ThongTin = dism.exe /Get-WimInfo /WimFile:$FileWim /English; $Idx = $null; $Dem = 0; $DanhSachBanWin.Items.Clear()
            foreach ($Dong in $ThongTin) {
                if ($Dong -match 'Index : (\d+)') { $Idx = $matches[1] }
                if ($Dong -match 'Name : (.*)' -and $Idx) { $DanhSachBanWin.Items.Add("Index $($Idx): $($matches[1])") | Out-Null; $Idx = $null; $Dem++ }
            }
            if ($Dem -gt 0) { $DanhSachBanWin.SelectedIndex = 0 } else { $DanhSachBanWin.Items.Add("❌ Trống") | Out-Null }
        }
    } catch { $DanhSachBanWin.Items.Add("❌ Lỗi") | Out-Null } finally { if ($Mount) { Dismount-DiskImage -ImagePath $File | Out-Null }; $UI.Cursor = [System.Windows.Input.Cursors]::Arrow }
}

$NutChonFile.Add_Click({ $Hop = New-Object System.Windows.Forms.OpenFileDialog; $Hop.Filter = "Windows Image (*.wim;*.esd;*.iso)|*.wim;*.esd;*.iso"; if ($Hop.ShowDialog() -eq 'OK') { $HopFileBoCai.Text = $Hop.FileName; Quet-ISO_WIM } })
$NutChonDriver.Add_Click({ $KetQua = Chon-ThuMucHienDai "Chọn Thư mục chứa/Lưu Driver"; if ($KetQua) { $HopThuMucDriver.Text = $KetQua } })

# ==========================================
# 6. KÍCH HOẠT RUNSPACE (LÕI BACKGROUND)
# ==========================================
$KichBanNen = {
    param($G, $FileCai, $FileDriver, $IndexLoi, $TenUser, $OOBE, $Logon, $BitLocker, $Wifi, $TPM, $AnyDesk, $BackupDriver)
    function InLog($txt) { $G.Log += "`n[$((Get-Date).ToString('HH:mm:ss'))] $txt" }
    
    try {
        if ($FileDriver) {
            if ($BackupDriver) { $G.TrangThai = "Đang vắt kiệt Driver máy hiện tại..."; Export-WindowsDriver -Online -Destination $FileDriver | Out-Null; InLog "✅ Đã backup xong Driver!" }
            if ($Wifi) { InLog "Đang sao lưu Wi-Fi..."; Invoke-Expression "netsh wlan export profile key=clear folder=`"$FileDriver`"" | Out-Null }
        }

        if ($FileCai -match '(?i)\.iso$') {
            $G.TrangThai = "Đang giải nén ISO..."; InLog "Đang trích xuất ruột ISO, đợi một lát..."
            Mount-DiskImage -ImagePath $FileCai -PassThru | Out-Null; Start-Sleep 1
            $KyTuIso = (Get-DiskImage -ImagePath $FileCai | Get-Volume).DriveLetter[0]
            $Wim = "$($KyTuIso):\sources\install.wim"; $Esd = "$($KyTuIso):\sources\install.esd"
            $FileTrich = if (Test-Path $Wim) { $Wim } elseif (Test-Path $Esd) { $Esd } else { $null }
            $FileCaiDich = Join-Path ([System.IO.Path]::GetDirectoryName($FileCai)) ("install_extracted" + [System.IO.Path]::GetExtension($FileTrich))
            if (-not (Test-Path $FileCaiDich)) {
                $LuongVao = [System.IO.File]::OpenRead($FileTrich); $LuongRa = [System.IO.File]::Create($FileCaiDich)
                $BoNhoDem = New-Object byte[] (8 * 1024 * 1024); $Tong = $LuongVao.Length; $DaCopy = 0
                while (($DocDuoc = $LuongVao.Read($BoNhoDem, 0, $BoNhoDem.Length)) -gt 0) { $LuongRa.Write($BoNhoDem, 0, $DocDuoc); $DaCopy += $DocDuoc; $G.TienDo = [math]::Round(($DaCopy / $Tong) * 100) }
                $LuongVao.Close(); $LuongRa.Close()
            }
            Dismount-DiskImage -ImagePath $FileCai | Out-Null; $FileCai = $FileCaiDich
        }
        $G.TienDo = 100; $G.TrangThai = "Đang tạo kịch bản OOBE & WinRE..."

        # TẠO UNATTEND.XML ĐỂ TRỊ MÀN HÌNH XANH OOBE (ĐIỂM NÂNG CẤP V7)
        if ($OOBE) {
            $UnattendXML = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
        </component>
    </settings>
</unattend>
"@
            $UnattendXML | Out-File "$env:TEMP\unattend_ZT.xml" -Encoding utf8
        }

        # TẠO LỆNH SETUPCOMPLETE
        $Cmd = "@echo off`r`n"
        $Cmd += "net user `"$TenUser`" /add /passwordreq:no`r`n"
        $Cmd += "net localgroup administrators `"$TenUser`" /add`r`n"
        if ($TPM) {
            $Cmd += "reg add `"HKLM\SYSTEM\Setup\MoSetup`" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f`r`n"
            $Cmd += "reg add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassTPMCheck /t REG_DWORD /d 1 /f`r`n"
            $Cmd += "reg add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f`r`n"
        }
        if ($FileDriver) {
            if ($Wifi) { $Cmd += "for %%f in (`"$FileDriver\*.xml`") do netsh wlan add profile filename=`"%%f`" user=all`r`n" }
            $Cmd += "pnputil /add-driver `"$FileDriver\*.inf`" /subdirs /install`r`n"
        }
        if ($BitLocker) { $Cmd += "manage-bde -off C:`r`n" }
        if ($Logon) {
            $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v AutoAdminLogon /t REG_SZ /d 1 /f`r`n"
            $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v DefaultUserName /t REG_SZ /d `"$TenUser`" /f`r`n"
        }
        if ($AnyDesk) {
            $Cmd += "powershell -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'`"`r`n"
            $Cmd += "start `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`r`n"
        }
        $Cmd += "del %0`r`n"
        $Cmd | Out-File "$env:TEMP\SetupComplete_ZT.cmd" -Encoding oem

        # XỬ LÝ WINRE
        $ChuCaiO_Win = [System.IO.Path]::GetPathRoot($env:windir).Substring(0,1); $PhanVungOS = Get-Partition -DriveLetter $ChuCaiO_Win
        $OsDiskNum = $PhanVungOS.DiskNumber; $OsPartNum = $PhanVungOS.PartitionNumber; $DuongDanTuongDoi = $FileCai.Substring(3)
        $G.TrangThai = "Đang xử lý lõi WinRE (Khoảng 30 giây)..."
        reagentc.exe /enable | Out-Null; Start-Sleep 2; reagentc.exe /disable | Out-Null
        $WinREGoc = "C:\Windows\System32\Recovery\winre.wim"; $ThuMucMnt = "C:\MountRE"; $ThuMucXuLy = "C:\WinRE_XuLy"
        dism.exe /Cleanup-Wim | Out-Null
        if (Test-Path $ThuMucMnt) { dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Discard | Out-Null; Remove-Item $ThuMucMnt -Recurse -Force }
        New-Item -ItemType Directory -Path $ThuMucMnt | Out-Null; if (-not (Test-Path $ThuMucXuLy)) { New-Item -ItemType Directory -Path $ThuMucXuLy | Out-Null }
        $WinRECopy = "$ThuMucXuLy\winre.wim"; Copy-Item -Path $WinREGoc -Destination $WinRECopy -Force; Set-ItemProperty -Path $WinRECopy -Name IsReadOnly -Value $false
        dism.exe /Mount-Image /ImageFile:$WinRECopy /Index:1 /MountDir:$ThuMucMnt | Out-Null
        Copy-Item -Path "$env:TEMP\SetupComplete_ZT.cmd" -Destination "$ThuMucMnt\Windows\System32\SetupComplete_ZT.cmd" -Force
        if ($OOBE) { Copy-Item -Path "$env:TEMP\unattend_ZT.xml" -Destination "$ThuMucMnt\Windows\System32\unattend_ZT.xml" -Force }

        # LỆNH TRONG WINRE CÓ CHÈN UNATTEND.XML
        @"
@echo off
set "WIM_THUC_TE="; set "DRIVER_THUC_TE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\$DuongDanTuongDoi" set "WIM_THUC_TE=%%D:\$DuongDanTuongDoi"
    if exist "%%D:\$FileDriver" set "DRIVER_THUC_TE=%%D:\$FileDriver"
)

(echo select disk $OsDiskNum & echo select partition $OsPartNum & echo assign letter=W & echo format quick fs=ntfs label="Windows") | diskpart
dism /apply-image /imagefile:"%WIM_THUC_TE%" /index:$IndexLoi /applydir:W:\
if not "%DRIVER_THUC_TE%"=="" dism /image:W:\ /add-driver /driver:"%DRIVER_THUC_TE%" /recurse

echo Xoa BCD cu...
for %%p in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( if exist %%p:\EFI\Microsoft\Boot\BCD ( attrib -h -s -r %%p:\EFI\Microsoft\Boot\BCD & del /f /q %%p:\EFI\Microsoft\Boot\BCD ) )

bcdboot W:\Windows
bcdedit /timeout 0; bcdedit /set {default} bootstatuspolicy IgnoreAllFailures; bcdedit /set {default} recoveryenabled No

mkdir W:\Windows\Setup\Scripts
copy /Y X:\Windows\System32\SetupComplete_ZT.cmd W:\Windows\Setup\Scripts\SetupComplete.cmd
if exist X:\Windows\System32\unattend_ZT.xml (
    mkdir W:\Windows\Panther
    copy /Y X:\Windows\System32\unattend_ZT.xml W:\Windows\Panther\unattend.xml
)

del /F /Q X:\Windows\System32\winpeshl.ini
ping 127.0.0.1 -n 3 >nul
wpeutil reboot
exit
"@ | Out-File "$ThuMucMnt\Windows\System32\LenhRE.cmd" -Encoding oem
        "[LaunchApps]`r`nX:\Windows\System32\LenhRE.cmd" | Out-File "$ThuMucMnt\Windows\System32\winpeshl.ini" -Encoding ascii

        dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Commit | Out-Null; Remove-Item -Path $ThuMucMnt -Force
        Set-ItemProperty -Path $WinREGoc -Name IsReadOnly -Value $false; Copy-Item -Path $WinRECopy -Destination $WinREGoc -Force
        Remove-Item -Path $ThuMucXuLy -Recurse -Force
        reagentc.exe /enable | Out-Null; reagentc.exe /boottore | Out-Null

    } catch { $G.Loi = $_.Exception.Message } finally { $G.KetThuc = $true }
}

$NutKichHoat.Add_Click({
    $FileCai = $HopFileBoCai.Text; $FileDriver = $HopThuMucDriver.Text; $ChonIndex = $DanhSachBanWin.SelectedItem
    if (-not (Test-Path $FileCai)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn bộ cài!", "Lỗi", 0, 16); return }
    if ($ChonIndex -notmatch 'Index (\d+):') { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phiên bản!", "Lỗi", 0, 16); return }
    $IndexLoi = $matches[1]

    if ( ($ChkBackupDriver.IsChecked -or $ChkWifi.IsChecked) -and -not $FileDriver ) {
        [System.Windows.Forms.MessageBox]::Show("Bạn phải 'Chọn Driver' (Chọn 1 thư mục ở ổ D/E) để làm nơi lưu trữ Driver/Wi-Fi xuất ra!", "Lỗi", 0, 16); return
    }
    if ([System.Windows.Forms.MessageBox]::Show("BẠN SẮP FORMAT Ổ C.`nChắc chắn chưa?", "CẢNH BÁO TỐI THƯỢNG", 4, 48) -ne 'Yes') { return }

    $UI.Cursor = [System.Windows.Input.Cursors]::Wait; $NutKichHoat.IsEnabled = $false
    $Global:TrangThaiHethong.Log = ""; $Global:TrangThaiHethong.TienDo = 0; $Global:TrangThaiHethong.Loi = ""; $Global:TrangThaiHethong.DangChay = $true; $DongHoTimer.Start()

    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $TienTrinh = [powershell]::Create().AddScript($KichBanNen).AddArgument($Global:TrangThaiHethong).AddArgument($FileCai).AddArgument($FileDriver).AddArgument($IndexLoi).AddArgument($TxtTenUser.Text).AddArgument($ChkOOBE.IsChecked).AddArgument($ChkLogon.IsChecked).AddArgument($ChkBitLocker.IsChecked).AddArgument($ChkWifi.IsChecked).AddArgument($ChkTPM.IsChecked).AddArgument($ChkAnyDesk.IsChecked).AddArgument($ChkBackupDriver.IsChecked)
    $TienTrinh.Runspace = $MoiTruong; $TienTrinh.BeginInvoke() | Out-Null
})

$UI.ShowDialog() | Out-Null