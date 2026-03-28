# ==============================================================================
# Tên công cụ: VIETTOOLBOX - TRUNG TÂM SAO LƯU & PHỤC HỒI DRIVER
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Nâng cấp: Sửa lỗi mất 3 nút khi Fullscreen, thêm góc kéo để tự do co giãn
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- ĐỊNH NGHĨA KHUÔN DỮ LIỆU ---
Add-Type -TypeDefinition @"
public class DuLieuDriver {
    public bool DuocChon { get; set; }
    public string LoaiThietBi { get; set; }
    public string NhaCungCap { get; set; }
    public string MoTa { get; set; }
    public string TenInf { get; set; }
    public string PhienBan { get; set; }
}
"@

$laQuanTri = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($laQuanTri -eq $false) { 
    [System.Windows.MessageBox]::Show("Tuấn ơi, chuột phải chọn Run as Administrator nhé!", "Thiếu quyền", 0, 48)
    exit 
}

$global:yeuCauDung = $false

# --- GIAO DIỆN XAML WPF ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Quản Lý Driver" Width="1050" Height="750" MinWidth="900" MinHeight="600" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" Opacity="0">
    
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.4"/></Storyboard></BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Window.Resources>
        <Style x:Key="NutChuyenDong" TargetType="Button">
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="RenderTransform"><Setter.Value><ScaleTransform ScaleX="1" ScaleY="1"/></Setter.Value></Setter>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <EventTrigger RoutedEvent="MouseEnter"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1.02" Duration="0:0:0.1"/><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1.02" Duration="0:0:0.1"/></Storyboard></BeginStoryboard></EventTrigger>
                <EventTrigger RoutedEvent="MouseLeave"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1" Duration="0:0:0.1"/><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1" Duration="0:0:0.1"/></Storyboard></BeginStoryboard></EventTrigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="RowStyleDong" TargetType="DataGridRow">
            <Setter Property="Background" Value="#1E293B"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="BorderThickness" Value="0,0,0,1"/>
            <Setter Property="BorderBrush" Value="#0F172A"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#334155"/></Trigger>
                <Trigger Property="IsSelected" Value="True"><Setter Property="Background" Value="#3B82F6"/><Setter Property="Foreground" Value="White"/></Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Border Name="KhungVien" CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Name="BoGocTieuDe" Height="50" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0" Panel.ZIndex="2">
                <Grid>
                    <TextBlock Text="🛡️ VIETTOOLBOX - TRUNG TÂM SAO LƯU &amp; PHỤC HỒI DRIVER V19.22" Foreground="#38BDF8" FontWeight="Bold" FontSize="16" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,10,0">
                        <Button Name="NutThuNho" Content="—" Width="40" Background="Transparent" Foreground="#94A3B8" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                        <Button Name="NutPhongTo" Content="◻" Width="40" Background="Transparent" Foreground="#94A3B8" BorderThickness="0" FontSize="18" Cursor="Hand" FontWeight="Bold"/>
                        <Button Name="NutDongCuaSo" Content="✕" Width="40" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                    </StackPanel>
                </Grid>
            </Border>
            
            <Grid Margin="0,50,0,0" VerticalAlignment="Top" Height="35" Panel.ZIndex="3">
                <ProgressBar Name="ThanhTienTrinh" Height="3" VerticalAlignment="Top" IsIndeterminate="True" Visibility="Hidden" Background="Transparent" Foreground="#F59E0B" BorderThickness="0"/>
                <Button Name="NutDung" Content="⏹ DỪNG LẠI" Width="100" Height="26" Background="#EF4444" Foreground="White" FontWeight="Bold" FontSize="12" Cursor="Hand" HorizontalAlignment="Right" Margin="0,5,20,0" Visibility="Hidden">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></Button.Resources>
                </Button>
            </Grid>

            <Grid Margin="20,70,20,20">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,15">
                    <Button Name="NutQuetDriver" Content="🔍 QUÉT HỆ THỐNG" Width="160" Height="35" Background="#3B82F6" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                    <TextBlock Name="NhanTrangThai" Text="Bấm Quét Hệ Thống để tải danh sách. Sau đó dùng các nút bên dưới để chọn nhanh." Foreground="#94A3B8" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="14" FontStyle="Italic"/>
                </StackPanel>

                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
                    <Button Name="NutChonTatCa" Content="☑ Chọn tất cả" Width="110" Height="28" Background="#475569" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,8,0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutBoChon" Content="☐ Bỏ chọn" Width="100" Height="28" Background="#475569" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,8,0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutChonThietYeu" Content="⭐ Chọn Driver chính yếu (Mạng, VGA, Âm thanh, Chipset)" Padding="10,0" Height="28" Background="#F59E0B" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></Button.Resources>
                    </Button>
                </StackPanel>

                <DataGrid Name="BangDanhSach" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" CanUserSortColumns="True" Background="#1E293B" Foreground="#E2E8F0" RowBackground="#1E293B" AlternatingRowBackground="#0F172A" HeadersVisibility="Column" GridLinesVisibility="None" BorderThickness="1" BorderBrush="#334155" SelectionMode="Single" RowStyle="{StaticResource RowStyleDong}">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader">
                            <Setter Property="Background" Value="#334155"/>
                            <Setter Property="Foreground" Value="White"/>
                            <Setter Property="FontWeight" Value="Bold"/>
                            <Setter Property="Padding" Value="10,8"/>
                            <Setter Property="Cursor" Value="Hand"/>
                        </Style>
                        <Style TargetType="DataGridCell">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="DataGridCell">
                                        <Border Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}">
                                            <ContentPresenter VerticalAlignment="Center" />
                                        </Border>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridCheckBoxColumn Header="CHỌN" Binding="{Binding DuocChon, UpdateSourceTrigger=PropertyChanged}" Width="70">
                            <DataGridCheckBoxColumn.ElementStyle>
                                <Style TargetType="CheckBox"><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
                            </DataGridCheckBoxColumn.ElementStyle>
                        </DataGridCheckBoxColumn>
                        <DataGridTextColumn Header="LOẠI THIẾT BỊ" Binding="{Binding LoaiThietBi}" Width="150" IsReadOnly="True"/>
                        <DataGridTextColumn Header="NHÀ CUNG CẤP" Binding="{Binding NhaCungCap}" Width="200" IsReadOnly="True"/>
                        <DataGridTextColumn Header="MÔ TẢ (TÊN FILE GỐC)" Binding="{Binding MoTa}" Width="*" IsReadOnly="True"/>
                        <DataGridTextColumn Header="PHIÊN BẢN" Binding="{Binding PhienBan}" Width="120" IsReadOnly="True"/>
                    </DataGrid.Columns>
                </DataGrid>

                <Grid Grid.Row="3" Margin="0,15,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Button Name="NutSaoLuu" Grid.Column="0" Content="📦 SAO LƯU DRIVER &amp; TẠO FILE TỰ PHỤC HỒI" Height="50" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="14" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0" Style="{StaticResource NutChuyenDong}"/>
                    
                    <Button Name="NutPhucHoi" Grid.Column="1" Content="♻️ PHỤC HỒI DRIVER TỪ THƯ MỤC KHÁC" Height="50" Background="#F43F5E" Foreground="White" FontWeight="Bold" FontSize="14" BorderThickness="0" Cursor="Hand" Margin="10,0,0,0" Style="{StaticResource NutChuyenDong}"/>
                </Grid>
            </Grid>

            <Thumb Name="GocKeo" Width="15" Height="15" HorizontalAlignment="Right" VerticalAlignment="Bottom" Cursor="SizeNWSE" Background="Transparent" Panel.ZIndex="10" ToolTip="Giữ chuột và kéo để thay đổi kích thước">
                <Thumb.Template>
                    <ControlTemplate>
                        <Path Data="M15,15 L0,15 L15,0 Z" Fill="#475569" Opacity="0.8" Margin="0,0,4,4" HorizontalAlignment="Right" VerticalAlignment="Bottom"/>
                    </ControlTemplate>
                </Thumb.Template>
            </Thumb>
        </Grid>
    </Border>
