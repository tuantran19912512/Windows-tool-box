# ==============================================================================
# Tên công cụ: VIETTOOLBOX - BRIGHTNESS FIXER (V26.1)
# Tác giả: Kỹ Thuật Viên
# Chức năng: Tắt Adaptive Brightness và các chế độ tự động thay đổi độ sáng
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA QUYỀN QUẢN TRỊ ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 
    [System.Windows.MessageBox]::Show("Sếp phải chạy bằng Administrator mới can thiệp được vào Power Plan!", "Thiếu quyền", 0, 48); exit 
}

# --- GIAO DIỆN XAML ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Brightness Fixer" Width="500" Height="450" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="50" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="🔆 FIX LỖI TỰ ĐỘNG TĂNG GIẢM ĐỘ SÁNG" Foreground="#38BDF8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDong" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>

            <StackPanel Margin="30,70,30,20">
                <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                    <TextBlock TextWrapping="Wrap" Foreground="#E2E8F0" FontSize="12" LineHeight="18">
                        <Run Text="CHỨC NĂNG:" FontWeight="Bold" Foreground="#38BDF8"/> 
                        Tắt Adaptive Brightness trong Power Plan, vô hiệu hóa dịch vụ Sensor (Cảm biến ánh sáng) và cấu hình Registry để ngăn màn hình tự tối khi dùng Pin.
                    </TextBlock>
                </Border>

                <Button Name="NutFix" Content="🚀 FIX LỖI ĐỘ SÁNG (STABLE)" Height="60" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="16" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>

                <Button Name="NutCheckIntel" Content="🔍 KIỂM TRA CẤU HÌNH INTEL/AMD" Height="40" Background="#334155" Foreground="White" FontSize="12" Cursor="Hand" Margin="0,15,0,0">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
                
                <TextBlock Name="TxtLog" Text="Trạng thái: Sẵn sàng." Foreground="#38BDF8" FontSize="11" HorizontalAlignment="Center" Margin="0,15,0,0" FontStyle="Italic"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($reader)

$nutFix = $CuaSo.FindName("NutFix"); $nutCheckIntel = $CuaSo.FindName("NutCheckIntel")
$txtLog = $CuaSo.FindName("TxtLog"); $nutDong = $CuaSo.FindName("NutDong")

$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDong.Add_Click({ $CuaSo.Close() })

# --- HÀM THỰC THI FIX ---
$nutFix.Add_Click({
    try {
        $txtLog.Text = "⏳ Đang xử lý Power Plan..."
        
        # 1. Tắt Adaptive Brightness cho tất cả Power Schemes (Cả dùng Pin và Cắm sạc)
        # GUID: fbd9aa66-9553-4097-ba44-ed6e9d65eab8 là Adaptive Brightness
        powercfg /setacvalueindex SCHEME_CURRENT sub_video fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0
        powercfg /setdcvalueindex SCHEME_CURRENT sub_video fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0
        
        # 2. Tắt tính năng tự giảm độ sáng để tiết kiệm Pin (Dim display)
        powercfg /setacvalueindex SCHEME_CURRENT sub_video 17aaa29b-8543-4815-a43e-ad14aa573bc3 0
        powercfg /setdcvalueindex SCHEME_CURRENT sub_video 17aaa29b-8543-4815-a43e-ad14aa573bc3 0
        
        # Áp dụng thay đổi ngay lập tức
        powercfg /setactive SCHEME_CURRENT

        # 3. Vô hiệu hóa Sensor Service (Cảm biến ánh sáng nếu có)
        Stop-Service -Name "SensorService" -ErrorAction SilentlyContinue
        Set-Service -Name "SensorService" -StartupType Disabled -ErrorAction SilentlyContinue

        # 4. Registry Fix cho Intel Graphics (Vô hiệu hóa Display Power Saving Technology)
        $intelPath = "HKLM:\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
        if (Test-Path $intelPath) {
            Set-ItemProperty -Path $intelPath -Name "FeatureTestControl" -Value 0x9240 -ErrorAction SilentlyContinue
        }

        $txtLog.Text = "✅ Đã Fix xong! Độ sáng sẽ không tự nhảy nữa."
        [System.Windows.MessageBox]::Show("Đã tắt Adaptive Brightness và Sensor. Nếu vẫn còn bị, sếp hãy kiểm tra trong Intel/AMD Graphics Control Panel nhé!", "Hoàn tất", 0, 64)
    } catch {
        $txtLog.Text = "❌ Có lỗi xảy ra khi thực thi!"
    }
})

# --- HÀM KIỂM TRA CARD ĐỒ HỌA ---
$nutCheckIntel.Add_Click({
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Caption
    $txtLog.Text = "💻 GPU: $gpu"
    [System.Windows.MessageBox]::Show("Máy đang dùng: $gpu`n`nSếp lưu ý: Nếu là Intel, hãy tắt 'Display Power Saving' trong App Intel Graphics Command Center.", "Thông tin GPU", 0, 64)
})

$CuaSo.ShowDialog() | Out-Null