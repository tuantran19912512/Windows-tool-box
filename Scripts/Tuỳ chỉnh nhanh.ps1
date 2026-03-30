# ==============================================================================
# Tên công cụ: VIETTOOLBOX - TÙY CHỈNH HỆ THỐNG (V19.12 - NEW LAYOUT)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Layout Mới: Tắt/Ẩn <Nút Gạt> Bật/Hiện (Giữ nguyên toàn bộ logic gốc)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin -eq $false) { 
    [System.Windows.MessageBox]::Show("Sếp Tuấn ơi, chuột phải chọn Run as Administrator nhé!", "Thiếu quyền", 0, 48)
    exit 
}

$IsWin11 = [Environment]::OSVersion.Version.Build -ge 22000

# --- GIAO DIỆN XAML WPF (NEW LAYOUT) ---
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox" Width="1150" Height="950" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" Language="vi-VN">
    <Window.Resources>
        <Style x:Key="ToggleSwitch" TargetType="CheckBox">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid Background="Transparent" Margin="0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="200"/> <ColumnDefinition Width="65"/>  <ColumnDefinition Width="*"/>   </Grid.ColumnDefinitions>
                            
                            <TextBlock Grid.Column="0" Text="{TemplateBinding Tag}" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#94A3B8" FontSize="13" Margin="0,0,10,0" TextWrapping="Wrap"/>
                            
                            <Grid Grid.Column="1" Width="45" Height="22" HorizontalAlignment="Left">
                                <Border x:Name="Bg" Background="#334155" CornerRadius="11"/>
                                <Ellipse x:Name="Dot" Fill="White" Width="16" Height="16" HorizontalAlignment="Left" Margin="3,0,0,0">
                                    <Ellipse.RenderTransform><TranslateTransform X="0"/></Ellipse.RenderTransform>
                                </Ellipse>
                            </Grid>
                            
                            <TextBlock Grid.Column="2" Text="{TemplateBinding Content}" HorizontalAlignment="Left" VerticalAlignment="Center" Foreground="#E2E8F0" FontSize="13" TextWrapping="Wrap"/>
                        </Grid>
                        
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#3B82F6"/>
                                <Trigger.EnterActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Dot" Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" To="23" Duration="0:0:0.15"/></Storyboard></BeginStoryboard></Trigger.EnterActions>
                                <Trigger.ExitActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Dot" Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" To="0" Duration="0:0:0.15"/></Storyboard></BeginStoryboard></Trigger.ExitActions>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Grid Height="50" VerticalAlignment="Top" Background="#1E293B">
                <Grid.Clip><RectangleGeometry Rect="0,0,1150,50" RadiusX="15" RadiusY="15"/></Grid.Clip>
                <TextBlock Name="TxtTitle" Text="⚙️ VIETTOOLBOX - TÙY CHỈNH HỆ THỐNG V19.12" Foreground="#38BDF8" FontWeight="Bold" FontSize="16" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <Button Name="BtnClose" Content="✕" Width="50" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <Grid Margin="30,75,30,25">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Margin="0,0,15,0">
                    <TextBlock Text="BIỂU TƯỢNG DESKTOP" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkShowThisPC" Tag="Ẩn This PC" Content="Hiện This PC ra màn hình" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkShowNetwork" Tag="Ẩn Mạng (Network)" Content="Hiện Mạng (Network)" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkShowControl" Tag="Ẩn Control Panel" Content="Hiện Control Panel" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkShowUser" Tag="Ẩn Thư mục User" Content="Hiện Thư mục User" Style="{StaticResource ToggleSwitch}"/>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="CÀI ĐẶT MẠNG (DNS) - ÁP DỤNG NGAY" Foreground="#38BDF8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkDNSGoogle" Tag="DNS Tự động (DHCP)" Content="Khóa DNS Google (8.8.8.8)" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkDNSCloud" Tag="DNS Tự động (DHCP)" Content="Khóa DNS Cloudflare (1.1.1.1)" Style="{StaticResource ToggleSwitch}"/>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="GIAO DIỆN &amp; TASKBAR" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkDarkMode" Tag="Giao diện Sáng (Light)" Content="Giao diện Tối (Dark Mode)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12" Foreground="#F59E0B" FontWeight="Bold"/>
                            <CheckBox Name="ChkWidgets" Tag="Ẩn Widgets (Thời tiết)" Content="Hiện Widgets trên Taskbar" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkSearchIcon" Tag="Tắt ô Search Taskbar" Content="Hiện biểu tượng Search (Icon nhỏ)" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkClassicMenu" Tag="Dùng Menu Win 11" Content="Trở về Menu Win 10" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkThisPC" Tag="Mở vào Quick Access" Content="Mở Explorer vào thẳng This PC" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkTaskbarCenter" Tag="Taskbar lệch Trái" Content="Căn giữa Taskbar" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkShowAllIcons" Tag="Giấu bớt Icon góc phải" Content="Hiện tất cả Icon dưới khay hệ thống" Style="{StaticResource ToggleSwitch}"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="15,0,0,0">
                    <TextBlock Text="QUẢN LÝ THỜI GIAN" Foreground="#10B981" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkSetVNTZ" Tag="Dùng Múi giờ hiện tại" Content="Ép Múi giờ Việt Nam (UTC+7)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,5"/>
                            <CheckBox Name="ChkDateDDMM" Tag="Dùng Tháng/Ngày/Năm" Content="Định dạng Ngày/Tháng/Năm (VN)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,5"/>
                            <CheckBox Name="ChkTime24h" Tag="Dùng Giờ 12h (AM/PM)" Content="Định dạng giờ 24h" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,15"/>
                            
                            <Grid Margin="0,0,0,10">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" Margin="0,0,5,0">
                                    <TextBlock Text="Ngày (dd/MM/yyyy)" Foreground="#64748B" FontSize="11" Margin="0,0,0,2"/>
                                    <DatePicker Name="DpDate" Height="26" BorderBrush="#334155" SelectedDateFormat="Short"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" Margin="5,0,0,0">
                                    <TextBlock Text="Giờ (HH:mm:ss)" Foreground="#64748B" FontSize="11" Margin="0,0,0,2"/>
                                    <TextBox Name="TxtTime" Height="26" Background="#0F172A" Foreground="White" BorderBrush="#334155" Padding="5,0" VerticalContentAlignment="Center"/>
                                </StackPanel>
                            </Grid>
                            
                            <UniformGrid Columns="2">
                                <Button Name="BtnSetManual" Content="✍️ Lưu giờ thủ công" Height="30" Background="#475569" Foreground="White" BorderThickness="0" Margin="0,0,5,0" Cursor="Hand"/>
                                <Button Name="BtnSyncTime" Content="🔄 ĐỒNG BỘ INTERNET" Height="30" Background="#10B981" Foreground="White" BorderThickness="0" Margin="5,0,0,0" Cursor="Hand"/>
                            </UniformGrid>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="BẢO MẬT &amp; UPDATE - ÁP DỤNG NGAY" Foreground="#F59E0B" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkDefender" Tag="BẬT Windows Defender" Content="TẮT Defender (Diệt Virus thời gian thực)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12" Foreground="#EF4444" FontWeight="Bold"/>
                            <CheckBox Name="ChkWinUpdate" Tag="TẮT Update (Khóa Cập Nhật)" Content="BẬT Update (Cho phép Cập Nhật)" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkSAC" Tag="Tắt Smart App Control" Content="Bật Smart App Control" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkWPP" Tag="Bật WPP (Chuẩn Bảo mật mới)" Content="TẮT WPP (Cho phép kết nối Máy in cũ)" Style="{StaticResource ToggleSwitch}"/>
                            <CheckBox Name="ChkBitlocker" Tag="Đóng Bitlocker" Content="Mở bảng điều khiển mã hóa ổ đĩa (C:)" Style="{StaticResource ToggleSwitch}"/>
                        </StackPanel>
                    </Border>

                    <Border Background="#020617" CornerRadius="10" Padding="15" Margin="0,20,0,0">
                        <StackPanel>
                            <TextBlock Name="LblTrangThai" Text="⚡ Sẵn sàng. Các tùy chọn sẽ được lưu ngay khi bạn gạt công tắc." Foreground="#38BDF8" FontSize="13" HorizontalAlignment="Center" FontWeight="Bold" TextWrapping="Wrap" Margin="0,0,0,15"/>
                            <Button Name="BtnRestartExplorer" Content="🔄 KHỞI ĐỘNG LẠI EXPLORER ĐỂ CẬP NHẬT GIAO DIỆN" Height="45" Background="#F43F5E" Foreground="White" FontWeight="Bold" FontSize="14" BorderThickness="0" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                            </Button>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$Form = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($inputXML))))