</Window>
"@

$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

$nutDongCuaSo = $CuaSo.FindName("NutDongCuaSo"); $nutThuNho = $CuaSo.FindName("NutThuNho"); $nutPhongTo = $CuaSo.FindName("NutPhongTo")
$nutQuetDriver = $CuaSo.FindName("NutQuetDriver"); $nutChonTatCa = $CuaSo.FindName("NutChonTatCa"); $nutBoChon = $CuaSo.FindName("NutBoChon"); $nutChonThietYeu = $CuaSo.FindName("NutChonThietYeu")
$nutSaoLuu = $CuaSo.FindName("NutSaoLuu"); $nutPhucHoi = $CuaSo.FindName("NutPhucHoi"); $bangDanhSach = $CuaSo.FindName("BangDanhSach")
$nhanTrangThai = $CuaSo.FindName("NhanTrangThai"); $thanhTienTrinh = $CuaSo.FindName("ThanhTienTrinh"); $nutDung = $CuaSo.FindName("NutDung")
$khungVien = $CuaSo.FindName("KhungVien"); $boGocTieuDe = $CuaSo.FindName("BoGocTieuDe"); $gocKeo = $CuaSo.FindName("GocKeo")

# --- ĐIỀU KHIỂN CỬA SỔ & CO GIÃN TỰ DO ---
$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDongCuaSo.Add_Click({ $CuaSo.Close() })
$nutThuNho.Add_Click({ $CuaSo.WindowState = [System.Windows.WindowState]::Minimized })

