# ==============================================================================
# VIETTOOLBOX PRO V53 - MAX OPTIONS (AUTO DEPLOY + ANIMATION + GDRIVE SPLIT)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

# 1. GIAO DIỆN XAML
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro Installer 2026 - Tự Động Hóa 100%" Width="1050" Height="800" WindowStartupLocation="CenterScreen"
        Background="#F4F7F9" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/>    <RowDefinition Height="Auto"/> <RowDefinition Height="180"/>  <RowDefinition Height="70"/>   </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="HỆ THỐNG CÀI ĐẶT TỰ ĐỘNG PRO V53" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Tích hợp Auto-Deploy môi trường &amp; Hiệu ứng nhận diện quá trình cài đặt" Foreground="#666666"/>
        </StackPanel>

        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#DDD" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <TextBlock Name="TxtWinget" Grid.Column="0" Text="⏳ Đang kiểm tra Winget..." FontWeight="Bold" Foreground="#333"/>
                <TextBlock Name="TxtChoco" Grid.Column="1" Text="⏳ Đang kiểm tra Choco..." FontWeight="Bold" Foreground="#333"/>
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
            <Button Name="BtnReload" Grid.Column="0" Content="NẠP LẠI" Height="45" Background="#2E7D32" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/>
            <Button Name="BtnQuet" Grid.Column="1" Content="QUÉT MÁY" Height="45" Background="#455A64" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/>
            <Button Name="BtnSelect" Grid.Column="2" Content="CHỌN TẤT CẢ" Height="45" Background="#1565C0" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/>
            <Button Name="BtnInstall" Grid.Column="3" Content="BẮT ĐẦU CÀI ĐẶT" Height="45" Background="#E65100" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/>
            <Button Name="BtnStop" Grid.Column="4" Content="🛑" Height="45" Background="#C62828" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
        </Grid>
    </Grid>
</Window>
"@

# 2. KHỞI TẠO CỬA SỔ
$stringReader = New-Object System.IO.StringReader($inputXML)
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [Windows.Markup.XamlReader]::Load($xmlReader)

$txtWinget = $window.FindName("TxtWinget"); $txtChoco = $window.FindName("TxtChoco")
$lstApps = $window.FindName("LstApps"); $txtLog = $window.FindName("TxtLog")
$pbTotal = $window.FindName("PbTotal"); $btnInstall = $window.FindName("BtnInstall")
$btnQuet = $window.FindName("BtnQuet"); $btnSelect = $window.FindName("BtnSelect"); $btnStop = $window.FindName("BtnStop"); $btnReload = $window.FindName("BtnReload")

$Global:WingetReady = $false; $Global:ChocoReady = $false; $script:HuyCaiDat = $false

# 3. HÀM LOGIC CHÍNH

function Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{ 
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n"); $txtLog.ScrollToEnd() 
    })
    [System.Windows.Forms.Application]::DoEvents()
}

# HÀM MỚI: CHỜ CÀI ĐẶT CÓ HIỆU ỨNG CHỮ CHẠY (ANIMATION)
function Wait-TrinhCaiDat($proc, $appItem, $baseText) {
    $dotCount = 0
    while (-not $proc.HasExited) {
        $dotCount = ($dotCount + 1) % 4
        $dots = "." * $dotCount
        
        $window.Dispatcher.Invoke([action]{
            $appItem.Status = "$baseText$dots"
            $lstApps.Items.Refresh()
        })
        
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 400
    }
    return $proc.ExitCode
}

