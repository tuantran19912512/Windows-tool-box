# ==============================================================================
# Tên công cụ: VIETTOOLBOX - TRUY CẬP BIOS NHANH
# Tác giả: Kỹ Thuật Viên
# Chức năng: Tự động khởi động lại và nhảy thẳng vào màn hình cấu hình BIOS/UEFI
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA QUYỀN QUẢN TRỊ ---
$laQuanTri = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($laQuanTri -eq $false) { 
    [System.Windows.MessageBox]::Show("Bạn cần chạy bằng quyền Administrator để thực hiện lệnh khởi động hệ thống!", "Thiếu quyền", 0, 48)
    exit 
}

# --- GIAO DIỆN XAML WPF ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Truy Cap BIOS" Width="500" Height="350" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" Opacity="0">
    
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.3"/></Storyboard></BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="45" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="⚡ KHỞI ĐỘNG VÀO BIOS NHANH" Foreground="#38BDF8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDongCuaSo" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="15" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>
            
            <StackPanel Margin="30,70,30,20">
                <TextBlock Text="CẢNH BÁO HỆ THỐNG" Foreground="#F59E0B" FontWeight="Bold" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                
                <TextBlock Text="Máy tính sẽ KHỞI ĐỘNG LẠI ngay lập tức và tự động truy cập vào màn hình cài đặt BIOS/UEFI. Hãy lưu lại mọi công việc đang dang dở!" 
                           Foreground="#E2E8F0" FontSize="14" TextWrapping="Wrap" TextAlignment="Center" Margin="0,0,0,25"/>

                <Button Name="NutXacNhan" Content="🔄 KHỞI ĐỘNG LẠI VÀO BIOS" Height="55" Background="#F43F5E" Foreground="White" FontWeight="Bold" FontSize="15" BorderThickness="0" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
                
                <TextBlock Name="NhanTrangThai" Text="Lưu ý: Chỉ hỗ trợ máy chạy chuẩn UEFI" Foreground="#64748B" FontSize="12" HorizontalAlignment="Center" Margin="0,15,0,0"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))
$nutDongCuaSo = $CuaSo.FindName("NutDongCuaSo")
$nutXacNhan = $CuaSo.FindName("NutXacNhan")
$nhanTrangThai = $CuaSo.FindName("NhanTrangThai")

$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDongCuaSo.Add_Click({ $CuaSo.Close() })

# --- XỬ LÝ LỆNH REBOOT VÀO BIOS ---
$nutXacNhan.Add_Click({
    # 1. Kiểm tra xem máy có phải chuẩn UEFI không
    $moiTruongBoot = $env:firmware_type
    
    # Nếu biến môi trường không có, dùng cách kiểm tra file log hệ thống (chính xác hơn)
    if ([string]::IsNullOrEmpty($moiTruongBoot)) {
        if (Test-Path "$env:windir\Panther\setupact.log") {
            $checkUEFI = Select-String -Path "$env:windir\Panther\setupact.log" -Pattern "Detected boot environment: UEFI" -Quiet
            if ($checkUEFI) { $moiTruongBoot = "UEFI" } else { $moiTruongBoot = "Legacy" }
        }
    }

    if ($moiTruongBoot -eq "UEFI" -or $moiTruongBoot -eq "Firmware") {
        try {
            # Lệnh reboot vào Firmware (BIOS)
            shutdown /r /fw /t 0
        } catch {
            [System.Windows.MessageBox]::Show("Lỗi thực thi lệnh! Có thể phần cứng máy này không hỗ trợ lệnh truy cập Firmware từ Windows.", "Lỗi", 0, 16)
        }
    } else {
        [System.Windows.MessageBox]::Show("Máy tính này đang chạy chuẩn BIOS cũ (Legacy). Lệnh khởi động nhanh vào BIOS chỉ hoạt động trên chuẩn UEFI hiện đại. Bạn hãy khởi động lại máy và bấm phím cứng (F2, Del, F12...) theo cách truyền thống.", "Không hỗ trợ", 0, 48)
    }
})

$CuaSo.ShowDialog() | Out-Null