<#
.SYNOPSIS
    CÔNG CỤ TRIỂN KHAI WINDOWS TỰ ĐỘNG - V8.1 (REGION TỐI ƯU & FULL NGÔN NGỮ CHÂU Á)
    Tác giả: Tuấn & AI Assistant
#>

# ==========================================
# 1. YÊU CẦU QUYỀN ADMIN & ÉP LUỒNG STA
# ==========================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ApartmentState STA -File $PSCommandPath ; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ==========================================
# 2. BIẾN ĐỒNG BỘ TOÀN CỤC
# ==========================================
$Global:TrangThaiHethong = [hashtable]::Synchronized(@{
    TienDo = 0; Log = ""; TrangThai = "Sẵn sàng"; DangChay = $false; KetThuc = $false; Loi = ""
})

# ==========================================
# 3. GIAO DIỆN WPF (XAML) - BỔ SUNG NGÔN NGỮ
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Zero-Touch Deployment V8.1 (Đa Ngôn Ngữ &amp; Region Tối Ưu)" 
        Width="780" Height="900" WindowStartupLocation="CenterScreen" Background="#F8FAFC">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="HỆ THỐNG TRIỂN KHAI WINDOWS TỰ ĐỘNG" FontSize="24" FontWeight="Bold" Foreground="#0F172A" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#E2E8F0" BorderThickness="1">
            <StackPanel>
                <TextBlock Text="1. Nguồn dữ liệu:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                    <TextBox Name="HopFileBoCai" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0"/>
                    <Button Name="NutChonFile" Grid.Column="1" Content="📂 Chọn Bộ Cài" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                </Grid>
                <ComboBox Name="DanhSachBanWin" Height="32" Margin="0,0,0,8" VerticalContentAlignment="Center"/>
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                    <TextBox Name="HopThuMucDriver" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0"/>
                    <Button Name="NutChonDriver" Grid.Column="1" Content="🖨️ Chọn Driver" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                </Grid>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#E2E8F0" BorderThickness="1">
            <StackPanel>
                <TextBlock Text="2. Cấu hình Hệ thống (Vùng &amp; Ngôn ngữ):" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid Margin="0,0,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="130"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <TextBlock Text="Ngôn ngữ hiển thị:" VerticalAlignment="Center" Foreground="#475569"/>
                    <ComboBox Name="CboLanguage" Grid.Column="1" Height="32" VerticalContentAlignment="Center">
                        <ComboBoxItem Content="Tiếng Anh (en-US)" Tag="en-US" IsSelected="True"/>
                        <ComboBoxItem Content="Tiếng Việt (vi-VN)" Tag="vi-VN"/>
                        <ComboBoxItem Content="Tiếng Trung Giản Thể (zh-CN)" Tag="zh-CN"/>
                        <ComboBoxItem Content="Tiếng Trung Phồn Thể (zh-TW)" Tag="zh-TW"/>
                        <ComboBoxItem Content="Tiếng Hàn Quốc (ko-KR)" Tag="ko-KR"/>
                        <ComboBoxItem Content="Tiếng Nhật Bản (ja-JP)" Tag="ja-JP"/>
                    </ComboBox>
                </Grid>
                <TextBlock Text="* Mặc định: Múi giờ +7 (Hà Nội) &amp; Định dạng ngày tháng kiểu Việt Nam (DD/MM/YYYY)" FontSize="11" Foreground="#0284C7" Margin="130,0,0,10"/>
                <Grid Margin="0,0,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="130"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <TextBlock Text="Tên Tài Khoản:" VerticalAlignment="Center" Foreground="#475569"/>
                    <TextBox Name="TxtTenUser" Grid.Column="1" Height="32" VerticalContentAlignment="Center" Text="Admin" FontWeight="Bold" Padding="10,0"/>
                </Grid>
            </StackPanel>
        </Border>

        <Border Grid.Row="3" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#E2E8F0" BorderThickness="1">
            <UniformGrid Columns="2">
                <CheckBox Name="ChkOOBE" Content="Bypass OOBE 100%" IsChecked="True" FontWeight="Bold" Margin="0,0,0,10"/>
                <CheckBox Name="ChkLogon" Content="Auto Logon Desktop" IsChecked="True" FontWeight="Bold" Margin="0,0,0,10"/>
                <CheckBox Name="ChkBackupDriver" Content="Backup Driver Mạng" IsChecked="True" Margin="0,0,0,10"/>
                <CheckBox Name="ChkTPM" Content="Bypass TPM 2.0" IsChecked="True" Foreground="#E11D48" FontWeight="Bold" Margin="0,0,0,10"/>
                <CheckBox Name="ChkAnyDesk" Content="Tải AnyDesk" IsChecked="True" Foreground="#0284C7" FontWeight="Bold"/>
                <CheckBox Name="ChkWifi" Content="Sao lưu Wi-Fi" IsChecked="True"/>
            </UniformGrid>
        </Border>

        <Border Grid.Row="4" Background="#0F172A" CornerRadius="8" Margin="0,0,0,15" Padding="10">
            <TextBox Name="HopNhatKy" Background="Transparent" Foreground="#10B981" FontFamily="Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
        </Border>

        <StackPanel Grid.Row="5" Margin="0,0,0,15">
            <ProgressBar Name="ThanhTienDo" Height="10" Foreground="#0EA5E9" Background="#E2E8F0" BorderThickness="0"/>
            <TextBlock Name="TxtTrangThai" Text="Sẵn sàng" FontSize="11" Margin="0,5,0,0" HorizontalAlignment="Center"/>
        </StackPanel>

        <Button Name="NutKichHoat" Grid.Row="6" Content="🚀 TRIỂN KHAI WINDOWS" Height="50" Background="#E11D48" Foreground="White" FontSize="18" FontWeight="Bold" BorderThickness="0"/>
    </Grid>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML); $UI = [Windows.Markup.XamlReader]::Load($TrinhDoc)
