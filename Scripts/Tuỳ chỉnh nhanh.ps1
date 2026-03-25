# ==============================================================================
# Tên công cụ: VIETTOOLBOX - TÙY CHỈNH HỆ THỐNG (V19.1 - PRECISION DNS)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc trị: Lỗi dò sai trạng thái DNS, Hiện đầy đủ mục Máy in
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin -eq $false) { 
    [System.Windows.MessageBox]::Show("Tuấn ơi, chuột phải chọn Run as Administrator nhé!")
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
                <TextBlock Name="TxtTitle" Text="⚙️ VIETTOOLBOX - TÙY CHỈNH HỆ THỐNG V19.1" Foreground="#38BDF8" FontWeight="Bold" FontSize="16" VerticalAlignment="Center" Margin="20,0,0,0"/>
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
                        </StackPanel>
                    </Border>

                    <TextBlock Text="GIAO DIỆN &amp; TASKBAR" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkClassicMenu" Content="Menu Win 10" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkThisPC" Content="Mở Explorer vào This PC" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkTaskbarCenter" Content="Căn giữa Taskbar - Tắt về bên trái" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkShowAllIcons" Content="Hiện icon Tray" Style="{StaticResource ToggleSwitch}" Foreground="#38BDF8"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="15,0,0,0">
                    <TextBlock Text="QUẢN LÝ THỜI GIAN" Foreground="#10B981" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkSetVNTZ" Content="Múi giờ VN (UTC+7)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,10"/>
                            <CheckBox Name="ChkTime24h" Content="Định dạng giờ 24h" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,15"/>
                            <Grid Margin="0,0,0,10">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" Margin="0,0,5,0">
                                    <TextBlock Text="Ngày (dd/MM/yyyy)" Foreground="#64748B" FontSize="11"/><TextBox Name="TxtDate" Height="25" Background="#0F172A" Foreground="White" BorderBrush="#334155"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" Margin="5,0,0,0">
                                    <TextBlock Text="Giờ (HH:mm:ss)" Foreground="#64748B" FontSize="11"/><TextBox Name="TxtTime" Height="25" Background="#0F172A" Foreground="White" BorderBrush="#334155"/>
                                </StackPanel>
                            </Grid>
                            <UniformGrid Columns="2">
                                <Button Name="BtnSetManual" Content="✍️ ĐẶT TAY" Height="28" Background="#475569" Foreground="White" BorderThickness="0" Margin="0,0,5,0"/>
                                <Button Name="BtnSyncTime" Content="🔄 ĐỒNG BỘ" Height="28" Background="#10B981" Foreground="White" BorderThickness="0" Margin="5,0,0,0"/>
                            </UniformGrid>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="BẢO MẬT &amp; UPDATE" Foreground="#F59E0B" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="10" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkWinUpdate" Content="Kích hoạt Update" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkSAC" Content="Smart App Control" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkWPP" Content="Hỗ trợ máy in cũ (Tắt WPP)" Style="{StaticResource ToggleSwitch}" Margin="0,0,0,12" Foreground="#38BDF8" FontWeight="Bold"/>
                            <CheckBox Name="ChkBitlocker" Content="Bật BitLocker (C:)" Style="{StaticResource ToggleSwitch}"/>
                        </StackPanel>
                    </Border>

                    <Button Name="BtnApply" Content="🚀 LƯU VÀ ÁP DỤNG" Height="60" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="18" BorderThickness="0" Cursor="Hand" Margin="0,20,0,0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                    <TextBlock Name="LblTrangThai" Text="Sẵn sàng." Foreground="#10B981" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0" Visibility="Hidden"/>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$Form = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($inputXML))))

# Kết nối UI
$btnClose = $Form.FindName("BtnClose"); $btnApply = $Form.FindName("BtnApply"); $lblTrangThai = $Form.FindName("LblTrangThai")
$chkWinUpdate = $Form.FindName("ChkWinUpdate"); $chkSAC = $Form.FindName("ChkSAC"); $chkWPP = $Form.FindName("ChkWPP")
$btnSyncTime = $Form.FindName("BtnSyncTime"); $btnSetManual = $Form.FindName("BtnSetManual")
$txtDate = $Form.FindName("TxtDate"); $txtTime = $Form.FindName("TxtTime")
$chkShowThisPC = $Form.FindName("ChkShowThisPC"); $chkShowNetwork = $Form.FindName("ChkShowNetwork"); $chkShowControl = $Form.FindName("ChkShowControl"); $chkShowUser = $Form.FindName("ChkShowUser")
$chkBitlocker = $Form.FindName("ChkBitlocker"); $chkThisPC = $Form.FindName("ChkThisPC")
$chkClassicMenu = $Form.FindName("ChkClassicMenu"); $chkTaskbarCenter = $Form.FindName("ChkTaskbarCenter"); $chkShowAllIcons = $Form.FindName("ChkShowAllIcons")
$chkSetVNTZ = $Form.FindName("ChkSetVNTZ"); $chkTime24h = $Form.FindName("ChkTime24h")
$chkDNSGoogle = $Form.FindName("ChkDNSGoogle"); $chkDNSCloud = $Form.FindName("ChkDNSCloud")
$txtTitle = $Form.FindName("TxtTitle")

if ($IsWin11 -eq $false) { 
    $txtTitle.Text = "⚙️ VIETTOOLBOX WIN 10"
    $chkClassicMenu.IsEnabled = $false; $chkTaskbarCenter.IsEnabled = $false; $chkSAC.IsEnabled = $false; $chkWPP.IsEnabled = $false 
}

$chkDNSGoogle.Add_Checked({ $chkDNSCloud.IsChecked = $false })
$chkDNSCloud.Add_Checked({ $chkDNSGoogle.IsChecked = $false })
$Form.Add_MouseLeftButtonDown({ $Form.DragMove() })
$btnClose.Add_Click({ $Form.Close() })

$txtDate.Text = (Get-Date).ToString("dd/MM/yyyy")
$txtTime.Text = (Get-Date).ToString("HH:mm:ss")

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
            $sac = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
            $chkSAC.IsChecked = ($sac -eq 1 -or $sac -eq 2)
            $wppVal = (Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\Printers" -Name "ConfigureWindowsProtectedPrintMode" -ErrorAction SilentlyContinue).ConfigureWindowsProtectedPrintMode
            $chkWPP.IsChecked = ($wppVal -eq 0 -or $wppVal -eq $null)
        }

        $svc = Get-Service wuauserv -ErrorAction SilentlyContinue
        $chkWinUpdate.IsChecked = ($svc.StartType -ne "Disabled")
        $chkSetVNTZ.IsChecked = ((Get-TimeZone).Id -eq "SE Asia Standard Time")
        $chkTime24h.IsChecked = ((Get-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime").sShortTime -notmatch "tt")
        
        # --- QUÉT DNS CHÍNH XÁC ---
        $dnsA = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null -and $_.InterfaceAlias -notmatch "vEthernet|Loopback|Virtual" }).ServerAddresses
        $chkDNSGoogle.IsChecked = ($dnsA -contains "8.8.8.8")
        $chkDNSCloud.IsChecked = ($dnsA -contains "1.1.1.1")
        
        $chkBitlocker.IsChecked = ((manage-bde -status C: -ErrorAction SilentlyContinue) -match "Protection On")
    } catch { }
}

