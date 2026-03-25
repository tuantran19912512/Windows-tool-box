# ==============================================================================
# Tên công cụ: TÙY CHỈNH HỆ THỐNG & THỜI GIAN (V6.2 - SIÊU ỔN ĐỊNH)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc trị: Fix dứt điểm lỗi cú pháp 'if', Giao diện ngang Modern
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

# --- GIAO DIỆN XAML WPF (DÀN TRANG NGANG) ---
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox - Tùy Chỉnh Windows" Width="950" Height="580" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border CornerRadius="12" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Grid Height="45" VerticalAlignment="Top" Background="#1E293B">
                <Grid.Clip><RectangleGeometry Rect="0,0,950,45" RadiusX="12" RadiusY="12"/></Grid.Clip>
                <TextBlock Name="TxtTitle" Text="⚙️ TÙY CHỈNH HỆ THỐNG &amp; THỜI GIAN" Foreground="#38BDF8" FontWeight="Bold" FontSize="15" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <Button Name="BtnClose" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="15" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <Grid Margin="25,65,25,20">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Margin="0,0,12,0">
                    <TextBlock Text="GIAO DIỆN &amp; EXPLORER" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="8" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkBitlocker" Content="Bật BitLocker (Mã hóa ổ C:)" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkThisPC" Content="Mở Explorer vào This PC" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkClassicMenu" Content="Menu chuột phải Win 10" Foreground="#E2E8F0" FontSize="14" Cursor="Hand"/>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="THANH TÁC VỤ (TASKBAR)" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="8" Padding="15">
                        <StackPanel>
                            <CheckBox Name="ChkTaskbarCenter" Content="Căn giữa biểu tượng (Win 11)" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,10" Cursor="Hand"/>
                            <CheckBox Name="ChkShowAllIcons" Content="Hiện tất cả icon góc đồng hồ" Foreground="#38BDF8" FontSize="14" Margin="0,0,0,10" Cursor="Hand" FontWeight="SemiBold"/>
                            <UniformGrid Columns="2">
                                <CheckBox Name="ChkSearch" Content="Tìm kiếm" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                                <CheckBox Name="ChkTaskView" Content="Task View" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                                <CheckBox Name="ChkWidgets" Content="Widgets" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                                <CheckBox Name="ChkChat" Content="Chat Teams" Foreground="#E2E8F0" FontSize="13" Margin="0,0,0,8" Cursor="Hand"/>
                            </UniformGrid>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="12,0,0,0">
                    <TextBlock Text="THỜI GIAN &amp; VÙNG (TIME &amp; REGION)" Foreground="#94A3B8" FontWeight="Bold" FontSize="13" Margin="0,0,0,10"/>
                    <Border Background="#1E293B" CornerRadius="8" Padding="15" Margin="0,0,0,20">
                        <StackPanel>
                            <CheckBox Name="ChkSetVNTZ" Content="Múi giờ Việt Nam (UTC+07:00)" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,12" Cursor="Hand"/>
                            <CheckBox Name="ChkTime24h" Content="Sử dụng định dạng giờ 24h (H:mm)" Foreground="#E2E8F0" FontSize="14" Margin="0,0,0,15" Cursor="Hand"/>
                            
                            <Button Name="BtnSyncTime" Content="🔄 ĐỒNG BỘ GIỜ TRỰC TUYẾN" Height="35" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                            <TextBlock Text="Đồng bộ với máy chủ time.windows.com" Foreground="#64748B" FontSize="11" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                        </StackPanel>
                    </Border>

                    <Grid VerticalAlignment="Bottom" Height="150">
                        <Button Name="BtnApply" Content="🚀 ÁP DỤNG TẤT CẢ" Height="60" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="18" BorderThickness="0" Cursor="Hand" VerticalAlignment="Bottom" Margin="0,0,0,40">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                        </Button>
                        <TextBlock Name="LblTrangThai" Text="Sẵn sàng." Foreground="#10B981" FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,10" Visibility="Hidden"/>
                    </Grid>
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
$chkBitlocker = $FormTuyChinh.FindName("ChkBitlocker"); $chkThisPC = $FormTuyChinh.FindName("ChkThisPC")
$chkClassicMenu = $FormTuyChinh.FindName("ChkClassicMenu"); $chkTaskbarCenter = $FormTuyChinh.FindName("ChkTaskbarCenter"); $chkShowAllIcons = $FormTuyChinh.FindName("ChkShowAllIcons")
$chkWidgets = $FormTuyChinh.FindName("ChkWidgets"); $chkTaskView = $FormTuyChinh.FindName("ChkTaskView")
$chkSearch = $FormTuyChinh.FindName("ChkSearch"); $chkChat = $FormTuyChinh.FindName("ChkChat")
$chkSetVNTZ = $FormTuyChinh.FindName("ChkSetVNTZ"); $chkTime24h = $FormTuyChinh.FindName("ChkTime24h")
$txtTitle = $FormTuyChinh.FindName("TxtTitle")

if (-not $IsWin11) {
    $txtTitle.Text = "⚙️ TÙY CHỈNH HỆ THỐNG WINDOWS 10"
    $chkClassicMenu.IsEnabled = $false; $chkClassicMenu.Opacity = 0.5
    $chkTaskbarCenter.IsEnabled = $false; $chkTaskbarCenter.Opacity = 0.5
}

$FormTuyChinh.Add_MouseLeftButtonDown({ $FormTuyChinh.DragMove() })
$btnClose.Add_Click({ $FormTuyChinh.Close() })

