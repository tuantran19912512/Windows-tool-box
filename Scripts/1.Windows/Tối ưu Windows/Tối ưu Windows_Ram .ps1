<#
.SYNOPSIS
    VIETTOOLBOX V4 - BẢN HOÀN THIỆN TỐI ĐA
    WPF + Runspace + Dọn dẹp sâu + Phục hồi mặc định
#>

# =============================================
# 1. KIỂM TRA QUYỀN ADMIN
# =============================================
$DuongDanKichBan = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Definition }
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$DuongDanKichBan`""
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml

# =============================================
# 2. BIẾN TOÀN CỤC
# =============================================
$Global:TepNhatKy = "$env:USERPROFILE\Desktop\VietToolbox_NhatKy_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$Global:SaoLuuReg = "$env:USERPROFILE\Desktop\VietToolbox_SaoLuuReg_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
$Global:HangDoiMsg = [System.Collections.Concurrent.ConcurrentQueue[hashtable]]::new()

# =============================================
# 3. GIAO DIỆN XAML (WPF)
# =============================================
[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="VietToolbox V4 - Tối Ưu &amp; Bảo Mật Windows"
    Height="720" Width="680" ResizeMode="CanMinimize" WindowStartupLocation="CenterScreen" Background="#111318" FontFamily="Segoe UI">

    <Window.Resources>
        <SolidColorBrush x:Key="TextPri"   Color="#E8EAED"/>
        <SolidColorBrush x:Key="TextSec"   Color="#7B8394"/>
        <SolidColorBrush x:Key="Accent"    Color="#00D26A"/>
        <SolidColorBrush x:Key="Danger"    Color="#E05252"/>

        <Style x:Key="ModernCheck" TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPri}"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,3,0,3"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border x:Name="Box" Width="16" Height="16" CornerRadius="3" Background="#1C1F27" BorderBrush="#3A3D4A" BorderThickness="1.5">
                                <Path x:Name="Check" Data="M2,8 L6,12 L14,4" Stroke="#00D26A" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Visibility="Collapsed"/>
                            </Border>
                            <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center" RecognizesAccessKey="True"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Box" Property="Background" Value="#0D2E1A"/>
                                <Setter TargetName="Box" Property="BorderBrush" Value="#00D26A"/>
                                <Setter TargetName="Check" Property="Visibility" Value="Visible"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="BtnPrimary" TargetType="Button">
            <Setter Property="Background" Value="#00D26A"/>
            <Setter Property="Foreground" Value="#0A0F0A"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>

        <Style x:Key="BtnDanger" TargetType="Button">
            <Setter Property="Background" Value="#E05252"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>

        <Style x:Key="BtnSecondary" TargetType="Button">
            <Setter Property="Background" Value="#1C1F27"/>
            <Setter Property="Foreground" Value="{StaticResource TextPri}"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderBrush" Value="#2A2D38"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="6" Padding="12,0"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>

        <Style x:Key="ModernTab" TargetType="TabItem">
            <Setter Property="Foreground" Value="#7B8394"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="Bd" Background="Transparent" BorderThickness="0,0,0,2" BorderBrush="Transparent" Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#00D26A"/>
                                <Setter Property="Foreground" Value="#00D26A"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="20,16,20,16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="120"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel>
                <TextBlock Text="VietToolbox V4" FontSize="24" FontWeight="Bold" Foreground="{StaticResource Accent}"/>
                <TextBlock Text="Hệ thống tối ưu, dọn dẹp &amp; bảo mật toàn diện" FontSize="12" Foreground="{StaticResource TextSec}" Margin="0,2,0,0"/>
            </StackPanel>
            <Border Grid.Column="1" Background="#1C1F27" CornerRadius="6" Padding="12,6" VerticalAlignment="Center">
                <StackPanel Orientation="Horizontal">
                    <Ellipse x:Name="ChamTrangThai" Width="8" Height="8" Fill="#4A5060" VerticalAlignment="Center"/>
                    <TextBlock x:Name="ChuTrangThai" Text="Sẵn sàng" Foreground="{StaticResource TextSec}" FontSize="12" Margin="8,0,0,0" VerticalAlignment="Center"/>
                </StackPanel>
            </Border>
        </Grid>

        <Grid Grid.Row="1" Margin="0,0,0,15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <ProgressBar x:Name="ThanhTienTrinh" Height="6" Background="#1C1F27" Foreground="#00D26A" BorderThickness="0" Value="0">
                <ProgressBar.Template><ControlTemplate TargetType="ProgressBar"><Border CornerRadius="3" Background="{TemplateBinding Background}" ClipToBounds="True"><Border x:Name="PART_Indicator" HorizontalAlignment="Left" CornerRadius="3" Background="{TemplateBinding Foreground}"/></Border></ControlTemplate></ProgressBar.Template>
            </ProgressBar>
            <TextBlock x:Name="ChuPhanTram" Grid.Column="1" Text="0%" Foreground="{StaticResource TextSec}" FontSize="11" Margin="10,0,0,0" VerticalAlignment="Center"/>
        </Grid>

        <TabControl Grid.Row="2" x:Name="CacThe" Background="Transparent" BorderThickness="0" Padding="0" Margin="0,0,0,15">
            
            <TabItem Header="🧹 Dọn Dẹp" Style="{StaticResource ModernTab}">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <WrapPanel Orientation="Horizontal">
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="WINDOWS UPDATE" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_WinUpdate" Content="Xóa cache SoftwareDistribution" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_WinUpdate2" Content="Tắt dịch vụ Windows Update" Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="FILE RÁC &amp; CACHE" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_Temp" Content="Xóa Temp, Windows\Temp, Prefetch" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_RecycleBin" Content="Dọn Thùng Rác" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_ThumbCache" Content="Xóa Thumbnail Cache" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_FontCache" Content="Làm mới Font Cache" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="HỆ THỐNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_DISM" Content="DISM ép dọn WinSxS (rất lâu)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_EventLog" Content="Xóa Event Log hệ thống" Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="ỨNG DỤNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_AppRac" Content="Gỡ app rác (BingNews, Skype...)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_DellSA" Content="Xóa rác Dell SARemediation" Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>
                    </WrapPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="⚡ Tối Ưu" Style="{StaticResource ModernTab}">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <WrapPanel Orientation="Horizontal">
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="HỆ THỐNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_PageFile" Content="Tối ưu PageFile (xóa khi tắt)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_Hibern" Content="Tắt Hibernation – cứu SSD" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_VisualFx" Content="Phẳng hóa hiệu ứng Visual" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_Prefetch" Content="Tối ưu Prefetch / Superfetch" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="MẠNG" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_NetThrot" Content="Bỏ giới hạn băng thông mạng" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_TCP" Content="Tối ưu TCP/IP (tắt Nagle)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_DNS" Content="Tăng DNS Cache" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_IRPStack" Content="Tăng IRPStackSize" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="Ổ ĐĨA" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_SSD" Content="Re-TRIM nếu phát hiện SSD" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_NTFS" Content="Tối ưu NTFS (tắt ghi timestamp)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="GAMING" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_GameMode" Content="Game Mode &amp; GPU Scheduling" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                    </WrapPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="🔒 Bảo Mật" Style="{StaticResource ModernTab}">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <WrapPanel Orientation="Horizontal">
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="THEO DÕI &amp; QUẢNG CÁO" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_Telemetry" Content="Tắt Telemetry &amp; DiagTrack" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_Cortana" Content="Tắt Cortana" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_AdvApps" Content="Tắt quảng cáo Start &amp; App" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_WifiSense" Content="Tắt WiFi Sense" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="DỊCH VỤ" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_DiagSvc" Content="Tắt Diagnostic Services" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_RemoteReg" Content="Tắt Remote Registry" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,10,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="ĐĂNG NHẬP" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_LockScreen" Content="Tắt Lock Screen" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_AutoLogon" Content="Auto-Logon (Bỏ qua Welcome)" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                                <CheckBox x:Name="chk_UAC" Content="Hạ UAC (ít hỏi quyền hơn)" Style="{StaticResource ModernCheck}" IsChecked="False"/>
                            </StackPanel>
                        </Border>
                        <Border Background="#1C1F27" CornerRadius="8" Margin="0,0,0,10" Padding="14,10" Width="295">
                            <StackPanel>
                                <TextBlock Text="SAO LƯU" Foreground="#7B8394" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                <CheckBox x:Name="chk_BackupReg" Content="Backup Registry trước khi sửa" Style="{StaticResource ModernCheck}" IsChecked="True"/>
                            </StackPanel>
                        </Border>
                    </WrapPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>

        <Grid Grid.Row="3" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="2*"/>
                <ColumnDefinition Width="10"/>
                <ColumnDefinition Width="100"/>
                <ColumnDefinition Width="10"/>
                <ColumnDefinition Width="100"/>
                <ColumnDefinition Width="10"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="NutBatDau" Grid.Column="0" Content="▶  BẮT ĐẦU TỐI ƯU" Style="{StaticResource BtnPrimary}"/>
            <Button x:Name="NutChonTatCa" Grid.Column="2" Content="✔ Chọn Hết" Style="{StaticResource BtnSecondary}"/>
            <Button x:Name="NutBoChonTatCa" Grid.Column="4" Content="✖ Bỏ Chọn" Style="{StaticResource BtnSecondary}"/>
            <Button x:Name="NutPhucHoi" Grid.Column="6" Content="↺ PHỤC HỒI" Style="{StaticResource BtnDanger}"/>
        </Grid>

        <Border Grid.Row="4" BorderBrush="#2A2D38" BorderThickness="1" CornerRadius="8" ClipToBounds="True">
            <Grid>
                <ListBox x:Name="HopNhatKy" Background="#0C0E13" BorderThickness="0" FontFamily="Consolas" FontSize="11" Foreground="#4FC3F7" Padding="4" ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>
                <TextBlock x:Name="ChuGoiY" Text="Nhật ký hệ thống sẽ hiển thị tại đây..." Foreground="#3A4050" FontFamily="Consolas" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# =============================================
# 4. NẠP XAML & GẮN BIẾN ĐIỀU KHIỂN
# =============================================
$Reader = [System.Xml.XmlNodeReader]::new($XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

function Lay-Ctrl($Ten) { $Window.FindName($Ten) }
$NutBatDau = Lay-Ctrl "NutBatDau"; $NutPhucHoi = Lay-Ctrl "NutPhucHoi"
$NutChonTatCa = Lay-Ctrl "NutChonTatCa"; $NutBoChonTatCa = Lay-Ctrl "NutBoChonTatCa"
$ThanhTienTrinh = Lay-Ctrl "ThanhTienTrinh"; $ChuPhanTram = Lay-Ctrl "ChuPhanTram"
$ChuTrangThai = Lay-Ctrl "ChuTrangThai"; $ChamTrangThai = Lay-Ctrl "ChamTrangThai"
$HopNhatKy = Lay-Ctrl "HopNhatKy"; $ChuGoiY = Lay-Ctrl "ChuGoiY"; $CacThe = Lay-Ctrl "CacThe"

$chk = @{}
@("WinUpdate","WinUpdate2","Temp","RecycleBin","ThumbCache","FontCache","DISM","EventLog","AppRac","DellSA","PageFile","Hibern","VisualFx","Prefetch","NetThrot","TCP","DNS","IRPStack","SSD","NTFS","GameMode","Telemetry","Cortana","AdvApps","WifiSense","DiagSvc","RemoteReg","LockScreen","AutoLogon","UAC","BackupReg") | ForEach-Object { $chk[$_] = Lay-Ctrl "chk_$_" }

function Lay-HopChonTrongThe {
    $TheDangChon = $CacThe.SelectedItem; $DanhSach = @(); $HangDoi = [System.Collections.Queue]::new()
    $HangDoi.Enqueue($TheDangChon)
    while ($HangDoi.Count -gt 0) {
        $PhanTu = $HangDoi.Dequeue()
        if ($PhanTu -is [System.Windows.Controls.CheckBox]) { $DanhSach += $PhanTu }
        if ($PhanTu -is [System.Windows.Controls.Panel] -or $PhanTu -is [System.Windows.Controls.Border] -or $PhanTu -is [System.Windows.Controls.TabItem] -or $PhanTu -is [System.Windows.Controls.ScrollViewer]) {
            $Con = $null
            if ($PhanTu -is [System.Windows.Controls.Border]) { $Con = @($PhanTu.Child) }
            elseif ($PhanTu -is [System.Windows.Controls.ScrollViewer]) { $Con = @($PhanTu.Content) }
            elseif ($PhanTu -is [System.Windows.Controls.TabItem]) { $Con = @($PhanTu.Content) }
            else { $Con = $PhanTu.Children }
            if ($Con) { foreach ($C in $Con) { if ($C) { $HangDoi.Enqueue($C) } } }
        }
    }
    return $DanhSach
}
$NutChonTatCa.Add_Click({ Lay-HopChonTrongThe | ForEach-Object { $_.IsChecked = $true } })
$NutBoChonTatCa.Add_Click({ Lay-HopChonTrongThe | ForEach-Object { $_.IsChecked = $false } })

# =============================================
# 5. WORKER SCRIPT (CHẠY NGẦM ĐA LUỒNG)
# =============================================
$WorkerScript = {
    param($CheDo)
    
    function W-Log($Pct, $Status, $Text) { $HangDoiMsg.Enqueue(@{ Type="LOG"; Pct=[Math]::Min($Pct,100); Status=$Status; Text=$Text }) }
    function W-Reg($Path, $Name, $Val, $Type = "DWord") {
        try { if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }; Set-ItemProperty -Path $Path -Name $Name -Value $Val -Type $Type -Force | Out-Null } catch { $HangDoiMsg.Enqueue(@{ Type="ERROR"; Text="Reg: $Path\$Name – $_" }) }
    }
    function W-Exec($Cmd, $Args) { try { $p = Start-Process -FilePath $Cmd -ArgumentList $Args -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue; if ($p) { $p.WaitForExit() } } catch {} }
    function KiemTra-SSDWorker { try { return ((Get-PhysicalDisk | Where-Object DeviceId -eq 0 | Select-Object -First 1).MediaType -eq "SSD") } catch { return $false } }

    if ($CheDo -eq "OPTIMIZE") {
        $TongBuoc = [Math]::Max(1, ($CauHinh.Values | Where-Object { $_ -eq $true }).Count); $Buoc = 0

        if ($CauHinh.BackupReg) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Sao lưu Registry..." "Đang sao lưu registry..."
            W-Exec "reg.exe" "export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion `"$($CauHinh.SaoLuuReg)`" /y"
            W-Log ([int]($Buoc/$TongBuoc*100)) "Sao lưu Registry..." "✓ Đã sao lưu: $($CauHinh.SaoLuuReg)"
        }
        if ($CauHinh.WinUpdate) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa cache Windows Update..."
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            W-Exec "cmd.exe" "/c rmdir /s /q `"C:\Windows\SoftwareDistribution\Download`""
            Start-Service wuauserv -ErrorAction SilentlyContinue
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Xóa xong SoftwareDistribution"
        }
        if ($CauHinh.WinUpdate2) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Tắt dịch vụ Windows Update..."
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue; Set-Service wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Windows Update đã tắt"
        }
        if ($CauHinh.DellSA) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa rác Dell SARemediation..."
            W-Exec "cmd.exe" "/c rmdir /s /q `"C:\ProgramData\Dell\SARemediation\SystemRepair`""
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Xóa xong rác Dell"
        }
        if ($CauHinh.Temp) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa Temp & Prefetch..."
            W-Exec "cmd.exe" "/c rmdir /s /q `"$env:TEMP`""; W-Exec "cmd.exe" "/c rmdir /s /q `"C:\Windows\Temp`""; W-Exec "cmd.exe" "/c rmdir /s /q `"C:\Windows\Prefetch`""
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Xóa xong Temp & Prefetch"
        }
        if ($CauHinh.RecycleBin) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Dọn Thùng Rác..."
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Thùng rác sạch"
        }
        if ($CauHinh.ThumbCache) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa Thumbnail Cache..."
            Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Xóa xong Thumbnail Cache"
        }
        if ($CauHinh.FontCache) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Làm mới Font Cache..."
            Stop-Service FontCache -Force -ErrorAction SilentlyContinue; Remove-Item "$env:windir\ServiceProfiles\LocalService\AppData\Local\FontCache*" -Force -ErrorAction SilentlyContinue; Start-Service FontCache -ErrorAction SilentlyContinue
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Font Cache làm mới xong"
        }
        if ($CauHinh.EventLog) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "Xóa Event Log..."
            Get-EventLog -LogName * -ErrorAction SilentlyContinue | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }
            W-Log ([int]($Buoc/$TongBuoc*100)) "Dọn dẹp..." "✓ Event Log đã xóa"
        }
        if ($CauHinh.DISM) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "DISM (Cực nặng)..." "Chạy DISM ResetBase ép dọn WinSxS (Mất 5-20 phút)..."
            W-Exec "dism.exe" "/online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet"
            W-Log ([int]($Buoc/$TongBuoc*100)) "DISM..." "✓ DISM hoàn tất, giải phóng tối đa"
        }
        if ($CauHinh.AppRac) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Debloat..." "Gỡ ứng dụng rác..."
            @("BingNews","BingWeather","YourPhone","GetHelp","SkypeApp","SolitaireCollection","Microsoft.People","Office.OneNote","Microsoft.MicrosoftOfficeHub","Microsoft.3DBuilder","Microsoft.XboxApp","Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.MixedReality.Portal","Microsoft.Wallet") | ForEach-Object {
                $Pkg = Get-AppxPackage -Name "*$_*" -AllUsers -ErrorAction SilentlyContinue
                if ($Pkg) { $Pkg | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; W-Log ([int]($Buoc/$TongBuoc*100)) "Debloat..." "  Gỡ: $_" }
            }
            W-Log ([int]($Buoc/$TongBuoc*100)) "Debloat..." "✓ Gỡ xong ứng dụng rác"
        }
        if ($CauHinh.PageFile) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Cấu hình PageFile xóa khi tắt máy..."
            W-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 1
            W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ Xong PageFile"
        }
        if ($CauHinh.Hibern) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Tắt Hibernation..."
            W-Exec "powercfg.exe" "-h off"
            W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ Hibernation tắt"
        }
        if ($CauHinh.VisualFx) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Phẳng hóa hiệu ứng Visual..."
            W-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
            W-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](144,20,7,128,18,0,0,0)) "Binary"
            W-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
            W-Reg "HKCU:\Software\Microsoft\Windows\DWM" "Composition" 0
            W-Reg "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0
            W-Reg "HKCU:\Software\Microsoft\Windows\DWM" "AlwaysHibernateThumbnails" 0
            W-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
            W-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
            W-Exec "cmd.exe" "/c RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters"
            W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ Giao diện phẳng hóa (Max Performance)"
        }
        if ($CauHinh.Prefetch) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "Cấu hình Prefetch/Superfetch..."
            W-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 3; W-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" 3
            W-Log ([int]($Buoc/$TongBuoc*100)) "Tối ưu..." "✓ Xong Prefetch"
        }
        if ($CauHinh.NetThrot) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "Bỏ giới hạn băng thông..."
            W-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" "ffffffff"; W-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
            W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "✓ Đã gỡ giới hạn"
        }
        if ($CauHinh.TCP) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "Tối ưu TCP/IP (Tắt Nagle)..."
            $TCP = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            W-Reg $TCP "TcpAckFrequency" 1 ; W-Reg $TCP "TCPNoDelay" 1; W-Reg $TCP "DefaultTTL" 64 ; W-Reg $TCP "EnablePMTUDiscovery" 1
            W-Exec "netsh.exe" "int tcp set global autotuninglevel=normal"; W-Exec "netsh.exe" "int tcp set global chimney=enabled"
            W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "✓ TCP/IP tối ưu"
        }
        if ($CauHinh.DNS) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "Tăng DNS Cache..."
            $DNS = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
            W-Reg $DNS "CacheHashTableBucketSize" 1; W-Reg $DNS "CacheHashTableSize" 384; W-Reg $DNS "MaxCacheEntryTtlLimit" 64000; W-Reg $DNS "MaxSOACacheEntryTtlLimit" 301
            W-Exec "ipconfig.exe" "/flushdns"
            W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "✓ DNS Cache tăng & flush"
        }
        if ($CauHinh.IRPStack) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "Tăng IRPStackSize..."
            W-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "IRPStackSize" 20
            W-Log ([int]($Buoc/$TongBuoc*100)) "Mạng..." "✓ IRPStackSize = 20"
        }
        if ($CauHinh.SSD) {
            $Buoc++; if (KiemTra-SSDWorker) {
                W-Log ([int]($Buoc/$TongBuoc*100)) "SSD..." "Phát hiện SSD – Re-TRIM..."
                Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
                W-Reg "HKLM:\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" "Enable" "N" "String"
                W-Log ([int]($Buoc/$TongBuoc*100)) "SSD..." "✓ Re-TRIM & tắt Defrag"
            } else { W-Log ([int]($Buoc/$TongBuoc*100)) "Ổ đĩa..." "HDD – bỏ qua TRIM" }
        }
        if ($CauHinh.NTFS) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "NTFS..." "Tắt ghi timestamp..."
            W-Exec "fsutil.exe" "behavior set disablelastaccess 1"; W-Exec "fsutil.exe" "behavior set disable8dot3 1"
            W-Log ([int]($Buoc/$TongBuoc*100)) "NTFS..." "✓ NTFS tối ưu"
        }
        if ($CauHinh.GameMode) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Gaming..." "Bật Game Mode & GPU Scheduling..."
            W-Reg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
            W-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
            W-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8; W-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
            W-Log ([int]($Buoc/$TongBuoc*100)) "Gaming..." "✓ Game Mode bật"
        }
        if ($CauHinh.Telemetry) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Tắt Telemetry & DiagTrack..."
            @("DiagTrack","dmwappushservice") | ForEach-Object { Stop-Service $_ -Force -ErrorAction SilentlyContinue; Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue }
            W-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0; W-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
            @("Microsoft Compatibility Appraiser","ProgramDataUpdater","Proxy","Consolidator","UsbCeip") | ForEach-Object { Get-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue }
            W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Telemetry tắt"
        }
        if ($CauHinh.Cortana) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Tắt Cortana..."
            W-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0; W-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0; W-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
            W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Cortana tắt"
        }
        if ($CauHinh.AdvApps) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Tắt quảng cáo..."
            $CDM = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            W-Reg $CDM "SystemPaneSuggestionsEnabled" 0 ; W-Reg $CDM "SilentInstalledAppsEnabled" 0; W-Reg $CDM "SubscribedContent-338393Enabled" 0 ; W-Reg $CDM "SubscribedContent-353698Enabled" 0
            W-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
            W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Quảng cáo tắt"
        }
        if ($CauHinh.WifiSense) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Tắt WiFi Sense..."
            W-Reg "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" "value" 0; W-Reg "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" "value" 0
            W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ WiFi Sense tắt"
        }
        if ($CauHinh.DiagSvc) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Tắt Diagnostic Services..."
            @("diagnosticshub.standardcollector.service","WerSvc","wercplsupport") | ForEach-Object { Stop-Service $_ -Force -ErrorAction SilentlyContinue; Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue }
            W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Diagnostic tắt"
        }
        if ($CauHinh.RemoteReg) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Tắt Remote Registry..."
            Stop-Service RemoteRegistry -Force -ErrorAction SilentlyContinue; Set-Service RemoteRegistry -StartupType Disabled -ErrorAction SilentlyContinue
            W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ Remote Registry tắt"
        }
        if ($CauHinh.UAC) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "Hạ UAC..."
            W-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 0; W-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" 0
            W-Log ([int]($Buoc/$TongBuoc*100)) "Bảo mật..." "✓ UAC hạ"
        }
        if ($CauHinh.LockScreen) {
            $Buoc++; W-Log ([int]($Buoc/$TongBuoc*100)) "Boot..." "Tắt Lock Screen..."
            W-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1; W-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStatusMessages" 1
            W-Log ([int]($Buoc/$TongBuoc*100)) "Boot..." "✓ Lock Screen tắt"
        }
        if ($CauHinh.AutoLogon) {
            $Buoc++; $U = $env:USERNAME
            W-Log ([int]($Buoc/$TongBuoc*100)) "Đăng nhập..." "Check Auto-Logon: $U"
            $UI = Get-LocalUser -Name $U -ErrorAction SilentlyContinue; $NoPS = $false
            try { Add-Type -AssemblyName System.DirectoryServices.AccountManagement; $Ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine); $NoPS = $Ctx.ValidateCredentials($U, "") } catch {}
            if ($UI -and $NoPS -and ($UI.PrincipalSource -ne "MicrosoftAccount")) {
                $RL = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                W-Reg $RL "AutoAdminLogon" "1" "String"; W-Reg $RL "DefaultUserName" $U "String"; W-Reg $RL "DefaultPassword" "" "String"
                W-Reg $RL "ForceAutoLogon" "0" "String" # <--- Fix kẹt Lock Máy
                W-Log ([int]($Buoc/$TongBuoc*100)) "Đăng nhập..." "✓ Auto-Logon bật (Vẫn Lock được máy)"
            } else { W-Log ([int]($Buoc/$TongBuoc*100)) "Đăng nhập..." "⚠ Có mật khẩu/Microsoft Acc - Bỏ qua" }
        }
        $HangDoiMsg.Enqueue(@{ Type="LOG"; Pct=100; Status="✅ Hoàn tất!"; Text="══════ TẤT CẢ TÁC VỤ HOÀN THÀNH ══════" })
    } 
    else {
        # ---- LOGIC PHỤC HỒI MẶC ĐỊNH ----
        W-Log 10 "Phục hồi..." "Bật lại dịch vụ Update & Telemetry..."
        Set-Service wuauserv -StartupType Automatic -ErrorAction SilentlyContinue; Set-Service DiagTrack -StartupType Automatic -ErrorAction SilentlyContinue
        
        W-Log 30 "Phục hồi..." "Tắt Auto-Logon..."
        $RL = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        W-Reg $RL "AutoAdminLogon" "0" "String"; W-Reg $RL "ForceAutoLogon" "0" "String"
        
        W-Log 60 "Phục hồi..." "Bật lại Hiệu ứng Visual & Ngủ đông..."
        W-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 0
        W-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "1" "String"
        W-Exec "powercfg.exe" "-h on"
        
        W-Log 80 "Phục hồi..." "Khôi phục băng thông mạng..."
        W-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10
        
        W-Log 100 "Phục hồi xong!" "Hệ thống đã trả về mặc định!"
    }
    $HangDoiMsg.Enqueue(@{ Type="DONE" })
}

