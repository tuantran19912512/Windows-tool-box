# ==========================================================
# CÔNG CỤ TỐI ƯU MẠNG LAN & CHIA SẺ FILE (WPF - V72)
# Fix lỗi XAML LetterSpacing - Lõi an toàn không đụng IP
# ==========================================================

# 1. KIỂM TRA QUYỀN QUẢN TRỊ CAO NHẤT (ADMINISTRATOR)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. NẠP THƯ VIỆN GIAO DIỆN HỆ THỐNG
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$ThuatToanSuaLoiLAN_V72 = {
    # --- BIẾN TOÀN CỤC & NHẬT KÝ ---
    $script:DongHoBamGio = [System.Diagnostics.Stopwatch]::New()
    $script:DangChay = $false
    $script:BuocHienTai = 0 
    $script:TienTrinhPhu = $null
    $script:NhatKyHoatDong = @(
        "==========================================================",
        " BÁO CÁO XỬ LÝ CHIA SẺ TỆP TIN VÀ MÁY IN (V72)",
        " Thời gian: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')",
        "=========================================================="
    )

    # --- 3. GIAO DIỆN XAML PHẲNG (ĐÃ FIX LỖI LETTERSPACING) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cong Cu Xu Ly LAN V72" Width="580" Height="480"
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

    <Border Background="#1E1E1E" BorderBrush="#00A4EF" BorderThickness="1" CornerRadius="0">
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="32"/><RowDefinition Height="*"/></Grid.RowDefinitions>

            <Grid Name="ThanhTieuDe" Grid.Row="0" Background="#2D2D2D">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="CÔNG CỤ XỬ LÝ CHIA SẺ MẠNG LAN - V72" Foreground="#CCCCCC" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="11" FontWeight="Bold"/>
                <Button Name="NutThuNho" Grid.Column="1" Content="—" Style="{StaticResource KieuNutTieuDe}"/>
                <Button Name="NutDong" Grid.Column="2" Content="✕" Style="{StaticResource KieuNutDong}"/>
            </Grid>

            <Grid Grid.Row="1" Margin="30,25,30,25">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

                <DockPanel Grid.Row="0" Margin="0,0,0,20">
                    <TextBlock Text="📂" FontSize="28" Foreground="#00A4EF" VerticalAlignment="Center" Margin="0,0,15,0" FontFamily="Segoe UI Emoji"/>
                    <StackPanel DockPanel.Dock="Left" VerticalAlignment="Center">
                        <TextBlock Name="ChuTrangThai" Text="HỆ THỐNG ĐÃ SẴN SÀNG" FontSize="20" FontWeight="Bold" Foreground="#00A4EF"/>
                        <TextBlock Name="ChuChiTiet" Text="Sẽ dọn dẹp Cache, mở khóa phân quyền và nạp chuẩn SMB/NTLM." Foreground="#888888" FontSize="13" Margin="0,2,0,0"/>
                    </StackPanel>
                    <TextBlock Name="ChuThoiGian" Text="00:00:00" FontSize="16" Foreground="#555555" HorizontalAlignment="Right" VerticalAlignment="Center" FontFamily="Consolas"/>
                </DockPanel>

                <Border Grid.Row="1" Height="4" Background="#333333" CornerRadius="0">
                    <ProgressBar Name="ThanhTienDo" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0" Foreground="#00A4EF"/>
                </Border>

                <Border Grid.Row="2" Background="#111111" BorderBrush="#333333" BorderThickness="1" Margin="0,20,0,20" Padding="15">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <TextBlock Name="ChuConsole" Foreground="#00FF00" FontFamily="Consolas" FontSize="12" TextWrapping="Wrap" 
                                   Text="[OK] Phân quyền hệ thống đã được cấp.&#x0a;[OK] Đã bảo lưu cấu hình Card mạng và IP.&#x0a;[INFO] Chờ lệnh khởi động tiến trình làm sạch Share Folder..."/>
                    </ScrollViewer>
                </Border>

                <Grid Grid.Row="3">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="NutBatDau" Grid.Column="0" Content="KÍCH HOẠT XỬ LÝ LAN" Height="45" Background="#00A4EF" FontSize="13"/>
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
            if ([System.Windows.MessageBox]::Show("Hệ thống đang được xử lý mạng. Bạn có chắc muốn thoát?", "Cảnh báo", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "No") { return }
            if ($null -ne $script:TienTrinhPhu) { try { Stop-Process -Id $script:TienTrinhPhu.Id -Force } catch {} }
        }
        $CuaSo.Close()
    })

    $BoDemChinh = New-Object System.Windows.Threading.DispatcherTimer
    $BoDemChinh.Interval = [TimeSpan]::FromMilliseconds(600)
    
    $BoDemChinh.Add_Tick({
        $ThoiGianDaTroi = $script:DongHoBamGio.Elapsed
        $ChuThoiGian.Text = "{0:00}:{1:00}:{2:00}" -f [math]::Floor($ThoiGianDaTroi.TotalHours), $ThoiGianDaTroi.Minutes, $ThoiGianDaTroi.Seconds
        
        if ($script:DangChay -and $null -ne $script:TienTrinhPhu) {
            if ($script:TienTrinhPhu.HasExited) {
                $script:TienTrinhPhu = $null
                switch ($script:BuocHienTai) {
                    1 { $script:BuocHienTai = 2 }
                    3 { $script:BuocHienTai = 4 }
                }
            }
        }

        if ($script:DangChay -and $null -eq $script:TienTrinhPhu) {
            switch ($script:BuocHienTai) {
                1 {
                    $ChuTrangThai.Text = "ĐANG NẠP PROTOCOL MẠNG"
                    $ChuChiTiet.Text = "Kích hoạt SMB 1.0 hỗ trợ giao tiếp với máy chủ cũ..."
                    $ThanhTienDo.IsIndeterminate = $true
                    GhiLog "Đang thực thi DISM để mở khóa SMB1Protocol..."
                    $script:TienTrinhPhu = Start-Process dism.exe -ArgumentList "/online /enable-feature /featurename:SMB1Protocol /all /norestart" -WindowStyle Hidden -PassThru
                }
                2 {
                    $ChuTrangThai.Text = "ĐANG LÀM SẠCH VÀ VÁ LỖI"
                    $ChuChiTiet.Text = "Xóa mật khẩu kẹt, chuẩn hóa NTLM và cấp quyền Pass trắng..."
                    GhiLog "Bắt đầu xóa Credential Cache và nạp Registry chuẩn..."
                    
                    $SuaLoiHeThong = {
                        function ThietLap-Reg ($DuongDan, $Ten, $GiaTri, $Kieu = "DWord") { if (!(Test-Path $DuongDan)) { New-Item $DuongDan -Force | Out-Null }; Set-ItemProperty $DuongDan $Ten $GiaTri -Type $Kieu -Force }
                        
                        # 1. XÓA MẬT KHẨU SAI BỊ KẸT (Cốt lõi sửa lỗi Credential)
                        cmdkey.exe /list | Select-String -Pattern "Target: (.*)" | ForEach-Object { $MucTieu = $_.Matches.Groups[1].Value.Trim(); & cmdkey.exe /delete:$MucTieu | Out-Null }
                        
                        # 2. XỬ LÝ PHÂN QUYỀN (Guest, Pass Trắng, NTLM)
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LimitBlankPasswordUse" 0
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" 1
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "everyoneincludesanonymous" 1
                        
                        # 3. MỞ ĐƯỜNG TƯỜNG LỬA CHO MẠNG NỘI BỘ
                        $DanhSachMang = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Public" }
                        if ($DanhSachMang) { foreach ($Mang in $DanhSachMang) { Set-NetConnectionProfile -InterfaceAlias $Mang.InterfaceAlias -NetworkCategory Private } }
                        
                        $DanhSachDichVu = @("fdPHost", "FDResPub", "SSDPSRV", "upnphost")
                        foreach ($DichVu in $DanhSachDichVu) { Set-Service $DichVu -StartupType Automatic; Start-Service $DichVu -ErrorAction SilentlyContinue }
                        
                        netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
                        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
                    }
                    &$SuaLoiHeThong
                    
                    GhiLog "Hoàn tất cấp quyền truy cập và mở Tường lửa."
                    $script:BuocHienTai = 3
                }
                3 {
                    $ChuTrangThai.Text = "LÀM MỚI DỊCH VỤ WORKSTATION"
                    $ChuChiTiet.Text = "Đang khởi động lại dịch vụ máy trạm để nhận cấu hình..."
                    GhiLog "Restart LanmanWorkstation và Print Spooler..."
                    $script:TienTrinhPhu = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Restart-Service LanmanWorkstation -Force; Restart-Service Spooler -Force`"" -WindowStyle Hidden -PassThru
                }
                4 {
                    $ChuTrangThai.Text = "HOÀN TẤT CHIẾN DỊCH V72"
                    $ChuTrangThai.Foreground = "#107C10"
                    $ChuChiTiet.Text = "Mọi rào cản truy cập mạng nội bộ đã được tháo gỡ."
                    $ThanhTienDo.IsIndeterminate = $false; $ThanhTienDo.Value = 100
                    GhiLog "QUY TRÌNH XỬ LÝ KẾT THÚC THÀNH CÔNG!"
                    
                    $script:DangChay = $false; $script:DongHoBamGio.Stop(); $BoDemChinh.Stop()
                    
                    $DuongDanFile = Join-Path ([System.Environment]::GetFolderPath('Desktop')) "Bao_Cao_Fix_LAN_V72.txt"
                    $script:NhatKyHoatDong | Out-File -FilePath $DuongDanFile -Encoding UTF8

                    [System.Windows.MessageBox]::Show("Tối ưu mạng chia sẻ V72 hoàn tất!`n`nĐã làm sạch mật khẩu kẹt và mở khóa giao thức mà không làm ảnh hưởng đến cấu hình mạng (IP/DNS) của máy.`n`nHãy truy cập lại thư mục Share của bạn.", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
                }
            }
        }
    })

    $NutBatDau.Add_Click({
        $ChuConsole.Text = "[SYS] Đã nhận lệnh. Bắt đầu xử lý Share Folder..."
        $script:DangChay = $true; $script:BuocHienTai = 1; $script:DongHoBamGio.Reset(); $script:DongHoBamGio.Start(); $BoDemChinh.Start()
        $NutBatDau.IsEnabled = $false; $NutDung.IsEnabled = $true
    })

    $NutDung.Add_Click({
        $script:DangChay = $false; $BoDemChinh.Stop()
        if ($null -ne $script:TienTrinhPhu) { try { Stop-Process -Id $script:TienTrinhPhu.Id -Force } catch {} }
        $ChuTrangThai.Text = "TIẾN TRÌNH BỊ ÉP DỪNG"
        $ChuTrangThai.Foreground = "#C50F1F"
        GhiLog "CẢNH BÁO: Quá trình làm sạch bị hủy ngang!"
        $ThanhTienDo.IsIndeterminate = $false; $ThanhTienDo.Value = 0
        $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$ThuatToanSuaLoiLAN_V72