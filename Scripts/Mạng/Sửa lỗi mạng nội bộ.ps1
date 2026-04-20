# ==========================================================
# VIETTOOLBOX: CHUYÊN GIA MÁY IN & LAN (WPF - V64.3)
# Bản cập nhật: Hỗ trợ máy cũ, Share nội bộ & Xóa lỗi Credential
# ==========================================================

# 1. ÉP QUYỀN QUẢN TRỊ (ADMINISTRATOR)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. NẠP THƯ VIỆN GIAO DIỆN WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicFixMayInLAN_V64 = {
    # --- BIẾN ĐIỀU KHIỂN & BÁO CÁO ---
    $script:DongHoBamGio = [System.Diagnostics.Stopwatch]::New()
    $script:DangChay = $false
    $script:BuocHienTai = 0 
    $script:TienTrinhPhu = $null
    $script:BaoCaoLoi = @("==========================================================","VIETTOOLBOX - BÁO CÁO FIX MÁY IN & LAN","Ngày: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')","==========================================================")

    $BieuTuong_YTe = [char]::ConvertFromUtf32(0x1FA7A)
    $BieuTuong_TenLua = [char]::ConvertFromUtf32(0x1F680)
    $BieuTuong_Dich = [char]::ConvertFromUtf32(0x1F3C1)
    $BieuTuong_Dung = [char]::ConvertFromUtf32(0x1F6D1)

    # --- 3. GIAO DIỆN XAML ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="550" Height="480"
        WindowStartupLocation="CenterScreen" Background="Transparent" FontFamily="Segoe UI" 
        AllowsTransparency="True" WindowStyle="None" ResizeMode="CanMinimize">
    
    <Window.Resources>
        <Storyboard x:Key="HieuUngQuet" RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetName="BieuTuongQuet" Storyboard.TargetProperty="(Canvas.Left)" From="20" To="420" Duration="0:0:2" AutoReverse="True">
                <DoubleAnimation.EasingFunction><QuadraticEase EasingMode="EaseInOut"/></DoubleAnimation.EasingFunction>
            </DoubleAnimation>
        </Storyboard>
        <Storyboard x:Key="HieuUngSuaChua" RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetName="XoaySuaChua" Storyboard.TargetProperty="Angle" From="0" To="360" Duration="0:0:3"/>
        </Storyboard>

        <Style x:Key="KieuNutTieuDe" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#0078D7"/>
            <Setter Property="Width" Value="40"/><Setter Property="Height" Value="35"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
            <Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#33FFFFFF"/></Trigger></Style.Triggers>
        </Style>

        <Style x:Key="KieuNutDong" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="Width" Value="45"/><Setter Property="Height" Value="35"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
            <Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#E81123"/></Trigger></Style.Triggers>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Foreground" Value="White"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>

    <Border Background="#2D2D2D" CornerRadius="12" BorderBrush="#3F3F3F" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="35"/><RowDefinition Height="*"/></Grid.RowDefinitions>

            <Grid Name="ThanhTieuDe" Grid.Row="0" Background="#252526">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="🖨️ VietToolbox: Chuyên Gia Máy In &amp; LAN" Foreground="Gray" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="11"/>
                <Button Name="NutThuNho" Grid.Column="1" Content="—" Style="{StaticResource KieuNutTieuDe}"/>
                <Button Name="NutDong" Grid.Column="2" Content="✕" Style="{StaticResource KieuNutDong}" FontSize="14"/>
            </Grid>

            <Grid Grid.Row="1" Margin="25,10,25,25">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="60"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

                <DockPanel Grid.Row="0" Margin="0,0,0,15">
                    <TextBlock Name="ChuTrangThaiIcon" FontSize="20" Foreground="#00D4FF" VerticalAlignment="Center" Margin="0,0,8,0" FontFamily="Segoe UI Emoji">$BieuTuong_YTe</TextBlock>
                    <TextBlock Name="BieuTuongSua" FontSize="22" Margin="0,0,10,0" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5" Visibility="Collapsed" DockPanel.Dock="Left">
                        <TextBlock.RenderTransform><RotateTransform x:Name="XoaySuaChua" Angle="0"/></TextBlock.RenderTransform>
                        <Run FontFamily="Segoe UI Emoji" Text="&#x1F6E0;"/>
                    </TextBlock>
                    <TextBlock Name="ChuTrangThai" Text="Sẵn sàng xử lý..." FontSize="18" FontWeight="Bold" Foreground="#00D4FF" VerticalAlignment="Center" DockPanel.Dock="Left"/>
                    <TextBlock Name="ChuThoiGian" Text="00:00:00" FontSize="16" Foreground="Gray" HorizontalAlignment="Right" VerticalAlignment="Center" FontFamily="Consolas"/>
                </DockPanel>

                <Border Grid.Row="1" Height="15" Background="#424242" CornerRadius="7" ClipToBounds="True">
                    <ProgressBar Name="ThanhTienDo" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0" Foreground="#0078D7"/>
                </Border>

                <Canvas Grid.Row="2" VerticalAlignment="Center">
                    <TextBlock Name="BieuTuongQuet" Text="🔍" FontSize="26" Canvas.Top="10" FontFamily="Segoe UI Emoji"/>
                </Canvas>

                <TextBlock Name="ChuChiTiet" Grid.Row="3" Text="Sửa lỗi 0x11b, NTLM Credential, LAN Guest, SMB 1.0 và nạp Component máy cổ." Foreground="#A0A0A0" FontSize="13" 
                            FontStyle="Italic" HorizontalAlignment="Center" VerticalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center"/>

                <Grid Grid.Row="4">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="NutBatDau" Grid.Column="0" Content="$BieuTuong_TenLua BẮT ĐẦU FIX" Height="50" Background="#27AE60"/>
                    <Button Name="NutDung" Grid.Column="2" Content="$BieuTuong_Dung DỪNG LẠI" Height="50" Background="#D32F2F" IsEnabled="False"/>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    # Ánh xạ thành phần giao diện
    $ThanhTieuDe = $CuaSo.FindName("ThanhTieuDe"); $NutThuNho = $CuaSo.FindName("NutThuNho"); $NutDong = $CuaSo.FindName("NutDong")
    $ChuTrangThai = $CuaSo.FindName("ChuTrangThai"); $ChuThoiGian = $CuaSo.FindName("ChuThoiGian"); $ChuChiTiet = $CuaSo.FindName("ChuChiTiet")
    $ChuTrangThaiIcon = $CuaSo.FindName("ChuTrangThaiIcon"); $BieuTuongSua = $CuaSo.FindName("BieuTuongSua")
    $ThanhTienDo = $CuaSo.FindName("ThanhTienDo"); $NutBatDau = $CuaSo.FindName("NutBatDau"); $NutDung = $CuaSo.FindName("NutDung")
    $HieuUngQuet = $CuaSo.Resources["HieuUngQuet"]; $HieuUngSuaChua = $CuaSo.Resources["HieuUngSuaChua"]

    # --- SỰ KIỆN CỬA SỔ ---
    $ThanhTieuDe.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
    $NutThuNho.Add_Click({ $CuaSo.WindowState = [System.Windows.WindowState]::Minimized })
    $NutDong.Add_Click({
        if ($script:DangChay) {
            if ([System.Windows.MessageBox]::Show("Đang chạy tiến trình, bạn có chắc chắn muốn thoát không?", "Xác nhận", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "No") { return }
            if ($null -ne $script:TienTrinhPhu) { try { Stop-Process -Id $script:TienTrinhPhu.Id -Force } catch {} }
        }
        $CuaSo.Close()
    })

    # --- BỘ NÃO HẸN GIỜ (TIMER) ---
    $BoDemChinh = New-Object System.Windows.Threading.DispatcherTimer
    $BoDemChinh.Interval = [TimeSpan]::FromMilliseconds(500)
    
    $BoDemChinh.Add_Tick({
        $ThoiGianDaTroi = $script:DongHoBamGio.Elapsed
        $ChuThoiGian.Text = "{0:00}:{1:00}:{2:00}" -f [math]::Floor($ThoiGianDaTroi.TotalHours), $ThoiGianDaTroi.Minutes, $ThoiGianDaTroi.Seconds
        
        if ($script:DangChay -and $null -ne $script:TienTrinhPhu) {
            if ($script:TienTrinhPhu.HasExited) {
                $script:TienTrinhPhu = $null
                switch ($script:BuocHienTai) {
                    1 { $script:BuocHienTai = 2; $ThanhTienDo.Value = 20 } # Hoàn thành SMB1
                    2 { $script:BuocHienTai = 3; $ThanhTienDo.Value = 40 } # Hoàn thành Component cũ
                    4 { $script:BuocHienTai = 5; $ThanhTienDo.Value = 70 } # Hoàn thành Tối ưu LAN
                    5 { $script:BuocHienTai = 6; $ThanhTienDo.Value = 100 } # Hoàn thành Khởi động Dịch vụ
                }
            } elseif ($ThanhTienDo.Value -lt 99) { $ThanhTienDo.Value += 0.05 }
        }

        if ($script:DangChay -and $null -eq $script:TienTrinhPhu) {
            switch ($script:BuocHienTai) {
                1 {
                    $ChuTrangThai.Text = "🌐 Nạp SMB 1.0..."; $ChuChiTiet.Text = "Kích hoạt giao thức chia sẻ cho máy đời cũ (Win XP/7)..."
                    $ThanhTienDo.IsIndeterminate = $true
                    $script:TienTrinhPhu = Start-Process dism.exe -ArgumentList "/online /enable-feature /featurename:SMB1Protocol /all /norestart" -WindowStyle Hidden -PassThru
                }
                2 {
                    $ChuTrangThai.Text = "📦 Nạp Component cũ..."; $ChuChiTiet.Text = "Đang cài đặt DirectPlay và Function Discovery để các máy thấy nhau..."
                    $ThanhTienDo.IsIndeterminate = $true
                    $script:TienTrinhPhu = Start-Process dism.exe -ArgumentList "/online /enable-feature /featurename:DirectPlay /all /norestart" -WindowStyle Hidden -PassThru
                }
                3 {
                    $ChuTrangThaiIcon.Visibility = "Collapsed"; $BieuTuongSua.Visibility = "Visible"; $HieuUngSuaChua.Begin($CuaSo)
                    $ChuTrangThai.Text = "🛠️ Vá Registry & Giao thức..."; $ChuChiTiet.Text = "Xử lý lỗi Credential NTLM, đổi mạng sang Private và vá 0x11b..."
                    $ThanhTienDo.IsIndeterminate = $false
                    
                    # Chạy các lệnh vá Registry & Dịch vụ nội bộ
                    $SuaLoiHeThong = {
                        function ThietLap-Reg ($DuongDan, $Ten, $GiaTri, $Kieu = "DWord") { if (!(Test-Path $DuongDan)) { New-Item $DuongDan -Force | Out-Null }; Set-ItemProperty $DuongDan $Ten $GiaTri -Type $Kieu -Force }
                        
                        # Xử lý Guest, 0x11b
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Print" "RpcAuthnLevelPrivacyEnabled" 0
                        ThietLap-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "RestrictDriverInstallationToAdministrators" 0
                        
                        # Xử lý lỗi hỏi Credential liên tục (NTLM và Mật khẩu trống)
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" 1
                        ThietLap-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LimitBlankPasswordUse" 0
                        
                        # Kích hoạt các Dịch vụ tìm kiếm máy tính trong mạng nội bộ
                        $DanhSachDichVu = @("fdPHost", "FDResPub", "SSDPSRV", "upnphost")
                        foreach ($DichVu in $DanhSachDichVu) {
                            Set-Service $DichVu -StartupType Automatic
                            Start-Service $DichVu -ErrorAction SilentlyContinue
                        }

                        # Bật Network Discovery qua Tường lửa (Firewall)
                        netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
                        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

                        # Tự động quét và chuyển đổi tất cả mạng Public sang Private
                        $DanhSachMang = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Public" }
                        if ($DanhSachMang) {
                            foreach ($Mang in $DanhSachMang) {
                                Set-NetConnectionProfile -InterfaceAlias $Mang.InterfaceAlias -NetworkCategory Private
                            }
                        }
                    }
                    &$SuaLoiHeThong
                    $script:BaoCaoLoi += "[$(Get-Date -Format 'HH:mm:ss')] Đã nạp thành công bộ Fix NTLM, Credential và Discovery."
                    $script:BuocHienTai = 4
                }
                4 {
                    $ChuTrangThai.Text = "🚀 Tối ưu kết nối..."; $ChuChiTiet.Text = "Tắt yêu cầu chữ ký SMB Signing để tăng tốc độ truyền tải..."
                    $script:TienTrinhPhu = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-SmbClientConfiguration -RequireSecuritySignature `$false -Force; Set-SmbServerConfiguration -RequireSecuritySignature `$false -Force`"" -WindowStyle Hidden -PassThru
                }
                5 {
                    $ChuTrangThai.Text = "🖨️ Làm mới dịch vụ..."; $ChuChiTiet.Text = "Đang khởi động lại Print Spooler và LanmanWorkstation..."
                    $script:TienTrinhPhu = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Service Spooler -StartupType Automatic; Restart-Service Spooler -Force; Restart-Service LanmanWorkstation -Force`"" -WindowStyle Hidden -PassThru
                }
                6 {
                    $script:DangChay = $false; $script:DongHoBamGio.Stop(); $BoDemChinh.Stop(); $HieuUngQuet.Stop($CuaSo); $HieuUngSuaChua.Stop($CuaSo)
                    
                    # XUẤT BÁO CÁO KẾT QUẢ
                    $DuongDanDesktop = [System.Environment]::GetFolderPath('Desktop'); $DuongDanFile = Join-Path $DuongDanDesktop "Bao_Cao_Fix_In_LAN.txt"
                    $script:BaoCaoLoi += "=========================================================="
                    $script:BaoCaoLoi += "TỔNG KẾT: Đã hoàn tất sửa lỗi NTLM, nạp SMB1, DirectPlay và chuyển mạng Private."
                    $script:BaoCaoLoi | Out-File -FilePath $DuongDanFile -Encoding UTF8

                    $ChuTrangThaiIcon.Visibility = "Visible"; $BieuTuongSua.Visibility = "Collapsed"; $ChuTrangThaiIcon.Text = $BieuTuong_Dich
                    $ChuTrangThai.Text = "🏁 HOÀN TẤT!"; $ChuTrangThai.Foreground = "#27AE60"
                    $ChuChiTiet.Text = "Đã xử lý triệt để lỗi Credential & Máy cổ. Hãy khởi động lại máy tính!"
                    
                    [System.Windows.MessageBox]::Show("Đã hoàn tất quy trình sửa lỗi!`n`nĐã kích hoạt chuẩn NTLM cũ, chuyển cấu hình mạng sang Private và hỗ trợ kết nối máy in nội bộ thành công. Xin vui lòng khởi động lại máy tính để áp dụng.", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
                }
            }
        }
    })

    # --- SỰ KIỆN NÚT BẤM ---
    $NutBatDau.Add_Click({
        $script:DangChay = $true; $script:BuocHienTai = 1; $script:DongHoBamGio.Reset(); $script:DongHoBamGio.Start(); $BoDemChinh.Start()
        $NutBatDau.IsEnabled = $false; $NutDung.IsEnabled = $true; $HieuUngQuet.Begin($CuaSo)
    })

    $NutDung.Add_Click({
        $script:DangChay = $false; $BoDemChinh.Stop(); $HieuUngQuet.Stop($CuaSo); $HieuUngSuaChua.Stop($CuaSo)
        if ($null -ne $script:TienTrinhPhu) { try { Stop-Process -Id $script:TienTrinhPhu.Id -Force } catch {} }
        $ChuTrangThaiIcon.Visibility = "Visible"; $BieuTuongSua.Visibility = "Collapsed"; $ChuTrangThaiIcon.Text = $BieuTuong_Dung
        $ChuTrangThai.Text = "⛔ ĐÃ HỦY QUY TRÌNH!"; $ThanhTienDo.Value = 0; $NutBatDau.IsEnabled = $true; $NutDung.IsEnabled = $false
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$LogicFixMayInLAN_V64