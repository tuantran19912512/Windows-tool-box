# ==============================================================================
# Tên công cụ: GIAO DIỆN GỠ PHONG ẤN TẬP TIN (PHIÊN BẢN ĐA LUỒNG - CHỐNG TREO)
# Đặc tính: Không đơ UI khi quét mạng lớn, Hỗ trợ UNC & Ổ ánh xạ, Auto-Fix Harmful
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
                        <TextBox Name="OTimKiem" FontSize="14" VerticalContentAlignment="Center" Padding="10,0" Background="Transparent" Foreground="White" BorderThickness="0" ToolTip="Dán đường dẫn vào đây (Hỗ trợ ổ đĩa thường, ổ ánh xạ và mạng UNC)"/>
                    </Border>
                    
                    <Button Name="NutChon" Grid.Column="1" Content="📁 Duyệt..." Height="40" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="14" BorderThickness="0" Cursor="Hand" Margin="10,0,0,0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <CheckBox Name="HopKiemAnToan" Content="🛡️ Tự động khai báo máy chủ này là mạng nội bộ an toàn (Sửa lỗi báo Harmful)" Foreground="#94A3B8" FontSize="13" Margin="0,0,0,20" IsChecked="True"/>

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
$CuaSo = [System.Windows.Markup.XamlReader]::Load($DocXML)

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

$NutChon.Add_Click({
    $HopThoai = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoai.Title = "Chọn thư mục"
    $HopThoai.ValidateNames = $false
    $HopThoai.CheckFileExists = $false
    $HopThoai.FileName = "Chọn_Thư_Mục_Này" 
    if ($HopThoai.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $OTimKiem.Text = [System.IO.Path]::GetDirectoryName($HopThoai.FileName)
    }
})

# --- SỰ KIỆN: NÚT MỞ KHÓA (ĐÃ TÍCH HỢP ĐA LUỒNG) ---
$NutThucThi.Add_Click({
    $DuongDan = $OTimKiem.Text.Trim('"').Trim()
    
    if ([string]::IsNullOrWhiteSpace($DuongDan)) {
        $NhanTrangThai.Text = "❌ Vui lòng nhập đường dẫn!"
        $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#EF4444")
        return
    }

    # Chuyển đổi ổ ánh xạ (Z:\) thành mạng thực (UNC)
    $DuongDanThuc = $DuongDan
    if ($DuongDan -match "^([A-Za-z]):") {
        $KyTuO = $matches[1]
        $ThongTinMang = Get-ItemProperty -Path "HKCU:\Network\$KyTuO" -ErrorAction SilentlyContinue
        if ($null -ne $ThongTinMang -and -not [string]::IsNullOrEmpty($ThongTinMang.RemotePath)) {
            $DuongDanThuc = $DuongDan -replace "^[A-Za-z]:", $ThongTinMang.RemotePath
        }
    }

    if (-not (Test-Path -LiteralPath $DuongDanThuc)) {
        $NhanTrangThai.Text = "❌ Lỗi: Không thể truy cập '$DuongDanThuc'."
        $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#EF4444")
        return
    }

    # CẬP NHẬT GIAO DIỆN TRƯỚC KHI CHẠY NGẦM
    $NutThucThi.IsEnabled = $false
    $NhanTrangThai.Text = "⏳ Đang khởi động bộ quét ngầm..."
    $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#F59E0B")

    # Thu thập dữ liệu để đẩy xuống luồng ngầm
    $CapQuyenMang = $HopKiemAnToan.IsChecked
    $TenMayChu = $null
    if ($CapQuyenMang -and $DuongDanThuc -match "^\\\\\\*([^\\]+)") {
        $TenMayChu = $matches[1]
    }

    # TẠO LUỒNG CHẠY NGẦM (RUNSPACE) ĐỂ KHÔNG LÀM TREO GIAO DIỆN
    $KhongGianChay = [runspacefactory]::CreateRunspace()
    $KhongGianChay.ThreadOptions = "ReuseThread"
    $KhongGianChay.Open()
    $TienTrinhPS = [powershell]::Create()
    $TienTrinhPS.Runspace = $KhongGianChay

    [void]$TienTrinhPS.AddScript({
        param($DuongDanQuet, $MayChu)
        try {
            $TinNhan = ""
            # Cấu hình Local Intranet
            if ($MayChu) {
                $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
                if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
                Set-ItemProperty -Path $RegPath -Name $MayChu -Value "1" -Type String -Force
                $TinNhan = "`n🛡️ Đã cấp quyền tin cậy mạng nội bộ cho: $MayChu"
            }
            # Lệnh quét ngầm tốn thời gian
            Get-ChildItem -LiteralPath $DuongDanQuet -Recurse -File -Force -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
            return "THANHCONG|$TinNhan"
        } catch {
            return "LOI|$_"
        }
    }).AddArgument($DuongDanThuc).AddArgument($TenMayChu)

    # Bắt đầu thực thi ngầm
    $KqChayNgam = $TienTrinhPS.BeginInvoke()

    # BỘ HẸN GIỜ KIỂM TRA TRẠNG THÁI (Đồng bộ với giao diện)
    $BoDem = New-Object System.Windows.Threading.DispatcherTimer
    $BoDem.Interval = [TimeSpan]::FromMilliseconds(500)
    $NhipHieuUng = 0

    $BoDem.Add_Tick({
        if ($KqChayNgam.IsCompleted) {
            # Khi luồng ngầm hoàn tất
            $BoDem.Stop()
            $KetQuaTraVe = $TienTrinhPS.EndInvoke($KqChayNgam)
            
            # Dọn dẹp bộ nhớ
            $TienTrinhPS.Dispose()
            $KhongGianChay.Close()
            $KhongGianChay.Dispose()

            # Phân tách kết quả
            $TachKQ = $KetQuaTraVe -split "\|", 2
            if ($TachKQ[0] -eq "THANHCONG") {
                $NhanTrangThai.Text = "✅ ĐÃ XONG: Hoàn tất quét và mở khóa tập tin." + $TachKQ[1]
                $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#10B981")
            } else {
                $NhanTrangThai.Text = "❌ CÓ LỖI: " + $TachKQ[1]
                $NhanTrangThai.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#EF4444")
            }
            $NutThucThi.IsEnabled = $true
        } else {
            # Hiệu ứng đang chạy để báo hiệu UI không chết
            $NhipHieuUng++
            $Cham = "." * ($NhipHieuUng % 4)
            $NhanTrangThai.Text = "⏳ Đang quét cấu trúc mạng ngầm (Đừng tắt cửa sổ)$Cham"
        }
    })
    $BoDem.Start()
})

# Hiển thị cửa sổ
$CuaSo.ShowDialog() | Out-Null