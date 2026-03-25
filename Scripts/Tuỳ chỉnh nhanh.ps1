# ==============================================================================
# Tên công cụ: VIETTOOLBOX - TÙY CHỈNH HỆ THỐNG (V12 - SMART APP CONTROL)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Chức năng: Desktop Icons, DNS, Update, Time, Smart App Control (Win 11)
# Đặc trị: Fix dứt điểm lỗi cú pháp, Tự động quét trạng thái hệ thống
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA ADMIN ---
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 
    [System.Windows.MessageBox]::Show("Vui lòng chạy Tool với quyền Administrator!", "Thông báo")
    exit 
}

$IsWin11 = [Environment]::OSVersion.Version.Build -ge 22000

# --- GIAO DIỆN XAML WPF ---
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox" Width="1050" Height="820" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
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
                <Grid.Clip><RectangleGeometry Rect="0,0,1050,50" RadiusX="15" RadiusY="15"/></Grid.Clip>
                <TextBlock Name="TxtTitle" Text="⚙️ VIETTOOLBOX - TÙY CHỈNH HỆ THỐNG &amp; BẢO MẬT V12" Foreground="#38BDF8" FontWeight="Bold" FontSize="16" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <Button Name="BtnClose" Content="✕" Width="50" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <Grid Margin="30,75,30,25">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Margin="0,0,15,0">
                    <TextBlock Text="BIỂU TƯỢNG DESKTOP" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <UniformGrid Columns="2">
                            <CheckBox Name="ChkShowThisPC" Content="This PC" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowNetwork" Content="Network" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowControl" Content="Control Panel" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowUser" Content="User Folder" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                        </UniformGrid>
                    </Border>

                    <TextBlock Text="CÀI ĐẶT MẠNG (DNS)" Foreground="#38BDF8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkDNSGoogle" Content="DNS Google (8.8.8.8)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkDNSCloud" Content="DNS Cloudflare (1.1.1.1)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,5"/>
                            <TextBlock Text="* Tắt cả hai để dùng DNS Tự động" Foreground="#64748B" FontSize="11" Margin="55,0,0,0"/>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="GIAO DIỆN &amp; TASKBAR" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkClassicMenu" Content="Menu chuột phải Win 10" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkThisPC" Content="Mở Explorer vào This PC" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkTaskbarCenter" Content="Căn giữa Taskbar (W11)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowAllIcons" Content="Hiện tất cả icon Tray" Style="{StaticResource ToggleSwitch}" Foreground="#38BDF8"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="15,0,0,0">
                    <TextBlock Text="QUẢN LÝ THỜI GIAN" Foreground="#10B981" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkSetVNTZ" Content="Múi giờ Việt Nam (UTC+7)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,10"/>
                            <CheckBox Name="ChkTime24h" Content="Định dạng giờ 24h" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,15"/>
                            <Grid Margin="0,0,0,10">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" Margin="0,0,5,0">
                                    <TextBlock Text="Ngày (dd/MM/yyyy)" Foreground="#64748B" FontSize="11" Margin="2,0,0,2"/><TextBox Name="TxtDate" Height="28" Background="#0F172A" Foreground="White" BorderBrush="#334155" Padding="5,2" VerticalContentAlignment="Center"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" Margin="5,0,0,0">
                                    <TextBlock Text="Giờ (HH:mm:ss)" Foreground="#64748B" FontSize="11" Margin="2,0,0,2"/><TextBox Name="TxtTime" Height="28" Background="#0F172A" Foreground="White" BorderBrush="#334155" Padding="5,2" VerticalContentAlignment="Center"/>
                                </StackPanel>
                            </Grid>
                            <UniformGrid Columns="2">
                                <Button Name="BtnSetManual" Content="✍️ ĐẶT GIỜ TAY" Height="30" Background="#475569" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,5,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                                <Button Name="BtnSyncTime" Content="🔄 ĐỒNG BỘ" Height="30" Background="#10B981" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="5,0,0,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                            </UniformGrid>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="BẢO MẬT &amp; WINDOWS UPDATE" Foreground="#F59E0B" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkWinUpdate" Content="Kích hoạt Windows Update" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkSAC" Content="Smart App Control (Khuyên: Tắt)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkBitlocker" Content="Bật BitLocker (Mã hóa C:)" Style="{StaticResource ToggleSwitch}"/>
                        </StackPanel>
                    </Border>

                    <Button Name="BtnApply" Content="🚀 LƯU VÀ ÁP DỤNG" Height="60" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="18" BorderThickness="0" Cursor="Hand" Margin="0,20,0,0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></Button.Resources>
                    </Button>
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
$chkWinUpdate = $FormTuyChinh.FindName("ChkWinUpdate"); $chkSAC = $FormTuyChinh.FindName("ChkSAC"); $btnSyncTime = $FormTuyChinh.FindName("BtnSyncTime"); $btnSetManual = $FormTuyChinh.FindName("BtnSetManual")
$txtDate = $FormTuyChinh.FindName("TxtDate"); $txtTime = $FormTuyChinh.FindName("TxtTime")
$chkShowThisPC = $FormTuyChinh.FindName("ChkShowThisPC"); $chkShowNetwork = $FormTuyChinh.FindName("ChkShowNetwork"); $chkShowControl = $FormTuyChinh.FindName("ChkShowControl"); $chkShowUser = $FormTuyChinh.FindName("ChkShowUser")
$chkBitlocker = $FormTuyChinh.FindName("ChkBitlocker"); $chkThisPC = $FormTuyChinh.FindName("ChkThisPC")
$chkClassicMenu = $FormTuyChinh.FindName("ChkClassicMenu"); $chkTaskbarCenter = $FormTuyChinh.FindName("ChkTaskbarCenter"); $chkShowAllIcons = $FormTuyChinh.FindName("ChkShowAllIcons")
$chkSetVNTZ = $FormTuyChinh.FindName("ChkSetVNTZ"); $chkTime24h = $FormTuyChinh.FindName("ChkTime24h")
$chkDNSGoogle = $FormTuyChinh.FindName("ChkDNSGoogle"); $chkDNSCloud = $FormTuyChinh.FindName("ChkDNSCloud")
$txtTitle = $FormTuyChinh.FindName("TxtTitle")

