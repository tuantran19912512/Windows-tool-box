# ==============================================================================
# Tên công cụ: VIETTOOLBOX - XÓA FILE CỨNG ĐẦU (FORCE DELETE)
# Tác giả: Kỹ Thuật Viên
# Chức năng: Chiếm quyền và ép buộc xóa các file/folder không cho xóa thông thường
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA QUYỀN QUẢN TRỊ ---
$laQuanTri = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($laQuanTri -eq $false) { 
    [System.Windows.MessageBox]::Show("Bạn phải chạy Script này bằng quyền Administrator!", "Thiếu quyền", 0, 48)
    exit 
}

# --- GIAO DIỆN XAML WPF ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Force Deleter" Width="550" Height="420" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" Opacity="0">
    
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.3"/></Storyboard></BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Border CornerRadius="15" BorderBrush="#451a1a" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="50" VerticalAlignment="Top" Background="#2d0a0a" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="🔥 TIÊU DIỆT FILE/FOLDER CỨNG ĐẦU" Foreground="#F87171" FontWeight="Bold" FontSize="15" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDong" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#F87171" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>

            <StackPanel Margin="30,70,30,20">
                <TextBlock Text="CHỌN FILE HOẶC THƯ MỤC CẦN XÓA:" Foreground="#94A3B8" FontSize="13" Margin="0,0,0,5"/>
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtDuongDan" Grid.Column="0" Height="30" VerticalContentAlignment="Center" Background="#1E293B" Foreground="White" BorderBrush="#334155" Padding="5,0"/>
                    <Button Name="NutChonFile" Grid.Column="1" Content="📄 File" Width="55" Margin="5,0,0,0" Background="#334155" Foreground="White" Cursor="Hand"/>
                    <Button Name="NutChonFolder" Grid.Column="2" Content="📁 Thư mục" Width="65" Margin="5,0,0,0" Background="#334155" Foreground="White" Cursor="Hand"/>
                </Grid>

                <Border Background="#1a0a0a" CornerRadius="8" Padding="15" Margin="0,0,0,20">
                    <TextBlock Foreground="#FCA5A5" FontSize="13" TextWrapping="Wrap" LineHeight="20">
                        <Run Text="⚠️ CẢNH BÁO:" FontWeight="Bold"/> Dữ liệu sau khi xóa bằng công cụ này sẽ <Run Text="BIẾN MẤT VĨNH VIỄN" FontWeight="Bold" Foreground="#EF4444"/> và không nằm trong thùng rác. Hãy kiểm tra kỹ đường dẫn trước khi bấm nút!
                    </TextBlock>
                </Border>

                <Button Name="NutXoa" Content="💀 XÓA VĨNH VIỄN NGAY LẬP TỨC" Height="60" Background="#B91C1C" Foreground="White" FontWeight="Bold" FontSize="16" BorderThickness="0" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
                
                <TextBlock Name="TxtLog" Text="Sẵn sàng thực thi..." Foreground="#94A3B8" FontSize="12" HorizontalAlignment="Center" Margin="0,15,0,0" FontStyle="Italic"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))
$txtDuongDan = $CuaSo.FindName("TxtDuongDan"); $txtLog = $CuaSo.FindName("TxtLog")
$nutChonFile = $CuaSo.FindName("NutChonFile"); $nutChonFolder = $CuaSo.FindName("NutChonFolder")
$nutXoa = $CuaSo.FindName("NutXoa"); $nutDong = $CuaSo.FindName("NutDong")

$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDong.Add_Click({ $CuaSo.Close() })

# --- CHỌN FILE ---
$nutChonFile.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Chọn file cần xóa"
    if ($dialog.ShowDialog() -eq "OK") { $txtDuongDan.Text = $dialog.FileName }
})

# --- CHỌN THƯ MỤC ---
$nutChonFolder.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") { $txtDuongDan.Text = $dialog.SelectedPath }
})

# --- HÀM XÓA CƯỠNG BỨC ---
$nutXoa.Add_Click({
    $path = $txtDuongDan.Text
    if ([string]::IsNullOrWhiteSpace($path) -or !(Test-Path $path)) {
        [System.Windows.MessageBox]::Show("Vui lòng chọn đường dẫn hợp lệ!", "Lỗi", 0, 48)
        return
    }

    $confirm = [System.Windows.MessageBox]::Show("Bạn có CHẮC CHẮN muốn xóa vĩnh viễn mục này không? Thao tác này không thể hoàn tác!", "Xác nhận xóa", 4, 32)
    if ($confirm -ne "Yes") { return }

    $nutXoa.IsEnabled = $false
    $txtLog.Text = "⏳ Đang thực hiện quy trình xóa cưỡng bức..."
    $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)

    try {
        # Bước 1: Chiếm quyền Ownership
        takeown /f "$path" /r /d y | Out-Null
        
        # Bước 2: Cấp Full Control cho Administrators
        icacls "$path" /grant administrators:F /t /q /c | Out-Null

        # Bước 3: Xóa vĩnh viễn (Sử dụng Remove-Item với -Recurse -Force)
        if (Test-Path -Path $path -PathType Container) {
            # Nếu là thư mục: Dùng lệnh RD của CMD để xóa sạch kể cả file ẩn/hệ thống
            cmd /c "rd /s /q `"$path`""
        } else {
            # Nếu là file: Dùng lệnh DEL của CMD để ép xóa
            cmd /c "del /f /q /a `"$path`""
        }

        if (!(Test-Path $path)) {
            $txtLog.Text = "✅ Đã tiêu diệt thành công!"
            [System.Windows.MessageBox]::Show("Mục đã được xóa sạch khỏi hệ thống.", "Hoàn tất", 0, 64)
            $txtDuongDan.Text = ""
        } else {
            $txtLog.Text = "❌ Không thể xóa! Có thể file đang bị một ứng dụng khác chiếm dụng (In use)."
            [System.Windows.MessageBox]::Show("Vẫn không xóa được. Bạn hãy thử tắt các ứng dụng đang chạy ngầm hoặc khởi động lại máy rồi thử lại.", "Thông báo", 0, 48)
        }
    } catch {
        $txtLog.Text = "❌ Có lỗi xảy ra trong quá trình xóa!"
    } finally {
        $nutXoa.IsEnabled = $true
    }
})

$CuaSo.ShowDialog() | Out-Null