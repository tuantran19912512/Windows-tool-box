# ==============================================================================
# SCRIPT: CẤU HÌNH DNS TÙY CHỌN - GIAO DIỆN WPF (BẢNG CHỌN RADIO)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

# ÉP POWERSHELL HIỂU TIẾNG VIỆT & NẠP WPF (LOẠI BỎ HOÀN TOÀN WINFORMS)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicThucThi = {
    # --- 1. KHỞI TẠO GIAO DIỆN XAML WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Lựa chọn DNS" Width="420" Height="340"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" FontFamily="Segoe UI" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#E0E0E0"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Margin" Value="30,12"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.85"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="CHỌN HỆ THỐNG DNS MUỐN CẤU HÌNH:" Foreground="#00D4FF" FontSize="16" FontWeight="Bold" TextAlignment="Center" Margin="0,10,0,20"/>

        <StackPanel Grid.Row="1" VerticalAlignment="Center" Background="#252526">
            <RadioButton Name="radGoogle" Content="GOOGLE DNS (8.8.8.8 - 8.8.4.4)" IsChecked="True"/>
            <RadioButton Name="radCloudflare" Content="CLOUDFLARE DNS (1.1.1.1 - 1.0.0.1)"/>
            <RadioButton Name="radDHCP" Content="MẶC ĐỊNH (NHÀ MẠNG / DHCP)"/>
        </StackPanel>

        <Button Name="btnApDung" Grid.Row="2" Content="ÁP DỤNG CẤU HÌNH" Height="45" Background="#00D4FF" Foreground="#1E1E1E" FontWeight="Bold" FontSize="14" Margin="30,20,30,10"/>
    </Grid>
</Window>
"@

    # --- 2. ÁNH XẠ BIẾN & XỬ LÝ SỰ KIỆN GIAO DIỆN ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    $radGoogle = $CuaSo.FindName("radGoogle")
    $radCloudflare = $CuaSo.FindName("radCloudflare")
    $radDHCP = $CuaSo.FindName("radDHCP")
    $btnApDung = $CuaSo.FindName("btnApDung")

    $Global:DNS_Selected = $null
    $Global:DNS_Name = ""

    # Logic khi bấm nút Áp Dụng
    $btnApDung.Add_Click({
        if ($radGoogle.IsChecked) {
            $Global:DNS_Selected = @("8.8.8.8", "8.8.4.4")
            $Global:DNS_Name = "GOOGLE DNS"
        } elseif ($radCloudflare.IsChecked) {
            $Global:DNS_Selected = @("1.1.1.1", "1.0.0.1")
            $Global:DNS_Name = "CLOUDFLARE DNS"
        } else {
            $Global:DNS_Selected = "RESET"
            $Global:DNS_Name = "MẶC ĐỊNH (DHCP)"
        }
        $CuaSo.Close()
    })

    # Hiển thị cửa sổ (Chặn luồng cho đến khi khách chọn xong)
    $CuaSo.ShowDialog() | Out-Null

    # --- 3. XỬ LÝ LOGIC MẠNG SAU KHI CHỌN ---
    if ($null -eq $Global:DNS_Selected) { return } # Nếu khách bấm X tắt bảng mà không chọn gì thì thoát luôn

    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG THIẾT LẬP: $Global:DNS_Name <<<"
    Ghi-Log "=========================================================="

    try {
        # Lấy tất cả các Card mạng đang cắm dây / kết nối Wifi
        $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        if (-not $Adapters) { Ghi-Log "!!! LỖI: Không tìm thấy Card mạng đang hoạt động."; return }

        foreach ($Adapter in $Adapters) {
            Ghi-Log "-> Đang xử lý: $($Adapter.Name)"
            if ($Global:DNS_Selected -eq "RESET") {
                # Trả về DHCP (Nhà mạng)
                Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ResetServerAddresses -ErrorAction Stop
            } else {
                # Gán DNS cụ thể
                Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ServerAddresses $Global:DNS_Selected -ErrorAction Stop
            }
            Ghi-Log "   [OK] Thành công."
        }

        Ghi-Log "-> Làm mới DNS (FlushDNS)..."
        ipconfig /flushdns | Out-Null
        Ghi-Log ">>> HOÀN TẤT CẬP NHẬT DNS <<<"

        # Thay thế MessageBox của WinForms sang WPF
        [System.Windows.MessageBox]::Show("Đã thiết lập $Global:DNS_Name trên các Card mạng thành công!", "VietToolbox", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

    } catch {
        Ghi-Log "!!! LỖI: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show("Lỗi cấu hình DNS: $($_.Exception.Message)", "VietToolbox - Lỗi", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
    Ghi-Log "=========================================================="
}

# Tích hợp vào hệ thống VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang mở bảng chọn DNS..." $LogicThucThi
} else {
    &$LogicThucThi
}