if (-not $IsWin11) { 
    $txtTitle.Text = "⚙️ VIETTOOLBOX WIN 10"
    $chkClassicMenu.IsEnabled = $false; $chkTaskbarCenter.IsEnabled = $false; $chkSAC.IsEnabled = $false; $chkSAC.Content = "Smart App Control (Chỉ Win 11)"
}

# RADIO DNS
$chkDNSGoogle.Add_Checked({ $chkDNSCloud.IsChecked = $false })
$chkDNSCloud.Add_Checked({ $chkDNSGoogle.IsChecked = $false })

$FormTuyChinh.Add_MouseLeftButtonDown({ $FormTuyChinh.DragMove() })
$btnClose.Add_Click({ $FormTuyChinh.Close() })

$txtDate.Text = (Get-Date).ToString("dd/MM/yyyy")
$txtTime.Text = (Get-Date).ToString("HH:mm:ss")

# --- HÀM ĐỌC TRẠNG THÁI ---
function Doc-TrangThai {
    $kD = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    $kA = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    try {
        $chkShowThisPC.IsChecked = ((Get-ItemProperty $kD -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -ErrorAction SilentlyContinue)."{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -eq 0)
        $chkShowNetwork.IsChecked = ((Get-ItemProperty $kD -Name "{F02C1034-056E-447a-859F-370A18395C10}" -ErrorAction SilentlyContinue)."{F02C1034-056E-447a-859F-370A18395C10}" -eq 0)
        $chkShowControl.IsChecked = ((Get-ItemProperty $kD -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -ErrorAction SilentlyContinue)."{5399E694-6CD5-4b5c-B231-819A47DC248A}" -eq 0)
        $chkShowUser.IsChecked = ((Get-ItemProperty $kD -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -ErrorAction SilentlyContinue)."{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -eq 0)
        
        $chkThisPC.IsChecked = ((Get-ItemProperty $kA -Name "LaunchTo" -ErrorAction SilentlyContinue).LaunchTo -eq 1)
        $chkShowAllIcons.IsChecked = ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -ErrorAction SilentlyContinue).EnableAutoTray -eq 0)
        
        if ($IsWin11) {
            $chkTaskbarCenter.IsChecked = ((Get-ItemProperty $kA -Name "TaskbarAl" -ErrorAction SilentlyContinue).TaskbarAl -eq 1)
            $chkClassicMenu.IsChecked = Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            
            # Đọc Smart App Control (SAC)
            $sacVal = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
            if ($sacVal -eq 1 -or $sacVal -eq 2) { $chkSAC.IsChecked = $true } else { $chkSAC.IsChecked = $false }
        }

        $svcUpdate = Get-Service wuauserv -ErrorAction SilentlyContinue
        if ($svcUpdate.StartType -eq "Disabled") { $chkWinUpdate.IsChecked = $false } else { $chkWinUpdate.IsChecked = $true }
        
        $chkSetVNTZ.IsChecked = ((Get-TimeZone).Id -eq "SE Asia Standard Time")
        $chkTime24h.IsChecked = ((Get-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime").sShortTime -notmatch "tt")
        $chkBitlocker.IsChecked = ((manage-bde -status C:) -match "Protection On|Fully Encrypted")

        $dnsAddr = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses -ne $null).ServerAddresses
        if ($dnsAddr -contains "8.8.8.8") { $chkDNSGoogle.IsChecked = $true }
        elseif ($dnsAddr -contains "1.1.1.1") { $chkDNSCloud.IsChecked = $true }
    } catch {}
}

$btnSetManual.Add_Click({
    try { $mD = [DateTime]::ParseExact("$($txtDate.Text) $($txtTime.Text)", "dd/MM/yyyy HH:mm:ss", $null); Set-Date $mD; [System.Windows.MessageBox]::Show("Đã đặt giờ tay!") } catch { [System.Windows.MessageBox]::Show("Sai định dạng!") }
})

$btnSyncTime.Add_Click({
    $btnSyncTime.IsEnabled = $false
    try { Start-Service W32Time -ErrorAction SilentlyContinue; w32tm /resync /force; [System.Windows.MessageBox]::Show("Đồng bộ thành công!") } catch { [System.Windows.MessageBox]::Show("Lỗi đồng bộ!") }
    $btnSyncTime.IsEnabled = $true
})

$btnApply.Add_Click({
    $btnApply.IsEnabled = $false
    $lblTrangThai.Visibility = "Visible"; $lblTrangThai.Text = "⏳ Đang thực thi..."
    try {
        # DNS
        $adaptersActive = Get-NetAdapter | Where-Object Status -eq "Up"
        foreach ($adp in $adaptersActive) {
            if ($chkDNSGoogle.IsChecked) { Set-DnsClientServerAddress -InterfaceIndex $adp.InterfaceIndex -ServerAddresses ("8.8.8.8","8.8.4.4") }
            elseif ($chkDNSCloud.IsChecked) { Set-DnsClientServerAddress -InterfaceIndex $adp.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1") }
            else { Set-DnsClientServerAddress -InterfaceIndex $adp.InterfaceIndex -ResetServerAddresses }
        }

        # Windows Update
        if ($chkWinUpdate.IsChecked) { 
            Set-Service wuauserv -StartupType Automatic
            reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f 2>$null 
        } else { 
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue; Set-Service wuauserv -StartupType Disabled
            $regP = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; if (-not (Test-Path $regP)) { New-Item $regP -Force | Out-Null }; Set-ItemProperty $regP -Name "NoAutoUpdate" -Value 1 
        }

        # Smart App Control (Chỉ Win 11)
        if ($IsWin11) {
            if ($chkSAC.IsChecked) { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value 1 }
            else { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value 0 }
        }

        # Icons Desktop
        $regD = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
        if (-not (Test-Path $regD)) { New-Item $regD -Force | Out-Null }
        Set-ItemProperty $regD -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value (if ($chkShowThisPC.IsChecked) {0} else {1})
        Set-ItemProperty $regD -Name "{F02C1034-056E-447a-859F-370A18395C10}" -Value (if ($chkShowNetwork.IsChecked) {0} else {1})
        Set-ItemProperty $regD -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -Value (if ($chkShowControl.IsChecked) {0} else {1})
        Set-ItemProperty $regD -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value (if ($chkShowUser.IsChecked) {0} else {1})

        # Time & Region
        if ($chkSetVNTZ.IsChecked) { Set-TimeZone -Id "SE Asia Standard Time" }
        Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime" -Value (if ($chkTime24h.IsChecked) {"H:mm"} else {"h:mm tt"})

        # Explorer & Taskbar
        $regAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value (if ($chkShowAllIcons.IsChecked) {0} else {1})
        Set-ItemProperty $regAdv -Name "LaunchTo" -Value (if ($chkThisPC.IsChecked) {1} else {2})

        if ($IsWin11) {
            $regM = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            if ($chkClassicMenu.IsChecked) { if (-not (Test-Path "$regM\InprocServer32")) { New-Item "$regM\InprocServer32" -Force | Out-Null; Set-ItemProperty "$regM\InprocServer32" -Name "(Default)" -Value "" } } 
            else { if (Test-Path $regM) { Remove-Item $regM -Recurse -Force } }
            Set-ItemProperty $regAdv -Name "TaskbarAl" -Value (if ($chkTaskbarCenter.IsChecked) {1} else {0})
        }

        if ($chkBitlocker.IsChecked) { if (-not ((manage-bde -status C:) -match "Protection On|Fully Encrypted")) { Start-Process "control.exe" "/name Microsoft.BitLockerDriveEncryption" } } 
        else { manage-bde -off C: | Out-Null }

        Stop-Process -Name explorer -Force
        $lblTrangThai.Text = "✅ Đã xong!"; [System.Windows.MessageBox]::Show("Đã hoàn tất mọi thiết lập!")
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)") }
    $btnApply.IsEnabled = $true
})

Doc-TrangThai
$FormTuyChinh.ShowDialog() | Out-Null