# --- ĐỌC TRẠNG THÁI HIỆN TẠI ---
function Doc-TrangThai {
    $keyAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $keySearch = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    try {
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
            $chkSearch.IsChecked = ((Get-ItemProperty $keySearch -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue).SearchboxTaskbarMode -ne 0)
        } else {
            $chkWidgets.IsChecked = ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -ErrorAction SilentlyContinue).ShellFeedsTaskbarViewMode -ne 2)
            $chkTaskView.IsChecked = ((Get-ItemProperty $keyAdv -Name "ShowTaskViewButton" -ErrorAction SilentlyContinue).ShowTaskViewButton -ne 0)
            $chkSearch.IsChecked = ((Get-ItemProperty $keySearch -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue).SearchboxTaskbarMode -ne 0)
            $chkChat.IsChecked = ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -ErrorAction SilentlyContinue).PeopleBand -ne 0)
        }
    } catch {}
    if ($IsWin11) { $chkClassicMenu.IsChecked = Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" }
    try { $chkBitlocker.IsChecked = ((manage-bde -status C:) -match "Protection On|Fully Encrypted") } catch {}
}

# --- NÚT ĐỒNG BỘ GIỜ ---
$btnSyncTime.Add_Click({
    $btnSyncTime.IsEnabled = $false
    try {
        Start-Service W32Time -ErrorAction SilentlyContinue
        w32tm /resync /force
        [System.Windows.MessageBox]::Show("Đã đồng bộ thời gian thành công!", "Đồng bộ giờ")
    } catch { 
        [System.Windows.MessageBox]::Show("Lỗi: Không thể kết nối máy chủ thời gian.", "Lỗi") 
    }
    $btnSyncTime.IsEnabled = $true
})

# --- NÚT ÁP DỤNG ---
$btnApply.Add_Click({
    $btnApply.IsEnabled = $false
    $lblTrangThai.Visibility = "Visible"
    $lblTrangThai.Text = "⏳ Đang cấu hình..."
    
    try {
        # 1. Xử lý Thời gian & Múi giờ
        if ($chkSetVNTZ.IsChecked) { Set-TimeZone -Id "SE Asia Standard Time" }
        if ($chkTime24h.IsChecked) {
            Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime" -Value "H:mm"
            Set-ItemProperty "HKCU:\Control Panel\International" -Name "sLongTime" -Value "H:mm:ss"
        } else {
            Set-ItemProperty "HKCU:\Control Panel\International" -Name "sShortTime" -Value "h:mm tt"
            Set-ItemProperty "HKCU:\Control Panel\International" -Name "sLongTime" -Value "h:mm:ss tt"
        }

        # 2. Xử lý Registry chung
        $keyAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
        $trayVal = 1; if ($chkShowAllIcons.IsChecked) { $trayVal = 0 }
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value $trayVal
        
        $launchVal = 2; if ($chkThisPC.IsChecked) { $launchVal = 1 }
        Set-ItemProperty $keyAdv -Name "LaunchTo" -Value $launchVal

        # 3. Xử lý Win 11 đặc thù
        if ($IsWin11) {
            $keyMenu = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            if ($chkClassicMenu.IsChecked) {
                if (-not (Test-Path "$keyMenu\InprocServer32")) { New-Item "$keyMenu\InprocServer32" -Force | Out-Null; Set-ItemProperty "$keyMenu\InprocServer32" -Name "(Default)" -Value "" }
            } else { if (Test-Path $keyMenu) { Remove-Item $keyMenu -Recurse -Force } }
            
            $alVal = 0; if ($chkTaskbarCenter.IsChecked) { $alVal = 1 }
            Set-ItemProperty $keyAdv -Name "TaskbarAl" -Value $alVal
            
            $daVal = 0; if ($chkWidgets.IsChecked) { $daVal = 1 }
            Set-ItemProperty $keyAdv -Name "TaskbarDa" -Value $daVal
            
            $mnVal = 0; if ($chkChat.IsChecked) { $mnVal = 1 }
            Set-ItemProperty $keyAdv -Name "TaskbarMn" -Value $mnVal
        } else {
            # Xử lý Win 10 đặc thù
            $feedVal = 2; if ($chkWidgets.IsChecked) { $feedVal = 0 }
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value $feedVal
            
            $peopleVal = 0; if ($chkChat.IsChecked) { $peopleVal = 1 }
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Value $peopleVal
        }

        # 4. Taskbar chung
        $tvVal = 0; if ($chkTaskView.IsChecked) { $tvVal = 1 }
        Set-ItemProperty $keyAdv -Name "ShowTaskViewButton" -Value $tvVal
        
        $searchVal = 0; if ($chkSearch.IsChecked) { $searchVal = 1 }
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value $searchVal

        # 5. BitLocker
        if ($chkBitlocker.IsChecked) { 
             if (-not ((manage-bde -status C:) -match "Protection On|Fully Encrypted")) { Start-Process "control.exe" "/name Microsoft.BitLockerDriveEncryption" }
        } else { manage-bde -off C: | Out-Null }

        $lblTrangThai.Text = "⏳ Đang khởi động lại Explorer..."
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        
        $lblTrangThai.Text = "✅ Đã xong!"
        [System.Windows.MessageBox]::Show("Tất cả cài đặt đã được áp dụng!", "VietToolbox")
    } catch { 
        [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)") 
    }
    $btnApply.IsEnabled = $true
})

Doc-TrangThai
$FormTuyChinh.ShowDialog() | Out-Null