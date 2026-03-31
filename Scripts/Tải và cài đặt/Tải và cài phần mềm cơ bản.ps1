# ==============================================================================
# Tên công cụ: VIETTOOLBOX - TỰ ĐỘNG CÀI ĐẶT PHẦN MỀM (WINGET)
# Đặc tính: Chuột phải copy lỗi, Hiện Console Winget, Chống treo, Cắt khoảng trắng, HIỆN ICON
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- MÃ NHÚNG C# ĐỂ TẠM DỪNG / TIẾP TỤC TIẾN TRÌNH ---
$MaCSharp = @"
using System;
using System.Runtime.InteropServices;
public static class QuanLyTienTrinh {
    [DllImport("ntdll.dll")]
    public static extern int NtSuspendProcess(IntPtr processHandle);
    [DllImport("ntdll.dll")]
    public static extern int NtResumeProcess(IntPtr processHandle);
}
"@
Add-Type -TypeDefinition $MaCSharp

# 1. KIỂM TRA QUYỀN QUẢN TRỊ
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.MessageBox]::Show("Vui lòng nhấp chuột phải và chọn 'Run as Administrator' để công cụ có quyền cài đặt!", "Thiếu quyền quản trị", 0, 48)
    exit
}

# --- ĐƯỜNG DẪN TẢI DANH SÁCH TỪ GITHUB ---
$Global:DuongDanCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"

