<#
.SYNOPSIS
    CÔNG CỤ TỰ ĐỘNG SYSPREP & BACKUP WINDOWS (CAPTURE TO WIM) - V1.4
    Tích hợp: Dọn rác -> Tối ưu Win -> Phục hồi WinRE -> Sysprep/NoSysprep -> Boot to RE -> Auto Capture -> Reboot
#>

# ==========================================
# 1. YÊU CẦU QUYỀN ADMIN & STA
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
        Title="Auto Sysprep &amp; Capture Tool V1.4 (Optimize &amp; Rescue)" 
        Width="700" Height="820" MinWidth="600" MinHeight="600" 
        WindowStartupLocation="CenterScreen" Background="#F1F5F9">
    <DockPanel Margin="15">
        
        <TextBlock DockPanel.Dock="Top" Text="HỆ THỐNG TỰ ĐỘNG BACKUP &amp; TỐI ƯU WIM" FontSize="20" FontWeight="Bold" Foreground="#1E293B" HorizontalAlignment="Center" Margin="0,0,0,15"/>

        <StackPanel DockPanel.Dock="Bottom" Margin="0,15,0,0">
            <StackPanel Margin="0,0,0,10">
                <Grid Margin="0,0,0,5">
                    <TextBlock Name="TxtTrangThai" Text="Sẵn sàng" FontSize="12" Foreground="#334155" FontWeight="Bold"/>
                    <TextBlock Name="TxtPhanTram" Text="0%" FontWeight="Bold" FontSize="13" Foreground="#2563EB" HorizontalAlignment="Right"/>
                </Grid>
                <ProgressBar Name="ThanhTienDo" Height="14" Foreground="#3B82F6" Background="#E2E8F0" BorderThickness="0"/>
            </StackPanel>
            <Button Name="NutKichHoat" Content="⚙️ BẮT ĐẦU QUY TRÌNH (OPTIMIZE + CAPTURE)" Height="50" Background="#1E293B" Foreground="White" FontSize="15" FontWeight="Bold" BorderThickness="0" Cursor="Hand" Margin="0,10,0,0"/>
        </StackPanel>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="1*"/> 
            </Grid.RowDefinitions>

            <Border Grid.Row="0" Background="#FFF1F2" CornerRadius="8" Padding="15" Margin="0,0,0,10" BorderBrush="#FDA4AF" BorderThickness="1">
                <StackPanel>
                    <Grid Margin="0,0,0,10">
                        <TextBlock Text="1. Cấp cứu lõi WinRE (Dành cho Win Mod/Lite):" FontWeight="Bold" Foreground="#E11D48"/>
                        <TextBlock Name="TxtTrangThaiWinRE" Text="Đang kiểm tra..." HorizontalAlignment="Right" FontWeight="Bold" Foreground="#059669"/>
                    </Grid>
                    <TextBlock Text="Nếu WinRE hỏng, hãy chọn file winre.wim dự phòng để Tool phục hồi trước khi tiến hành Capture." FontSize="11" Foreground="#475569" Margin="0,0,0,8" TextWrapping="Wrap"/>
                    <Grid Margin="0,0,0,5">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                        <TextBlock Text="File winre.wim:" VerticalAlignment="Center" Foreground="#475569" FontWeight="Bold"/>
                        <TextBox Name="HopFileWinRE" Grid.Column="1" Height="30" VerticalContentAlignment="Center" IsReadOnly="True" Background="#F8FAFC" Margin="0,0,5,0"/>
                        <Button Name="NutChonWinRE" Grid.Column="2" Content="📂 Nạp File" Background="#E11D48" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                    </Grid>
                </StackPanel>
            </Border>

            <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,10" BorderBrush="#CBD5E1" BorderThickness="1">
                <StackPanel>
                    <TextBlock Text="2. Thiết lập nơi lưu bản WIM:" FontWeight="Bold" Foreground="#1E293B" Margin="0,0,0,10"/>
                    <Grid Margin="0,0,0,10">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                        <TextBlock Text="Nơi lưu File:" VerticalAlignment="Center" Foreground="#475569" FontWeight="Bold"/>
                        <TextBox Name="HopNoiLuu" Grid.Column="1" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Background="#F8FAFC" Margin="0,0,5,0"/>
                        <Button Name="NutChonNoiLuu" Grid.Column="2" Content="💾 Chọn ổ" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                    </Grid>
                    <TextBlock Text="* Bắt buộc lưu sang phân vùng khác (VD: Ổ D, E) hoặc ổ cứng gắn ngoài." FontSize="11" Foreground="#DC2626" FontStyle="Italic"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,10" BorderBrush="#CBD5E1" BorderThickness="1">
                <StackPanel>
                    <TextBlock Text="3. Cấu hình bản Backup &amp; Tối ưu:" FontWeight="Bold" Foreground="#1E293B" Margin="0,0,0,10"/>
                    <Grid Margin="0,0,0,8">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <TextBlock Text="Tên Image:" VerticalAlignment="Center" Foreground="#475569"/>
                        <TextBox Name="TxtTenWin" Grid.Column="1" Height="30" VerticalContentAlignment="Center" Text="Windows Mod by ZT Tool" Padding="5,0"/>
                    </Grid>
                    
                    <CheckBox Name="ChkDeepClean" Content="Dọn dẹp rác cơ bản (Temp, Prefetch, Log, SoftwareDistribution)" IsChecked="True" Margin="0,5,0,0" FontWeight="Bold" Foreground="#475569"/>
                    
                    <CheckBox Name="ChkOptimize" Content="Tối ưu hệ thống sâu (Gỡ Bloatware, Tắt BitLocker, Startup, Hibernate...)" IsChecked="True" Margin="0,5,0,0" FontWeight="Bold" Foreground="#0284C7"/>
                    
                    <CheckBox Name="ChkSysprep" Content="Thực hiện Sysprep (Generalize &amp; OOBE) trước khi Capture" IsChecked="True" Margin="0,5,0,0" FontWeight="Bold" Foreground="#D97706"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="3" Background="#0F172A" CornerRadius="8" Padding="10">
                <TextBox Name="HopNhatKy" Background="Transparent" Foreground="#FACC15" FontFamily="Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
            </Border>
        </Grid>
    </DockPanel>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML); $UI = [Windows.Markup.XamlReader]::Load($TrinhDoc)
