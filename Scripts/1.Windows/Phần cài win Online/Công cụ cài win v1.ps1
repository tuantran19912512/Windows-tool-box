<#
.SYNOPSIS
    CÔNG CỤ TRIỂN KHAI WINDOWS TỰ ĐỘNG - V10.2 (SMART OVERRIDE & BOOT BYPASS)
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
# 3. GIAO DIỆN WPF (XAML)
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Zero-Touch Deployment V10.2 (Boot Bypass)" 
        Width="760" Height="650" MinWidth="700" MinHeight="500" 
        WindowStartupLocation="CenterScreen" Background="#F8FAFC">
    <DockPanel Margin="12">
        
        <TextBlock DockPanel.Dock="Top" Text="HỆ THỐNG TRIỂN KHAI WINDOWS TỰ ĐỘNG" FontSize="20" FontWeight="Bold" Foreground="#0F172A" HorizontalAlignment="Center" Margin="0,0,0,10"/>

        <StackPanel DockPanel.Dock="Bottom" Margin="0,10,0,0">
            <StackPanel Margin="0,0,0,10">
                <Grid Margin="0,0,0,5">
                    <TextBlock Name="TxtTrangThai" Text="Sẵn sàng" FontSize="12" Foreground="#1E293B" FontWeight="Bold"/>
                    <TextBlock Name="TxtPhanTram" Text="0%" FontWeight="Bold" FontSize="13" Foreground="#E11D48" HorizontalAlignment="Right"/>
                </Grid>
                <ProgressBar Name="ThanhTienDo" Height="14" Foreground="#10B981" Background="#E2E8F0" BorderThickness="0"/>
            </StackPanel>
            <Button Name="NutKichHoat" Content="🚀 KÍCH HOẠT QUY TRÌNH ZERO-TOUCH" Height="45" Background="#E11D48" Foreground="White" FontSize="16" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
        </StackPanel>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="2*"/> <RowDefinition Height="Auto"/> <RowDefinition Height="1*" MinHeight="80"/> </Grid.RowDefinitions>

            <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Padding="0,0,8,0" Margin="0,0,0,5">
                <StackPanel>
                    <Border Background="White" CornerRadius="8" Padding="10" Margin="0,0,0,8" BorderBrush="#E2E8F0" BorderThickness="1">
                        <StackPanel>
                            <TextBlock Text="1. Nguồn dữ liệu (ISO/WIM &amp; Driver):" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,8"/>
                            <Grid Margin="0,0,0,6">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                                <TextBox Name="HopFileBoCai" Height="28" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,8,0"/>
                                <Button Name="NutChonFile" Grid.Column="1" Content="📂 Chọn Bộ Cài" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                            </Grid>
                            <ComboBox Name="DanhSachBanWin" Height="28" Margin="0,0,0,6" VerticalContentAlignment="Center"/>
                            <Grid>
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                                <TextBox Name="HopThuMucDriver" Height="28" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,8,0"/>
                                <Button Name="NutChonDriver" Grid.Column="1" Content="🖨️ Chọn Driver" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                            </Grid>
                        </StackPanel>
                    </Border>

                    <Border Background="White" CornerRadius="8" Padding="10" Margin="0,0,0,8" BorderBrush="#E2E8F0" BorderThickness="1">
                        <StackPanel>
                            <CheckBox Name="ChkGhiDeUnattend" Content="2. Can thiệp Hệ thống (Tạo User, Region US-VN) - Bỏ tick nếu dùng WIM Mod sẵn" IsChecked="True" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,8"/>
                            
                            <StackPanel Name="KhuVucRegion" Margin="20,0,0,0">
                                <TextBlock Text="* Khóa cứng Tiếng Anh (US) nhằm loại bỏ bộ gõ VIE gây phiền phức." FontSize="11" Foreground="#D97706" FontWeight="Bold" Margin="0,0,0,3"/>
                                <TextBlock Text="* Tự động set Múi giờ +7 (Hà Nội) &amp; Định dạng ngày tháng VN (DD/MM/YYYY)." FontSize="11" Foreground="#0284C7" Margin="0,0,0,10"/>
                                <Grid Margin="0,0,0,2">
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <TextBlock Text="Tên Tài Khoản:" VerticalAlignment="Center" Foreground="#475569" FontWeight="Bold" FontSize="12"/>
                                    <TextBox Name="TxtTenUser" Grid.Column="1" Height="28" VerticalContentAlignment="Center" Text="Admin" FontWeight="Bold" Padding="10,0"/>
                                </Grid>
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <Border Background="White" CornerRadius="8" Padding="10" Margin="0,0,0,2" BorderBrush="#E2E8F0" BorderThickness="1">
                        <StackPanel>
                            <TextBlock Text="3. Module Kích hoạt ngầm (An toàn dữ liệu):" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,8"/>
                            <UniformGrid Columns="2" VerticalAlignment="Top">
                                <CheckBox Name="ChkOOBE" Content="Tiêu diệt Màn hình xanh OOBE" IsChecked="True" FontWeight="Bold" Margin="0,0,0,6" FontSize="12"/>
                                <CheckBox Name="ChkLogon" Content="Auto Logon vào Desktop" IsChecked="True" FontWeight="Bold" Margin="0,0,0,6" FontSize="12"/>
                                <CheckBox Name="ChkBackupDriver" Content="Rút Driver máy hiện tại" IsChecked="True" Margin="0,0,0,6" FontSize="12"/>
                                <CheckBox Name="ChkTPM" Content="Bypass TPM 2.0 &amp; CPU" IsChecked="True" Foreground="#E11D48" FontWeight="Bold" Margin="0,0,0,6" FontSize="12"/>
                                <CheckBox Name="ChkAnyDesk" Content="Tải &amp; Bật sẵn AnyDesk" IsChecked="True" Foreground="#0284C7" FontWeight="Bold" FontSize="12"/>
                                <CheckBox Name="ChkWifi" Content="Sao lưu Pass Wi-Fi" IsChecked="True" FontSize="12"/>
                            </UniformGrid>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </ScrollViewer>

            <GridSplitter Grid.Row="1" Height="5" HorizontalAlignment="Stretch" VerticalAlignment="Center" Background="#CBD5E1" Cursor="SizeNS" Margin="0,2,0,5"/>

            <Border Grid.Row="2" Background="#0F172A" CornerRadius="8" Padding="8">
                <TextBox Name="HopNhatKy" Background="Transparent" Foreground="#38BDF8" FontFamily="Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
            </Border>
        </Grid>
    </DockPanel>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML); $UI = [Windows.Markup.XamlReader]::Load($TrinhDoc)
