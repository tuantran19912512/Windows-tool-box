<#
.SYNOPSIS
    CÔNG CỤ TRIỂN KHAI WINDOWS TỰ ĐỘNG - V4.2 (AUTO ANYDESK & REMOTE SUPPORT)
    Tác giả: Tuấn & AI Assistant
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

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ==========================================
# 2. HÀM GIAO DIỆN PHỤ
# ==========================================
function CapNhat-GiaoDien {
    $KhungChayDoi = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [System.Action]{ $KhungChayDoi.Continue = $false }) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($KhungChayDoi)
}

function Chon-ThuMucHienDai($TieuDe) {
    $HopThoai = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoai.Title = $TieuDe
    $HopThoai.ValidateNames = $false
    $HopThoai.CheckFileExists = $false
    $HopThoai.CheckPathExists = $true
    $HopThoai.FileName = "[Vào_thư_mục_và_bấm_Open]" 
    if ($HopThoai.ShowDialog() -eq 'OK') { return [System.IO.Path]::GetDirectoryName($HopThoai.FileName) }
    return $null
}

# ==========================================
# 3. XÂY DỰNG GIAO DIỆN WPF (XAML)
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Zero-Touch Deployment V4.2 (AnyDesk Remote Support)" 
        Width="750" Height="820" WindowStartupLocation="CenterScreen" Background="#F0F4F8">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="HỆ THỐNG CÀI ĐẶT WINDOWS TỰ ĐỘNG" FontSize="22" FontWeight="Bold" Foreground="#1E293B" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,12">
            <StackPanel>
                <TextBlock Text="1. Bộ cài Windows và Driver:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid Margin="0,0,0,5">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                    <TextBox Name="HopThoaiFileBoCai" Height="30" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0"/>
                    <Button Name="NutChonFileBoCai" Grid.Column="1" Content="Duyệt WIM" Background="#475569" Foreground="White" BorderThickness="0"/>
                </Grid>
                <ComboBox Name="DanhSachPhienBanWin" Height="30" Margin="0,5,0,5" VerticalContentAlignment="Center"/>
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                    <TextBox Name="HopThoaiThuMucDriver" Height="30" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0"/>
                    <Button Name="NutChonThuMucDriver" Grid.Column="1" Content="Duyệt Driver" Background="#475569" Foreground="White" BorderThickness="0"/>
                </Grid>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,12">
            <StackPanel>
                <TextBlock Text="2. Thiết lập User và Bypass OOBE:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid Margin="0,0,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <TextBlock Text="Tên User tạo mới:" VerticalAlignment="Center" Foreground="#1E293B"/>
                    <TextBox Name="TxtTenUser" Grid.Column="1" Height="30" VerticalContentAlignment="Center" Text="Admin" FontWeight="Bold" Padding="5,0"/>
                </Grid>
                <CheckBox Name="ChkBypassOOBE" Content="Bỏ qua Internet, OOBE và các câu hỏi riêng tư (Privacy)" IsChecked="True" FontWeight="Bold" Margin="0,0,0,5"/>
                <CheckBox Name="ChkAutoLogon" Content="Tự động đăng nhập vào Desktop sau khi cài xong" IsChecked="True" FontWeight="Bold"/>
            </StackPanel>
        </Border>

        <Border Grid.Row="3" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,12">
            <StackPanel>
                <TextBlock Text="3. Tùy chọn nâng cao:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <UniformGrid Columns="2">
                    <CheckBox Name="ChkTatBitLocker" Content="Tắt BitLocker ổ C" IsChecked="True" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkSaoLuuWifi" Content="Sao lưu Wi-Fi hiện tại" IsChecked="True" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkBypassTPM" Content="Bypass TPM 2.0 &amp; CPU (Dành cho máy cũ)" IsChecked="True" Foreground="#E11D48" FontWeight="Bold" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkAutoAnyDesk" Content="Tự tải AnyDesk và bật khi vào Desktop" IsChecked="True" Foreground="#0284C7" FontWeight="Bold"/>
                </UniformGrid>
            </StackPanel>
        </Border>

        <Border Grid.Row="4" Background="#0F172A" CornerRadius="4" Margin="0,0,0,12" Padding="5">
            <TextBox Name="HopThoaiNhatKy" Background="Transparent" Foreground="#38BDF8" FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
        </Border>

        <Button Name="NutBatDauCaiDat" Grid.Row="5" Content="KÍCH HOẠT QUY TRÌNH ZERO-TOUCH" Height="50" Background="#E11D48" Foreground="White" FontSize="16" FontWeight="Bold" BorderThickness="0"/>
    </Grid>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML)