# =============================================
# 6. HÀM CHẠY (DISPATCH SANG RUNSPACE)
# =============================================
$RunWorker = {
    param($Mode)
    $CauHinh = @{}; foreach ($Key in $chk.Keys) { $CauHinh[$Key] = $chk[$Key].IsChecked }; $CauHinh["SaoLuuReg"] = $Global:SaoLuuReg
    $NutBatDau.IsEnabled = $NutPhucHoi.IsEnabled = $NutChonTatCa.IsEnabled = $NutBoChonTatCa.IsEnabled = $false
    $NutBatDau.Content = "⏳ Đang chạy..."; $HopNhatKy.Items.Clear(); $ChuGoiY.Visibility = "Collapsed"
    $ThanhTienTrinh.Value = 0; $ChuPhanTram.Text = "0%"; $ChuTrangThai.Text = "Đang tải dữ liệu..."; $ChamTrangThai.Fill = [System.Windows.Media.Brushes]::Orange
    
    $UITimer.Start()
    $RS = [runspacefactory]::CreateRunspace(); $RS.ApartmentState = "STA"; $RS.Open()
    $RS.SessionStateProxy.SetVariable("HangDoiMsg", $Global:HangDoiMsg); $RS.SessionStateProxy.SetVariable("CauHinh", $CauHinh)
    $PS = [powershell]::Create().AddScript($WorkerScript).AddArgument($Mode); $PS.Runspace = $RS; $Handle = $PS.BeginInvoke()
    $Script:PS = $PS; $Script:Handle = $Handle; $Script:RS = $RS
}

