# ==============================================================================
# Tên công cụ: TÙY CHỈNH HỆ THỐNG & WINDOWS UPDATE (V9.2 - FIXED STATUS)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc điểm: Hàm Doc-TrangThai quét sạch 100% Registry, Nút gạt nhảy chuẩn
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 
    [System.Windows.MessageBox]::Show("Vui lòng chạy Tool với quyền Administrator!", "Thông báo")
    exit 
}

$IsWin11 = [Environment]::OSVersion.Version.Build -ge 22000
$BrushConv = New-Object System.Windows.Media.BrushConverter

# --- GIAO DIỆN XAML WPF ---
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox" Width="1000" Height="680" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="ToggleSwitch" TargetType="CheckBox">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid Background="Transparent">
                            <StackPanel Orientation="Horizontal">
                                <Grid Width="45" Height="22" Margin="0,0,10,0">
                                    <Border x:Name="Bg" Background="#334155" CornerRadius="11"/>
                                    <Ellipse x:Name="Dot" Fill="White" Width="16" Height="16" HorizontalAlignment="Left" Margin="3,0,0,0">
                                        <Ellipse.RenderTransform><TranslateTransform X="0"/></Ellipse.RenderTransform>
                                    </Ellipse>
                                </Grid>
                                <TextBlock Text="{TemplateBinding Content}" VerticalAlignment="Center" Foreground="#E2E8F0" FontSize="14"/>
                            </StackPanel>
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
                <Grid.Clip><RectangleGeometry Rect="0,0,1000,50" RadiusX="15" RadiusY="15"/></Grid.Clip>
                <TextBlock Name="TxtTitle" Text="⚙️ VIETTOOLBOX - TÙY CHỈNH HỆ THỐNG &amp; WINDOWS UPDATE" Foreground="#38BDF8" FontWeight="Bold" FontSize="16" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <Button Name="BtnClose" Content="✕" Width="50" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <Grid Margin="30,75,30,25">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Margin="0,0,15,0">
                    <TextBlock Text="BIỂU TƯỢNG DESKTOP" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,12"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <UniformGrid Columns="2">
                            <CheckBox Name="ChkShowThisPC" Content="This PC" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowNetwork" Content="Network" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowControl" Content="Control Panel" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowUser" Content="User Folder" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                        </UniformGrid>
                    </Border>

                    <TextBlock Text="GIAO DIỆN &amp; TASKBAR" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,12"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkClassicMenu" Content="Menu chuột phải Win 10" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkThisPC" Content="Mở Explorer vào This PC" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkTaskbarCenter" Content="Căn giữa Taskbar (W11)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowAllIcons" Content="Hiện tất cả icon Tray" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12" Foreground="#38BDF8"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="15,0,0,0">
                    <TextBlock Text="QUẢN LÝ WINDOWS UPDATE" Foreground="#F59E0B" FontWeight="Bold" FontSize="13" Margin="0,0,0,12"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20" BorderBrush="#F59E0B" BorderThickness="1">
                        <StackPanel>
                            <CheckBox Name="ChkWinUpdate" Content="Kích hoạt Windows Update" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,5" FontWeight="Bold"/>
                            <TextBlock Text="Tắt sẽ chặn vĩnh viễn Services &amp; Registry." Foreground="#64748B" FontSize="11" Margin="55,0,0,5"/>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="THỜI GIAN &amp; KHÁC" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,12"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkSetVNTZ" Content="Múi giờ Việt Nam (UTC+7)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkTime24h" Content="Định dạng giờ 24h" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,15"/>
                            <Button Name="BtnSyncTime" Content="🔄 ĐỒNG BỘ GIỜ HỆ THỐNG" Height="35" Background="#475569" Foreground="White" BorderThickness="0" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                            <Separator Background="#334155" Margin="0,15,0,15"/>
                            <CheckBox Name="ChkBitlocker" Content="Bật BitLocker (Mã hóa C:)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,5"/>
                        </StackPanel>
                    </Border>

                    <Button Name="BtnApply" Content="🚀 LƯU VÀ ÁP DỤNG" Height="60" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="18" BorderThickness="0" Cursor="Hand" Margin="0,25,0,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></Button.Resources></Button>
                    <TextBlock Name="LblTrangThai" Text="Sẵn sàng." Foreground="#10B981" FontSize="13" HorizontalAlignment="Center" Margin="0,10,0,0" Visibility="Hidden"/>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