# KẾT NỐI BIẾN UI
$btnClose = $Form.FindName("BtnClose"); $btnRestartExplorer = $Form.FindName("BtnRestartExplorer"); $lblTrangThai = $Form.FindName("LblTrangThai")
$chkWinUpdate = $Form.FindName("ChkWinUpdate"); $chkSAC = $Form.FindName("ChkSAC"); $chkWPP = $Form.FindName("ChkWPP")
$chkDefender = $Form.FindName("ChkDefender")
$btnSyncTime = $Form.FindName("BtnSyncTime"); $btnSetManual = $Form.FindName("BtnSetManual")
$dpDate = $Form.FindName("DpDate"); $txtTime = $Form.FindName("TxtTime")
$chkShowThisPC = $Form.FindName("ChkShowThisPC"); $chkShowNetwork = $Form.FindName("ChkShowNetwork"); $chkShowControl = $Form.FindName("ChkShowControl"); $chkShowUser = $Form.FindName("ChkShowUser")
$chkBitlocker = $Form.FindName("ChkBitlocker"); $chkThisPC = $Form.FindName("ChkThisPC")
$chkWidgets = $Form.FindName("ChkWidgets"); $chkSearchIcon = $Form.FindName("ChkSearchIcon"); $chkDarkMode = $Form.FindName("ChkDarkMode")
$chkClassicMenu = $Form.FindName("ChkClassicMenu"); $chkTaskbarCenter = $Form.FindName("ChkTaskbarCenter"); $chkShowAllIcons = $Form.FindName("ChkShowAllIcons")
$chkSetVNTZ = $Form.FindName("ChkSetVNTZ"); $chkTime24h = $Form.FindName("ChkTime24h"); $chkDateDDMM = $Form.FindName("ChkDateDDMM")
$chkDNSGoogle = $Form.FindName("ChkDNSGoogle"); $chkDNSCloud = $Form.FindName("ChkDNSCloud")
$txtTitle = $Form.FindName("TxtTitle")