# 2. GIAO DIỆN XAML WPF (ĐÃ THÊM CỘT BIỂU TƯỢNG)
$GiaoDienXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Winget" Width="950" Height="750" MinWidth="800" MinHeight="600" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    
    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="2" Background="#0F172A">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="60"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Background="#1E293B">
                <Grid.Clip><RectangleGeometry Rect="0,0,3000,60" RadiusX="15" RadiusY="15"/></Grid.Clip>
                <TextBlock Text="🚀 VIETTOOLBOX - TRÌNH CÀI ĐẶT PHẦN MỀM TỰ ĐỘNG" Foreground="#38BDF8" FontWeight="Bold" FontSize="18" VerticalAlignment="Center" Margin="25,0,0,0"/>
                <Button Name="NutDong" Content="✕" Width="60" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="20" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <Grid Grid.Row="1" Margin="25,15,25,25">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/> 
                    <RowDefinition Height="*"/>    
                    <RowDefinition Height="Auto"/> 
                    <RowDefinition Height="Auto"/> 
                </Grid.RowDefinitions>

                <Grid Grid.Row="0" Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <Border Grid.Column="0" Background="#1E293B" CornerRadius="8" Padding="10" Margin="0,0,10,0">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="Trạng thái Winget: " Foreground="#94A3B8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                            <TextBlock Name="NhanTrangThaiWinget" Text="Đang khởi tạo..." Foreground="#F59E0B" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Border>
                    
                    <Button Name="NutTaiDanhSach" Grid.Column="1" Content="📥 TẢI DANH SÁCH (GITHUB)" Width="220" Height="40" Background="#3B82F6" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <Border Grid.Row="1" Background="#1E293B" CornerRadius="10" Padding="10" Margin="0,0,0,15">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        
                        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                            <Button Name="NutChonTatCa" Content="☑ Chọn Tất Cả" Padding="10,5" Background="#475569" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0"/>
                            <Button Name="NutBoChon" Content="☐ Bỏ Chọn Hết" Padding="10,5" Background="#475569" Foreground="White" BorderThickness="0" Cursor="Hand"/>
                        </StackPanel>

                        <ListView Name="BangDanhSach" Grid.Row="1" Background="Transparent" BorderThickness="0" Foreground="#E2E8F0" FontSize="14" VirtualizingStackPanel.IsVirtualizing="True" ScrollViewer.CanContentScroll="True">
                            <ListView.ContextMenu>
                                <ContextMenu>
                                    <MenuItem Name="NutSaoChep" Header="📋 Sao chép thông tin phần mềm này"/>
                                </ContextMenu>
                            </ListView.ContextMenu>
                            
                            <ListView.ItemContainerStyle>
                                <Style TargetType="ListViewItem">
                                    <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
                                    <Setter Property="Margin" Value="0,2"/>
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="ListViewItem">
                                                <Border x:Name="KhungDong" Background="Transparent" CornerRadius="4" Padding="5,2">
                                                    <GridViewRowPresenter VerticalAlignment="Center"/>
                                                </Border>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="KhungDong" Property="Background" Value="#334155"/>
                                                    </Trigger>
                                                    <Trigger Property="IsSelected" Value="True">
                                                        <Setter TargetName="KhungDong" Property="Background" Value="#0F172A"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </ListView.ItemContainerStyle>
                            <ListView.View>
                                <GridView>
                                    <GridViewColumn Header="CÀI" Width="50">
                                        <GridViewColumn.CellTemplate>
                                            <DataTemplate>
                                                <CheckBox IsChecked="{Binding IsSelected}" HorizontalAlignment="Center">
                                                    <CheckBox.LayoutTransform><ScaleTransform ScaleX="1.3" ScaleY="1.3"/></CheckBox.LayoutTransform>
                                                </CheckBox>
                                            </DataTemplate>
                                        </GridViewColumn.CellTemplate>
                                    </GridViewColumn>
                                    <GridViewColumn Header="ICON" Width="60">
                                        <GridViewColumn.CellTemplate>
                                            <DataTemplate>
                                                <Image Source="{Binding BieuTuong}" Width="24" Height="24" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality"/>
                                            </DataTemplate>
                                        </GridViewColumn.CellTemplate>
                                    </GridViewColumn>
                                    <GridViewColumn Header="TÊN PHẦN MỀM" Width="260" DisplayMemberBinding="{Binding Name}"/>
                                    <GridViewColumn Header="MÃ ID WINGET" Width="230" DisplayMemberBinding="{Binding ID}"/>
                                    <GridViewColumn Header="TRẠNG THÁI" Width="200" DisplayMemberBinding="{Binding Status}"/>
                                </GridView>
                            </ListView.View>
                        </ListView>
                    </Grid>
                </Border>

                <StackPanel Grid.Row="2" Margin="0,0,0,15">
                    <TextBlock Name="NhanTienDo" Text="Sẵn sàng. Vui lòng tải danh sách từ Github." Foreground="#38BDF8" FontWeight="Bold" Margin="0,0,0,5"/>
                    <ProgressBar Name="ThanhTienDo" Height="15" Minimum="0" Maximum="100" Value="0" Background="#334155" Foreground="#10B981" BorderThickness="0"/>
                </StackPanel>

                <Grid Grid.Row="3">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Button Name="NutCaiDat" Grid.Column="0" Content="▶ BẮT ĐẦU CÀI ĐẶT" Height="45" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="15" Margin="0,0,5,0" BorderThickness="0" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutTamDung" Grid.Column="1" Content="⏸ TẠM DỪNG" Height="45" Background="#F59E0B" Foreground="White" FontWeight="Bold" FontSize="15" Margin="5,0,5,0" BorderThickness="0" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutHuyBo" Grid.Column="2" Content="⏹ HỦY BỎ" Height="45" Background="#EF4444" Foreground="White" FontWeight="Bold" FontSize="15" Margin="5,0,0,0" BorderThickness="0" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                </Grid>
            </Grid>

            <Border Name="KhungKeoGian" Grid.RowSpan="2" Width="30" Height="30" HorizontalAlignment="Right" VerticalAlignment="Bottom" Cursor="SizeNWSE" Background="Transparent">
                <TextBlock Text="◢" Foreground="#475569" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,3,3" FontSize="16" IsHitTestVisible="False"/>
            </Border>
        </Grid>
    </Border>
</Window>
"@

# --- NẠP GIAO DIỆN CHUẨN ---
$BoDocTruyen = New-Object System.IO.StringReader($GiaoDienXML)
$DocXML = [System.Xml.XmlReader]::Create($BoDocTruyen)
try {
    $CuaSo = [System.Windows.Markup.XamlReader]::Load($DocXML)
} catch {
    [System.Windows.MessageBox]::Show("Lỗi phân tích giao diện XAML: $_", "Lỗi Nghiêm Trọng", 0, 16)
    exit
}

