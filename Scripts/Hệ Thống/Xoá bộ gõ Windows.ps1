# ==========================================================
# VIETTOOLBOX - SỬA LỖI & DỌN DẸP LAYOUT BÀN PHÍM
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# NẠP THƯ VIỆN WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Ghi-Log "=========================================="
Ghi-Log ">>> KIỂM TRA NGÔN NGỮ & BỘ GÕ HỆ THỐNG <<<"

# 1. Liệt kê danh sách đang có ra khung LOG
$CurrentList = Get-WinUserLanguageList
Ghi-Log "DANH SÁCH HIỆN TẠI:"
foreach ($lang in $CurrentList) {
    Ghi-Log "   [+] $($lang.LanguageTag) - $($lang.Autonym)"
}
Ghi-Log "------------------------------------------"

# 2. GIAO DIỆN CHỌN (THAY THẾ HOÀN TOÀN VISUAL BASIC INPUTBOX)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="VietToolbox - Dọn dẹp Ngôn ngữ" Width="500" Height="360"
        WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="0,5"/>
            <Setter Property="Height" Value="45"/>
            <Setter Property="FontSize" Value="14"/>
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
                    <Setter Property="Opacity" Value="0.9"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <TextBlock Text="MÁY ĐANG CÓ $($CurrentList.Count) NGÔN NGỮ" FontSize="20" FontWeight="Bold" Foreground="#1A237E" HorizontalAlignment="Center"/>
        <TextBlock Grid.Row="1" Text="Bạn muốn dọn dẹp thanh Language Bar như thế nào?" FontSize="14" Foreground="#666666" HorizontalAlignment="Center" Margin="0,5,0,15"/>
        
        <StackPanel Grid.Row="2" VerticalAlignment="Center">
            <Button Name="btnEng" Content="1. CHỈ GIỮ TIẾNG ANH (en-US)" Background="#2196F3"/>
            <Button Name="btnVie" Content="2. CHỈ GIỮ TIẾNG VIỆT (vi-VN)" Background="#4CAF50"/>
            <Button Name="btnBoth" Content="3. GIỮ CẢ TIẾNG VIỆT &amp; ANH (Sạch nhất)" Background="#FF9800"/>
            <Button Name="btnCancel" Content="0. KHÔNG XÓA - Thoát ngay" Background="#9E9E9E" Margin="0,15,0,0"/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$btnEng = $window.FindName("btnEng")
$btnVie = $window.FindName("btnVie")
$btnBoth = $window.FindName("btnBoth")
$btnCancel = $window.FindName("btnCancel")

# Biến lưu trữ lựa chọn
$script:LuaChon = "0"

$btnEng.Add_Click({ $script:LuaChon = "1"; $window.Close() })
$btnVie.Add_Click({ $script:LuaChon = "2"; $window.Close() })
$btnBoth.Add_Click({ $script:LuaChon = "3"; $window.Close() })
$btnCancel.Add_Click({ $script:LuaChon = "0"; $window.Close() })

$window.ShowDialog() | Out-Null

# HÀM DOEVENTS CHUẨN WPF
$CapNhatGiaoDien = {
    $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

# 3. XỬ LÝ LOGIC NGÔN NGỮ
switch ($script:LuaChon) {
    "1" {
        Ghi-Log "-> Đang thực hiện: CHỈ GIỮ TIẾNG ANH (en-US)..."
        $NewList = New-WinUserLanguageList en-US
        Set-WinUserLanguageList $NewList -Force
    }
    
    "2" {
        Ghi-Log "-> Đang thực hiện: CHỈ GIỮ TIẾNG VIỆT (vi-VN)..."
        $NewList = New-WinUserLanguageList vi-VN
        Set-WinUserLanguageList $NewList -Force
    }

    "3" {
        Ghi-Log "-> Đang thực hiện: GIỮ TIẾNG VIỆT (Ưu tiên) + TIẾNG ANH..."
        $NewList = New-WinUserLanguageList vi-VN
        $NewList.Add("en-US")
        Set-WinUserLanguageList $NewList -Force
    }

    "0" { 
        Ghi-Log "!!! Đã hủy quy trình. Không có thay đổi nào được thực hiện."
        return 
    }
}

# 4. KIỂM TRA LẠI SAU KHI XÓA
&$CapNhatGiaoDien
$FinalList = Get-WinUserLanguageList
Ghi-Log "-> DANH SÁCH MỚI: $(($FinalList.LanguageTag) -join ' | ')"
Ghi-Log ">>> HOÀN TẤT DỌN DẸP."

[System.Windows.MessageBox]::Show("Đã cập nhật layout bàn phím và ngôn ngữ hệ thống thành công!", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)