# ==============================================================================
# Tên công cụ: TÙY CHỈNH HỆ THỐNG & BIỂU TƯỢNG (V7.1 - FIXED SYNTAX)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Chức năng: Desktop Icons, BitLocker, This PC, Time & Taskbar
# Đặc trị: Fix dứt điểm lỗi cú pháp 'The term if'
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- KIỂM TRA QUYỀN ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 
    [System.Windows.MessageBox]::Show("Vui lòng chạy Tool với quyền Administrator!", "Thông báo", "OK", "Warning")
    exit 
}

$IsWin11 = [Environment]::OSVersion.Version.Build -ge 22000
$BrushConv = New-Object System.Windows.Media.BrushConverter

# --- GIAO DIỆN XAML WPF ---
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox - Tùy Chỉnh Windows" Width="950" Height="620" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border CornerRadius="12" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Grid Height="45" VerticalAlignment="Top" Background="#1E293B">
                <Grid.Clip><RectangleGeometry Rect="0,0,950,45" RadiusX="12" RadiusY="12"/></Grid.Clip>
                <TextBlock Name="TxtTitle" Text="⚙️ TÙY CHỈNH HỆ THỐNG &amp; BIỂU TƯỢNG DESKTOP" Foreground="#38BDF8" FontWeight="Bold" FontSize="15" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <Button Name="BtnClose" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="15" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <Grid Margin="25,65,25,20">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Margin="0,0,12,0">
                    <TextBlock Text="BIỂU TƯỢNG DESKTOP" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="8" Padding="15" Margin="0,0,0,20">
                        <UniformGrid Columns="2">
                            <CheckBox Name="ChkShowThisPC" Content="Hiện This PC" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkShowNetwork" Content="Hiện Network" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkShowControl" Content="Hiện Control Panel" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkShowUser" Content="Hiện User Folder" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                        </UniformGrid>
                    </Border>

                    <TextBlock Text="GIAO DIỆN &amp; EXPLORER" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="8" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkBitlocker" Content="Bật BitLocker (Mã hóa ổ C:)" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkThisPC" Content="Mở Explorer vào This PC" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkClassicMenu" Content="Menu chuột phải Win 10" Foreground="#E2E8F0" FontSize="14" Cursor="Hand"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="12,0,0,0">
                    <TextBlock Text="TASKBAR &amp; THỜI GIAN" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="8" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkShowAllIcons" Content="Hiện tất cả icon góc đồng hồ" Foreground="#38BDF8" FontSize="14" Margin="0,0,0,10" Cursor="Hand" FontWeight="SemiBold"/>
                            <CheckBox Name="ChkTaskbarCenter" Content="Căn giữa biểu tượng (Win 11)" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <UniformGrid Columns="2">
                                <CheckBox Name="ChkSearch" Content="Tìm kiếm" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                                <CheckBox Name="ChkTaskView" Content="Task View" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                                <CheckBox Name="ChkWidgets" Content="Widgets" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                                <CheckBox Name="ChkChat" Content="Chat Teams" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                            </UniformGrid>
                            <Separator Background="#334155" Margin="0,10,0,10"/>
                            <CheckBox Name="ChkSetVNTZ" Content="Múi giờ Việt Nam (UTC+07)" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,8" Cursor="Hand"/>
                            <CheckBox Name="ChkTime24h" Content="Định dạng giờ 24h" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <Button Name="BtnSyncTime" Content="🔄 ĐỒNG BỘ GIỜ" Height="30" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </StackPanel>
                    </Border>

                    <Button Name="BtnApply" Content="🚀 ÁP DỤNG TẤT CẢ" Height="60" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="18" BorderThickness="0" Cursor="Hand" Margin="0,10,0,0">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
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
$btnSyncTime = $FormTuyChinh.FindName("BtnSyncTime")
$chkShowThisPC = $FormTuyChinh.FindName("ChkShowThisPC"); $chkShowNetwork = $FormTuyChinh.FindName("ChkShowNetwork")
$chkShowControl = $FormTuyChinh.FindName("ChkShowControl"); $chkShowUser = $FormTuyChinh.FindName("ChkShowUser")
$chkBitlocker = $FormTuyChinh.FindName("ChkBitlocker"); $chkThisPC = $FormTuyChinh.FindName("ChkThisPC")
$chkClassicMenu = $FormTuyChinh.FindName("ChkClassicMenu"); $chkTaskbarCenter = $FormTuyChinh.FindName("ChkTaskbarCenter"); $chkShowAllIcons = $FormTuyChinh.FindName("ChkShowAllIcons")
$chkWidgets = $FormTuyChinh.FindName("ChkWidgets"); $chkTaskView = $FormTuyChinh.FindName("ChkTaskView")
$chkSearch = $FormTuyChinh.FindName("ChkSearch"); $chkChat = $FormTuyChinh.FindName("ChkChat")
$chkSetVNTZ = $FormTuyChinh.FindName("ChkSetVNTZ"); $chkTime24h = $FormTuyChinh.FindName("ChkTime24h")
$txtTitle = $FormTuyChinh.FindName("TxtTitle")

