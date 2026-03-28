# ==============================================================================
# Tên công cụ: VIETTOOLBOX - ĐẶC TRỊ LỖI KÉO THẢ ẢNH PHOTOSHOP
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Chức năng: Fix lỗi không kéo được file từ Explorer vào PTS / AI / Corel
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA QUYỀN QUẢN TRỊ ---
$laQuanTri = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($laQuanTri -eq $false) { 
    [System.Windows.MessageBox]::Show("Tuấn ơi, chuột phải chọn Run as Administrator nhé!", "Thiếu quyền", 0, 48)
    exit 
}

# --- GIAO DIỆN XAML WPF ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Fix Drag &amp; Drop" Width="600" Height="400" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" Opacity="0">
    
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.3"/></Storyboard></BeginStoryboard>
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
                <EventTrigger RoutedEvent="MouseEnter"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1.03" Duration="0:0:0.1"/><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1.03" Duration="0:0:0.1"/></Storyboard></BeginStoryboard></EventTrigger>
                <EventTrigger RoutedEvent="MouseLeave"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1" Duration="0:0:0.1"/><DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1" Duration="0:0:0.1"/></Storyboard></BeginStoryboard></EventTrigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Border Name="KhungVien" CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="45" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="🛠️ FIX LỖI KÉO THẢ ẢNH - VIETTOOLBOX" Foreground="#38BDF8" FontWeight="Bold" FontSize="15" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDongCuaSo" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="15" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>
            
            <StackPanel Margin="30,70,30,20">
                <TextBlock Text="CÔNG CỤ XỬ LÝ XUNG ĐỘT QUYỀN HẠN (UAC)" Foreground="#E2E8F0" FontWeight="Bold" FontSize="16" HorizontalAlignment="Center" Margin="0,0,0,15"/>
                
                <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,25">
                    <TextBlock Foreground="#94A3B8" FontSize="14" TextWrapping="Wrap" LineHeight="22">
                        <Run Text="Hiện tượng:" Foreground="#F59E0B" FontWeight="Bold"/> Trỏ chuột hiện dấu tròn gạch chéo (🚫) khi kéo ảnh vào Photoshop, Illustrator, Corel, v.v...
                        <LineBreak/><LineBreak/>
                        <Run Text="Lý do:" Foreground="#3B82F6" FontWeight="Bold"/> Phần mềm đồ họa đang chạy dưới quyền Admin, trong khi thư mục (Explorer) chạy ở quyền thường. Windows đã khóa chức năng kéo thả để bảo mật.
                    </TextBlock>
                </Border>

                <TextBlock Name="NhanTrangThai" Text="Sẵn sàng tiêm mã sửa lỗi vào Registry hệ thống." Foreground="#10B981" FontSize="14" HorizontalAlignment="Center" FontWeight="Bold" Margin="0,0,0,15"/>

                <Button Name="NutSuaLoi" Content="🚀 BẤM VÀO ĐÂY ĐỂ FIX LỖI NGAY" Height="55" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="16" BorderThickness="0" Cursor="Hand" Style="{StaticResource NutChuyenDong}"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

$nutDongCuaSo = $CuaSo.FindName("NutDongCuaSo")
$nutSuaLoi = $CuaSo.FindName("NutSuaLoi")
$nhanTrangThai = $CuaSo.FindName("NhanTrangThai")

$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDongCuaSo.Add_Click({ $CuaSo.Close() })

# --- HÀM XỬ LÝ SỬA LỖI REGISTRY ---
$nutSuaLoi.Add_Click({
    $nhanTrangThai.Text = "⏳ Đang cấu hình lại hệ thống..."
    $nhanTrangThai.Foreground = "#F59E0B"
    $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)

    try {
        $duongDanReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        
        # 1. Bật lại LUA (Bắt buộc để Windows cho phép kéo thả giữa các App)
        Set-ItemProperty -Path $duongDanReg -Name "EnableLUA" -Value 1 -Type DWord -Force
        
        # 2. Bật LinkedConnections (Cho phép chia sẻ quyền giữa Admin và User)
        Set-ItemProperty -Path $duongDanReg -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force

        $nhanTrangThai.Text = "✅ Đã Fix xong! Vui lòng khởi động lại máy tính để áp dụng."
        $nhanTrangThai.Foreground = "#10B981"
        
        $hoiRestart = [System.Windows.MessageBox]::Show($CuaSo, "Đã can thiệp Registry thành công!`n`nBạn CẦN KHỞI ĐỘNG LẠI MÁY TÍNH (Restart) để Photoshop nhận diện cấu hình mới.`n`nKhởi động lại ngay bây giờ?", "Yêu cầu Restart", 4, 32)
        if ($hoiRestart -eq "Yes") {
            Restart-Computer -Force
        }
    } catch {
        $nhanTrangThai.Text = "❌ Lỗi: Không thể ghi vào Registry! Hãy chắc chắn bạn đã Run as Administrator."
        $nhanTrangThai.Foreground = "#EF4444"
    }
})

$CuaSo.ShowDialog() | Out-Null