# Ngăn cửa sổ che Taskbar khi Fullscreen
$CuaSo.MaxHeight = [System.Windows.SystemParameters]::WorkArea.Height
$CuaSo.MaxWidth = [System.Windows.SystemParameters]::WorkArea.Width

$nutPhongTo.Add_Click({ 
    if ($CuaSo.WindowState -eq [System.Windows.WindowState]::Maximized) { 
        $CuaSo.WindowState = [System.Windows.WindowState]::Normal
        $khungVien.CornerRadius = "15"
        $boGocTieuDe.CornerRadius = "15,15,0,0"
    } else { 
        $CuaSo.WindowState = [System.Windows.WindowState]::Maximized
        $khungVien.CornerRadius = "0"
        $boGocTieuDe.CornerRadius = "0"
    } 
})

# Code xử lý kéo thả góc (Resize Grip)
$gocKeo.Add_DragDelta({
    param($sender, $e)
    if ($CuaSo.WindowState -ne [System.Windows.WindowState]::Maximized) {
        $xMoi = $CuaSo.Width + $e.HorizontalChange
        $yMoi = $CuaSo.Height + $e.VerticalChange
        if ($xMoi -gt $CuaSo.MinWidth) { $CuaSo.Width = $xMoi }
        if ($yMoi -gt $CuaSo.MinHeight) { $CuaSo.Height = $yMoi }
    }
})

$duLieuHienThi = New-Object System.Collections.ObjectModel.ObservableCollection[DuLieuDriver]
$bangDanhSach.ItemsSource = $duLieuHienThi

function CapNhat-TrangThaiChay($DangChay) {
    if ($DangChay) {
        $global:yeuCauDung = $false; $thanhTienTrinh.Visibility = "Visible"; $nutDung.Visibility = "Visible"
        $nutQuetDriver.IsEnabled = $false; $nutSaoLuu.IsEnabled = $false; $nutPhucHoi.IsEnabled = $false
    } else {
        $thanhTienTrinh.Visibility = "Hidden"; $nutDung.Visibility = "Hidden"
        $nutQuetDriver.IsEnabled = $true; $nutSaoLuu.IsEnabled = $true; $nutPhucHoi.IsEnabled = $true
    }
}

$nutDung.Add_Click({ 
    $global:yeuCauDung = $true
    $nhanTrangThai.Text = "⚠️ Đang chém đứt tiến trình... Đợi chút nhé!"
    $nhanTrangThai.Foreground = "#EF4444" 
})