if (-not $IsWin11) {
    $txtTitle.Text = "⚙️ TÙY CHỈNH HỆ THỐNG WINDOWS 10"
    $chkClassicMenu.IsEnabled = $false; $chkClassicMenu.Opacity = 0.5; $chkTaskbarCenter.IsEnabled = $false; $chkTaskbarCenter.Opacity = 0.5
}

$FormTuyChinh.Add_MouseLeftButtonDown({ $FormTuyChinh.DragMove() })
$btnClose.Add_Click({ $FormTuyChinh.Close() })

function Doc-TrangThai {
    $keyDesktop = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    $keyAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    try {
        $chkShowThisPC.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -ErrorAction SilentlyContinue)."{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -eq 0)
        $chkShowNetwork.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{F02C1034-056E-447a-859F-370A18395C10}" -ErrorAction SilentlyContinue)."{F02C1034-056E-447a-859F-370A18395C10}" -eq 0)
        $chkShowControl.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -ErrorAction SilentlyContinue)."{5399E694-6CD5-4b5c-B231-819A47DC248A}" -eq 0)
        $chkShowUser.IsChecked = ((Get-ItemProperty $keyDesktop -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -ErrorAction SilentlyContinue)."{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -eq 0)
        
        $chkThisPC.IsChecked = ((Get-ItemProperty $keyAdv -Name "LaunchTo" -ErrorAction SilentlyContinue).LaunchTo -eq 1)
        $chkShowAllIcons.IsChecked = ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -ErrorAction SilentlyContinue).EnableAutoTray -eq 0)
        
        $timeFormat = (Get-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime").sShortTime
        if ($timeFormat -match "tt") { $chkTime24h.IsChecked = $false } else { $chkTime24h.IsChecked = $true }
        if ((Get-TimeZone).Id -eq "SE Asia Standard Time") { $chkSetVNTZ.IsChecked = $true } else { $chkSetVNTZ.IsChecked = $false }

        if ($IsWin11) {
            $chkTaskbarCenter.IsChecked = ((Get-ItemProperty $keyAdv -Name "TaskbarAl" -ErrorAction SilentlyContinue).TaskbarAl -eq 1)
            $chkWidgets.IsChecked = ((Get-ItemProperty $keyAdv -Name "TaskbarDa" -ErrorAction SilentlyContinue).TaskbarDa -eq 1)
            $chkTaskView.IsChecked = ((Get-ItemProperty $keyAdv -Name "ShowTaskViewButton" -ErrorAction SilentlyContinue).ShowTaskViewButton -eq 1)
            $chkChat.IsChecked = ((Get-ItemProperty $keyAdv -Name "TaskbarMn" -ErrorAction SilentlyContinue).TaskbarMn -eq 1)
            $chkSearch.IsChecked = ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue).SearchboxTaskbarMode -ne 0)
        }
    } catch {}
    if ($IsWin11) { $chkClassicMenu.IsChecked = Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" }
    try { $chkBitlocker.IsChecked = ((manage-bde -status C:) -match "Protection On|Fully Encrypted") } catch {}
}