$GiaoDien = [Windows.Markup.XamlReader]::Load($TrinhDoc)

$HopThoaiFileBoCai = $GiaoDien.FindName("HopThoaiFileBoCai")
$NutChonFileBoCai = $GiaoDien.FindName("NutChonFileBoCai")
$DanhSachPhienBanWin = $GiaoDien.FindName("DanhSachPhienBanWin")
$HopThoaiThuMucDriver = $GiaoDien.FindName("HopThoaiThuMucDriver")
$NutChonThuMucDriver = $GiaoDien.FindName("NutChonThuMucDriver")
$TxtTenUser = $GiaoDien.FindName("TxtTenUser")
$ChkBypassOOBE = $GiaoDien.FindName("ChkBypassOOBE")
$ChkAutoLogon = $GiaoDien.FindName("ChkAutoLogon")
$ChkTatBitLocker = $GiaoDien.FindName("ChkTatBitLocker")
$ChkSaoLuuWifi = $GiaoDien.FindName("ChkSaoLuuWifi")
$ChkBypassTPM = $GiaoDien.FindName("ChkBypassTPM")
$ChkAutoAnyDesk = $GiaoDien.FindName("ChkAutoAnyDesk") # Nút mới
$HopThoaiNhatKy = $GiaoDien.FindName("HopThoaiNhatKy")
$NutBatDauCaiDat = $GiaoDien.FindName("NutBatDauCaiDat")

# ==========================================
# 4. HÀM XỬ LÝ LÕI
# ==========================================

function Ghi-NhatKy($NoiDung) {
    $ThoiGian = Get-Date -Format "HH:mm:ss"
    $HopThoaiNhatKy.AppendText("[$ThoiGian] $NoiDung`n")
    $HopThoaiNhatKy.ScrollToEnd()
    CapNhat-GiaoDien
}

function Quet-VaCapNhatPhienBanWin {
    $DuongDanFile = $HopThoaiFileBoCai.Text
    if (-not (Test-Path $DuongDanFile)) { return }
    Ghi-NhatKy "Đang quét danh sách phiên bản..."
    $DanhSachPhienBanWin.Items.Clear()
    try {
        $ThongTinWim = dism.exe /Get-WimInfo /WimFile:$DuongDanFile /English
        $ChiSoHienTai = $null
        foreach ($Dong in $ThongTinWim) {
            if ($Dong -match 'Index : (\d+)') { $ChiSoHienTai = $matches[1] }
            if ($Dong -match 'Name : (.*)' -and $ChiSoHienTai) {
                $DanhSachPhienBanWin.Items.Add("Index $($ChiSoHienTai): $($matches[1])") | Out-Null
                $ChiSoHienTai = $null
            }
        }
        $DanhSachPhienBanWin.SelectedIndex = 0
    } catch { Ghi-NhatKy "❌ Lỗi đọc file!" }
}

$NutChonFileBoCai.Add_Click({
    $HopThoaiFile = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoaiFile.Filter = "Windows Image (*.wim;*.esd;*.iso)|*.wim;*.esd;*.iso"
    if ($HopThoaiFile.ShowDialog() -eq 'OK') { 
        $HopThoaiFileBoCai.Text = $HopThoaiFile.FileName 
        Quet-VaCapNhatPhienBanWin
    }
})

$NutChonThuMucDriver.Add_Click({
    $KetQua = Chon-ThuMucHienDai "Chọn thư mục Driver"
    if ($KetQua) { $HopThoaiThuMucDriver.Text = $KetQua }
})

