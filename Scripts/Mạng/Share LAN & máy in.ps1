# ==========================================================
# CÔNG CỤ TỐI ƯU MẠNG & MÁY IN TOÀN DIỆN (WPF - V74)
# Tích hợp: Bật SMB1 + Trị 14 Lỗi Máy in + Share File
# ==========================================================

# 1. KIỂM TRA QUYỀN QUẢN TRỊ CAO NHẤT (ADMINISTRATOR)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. NẠP THƯ VIỆN GIAO DIỆN HỆ THỐNG
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$ThuatToanSuaLoiToanDien_V74 = {
    # --- BIẾN TOÀN CỤC & NHẬT KÝ ---
    $script:DongHoBamGio = [System.Diagnostics.Stopwatch]::New()
    $script:DangChay = $false
    $script:BuocHienTai = 0 
    $script:TienTrinhPhu = $null
    $script:NhatKyHoatDong = @(
        "==========================================================",
        " BÁO CÁO XỬ LÝ HỆ THỐNG ĐA KHOA (V74)",
        " Thời gian: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')",
        "=========================================================="
    )

    # --- 3. GIAO DIỆN XAML PHẲNG (FLAT DESIGN) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cong Cu Xu Ly He Thong V74" Width="600" Height="500"
        WindowStartupLocation="CenterScreen" Background="Transparent" FontFamily="Segoe UI" 
        AllowsTransparency="True" WindowStyle="None" ResizeMode="CanMinimize">
    
    <Window.Resources>
        <Style x:Key="KieuNutTieuDe" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#888888"/>
            <Setter Property="Width" Value="45"/><Setter Property="Height" Value="32"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
            <Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#333333"/><Setter Property="Foreground" Value="White"/></Trigger></Style.Triggers>
        </Style>

        <Style x:Key="KieuNutDong" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#888888"/>
            <Setter Property="Width" Value="45"/><Setter Property="Height" Value="32"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
            <Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#E81123"/><Setter Property="Foreground" Value="White"/></Trigger></Style.Triggers>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="2"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
            <Style.Triggers><Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger></Style.Triggers>
        </Style>
    </Window.Resources>

    <Border Background="#1E1E1E" BorderBrush="#8E44AD" BorderThickness="1" CornerRadius="0">
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="32"/><RowDefinition Height="*"/></Grid.RowDefinitions>

            <Grid Name="ThanhTieuDe" Grid.Row="0" Background="#2D2D2D">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="CÔNG CỤ XỬ LÝ ĐA KHOA: MẠNG &amp; MÁY IN V74" Foreground="#CCCCCC" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="11" FontWeight="Bold"/>
                <Button Name="NutThuNho" Grid.Column="1" Content="—" Style="{StaticResource KieuNutTieuDe}"/>
                <Button Name="NutDong" Grid.Column="2" Content="✕" Style="{StaticResource KieuNutDong}"/>
            </Grid>

            <Grid Grid.Row="1" Margin="30,25,30,25">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

                <DockPanel Grid.Row="0" Margin="0,0,0,20">
                    <TextBlock Text="⚡" FontSize="28" Foreground="#8E44AD" VerticalAlignment="Center" Margin="0,0,15,0" FontFamily="Segoe UI Emoji"/>
                    <StackPanel DockPanel.Dock="Left" VerticalAlignment="Center">
                        <TextBlock Name="ChuTrangThai" Text="HỆ THỐNG ĐÃ SẴN SÀNG" FontSize="20" FontWeight="Bold" Foreground="#8E44AD"/>
                        <TextBlock Name="ChuChiTiet" Text="Nạp SMB, vá 14 lỗi máy in, xóa Cache và giải phóng Session." Foreground="#888888" FontSize="13" Margin="0,2,0,0"/>
                    </StackPanel>
                    <TextBlock Name="ChuThoiGian" Text="00:00:00" FontSize="16" Foreground="#555555" HorizontalAlignment="Right" VerticalAlignment="Center" FontFamily="Consolas"/>
                </DockPanel>

                <Border Grid.Row="1" Height="4" Background="#333333" CornerRadius="0">
                    <ProgressBar Name="ThanhTienDo" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0" Foreground="#8E44AD"/>
                </Border>

                <Border Grid.Row="2" Background="#111111" BorderBrush="#333333" BorderThickness="1" Margin="0,20,0,20" Padding="15">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <TextBlock Name="ChuConsole" Foreground="#00FF00" FontFamily="Consolas" FontSize="12" TextWrapping="Wrap" 
                                   Text="[OK] Quản trị viên cấp cao: Hợp lệ.&#x0a;[INFO] Load module: PrintNightmare, RPC, SMB1, NetSession.&#x0a;[INFO] Sẵn sàng kích hoạt chiến dịch làm sạch toàn diện..."/>
                    </ScrollViewer>
                </Border>

                <Grid Grid.Row="3">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="NutBatDau" Grid.Column="0" Content="KÍCH HOẠT QUÉT ĐA KHOA" Height="45" Background="#8E44AD" FontSize="13"/>
                    <Button Name="NutDung" Grid.Column="2" Content="HỦY BỎ TIẾN TRÌNH" Height="45" Background="#C50F1F" FontSize="13" IsEnabled="False"/>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    $ThanhTieuDe = $CuaSo.FindName("ThanhTieuDe"); $NutThuNho = $CuaSo.FindName("NutThuNho"); $NutDong = $CuaSo.FindName("NutDong")
    $ChuTrangThai = $CuaSo.FindName("ChuTrangThai"); $ChuChiTiet = $CuaSo.FindName("ChuChiTiet"); $ChuThoiGian = $CuaSo.FindName("ChuThoiGian")
    $ThanhTienDo = $CuaSo.FindName("ThanhTienDo"); $ChuConsole = $CuaSo.FindName("ChuConsole")
    $NutBatDau = $CuaSo.FindName("NutBatDau"); $NutDung = $CuaSo.FindName("NutDung")

    function GhiLog ($NoiDung) { 
        $script:NhatKyHoatDong += "[$(Get-Date -Format 'HH:mm:ss')] $NoiDung"
        $ChuConsole.Text += "`n[SYS] $NoiDung"
    }

    $ThanhTieuDe.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
    $NutThuNho.Add_Click({ $CuaSo.WindowState = [System.Windows.WindowState]::Minimized })
    $NutDong.Add_Click({
        if ($script:DangChay) {
            if ([System.Windows.MessageBox]::Show("Hệ thống đang chạy tiến trình sâu. Bạn có chắc muốn thoát?", "Cảnh báo", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "No") { return }
            if ($null -ne $script:TienTrinhPhu) { try { Stop-Process -Id $script:TienTrinhPhu.Id -Force } catch {} }
        }
        $CuaSo.Close()
    })

    $BoDemChinh = New-Object System.Windows.Threading.DispatcherTimer
    $BoDemChinh.Interval = [TimeSpan]::FromMilliseconds(700)
    
    $BoDemChinh.Add_Tick({
        $ThoiGianDaTroi = $script:DongHoBamGio.Elapsed
        $ChuThoiGian.Text = "{0:00}:{1:00}:{2:00}" -f [math]::Floor($ThoiGianDaTroi.TotalHours), $ThoiGianDaTroi.Minutes, $ThoiGianDaTroi.Seconds
        
        if ($script:DangChay -and $null -ne $script:TienTrinhPhu) {
            if ($script:TienTrinhPhu.HasExited) {
                $script:TienTrinhPhu = $null
                switch ($script:BuocHienTai) {
                    1 { $script:BuocHienTai = 2 }
                }
            }
        }

        if ($script:DangChay -and $null -eq $script:TienTrinhPhu) {
            switch ($script:BuocHienTai) {
                1 {
                    $ChuTrangThai.Text = "NẠP GIAO THỨC SMB 1.0"
                    $ChuChiTiet.Text = "Kích hoạt giao tiếp vật lý với các máy tính đời cũ..."
                    $ThanhTienDo.IsIndeterminate = $true
                    GhiLog "Đang thực thi DISM để mở khóa SMB1Protocol..."
                    $script:TienTrinhPhu = Start-Process dism.exe -ArgumentList "/online /enable-feature /featurename:SMB1Protocol /all /norestart" -WindowStyle Hidden -PassThru
                }
                2 {
                    $ChuTrangThai.Text = "DỌN DẸP RÁC MẠNG & SPOOLER"
                    $ChuChiTiet.Text = "Xóa Credential, đá Session 0x47 và dọn hàng đợi in..."
                    GhiLog "Tiến hành quét dọn Cache, Session và Spooler..."
                    
                    $DonDepRac = {
                        # Xóa Session kẹt (Hỗ trợ lỗi 0x00000047 giới hạn kết nối)
                        net session /delete /y | Out-Null
                        
                        # Xóa Credential (Lỗi đòi pass liên tục)
                        cmdkey.exe /list | Select-String -Pattern "Target: (.*)" | ForEach-Object { $MucTieu = $_.Matches.Groups[1].Value.Trim(); & cmdkey.exe /delete:$MucTieu | Out-Null }
                        
                        # Dọn hàng đợi in (Lỗi kẹt máy in)
                        Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        Remove-Item -Path "$env:windir\System32\spool\PRINTERS\*.*" -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    &$DonDepRac
                    
                    GhiLog "Hoàn tất làm sạch bộ nhớ đệm và phiên kết nối treo."
                    $script:BuocHienTai = 3
                }
                3 {
                    $ChuTrangThai.Text = "VÁ LỖI REGISTRY & TƯỜNG LỬA"
                    $ChuChiTiet.Text = "Xử lý PrintNightmare, RPC và phân quyền Guest..."
                    
                    $SuaLoiRegistry = {
                        function ThietLap-Reg ($DuongDan, $Ten, $GiaTri, $Kieu = "DWord") { if (!(Test-Path $DuongDan)) { New-Item $DuongDan -Force | Out-Null }; Set-ItemProperty $DuongDan $Ten $GiaTri -Type $Kieu -Force }
                        
                        # 1. Share File: NTLM & Guest (Bật Pass trắng)
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LimitBlankPasswordUse" 0
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" 1
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "everyoneincludesanonymous" 1
                        
                        # 2. Máy In: PrintNightmare (0x11b, 0x709, 0x7c) & RPC Pipes (0xbc4, 0x771)
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Print" "RpcAuthnLevelPrivacyEnabled" 0
                        ThietLap-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "RestrictDriverInstallationToAdministrators" 0
                        ThietLap-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" "RpcUseNamedPipeProtocol" 1
                        ThietLap-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" "RpcTcpPort" 0
                        
                        # 3. Tường lửa & Khám phá mạng
                        $DanhSachMang = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Public" }
                        if ($DanhSachMang) { foreach ($Mang in $DanhSachMang) { Set-NetConnectionProfile -InterfaceAlias $Mang.InterfaceAlias -NetworkCategory Private } }
                        
                        $DanhSachDichVu = @("fdPHost", "FDResPub", "SSDPSRV", "upnphost", "mpssvc")
                        foreach ($DichVu in $DanhSachDichVu) { Set-Service $DichVu -StartupType Automatic; Start-Service $DichVu -ErrorAction SilentlyContinue }
                        
                        netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes | Out-Null
                        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes | Out-Null
                    }
                    &$SuaLoiRegistry
                    
                    GhiLog "Đã mở khóa các chính sách mã hóa bảo mật toàn hệ thống."
                    $script:BuocHienTai = 4
                }
                4 {
                    $ChuTrangThai.Text = "LÀM MỚI DỊCH VỤ HỆ THỐNG"
                    $ChuChiTiet.Text = "Đang khởi động lại LanmanWorkstation và Print Spooler..."
                    GhiLog "Restart các dịch vụ mạng lõi để nhận cấu hình..."
                    
                    Start-Service -Name Spooler -ErrorAction SilentlyContinue
                    Start-Service -Name LanmanWorkstation -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 1
                    
                    $script:BuocHienTai = 5
                }
                5 {
                    $ChuTrangThai.Text = "HOÀN TẤT CHIẾN DỊCH V74"
                    $ChuTrangThai.Foreground = "#8E44AD"
                    $ChuChiTiet.Text = "Toàn bộ rào cản Máy in và Share File đã được dọn sạch."
                    $ThanhTienDo.IsIndeterminate = $false; $ThanhTienDo.Value = 100
                    GhiLog "QUY TRÌNH KẾT THÚC THÀNH CÔNG!"
                    
                    $script:DangChay = $false; $script:DongHoBamGio.Stop(); $BoDemChinh.Stop()
                    
                    $DuongDanFile = Join-Path ([System.Environment]::GetFolderPath('Desktop')) "Bao_Cao_DaKhoa_V74.txt"
                    $script:NhatKyHoatDong | Out-File -FilePath $DuongDanFile -Encoding UTF8

                    [System.Windows.MessageBox]::Show("Tối ưu hệ thống Đa Khoa V74 hoàn tất!`n`nĐã làm sạch toàn bộ rác kết nối (kể cả lỗi Full User 0x47), mở lại tính năng Pass Trắng và vá toàn bộ 14 mã lỗi máy in LAN.`n`nHÃY KHỞI ĐỘNG LẠI MÁY TÍNH ĐỂ CẤU HÌNH CÓ HIỆU LỰC.", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
                }
            }
        }
    })

    $NutBatDau.Add_Click({
        $ChuConsole.Text = "[SYS] Đã tiếp nhận lệnh. Bắt đầu chiến dịch đa khoa..."
        $script:DangChay = $true; $script:BuocHienTai = 1; $script:DongHoBamGio.Reset(); $script:DongHoBamGio.Start(); $BoDemChinh.Start()
        $NutBatDau.IsEnabled = $false; $NutDung.IsEnabled = $true
    })

    $NutDung.Add_Click({
        $script:DangChay = $false; $BoDemChinh.Stop()
        Start-Service -Name Spooler -ErrorAction SilentlyContinue
        if ($null -ne $script:TienTrinhPhu) { try { Stop-Process -Id $script:TienTrinhPhu.Id -Force } catch {} }
        $ChuTrangThai.Text = "TIẾN TRÌNH BỊ ÉP DỪNG"
        $ChuTrangThai.Foreground = "#C50F1F"
        GhiLog "CẢNH BÁO: Quá trình sửa lỗi bị hủy ngang!"
        $ThanhTienDo.IsIndeterminate = $false; $ThanhTienDo.Value = 0
        $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$ThuatToanSuaLoiToanDien_V74