$NutBatDau.Add_Click({ &$RunWorker "OPTIMIZE" })
$NutPhucHoi.Add_Click({ 
    $Ask = [System.Windows.MessageBox]::Show("Khôi phục các thiết lập quan trọng về mặc định?", "Xác nhận Phục hồi", "YesNo", "Question")
    if ($Ask -eq "Yes") { &$RunWorker "RESTORE" }
})

# =============================================
# 7. TIMER CẬP NHẬT GIAO DIỆN
# =============================================
$UITimer = New-Object System.Windows.Threading.DispatcherTimer
$UITimer.Interval = [TimeSpan]::FromMilliseconds(50)
$UITimer.Add_Tick({
    $Msg = $null
    while ($Global:HangDoiMsg.TryDequeue([ref]$Msg)) {
        if ($Msg.Type -eq "LOG") {
            $ThanhTienTrinh.Value = $Msg.Pct; $ChuPhanTram.Text = "$($Msg.Pct)%"; $ChuTrangThai.Text = $Msg.Status
            $LogDong = "[$([datetime]::Now.ToString('HH:mm:ss'))] $($Msg.Text)"
            $HopNhatKy.Items.Add($LogDong) | Out-Null; $HopNhatKy.ScrollIntoView($HopNhatKy.Items[-1])
            Add-Content -Path $Global:TepNhatKy -Value $LogDong -Encoding UTF8
        }
        if ($Msg.Type -eq "DONE") {
            $UITimer.Stop(); $ThanhTienTrinh.Value = 100; $ChuPhanTram.Text = "100%"; $ChuTrangThai.Text = "Hoàn tất!"; $ChamTrangThai.Fill = [System.Windows.Media.Brushes]::LimeGreen
            $NutBatDau.Content = "▶ BẮT ĐẦU TỐI ƯU"
            $NutBatDau.IsEnabled = $NutPhucHoi.IsEnabled = $NutChonTatCa.IsEnabled = $NutBoChonTatCa.IsEnabled = $true
            [System.Windows.MessageBox]::Show("Xử lý hoàn tất!", "Thông báo")
        }
        if ($Msg.Type -eq "ERROR") { $HopNhatKy.Items.Add("[LỖI] $($Msg.Text)") | Out-Null }
    }
})

$Window.Add_Closing({ $UITimer.Stop(); try { $Script:PS.Stop() } catch {}; try { $Script:RS.Close() } catch {} })

# =============================================
# 8. HIỂN THỊ CỬA SỔ
# =============================================
$Window.ShowDialog() | Out-Null