# 1. QUÉT DRIVER
$nutQuetDriver.Add_Click({
    CapNhat-TrangThaiChay $true
    $nhanTrangThai.Text = "⏳ Đang lấy danh sách Driver từ hệ thống. Quá trình này không thể dừng giữa chừng..."
    $nhanTrangThai.Foreground = "#F59E0B"
    $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
    $duLieuHienThi.Clear()
    
    try {
        $danhSachGoc = Get-WindowsDriver -Online
        $nhanTrangThai.Text = "⏳ Đang phân tích danh sách..."
        $nhomChinhYeu = @("Net", "Display", "System", "Media", "Bluetooth")
        $demChinhYeu = 0

        foreach ($dr in $danhSachGoc) {
            $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
            if ($global:yeuCauDung) { break }
            $tuDongChon = $false
            if ($nhomChinhYeu -contains $dr.ClassName) { $tuDongChon = $true; $demChinhYeu++ }
            
            $doiTuong = New-Object DuLieuDriver
            $doiTuong.DuocChon = $tuDongChon; $doiTuong.LoaiThietBi = $dr.ClassName; $doiTuong.NhaCungCap = $dr.ProviderName
            $doiTuong.MoTa = $dr.OriginalFileName; $doiTuong.TenInf = $dr.Driver; $doiTuong.PhienBan = $dr.Version
            $duLieuHienThi.Add($doiTuong)
        }
        
        if ($global:yeuCauDung) {
            $nhanTrangThai.Text = "⛔ Đã hủy quét hệ thống theo yêu cầu."; $nhanTrangThai.Foreground = "#EF4444"
        } else {
            $nhanTrangThai.Text = "✅ Đã tải $($duLieuHienThi.Count) Driver. Tự động đánh dấu $demChinhYeu Driver chính yếu."; $nhanTrangThai.Foreground = "#38BDF8"
        }
    } catch {
        $nhanTrangThai.Text = "❌ Lỗi trong quá trình quét hệ thống!"; $nhanTrangThai.Foreground = "#EF4444"
    } finally { CapNhat-TrangThaiChay $false }
})

$nutChonTatCa.Add_Click({ foreach ($muc in $duLieuHienThi) { $muc.DuocChon = $true }; $bangDanhSach.Items.Refresh() })
$nutBoChon.Add_Click({ foreach ($muc in $duLieuHienThi) { $muc.DuocChon = $false }; $bangDanhSach.Items.Refresh() })
$nutChonThietYeu.Add_Click({
    $nhomChinhYeu = @("Net", "Display", "System", "Media", "Bluetooth")
    foreach ($muc in $duLieuHienThi) { if ($nhomChinhYeu -contains $muc.LoaiThietBi) { $muc.DuocChon = $true } else { $muc.DuocChon = $false } }
    $bangDanhSach.Items.Refresh()
})

function Xuat-MatKhauWifi($ThuMucLuu) {
    try {
        $hoSoWlan = netsh wlan show profiles
        $danhSachTenWifi = @()
        foreach ($dong in $hoSoWlan) { if ($dong -match ":\s+(.+)$") { $ten = $matches[1].Trim(); if ($ten -ne "") { $danhSachTenWifi += $ten } } }
        
        if ($danhSachTenWifi.Count -gt 0) {
            $fileMatKhau = "$ThuMucLuu\MatKhau_WIFI_DaLuu.txt"
            "==========================================" | Out-File -LiteralPath $fileMatKhau -Encoding UTF8
            "    DANH SACH MAT KHAU WIFI TREN MAY      " | Out-File -LiteralPath $fileMatKhau -Append -Encoding UTF8
            "==========================================" | Out-File -LiteralPath $fileMatKhau -Append -Encoding UTF8
            
            foreach ($tenWifi in $danhSachTenWifi) {
                $thongTin = netsh wlan show profile name="$tenWifi" key=clear
                $matKhau = "<Khong co hoac Mang mo>"
                foreach ($dong in $thongTin) { if ($dong -match "(Key Content|Nội dung phím|Nội dung Khóa)\s*:\s*(.+)$") { $matKhau = $matches[2].Trim(); break } }
                "Ten Wifi (SSID) : $tenWifi" | Out-File -LiteralPath $fileMatKhau -Append -Encoding UTF8
                "Mat khau        : $matKhau" | Out-File -LiteralPath $fileMatKhau -Append -Encoding UTF8
                "------------------------------------------" | Out-File -LiteralPath $fileMatKhau -Append -Encoding UTF8
            }
            return $true
        }
        return $false
    } catch { return $false }
}

