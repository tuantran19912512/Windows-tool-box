# ==============================================================================
# Tên công cụ: GIAO DIỆN GỠ PHONG ẤN TẬP TIN (HỖ TRỢ Ổ ĐĨA ÁNH XẠ)
# Đặc tính: Hỗ trợ mạng UNC, Ổ đĩa ánh xạ, Tự động Fix lỗi "Harmful"
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# 1. KIỂM TRA QUYỀN QUẢN TRỊ
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.MessageBox]::Show("Vui lòng nhấp chuột phải vào tập tin và chọn 'Run as Administrator' để công cụ có quyền can thiệp hệ thống!", "Thiếu quyền quản trị", 0, 48)
    exit
}

# 2. XÂY DỰNG GIAO DIỆN XAML
$GiaoDienXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        Title="Cong Cu Go Phong An" Width="600" Height="410" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    
    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="2" Background="#0F172A">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="55"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Background="#1E293B">
                <Grid.Clip><RectangleGeometry Rect="0,0,600,55" RadiusX="15" RadiusY="15"/></Grid.Clip>
                <TextBlock Text="🔓 TRÌNH GỠ PHONG ẤN BẢO MẬT TẬP TIN" Foreground="#38BDF8" FontWeight="Bold" FontSize="16" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <Button Name="NutDong" Content="✕" Width="55" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="18" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <StackPanel Grid.Row="1" Margin="25">
                <TextBlock Text="Nhập đường dẫn cục bộ hoặc mạng (VD: D:\, Z:\ hoặc \\MayChu\ThuMuc):" Foreground="#E2E8F0" FontSize="14" FontWeight="SemiBold" Margin="0,0,0,10"/>
                
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="110"/>
                    </Grid.ColumnDefinitions>
                    
                    <Border Grid.Column="0" CornerRadius="6" BorderBrush="#475569" BorderThickness="1" Background="#1E293B">
                        <TextBox Name="OTimKiem" FontSize="14" VerticalContentAlignment="Center" Padding="10,0" Background="Transparent" Foreground="White" BorderThickness="0" ToolTip="Dán đường dẫn vào đây (Hỗ trợ cả ổ đĩa thường, ổ ánh xạ và đường dẫn mạng)"/>
                    </Border>
                    
                    <Button Name="NutChon" Grid.Column="1" Content="📁 Duyệt..." Height="40" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="14" BorderThickness="0" Cursor="Hand" Margin="10,0,0,0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <CheckBox Name="HopKiemAnToan" Content="🛡️ Tự động khai báo máy chủ này là mạng nội bộ an toàn (Sửa lỗi báo Harmful)" Foreground="#94A3B8" FontSize="13" Margin="0,0,0,20" IsChecked="True" ToolTip="Giúp khung Preview của Windows không chặn file từ IP/Máy chủ mạng này nữa"/>

                <Button Name="NutThucThi" Content="⚡ MỞ KHÓA TOÀN BỘ TẬP TIN" Height="50" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="16" BorderThickness="0" Cursor="Hand" Margin="0,0,0,20">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>

                <Border Background="#1E293B" CornerRadius="8" Padding="15" MinHeight="65">
                    <TextBlock Name="NhanTrangThai" Text="Trạng thái: Đang chờ lệnh..." Foreground="#94A3B8" FontSize="14" TextWrapping="Wrap" FontWeight="Medium"/>
                </Border>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# --- NẠP GIAO DIỆN ---
$BoDocTruyen = New-Object System.IO.StringReader($GiaoDienXML)
$DocXML = [System.Xml.XmlReader]::Create($BoDocTruyen)
try {
    $CuaSo = [System.Windows.Markup.XamlReader]::Load($DocXML)
} catch {
    [System.Windows.MessageBox]::Show("Lỗi phân tích giao diện XAML: $_", "Lỗi", 0, 16)
    exit
}

# --- KẾT NỐI BIẾN ---
$NutDong = $CuaSo.FindName("NutDong")
$OTimKiem = $CuaSo.FindName("OTimKiem")
$NutChon = $CuaSo.FindName("NutChon")
$HopKiemAnToan = $CuaSo.FindName("HopKiemAnToan")
$NutThucThi = $CuaSo.FindName("NutThucThi")
$NhanTrangThai = $CuaSo.FindName("NhanTrangThai")