# --- KẾT NỐI BIẾN GIAO DIỆN ---
$NutDong = $CuaSo.FindName("NutDong"); $NutTaiDanhSach = $CuaSo.FindName("NutTaiDanhSach")
$NutChonTatCa = $CuaSo.FindName("NutChonTatCa"); $NutBoChon = $CuaSo.FindName("NutBoChon")
$NutCaiDat = $CuaSo.FindName("NutCaiDat"); $NutTamDung = $CuaSo.FindName("NutTamDung"); $NutHuyBo = $CuaSo.FindName("NutHuyBo")
$NhanTrangThaiWinget = $CuaSo.FindName("NhanTrangThaiWinget"); $NhanTienDo = $CuaSo.FindName("NhanTienDo")
$BangDanhSach = $CuaSo.FindName("BangDanhSach"); $ThanhTienDo = $CuaSo.FindName("ThanhTienDo")
$KhungKeoGian = $CuaSo.FindName("KhungKeoGian")
$NutSaoChep = $CuaSo.FindName("NutSaoChep")

# --- BIẾN TOÀN CỤC ---
$Global:DanhSachTong = @()          
$Global:DanhSachCanCai = @()        
$Global:ChiSoHienTai = 0            
$Global:TienTrinhHienTai = $null    
$Global:TrangThaiHeThong = "CHO_XULY" 
$Global:DangKeo = $false
$Global:DiemBatDau = $null

# --- SỰ KIỆN COPY (CHUỘT PHẢI) ---
$NutSaoChep.Add_Click({
    $DongDuocChon = $BangDanhSach.SelectedItem
    if ($DongDuocChon -ne $null) {
        $NoiDungCopy = "Tên: $($DongDuocChon.Name) | ID: $($DongDuocChon.ID) | Trạng thái: $($DongDuocChon.Status)"
        try {
            [System.Windows.Forms.Clipboard]::SetText($NoiDungCopy)
        } catch {
            [System.Windows.MessageBox]::Show("Không thể chép vào bộ nhớ tạm. Hãy thử lại!", "Lỗi", 0, 16)
        }
    }
})

# --- THUẬT TOÁN KÉO GIÃN ---
$KhungKeoGian.Add_MouseLeftButtonDown({
    $Global:DangKeo = $true
    $KhungKeoGian.CaptureMouse() | Out-Null
    $Global:DiemBatDau = [System.Windows.Forms.Cursor]::Position
})
$KhungKeoGian.Add_MouseMove({
    if ($Global:DangKeo) {
        $hienTai = [System.Windows.Forms.Cursor]::Position
        $CuaSo.Width = [math]::Max($CuaSo.MinWidth, $CuaSo.Width + ($hienTai.X - $Global:DiemBatDau.X))
        $CuaSo.Height = [math]::Max($CuaSo.MinHeight, $CuaSo.Height + ($hienTai.Y - $Global:DiemBatDau.Y))
        $Global:DiemBatDau = $hienTai
    }
})
$KhungKeoGian.Add_MouseLeftButtonUp({
    $Global:DangKeo = $false
    $KhungKeoGian.ReleaseMouseCapture() | Out-Null
})

