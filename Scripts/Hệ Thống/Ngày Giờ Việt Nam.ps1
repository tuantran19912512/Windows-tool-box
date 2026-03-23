# ==============================================================================
# SCRIPT: CẤU HÌNH NGÀY GIỜ + RESET EXPLORER (GIAO DIỆN CHỌN CHUYÊN NGHIỆP)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

# ÉP POWERSHELL HIỂU TIẾNG VIỆT & NẠP WPF
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicThucThi = {
    # --- 1. KHỞI TẠO GIAO DIỆN XAML WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Cấu hình Thời gian" Width="400" Height="300"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" FontFamily="Segoe UI" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Height" Value="50"/>
            <Setter Property="Margin" Value="0,10"/>
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
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.85"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="25">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="CHỌN ĐỊNH DẠNG GIỜ HỆ THỐNG" Foreground="#00D4FF" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <StackPanel Grid.Row="1" VerticalAlignment="Center">
            <Button Name="btn24h" Content="CHẾ ĐỘ 24 GIỜ (14:30)" Background="#2980B9"/>
            <Button Name="btn12h" Content="CHẾ ĐỘ 12 GIỜ (02:30 PM)" Background="#27AE60"/>
        </StackPanel>

        <TextBlock Grid.Row="2" Text="* Hệ thống sẽ Reset Explorer để áp dụng ngay" Foreground="Gray" FontSize="11" FontStyle="Italic" HorizontalAlignment="Center" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@

    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    $btn24h = $CuaSo.FindName("btn24h")
    $btn12h = $CuaSo.FindName("btn12h")

    $Global:TimeFormat_Choice = $null

    # Gán sự kiện cho nút bấm
    $btn24h.Add_Click({ $Global:TimeFormat_Choice = "24H"; $CuaSo.Close() })
    $btn12h.Add_Click({ $Global:TimeFormat_Choice = "12H"; $CuaSo.Close() })

    # Hiện bảng chọn
    $CuaSo.ShowDialog() | Out-Null

    # --- 2. XỬ LÝ LOGIC SAU KHI CHỌN ---
    if ($null -eq $Global:TimeFormat_Choice) { return }

    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG CẤU HÌNH THỜI GIAN (FORCED UPDATE) <<<"
    Ghi-Log "=========================================================="

    # Đồng bộ múi giờ & Giờ máy chủ
    Ghi-Log "-> Đang đồng bộ múi giờ +7 (Hà Nội) & Giờ hệ thống..."
    tzutil /s "SE Asia Standard Time"
    Start-Service w32time -ErrorAction SilentlyContinue
    w32tm /resync /force | Out-Null

    # Ghi Registry định dạng
    Ghi-Log "-> Đang ghi cấu hình định dạng Ngày/Tháng/Năm..."
    $RegPath = "HKCU:\Control Panel\International"
    Set-ItemProperty -Path $RegPath -Name "sShortDate" -Value "dd/MM/yyyy"
    Set-ItemProperty -Path $RegPath -Name "sDate" -Value "/"
    
    if ($Global:TimeFormat_Choice -eq "24H") {
        Set-ItemProperty -Path $RegPath -Name "sTimeFormat" -Value "HH:mm:ss"
        Set-ItemProperty -Path $RegPath -Name "sShortTime" -Value "HH:mm"
        Ghi-Log "   [+] Đã thiết lập: Chế độ 24 Giờ."
    } else {
        Set-ItemProperty -Path $RegPath -Name "sTimeFormat" -Value "h:mm:ss tt"
        Set-ItemProperty -Path $RegPath -Name "sShortTime" -Value "h:mm tt"
        Ghi-Log "   [+] Đã thiết lập: Chế độ 12 Giờ."
    }

    # Reset Explorer
    Ghi-Log "-> Đang làm mới Explorer (Màn hình sẽ chớp nhẹ)..."
    try {
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 1
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
        Ghi-Log "   [OK] Đã làm mới giao diện thành công."
    } catch {
        Ghi-Log "   [!] Lỗi khi reset Explorer."
    }

    Ghi-Log "=========================================================="
    Ghi-Log ">>> HOÀN TẤT CẬP NHẬT NGÀY GIỜ <<<"
    Ghi-Log "=========================================================="
    
    [System.Windows.MessageBox]::Show("Đã đồng bộ và cập nhật định dạng $Global:TimeFormat_Choice thành công!", "VietToolbox", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
}

# Tích hợp vào hệ thống
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang mở bảng chọn Ngày Giờ..." $LogicThucThi
} else {
    &$LogicThucThi
}