$HopFileBoCai = $UI.FindName("HopFileBoCai"); $NutChonFile = $UI.FindName("NutChonFile"); $DanhSachBanWin = $UI.FindName("DanhSachBanWin")
$HopThuMucDriver = $UI.FindName("HopThuMucDriver"); $NutChonDriver = $UI.FindName("NutChonDriver"); $TxtTenUser = $UI.FindName("TxtTenUser")
$CboLanguage = $UI.FindName("CboLanguage"); $ChkOOBE = $UI.FindName("ChkOOBE"); $ChkLogon = $UI.FindName("ChkLogon")
$ChkTPM = $UI.FindName("ChkTPM"); $ChkAnyDesk = $UI.FindName("ChkAnyDesk"); $ChkWifi = $UI.FindName("ChkWifi")
$ChkBackupDriver = $UI.FindName("ChkBackupDriver"); $HopNhatKy = $UI.FindName("HopNhatKy"); $TxtTrangThai = $UI.FindName("TxtTrangThai")
$ThanhTienDo = $UI.FindName("ThanhTienDo"); $NutKichHoat = $UI.FindName("NutKichHoat")

# ==========================================
# 4. TIMER ĐỒNG BỘ
# ==========================================
$DongHoTimer = New-Object System.Windows.Threading.DispatcherTimer
$DongHoTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$DongHoTimer.Add_Tick({
    if ($Global:TrangThaiHethong.Log) { $HopNhatKy.AppendText($Global:TrangThaiHethong.Log); $HopNhatKy.ScrollToEnd(); $Global:TrangThaiHethong.Log = "" }
    $ThanhTienDo.Value = $Global:TrangThaiHethong.TienDo; $TxtTrangThai.Text = $Global:TrangThaiHethong.TrangThai
    if ($Global:TrangThaiHethong.KetThuc) {
        $DongHoTimer.Stop()
        if ($Global:TrangThaiHethong.Loi) { [System.Windows.Forms.MessageBox]::Show($Global:TrangThaiHethong.Loi, "LỖI", 0, 16) }
        else { $HopNhatKy.AppendText("`n✅ XONG! ĐANG KHỞI ĐỘNG LẠI...") }
        $NutKichHoat.IsEnabled = $true
    }
})

# ==========================================
# 5. CÁC HÀM XỬ LÝ (QUÉT FILE)
# ==========================================
function Quet-ISO_WIM {
    $File = $HopFileBoCai.Text; if (-not (Test-Path $File)) { return }
    $DanhSachBanWin.Items.Clear(); $DanhSachBanWin.Items.Add("⏳ Đang quét..."); $DanhSachBanWin.SelectedIndex = 0
    $UI.Cursor = [System.Windows.Input.Cursors]::Wait
    $FileWim = $File; $Mount = $false
    try {
        if ($File -match '(?i)\.iso$') {
            Mount-DiskImage -ImagePath $File -PassThru | Out-Null; Start-Sleep 1
            $KyTu = (Get-DiskImage -ImagePath $File | Get-Volume).DriveLetter[0]
            $FileWim = "$($KyTu):\sources\install.wim"; if (-not (Test-Path $FileWim)) { $FileWim = "$($KyTu):\sources\install.esd" }
            $Mount = $true
        }
        if (Test-Path $FileWim) {
            $ThongTin = dism.exe /Get-WimInfo /WimFile:$FileWim /English; $Idx = $null; $DanhSachBanWin.Items.Clear()
            foreach ($Dong in $ThongTin) {
                if ($Dong -match 'Index : (\d+)') { $Idx = $matches[1] }
                if ($Dong -match 'Name : (.*)' -and $Idx) { $DanhSachBanWin.Items.Add("Index $($Idx): $($matches[1])") | Out-Null; $Idx = $null }
            }
            $DanhSachBanWin.SelectedIndex = 0
        }
    } catch { } finally { if ($Mount) { Dismount-DiskImage -ImagePath $File | Out-Null }; $UI.Cursor = [System.Windows.Input.Cursors]::Arrow }
}