# ==========================================
# 5. KHỐI LÕI PHÂN VÙNG VÀ KÍCH NỔ
# ==========================================

function ChuanBi-PhanVungHeThong {
    Ghi-NhatKy "Đang kiểm tra cấu trúc EFI & Recovery..."
    try {
        $ChuCaiO_Win = [System.IO.Path]::GetPathRoot($env:windir).Substring(0,1)
        $PhanVungOS = Get-Partition -DriveLetter $ChuCaiO_Win -ErrorAction Stop
        $global:OsDiskNum = $PhanVungOS.DiskNumber
        $global:OsPartNum = $PhanVungOS.PartitionNumber 

        $CacPhanVung = Get-Partition -DiskNumber $global:OsDiskNum
        $CoEFI = $CacPhanVung | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -or $_.Type -eq 'System' }
        $CoRec = $CacPhanVung | Where-Object { $_.GptType -eq '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -or $_.Type -eq 'Recovery' }

        if (-not $CoEFI -or -not $CoRec) {
            Ghi-NhatKy "⚠️ Tạo phân vùng EFI & Recovery bị thiếu..."
            $KichThuocMoi = $PhanVungOS.Size - 1GB
            Resize-Partition -DriveLetter $ChuCaiO_Win -Size $KichThuocMoi -ErrorAction Stop
            
            $ScriptDiskpart = @"
select disk $global:OsDiskNum
create partition efi size=260
format quick fs=fat32 label="System"
assign letter=S
create partition primary size=740
format quick fs=ntfs label="Recovery"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
assign letter=R
"@
            $ScriptDiskpart | Out-File "$env:TEMP\diskpart_auto.txt" -Encoding ascii
            Start-Process "diskpart.exe" "/s $env:TEMP\diskpart_auto.txt" -Wait -WindowStyle Hidden
            Ghi-NhatKy "✅ Xong cấu trúc phân vùng."
        }
    } catch { throw "Lỗi chia phân vùng: $_" }
}

