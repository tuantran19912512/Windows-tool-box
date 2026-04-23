<#
.SYNOPSIS
    VIETTOOLBOX V4 - WPF + RUNSPACE
    Giao diện WPF hiện đại, dark theme, worker chạy nền không treo UI.
#>

# --- KIỂM TRA QUYỀN ADMIN ---
$DuongDanKichBan = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Definition }
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$DuongDanKichBan`""
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml

# =============================================
# BIẾN TOÀN CỤC
# =============================================
$Global:TepNhatKy = "$env:USERPROFILE\Desktop\VietToolbox_NhatKy_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$Global:SaoLuuReg = "$env:USERPROFILE\Desktop\VietToolbox_SaoLuuReg_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
$Global:HangDoiMsg = [System.Collections.Concurrent.ConcurrentQueue[hashtable]]::new()

# =============================================
# XAML - GIAO DIỆN WPF
# =============================================
[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="VietToolbox V4 - Tối Ưu &amp; Bảo Mật Windows"
    Height="700" Width="660"
    ResizeMode="CanMinimize"
    WindowStartupLocation="CenterScreen"
    Background="#111318"
    FontFamily="Segoe UI">

    <Window.Resources>

        <SolidColorBrush x:Key="BgMain"    Color="#111318"/>
        <SolidColorBrush x:Key="BgCard"    Color="#1C1F27"/>
        <SolidColorBrush x:Key="BgInput"   Color="#13151A"/>
        <SolidColorBrush x:Key="Accent"    Color="#00D26A"/>
        <SolidColorBrush x:Key="AccentDim" Color="#00874A"/>
        <SolidColorBrush x:Key="Danger"    Color="#E05252"/>
        <SolidColorBrush x:Key="Info"      Color="#4FC3F7"/>
        <SolidColorBrush x:Key="TextPri"   Color="#E8EAED"/>
        <SolidColorBrush x:Key="TextSec"   Color="#7B8394"/>
        <SolidColorBrush x:Key="Border"    Color="#2A2D38"/>

        <Style x:Key="ModernCheck" TargetType="CheckBox">
            <Setter Property="Foreground"  Value="{StaticResource TextPri}"/>
            <Setter Property="Background"  Value="Transparent"/>
            <Setter Property="FontSize"    Value="12"/>
            <Setter Property="Cursor"      Value="Hand"/>
            <Setter Property="Margin"      Value="0,3,0,3"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border x:Name="Box" Width="16" Height="16" CornerRadius="3"
                                    Background="#1C1F27" BorderBrush="#3A3D4A" BorderThickness="1.5"
                                    VerticalAlignment="Center">
                                <Path x:Name="Check" Data="M2,8 L6,12 L14,4"
                                      Stroke="#00D26A" StrokeThickness="2"
                                      StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                      Visibility="Collapsed"/>
                            </Border>
                            <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center"
                                              RecognizesAccessKey="True"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Box"   Property="Background"    Value="#0D2E1A"/>
                                <Setter TargetName="Box"   Property="BorderBrush"   Value="#00D26A"/>
                                <Setter TargetName="Check" Property="Visibility"    Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Box" Property="BorderBrush" Value="#00D26A"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="BtnPrimary" TargetType="Button">
            <Setter Property="Background"   Value="#00D26A"/>
            <Setter Property="Foreground"   Value="#0A0F0A"/>
            <Setter Property="FontSize"     Value="13"/>
            <Setter Property="FontWeight"   Value="Bold"/>
            <Setter Property="Height"       Value="40"/>
            <Setter Property="Cursor"       Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="16,0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#00F07A"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#00874A"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Background" Value="#2A3530"/>
                                <Setter Property="Foreground" Value="#4A5550"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="BtnSecondary" TargetType="Button">
            <Setter Property="Background"      Value="#1C1F27"/>
            <Setter Property="Foreground"      Value="{StaticResource TextPri}"/>
            <Setter Property="FontSize"        Value="12"/>
            <Setter Property="Height"          Value="40"/>
            <Setter Property="Cursor"          Value="Hand"/>
            <Setter Property="BorderBrush"     Value="#2A2D38"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" Padding="12,0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#00D26A"/>
                                <Setter TargetName="Bd" Property="Background"  Value="#1F2830"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#141820"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernTab" TargetType="TabItem">
            <Setter Property="Foreground"      Value="#7B8394"/>
            <Setter Property="FontSize"        Value="13"/>
            <Setter Property="Padding"         Value="18,10"/>
            <Setter Property="Background"      Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor"          Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="Bd" Background="Transparent"
                                BorderThickness="0,0,0,2" BorderBrush="Transparent"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header"
                                              HorizontalAlignment="Center"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#00D26A"/>
                                <Setter Property="Foreground" Value="#00D26A"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="#E8EAED"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernTabControl" TargetType="TabControl">
            <Setter Property="Background"      Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding"         Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabControl">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Grid.Row="0" BorderBrush="#2A2D38" BorderThickness="0,0,0,1">
                                <TabPanel IsItemsHost="True" Background="Transparent"/>
                            </Border>
                            <ContentPresenter Grid.Row="1" ContentSource="SelectedContent"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernProgress" TargetType="ProgressBar">
            <Setter Property="Height"          Value="6"/>
            <Setter Property="Background"      Value="#1C1F27"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground"      Value="#00D26A"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Border CornerRadius="3" Background="{TemplateBinding Background}"
                                ClipToBounds="True">
                            <Border x:Name="PART_Indicator" HorizontalAlignment="Left"
                                    CornerRadius="3" Background="{TemplateBinding Foreground}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="4"/>
            <Setter Property="Background" Value="Transparent"/>
        </Style>

        <Style x:Key="LogBox" TargetType="ListBox">
            <Setter Property="Background"      Value="#0C0E13"/>
            <Setter Property="BorderBrush"     Value="#2A2D38"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontFamily"      Value="Cascadia Mono, Consolas"/>
            <Setter Property="FontSize"        Value="11"/>
            <Setter Property="Foreground"      Value="#4FC3F7"/>
            <Setter Property="Padding"         Value="4"/>
            <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Disabled"/>
        </Style>

    </Window.Resources>

    <Grid Margin="20,16,20,16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>  <RowDefinition Height="Auto"/>  <RowDefinition Height="Auto"/>  <RowDefinition Height="*"/>     <RowDefinition Height="Auto"/>  <RowDefinition Height="110"/>   </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel>
                <TextBlock Text="VietToolbox V4"
                           FontSize="22" FontWeight="Bold"
                           Foreground="{StaticResource Accent}"/>
                <TextBlock Text="Hệ thống tối ưu &amp; bảo mật Windows toàn diện"
                           FontSize="12" Foreground="{StaticResource TextSec}" Margin="0,2,0,0"/>
            </StackPanel>
            <Border Grid.Column="1" Background="#1C1F27" CornerRadius="6"
                    Padding="12,6" VerticalAlignment="Center">
                <StackPanel Orientation="Horizontal">
                    <Ellipse x:Name="ChamTrangThai" Width="8" Height="8" Fill="#4A5060"
                             VerticalAlignment="Center"/>
                    <TextBlock x:Name="ChuTrangThai" Text="Sẵn sàng"
                               Foreground="{StaticResource TextSec}"
                               FontSize="12" Margin="8,0,0,0" VerticalAlignment="Center"/>
                </StackPanel>
            </Border>
        </Grid>

        <Grid Grid.Row="2" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <ProgressBar x:Name="ThanhTienTrinh" Style="{StaticResource ModernProgress}" Value="0"/>
            <TextBlock x:Name="ChuPhanTram" Grid.Column="1" Text="0%"
                       Foreground="{StaticResource TextSec}" FontSize="11"
                       Margin="10,0,0,0" VerticalAlignment="Center"/>
        </Grid>

        <TabControl Grid.Row="3" x:Name="CacThe"
                    Style="{StaticResource ModernTabControl}"
                    Margin="0,0,0,14">

            <TabItem Header="🧹  Dọn Dẹp" Style="{StaticResource ModernTab}">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <WrapPanel Orientation="Horizontal">

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="WINDOWS UPDATE" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_WinUpdate"  Content="Xóa cache SoftwareDistribution" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_WinUpdate2" Content="Tắt dịch vụ Windows Update"     Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="FILE RÁC &amp; CACHE" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_Temp"       Content="Xóa Temp, Windows\Temp, Prefetch" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_RecycleBin" Content="Dọn Thùng Rác"                    Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_ThumbCache" Content="Xóa Thumbnail Cache"              Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_FontCache"  Content="Làm mới Font Cache"               Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="HỆ THỐNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_DISM"     Content="DISM dọn WinSxS (mất vài phút)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_EventLog" Content="Xóa Event Log hệ thống"          Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="ỨNG DỤNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_AppRac" Content="Gỡ app rác (BingNews, Skype...)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_DellSA" Content="Xóa rác Dell SARemediation"      Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>

                    </WrapPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="⚡  Tối Ưu" Style="{StaticResource ModernTab}">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <WrapPanel Orientation="Horizontal">

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="HỆ THỐNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_PageFile" Content="Tối ưu PageFile (xóa khi tắt)"      Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_Hibern"   Content="Tắt Hibernation – giải phóng ổ C"   Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_VisualFx" Content="Tắt hiệu ứng Visual (máy yếu)"      Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_Prefetch" Content="Tối ưu Prefetch / Superfetch"        Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="MẠNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_NetThrot" Content="Bỏ giới hạn băng thông"            Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_TCP"      Content="Tối ưu TCP/IP (tắt Nagle)"         Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_DNS"      Content="Tăng DNS Cache"                    Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_IRPStack" Content="Tăng IRPStackSize"                 Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="Ổ ĐĨA" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_SSD"  Content="Re-TRIM nếu phát hiện SSD"        Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_NTFS" Content="Tối ưu NTFS (tắt ghi timestamp)"  Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="GAMING" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_GameMode" Content="Game Mode &amp; GPU Scheduling" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                    </WrapPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="🔒  Bảo Mật" Style="{StaticResource ModernTab}">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <WrapPanel Orientation="Horizontal">

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="THEO DÕI &amp; THU THẬP" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_Telemetry" Content="Tắt Telemetry &amp; DiagTrack"   Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_Cortana"   Content="Tắt Cortana"                     Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_AdvApps"   Content="Tắt quảng cáo Start &amp; App"  Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_WifiSense" Content="Tắt WiFi Sense"                  Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="DỊCH VỤ" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_DiagSvc"  Content="Tắt Diagnostic Services"  Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_RemoteReg" Content="Tắt Remote Registry"     Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="ĐĂNG NHẬP" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_LockScreen" Content="Tắt Lock Screen"                  Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_AutoLogon"  Content="Tự đăng nhập (không mật khẩu)"   Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_UAC"        Content="Hạ UAC (ít hỏi quyền hơn)"       Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>

                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="285">
                            <StackPanel>
                                <TextBlock Text="SAO LƯU" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_BackupReg" Content="Backup Registry trước khi sửa" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                    </WrapPanel>
                </ScrollViewer>
            </TabItem>

        </TabControl>

        <Grid Grid.Row="4" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="10"/>
                <ColumnDefinition Width="130"/>
                <ColumnDefinition Width="10"/>
                <ColumnDefinition Width="130"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="NutBatDau" Grid.Column="0"
                    Content="▶   BẮT ĐẦU TỐI ƯU"
                    Style="{StaticResource BtnPrimary}"/>
            <Button x:Name="NutChonTatCa" Grid.Column="2"
                    Content="✔  Chọn Tất Cả"
                    Style="{StaticResource BtnSecondary}"/>
            <Button x:Name="NutBoChonTatCa" Grid.Column="4"
                    Content="✖  Bỏ Chọn"
                    Style="{StaticResource BtnSecondary}"/>
        </Grid>

        <Border Grid.Row="5" BorderBrush="#2A2D38" BorderThickness="1" CornerRadius="8" ClipToBounds="True">
            <Grid>
                <ListBox x:Name="HopNhatKy" Style="{StaticResource LogBox}"/>
                <TextBlock x:Name="ChuGoiY" Text="Nhật ký hệ thống sẽ hiển thị tại đây..."
                           Foreground="#3A4050" FontFamily="Cascadia Mono, Consolas" FontSize="11"
                           HorizontalAlignment="Center" VerticalAlignment="Center"
                           IsHitTestVisible="False"/>
            </Grid>
        </Border>

    </Grid>
</Window>
"@

# =============================================
# NẠP XAML VÀ LẤY CÁC CONTROL
# =============================================
$Reader = [System.Xml.XmlNodeReader]::new($XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

function Lay-Control($Ten) { $Window.FindName($Ten) }

$NutBatDau       = Lay-Control "NutBatDau"
$NutChonTatCa    = Lay-Control "NutChonTatCa"
$NutBoChonTatCa  = Lay-Control "NutBoChonTatCa"
$ThanhTienTrinh  = Lay-Control "ThanhTienTrinh"
$ChuPhanTram     = Lay-Control "ChuPhanTram"
$ChuTrangThai    = Lay-Control "ChuTrangThai"
$ChamTrangThai   = Lay-Control "ChamTrangThai"
$HopNhatKy       = Lay-Control "HopNhatKy"
$ChuGoiY         = Lay-Control "ChuGoiY"
$CacThe          = Lay-Control "CacThe"

# Checkboxes
$chk = @{}
@("WinUpdate","WinUpdate2","Temp","RecycleBin","ThumbCache","FontCache","DISM","EventLog","AppRac","DellSA",
  "PageFile","Hibern","VisualFx","Prefetch","NetThrot","TCP","DNS","IRPStack","SSD","NTFS","GameMode",
  "Telemetry","Cortana","AdvApps","WifiSense","DiagSvc","RemoteReg","LockScreen","AutoLogon","UAC","BackupReg"
) | ForEach-Object { $chk[$_] = Lay-Control "chk_$_" }

# =============================================
# TIMER - ĐỌC QUEUE VÀ ĐẨY LÊN UI
# =============================================
$UITimer          = New-Object System.Windows.Threading.DispatcherTimer
$UITimer.Interval = [TimeSpan]::FromMilliseconds(50)

$UITimer.Add_Tick({
    $TinNhan = $null
    while ($Global:HangDoiMsg.TryDequeue([ref]$TinNhan)) {
        switch ($TinNhan.Type) {
            "LOG" {
                $ThanhTienTrinh.Value  = $TinNhan.Pct
                $ChuPhanTram.Text      = "$($TinNhan.Pct)%"
                $ChuTrangThai.Text     = $TinNhan.Status
                $Dong = "[$([datetime]::Now.ToString('HH:mm:ss'))]  $($TinNhan.Text)"
                $HopNhatKy.Items.Add($Dong) | Out-Null
                $HopNhatKy.ScrollIntoView($HopNhatKy.Items[$HopNhatKy.Items.Count - 1])
                $ChuGoiY.Visibility = "Collapsed"
                Add-Content -Path $Global:TepNhatKy -Value $Dong -Encoding UTF8
            }
            "DONE" {
                $UITimer.Stop()
                $ThanhTienTrinh.Value  = 100
                $ChuPhanTram.Text      = "100%"
                $ChuTrangThai.Text     = "Hoàn tất!"
                $ChamTrangThai.Fill    = [System.Windows.Media.Brushes]::LimeGreen
                $NutBatDau.Content     = "▶   BẮT ĐẦU TỐI ƯU"
                $NutBatDau.IsEnabled   = $true
                [System.Windows.MessageBox]::Show(
                    "VietToolbox V4 hoàn thành xuất sắc!`n`nNhật ký lưu tại:`n$($Global:TepNhatKy)`n`nVui lòng khởi động lại máy để áp dụng.",
                    "Hoàn Tất", "OK", "Information")
            }
            "ERROR" {
                $HopNhatKy.Items.Add("[LỖI]  $($TinNhan.Text)") | Out-Null
            }
        }
    }
})

