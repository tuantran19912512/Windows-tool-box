# ==========================================================
# VIETTOOLBOX - KHO FONT CHỮ CLOUD (PURE WPF EDITION)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8 VÀ NẠP WPF
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# --- KIỂM TRA QUYỀN ADMINISTRATOR ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    [System.Windows.MessageBox]::Show("Tuấn vui lòng Chuột phải chọn 'Run as Administrator' để có quyền copy Font vào hệ thống nhé!", "Yêu cầu quyền Quản trị", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
}

$LogicSieuThiFont = {
    # --- CẤU HÌNH ID GOOGLE DRIVE ---
    $ID_CO_BAN    = "1FvJOK41gP3Ic16I6xiv6L_R1CDcwgjZM" 
    $ID_TIEU_HOC  = "17h7c2jKVY3HPW8Qhe0Azz1uFgd4yIYcI"   # Thay ID của ông vào đây
    $ID_THIET_KE  = "16oSUuUnIstzf4-ibBtrDT-dN3dOiZ_iq"   # Thay ID của ông vào đây

    # --- GIAO DIỆN XAML PURE WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - KHO FONT CHỮ CLOUD" Width="500" Height="550"
        WindowStartupLocation="CenterScreen" Background="#F8F9FA" FontFamily="Segoe UI" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Height" Value="60"/>
            <Setter Property="Margin" Value="0,10"/>
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
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Opacity" Value="0.6"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.9"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="25">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="CHỌN BỘ FONT CẦN CÀI ĐẶT" FontSize="20" FontWeight="Bold" Foreground="#0D47A1" HorizontalAlignment="Center" Margin="0,10,0,25"/>

        <StackPanel Grid.Row="1" VerticalAlignment="Center" Margin="20,0">
            <Button Name="btnCoBan" Content="FONT CƠ BẢN (VNI, UTM...)" Background="#2196F3"/>
            <Button Name="btnTieuHoc" Content="FONT TIỂU HỌC (TẬP VIẾT)" Background="#4CAF50"/>
            <Button Name="btnThietKe" Content="FONT THIẾT KẾ (VIỆT HÓA)" Background="#FF9800"/>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,20,0,0">
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng..." FontStyle="Italic" Foreground="#666666" Margin="0,0,0,8"/>
            <ProgressBar Name="pgBar" Height="15" Background="#E0E0E0" Foreground="#0D47A1" BorderThickness="0"/>
        </StackPanel>
    </Grid>
</Window>
"@

    # --- KHỞI TẠO CỬA SỔ & ÁNH XẠ BIẾN ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $window = [Windows.Markup.XamlReader]::Load($DocXml)

    $btnCoBan = $window.FindName("btnCoBan")
    $btnTieuHoc = $window.FindName("btnTieuHoc")
    $btnThietKe = $window.FindName("btnThietKe")
    $lblStatus = $window.FindName("lblStatus")
    $pgBar = $window.FindName("pgBar")

    # --- HÀM CHỐNG ĐƠ GIAO DIỆN WPF ---
    $CapNhatGiaoDien = {
        $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        $Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }

    # --- HÀM XỬ LÝ CÀI ĐẶT ---
    function Start-FontInstall ($driveId, $categoryName) {
        if ($driveId -match "ID_CUA_BO" -or $driveId -match "Thay ID") { 
            [System.Windows.MessageBox]::Show("Tuấn ơi, ông chưa nhập ID Google Drive cho bộ $categoryName!", "Thiếu thông tin", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return 
        }

        $btnCoBan.IsEnabled = $false; $btnTieuHoc.IsEnabled = $false; $btnThietKe.IsEnabled = $false
        $tempZip = Join-Path $env:TEMP "vt_fonts_download.zip"
        $extractPath = Join-Path $env:TEMP "vt_extract_fonts"

        try {
            # Bật thanh chạy vô cực lúc tải file
            $lblStatus.Text = "Đang tải $categoryName từ Google Drive..."
            $pgBar.IsIndeterminate = $true
            &$CapNhatGiaoDien

            $url = "https://drive.google.com/uc?export=download&id=$driveId"
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
            $webClient.DownloadFile($url, $tempZip)
            
            $lblStatus.Text = "Đang giải nén bộ $categoryName..."
            &$CapNhatGiaoDien
            
            if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
            Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
            
            $fontFiles = Get-ChildItem -Path $extractPath -Recurse -Include *.ttf, *.otf
            if ($fontFiles.Count -eq 0) { throw "Không tìm thấy file .ttf hoặc .otf trong file Zip!" }
            
            # Tắt chế độ chạy vô cực, chuyển sang đếm số lượng font
            $pgBar.IsIndeterminate = $false
            $pgBar.Maximum = $fontFiles.Count
            $pgBar.Value = 0
            
            foreach ($file in $fontFiles) {
                $lblStatus.Text = "Đang cài đặt: $($file.Name)..."
                &$CapNhatGiaoDien
                
                # Copy vào thư mục Font Windows
                $targetPath = Join-Path $env:windir "Fonts\$($file.Name)"
                Copy-Item $file.FullName $targetPath -Force -ErrorAction SilentlyContinue
                
                # Đăng ký Registry để Windows nhận diện font ngay lập tức
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                $type = if ($file.Extension -eq ".otf") { "(OpenType)" } else { "(TrueType)" }
                New-ItemProperty -Path $regPath -Name "$($file.BaseName) $type" -Value $file.Name -PropertyType String -Force | Out-Null
                
                $pgBar.Value++
            }

            # Dọn dẹp rác cài đặt
            if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
            if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
            
            [System.Windows.MessageBox]::Show("Tuyệt vời! Đã cài xong bộ $categoryName.", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            $lblStatus.Text = "Hoàn tất cài đặt bộ $categoryName."
        } catch {
            [System.Windows.MessageBox]::Show("Lỗi: " + $_.Exception.Message, "Lỗi cài đặt", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            $lblStatus.Text = "Lỗi trong quá trình cài đặt."
            $pgBar.IsIndeterminate = $false
        }
        
        $btnCoBan.IsEnabled = $true; $btnTieuHoc.IsEnabled = $true; $btnThietKe.IsEnabled = $true; $pgBar.Value = 0
    }

    # --- SỰ KIỆN NÚT BẤM ---
    $btnCoBan.Add_Click({ Start-FontInstall $ID_CO_BAN "Font Cơ Bản" })
    $btnTieuHoc.Add_Click({ Start-FontInstall $ID_TIEU_HOC "Font Tiểu Học" })
    $btnThietKe.Add_Click({ Start-FontInstall $ID_THIET_KE "Font Thiết Kế" })

    $window.ShowDialog() | Out-Null
}

&$LogicSieuThiFont