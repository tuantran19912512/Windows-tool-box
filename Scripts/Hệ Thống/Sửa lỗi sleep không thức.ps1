# ==============================================================================
# Tên công cụ: VIETTOOLBOX - WAKE UP MASTER (V24.27)
# Tác giả: Kỹ Thuật Viên
# Chức năng: Fix lỗi đen màn hình sau khi Sleep, không nhận chuột phím để thức dậy
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA QUYỀN QUẢN TRỊ ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 
    [System.Windows.MessageBox]::Show("Sếp phải chạy bằng Administrator mới can thiệp được hệ thống nguồn!", "Thiếu quyền", 0, 48); exit 
}

# --- GIAO DIỆN XAML ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Wake Up Master" Width="500" Height="480" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="50" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="🌙 FIX LỖI SLEEP KHÔNG TỈNH (WAKE UP)" Foreground="#38BDF8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDong" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>

            <StackPanel Margin="30,70,30,20">
                <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                    <TextBlock TextWrapping="Wrap" Foreground="#E2E8F0" FontSize="12" LineHeight="18">
                        <Run Text="NGUYÊN NHÂN:" FontWeight="Bold" Foreground="#38BDF8"/> 
                        Do Windows ngắt điện các thiết bị ngoại vi hoặc lỗi nạp Driver từ Fast Startup. Script sẽ tắt Fast Startup, ngăn ngắt điện USB và PCI Express.
                    </TextBlock>
                </Border>

                <Button Name="NutFix" Content="🚀 FIX LỖI SLEEP (ULTIMATE FIX)" Height="60" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="16" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>

                <Button Name="NutRestore" Content="♻️ BẬT LẠI KHỞI ĐỘNG NHANH" Height="40" Background="#334155" Foreground="#94A3B8" FontSize="12" Cursor="Hand" Margin="0,15,0,0">
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

# --- HÀM THỰC THI FIX ---
$nutFix.Add_Click({
    try {
        $txtLog.Text = "⏳ Đang thực thi các bước bảo trì..."
        
        # 1. Tắt Fast Startup (Thằng này là trùm gây lỗi Sleep/Hibernate)
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0

        # 2. Tắt USB Selective Suspend (Ngăn ngắt điện chuột/phím)
        powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 4835d277-5b30-4449-b69a-7a565d702319 0
        powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 4835d277-5b30-4449-b69a-7a565d702319 0

        # 3. PCI Express Link State Power Management -> Off (Ngăn ngắt điện card màn hình)
        powercfg /setacvalueindex SCHEME_CURRENT ee12f753-ad31-4c63-9943-88392ba05630 ee12f753-ad31-4c63-9943-88392ba05630 0
        powercfg /setdcvalueindex SCHEME_CURRENT ee12f753-ad31-4c63-9943-88392ba05630 ee12f753-ad31-4c63-9943-88392ba05630 0

        # 4. Allow Wake Timers -> Enable
        powercfg /setacvalueindex SCHEME_CURRENT 238c9ce8-0023-4556-991d-70753c306d96 bd3b7180-6c1c-4235-8515-0447447d0801 1
        powercfg /setdcvalueindex SCHEME_CURRENT 238c9ce8-0023-4556-991d-70753c306d96 bd3b7180-6c1c-4235-8515-0447447d0801 1

        # Áp dụng cấu hình
        powercfg /setactive SCHEME_CURRENT

        $txtLog.Text = "✅ Đã Fix xong! Sếp cho khởi động lại máy nhé."
        [System.Windows.MessageBox]::Show("Đã tắt Fast Startup và các chế độ ngắt điện linh kiện. Sếp hãy Restart máy để hoàn tất!", "Thành công", 0, 64)
    } catch {
        $txtLog.Text = "❌ Lỗi thực thi Registry!"
    }
})

$nutRestore.Add_Click({
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1
    $txtLog.Text = "♻️ Đã bật lại Fast Startup."
})

$CuaSo.ShowDialog() | Out-Null