# =============================================
# CHỌN / BỎ CHỌN TẤT CẢ TRONG TAB HIỆN TẠI
# =============================================
function Lay-HopChonTrongThe {
    $TheDangChon = $CacThe.SelectedItem
    $DanhSachHopChon = @()
    $HangDoi = [System.Collections.Queue]::new()
    $HangDoi.Enqueue($TheDangChon)
    while ($HangDoi.Count -gt 0) {
        $PhanTu = $HangDoi.Dequeue()
        if ($PhanTu -is [System.Windows.Controls.CheckBox]) {
            $DanhSachHopChon += $PhanTu
        }
        if ($PhanTu -is [System.Windows.Controls.Panel] -or
            $PhanTu -is [System.Windows.Controls.Border] -or
            $PhanTu -is [System.Windows.Controls.TabItem] -or
            $PhanTu -is [System.Windows.Controls.ScrollViewer]) {
            $PhanTuCon = $null
            if ($PhanTu -is [System.Windows.Controls.Border])       { $PhanTuCon = @($PhanTu.Child) }
            elseif ($PhanTu -is [System.Windows.Controls.ScrollViewer]) { $PhanTuCon = @($PhanTu.Content) }
            elseif ($PhanTu -is [System.Windows.Controls.TabItem])  { $PhanTuCon = @($PhanTu.Content) }
            else { $PhanTuCon = $PhanTu.Children }
            if ($PhanTuCon) { foreach ($C in $PhanTuCon) { if ($C) { $HangDoi.Enqueue($C) } } }
        }
    }
    return $DanhSachHopChon
}