# 3. SAO LƯU (CÓ CƠ CHẾ TIMEOUT 25s VÀ TASKKILL)
$nutSaoLuu.Add_Click({
    $cacMucDaChon = $duLieuHienThi | Where-Object { $_.DuocChon -eq $true }
    if ($cacMucDaChon.Count -eq 0) { [System.Windows.MessageBox]::Show($CuaSo, "Tuấn chưa tích chọn Driver nào để sao lưu kìa!", "Thông báo", 0, 48); return }

    $hopThoaiLuu = New-Object System.Windows.Forms.FolderBrowserDialog
    $hopThoaiLuu.Description = "CHỌN NƠI LƯU BẢN BACKUP DRIVER"
    if ($hopThoaiLuu.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        
        $thoiGianThuc = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $thuMucBackup = "$($hopThoaiLuu.SelectedPath)\VietToolbox_Driver_$thoiGianThuc"
        New-Item -ItemType Directory -Force -Path $thuMucBackup | Out-Null
        
        CapNhat-TrangThaiChay $true
        $thanhCong = 0; $tongSo = $cacMucDaChon.Count
        $soBoQua = 0
        
        foreach ($driver in $cacMucDaChon) {
            $nhanTrangThai.Text = "⏳ Đang trích xuất ($thanhCong/$tongSo) Driver..."
            $nhanTrangThai.Foreground = "#38BDF8"
            $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
            
            if ($global:yeuCauDung) { break }

            try {
                if ($driver.LoaiThietBi -eq "Net") { $thuMucCon = "$thuMucBackup\1_Driver_Mang" } 
                else { $thuMucCon = "$thuMucBackup\2_Driver_Khac" }
                if (!(Test-Path $thuMucCon)) { New-Item -ItemType Directory -Force -Path $thuMucCon | Out-Null }

                $thamSo = "/export-driver $($driver.TenInf) `"$thuMucCon`""
                $tienTrinhBackup = Start-Process -FilePath "pnputil.exe" -ArgumentList $thamSo -WindowStyle Hidden -PassThru
                
                $thoiGianBatDau = Get-Date
                $biTreo = $false
                
                while (-not $tienTrinhBackup.HasExited) {
                    $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
                    if ($global:yeuCauDung) { 
                        Start-Process "taskkill.exe" -ArgumentList "/F /T /PID $($tienTrinhBackup.Id)" -WindowStyle Hidden -Wait
                        break 
                    }
                    if (((Get-Date) - $thoiGianBatDau).TotalSeconds -gt 25) {
                        Start-Process "taskkill.exe" -ArgumentList "/F /T /PID $($tienTrinhBackup.Id)" -WindowStyle Hidden -Wait
                        $biTreo = $true
                        $soBoQua++
                        break
                    }
                    Start-Sleep -Milliseconds 50
                }
                
                if ($global:yeuCauDung) { break }
                if ($biTreo -eq $false) { $thanhCong++ }
                
            } catch { }
        }

        if ($global:yeuCauDung) {
            $nhanTrangThai.Text = "⛔ Đã hủy sao lưu! Chỉ copy được $thanhCong Driver."
            $nhanTrangThai.Foreground = "#EF4444"
            [System.Windows.MessageBox]::Show($CuaSo, "Đã dừng sao lưu! Dữ liệu đang chép dở nằm tại: $thuMucBackup", "Đã hủy", 0, 48)
        } else {
            $coMang = $cacMucDaChon | Where-Object { $_.LoaiThietBi -eq "Net" }
            $chuoiWifi = ""
            if ($coMang) { if (Xuat-MatKhauWifi $thuMucBackup) { $chuoiWifi = "`n- Đã xuất kèm file Mật khẩu Wifi" } }

            $chuoiBoQua = ""
            if ($soBoQua -gt 0) { $chuoiBoQua = "`n- Bỏ qua $soBoQua Driver bị hỏng/treo hệ thống." }

            $noiDungBat = @"
@echo off
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' ( echo Dang yeu cau quyen Quan tri vien ^(Admin^)... & goto UACPrompt ) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
color 0A
title CONG CU PHUC HOI DRIVER TU DONG - VIETTOOLBOX
echo ============================================================
echo        TIEN TRINH PHUC HOI DRIVER TU DONG (1-CLICK)
echo        UU TIEN CHAY DRIVER MANG DE CO INTERNET TRUOC
echo ============================================================
echo.
if exist "%~dp01_Driver_Mang" (
    echo [1/2] DANG NAP DRIVER MANG ^(LAN/WIFI^)... Vui long cho!
    pnputil.exe /add-driver "%~dp01_Driver_Mang\*.inf" /subdirs /install
    echo.
)
if exist "%~dp02_Driver_Khac" (
    echo [2/2] DANG NAP CAC DRIVER CON LAI ^(VGA, SOUND, CHIPSET^)...
    pnputil.exe /add-driver "%~dp02_Driver_Khac\*.inf" /subdirs /install
    echo.
)
echo ============================================================
echo   HOAN TAT! XIN VUI LONG KHOI DONG LAI MAY TINH!
echo ============================================================
pause
"@
            $noiDungBat | Out-File -LiteralPath "$thuMucBackup\[CHAY_DE_PHUC_HOI_DRIVER].bat" -Encoding OEM

            $nhanTrangThai.Text = "✅ Sao lưu hoàn tất!"
            $nhanTrangThai.Foreground = "#10B981"
            [System.Windows.MessageBox]::Show($CuaSo, "Tuyệt vời! Sao lưu xong.`n- Thành công: $thanhCong/$tongSo Driver.$chuoiWifi$chuoiBoQua`n`nDữ liệu nằm tại: $thuMucBackup", "Hoàn tất", 0, 64)
            Invoke-Item $thuMucBackup
        }
        CapNhat-TrangThaiChay $false
    }
})

# 4. HÀM PHỤC HỒI DRIVER
$nutPhucHoi.Add_Click({
    $hopThoaiTim = New-Object System.Windows.Forms.FolderBrowserDialog
    $hopThoaiTim.Description = "CHỌN THƯ MỤC CHỨA BẢN BACKUP DRIVER ĐỂ PHỤC HỒI"
    if ($hopThoaiTim.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        
        $hoiXacNhan = [System.Windows.MessageBox]::Show($CuaSo, "Bạn có chắc muốn phục hồi toàn bộ Driver trong thư mục này không?", "Xác nhận cài đặt", 4, 32)
        if ($hoiXacNhan -eq "Yes") {
            CapNhat-TrangThaiChay $true
            $nhanTrangThai.Text = "⏳ Đang tiêm (Inject) Driver vào hệ thống... Đừng bấm Dừng nếu không thật sự cần thiết!"
            $nhanTrangThai.Foreground = "#F59E0B"

            try {
                $duongDanNguon = $hopThoaiTim.SelectedPath
                $tienTrinhPnp = Start-Process -FilePath "pnputil.exe" -ArgumentList "/add-driver `"$duongDanNguon\*.inf`" /subdirs /install" -WindowStyle Hidden -PassThru
                
                while (-not $tienTrinhPnp.HasExited) {
                    $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
                    if ($global:yeuCauDung) { 
                        Start-Process "taskkill.exe" -ArgumentList "/F /T /PID $($tienTrinhPnp.Id)" -WindowStyle Hidden -Wait
                        break 
                    }
                    Start-Sleep -Milliseconds 100
                }
                
                if ($global:yeuCauDung) {
                    $nhanTrangThai.Text = "⛔ Đã ép dừng quá trình nạp Driver ngang xương!"
                    $nhanTrangThai.Foreground = "#EF4444"
                    [System.Windows.MessageBox]::Show($CuaSo, "Đã hủy cài đặt Driver giữa chừng!", "Đã hủy", 0, 48)
                } else {
                    $nhanTrangThai.Text = "✅ Phục hồi hoàn tất. Hãy Restart lại máy tính."
                    $nhanTrangThai.Foreground = "#10B981"
                    [System.Windows.MessageBox]::Show($CuaSo, "Đã nạp xong Driver! Bạn nên khởi động lại máy để hệ thống nhận diện tốt nhất.", "Xong", 0, 64)
                }
            } catch {
                [System.Windows.MessageBox]::Show($CuaSo, "Có lỗi xảy ra khi nạp Driver!", "Lỗi", 0, 16)
            } finally { CapNhat-TrangThaiChay $false }
        }
    }
})

$CuaSo.ShowDialog() | Out-Null