$btnSetManual.Add_Click({
    try { $mD = [DateTime]::ParseExact("$($txtDate.Text) $($txtTime.Text)", "dd/MM/yyyy HH:mm:ss", $null); Set-Date $mD; [System.Windows.MessageBox]::Show("Xong!") } catch { }
})

$btnSyncTime.Add_Click({
    try { Start-Service W32Time; w32tm /resync /force; [System.Windows.MessageBox]::Show("OK!") } catch { }
})

$btnApply.Add_Click({
    $btnApply.IsEnabled = $false; $lblTrangThai.Visibility = "Visible"; $lblTrangThai.Text = "⏳ Đang cấu hình..."
    try {
        $ads = Get-NetAdapter | Where-Object Status -eq "Up"
        foreach ($ad in $ads) {
            if ($chkDNSGoogle.IsChecked) { Set-DnsClientServerAddress -InterfaceIndex $ad.InterfaceIndex -ServerAddresses ("8.8.8.8","8.8.4.4") }
            elseif ($chkDNSCloud.IsChecked) { Set-DnsClientServerAddress -InterfaceIndex $ad.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1") }
            else { Set-DnsClientServerAddress -InterfaceIndex $ad.InterfaceIndex -ResetServerAddresses }
        }

        if ($chkWinUpdate.IsChecked) { 
            Set-Service wuauserv -StartupType Automatic
            reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f 2>$null 
        } else { 
            Stop-Service wuauserv -Force; Set-Service wuauserv -StartupType Disabled
            $rP = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; if (!(Test-Path $rP)) { New-Item $rP -Force }; Set-ItemProperty $rP -Name "NoAutoUpdate" -Value 1 
        }

        if ($IsWin11) {
            Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value ([int]$chkSAC.IsChecked)
            $regW = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers"; if (!(Test-Path $regW)) { New-Item $regW -Force }
            $wValue = 1; if ($chkWPP.IsChecked) { $wValue = 0 }; Set-ItemProperty $regW -Name "ConfigureWindowsProtectedPrintMode" -Value $wValue
            Restart-Service spooler -Force
            $regM = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            if ($chkClassicMenu.IsChecked) { if (!(Test-Path "$regM\InprocServer32")) { New-Item "$regM\InprocServer32" -Force; Set-ItemProperty "$regM\InprocServer32" -Name "(Default)" -Value "" } }
            else { if (Test-Path $regM) { Remove-Item $regM -Recurse -Force } }
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value ([int]$chkTaskbarCenter.IsChecked)
        }

        $regD = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"; if (!(Test-Path $regD)) { New-Item $regD -Force }
        $vPC = 1; if ($chkShowThisPC.IsChecked) { $vPC = 0 }; Set-ItemProperty $regD -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value $vPC
        $vNet = 1; if ($chkShowNetwork.IsChecked) { $vNet = 0 }; Set-ItemProperty $regD -Name "{F02C1034-056E-447a-859F-370A18395C10}" -Value $vNet
        $vCtl = 1; if ($chkShowControl.IsChecked) { $vCtl = 0 }; Set-ItemProperty $regD -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -Value $vCtl
        $vUsr = 1; if ($chkShowUser.IsChecked) { $vUsr = 0 }; Set-ItemProperty $regD -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value $vUsr

        if ($chkSetVNTZ.IsChecked) { Set-TimeZone -Id "SE Asia Standard Time" }
        $vTime = "h:mm tt"; if ($chkTime24h.IsChecked) { $vTime = "H:mm" }; Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime" -Value $vTime
        $vTray = 1; if ($chkShowAllIcons.IsChecked) { $vTray = 0 }; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value $vTray
        $vLaunch = 2; if ($chkThisPC.IsChecked) { $vLaunch = 1 }; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value $vLaunch

        Stop-Process -Name explorer -Force
        [System.Windows.MessageBox]::Show("Đã hoàn tất!"); $Form.Close()
    } catch { [System.Windows.MessageBox]::Show($_.Exception.Message) }
})

Doc-TrangThai
$Form.ShowDialog() | Out-Null