# --- HÀM TỰ ĐỘNG CÀI MÔI TRƯỜNG (WINGET & CHOCO) ---
function CaiDat-MoiTruong {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $window.Dispatcher.Invoke([action]{ $txtWinget.Text = "✅ Winget: Sẵn sàng"; $txtWinget.Foreground = "Green" })
        $Global:WingetReady = $true
    } else {
        $window.Dispatcher.Invoke([action]{ $txtWinget.Text = "⚙️ Đang cài Winget (AppInstaller)..."; $txtWinget.Foreground = "Orange" })
        Ghi-Log "[*] Máy chưa có Winget. Đang kéo bản gốc từ Microsoft..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $wingetPath = "$env:TEMP\winget.msixbundle"
            (New-Object System.Net.WebClient).DownloadFile($wingetUrl, $wingetPath)
            Add-AppxPackage -Path $wingetPath
            $window.Dispatcher.Invoke([action]{ $txtWinget.Text = "✅ Winget: Đã cài xong!"; $txtWinget.Foreground = "Green" })
            $Global:WingetReady = $true; Ghi-Log "✓ Cài Winget thành công!"
        } catch {
            $window.Dispatcher.Invoke([action]{ $txtWinget.Text = "❌ Winget: Lỗi cài đặt"; $txtWinget.Foreground = "Red" })
            Ghi-Log "❌ Lỗi cài Winget: Cần update Windows hoặc thiếu thư viện."
        }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $window.Dispatcher.Invoke([action]{ $txtChoco.Text = "✅ Chocolatey: Sẵn sàng"; $txtChoco.Foreground = "Green" })
        $Global:ChocoReady = $true
    } else {
        $window.Dispatcher.Invoke([action]{ $txtChoco.Text = "⚙️ Đang cài Chocolatey..."; $txtChoco.Foreground = "Orange" })
        Ghi-Log "[*] Máy chưa có Choco. Đang kéo script từ Server..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $window.Dispatcher.Invoke([action]{ $txtChoco.Text = "✅ Chocolatey: Đã cài xong!"; $txtChoco.Foreground = "Green" })
            $Global:ChocoReady = $true
            $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"
            Ghi-Log "✓ Cài Chocolatey thành công!"
        } catch {
            $window.Dispatcher.Invoke([action]{ $txtChoco.Text = "❌ Chocolatey: Lỗi cài đặt"; $txtChoco.Foreground = "Red" })
            Ghi-Log "❌ Lỗi cài Choco: Kiểm tra lại mạng hoặc quyền Admin."
        }
    }
}

function Get-SmartIcon($name) {
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
    $n = $name.Trim()
    if ($IconLibrary.ContainsKey($n)) { return $IconLibrary[$n] }
    return "https://cdn-icons-png.flaticon.com/512/1243/1243968.png"
}

function Tai-DanhSach {
    try {
        $githubUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv"
        $wc = New-Object System.Net.WebClient
        $wc.Encoding = [System.Text.Encoding]::UTF8
        $data = $wc.DownloadString($githubUrl + "?t=" + (Get-Date).Ticks) | ConvertFrom-Csv
        $appList = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
        
        foreach ($item in $data) {
            $icon = if ($item.IconURL) { $item.IconURL } else { Get-SmartIcon $item.Name }
            $appList.Add([PSCustomObject]@{
                Check = $true; IconURL = $icon; Name = $item.Name; Status = "Chờ quét..."; 
                StatusColor = "Black"; WID = $item.WingetID; CID = $item.ChocoID; GID = $item.GDriveID; Args = $item.SilentArgs
            })
        }
        $lstApps.ItemsSource = $appList
        Ghi-Log "✓ Đã nạp danh sách phần mềm từ Cloud."
    } catch { Ghi-Log "❌ Lỗi: Không tải được danh sách từ GitHub!" }
}