function Do-WinRE_Va_KichNo {
    param($WimPath, $Index, $DriverPath, $TenUser, $BypassOOBE, $AutoLogon, $TatBitLocker, $SaoLuuWifi, $BypassTPM, $AutoAnyDesk)
    
    Ghi-NhatKy "Đang thiết lập định tuyến WinRE..."
    $PhanVungOS = Get-Partition -DriveLetter "C"
    $OsDiskNum = $PhanVungOS.DiskNumber
    $OsPartNum = $PhanVungOS.PartitionNumber
    $DuongDanTuongDoi = $WimPath.Substring(3)

    # 1. TẠO KỊCH BẢN SETUPCOMPLETE (ĐÃ THÊM LỆNH ANYDESK)
    $Cmd = "@echo off`r`n"
    $Cmd += "echo --- KICH BAN ZERO-TOUCH DANG CHAY ---`r`n"
    $Cmd += "net user `"$TenUser`" /add /passwordreq:no`r`n"
    $Cmd += "net localgroup administrators `"$TenUser`" /add`r`n"
    
    if ($BypassOOBE) { $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE`" /v BypassNRO /t REG_DWORD /d 1 /f`r`n" }
    
    if ($BypassTPM) {
        $Cmd += "reg add `"HKLM\SYSTEM\Setup\MoSetup`" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f`r`n"
        $Cmd += "reg add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassTPMCheck /t REG_DWORD /d 1 /f`r`n"
        $Cmd += "reg add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f`r`n"
    }

    if ($DriverPath) {
        if ($SaoLuuWifi) { $Cmd += "for %%f in (`"$DriverPath\*.xml`") do netsh wlan add profile filename=`"%%f`" user=all`r`n" }
        $Cmd += "pnputil /add-driver `"$DriverPath\*.inf`" /subdirs /install`r`n"
    }

    if ($TatBitLocker) { $Cmd += "manage-bde -off C:`r`n" }

    if ($AutoLogon) {
        $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v AutoAdminLogon /t REG_SZ /d 1 /f`r`n"
        $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" /v DefaultUserName /t REG_SZ /d `"$TenUser`" /f`r`n"
    }

    # --- KHỐI LỆNH TỰ TẢI ANYDESK ---
    if ($AutoAnyDesk) {
        $Cmd += "echo Dang tai AnyDesk de ho tro tu xa...`r`n"
        $Cmd += "powershell -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'`"`r`n"
        $Cmd += "start `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`r`n"
    }

    $Cmd += "del %0`r`n"
    $Cmd | Out-File "$env:TEMP\SetupComplete_ZeroTouch.cmd" -Encoding oem

    # 2. XỬ LÝ WINRE
    reagentc.exe /enable | Out-Null; Start-Sleep 2; reagentc.exe /disable | Out-Null
    $WinRE_Goc = "C:\Windows\System32\Recovery\winre.wim"
    $ThuMucMount = "C:\MountRE"; $ThuMucXuLy = "C:\WinRE_XuLy"
    
    dism.exe /Cleanup-Wim | Out-Null
    if (Test-Path $ThuMucMount) { dism.exe /Unmount-Image /MountDir:$ThuMucMount /Discard | Out-Null; Remove-Item $ThuMucMount -Recurse -Force }
    New-Item -ItemType Directory -Path $ThuMucMount | Out-Null
    if (-not (Test-Path $ThuMucXuLy)) { New-Item -ItemType Directory -Path $ThuMucXuLy | Out-Null }
    
    $WinRE_Copy = "$ThuMucXuLy\winre.wim"
    Copy-Item -Path $WinRE_Goc -Destination $WinRE_Copy -Force
    Set-ItemProperty -Path $WinRE_Copy -Name IsReadOnly -Value $false

    Ghi-NhatKy "Đang Mount WinRE (30s)..."
    CapNhat-GiaoDien
    dism.exe /Mount-Image /ImageFile:$WinRE_Copy /Index:1 /MountDir:$ThuMucMount | Out-Null

    Copy-Item -Path "$env:TEMP\SetupComplete_ZeroTouch.cmd" -Destination "$ThuMucMount\Windows\System32\SetupComplete_ZeroTouch.cmd" -Force

    @"
@echo off
set "WIM_THUC_TE="
set "DRIVER_THUC_TE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\$DuongDanTuongDoi" set "WIM_THUC_TE=%%D:\$DuongDanTuongDoi"
    if exist "%%D:\$DriverPath" set "DRIVER_THUC_TE=%%D:\$DriverPath"
)

if "%WIM_THUC_TE%"=="" goto :Loi

(echo select disk $OsDiskNum & echo select partition $OsPartNum & echo assign letter=W & echo format quick fs=ntfs label="Windows") | diskpart

dism /apply-image /imagefile:"%WIM_THUC_TE%" /index:$Index /applydir:W:\
if %errorlevel% neq 0 goto :Loi

if not "%DRIVER_THUC_TE%"=="" dism /image:W:\ /add-driver /driver:"%DRIVER_THUC_TE%" /recurse

bcdboot W:\Windows
bcdedit /timeout 0
bcdedit /set {default} bootstatuspolicy IgnoreAllFailures
bcdedit /set {default} recoveryenabled No

mkdir W:\Windows\Setup\Scripts
copy /Y X:\Windows\System32\SetupComplete_ZeroTouch.cmd W:\Windows\Setup\Scripts\SetupComplete.cmd

if exist X:\Windows\System32\winpeshl.ini del X:\Windows\System32\winpeshl.ini /F /Q
echo Thanh cong! Dang reset...
ping 127.0.0.1 -n 4 >nul
wpeutil reboot
exit

:Loi
pause
cmd.exe
"@ | Out-File "$ThuMucMount\Windows\System32\LenhChayTrongRE.cmd" -Encoding oem

    "[LaunchApps]`r`nX:\Windows\System32\LenhChayTrongRE.cmd" | Out-File "$ThuMucMount\Windows\System32\winpeshl.ini" -Encoding ascii

    Ghi-NhatKy "Đang Unmount WinRE..."
    CapNhat-GiaoDien
    dism.exe /Unmount-Image /MountDir:$ThuMucMount /Commit | Out-Null
    Remove-Item -Path $ThuMucMount -Force

    Set-ItemProperty -Path $WinRE_Goc -Name IsReadOnly -Value $false
    Copy-Item -Path $WinRE_Copy -Destination $WinRE_Goc -Force
    Remove-Item -Path $ThuMucXuLy -Recurse -Force

    reagentc.exe /enable | Out-Null
    Ghi-NhatKy "Ép khởi động vào WinRE!"
    reagentc.exe /boottore | Out-Null
}