# --- SỰ KIỆN GIAO DIỆN CƠ BẢN ---
$NutDong.Add_Click({ $CuaSo.Close() })
$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })

# --- SỰ KIỆN: NÚT DUYỆT THƯ MỤC ---
$NutChon.Add_Click({
    $HopThoai = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoai.Title = "Chọn thư mục cần gỡ phong ấn bảo mật"
    $HopThoai.ValidateNames = $false
    $HopThoai.CheckFileExists = $false
    $HopThoai.CheckPathExists = $true
    $HopThoai.FileName = "Chọn_Thư_Mục_Này" 
    
    if ($HopThoai.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $OTimKiem.Text = [System.IO.Path]::GetDirectoryName($HopThoai.FileName)
    }
})

# --- SỰ KIỆN: NÚT MỞ KHÓA TẬP TIN ---
$NutThucThi.Add_Click({
    $DuongDan = $OTimKiem.Text.Trim('"').Trim()
    
    if ([string]::IsNullOrWhiteSpace($DuongDan)) {
        $NhanTrangThai.Text = "❌ Vui lòng nhập hoặc chọn đường dẫn trước khi thực thi!"
        $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#EF4444")
        return
    }

    # BƯỚC XỬ LÝ Ổ ĐĨA ÁNH XẠ: Chuyển đổi ký tự ổ đĩa (VD: Z:\) thành đường dẫn mạng thực tế (UNC)
    $DuongDanThuc = $DuongDan
    if ($DuongDan -match "^([A-Za-z]):") {
        $KyTuO = $matches[1]
        # Đọc trực tiếp từ Registry của tài khoản hiện tại để lấy đường dẫn ánh xạ
        $ThongTinMang = Get-ItemProperty -Path "HKCU:\Network\$KyTuO" -ErrorAction SilentlyContinue
        if ($null -ne $ThongTinMang -and -not [string]::IsNullOrEmpty($ThongTinMang.RemotePath)) {
            $DuongDanThuc = $DuongDan -replace "^[A-Za-z]:", $ThongTinMang.RemotePath
        }
    }

    if (-not (Test-Path -LiteralPath $DuongDanThuc)) {
        if ($DuongDanThuc -match "^[A-Za-z]:\\") {
            $NhanTrangThai.Text = "❌ Lỗi: Không tìm thấy '$DuongDanThuc'. Hãy kiểm tra lại kết nối mạng."
        } else {
            $NhanTrangThai.Text = "❌ Lỗi: Đường dẫn mạng '$DuongDanThuc' không tồn tại hoặc không thể truy cập lúc này!"
        }
        $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#EF4444")
        return
    }

    $NhanTrangThai.Text = "⏳ Đang quét và cấu hình, vui lòng chờ..."
    $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#F59E0B")
    $NutThucThi.IsEnabled = $false
    $CuaSo.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render, [System.Action]{})

    # 1. Xử lý tự động thêm IP/Tên máy chủ vào vùng Local Intranet (Dùng đường dẫn thực UNC)
    $TrangThaiMang = ""
    if ($HopKiemAnToan.IsChecked -and $DuongDanThuc -match "^\\\\\\*([^\\]+)") {
        $TenMayChu = $matches[1]
        try {
            $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
            if (-not (Test-Path $RegPath)) {
                New-Item -Path $RegPath -Force | Out-Null
            }
            Set-ItemProperty -Path $RegPath -Name $TenMayChu -Value "1" -Type String -Force
            $TrangThaiMang = "`n🛡️ Đã cấp quyền tin cậy cho máy chủ: $TenMayChu"
        } catch {
            $TrangThaiMang = "`n⚠️ Không thể tự động thêm vùng tin cậy: $_"
        }
    }

    # 2. Thực thi gỡ phong ấn (Unblock-File) trên đường dẫn thực tế
    try {
        Get-ChildItem -LiteralPath $DuongDanThuc -Recurse -File -Force -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
        $NhanTrangThai.Text = "✅ THÀNH CÔNG: Đã gỡ phong ấn cho toàn bộ tập tin.$TrangThaiMang"
        $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#10B981")
    } catch {
        $NhanTrangThai.Text = "❌ LỖI HỆ THỐNG: $_"
        $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#EF4444")
    }

    $NutThucThi.IsEnabled = $true
})

# Hiển thị cửa sổ
$CuaSo.ShowDialog() | Out-Null