try { $FormTuyChinh = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($inputXML)))) } catch { [System.Windows.MessageBox]::Show("Lỗi XAML: $($_.Exception.Message)"); exit }

# Kết nối UI
$btnClose = $FormTuyChinh.FindName("BtnClose"); $btnApply = $FormTuyChinh.FindName("BtnApply"); $lblTrangThai = $FormTuyChinh.FindName("LblTrangThai")
$chkWinUpdate = $FormTuyChinh.FindName("ChkWinUpdate"); $btnSyncTime = $FormTuyChinh.FindName("BtnSyncTime")
$chkShowThisPC = $FormTuyChinh.FindName("ChkShowThisPC"); $chkShowNetwork = $FormTuyChinh.FindName("ChkShowNetwork")
$chkShowControl = $FormTuyChinh.FindName("ChkShowControl"); $chkShowUser = $FormTuyChinh.FindName("ChkShowUser")
$chkBitlocker = $FormTuyChinh.FindName("ChkBitlocker"); $chkThisPC = $FormTuyChinh.FindName("ChkThisPC")
$chkClassicMenu = $FormTuyChinh.FindName("ChkClassicMenu"); $chkTaskbarCenter = $FormTuyChinh.FindName("ChkTaskbarCenter"); $chkShowAllIcons = $FormTuyChinh.FindName("ChkShowAllIcons")
$chkSetVNTZ = $FormTuyChinh.FindName("ChkSetVNTZ"); $chkTime24h = $FormTuyChinh.FindName("ChkTime24h")
$txtTitle = $FormTuyChinh.FindName("TxtTitle")

if (-not $IsWin11) { $txtTitle.Text = "⚙️ TÙY CHỈNH WINDOWS 10"; $chkClassicMenu.IsEnabled = $false; $chkTaskbarCenter.IsEnabled = $false }

$FormTuyChinh.Add_MouseLeftButtonDown({ $FormTuyChinh.DragMove() })
$btnClose.Add_Click({ $FormTuyChinh.Close() })

# --- HÀM ĐỌC TRẠNG THÁI CHUẨN XÁC 100% ---
function Doc-TrangThai {
    $keyDesktop = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    $keyAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $keyAU = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

    try {
        # 1. Desktop Icons (0 = Hiện, 1 = Ẩn)
        $chkShowThisPC.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -ErrorAction SilentlyContinue)."{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -eq 0)
        $chkShowNetwork.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{F02C1034-056E-447a-859F-370A18395C10}" -ErrorAction SilentlyContinue)."{F02C1034-056E-447a-859F-370A18395C10}" -eq 0)
        $chkShowControl.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -ErrorAction SilentlyContinue)."{5399E694-6CD5-4b5c-B231-819A47DC248A}" -eq 0)
        $chkShowUser.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -ErrorAction SilentlyContinue)."{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -eq 0)

        # 2. Explorer & Taskbar
        $chkThisPC.IsChecked = ((Get-ItemProperty $keyAdv -Name "LaunchTo" -ErrorAction SilentlyContinue).LaunchTo -eq 1)
        $chkShowAllIcons.IsChecked = ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -ErrorAction SilentlyContinue).EnableAutoTray -eq 0)
        
        if ($IsWin11) {
            $chkTaskbarCenter.IsChecked = ((Get-ItemProperty $keyAdv -Name "TaskbarAl" -ErrorAction SilentlyContinue).TaskbarAl -eq 1)
            $chkClassicMenu.IsChecked = Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
        }

        # 3. Windows Update
        $svc = Get-Service wuauserv -ErrorAction SilentlyContinue
        $regUpdate = (Get-ItemProperty -Path $keyAU -Name "NoAutoUpdate" -ErrorAction SilentlyContinue).NoAutoUpdate
        if ($svc.StartType -eq "Disabled" -or $regUpdate -eq 1) { $chkWinUpdate.IsChecked = $false } else { $chkWinUpdate.IsChecked = $true }

        # 4. Thời gian
        $chkSetVNTZ.IsChecked = ((Get-TimeZone).Id -eq "SE Asia Standard Time")
        $timeFormat = (Get-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime").sShortTime
        $chkTime24h.IsChecked = ($timeFormat -notmatch "tt")

        # 5. BitLocker
        $chkBitlocker.IsChecked = ((manage-bde -status C:) -match "Protection On|Fully Encrypted")
    } catch {}
}

