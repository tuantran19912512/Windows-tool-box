# ==============================================================================
# VIETTOOLBOX PRO V50.1 - AUTO ICON & FULL LOGIC (WPF)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing

# 1. GIAO DIỆN XAML
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro Installer 2026" Width="1050" Height="800" WindowStartupLocation="CenterScreen"
        Background="#F4F7F9" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/>    <RowDefinition Height="Auto"/> <RowDefinition Height="180"/>  <RowDefinition Height="70"/>   </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="HỆ THỐNG CÀI ĐẶT TỰ ĐỘNG" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="VietToolbox Pro - Quản lý phần mềm thông minh" Foreground="#666666"/>
        </StackPanel>

        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#DDD" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <TextBlock Name="TxtWinget" Grid.Column="0" Text="⏳ Đang check Winget..." FontWeight="Bold" Foreground="#333"/>
                <TextBlock Name="TxtChoco" Grid.Column="1" Text="⏳ Đang check Choco..." FontWeight="Bold" Foreground="#333"/>
            </Grid>
        </Border>

        <ListView Name="LstApps" Grid.Row="2" Background="White" BorderThickness="1" BorderBrush="#DDD">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="45">
                        <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="ICON" Width="60">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate><Image Source="{Binding IconURL}" Width="32" Height="32" RenderOptions.BitmapScalingMode="HighQuality"/></DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="TÊN PHẦN MỀM" DisplayMemberBinding="{Binding Name}" Width="350"/>
                    <GridViewColumn Header="TRẠNG THÁI" Width="220">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="Bold"/></DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>

        <ProgressBar Name="PbTotal" Grid.Row="3" Height="12" Margin="0,15,0,5" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>

        <TextBox Name="TxtLog" Grid.Row="4" Background="#1E1E1E" Foreground="#00FF00" IsReadOnly="True" 
                 FontFamily="Consolas" FontSize="13" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Margin="0,10,0,0" Padding="10"/>

        <Grid Grid.Row="5" Margin="0,15,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="150"/><ColumnDefinition Width="150"/><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="60"/>
            </Grid.ColumnDefinitions>
            <Button Name="BtnReload" Grid.Column="0" Content="NẠP LẠI" Height="45" Background="#2E7D32" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
            <Button Name="BtnQuet" Grid.Column="1" Content="QUÉT MÁY" Height="45" Background="#455A64" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
            <Button Name="BtnSelect" Grid.Column="2" Content="CHỌN TẤT CẢ" Height="45" Background="#1565C0" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
            <Button Name="BtnInstall" Grid.Column="3" Content="BẮT ĐẦU CÀI ĐẶT" Height="45" Background="#E65100" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
            <Button Name="BtnStop" Grid.Column="4" Content="🛑" Height="45" Background="#C62828" Foreground="White" FontWeight="Bold"/>
        </Grid>
    </Grid>
</Window>
"@

# 2. KHỞI TẠO CỬA SỔ (SỬA LỖI CONSTRUCTOR)
$stringReader = New-Object System.IO.StringReader($inputXML)
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [Windows.Markup.XamlReader]::Load($xmlReader)

# Ánh xạ biến
$txtWinget = $window.FindName("TxtWinget"); $txtChoco = $window.FindName("TxtChoco")
$lstApps = $window.FindName("LstApps"); $txtLog = $window.FindName("TxtLog")
$pbTotal = $window.FindName("PbTotal"); $btnInstall = $window.FindName("BtnInstall")
$btnQuet = $window.FindName("BtnQuet"); $btnSelect = $window.FindName("BtnSelect"); $btnStop = $window.FindName("BtnStop"); $btnReload = $window.FindName("BtnReload")

# 3. HÀM LOGIC

function Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{ $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n"); $txtLog.ScrollToEnd() })
    [System.Windows.Forms.Application]::DoEvents()
}

function Get-SmartIcon($name) {
    # 1. BẢNG MAPPING "VÀNG" - Tuấn phải tự tay nạp link ảnh thật vào đây
    # Tôi lấy link PNG chất lượng cao (512px) từ Flaticon để đảm bảo ảnh đẹp, bo góc.
    $IconLibrary = @{
        "Zalo"          = "https://stc-zalopro.zdn.vn/v2/pc/logo.png"
        "Chrome"        = "https://cdn-icons-png.flaticon.com/512/888/888846.png"
        "Coc Coc"       = "https://upload.wikimedia.org/wikipedia/vi/3/3b/Coccoc_logo.png"
        "Unikey"        = "https://www.unikey.org/assets/img/unikey_logo.png"
        "UltraViewer"   = "https://ultraviewer.net/favicon.ico"
        "TeamViewer"    = "https://cdn-icons-png.flaticon.com/512/888/888871.png"
        "Microsoft Word" = "https://cdn-icons-png.flaticon.com/512/732/732228.png"
        "Microsoft Excel"= "https://cdn-icons-png.flaticon.com/512/732/732220.png"
        "WinRAR"        = "https://www.win-rar.com/favicon.ico"
        "7-Zip"         = "https://7-zip.org/7zip.png"
        "VLC Media Player" = "https://cdn-icons-png.flaticon.com/512/888/888874.png"
    }

    # 2. Xóa dấu, xóa khoảng trắng ở đầu/cuối của tên app trong máy khách
    $n = $name.Trim()

    # 3. So khớp chính xác 100%
    if ($IconLibrary.ContainsKey($n)) {
        return $IconLibrary[$n]
    }

    # 4. Nếu không tìm thấy, trả về một cái ICON "RỖNG" hoặc HÌNH HỘP QUÀ để Tuấn biết là chưa nạp
    return "https://cdn-icons-png.flaticon.com/512/1243/1243968.png" # Hình hộp công cụ
}