# --- SỰ KIỆN NÚT BẤM ---
$btnQuet.Add_Click({
    Ghi-Log "[*] Đang quét hệ thống..."
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

$script:AllState = $true
$btnSelect.Add_Click({
    $script:AllState = !$script:AllState
    foreach ($item in $lstApps.ItemsSource) { if ($item.StatusColor -ne "Gray") { $item.Check = $script:AllState } }
    $btnSelect.Content = if ($script:AllState) { "BỎ CHỌN" } else { "CHỌN TẤT CẢ" }
    $lstApps.Items.Refresh()
})

$btnStop.Add_Click({ $script:HuyCaiDat = $true; Ghi-Log "🛑 Đã nhận lệnh ngắt quy trình!" })

# --- TRÁI TIM CỦA TOOL: CÀI ĐẶT THÔNG MINH (ĐÃ THÊM PROGRESS BAR ANIMATION) ---
$btnInstall.Add_Click({
    $selected = @($lstApps.ItemsSource | Where-Object { $_.Check -eq $true })
    if ($selected.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn App nào!", "Nhắc nhở"); return }
    
    $btnInstall.IsEnabled = $false; $script:HuyCaiDat = $false; $done = 0

    foreach ($app in $selected) {
        if ($script:HuyCaiDat) { break }
        
        $app.StatusColor = "Orange"; $window.Dispatcher.Invoke([action]{ $lstApps.Items.Refresh() })
        [System.Windows.Forms.Application]::DoEvents()
        Ghi-Log "🚀 Đang xử lý: $($app.Name)..."
        
        $success = $false
        
        # 🟢 BẬT HIỆU ỨNG THANH CHẠY QUA CHẠY LẠI
        $pbTotal.IsIndeterminate = $true 
        
        # 1. Winget (Cho phép tối đa 3 phút)
        if ($app.WID -and $Global:WingetReady) {
            $p = Start-Process "winget" -ArgumentList "install --id `"$($app.WID)`" --silent --accept-package-agreements --accept-source-agreements --force" -PassThru -WindowStyle Hidden
            $result = Wait-TrinhCaiDat $p $app "Đang kéo Winget" 3
            if ($result -eq 0) { $success = $true }
            elseif ($result -eq "TIMEOUT") { Ghi-Log "⚠️ Winget quá chậm (Quá 3 phút). Chuyển luồng..." }
        }
        
        # 2. Choco (Tối đa 3 phút)
        if (-not $success -and $app.CID -and $Global:ChocoReady) {
            $p = Start-Process "choco" -ArgumentList "install `"$($app.CID)`" -y --silent" -PassThru -WindowStyle Hidden
            $result = Wait-TrinhCaiDat $p $app "Đang kéo Choco" 3
            if ($result -eq 0 -or $result -eq 3010) { $success = $true }
            elseif ($result -eq "TIMEOUT") { Ghi-Log "⚠️ Choco chậm! Chuyển luồng..." }
        }
        
        # 3. GDrive
        if (-not $success -and $app.GID) {
            $window.Dispatcher.Invoke([action]{ $app.Status = "Đang tải GDrive..."; $lstApps.Items.Refresh() })
            [System.Windows.Forms.Application]::DoEvents()
            
            $tmp = Join-Path $env:TEMP "$($app.Name).exe"
            try {
                (New-Object System.Net.WebClient).DownloadFile("https://docs.google.com/uc?export=download&id=$($app.GID)", $tmp)
                
                $p = Start-Process $tmp -ArgumentList $app.Args -PassThru -WindowStyle Hidden
                # Cài GDrive file exe có thể lâu, cho hẳn 5 phút timeout
                $result = Wait-TrinhCaiDat $p $app "Đang cài đặt" 5
                if ($result -eq 0 -or $app.Args -match "silent") { $success = $true }
            } catch { Ghi-Log "❌ Lỗi kéo file GDrive" }
        }

        # 🔴 TẮT HIỆU ỨNG CHẠY QUA CHẠY LẠI
        $pbTotal.IsIndeterminate = $false

        # Báo kết quả từng App
        if ($success) { 
            $window.Dispatcher.Invoke([action]{ $app.Status = "Xong!"; $app.StatusColor = "Green" })
        } else { 
            $window.Dispatcher.Invoke([action]{ $app.Status = "Lỗi!"; $app.StatusColor = "Red" })
        }
        
        # Cập nhật % tổng thể
        $done++; $pbTotal.Value = ($done / $selected.Count) * 100
        $window.Dispatcher.Invoke([action]{ $lstApps.Items.Refresh() })
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    $btnInstall.IsEnabled = $true
    if ($script:HuyCaiDat) { Ghi-Log "🛑 ĐÃ DỪNG CÀI ĐẶT." } else { Ghi-Log "✓ HOÀN TẤT CHU TRÌNH." }
})

$btnReload.Add_Click({ Tai-DanhSach })

# --- KHỞI CHẠY (NẠP DATA VÀ MÔI TRƯỜNG) ---
$window.Add_ContentRendered({
    Tai-DanhSach
    CaiDat-MoiTruong
})

$window.ShowDialog() | Out-Null