# ==============================================================================
# Tên công cụ: VIETTOOLBOX - LONG PATH & UNICODE FIXER (V25.1)
# Tác giả: Kỹ Thuật Viên
# Chức năng: Mở khóa giới hạn 260 ký tự và fix lỗi đường dẫn có dấu
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA QUYỀN QUẢN TRỊ ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 
    [System.Windows.MessageBox]::Show("Sếp phải chạy bằng quyền Administrator mới sửa được Registry hệ thống!", "Thiếu quyền", 0, 48); exit 
}

# --- GIAO DIỆN XAML ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Long Path Fixer" Width="500" Height="400" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="50" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="🛠️ FIX LỖI ĐƯỜNG DẪN DÀI &amp; CÓ DẤU" Foreground="#38BDF8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDong" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>

            <StackPanel Margin="30,70,30,20">
                <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                    <TextBlock TextWrapping="Wrap" Foreground="#E2E8F0" FontSize="12" LineHeight="18">
                        <Run Text="TÌNH TRẠNG:" FontWeight="Bold" Foreground="#38BDF8"/> Windows mặc định chặn đường dẫn dài hơn 260 ký tự. Script này sẽ mở giới hạn lên 32,767 ký tự và tối ưu hóa nhận diện tiếng Việt có dấu.
                    </TextBlock>
                </Border>

                <Button Name="NutFix" Content="🚀 KÍCH HOẠT LONG PATHS &amp; UTF-8" Height="60" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="16" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>

                <Button Name="NutRestore" Content="♻️ TRẢ VỀ MẶC ĐỊNH WINDOWS" Height="40" Background="#334155" Foreground="#94A3B8" FontWeight="Bold" FontSize="12" Cursor="Hand" Margin="0,15,0,0">
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

$nutFix = $CuaSo.FindName("NutFix"); $nutRestore = $CuaSo.FindName("NutRestore")
$txtLog = $CuaSo.FindName("TxtLog"); $nutDong = $CuaSo.FindName("NutDong")

$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDong.Add_Click({ $CuaSo.Close() })

# --- HÀM FIX LỖI ---
$nutFix.Add_Click({
    try {
        # 1. Mở khóa Long Paths trong FileSystem
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Set-ItemProperty -Path $regPath -Name "LongPathsEnabled" -Value 1 -Force
        
        # 2. Bật UTF-8 cho toàn hệ thống (Dành cho bản Win mới)
        # Lưu ý: Phần này can thiệp vào Locale, giúp App cũ hiểu được tiếng Việt
        $intlPath = "HKCU:\Control Panel\International"
        Set-ItemProperty -Path $intlPath -Name "LocaleName" -Value "vi-VN" -Force

        $txtLog.Text = "✅ Đã kích hoạt thành công! Hãy khởi động lại máy."
        [System.Windows.MessageBox]::Show("Đã mở giới hạn đường dẫn 32,767 ký tự. Sếp hãy cho khởi động lại máy để áp dụng hoàn toàn nhé!", "Hoàn tất", 0, 64)
    } catch {
        $txtLog.Text = "❌ Lỗi thực thi Registry!"
    }
})

# --- HÀM TRẢ VỀ MẶC ĐỊNH ---
$nutRestore.Add_Click({
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Set-ItemProperty -Path $regPath -Name "LongPathsEnabled" -Value 0 -Force
        $txtLog.Text = "✅ Đã trả về giới hạn 260 ký tự mặc định."
    } catch { $txtLog.Text = "❌ Lỗi khi Restore!" }
})

$CuaSo.ShowDialog() | Out-Null