$HopFileBoCai = $UI.FindName("HopFileBoCai"); $NutChonFile = $UI.FindName("NutChonFile"); $DanhSachBanWin = $UI.FindName("DanhSachBanWin")
$HopThuMucDriver = $UI.FindName("HopThuMucDriver"); $NutChonDriver = $UI.FindName("NutChonDriver"); $TxtTenUser = $UI.FindName("TxtTenUser")
$ChkGhiDeUnattend = $UI.FindName("ChkGhiDeUnattend"); $KhuVucRegion = $UI.FindName("KhuVucRegion")
$ChkOOBE = $UI.FindName("ChkOOBE"); $ChkLogon = $UI.FindName("ChkLogon")
$ChkTPM = $UI.FindName("ChkTPM"); $ChkAnyDesk = $UI.FindName("ChkAnyDesk"); $ChkWifi = $UI.FindName("ChkWifi")
$ChkBackupDriver = $UI.FindName("ChkBackupDriver"); $HopNhatKy = $UI.FindName("HopNhatKy"); $TxtTrangThai = $UI.FindName("TxtTrangThai")
$TxtPhanTram = $UI.FindName("TxtPhanTram"); $ThanhTienDo = $UI.FindName("ThanhTienDo"); $NutKichHoat = $UI.FindName("NutKichHoat")

# Xử lý Logic Giao diện Tắt/Bật
$ChkGhiDeUnattend.Add_Click({
    $TrangThai = $ChkGhiDeUnattend.IsChecked
    $KhuVucRegion.IsEnabled = $TrangThai
    $ChkOOBE.IsEnabled = $TrangThai
    $ChkLogon.IsEnabled = $TrangThai
})