$btnSyncTime.Add_Click({
    $btnSyncTime.IsEnabled = $false
    try { Start-Service W32Time -ErrorAction SilentlyContinue; w32tm /resync /force; [System.Windows.MessageBox]::Show("Đã đồng bộ giờ!", "VietToolbox") } catch {}
    $btnSyncTime.IsEnabled = $true
})

$btnApply.Add_Click({
    $btnApply.IsEnabled = $false
    $lblTrangThai.Visibility = "Visible"
    $lblTrangThai.Text = "⏳ Đang cấu hình hệ thống..."
    
    try {
        # 1. Desktop Icons
        $keyDesktop = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
        if (-not (Test-Path $keyDesktop)) { New-Item $keyDesktop -Force | Out-Null }
        
        $vPC = 1; if ($chkShowThisPC.IsChecked) { $vPC = 0 }
        Set-ItemProperty $keyDesktop -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value $vPC
        
        $vNet = 1; if ($chkShowNetwork.IsChecked) { $vNet = 0 }
        Set-ItemProperty $keyDesktop -Name "{F02C1034-056E-447a-859F-370A18395C10}" -Value $vNet
        
        $vCtrl = 1; if ($chkShowControl.IsChecked) { $vCtrl = 0 }
        Set-ItemProperty $keyDesktop -Name "{5399E694-6CD5-4b5c-B231-819A47DC248A}" -Value $vCtrl
        
        $vUser = 1; if ($chkShowUser.IsChecked) { $vUser = 0 }
        Set-ItemProperty $keyDesktop -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value $vUser

        # 2. Thời gian
        if ($chkSetVNTZ.IsChecked) { Set-TimeZone -Id "SE Asia Standard Time" }
        $vTime = "h:mm tt"; if ($chkTime24h.IsChecked) { $vTime = "H:mm" }
        Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime" -Value $vTime

        # 3. Registry chung
        $keyAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
        $vTray = 1; if ($chkShowAllIcons.IsChecked) { $vTray = 0 }
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value $vTray
        
        $vLaunch = 2; if ($chkThisPC.IsChecked) { $vLaunch = 1 }
        Set-ItemProperty $keyAdv -Name "LaunchTo" -Value $vLaunch

        if ($IsWin11) {
            $keyMenu = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            if ($chkClassicMenu.IsChecked) {
                if (-not (Test-Path "$keyMenu\InprocServer32")) { New-Item "$keyMenu\InprocServer32" -Force | Out-Null; Set-ItemProperty "$keyMenu\InprocServer32" -Name "(Default)" -Value "" }
            } else { if (Test-Path $keyMenu) { Remove-Item $keyMenu -Recurse -Force } }
            
            $vAl = 0; if ($chkTaskbarCenter.IsChecked) { $vAl = 1 }
            Set-ItemProperty $keyAdv -Name "TaskbarAl" -Value $vAl
            
            $vDa = 0; if ($chkWidgets.IsChecked) { $vDa = 1 }
            Set-ItemProperty $keyAdv -Name "TaskbarDa" -Value $vDa
            
            $vMn = 0; if ($chkChat.IsChecked) { $vMn = 1 }
            Set-ItemProperty $keyAdv -Name "TaskbarMn" -Value $vMn
        }

        $vTV = 0; if ($chkTaskView.IsChecked) { $vTV = 1 }
        Set-ItemProperty $keyAdv -Name "ShowTaskViewButton" -Value $vTV
        
        $vSearch = 0; if ($chkSearch.IsChecked) { $vSearch = 1 }
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value $vSearch

        if ($chkBitlocker.IsChecked) { 
            if (-not ((manage-bde -status C:) -match "Protection On|Fully Encrypted")) { Start-Process "control.exe" "/name Microsoft.BitLockerDriveEncryption" }
        } else { manage-bde -off C: | Out-Null }

        $lblTrangThai.Text = "⏳ Đang khởi động lại Explorer..."
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        
        $lblTrangThai.Text = "✅ Đã xong!"
        [System.Windows.MessageBox]::Show("Áp dụng thành công!", "VietToolbox")
    } catch { [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)") }
    $btnApply.IsEnabled = $true
})

Doc-TrangThai
$FormTuyChinh.ShowDialog() | Out-Null