# ==========================================
# 6. KÍCH NỔ HỆ THỐNG
# ==========================================
$NutBatDauCaiDat.Add_Click({
    try {
        $FileCai = $HopThoaiFileBoCai.Text; $FileDriver = $HopThoaiThuMucDriver.Text; $ChonIndex = $DanhSachPhienBanWin.SelectedItem
        $TenUser = $TxtTenUser.Text; $BypassOOBE = $ChkBypassOOBE.IsChecked; $AutoLogon = $ChkAutoLogon.IsChecked
        $TatBitLocker = $ChkTatBitLocker.IsChecked; $SaoLuuWifi = $ChkSaoLuuWifi.IsChecked; $BypassTPM = $ChkBypassTPM.IsChecked
        $AutoAnyDesk = $ChkAutoAnyDesk.IsChecked

        if (-not (Test-Path $FileCai)) { throw "Chưa chọn file bộ cài!" }
        if ($ChonIndex -notmatch 'Index (\d+):') { throw "Chưa chọn Index!" }
        $IndexLoi = $matches[1]

        if ([System.IO.Path]::GetPathRoot($FileCai) -match "(?i)^C:") { throw "File cài không được để ở ổ C!" }

        $XacNhan = [System.Windows.Forms.MessageBox]::Show("XÁC NHẬN FORMAT Ổ C VÀ CÀI LẠI WIN?", "CẢNH BÁO", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Stop)
        if ($XacNhan -ne 'Yes') { return }

        $NutBatDauCaiDat.IsEnabled = $false
        $GiaoDien.Cursor = [System.Windows.Input.Cursors]::Wait

        if ($SaoLuuWifi -and $FileDriver) {
            Invoke-Expression "netsh wlan export profile key=clear folder=`"$FileDriver`"" | Out-Null
        }

        if ($FileCai -match '(?i)\.iso$') {
            Mount-DiskImage -ImagePath $FileCai -PassThru | Out-Null; Start-Sleep 1
            $KyTuIso = (Get-DiskImage -ImagePath $FileCai | Get-Volume).DriveLetter[0]
            $Wim = "$($KyTuIso):\sources\install.wim"; $Esd = "$($KyTuIso):\sources\install.esd"
            $FileTrich = if (Test-Path $Wim) { $Wim } elseif (Test-Path $Esd) { $Esd } else { $null }
            $FileCai = Join-Path ([System.IO.Path]::GetDirectoryName($FileCai)) ("install_extracted" + [System.IO.Path]::GetExtension($FileTrich))
            Copy-Item -Path $FileTrich -Destination $FileCai -Force
            Dismount-DiskImage -ImagePath $HopThoaiFileBoCai.Text | Out-Null
        }

        ChuanBi-PhanVungHeThong
        Do-WinRE_Va_KichNo -WimPath $FileCai -Index $IndexLoi -DriverPath $FileDriver -TenUser $TenUser -BypassOOBE $BypassOOBE -AutoLogon $AutoLogon -TatBitLocker $TatBitLocker -SaoLuuWifi $SaoLuuWifi -BypassTPM $BypassTPM -AutoAnyDesk $AutoAnyDesk
        
        Ghi-NhatKy "🚀 XONG! MÁY RESET TRONG 5 GIÂY..."
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "LỖI", 0, 16)
    } finally {
        $NutBatDauCaiDat.IsEnabled = $true
        $GiaoDien.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

$GiaoDien.ShowDialog() | Out-Null