$NutChonTatCa.Add_Click({ Lay-HopChonTrongThe | ForEach-Object { $_.IsChecked = $true  } })
$NutBoChonTatCa.Add_Click({  Lay-HopChonTrongThe | ForEach-Object { $_.IsChecked = $false } })

# =============================================
# NÚT BẮT ĐẦU
# =============================================
$NutBatDau.Add_Click({
    $CauHinh = @{}
    foreach ($Key in $chk.Keys) { $CauHinh[$Key] = $chk[$Key].IsChecked }
    $CauHinh["SaoLuuReg"] = $Global:SaoLuuReg

    # Reset UI
    $NutBatDau.IsEnabled = $false
    $NutBatDau.Content   = "⏳  Đang xử lý..."
    $ThanhTienTrinh.Value = 0
    $ChuPhanTram.Text    = "0%"
    $ChuTrangThai.Text   = "Đang khởi động..."
    $ChamTrangThai.Fill  = [System.Windows.Media.Brushes]::Orange
    $HopNhatKy.Items.Clear()
    $ChuGoiY.Visibility  = "Collapsed"

    $UITimer.Start()

    # Tạo Runspace
    $KhongGianChay = [runspacefactory]::CreateRunspace()
    $KhongGianChay.ApartmentState = "STA"
    $KhongGianChay.ThreadOptions  = "ReuseThread"
    $KhongGianChay.Open()
    $KhongGianChay.SessionStateProxy.SetVariable("HangDoiMsg", $Global:HangDoiMsg)
    $KhongGianChay.SessionStateProxy.SetVariable("CauHinh", $CauHinh)

    $KichBanXuLy = {
        function Ghi-NhatKyWorker($Pct, $Status, $Text) {
            $HangDoiMsg.Enqueue(@{ Type="LOG"; Pct=[Math]::Min($Pct,100); Status=$Status; Text=$Text })
        }
        function Sua-RegWorker($Path, $Name, $Val, $Type = "DWord") {
            try {
                if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
                Set-ItemProperty -Path $Path -Name $Name -Value $Val -Type $Type -Force | Out-Null
            } catch { $HangDoiMsg.Enqueue(@{ Type="ERROR"; Text="Reg: $Path\$Name – $_" }) }
        }
        function Chay-LenhWorker($Cmd, $Args) {
            try {
                $p = Start-Process -FilePath $Cmd -ArgumentList $Args -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
                if ($p) { $p.WaitForExit() }
            } catch {}
        }
        function KiemTra-SSDWorker {
            try { return ((Get-PhysicalDisk | Where-Object DeviceId -eq 0 | Select-Object -First 1).MediaType -eq "SSD") }
            catch { return $false }
        }

        $TongBuoc = [Math]::Max(1, ($CauHinh.Values | Where-Object { $_ -eq $true }).Count)
        $Buoc = 0

        # ---- DỌN DẸP ----
        if ($CauHinh.BackupReg) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Sao lưu Registry..." "Đang sao lưu registry ra Desktop..."
            Chay-LenhWorker "reg.exe" "export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion `"$($CauHinh.SaoLuuReg)`" /y"
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Sao lưu Registry..." "✓ Đã sao lưu: $($CauHinh.SaoLuuReg)"
        }
        if ($CauHinh.WinUpdate) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa bộ nhớ đệm Windows Update..."
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Chay-LenhWorker "cmd.exe" "/c rmdir /s /q `"C:\Windows\SoftwareDistribution\Download`""
            Start-Service wuauserv -ErrorAction SilentlyContinue
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Đã xóa xong SoftwareDistribution"
        }
        if ($CauHinh.WinUpdate2) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Tắt dịch vụ Windows Update..."
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Set-Service  wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Windows Update đã được tắt"
        }
        if ($CauHinh.DellSA) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa rác Dell SARemediation..."
            Chay-LenhWorker "cmd.exe" "/c rmdir /s /q `"C:\ProgramData\Dell\SARemediation\SystemRepair`""
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Đã dọn sạch rác Dell"
        }
        if ($CauHinh.Temp) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa các thư mục Temp & Prefetch..."
            Chay-LenhWorker "cmd.exe" "/c rmdir /s /q `"$env:TEMP`""
            Chay-LenhWorker "cmd.exe" "/c rmdir /s /q `"C:\Windows\Temp`""
            Chay-LenhWorker "cmd.exe" "/c rmdir /s /q `"C:\Windows\Prefetch`""
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Đã làm sạch Temp & Prefetch"
        }
        if ($CauHinh.RecycleBin) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Làm trống Thùng Rác..."
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Thùng rác đã dọn sạch"
        }
        if ($CauHinh.ThumbCache) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa Thumbnail Cache..."
            Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Xóa xong Thumbnail Cache"
        }
        if ($CauHinh.FontCache) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Làm mới Font Cache..."
            Stop-Service FontCache -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:windir\ServiceProfiles\LocalService\AppData\Local\FontCache*" -Force -ErrorAction SilentlyContinue
            Start-Service FontCache -ErrorAction SilentlyContinue
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Đã làm mới Font Cache"
        }
        if ($CauHinh.EventLog) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa nhật ký Event Log..."
            Get-EventLog -LogName * -ErrorAction SilentlyContinue | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Đã xóa sạch Event Log"
        }
        if ($CauHinh.DISM) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Xử lý hệ thống..." "Đang chạy DISM dọn WinSxS (Có thể mất 5-15 phút)..."
            Chay-LenhWorker "dism.exe" "/online /Cleanup-Image /StartComponentCleanup /Quiet"
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Xử lý hệ thống..." "✓ Quét DISM hoàn tất"
        }
        if ($CauHinh.AppRac) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Thanh lọc..." "Gỡ bỏ các ứng dụng rác mặc định..."
            @("BingNews","BingWeather","YourPhone","GetHelp","SkypeApp","SolitaireCollection",
              "Microsoft.People","Office.OneNote","Microsoft.MicrosoftOfficeHub","Microsoft.3DBuilder",
              "Microsoft.XboxApp","Microsoft.ZuneMusic","Microsoft.ZuneVideo",
              "Microsoft.MixedReality.Portal","Microsoft.Wallet") | ForEach-Object {
                $Pkg = Get-AppxPackage -Name "*$_*" -AllUsers -ErrorAction SilentlyContinue
                if ($Pkg) {
                    $Pkg | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                    Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Thanh lọc..." "  Đã gỡ: $_"
                }
            }
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Thanh lọc..." "✓ Đã dọn xong ứng dụng rác"
        }

        # ---- TỐI ƯU ----
        if ($CauHinh.PageFile) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Cấu hình tự động dọn PageFile..."
            Sua-RegWorker "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 1
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ PageFile sẽ được xóa khi tắt máy"
        }
        if ($CauHinh.Hibern) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Vô hiệu hóa Ngủ đông (Hibernation)..."
            Chay-LenhWorker "powercfg.exe" "-h off"
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ Chế độ Ngủ đông đã tắt"
        }
        if ($CauHinh.VisualFx) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Tắt hiệu ứng chuyển động hình ảnh..."
            Sua-RegWorker "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
            Sua-RegWorker "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ Hiệu ứng Visual đã tắt"
        }
        if ($CauHinh.Prefetch) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Thiết lập lại Prefetch/Superfetch..."
            Sua-RegWorker "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 3
            Sua-RegWorker "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" 3
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ Tối ưu Prefetch/Superfetch thành công"
        }
        if ($CauHinh.NetThrot) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu mạng..." "Gỡ bỏ giới hạn băng thông..."
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" "ffffffff"
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu mạng..." "✓ Giới hạn băng thông đã được gỡ"
        }
        if ($CauHinh.TCP) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu TCP/IP..." "Tắt Nagle và tăng bộ đệm mạng..."
            $DuongDanTCP = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Sua-RegWorker $DuongDanTCP "TcpAckFrequency" 1 ; Sua-RegWorker $DuongDanTCP "TCPNoDelay" 1
            Sua-RegWorker $DuongDanTCP "DefaultTTL" 64   ; Sua-RegWorker $DuongDanTCP "EnablePMTUDiscovery" 1
            Chay-LenhWorker "netsh.exe" "int tcp set global autotuninglevel=normal"
            Chay-LenhWorker "netsh.exe" "int tcp set global chimney=enabled"
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu TCP/IP..." "✓ TCP/IP tối ưu hoàn tất"
        }
        if ($CauHinh.DNS) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu DNS..." "Tăng dung lượng DNS Cache..."
            $DuongDanDNS = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
            Sua-RegWorker $DuongDanDNS "CacheHashTableBucketSize" 1   ; Sua-RegWorker $DuongDanDNS "CacheHashTableSize" 384
            Sua-RegWorker $DuongDanDNS "MaxCacheEntryTtlLimit" 64000  ; Sua-RegWorker $DuongDanDNS "MaxSOACacheEntryTtlLimit" 301
            Chay-LenhWorker "ipconfig.exe" "/flushdns"
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu DNS..." "✓ DNS Cache đã được tăng và làm sạch"
        }
        if ($CauHinh.IRPStack) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu mạng..." "Điều chỉnh IRPStackSize..."
            Sua-RegWorker "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "IRPStackSize" 20
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu mạng..." "✓ Cấu hình IRPStackSize hoàn tất"
        }
        if ($CauHinh.SSD) {
            $Buoc++
            if (KiemTra-SSDWorker) {
                Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu SSD..." "Phát hiện SSD – Kích hoạt lệnh Re-TRIM..."
                Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
                Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" "Enable" "N" "String"
                Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu SSD..." "✓ Đã Re-TRIM & tắt tự động phân mảnh"
            } else {
                Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Kiểm tra phần cứng..." "Phát hiện HDD – bỏ qua lệnh TRIM"
            }
        }
        if ($CauHinh.NTFS) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu NTFS..." "Vô hiệu hóa ghi timestamp..."
            Chay-LenhWorker "fsutil.exe" "behavior set disablelastaccess 1"
            Chay-LenhWorker "fsutil.exe" "behavior set disable8dot3 1"
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Tối ưu NTFS..." "✓ NTFS đã được tối ưu"
        }
        if ($CauHinh.GameMode) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Gaming..." "Kích hoạt Game Mode & Hardware GPU Scheduling..."
            Sua-RegWorker "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
            Sua-RegWorker "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Gaming..." "✓ Chế độ Game Mode đã bật"
        }

        # ---- BẢO MẬT ----
        if ($CauHinh.Telemetry) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Chặn tiến trình Telemetry & DiagTrack..."
            @("DiagTrack","dmwappushservice") | ForEach-Object {
                Stop-Service $_ -Force -ErrorAction SilentlyContinue
                Set-Service  $_ -StartupType Disabled -ErrorAction SilentlyContinue
            }
            Sua-RegWorker "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                "AllowTelemetry" 0
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
            @("Microsoft Compatibility Appraiser","ProgramDataUpdater","Proxy","Consolidator","UsbCeip") | ForEach-Object {
                Get-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
            }
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Tiến trình theo dõi đã bị chặn"
        }
        if ($CauHinh.Cortana) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Vô hiệu hóa Cortana..."
            Sua-RegWorker "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"      0
            Sua-RegWorker "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"   "BingSearchEnabled" 0
            Sua-RegWorker "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"   "CortanaConsent"    0
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Cortana đã bị tắt"
        }
        if ($CauHinh.AdvApps) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Chặn quảng cáo trong hệ thống..."
            $DuongDanCDM = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Sua-RegWorker $DuongDanCDM "SystemPaneSuggestionsEnabled"    0 ; Sua-RegWorker $DuongDanCDM "SilentInstalledAppsEnabled"      0
            Sua-RegWorker $DuongDanCDM "SubscribedContent-338393Enabled" 0 ; Sua-RegWorker $DuongDanCDM "SubscribedContent-353698Enabled" 0
            Sua-RegWorker "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Quảng cáo đã bị vô hiệu hóa"
        }
        if ($CauHinh.WifiSense) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Đóng cổng WiFi Sense..."
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"            "value" 0
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" "value" 0
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ WiFi Sense đã tắt"
        }
        if ($CauHinh.DiagSvc) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Khóa các dịch vụ Diagnostic..."
            @("diagnosticshub.standardcollector.service","WerSvc","wercplsupport") | ForEach-Object {
                Stop-Service $_ -Force -ErrorAction SilentlyContinue
                Set-Service  $_ -StartupType Disabled -ErrorAction SilentlyContinue
            }
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Diagnostic Services đã dừng"
        }
        if ($CauHinh.RemoteReg) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Vô hiệu hóa Remote Registry..."
            Stop-Service RemoteRegistry -Force -ErrorAction SilentlyContinue
            Set-Service  RemoteRegistry -StartupType Disabled -ErrorAction SilentlyContinue
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Remote Registry đã khóa"
        }
        if ($CauHinh.UAC) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Hạ cấp cảnh báo UAC..."
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 0
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop"     0
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Đã hạ mức cảnh báo UAC"
        }
        if ($CauHinh.LockScreen) {
            $Buoc++
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Khởi động..." "Ẩn Lock Screen..."
            Sua-RegWorker "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"       "NoLockScreen"          1
            Sua-RegWorker "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStatusMessages" 1
            Ghi-NhatKyWorker ([int]($Buoc/$TongBuoc*100)) "Khởi động..." "✓ Đã tắt Lock Screen"
        }
       if ($CauHinh.AutoLogon) {
            $Buoc++
            $NguoiDung = $env:USERNAME
            W-Log ([int]($Buoc/$TongBuoc*100)) "Đăng nhập..." "Kiểm tra tài khoản: $NguoiDung"
            $ThongTinNguoiDung = Get-LocalUser -Name $NguoiDung -ErrorAction SilentlyContinue
            
            # Kiểm tra xem máy có thực sự KHÔNG mật khẩu không
            $KhongMatKhau = $false
            try {
                Add-Type -AssemblyName System.DirectoryServices.AccountManagement
                $NguCach = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
                $KhongMatKhau = $NguCach.ValidateCredentials($NguoiDung, "")
            } catch {}

            if ($ThongTinNguoiDung -and $KhongMatKhau -and ($ThongTinNguoiDung.PrincipalSource -ne "MicrosoftAccount")) {
                $RegDangNhap = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                
                # --- SỬA LỖI TẠI ĐÂY ---
                W-Reg $RegDangNhap "AutoAdminLogon" "1" "String"
                W-Reg $RegDangNhap "DefaultUserName" $NguoiDung "String"
                W-Reg $RegDangNhap "DefaultPassword" "" "String"
                
                # SET THÀNH 0 ĐỂ VẪN LOCK MÁY ĐƯỢC THỦ CÔNG
                W-Reg $RegDangNhap "ForceAutoLogon" "0" "String" 
                # -----------------------

                W-Log ([int]($Buoc/$TongBuoc*100)) "Đăng nhập..." "✓ Đã bật tự động đăng nhập (Vẫn có thể Lock máy)"
            } else {
                W-Log ([int]($Buoc/$TongBuoc*100)) "Đăng nhập..." "⚠ Không đủ điều kiện Auto-Logon - Đã bỏ qua"
            }
        }

        # ---- XONG ----
        $HangDoiMsg.Enqueue(@{ Type="LOG"; Pct=100; Status="✅ Hoàn tất!"; Text="══════ TẤT CẢ TÁC VỤ ĐÃ HOÀN THÀNH ══════" })
        $HangDoiMsg.Enqueue(@{ Type="DONE" })
    }

    $PS = [powershell]::Create()
    $PS.Runspace = $KhongGianChay
    $PS.AddScript($KichBanXuLy) | Out-Null
    $TienTrinhXuLy = $PS.BeginInvoke()

    # Giữ tham chiếu tránh thu gom rác bộ nhớ (GC)
    $Script:PS     = $PS
    $Script:TienTrinhXuLy = $TienTrinhXuLy
    $Script:KhongGianChay = $KhongGianChay
})

# Dọn dẹp khi đóng cửa sổ
$Window.Add_Closing({
    $UITimer.Stop()
    try { $Script:PS.Stop()  } catch {}
    try { $Script:KhongGianChay.Close() } catch {}
})

# =============================================
# HIỂN THỊ
# =============================================
$Window.ShowDialog() | Out-Null