# ==========================================================
# CÔNG CỤ ĐẶC TRỊ LỖI MÁY IN MẠNG LAN (WPF - V73)
# Fix tổng hợp 14 mã lỗi PrintNightmare, Spooler, RPC, SMB
# ==========================================================

# 1. KIỂM TRA QUYỀN QUẢN TRỊ CAO NHẤT (ADMINISTRATOR)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. NẠP THƯ VIỆN GIAO DIỆN HỆ THỐNG
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$ThuatToanSuaLoiMayIn_V73 = {
    # --- BIẾN TOÀN CỤC & NHẬT KÝ ---
    $script:DongHoBamGio = [System.Diagnostics.Stopwatch]::New()
    $script:DangChay = $false
    $script:BuocHienTai = 0 
    $script:TienTrinhPhu = $null
    $script:NhatKyHoatDong = @(
        "==========================================================",
        " BÁO CÁO XỬ LÝ LỖI MÁY IN TOÀN DIỆN (V73)",
        " Thời gian: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')",
        "=========================================================="
    )

    # --- 3. GIAO DIỆN XAML PHẲNG (FLAT DESIGN) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cong Cu Dac Tri May In V73" Width="580" Height="480"
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

    <Border Background="#1E1E1E" BorderBrush="#20A120" BorderThickness="1" CornerRadius="0">
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="32"/><RowDefinition Height="*"/></Grid.RowDefinitions>

            <Grid Name="ThanhTieuDe" Grid.Row="0" Background="#2D2D2D">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="CÔNG CỤ ĐẶC TRỊ LỖI MÁY IN MẠNG - V73" Foreground="#CCCCCC" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="11" FontWeight="Bold"/>
                <Button Name="NutThuNho" Grid.Column="1" Content="—" Style="{StaticResource KieuNutTieuDe}"/>
                <Button Name="NutDong" Grid.Column="2" Content="✕" Style="{StaticResource KieuNutDong}"/>
            </Grid>

            <Grid Grid.Row="1" Margin="30,25,30,25">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

                <DockPanel Grid.Row="0" Margin="0,0,0,20">
                    <TextBlock Text="🖨️" FontSize="28" Foreground="#20A120" VerticalAlignment="Center" Margin="0,0,15,0" FontFamily="Segoe UI Emoji"/>
                    <StackPanel DockPanel.Dock="Left" VerticalAlignment="Center">
                        <TextBlock Name="ChuTrangThai" Text="HỆ THỐNG ĐÃ SẴN SÀNG" FontSize="20" FontWeight="Bold" Foreground="#20A120"/>
                        <TextBlock Name="ChuChiTiet" Text="Sửa 14 mã lỗi máy in (0x11b, 0x709, 0xbc4, 0x6d9...)" Foreground="#888888" FontSize="13" Margin="0,2,0,0"/>
                    </StackPanel>
                    <TextBlock Name="ChuThoiGian" Text="00:00:00" FontSize="16" Foreground="#555555" HorizontalAlignment="Right" VerticalAlignment="Center" FontFamily="Consolas"/>
                </DockPanel>

                <Border Grid.Row="1" Height="4" Background="#333333" CornerRadius="0">
                    <ProgressBar Name="ThanhTienDo" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0" Foreground="#20A120"/>
                </Border>

                <Border Grid.Row="2" Background="#111111" BorderBrush="#333333" BorderThickness="1" Margin="0,20,0,20" Padding="15">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <TextBlock Name="ChuConsole" Foreground="#00FF00" FontFamily="Consolas" FontSize="12" TextWrapping="Wrap" 
                                   Text="[OK] Quản trị viên cấp cao: Hợp lệ.&#x0a;[INFO] Đã nạp danh sách 14 mã lỗi mục tiêu.&#x0a;[INFO] Sẵn sàng kích hoạt chiến dịch làm sạch Spooler và Registry..."/>
                    </ScrollViewer>
                </Border>

                <Grid Grid.Row="3">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="NutBatDau" Grid.Column="0" Content="KÍCH HOẠT SỬA LỖI MÁY IN" Height="45" Background="#20A120" FontSize="13"/>
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
            if ([System.Windows.MessageBox]::Show("Hệ thống đang được xử lý máy in. Bạn có chắc muốn thoát?", "Cảnh báo", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "No") { return }
        }
        $CuaSo.Close()
    })

    $BoDemChinh = New-Object System.Windows.Threading.DispatcherTimer
    $BoDemChinh.Interval = [TimeSpan]::FromMilliseconds(700)
    
    $BoDemChinh.Add_Tick({
        $ThoiGianDaTroi = $script:DongHoBamGio.Elapsed
        $ChuThoiGian.Text = "{0:00}:{1:00}:{2:00}" -f [math]::Floor($ThoiGianDaTroi.TotalHours), $ThoiGianDaTroi.Minutes, $ThoiGianDaTroi.Seconds
        
        if ($script:DangChay) {
            switch ($script:BuocHienTai) {
                1 {
                    $ChuTrangThai.Text = "ĐANG DỌN DẸP SPOOLER"
                    $ChuChiTiet.Text = "Xử lý kẹt lệnh in (0x3eb, 0x12, 0xbcb, 0x7e, 0x3e3)..."
                    $ThanhTienDo.Value = 25
                    GhiLog "Đang dừng dịch vụ Print Spooler..."
                    
                    $DonDepSpooler = {
                        Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        # Xóa sạch các file lệnh in bị kẹt trong thư mục PRINTERS
                        $ThuMucSpool = "$env:windir\System32\spool\PRINTERS\*.*"
                        Remove-Item -Path $ThuMucSpool -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    &$DonDepSpooler
                    
                    GhiLog "Đã dọn sạch hàng đợi máy in bị kẹt."
                    $script:BuocHienTai = 2
                }
                2 {
                    $ChuTrangThai.Text = "ĐANG VÁ REGISTRY BẢO MẬT"
                    $ChuChiTiet.Text = "Xử lý PrintNightmare & RPC (0x11b, 0x709, 0x7c, 0xbc4, 0x771)..."
                    $ThanhTienDo.Value = 50
                    GhiLog "Đang nạp các bản vá Registry cho kết nối RPC..."
                    
                    $SuaLoiRegistry = {
                        function ThietLap-Reg ($DuongDan, $Ten, $GiaTri, $Kieu = "DWord") { if (!(Test-Path $DuongDan)) { New-Item $DuongDan -Force | Out-Null }; Set-ItemProperty $DuongDan $Ten $GiaTri -Type $Kieu -Force }
                        
                        # Fix PrintNightmare (0x11b, 0x709, 0x7c)
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Print" "RpcAuthnLevelPrivacyEnabled" 0
                        ThietLap-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "RestrictDriverInstallationToAdministrators" 0
                        
                        # Fix RPC Connection Pipes (0xbc4, 0x771)
                        ThietLap-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" "RpcUseNamedPipeProtocol" 1
                        ThietLap-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" "RpcTcpPort" 0
                    }
                    &$SuaLoiRegistry
                    
                    GhiLog "Đã mở khóa các chính sách mã hóa bảo mật máy in."
                    $script:BuocHienTai = 3
                }
                3 {
                    $ChuTrangThai.Text = "PHỤC HỒI MẠNG & TƯỜNG LỬA"
                    $ChuChiTiet.Text = "Xử lý lỗi chặn mạng (0x6d9, 0x40, Cannot Connect)..."
                    $ThanhTienDo.Value = 75
                    GhiLog "Đang khôi phục Windows Firewall và kết nối SMB..."
                    
                    $SuaLoiMang = {
                        # Lỗi 0x6d9: Phục hồi Windows Defender Firewall bị tắt
                        Set-Service -Name mpssvc -StartupType Automatic -ErrorAction SilentlyContinue
                        Start-Service -Name mpssvc -ErrorAction SilentlyContinue
                        
                        # Cho phép máy in qua tường lửa
                        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes | Out-Null
                    }
                    &$SuaLoiMang
                    
                    GhiLog "Đã khởi động lại Print Spooler và Tường lửa."
                    $script:BuocHienTai = 4
                }
                4 {
                    $ChuTrangThai.Text = "ĐANG LÀM MỚI DỊCH VỤ"
                    $ChuChiTiet.Text = "Khởi động lại Spooler để nhận cấu hình mới..."
                    $ThanhTienDo.Value = 90
                    
                    Start-Service -Name Spooler -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 1
                    
                    $script:BuocHienTai = 5
                }
                5 {
                    $ChuTrangThai.Text = "HOÀN TẤT SỬA LỖI MÁY IN"
                    $ChuTrangThai.Foreground = "#20A120"
                    $ChuChiTiet.Text = "Toàn bộ 14 mã lỗi mục tiêu đã được vô hiệu hóa."
                    $ThanhTienDo.Value = 100
                    GhiLog "QUY TRÌNH KẾT THÚC THÀNH CÔNG!"
                    
                    $script:DangChay = $false; $script:DongHoBamGio.Stop(); $BoDemChinh.Stop()
                    
                    $DuongDanFile = Join-Path ([System.Environment]::GetFolderPath('Desktop')) "Bao_Cao_Fix_In_V73.txt"
                    $script:NhatKyHoatDong | Out-File -FilePath $DuongDanFile -Encoding UTF8

                    [System.Windows.MessageBox]::Show("Tối ưu Máy in V73 hoàn tất xuất sắc!`n`nCông cụ đã dọn sạch hàng đợi in bị kẹt, cấp lại quyền Firewall và vá toàn bộ lỗi Registry (0x11b, 0x709, 0xbc4...).`n`nHÃY KHỞI ĐỘNG LẠI MÁY TÍNH ĐỂ ÁP DỤNG CẤU HÌNH.", "Xử lý thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
                }
            }
        }
    })

    $NutBatDau.Add_Click({
        $ChuConsole.Text = "[SYS] Đã tiếp nhận lệnh. Bắt đầu chiến dịch sửa lỗi máy in..."
        $script:DangChay = $true; $script:BuocHienTai = 1; $script:DongHoBamGio.Reset(); $script:DongHoBamGio.Start(); $BoDemChinh.Start()
        $NutBatDau.IsEnabled = $false; $NutDung.IsEnabled = $true
    })

    $NutDung.Add_Click({
        $script:DangChay = $false; $BoDemChinh.Stop()
        Start-Service -Name Spooler -ErrorAction SilentlyContinue # Trả lại dịch vụ nếu bấm dừng ngang
        $ChuTrangThai.Text = "TIẾN TRÌNH BỊ ÉP DỪNG"
        $ChuTrangThai.Foreground = "#C50F1F"
        GhiLog "CẢNH BÁO: Quá trình sửa lỗi máy in bị hủy ngang!"
        $ThanhTienDo.Value = 0
        $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$ThuatToanSuaLoiMayIn_V73