# --- BỘ ĐẾM NHỊP (TIMER) CÀI ĐẶT ---
$Global:BoDem = New-Object System.Windows.Threading.DispatcherTimer
$Global:BoDem.Interval = [TimeSpan]::FromMilliseconds(500)
$Global:BoDem.Add_Tick({
    if ($Global:TrangThaiHeThong -eq "DANG_CHAY") {
        if ($Global:TienTrinhHienTai -eq $null -or $Global:TienTrinhHienTai.HasExited) {
            
            if ($Global:TienTrinhHienTai -ne $null) {
                $maLoi = $Global:TienTrinhHienTai.ExitCode
                if ($maLoi -eq 0 -or $maLoi -eq -1978335189) {
                    $Global:DanhSachCanCai[$Global:ChiSoHienTai].Status = "✅ Đã cài xong"
                } else {
                    $Global:DanhSachCanCai[$Global:ChiSoHienTai].Status = "❌ Lỗi (Mã: $maLoi)"
                }
                $Global:ChiSoHienTai++
                $BangDanhSach.Items.Refresh()
            }

            if ($Global:DanhSachCanCai.Count -gt 0) {
                $ThanhTienDo.Value = ($Global:ChiSoHienTai / $Global:DanhSachCanCai.Count) * 100
                $NhanTienDo.Text = "Tiến độ: $($Global:ChiSoHienTai) / $($Global:DanhSachCanCai.Count) phần mềm hoàn tất."
            }

            if ($Global:ChiSoHienTai -lt $Global:DanhSachCanCai.Count) {
                $ungDungTiepTheo = $Global:DanhSachCanCai[$Global:ChiSoHienTai]
                $ungDungTiepTheo.Status = "⏳ Đang tải & cài đặt..."
                $BangDanhSach.Items.Refresh()
                
                $idPhanMem = [string]$ungDungTiepTheo.ID
                $idPhanMem = $idPhanMem.Trim()
                $lenhCaiDat = "install --id `"$idPhanMem`" --silent --accept-package-agreements --accept-source-agreements"
                
                # MỞ CONSOLE ĐỂ THEO DÕI TIẾN TRÌNH RÕ RÀNG
                $Global:TienTrinhHienTai = Start-Process -FilePath "winget" -ArgumentList $lenhCaiDat -WindowStyle Normal -PassThru
            } else {
                $Global:TrangThaiHeThong = "CHO_XULY"
                $Global:BoDem.Stop()
                $NhanTienDo.Text = "🎉 ĐÃ HOÀN THÀNH TOÀN BỘ YÊU CẦU!"
                $NutCaiDat.IsEnabled = $true; $NutTamDung.IsEnabled = $false; $NutHuyBo.IsEnabled = $false
                $NutCaiDat.Content = "▶ CÀI ĐẶT LẠI"
                [System.Windows.MessageBox]::Show("Toàn bộ tiến trình cài đặt phần mềm đã hoàn tất!", "Thông báo", 0, 64)
            }
        }
    }
})

# --- HÀM KIỂM TRA WINGET AN TOÀN ---
function KiemTra-VaCaiWinget {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $NhanTrangThaiWinget.Text = "✅ Công cụ Winget đã sẵn sàng"
        $NhanTrangThaiWinget.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#10B981")
        return $true
    } else {
        $NhanTrangThaiWinget.Text = "❌ Chưa có. Đang tự động bổ sung Winget..."
        $NhanTrangThaiWinget.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#EF4444")
        $CuaSo.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render, [System.Action]{})
        
        try {
            $linkWinget = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $fileTam = "$env:TEMP\winget.msixbundle"
            Invoke-WebRequest -Uri $linkWinget -OutFile $fileTam -UseBasicParsing
            Add-AppxPackage -Path $fileTam
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                $NhanTrangThaiWinget.Text = "✅ Đã bổ sung Winget thành công!"
                $NhanTrangThaiWinget.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#10B981")
                return $true
            }
        } catch {
            [System.Windows.MessageBox]::Show("Lỗi bổ sung Winget. Máy quá cũ hoặc thiếu dịch vụ.", "Lỗi hệ thống", 0, 16)
        }
        return $false
    }
}

# --- SỰ KIỆN GIAO DIỆN ---
$NutDong.Add_Click({ $Global:BoDem.Stop(); $CuaSo.Close() })
$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })

$NutChonTatCa.Add_Click({ foreach ($app in $Global:DanhSachTong) { $app.IsSelected = $true }; $BangDanhSach.Items.Refresh() })
$NutBoChon.Add_Click({ foreach ($app in $Global:DanhSachTong) { $app.IsSelected = $false }; $BangDanhSach.Items.Refresh() })

$NutTaiDanhSach.Add_Click({
    try {
        $NhanTienDo.Text = "Đang kết nối để lấy danh sách từ Github..."
        $CuaSo.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render, [System.Action]{})
        
        $duLieuCsv = Invoke-RestMethod -Uri $Global:DuongDanCsv -UseBasicParsing | ConvertFrom-Csv
        
        $Global:DanhSachTong = @()
        foreach ($dong in $duLieuCsv) {
            # Ép kiểu URI để chắc chắn WPF tải được hình ảnh qua web
            $duongDanAnh = $null
            if (-not [string]::IsNullOrWhiteSpace($dong.iconurl)) {
                $duongDanAnh = [uri]$dong.iconurl
            }

            $Global:DanhSachTong += [PSCustomObject]@{ 
                IsSelected = $true; 
                BieuTuong = $duongDanAnh; 
                Name = $dong.Name; 
                ID = $dong.WingetID; 
                Status = "Đang chờ" 
            }
        }
        
        $BangDanhSach.ItemsSource = $Global:DanhSachTong
        $NhanTienDo.Text = "Đã tải $($Global:DanhSachTong.Count) phần mềm. Tích chọn các mục cần cài."
        $ThanhTienDo.Value = 0
    } catch {
        [System.Windows.MessageBox]::Show("Không thể tải tập tin CSV! Vui lòng kiểm tra lại đường dẫn.", "Lỗi truy xuất", 0, 16)
        $NhanTienDo.Text = "❌ Lỗi truy xuất danh sách."
    }
})

$NutCaiDat.Add_Click({
    if ($Global:DanhSachTong.Count -eq 0) { [System.Windows.MessageBox]::Show("Vui lòng tải danh sách trước!", "Cảnh báo", 0, 48); return }
    if (-not (KiemTra-VaCaiWinget)) { return }

    $Global:DanhSachCanCai = @()
    foreach ($app in $Global:DanhSachTong) {
        if ($app.IsSelected) { $app.Status = "Chờ cài đặt"; $Global:DanhSachCanCai += $app } 
        else { $app.Status = "Đã bỏ qua" }
    }
    $BangDanhSach.Items.Refresh()

    if ($Global:DanhSachCanCai.Count -eq 0) { [System.Windows.MessageBox]::Show("Bạn chưa chọn phần mềm nào!", "Thông báo", 0, 48); return }
    
    $Global:ChiSoHienTai = 0; $Global:TienTrinhHienTai = $null; $Global:TrangThaiHeThong = "DANG_CHAY"; $ThanhTienDo.Value = 0
    $NutCaiDat.IsEnabled = $false; $NutTamDung.IsEnabled = $true; $NutHuyBo.IsEnabled = $true; $NutTamDung.Content = "⏸ TẠM DỪNG"
    $Global:BoDem.Start()
})

$NutTamDung.Add_Click({
    if ($Global:TrangThaiHeThong -eq "DANG_CHAY") {
        if ($Global:TienTrinhHienTai -ne $null -and -not $Global:TienTrinhHienTai.HasExited) { [QuanLyTienTrinh]::NtSuspendProcess($Global:TienTrinhHienTai.Handle) | Out-Null }
        $Global:TrangThaiHeThong = "TAM_DUNG"; $NutTamDung.Content = "▶ TIẾP TỤC"
        $NutTamDung.Background = [Windows.Media.BrushConverter]::new().ConvertFrom("#3B82F6")
        $NhanTienDo.Text = "⚠️ Đang TẠM DỪNG quá trình cài đặt..."
    } elseif ($Global:TrangThaiHeThong -eq "TAM_DUNG") {
        if ($Global:TienTrinhHienTai -ne $null -and -not $Global:TienTrinhHienTai.HasExited) { [QuanLyTienTrinh]::NtResumeProcess($Global:TienTrinhHienTai.Handle) | Out-Null }
        $Global:TrangThaiHeThong = "DANG_CHAY"; $NutTamDung.Content = "⏸ TẠM DỪNG"
        $NutTamDung.Background = [Windows.Media.BrushConverter]::new().ConvertFrom("#F59E0B")
        $NhanTienDo.Text = "Tiếp tục cài đặt phần mềm..."
    }
})

$NutHuyBo.Add_Click({
    $Global:TrangThaiHeThong = "DA_HUY"; $Global:BoDem.Stop()
    if ($Global:TienTrinhHienTai -ne $null -and -not $Global:TienTrinhHienTai.HasExited) { Stop-Process -Id $Global:TienTrinhHienTai.Id -Force -ErrorAction SilentlyContinue }
    if ($Global:ChiSoHienTai -lt $Global:DanhSachCanCai.Count) { $Global:DanhSachCanCai[$Global:ChiSoHienTai].Status = "🛑 Đã bị hủy bỏ"; $BangDanhSach.Items.Refresh() }
    $NhanTienDo.Text = "ĐÃ HỦY BỎ TIẾN TRÌNH CÀI ĐẶT."
    $NutCaiDat.IsEnabled = $true; $NutTamDung.IsEnabled = $false; $NutHuyBo.IsEnabled = $false; $NutCaiDat.Content = "▶ BẮT ĐẦU LẠI"
})

$CuaSo.Add_ContentRendered({ KiemTra-VaCaiWinget | Out-Null })

$CuaSo.ShowDialog() | Out-Null