function Tai-DanhSach {
    try {
        $githubUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv"
        $wc = New-Object System.Net.WebClient
        $data = $wc.DownloadString($githubUrl + "?t=" + (Get-Date).Ticks) | ConvertFrom-Csv
        $appList = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
        
        foreach ($item in $data) {
            # Nếu CSV không có IconURL, tự "chế" link từ Google
            $icon = if ($item.IconURL) { $item.IconURL } else { Get-SmartIcon $item.Name }
            $appList.Add([PSCustomObject]@{
                Check = $true; IconURL = $icon; Name = $item.Name; Status = "Chờ quét..."; 
                StatusColor = "Black"; WID = $item.WingetID; CID = $item.ChocoID; GID = $item.GDriveID; Args = $item.SilentArgs
            })
        }
        $lstApps.ItemsSource = $appList
        Ghi-Log "✓ Đã tải danh sách phần mềm và Icon tự động."
    } catch { Ghi-Log "❌ Lỗi: Không thể kết nối GitHub!" }
}

# --- NÚT QUÉT HỆ THỐNG ---
$btnQuet.Add_Click({
    Ghi-Log "[*] Đang rà soát phần mềm trong máy khách..."
    $apps = (Get-ItemProperty @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") -ErrorAction SilentlyContinue).DisplayName
    foreach ($item in $lstApps.ItemsSource) {
        if ($apps -match [regex]::Escape($item.Name)) {
            $item.Status = "Đã có sẵn"; $item.Check = $false; $item.StatusColor = "Gray"
        } else {
            $item.Status = "Chưa cài đặt"; $item.Check = $true; $item.StatusColor = "#1565C0"
        }
    }
    $lstApps.Items.Refresh(); Ghi-Log "✓ Quét xong!"
})

# --- NÚT CHỌN TẤT CẢ ---
$script:AllState = $true
$btnSelect.Add_Click({
    $script:AllState = !$script:AllState
    foreach ($item in $lstApps.ItemsSource) { if ($item.StatusColor -ne "Gray") { $item.Check = $script:AllState } }
    $btnSelect.Content = if ($script:AllState) { "BỎ CHỌN" } else { "CHỌN TẤT CẢ" }
    $lstApps.Items.Refresh()
})

# --- NÚT DỪNG ---
$btnStop.Add_Click({ $script:HuyCaiDat = $true; Ghi-Log "🛑 Đang ngắt quy trình..." })

# --- NÚT BẮT ĐẦU CÀI ĐẶT (FULL FALLBACK) ---
$btnInstall.Add_Click({
    $selected = $lstApps.ItemsSource | Where-Object { $_.Check -eq $true }
    if ($selected.Count -eq 0) { return }
    $btnInstall.IsEnabled = $false; $script:HuyCaiDat = $false; $done = 0

    foreach ($app in $selected) {
        if ($script:HuyCaiDat) { break }
        $app.Status = "Đang cài..."; $app.StatusColor = "Orange"; $lstApps.Items.Refresh()
        Ghi-Log "🚀 Đang cài: $($app.Name)..."
        
        $success = $false
        # 1. Thử Winget
        if ($app.WID -and $Global:WingetReady) {
            $p = Start-Process "winget" -ArgumentList "install --id `"$($app.WID)`" --silent --accept-package-agreements --accept-source-agreements --force" -Wait -PassThru -WindowStyle Hidden
            if ($p.ExitCode -eq 0) { $success = $true }
        }
        # 2. Thử Choco
        if (-not $success -and $app.CID -and $Global:ChocoReady) {
            $p = Start-Process "choco" -ArgumentList "install `"$($app.CID)`" -y --silent" -Wait -PassThru -WindowStyle Hidden
            if ($p.ExitCode -eq 0) { $success = $true }
        }
        # 3. Thử GDrive
        if (-not $success -and $app.GID) {
            $tmp = Join-Path $env:TEMP "$($app.Name).exe"
            (New-Object System.Net.WebClient).DownloadFile("https://docs.google.com/uc?export=download&id=$($app.GID)", $tmp)
            $p = Start-Process $tmp -ArgumentList $app.Args -Wait -PassThru -WindowStyle Hidden
            $success = $true
        }

        if ($success) { $app.Status = "Xong!"; $app.StatusColor = "Green" } else { $app.Status = "Lỗi!"; $app.StatusColor = "Red" }
        $done++; $pbTotal.Value = ($done / $selected.Count) * 100
        $lstApps.Items.Refresh()
    }
    $btnInstall.IsEnabled = $true; Ghi-Log "✓ HOÀN TẤT CHU TRÌNH CÀI ĐẶT."
})

$btnReload.Add_Click({ Tai-DanhSach })

# --- KHỞI CHẠY ---
$window.Add_ContentRendered({
    Tai-DanhSach
    if (Get-Command winget -ErrorAction SilentlyContinue) { $txtWinget.Text = "✅ Winget: Sẵn sàng"; $Global:WingetReady = $true }
    if (Get-Command choco -ErrorAction SilentlyContinue) { $txtChoco.Text = "✅ Chocolatey: Sẵn sàng"; $Global:ChocoReady = $true }
})

$window.ShowDialog() | Out-Null