$btnSyncTime.Add_Click({
    $btnSyncTime.IsEnabled = $false
    try { Start-Service W32Time -ErrorAction SilentlyContinue; w32tm /resync /force; [System.Windows.MessageBox]::Show("Đã đồng bộ giờ thành công!") } catch {}
    $btnSyncTime.IsEnabled = $true
})

$btnApply.Add_Click({
    $btnApply.IsEnabled = $false
    $lblTrangThai.Visibility = "Visible"; $lblTrangThai.Text = "⏳ Đang thực thi cấu hình..."
    try {
        # Update
        if ($chkWinUpdate.IsChecked) { Set-Service wuauserv -StartupType Automatic; reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f 2>$null } 
        else { Stop-Service wuauserv -Force -ErrorAction SilentlyContinue; Set-Service wuauserv -StartupType Disabled; $pAU = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; if (!(Test-Path $pAU)) { New-Item $pAU -Force | Out-Null }; Set-ItemProperty $pAU -Name "NoAutoUpdate" -Value 1 }

        # Desktop Icons
        $kD = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
        if (!(Test-Path $kD)) { New-Item $kD -Force | Out-Null }
        Set-ItemProperty $kD -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value (if ($chkShowThisPC.IsChecked) {0} else {1})
        Set-ItemProperty $kD -Name "{F02C1034-056E-447a-859F-370A18395C10}" -Value (if ($chkShowNetwork.IsChecked) {0} else {1})
        Set-ItemProperty $kD -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -Value (if ($chkShowControl.IsChecked) {0} else {1})
        Set-ItemProperty $kD -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value (if ($chkShowUser.IsChecked) {0} else {1})

        # Time
        if ($chkSetVNTZ.IsChecked) { Set-TimeZone -Id "SE Asia Standard Time" }
        $vT = if ($chkTime24h.IsChecked) { "H:mm" } else { "h:mm tt" }
        Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime" -Value $vT

        # Explorer & Taskbar
        $kAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value (if ($chkShowAllIcons.IsChecked) {0} else {1})
        Set-ItemProperty $kAdv -Name "LaunchTo" -Value (if ($chkThisPC.IsChecked) {1} else {2})

        if ($IsWin11) {
            $kM = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            if ($chkClassicMenu.IsChecked) { if (!(Test-Path "$kM\InprocServer32")) { New-Item "$kM\InprocServer32" -Force | Out-Null; Set-ItemProperty "$kM\InprocServer32" -Name "(Default)" -Value "" } } 
            else { if (Test-Path $kM) { Remove-Item $kM -Recurse -Force } }
            Set-ItemProperty $kAdv -Name "TaskbarAl" -Value (if ($chkTaskbarCenter.IsChecked) {1} else {0})
        }

        if ($chkBitlocker.IsChecked) { if (!((manage-bde -status C:) -match "Protection On|Fully Encrypted")) { Start-Process "control.exe" "/name Microsoft.BitLockerDriveEncryption" } } 
        else { manage-bde -off C: | Out-Null }

        Stop-Process -Name explorer -Force
        $lblTrangThai.Text = "✅ Đã xong!"; [System.Windows.MessageBox]::Show("Hoàn tất!", "VietToolbox")
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)") }
    $btnApply.IsEnabled = $true
})

Doc-TrangThai
$FormTuyChinh.ShowDialog() | Out-Null