# ==========================================
# 4. TIMER ĐỒNG BỘ
# ==========================================
$DongHoTimer = New-Object System.Windows.Threading.DispatcherTimer
$DongHoTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$DongHoTimer.Add_Tick({
    if ($Global:TrangThaiHethong.Log) { $HopNhatKy.AppendText($Global:TrangThaiHethong.Log); $HopNhatKy.ScrollToEnd(); $Global:TrangThaiHethong.Log = "" }
    $ThanhTienDo.Value = $Global:TrangThaiHethong.TienDo; $TxtPhanTram.Text = "$($Global:TrangThaiHethong.TienDo)%"; $TxtTrangThai.Text = $Global:TrangThaiHethong.TrangThai
    if ($Global:TrangThaiHethong.KetThuc) {
        $DongHoTimer.Stop()
        if ($Global:TrangThaiHethong.Loi) { 
            [System.Windows.Forms.MessageBox]::Show($Global:TrangThaiHethong.Loi, "LỖI HỆ THỐNG", 0, 16) 
        } else { 
            $HopNhatKy.AppendText("`n`n[$(Get-Date -f 'HH:mm:ss')] ✅ TOÀN BỘ QUY TRÌNH ĐÃ HOÀN TẤT! Máy sẽ khởi động lại sau 5 giây...") 
            Start-Process "cmd.exe" -ArgumentList "/c shutdown /r /t 5 /c `"He thong Zero-Touch da hoan tat. May se khoi dong lai vao WinRE...`"" -WindowStyle Hidden
        }
        $NutKichHoat.IsEnabled = $true; $UI.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

# ==========================================
# 5. CÁC HÀM XỬ LÝ (QUÉT FILE)
# ==========================================
function Quet-ISO_WIM {
    $File = $HopFileBoCai.Text; if (-not (Test-Path $File)) { return }
    $DanhSachBanWin.Items.Clear(); $DanhSachBanWin.Items.Add("⏳ Đang quét danh sách phiên bản..."); $DanhSachBanWin.SelectedIndex = 0
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
# 6. KỊCH BẢN NỀN
# ==========================================
$KichBanNen = {
    param($G, $FileCai, $FileDriver, $IndexLoi, $GhiDeUnattend, $TenUser, $OOBE, $Logon, $TPM, $AnyDesk, $Wifi, $BackupDriver)
    
    function InLog($txt) { $G.Log += "`n[$(Get-Date -f 'HH:mm:ss')] $txt" }
    
    try {
        InLog "🚀 BẮT ĐẦU CHUỖI QUY TRÌNH ZERO-TOUCH..."
        
        # BƯỚC 1: BACKUP DRIVER & WI-FI 
        $MarkerName = "THUMUC_KHONG_TON_TAI.txt"
        $ThuMucDriverTuongDoi = ""

        if ($FileDriver) {
            $MarkerName = "ZT_Driver_$([guid]::NewGuid().ToString('N')).txt"
            Out-File -FilePath "$FileDriver\$MarkerName" -InputObject "Day la thu muc Driver ZT" -Encoding ascii
            $ThuMucDriverTuongDoi = if ($FileDriver.Length -gt 3) { $FileDriver.Substring(3) } else { "" }

            if ($BackupDriver) { 
                $G.TrangThai = "BƯỚC 1/6: Đang trích xuất Driver..."; $G.TienDo = 5
                InLog "Đang quét và trích xuất toàn bộ Driver máy hiện tại..."
                Export-WindowsDriver -Online -Destination $FileDriver | Out-Null 
                InLog "✅ Đã lưu Driver vào: $FileDriver"
            }
            if ($Wifi) { 
                InLog "Đang sao lưu thông tin Wi-Fi..."
                Invoke-Expression "netsh wlan export profile key=clear folder=`"$FileDriver`"" | Out-Null 
                InLog "✅ Đã lưu mật khẩu Wi-Fi."
            }
        }

        # BƯỚC 2: XỬ LÝ ISO
        if ($FileCai -match '(?i)\.iso$') {
            $G.TrangThai = "BƯỚC 2/6: Đang xả nén bộ cài từ ISO (Có thể mất 2-5 phút)..."
            InLog "Bắt đầu Mount ISO và xả nén file install.wim..."
            Mount-DiskImage -ImagePath $FileCai -PassThru | Out-Null; Start-Sleep 1
            $KyTuIso = (Get-DiskImage -ImagePath $FileCai | Get-Volume).DriveLetter[0]
            $Wim = "$($KyTuIso):\sources\install.wim"; $Esd = "$($KyTuIso):\sources\install.esd"
            $FileTrich = if (Test-Path $Wim) { $Wim } else { $Esd }
            $FileCaiDich = Join-Path ([System.IO.Path]::GetDirectoryName($FileCai)) ("install_extracted" + [System.IO.Path]::GetExtension($FileTrich))
            
            if (-not (Test-Path $FileCaiDich)) {
                $In = [System.IO.File]::OpenRead($FileTrich); $Out = [System.IO.File]::Create($FileCaiDich)
                $Buf = New-Object byte[] (8MB); $Len = $In.Length; $Done = 0
                while (($Read = $In.Read($Buf, 0, $Buf.Length)) -gt 0) { 
                    $Out.Write($Buf, 0, $Read); $Done += $Read
                    $G.TienDo = 5 + [math]::Round(($Done / $Len) * 30) 
                }
                $In.Close(); $Out.Close()
                InLog "✅ Xả nén WIM/ESD thành công!"
            } else { InLog "⚡ Đã tìm thấy file giải nén sẵn, bỏ qua bước copy." }
            Dismount-DiskImage -ImagePath $FileCai | Out-Null; $FileCai = $FileCaiDich
        }

        $G.TienDo = 40; $G.TrangThai = "BƯỚC 3/6: Kiến tạo File cấu hình tự động (Unattend.xml)..."
        $DuongDanTuongDoiWin = if ($FileCai.Length -gt 3) { $FileCai.Substring(3) } else { "" }

        # BƯỚC 3: TẠO UNATTEND.XML (CHỈ KHI TICK CHỌN)
        if ($GhiDeUnattend) {
            InLog "Đang tổng hợp cấu hình: Bàn phím US, Region VN, AutoLogon, User ($TenUser)..."
            if ($OOBE) {
                $KhốiUser = ""
                $KhốiLogonReg = ""
                
                if ($Logon) {
                    $KhốiLogonReg = @"
            <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
                <RunSynchronous>
                    <RunSynchronousCommand wcm:action="add">
                        <Order>1</Order>
                        <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f</Path>
                    </RunSynchronousCommand>
                    <RunSynchronousCommand wcm:action="add">
                        <Order>2</Order>
                        <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "$TenUser" /f</Path>
                    </RunSynchronousCommand>
                </RunSynchronous>
            </component>
"@
                    $KhốiUser = @"
                <UserAccounts>
                    <LocalAccounts>
                        <LocalAccount wcm:action="add">
                            <Password>
                                <Value></Value>
                                <PlainText>true</PlainText>
                            </Password>
                            <Description>Local Administrator</Description>
                            <DisplayName>$TenUser</DisplayName>
                            <Group>Administrators</Group>
                            <Name>$TenUser</Name>
                        </LocalAccount>
                    </LocalAccounts>
                </UserAccounts>
                <AutoLogon>
                    <Password>
                        <Value></Value>
                        <PlainText>true</PlainText>
                    </Password>
                    <Enabled>true</Enabled>
                    <LogonCount>9999</LogonCount>
                    <Username>$TenUser</Username>
                </AutoLogon>
"@
                }

                $UnattendXML = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <TimeZone>SE Asia Standard Time</TimeZone>
        </component>
$KhốiLogonReg
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
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
            $KhốiUser
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <CommandLine>cmd.exe /c C:\Windows\Setup\Scripts\PostInstall_ZT.cmd</CommandLine>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
"@
                $UnattendXML | Out-File "$env:TEMP\unattend_ZT.xml" -Encoding utf8
                InLog "✅ Đã tạo file Unattend.xml."
            }
        } else {
            InLog "⚡ Đã bỏ qua bước tạo Unattend.xml để bảo toàn cấu hình gốc của file WIM."
        }

        # BƯỚC 4: TẠO SCRIPT POST-INSTALL
        $G.TrangThai = "BƯỚC 4/6: Tạo kịch bản Hậu Cài đặt..."; $G.TienDo = 50
        $Cmd = "@echo off`r`n"
        if ($TPM) { $Cmd += "reg add `"HKLM\SYSTEM\Setup\MoSetup`" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f`r`n" }
        $Cmd += "manage-bde -off C:`r`n"
        
        if ($Wifi) { 
            $Cmd += "echo Dang doi Card mang khoi dong...`r`nping 127.0.0.1 -n 10 >nul`r`n"
            $Cmd += "for %%f in (`"%~dp0*.xml`") do netsh wlan add profile filename=`"%%f`" user=all`r`n" 
        }
        if ($AnyDesk) { 
            $Cmd += "echo Dang doi Internet ket noi de tai AnyDesk...`r`nping 127.0.0.1 -n 15 >nul`r`n"
            $Cmd += "powershell -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'`"`r`n"
            $Cmd += "start `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`r`n" 
        }
        $Cmd += "del %0`r`n"
        $Cmd | Out-File "$env:TEMP\PostInstall_ZT.cmd" -Encoding oem
        InLog "✅ Đã đóng gói các lệnh Hậu cài đặt."

        # BƯỚC 5: XỬ LÝ WINRE
        $G.TrangThai = "BƯỚC 5/6: Chuẩn bị lõi khởi động WinRE..."; $G.TienDo = 60
        $ChuCaiO_Win = [System.IO.Path]::GetPathRoot($env:windir).Substring(0,1)
        $PhanVungOS = Get-Partition -DriveLetter $ChuCaiO_Win
        $OsDiskNum = $PhanVungOS.DiskNumber; $OsPartNum = $PhanVungOS.PartitionNumber
        
        $WinREGoc = "C:\Windows\System32\Recovery\winre.wim"; $ThuMucMnt = "C:\MountRE"
        
        InLog "Đang ép hệ thống nhả file WinRE..."
        reagentc.exe /enable | Out-Null; Start-Sleep 2
        reagentc.exe /disable | Out-Null; Start-Sleep 2
        
        if (-not (Test-Path $WinREGoc)) { throw "KHÔNG TÌM THẤY LÕI WINRE! Máy này đã bị xóa mất phân vùng Recovery gốc." }

        if (Test-Path $ThuMucMnt) { dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Discard | Out-Null; Remove-Item $ThuMucMnt -Recurse -Force }
        New-Item -ItemType Directory -Path $ThuMucMnt | Out-Null
        $WinRECopy = "C:\winre_xu-ly.wim"; Copy-Item $WinREGoc $WinRECopy -Force; Set-ItemProperty $WinRECopy IsReadOnly $false
        
        dism.exe /Mount-Image /ImageFile:$WinRECopy /Index:1 /MountDir:$ThuMucMnt | Out-Null
        Copy-Item "$env:TEMP\PostInstall_ZT.cmd" "$ThuMucMnt\Windows\System32\PostInstall_ZT.cmd" -Force
        
        if ($GhiDeUnattend -and (Test-Path "$env:TEMP\unattend_ZT.xml")) { 
            Copy-Item "$env:TEMP\unattend_ZT.xml" "$ThuMucMnt\Windows\System32\unattend_ZT.xml" -Force 
        }
        
        # BƯỚC 6: LỆNH CHẠY BÊN TRONG WINRE (CÓ BCD BOOT BYPASS)
        $G.TrangThai = "BƯỚC 6/6: Ghi kịch bản tự động hóa..."; $G.TienDo = 80
        
        $CheckDriverPath = if ($ThuMucDriverTuongDoi) { "%%D:\$ThuMucDriverTuongDoi\$MarkerName" } else { "%%D:\$MarkerName" }
        $DriverInjectPath = if ($ThuMucDriverTuongDoi) { "%DRIVER_DRIVE%:\$ThuMucDriverTuongDoi\." } else { "%DRIVER_DRIVE%:\." }
        $XmlCopyPath = if ($ThuMucDriverTuongDoi) { "%DRIVER_DRIVE%:\$ThuMucDriverTuongDoi\*.xml" } else { "%DRIVER_DRIVE%:\*.xml" }

        @"
@echo off
set "WIM="
set "DRIVER_DRIVE="

REM Quet o dia tim ma xac nhan 
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( 
    if exist "%%D:\$DuongDanTuongDoiWin" set "WIM=%%D:\$DuongDanTuongDoiWin"
    if not "$MarkerName"=="THUMUC_KHONG_TON_TAI.txt" (
        if exist "$CheckDriverPath" (
            set "DRIVER_DRIVE=%%D"
        )
    )
)

(echo select disk $OsDiskNum & echo select partition $OsPartNum & echo assign letter=W & echo format quick fs=ntfs label="Windows") | diskpart
dism /apply-image /imagefile:"%WIM%" /index:$IndexLoi /applydir:W:\

mkdir W:\Windows\Setup\Scripts
if not "%DRIVER_DRIVE%"=="" (
    dism /image:W:\ /add-driver /driver:"$DriverInjectPath" /recurse
    copy /Y "$XmlCopyPath" W:\Windows\Setup\Scripts\
)

for %%p in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( if exist %%p:\EFI\Microsoft\Boot\BCD ( attrib -h -s -r %%p:\EFI\Microsoft\Boot\BCD & del /f /q %%p:\EFI\Microsoft\Boot\BCD ) )
bcdboot W:\Windows

REM [BÙA CHÚ] - Tat man hinh Recovery "Press Enter to try again" cho cac ban WIM Mod
bcdedit /timeout 0
bcdedit /set {default} recoveryenabled No
bcdedit /set {default} bootstatuspolicy IgnoreAllFailures

copy /Y X:\Windows\System32\PostInstall_ZT.cmd W:\Windows\Setup\Scripts\PostInstall_ZT.cmd

REM Co che Hook thong minh (Smart Override)
if exist X:\Windows\System32\unattend_ZT.xml ( 
    mkdir W:\Windows\Panther 
    copy /Y X:\Windows\System32\unattend_ZT.xml W:\Windows\Panther\unattend.xml 
) else (
    echo call C:\Windows\Setup\Scripts\PostInstall_ZT.cmd >> W:\Windows\Setup\Scripts\SetupComplete.cmd
)

del /F /Q X:\Windows\System32\winpeshl.ini
wpeutil reboot
"@ | Out-File "$ThuMucMnt\Windows\System32\LenhRE.cmd" -Encoding oem
        "[LaunchApps]`r`nX:\Windows\System32\LenhRE.cmd" | Out-File "$ThuMucMnt\Windows\System32\winpeshl.ini" -Encoding ascii
        
        $G.TrangThai = "Đang đóng gói và đăng ký WinRE..."; $G.TienDo = 90
        InLog "Đang lưu cấu hình WinRE..."
        dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Commit | Out-Null
        Start-Sleep 2
        
        cmd.exe /c "attrib -h -s -r `"$WinREGoc`"" | Out-Null
        Copy-Item $WinRECopy $WinREGoc -Force
        Remove-Item $WinRECopy -Force -ErrorAction SilentlyContinue
        
        InLog "Đang ép hệ thống nhận diện WinRE mới..."
        reagentc.exe /setreimage /path C:\Windows\System32\Recovery | Out-Null
        reagentc.exe /enable | Out-Null
        reagentc.exe /boottore | Out-Null
        
        $G.TienDo = 100
        InLog "✅ Đã nạp cờ Boot To RE thành công!"

    } catch { 
        $G.Loi = $_.Exception.Message 
    } finally { 
        Remove-Item "$env:TEMP\unattend_ZT.xml", "$env:TEMP\PostInstall_ZT.cmd" -Force -ErrorAction SilentlyContinue
        $G.KetThuc = $true 
    }
}

$NutKichHoat.Add_Click({
    $FileCai = $HopFileBoCai.Text; $FileDriver = $HopThuMucDriver.Text; $ChonIndex = $DanhSachBanWin.SelectedItem
    if (-not (Test-Path $FileCai)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn bộ cài!", "LỖI", 0, 16); return }
    
    if ($ChonIndex -match 'Index (\d+):') { $IndexLoi = $matches[1] } else { $IndexLoi = 1 }

    if ( ($ChkBackupDriver.IsChecked -or $ChkWifi.IsChecked) -and -not $FileDriver ) {
        [System.Windows.Forms.MessageBox]::Show("Để Backup Driver/Wi-Fi, vui lòng 'Chọn Driver' (Chọn 1 thư mục trống ở ổ D/E).", "THIẾU THÔNG TIN", 0, 16); return
    }

    if ([System.Windows.Forms.MessageBox]::Show("HỆ THỐNG SẼ FORMAT Ổ C.`nĐảm bảo bạn đã sao lưu dữ liệu quan trọng.`nTiếp tục?", "CẢNH BÁO TỐI THƯỢNG", 4, 48) -ne 'Yes') { return }

    $UI.Cursor = [System.Windows.Input.Cursors]::Wait; $NutKichHoat.IsEnabled = $false
    $Global:TrangThaiHethong.TienDo = 0; $Global:TrangThaiHethong.Log = ""; $Global:TrangThaiHethong.KetThuc = $false; $DongHoTimer.Start()

    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $TienTrinh = [powershell]::Create().AddScript($KichBanNen).AddArgument($Global:TrangThaiHethong).AddArgument($FileCai).AddArgument($FileDriver).AddArgument($IndexLoi).AddArgument($ChkGhiDeUnattend.IsChecked).AddArgument($TxtTenUser.Text).AddArgument($ChkOOBE.IsChecked).AddArgument($ChkLogon.IsChecked).AddArgument($ChkTPM.IsChecked).AddArgument($ChkAnyDesk.IsChecked).AddArgument($ChkWifi.IsChecked).AddArgument($ChkBackupDriver.IsChecked)
    $TienTrinh.Runspace = $MoiTruong; $TienTrinh.BeginInvoke() | Out-Null
})

$UI.ShowDialog() | Out-Null