$NutChonFile.Add_Click({ $Hop = New-Object System.Windows.Forms.OpenFileDialog; if ($Hop.ShowDialog() -eq 'OK') { $HopFileBoCai.Text = $Hop.FileName; Quet-ISO_WIM } })
$NutChonDriver.Add_Click({ $F = New-Object System.Windows.Forms.FolderBrowserDialog; if ($F.ShowDialog() -eq 'OK') { $HopThuMucDriver.Text = $F.SelectedPath } })

# ==========================================
# 6. KỊCH BẢN NỀN (CHẠY ĐA LUỒNG)
# ==========================================
$KichBanNen = {
    param($G, $FileCai, $FileDriver, $IndexLoi, $TenUser, $OOBE, $Logon, $TPM, $AnyDesk, $Wifi, $BackupDriver, $SelectedLang)
    
    try {
        if ($FileDriver -and $BackupDriver) { Export-WindowsDriver -Online -Destination $FileDriver | Out-Null }
        if ($FileDriver -and $Wifi) { Invoke-Expression "netsh wlan export profile key=clear folder=`"$FileDriver`"" | Out-Null }

        if ($FileCai -match '(?i)\.iso$') {
            Mount-DiskImage -ImagePath $FileCai -PassThru | Out-Null; Start-Sleep 1
            $KyTuIso = (Get-DiskImage -ImagePath $FileCai | Get-Volume).DriveLetter[0]
            $Wim = "$($KyTuIso):\sources\install.wim"; $Esd = "$($KyTuIso):\sources\install.esd"
            $FileTrich = if (Test-Path $Wim) { $Wim } else { $Esd }
            $FileCaiDich = Join-Path ([System.IO.Path]::GetDirectoryName($FileCai)) ("install_extracted" + [System.IO.Path]::GetExtension($FileTrich))
            if (-not (Test-Path $FileCaiDich)) {
                $In = [System.IO.File]::OpenRead($FileTrich); $Out = [System.IO.File]::Create($FileCaiDich)
                $Buf = New-Object byte[] (8MB); $Len = $In.Length; $Done = 0
                while (($Read = $In.Read($Buf, 0, $Buf.Length)) -gt 0) { $Out.Write($Buf, 0, $Read); $Done += $Read; $G.TienDo = [math]::Round(($Done / $Len) * 100) }
                $In.Close(); $Out.Close()
            }
            Dismount-DiskImage -ImagePath $FileCai | Out-Null; $FileCai = $FileCaiDich
        }

        # TẠO UNATTEND.XML VỚI MÚI GIỜ +7 VÀ ĐỊNH DẠNG VIỆT NAM (DD/MM/YYYY) KÈM NGÔN NGỮ TÙY CHỌN
        if ($OOBE) {
            $UnattendXML = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <TimeZone>SE Asia Standard Time</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>vi-VN</InputLocale>
            <SystemLocale>vi-VN</SystemLocale>
            <UILanguage>$SelectedLang</UILanguage>
            <UserLocale>vi-VN</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
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
        if ($TPM) { $Cmd += "reg add `"HKLM\SYSTEM\Setup\MoSetup`" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f`r`n" }
        if ($FileDriver) { $Cmd += "pnputil /add-driver `"$FileDriver\*.inf`" /subdirs /install`r`n" }
        if ($Logon) {
            $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v AutoAdminLogon /t REG_SZ /d 1 /f`r`n"
            $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v DefaultUserName /t REG_SZ /d `"$TenUser`" /f`r`n"
        }
        if ($AnyDesk) { $Cmd += "powershell -Command `"Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'; start 'C:\Users\Public\Desktop\AnyDesk.exe'`"`r`n" }
        $Cmd += "del %0`r`n"
        $Cmd | Out-File "$env:TEMP\SetupComplete_ZT.cmd" -Encoding oem

        # XỬ LÝ WINRE
        $ChuCaiO_Win = [System.IO.Path]::GetPathRoot($env:windir).Substring(0,1); $PhanVungOS = Get-Partition -DriveLetter $ChuCaiO_Win
        $OsDiskNum = $PhanVungOS.DiskNumber; $OsPartNum = $PhanVungOS.PartitionNumber; $DuongDanTuongDoi = $FileCai.Substring(3)
        reagentc.exe /enable | Out-Null; Start-Sleep 2; reagentc.exe /disable | Out-Null
        $WinREGoc = "C:\Windows\System32\Recovery\winre.wim"; $ThuMucMnt = "C:\MountRE"
        if (Test-Path $ThuMucMnt) { dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Discard | Out-Null; Remove-Item $ThuMucMnt -Recurse -Force }
        New-Item -ItemType Directory -Path $ThuMucMnt | Out-Null
        $WinRECopy = "C:\winre_xu-ly.wim"; Copy-Item $WinREGoc $WinRECopy -Force; Set-ItemProperty $WinRECopy IsReadOnly $false
        dism.exe /Mount-Image /ImageFile:$WinRECopy /Index:1 /MountDir:$ThuMucMnt | Out-Null
        Copy-Item "$env:TEMP\SetupComplete_ZT.cmd" "$ThuMucMnt\Windows\System32\SetupComplete_ZT.cmd" -Force
        if ($OOBE) { Copy-Item "$env:TEMP\unattend_ZT.xml" "$ThuMucMnt\Windows\System32\unattend_ZT.xml" -Force }

        # LỆNH TRONG WINRE
        @"
@echo off
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( if exist "%%D:\$DuongDanTuongDoi" set "WIM=%%D:\$DuongDanTuongDoi" )
(echo select disk $OsDiskNum & echo select partition $OsPartNum & echo assign letter=W & echo format quick fs=ntfs label="Windows") | diskpart
dism /apply-image /imagefile:"%WIM%" /index:$IndexLoi /applydir:W:\
for %%p in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( if exist %%p:\EFI\Microsoft\Boot\BCD ( attrib -h -s -r %%p:\EFI\Microsoft\Boot\BCD & del /f /q %%p:\EFI\Microsoft\Boot\BCD ) )
bcdboot W:\Windows
bcdedit /timeout 0
mkdir W:\Windows\Setup\Scripts
copy /Y X:\Windows\System32\SetupComplete_ZT.cmd W:\Windows\Setup\Scripts\SetupComplete.cmd
if exist X:\Windows\System32\unattend_ZT.xml ( mkdir W:\Windows\Panther & copy /Y X:\Windows\System32\unattend_ZT.xml W:\Windows\Panther\unattend.xml )
del /F /Q X:\Windows\System32\winpeshl.ini
wpeutil reboot
"@ | Out-File "$ThuMucMnt\Windows\System32\LenhRE.cmd" -Encoding oem
        "[LaunchApps]`r`nX:\Windows\System32\LenhRE.cmd" | Out-File "$ThuMucMnt\Windows\System32\winpeshl.ini" -Encoding ascii
        dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Commit | Out-Null
        Set-ItemProperty $WinREGoc IsReadOnly $false; Copy-Item $WinRECopy $WinREGoc -Force
        reagentc.exe /enable | Out-Null; reagentc.exe /boottore | Out-Null

    } catch { $G.Loi = $_.Exception.Message } finally { $G.KetThuc = $true }
}

$NutKichHoat.Add_Click({
    $FileCai = $HopFileBoCai.Text; $FileDriver = $HopThuMucDriver.Text; $ChonIndex = $DanhSachBanWin.SelectedItem
    if (-not (Test-Path $FileCai)) { return }
    
    if ($ChonIndex -match 'Index (\d+):') {
        $IndexLoi = $matches[1]
    } else {
        $IndexLoi = 1
    }
    
    $SelectedLang = ($CboLanguage.SelectedItem.Tag)

    $UI.Cursor = [System.Windows.Input.Cursors]::Wait; $NutKichHoat.IsEnabled = $false
    $Global:TrangThaiHethong.TienDo = 0; $Global:TrangThaiHethong.KetThuc = $false; $DongHoTimer.Start()

    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $TienTrinh = [powershell]::Create().AddScript($KichBanNen).AddArgument($Global:TrangThaiHethong).AddArgument($FileCai).AddArgument($FileDriver).AddArgument($IndexLoi).AddArgument($TxtTenUser.Text).AddArgument($ChkOOBE.IsChecked).AddArgument($ChkLogon.IsChecked).AddArgument($ChkTPM.IsChecked).AddArgument($ChkAnyDesk.IsChecked).AddArgument($ChkWifi.IsChecked).AddArgument($ChkBackupDriver.IsChecked).AddArgument($SelectedLang)
    $TienTrinh.Runspace = $MoiTruong; $TienTrinh.BeginInvoke() | Out-Null
})

$UI.ShowDialog() | Out-Null