$TxtTrangThaiWinRE = $UI.FindName("TxtTrangThaiWinRE"); $HopFileWinRE = $UI.FindName("HopFileWinRE"); $NutChonWinRE = $UI.FindName("NutChonWinRE")
$HopNoiLuu = $UI.FindName("HopNoiLuu"); $NutChonNoiLuu = $UI.FindName("NutChonNoiLuu")
$TxtTenWin = $UI.FindName("TxtTenWin"); $ChkDeepClean = $UI.FindName("ChkDeepClean")
$ChkOptimize = $UI.FindName("ChkOptimize"); $ChkSysprep = $UI.FindName("ChkSysprep")
$HopNhatKy = $UI.FindName("HopNhatKy"); $TxtTrangThai = $UI.FindName("TxtTrangThai")
$TxtPhanTram = $UI.FindName("TxtPhanTram"); $ThanhTienDo = $UI.FindName("ThanhTienDo"); $NutKichHoat = $UI.FindName("NutKichHoat")

# ==========================================
# 4. KIỂM TRA SỨC KHỎE WINRE
# ==========================================
function KiemTra-WinRE {
    $TxtTrangThaiWinRE.Text = "Đang kiểm tra..."
    $Check = reagentc /info
    if ($Check -match "Enabled") {
        $TxtTrangThaiWinRE.Text = "✅ ĐANG HOẠT ĐỘNG"
        $TxtTrangThaiWinRE.Foreground = "#059669"
    } else {
        reagentc /enable | Out-Null
        $CheckLai = reagentc /info
        if ($CheckLai -match "Enabled") {
            $TxtTrangThaiWinRE.Text = "✅ ĐÃ KÍCH HOẠT LẠI"
            $TxtTrangThaiWinRE.Foreground = "#059669"
        } else {
            $TxtTrangThaiWinRE.Text = "❌ ĐÃ HỎNG / BỊ XÓA"
            $TxtTrangThaiWinRE.Foreground = "#DC2626"
        }
    }
}
KiemTra-WinRE