# Tính năng Win 11 Only
if ($IsWin11 -eq $false) { 
    $txtTitle.Text = "⚙️ VIETTOOLBOX WIN 10 (REAL-TIME)"
    $chkClassicMenu.IsEnabled = $false; $chkTaskbarCenter.IsEnabled = $false; $chkSAC.IsEnabled = $false; $chkWPP.IsEnabled = $false
    $chkWidgets.IsEnabled = $false; $chkSearchIcon.IsEnabled = $false
}

$Form.Add_MouseLeftButtonDown({ $Form.DragMove() })
$btnClose.Add_Click({ $Form.Close() })

$dpDate.SelectedDate = (Get-Date)
$txtTime.Text = (Get-Date).ToString("HH:mm:ss")

# HÀM CẬP NHẬT TRẠNG THÁI UI
function Ghi-TrangThai($ThongBao, $MauSac = "#10B981") {
    $lblTrangThai.Text = $ThongBao
    $lblTrangThai.Foreground = $MauSac
}

# --- HÀM ĐỌC TRẠNG THÁI BAN ĐẦU ---
function Doc-TrangThai {
    $kD = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    $kA = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $kTheme = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    try {
        $chkShowThisPC.IsChecked = ((Get-ItemProperty $kD -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -ErrorAction SilentlyContinue)."{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -eq 0)
        $chkShowNetwork.IsChecked = ((Get-ItemProperty $kD -Name "{F02C1034-056E-447a-859F-370A18395C10}" -ErrorAction SilentlyContinue)."{F02C1034-056E-447a-859F-370A18395C10}" -eq 0)
        $chkShowControl.IsChecked = ((Get-ItemProperty $kD -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -ErrorAction SilentlyContinue)."{5399E694-6CD5-4b5c-B231-819A47DC248A}" -eq 0)
        $chkShowUser.IsChecked = ((Get-ItemProperty $kD -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -ErrorAction SilentlyContinue)."{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -eq 0)
        $chkThisPC.IsChecked = ((Get-ItemProperty $kA -Name "LaunchTo" -ErrorAction SilentlyContinue).LaunchTo -eq 1)
        $chkShowAllIcons.IsChecked = ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -ErrorAction SilentlyContinue).EnableAutoTray -eq 0)
        
        $isLight = (Get-ItemProperty $kTheme -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme
        $chkDarkMode.IsChecked = ($isLight -eq 0)

        $def = Get-MpPreference -ErrorAction SilentlyContinue
        if ($def) { $chkDefender.IsChecked = ($def.DisableRealtimeMonitoring -eq $true) }

        if ($IsWin11) {
            $chkWidgets.IsChecked = ((Get-ItemProperty $kA -Name "TaskbarDa" -ErrorAction SilentlyContinue).TaskbarDa -eq 1)
            $searchMode = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue).SearchboxTaskbarMode
            $chkSearchIcon.IsChecked = ($searchMode -ne 0)
            $chkTaskbarCenter.IsChecked = ((Get-ItemProperty $kA -Name "TaskbarAl" -ErrorAction SilentlyContinue).TaskbarAl -eq 1)
            $chkClassicMenu.IsChecked = Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            $sac = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
            $chkSAC.IsChecked = ($sac -eq 1 -or $sac -eq 2)
            $wppVal = (Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\Printers" -Name "ConfigureWindowsProtectedPrintMode" -ErrorAction SilentlyContinue).ConfigureWindowsProtectedPrintMode
            $chkWPP.IsChecked = ($wppVal -eq 0 -or $wppVal -eq $null)
        }

        $svc = Get-Service wuauserv -ErrorAction SilentlyContinue
        $chkWinUpdate.IsChecked = ($svc.StartType -ne "Disabled")
        $chkSetVNTZ.IsChecked = ((Get-TimeZone).Id -eq "SE Asia Standard Time")
        $chkTime24h.IsChecked = ((Get-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime").sShortTime -notmatch "tt")
        $chkDateDDMM.IsChecked = ((Get-ItemProperty "HKCU:\Control Panel\International" -Name "sShortDate").sShortDate -eq "dd/MM/yyyy")
        
        $dnsA = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null -and $_.InterfaceAlias -notmatch "vEthernet|Loopback|Virtual" }).ServerAddresses
        $chkDNSGoogle.IsChecked = ($dnsA -contains "8.8.8.8")
        $chkDNSCloud.IsChecked = ($dnsA -contains "1.1.1.1")
        
        $chkBitlocker.IsChecked = ((manage-bde -status C: -ErrorAction SilentlyContinue) -match "Protection On")
    } catch { }
}
Doc-TrangThai

# ==============================================================================
# SỰ KIỆN CLICK (GHI TRỰC TIẾP VÀO HỆ THỐNG)
# ==============================================================================

# --- ĐẶC TRỊ DEFENDER BỊ TAMPER PROTECTION ---
$chkDefender.Add_Click({
    $mongMuon = if ($chkDefender.IsChecked) {$true} else {$false}
    Set-MpPreference -DisableRealtimeMonitoring $mongMuon -ErrorAction SilentlyContinue
    $docLai = Get-MpPreference -ErrorAction SilentlyContinue
    
    if ($docLai -and $docLai.DisableRealtimeMonitoring -ne $mongMuon) {
        [System.Windows.MessageBox]::Show("Windows đã chặn thao tác này! Bạn phải tắt tính năng 'Tamper Protection' (Bảo vệ chống giả mạo) trong Windows Security trước khi dùng công cụ này để tắt Defender.", "Bị từ chối quyền", 0, 48)
        Start-Process "windowsdefender://threatsettings"
        $chkDefender.IsChecked = $docLai.DisableRealtimeMonitoring
        Ghi-TrangThai "❌ Lỗi: Thao tác bị Tamper Protection vô hiệu hóa." "#EF4444"
    } else {
        Ghi-TrangThai "✅ Đã thay đổi trạng thái Windows Defender thành công."
    }
})

# --- NHÓM BIỂU TƯỢNG DESKTOP ---
function Set-DesktopIcon($Name, $Guid, $IsChecked) {
    $regD = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    if (!(Test-Path $regD)) { New-Item $regD -Force | Out-Null }
    $val = if ($IsChecked) {0} else {1}
    New-ItemProperty -Path $regD -Name $Guid -Value $val -PropertyType DWord -Force | Out-Null
    Ghi-TrangThai "✅ Đã lưu cấu hình $Name. Bấm Khởi động lại Explorer để cập nhật màn hình."
}
$chkShowThisPC.Add_Click({ Set-DesktopIcon "This PC" "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" $this.IsChecked })
$chkShowNetwork.Add_Click({ Set-DesktopIcon "Network" "{F02C1034-056E-447a-859F-370A18395C10}" $this.IsChecked })
$chkShowControl.Add_Click({ Set-DesktopIcon "Control Panel" "{5399E694-6CD5-4b5c-B231-819A47DC248A}" $this.IsChecked })
$chkShowUser.Add_Click({ Set-DesktopIcon "User Folder" "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" $this.IsChecked })

# --- NHÓM DNS ---
function Apply-DNS($Dns1, $Dns2) {
    $ads = Get-NetAdapter | Where-Object Status -eq "Up"
    foreach ($ad in $ads) { Set-DnsClientServerAddress -InterfaceIndex $ad.InterfaceIndex -ServerAddresses ($Dns1, $Dns2) }
}
function Reset-DNS {
    $ads = Get-NetAdapter | Where-Object Status -eq "Up"
    foreach ($ad in $ads) { Set-DnsClientServerAddress -InterfaceIndex $ad.InterfaceIndex -ResetServerAddresses }
}
$chkDNSGoogle.Add_Click({
    if ($this.IsChecked) { $chkDNSCloud.IsChecked = $false; Apply-DNS "8.8.8.8" "8.8.4.4"; Ghi-TrangThai "✅ Đã áp dụng DNS Google cho toàn bộ thẻ mạng." } 
    else { Reset-DNS; Ghi-TrangThai "✅ Đã trả về DNS Tự động (DHCP)." }
})
$chkDNSCloud.Add_Click({
    if ($this.IsChecked) { $chkDNSGoogle.IsChecked = $false; Apply-DNS "1.1.1.1" "1.0.0.1"; Ghi-TrangThai "✅ Đã áp dụng DNS Cloudflare cho toàn bộ thẻ mạng." } 
    else { Reset-DNS; Ghi-TrangThai "✅ Đã trả về DNS Tự động (DHCP)." }
})

# --- NHÓM GIAO DIỆN & TASKBAR ---
$chkDarkMode.Add_Click({
    $kTheme = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (!(Test-Path $kTheme)) { New-Item $kTheme -Force | Out-Null }
    $val = if ($this.IsChecked) {0} else {1}
    New-ItemProperty -Path $kTheme -Name "AppsUseLightTheme" -Value $val -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $kTheme -Name "SystemUsesLightTheme" -Value $val -PropertyType DWord -Force | Out-Null
    Ghi-TrangThai "✅ Đã chuyển đổi Giao diện Sáng/Tối."
})

$chkWidgets.Add_Click({
    $val = if ($this.IsChecked) {1} else {0}
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value $val -PropertyType DWord -Force | Out-Null
    Ghi-TrangThai "✅ Đã điều chỉnh hiển thị Widgets thời tiết (Cần Restart Explorer)."
})

$chkSearchIcon.Add_Click({
    $regS = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (!(Test-Path $regS)) { New-Item $regS -Force | Out-Null }
    $val = if ($this.IsChecked) {1} else {0}
    New-ItemProperty -Path $regS -Name "SearchboxTaskbarMode" -Value $val -PropertyType DWord -Force | Out-Null
    Ghi-TrangThai "✅ Đã điều chỉnh hiển thị ô Search (Cần Restart Explorer để áp dụng)."
})

$chkClassicMenu.Add_Click({
    $regM = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
    if ($this.IsChecked) { if (!(Test-Path "$regM\InprocServer32")) { New-Item "$regM\InprocServer32" -Force | Out-Null; Set-ItemProperty "$regM\InprocServer32" -Name "(Default)" -Value "" } }
    else { if (Test-Path $regM) { Remove-Item $regM -Recurse -Force } }
    Ghi-TrangThai "✅ Đã đổi Menu Win. Bấm Khởi động lại Explorer để thấy thay đổi."
})
$chkTaskbarCenter.Add_Click({
    $val = if ($this.IsChecked) {1} else {0}
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value $val -PropertyType DWord -Force | Out-Null
    Ghi-TrangThai "✅ Đã chỉnh vị trí Taskbar. Bấm Khởi động lại Explorer để thay đổi."
})
$chkThisPC.Add_Click({
    $val = if ($this.IsChecked) {1} else {2}
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value $val -PropertyType DWord -Force | Out-Null
    Ghi-TrangThai "✅ Đã cấu hình Explorer mở thẳng vào This PC."
})
$chkShowAllIcons.Add_Click({
    $val = if ($this.IsChecked) {0} else {1}
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value $val -PropertyType DWord -Force | Out-Null
    Ghi-TrangThai "✅ Đã chỉnh cấu hình Icon khay hệ thống."
})

# --- NHÓM THỜI GIAN ---
$chkSetVNTZ.Add_Click({
    if ($this.IsChecked) { Set-TimeZone -Id "SE Asia Standard Time"; Ghi-TrangThai "✅ Đã ép múi giờ hệ thống về Việt Nam (UTC+7)." }
})
$chkDateDDMM.Add_Click({
    $val = if ($this.IsChecked) {"dd/MM/yyyy"} else {"M/d/yyyy"}
    Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortDate" -Value $val
    Ghi-TrangThai "✅ Đã đổi định dạng Ngày (Cần Restart Explorer để cập nhật dưới Taskbar)."
})
$chkTime24h.Add_Click({
    $val = if ($this.IsChecked) {"H:mm"} else {"h:mm tt"}
    Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime" -Value $val
    Ghi-TrangThai "✅ Đã đổi định dạng Giờ (Cần Restart Explorer để cập nhật dưới Taskbar)."
})
$btnSetManual.Add_Click({
    try { 
        $ngayChon = $dpDate.SelectedDate.ToString("dd/MM/yyyy")
        $mD = [DateTime]::ParseExact("$ngayChon $($txtTime.Text)", "dd/MM/yyyy HH:mm:ss", $null)
        Set-Date $mD
        Ghi-TrangThai "✅ Đã cập nhật giờ thủ công!" 
    } catch { 
        Ghi-TrangThai "❌ Lỗi: Vui lòng nhập đúng định dạng Giờ (HH:mm:ss)!" "#EF4444" 
    }
})
$btnSyncTime.Add_Click({
    try { Start-Service W32Time; w32tm /resync /force; Ghi-TrangThai "✅ Đồng bộ giờ từ Server Internet thành công!" } catch { Ghi-TrangThai "❌ Lỗi: Không thể kết nối với Time Server!" "#EF4444" }
})

# --- NHÓM BẢO MẬT & UPDATE ---
$chkWinUpdate.Add_Click({
    if ($this.IsChecked) { 
        Set-Service wuauserv -StartupType Automatic
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f 2>$null 
        Ghi-TrangThai "✅ Đã MỞ khóa Windows Update."
    } else { 
        Stop-Service wuauserv -Force; Set-Service wuauserv -StartupType Disabled
        $rP = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; if (!(Test-Path $rP)) { New-Item $rP -Force | Out-Null }; Set-ItemProperty $rP -Name "NoAutoUpdate" -Value 1 
        Ghi-TrangThai "✅ Đã TẮT Cứu cứng Windows Update."
    }
})
$chkSAC.Add_Click({
    if ($IsWin11) { 
        $val = if ($this.IsChecked) {1} else {0}
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value $val -PropertyType DWord -Force | Out-Null
        Ghi-TrangThai "✅ Đã cấu hình Smart App Control." 
    }
})
$chkWPP.Add_Click({
    if ($IsWin11) {
        $regW = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers"; if (!(Test-Path $regW)) { New-Item $regW -Force | Out-Null }
        $val = if ($this.IsChecked) {0} else {1}
        New-ItemProperty -Path $regW -Name "ConfigureWindowsProtectedPrintMode" -Value $val -PropertyType DWord -Force | Out-Null
        Restart-Service spooler -Force
        Ghi-TrangThai "✅ Đã cấu hình và khởi động lại dịch vụ Máy in (Print Spooler)."
    }
})
$chkBitlocker.Add_Click({
    Start-Process "control" -ArgumentList "/name Microsoft.BitLockerDriveEncryption"
    $this.IsChecked = -not $this.IsChecked 
    Ghi-TrangThai "✅ Đã mở bảng điều khiển Mã hóa ổ đĩa (BitLocker)."
})

# --- NÚT RESET EXPLORER TỔNG LỰC ---
$btnRestartExplorer.Add_Click({
    $lblTrangThai.Text = "⏳ Đang làm mới hệ thống..."
    Stop-Process -Name explorer -Force
    Start-Sleep -Seconds 1
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Ghi-TrangThai "✅ Đã làm mới giao diện và các định dạng ngày/giờ thành công!"
})

$Form.ShowDialog() | Out-Null