$NutChonWinRE.Add_Click({ 
    $Hop = New-Object System.Windows.Forms.OpenFileDialog
    $Hop.Filter = "WinRE File (winre.wim)|winre.wim"
    $Hop.Title = "Chọn file winre.wim dự phòng"
    if ($Hop.ShowDialog() -eq 'OK') { $HopFileWinRE.Text = $Hop.FileName } 
})

$NutChonNoiLuu.Add_Click({ 
    $Hop = New-Object System.Windows.Forms.SaveFileDialog
    $Hop.Filter = "Windows Image File (*.wim)|*.wim"
    $Hop.FileName = "Windows_Backup_$(Get-Date -f 'yyyyMMdd').wim"
    if ($Hop.ShowDialog() -eq 'OK') { $HopNoiLuu.Text = $Hop.FileName } 
})

# ==========================================
# 5. TIMER CẬP NHẬT UI
# ==========================================
$DongHoTimer = New-Object System.Windows.Threading.DispatcherTimer
$DongHoTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$DongHoTimer.Add_Tick({
    if ($Global:TrangThaiHethong.Log) { $HopNhatKy.AppendText($Global:TrangThaiHethong.Log); $HopNhatKy.ScrollToEnd(); $Global:TrangThaiHethong.Log = "" }
    $ThanhTienDo.Value = $Global:TrangThaiHethong.TienDo; $TxtPhanTram.Text = "$($Global:TrangThaiHethong.TienDo)%"; $TxtTrangThai.Text = $Global:TrangThaiHethong.TrangThai
    if ($Global:TrangThaiHethong.KetThuc) {
        $DongHoTimer.Stop()
        if ($Global:TrangThaiHethong.Loi) { 
            [System.Windows.Forms.MessageBox]::Show($Global:TrangThaiHethong.Loi, "LỖI KỊCH BẢN", 0, 16) 
            $NutKichHoat.IsEnabled = $true; $UI.Cursor = [System.Windows.Input.Cursors]::Arrow
        } else {
            [System.Windows.Forms.MessageBox]::Show("HỆ THỐNG ĐÃ XỬ LÝ XONG!`n`nMáy sẽ TẮT (SHUTDOWN) ngay bây giờ. Sau khi máy tắt, hãy khởi động lại để quá trình Capture bắt đầu tự động trong WinRE.", "THÀNH CÔNG", 0, 64)
            Stop-Computer -Force
        }
    }
})

# ==========================================
# 6. KỊCH BẢN CHÍNH (CHẠY TRÊN WIN SỐNG)
# ==========================================
$KichBanNen = {
    param($G, $FileDich, $TenWin, $DeepClean, $FileWinREDuPhong, $TinhTrangWinRE, $RunSysprep, $RunOptimize)
    function InLog($txt) { $G.Log += "`n[$(Get-Date -f 'HH:mm:ss')] $txt" }
    
    try {
        # BƯỚC 0: PHỤC HỒI WINRE
        if ($TinhTrangWinRE -match "❌") {
            if (-not $FileWinREDuPhong) { throw "WinRE hỏng. Vui lòng chọn file winre.wim dự phòng!" }
            $G.TrangThai = "Khởi động: Phục hồi lõi WinRE..."; $G.TienDo = 5
            InLog "Đang cấy lại lõi winre.wim từ file dự phòng..."
            
            reagentc /disable | Out-Null
            $ThuMucHoiSinh = "C:\Windows\System32\Recovery"
            if (-not (Test-Path $ThuMucHoiSinh)) { New-Item -ItemType Directory -Path $ThuMucHoiSinh -Force | Out-Null }
            cmd.exe /c "attrib -h -s -r C:\Windows\System32\Recovery\winre.wim" | Out-Null
            Copy-Item $FileWinREDuPhong "$ThuMucHoiSinh\winre.wim" -Force
            reagentc /setreimage /path C:\Windows\System32\Recovery | Out-Null
            reagentc /enable | Out-Null
            
            if ((reagentc /info) -match "Enabled") { InLog "✅ Phục hồi WinRE thành công!" } else { throw "Lỗi kích hoạt WinRE." }
        }

        # BƯỚC 1: DỌN RÁC & TỐI ƯU HỆ THỐNG SÂU
        $G.TrangThai = "BƯỚC 1/3: Dọn dẹp & Tối ưu..."; $G.TienDo = 10
        
        if ($DeepClean) {
            InLog "Đang xóa Temp, Prefetch, Logs..."
            $Paths = @("$env:TEMP\*", "C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Windows\SoftwareDistribution\Download\*")
            foreach ($P in $Paths) { Get-Item $P -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
            InLog "Dọn dẹp Disk Cleanup (Sagerun) & Windows Update..."
            Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden
            dism.exe /online /cleanup-image /startcomponentcleanup /resetbase | Out-Null
        }

        if ($RunOptimize) {
            $G.TienDo = 20
            InLog "Đang tắt BitLocker (Nếu có)..."
            Manage-bde -off C: | Out-Null
            Disable-BitLocker -MountPoint "C:" -ErrorAction SilentlyContinue | Out-Null

            InLog "Gỡ bỏ Bloatware (Chỉ giữ Camera, Photo, Snipping, Sticky, Calc, Paint)..."
            $keepApps = "Camera|Photos|ScreenSketch|StickyNotes|Calculator|Paint|Store|DesktopAppInstaller"
            Get-AppxPackage -AllUsers | Where-Object { $_.Name -notmatch $keepApps -and $_.IsFramework -eq $false -and $_.NonRemovable -eq $false } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

            InLog "Tắt Widgets (Win 11) & News (Win 10)..."
            New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

            InLog "Tắt Sleep/Hibernation..."
            powercfg.exe /hibernate off | Out-Null

            InLog "Cấu hình Visual Effects (Giữ Thumbnails & Smooth Fonts)..."
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3 -Force
            # Tắt animation
            $AdvPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $AdvPath -Name "ListviewAlphaSelect" -Value 0 -Force
            Set-ItemProperty -Path $AdvPath -Name "TaskbarAnimations" -Value 0 -Force
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force
            # Chừa 2 mục quan trọng
            Set-ItemProperty -Path $AdvPath -Name "IconsOnly" -Value 0 -Force
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value "2" -Force

            InLog "Tắt System Protection..."
            Disable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            vssadmin delete shadows /all /quiet 2>$null | Out-Null

            InLog "Dọn dẹp các ứng dụng Startup..."
            $RunPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")
            foreach ($path in $RunPaths) {
                if (Test-Path $path) {
                    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | ForEach-Object {
                        Remove-ItemProperty -Path $path -Name $_.Name -ErrorAction SilentlyContinue
                    }
                }
            }

            InLog "Chạy Compact OS (Giảm dung lượng System)..."
            compact.exe /compactos:always | Out-Null
            InLog "✅ Đã tối ưu hóa hệ thống sâu!"
        }

        # BƯỚC 2: CẤU HÌNH WINRE ĐỂ TỰ ĐỘNG CAPTURE
        $G.TrangThai = "BƯỚC 2/3: Chuẩn bị WinRE Auto Capture..."; $G.TienDo = 50
        InLog "Đang mount WinRE để cấy lệnh Backup..."
        reagentc /disable | Out-Null; Start-Sleep 2
        $WinRE = "C:\Windows\System32\Recovery\winre.wim"
        $MountDir = "C:\MountBackup"
        if (Test-Path $MountDir) { Remove-Item $MountDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $MountDir | Out-Null
        
        dism.exe /Mount-Image /ImageFile:$WinRE /Index:1 /MountDir:$MountDir | Out-Null

        $TargetDisk = $FileDich.Substring(0,2)
        $TargetFile = $FileDich.Substring(3)
        $ConfigPath = "$MountDir\Windows\System32\CaptureConfig.txt"
        "$TargetDisk|$TargetFile|$TenWin" | Out-File $ConfigPath -Encoding ascii

        $ReCmd = @"
@echo off
set /p CFG=<X:\Windows\System32\CaptureConfig.txt
for /f "tokens=1,2,3 delims=|" %%a in ("%CFG%") do (
    set "DISK=%%a"
    set "FILE=%%b"
    set "NAME=%%c"
)
cls
echo ======================================================
echo    HE THONG DANG TU DONG BACKUP WINDOWS (WIM)
echo ======================================================
echo Dang nen o C vao: %DISK%\%FILE%
echo Vui long cho doi...
dism /Capture-Image /ImageFile:"%DISK%\%FILE%" /CaptureDir:C:\ /Name:"%NAME%" /Compress:max
echo.
echo ✅ DA SAO LUU THANH CONG! May se khoi dong lai...
del /f /q X:\Windows\System32\winpeshl.ini
wpeutil reboot
"@
        $ReCmd | Out-File "$MountDir\Windows\System32\AutoCapture.cmd" -Encoding oem
        "[LaunchApps]`r`nX:\Windows\System32\AutoCapture.cmd" | Out-File "$MountDir\Windows\System32\winpeshl.ini" -Encoding ascii

        InLog "Đang đóng gói WinRE..."
        dism.exe /Unmount-Image /MountDir:$MountDir /Commit | Out-Null
        reagentc /setreimage /path C:\Windows\System32\Recovery | Out-Null
        reagentc /enable | Out-Null
        reagentc /boottore | Out-Null
        InLog "✅ Đã nạp cờ Boot To WinRE (Vào WinRE trong lần khởi động tới)."

        # BƯỚC 3: XỬ LÝ CHUNG CUỘC (SYSPREP OR SHUTDOWN)
        if ($RunSysprep) {
            $G.TrangThai = "BƯỚC 3/3: Thực thi Sysprep..."; $G.TienDo = 90
            InLog "Đang chạy Sysprep (Generalize). Máy sẽ tự tắt ngay sau đó..."
            Start-Process "C:\Windows\System32\Sysprep\sysprep.exe" -ArgumentList "/generalize /oobe /shutdown /quiet" -Wait
        } else {
            $G.TrangThai = "BƯỚC 3/3: Bỏ qua Sysprep, chuẩn bị tắt máy..."; $G.TienDo = 90
            InLog "Đã bỏ qua Sysprep theo yêu cầu."
        }
        
        $G.TienDo = 100
    } catch { $G.Loi = $_.Exception.Message } finally { $G.KetThuc = $true }
}

# Kích hoạt nút bấm
$NutKichHoat.Add_Click({
    if (-not $HopNoiLuu.Text) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn nơi lưu file Backup!", "LỖI", 0, 16); return }
    $LuuOC = $HopNoiLuu.Text.Substring(0,3)
    if ($LuuOC -eq "C:\") { [System.Windows.Forms.MessageBox]::Show("LỖI: Không được lưu file Backup vào ngay ổ C.", "LỖI", 0, 16); return }

    if ([System.Windows.Forms.MessageBox]::Show("Tiến trình sẽ DỌN DẸP, TỐI ƯU HỆ THỐNG và cấu hình Backup.`nMáy sẽ TỰ TẮT khi hoàn tất.`n`nTiếp tục?", "XÁC NHẬN", 4, 32) -ne 'Yes') { return }
    
    $UI.Cursor = [System.Windows.Input.Cursors]::Wait; $NutKichHoat.IsEnabled = $false
    $Global:TrangThaiHethong.TienDo = 0; $Global:TrangThaiHethong.Log = ""; $Global:TrangThaiHethong.KetThuc = $false; $DongHoTimer.Start()

    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $TienTrinh = [powershell]::Create().AddScript($KichBanNen).AddArgument($Global:TrangThaiHethong).AddArgument($HopNoiLuu.Text).AddArgument($TxtTenWin.Text).AddArgument($ChkDeepClean.IsChecked).AddArgument($HopFileWinRE.Text).AddArgument($TxtTrangThaiWinRE.Text).AddArgument($ChkSysprep.IsChecked).AddArgument($ChkOptimize.IsChecked)
    $TienTrinh.Runspace = $MoiTruong; $TienTrinh.BeginInvoke() | Out-Null
})

$UI.ShowDialog() | Out-Null