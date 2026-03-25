# ==============================================================================
# VIETTOOLBOX PRO INSTALLER (V67.2 - BẢN GIAO DIỆN CHIA CỘT TRÁI - PHẢI)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc trị: Giao diện Modern 2 Cột + Dừng khẩn cấp + Fix MSStore + Đồng bộ giờ
# ==============================================================================

# 1. BẢO HIỂM KẾT NỐI VÀ FONT CHỮ (TLS 1.2 + 1.3 & UTF-8)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# 2. ÉP QUYỀN ADMIN TỰ ĐỘNG
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$LogicInstallerV67 = {
    $script:AppCollection = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $script:HuyCaiDat = $false
    $script:CurrentProc = $null 
    $script:SelectAllState = $true

    function Do-Events {
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        [void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background,
            [System.Windows.Threading.DispatcherOperationCallback]{ param($f) $f.Continue = $false; return $null }, $frame)
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }

    function Ghi-Log($msg) {
        [void]$window.Dispatcher.Invoke([action]{ $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n"); $txtLog.ScrollToEnd() })
        Do-Events
    }

    # --- HÀM TỰ ĐỘNG CÀI ĐẶT MÔI TRƯỜNG & FIX LỖI CHỨNG CHỈ ---
    function Check-MoiTruong {
        $txtTLS.Text = "🛡️ TLS 1.3: Active"; $txtTLS.Foreground = "#1565C0"
        Ghi-Log "[*] Đang kiểm tra môi trường hệ thống..."

        # ÉP ĐỒNG BỘ GIỜ VIỆT NAM (Tránh lỗi 0x8a15005e)
        Ghi-Log "[*] Đang đồng bộ thời gian hệ thống để tránh lỗi chứng chỉ..."
        try {
            Start-Process w32tm -ArgumentList "/resync /force" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
            Ghi-Log "✅ Đã đồng bộ thời gian chuẩn."
        } catch { Ghi-Log "⚠️ Không thể tự động đồng bộ thời gian." }

        # KIỂM TRA & CÀI ĐẶT WINGET
        if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
            $txtWinget.Text = "⏳ Đang cài Winget..."; $txtWinget.Foreground = "#E65100"
            Ghi-Log "[!] Không tìm thấy Winget. Đang tự động cài đặt từ máy chủ Microsoft..."
            try {
                $urlWinget = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                $pathWinget = "$env:TEMP\WingetInstaller.msixbundle"
                (New-Object System.Net.WebClient).DownloadFile($urlWinget, $pathWinget)
                Add-AppxPackage -Path $pathWinget
                $txtWinget.Text = "✅ Winget: OK"; $txtWinget.Foreground = "#2E7D32"
                Ghi-Log "✅ Cài đặt Winget thành công."
            } catch {
                Ghi-Log "❌ Lỗi Winget: $($_.Exception.Message)"
                $txtWinget.Text = "❌ Winget Lỗi"; $txtWinget.Foreground = "#D32F2F"
            }
        } else { $txtWinget.Text = "✅ Winget: OK"; $txtWinget.Foreground = "#2E7D32" }

        # KIỂM TRA & CÀI ĐẶT CHOCOLATEY
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            $txtChoco.Text = "⏳ Đang cài Choco..."; $txtChoco.Foreground = "#E65100"
            Ghi-Log "[!] Đang cài đặt Chocolatey (Môi trường bổ trợ)..."
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                $txtChoco.Text = "✅ Choco: OK"; $txtChoco.Foreground = "#2E7D32"
                Ghi-Log "✅ Cài đặt Chocolatey thành công."
            } catch {
                Ghi-Log "❌ Lỗi Choco: $($_.Exception.Message)"
                $txtChoco.Text = "❌ Choco Lỗi"; $txtChoco.Foreground = "#D32F2F"
            }
        } else { $txtChoco.Text = "✅ Choco: OK"; $txtChoco.Foreground = "#2E7D32" }
        Do-Events
    }

    # --- HÀM TẢI DANH SÁCH TỪ GITHUB ---
    function Tai-DanhSach {
        try {
            $wc = New-Object System.Net.WebClient; $wc.Encoding = [System.Text.Encoding]::UTF8
            $csvText = $wc.DownloadString("https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv?t=" + (Get-Date).Ticks)
            $data = $csvText | ConvertFrom-Csv
            
            $script:AppCollection.Clear()
            foreach ($item in $data) {
                # CƠ CHẾ LOGO THÔNG MINH
                $safeName = [System.Uri]::EscapeDataString($item.Name)
                $icon = "https://ui-avatars.com/api/?name=$safeName&background=random&color=fff&size=64&bold=true&rounded=true"
                if ($item.PSObject.Properties.Match('IconURL').Count -gt 0 -and $item.IconURL -match "^http") { $icon = $item.IconURL }
                
                # TRẠNG THÁI CHECKBOX MẶC ĐỊNH
                $isCheck = $true
                if ($item.PSObject.Properties.Match('Check').Count -gt 0) { if ($item.Check -match "False") { $isCheck = $false } }

                $script:AppCollection.Add([PSCustomObject]@{ 
                    Check=$isCheck; IconURL=$icon; Name=$item.Name; Status="Sẵn sàng"; StatusColor="Black"; WID=$item.WingetID; Progress=0; ProgressVisibility="Hidden" 
                })
            }
            $lstApps.ItemsSource = $script:AppCollection; Ghi-Log "✓ Đã nạp danh sách App Cloud thành công."
        } catch { Ghi-Log "❌ Lỗi kết nối máy chủ GitHub!" }
    }

    # --- HÀM CHẠY LỆNH VÀ BẮT LỖI THÔNG MINH ---
    function Run-InstallWithProgress($App, $FullCommand) {
        $pInfo = New-Object System.Diagnostics.ProcessStartInfo
        $pInfo.FileName = "cmd.exe"; $pInfo.Arguments = "/c `"$FullCommand`""; $pInfo.RedirectStandardOutput = $true; $pInfo.RedirectStandardError = $true
        $pInfo.UseShellExecute = $false; $pInfo.CreateNoWindow = $true
        
        $script:CurrentProc = New-Object System.Diagnostics.Process
        $script:CurrentProc.StartInfo = $pInfo
        
        $errorOutput = ""

        try {
            [void]$script:CurrentProc.Start()
            
            while (!$script:CurrentProc.HasExited) {
                # KIỂM TRA NÚT DỪNG LIÊN TỤC
                if ($script:HuyCaiDat) {
                    if ($script:CurrentProc) { Start-Process taskkill -ArgumentList "/F /T /PID $($script:CurrentProc.Id)" -WindowStyle Hidden -ErrorAction SilentlyContinue }
                    return -1 
                }

                $line = $script:CurrentProc.StandardOutput.ReadLine()
                if ($line) { 
                    Ghi-Log "   > $($line.Trim())" 
                    if ($line -match '(\d+)%') { 
                        $percent = $matches[1]
                        $window.Dispatcher.Invoke([action]{ $App.Progress = [int]$percent; $App.ProgressVisibility = "Visible" })
                    }
                    if ($line -match "0x8a15005e|certificate did not match|msstore") { $errorOutput += $line }
                }
                Do-Events
            }
            
            $exitCode = [int]$script:CurrentProc.ExitCode

            # CƠ CHẾ DỰ PHÒNG LỖI CHỨNG CHỈ MSSTORE
            if ($exitCode -ne 0 -and $errorOutput -match "certificate did not match|msstore") {
                Ghi-Log "⚠️ Lỗi chứng chỉ msstore. Đang chạy nguồn thay thế..."
                $fallbackCommand = $FullCommand -replace "winget install", "winget install --source winget"
                
                $pInfo.Arguments = "/c `"$fallbackCommand`""
                $script:CurrentProc = New-Object System.Diagnostics.Process
                $script:CurrentProc.StartInfo = $pInfo
                [void]$script:CurrentProc.Start()
                
                while (!$script:CurrentProc.HasExited) {
                    if ($script:HuyCaiDat) { Start-Process taskkill -ArgumentList "/F /T /PID $($script:CurrentProc.Id)" -WindowStyle Hidden -ErrorAction SilentlyContinue; return -1 }
                    $line = $script:CurrentProc.StandardOutput.ReadLine()
                    if ($line) { Ghi-Log "   [Retry] > $($line.Trim())"; Do-Events }
                }
                $exitCode = [int]$script:CurrentProc.ExitCode
            }
            return $exitCode
        } catch { return -99 } finally { $script:CurrentProc = $null }
    }

    # --- GIAO DIỆN XAML CHIA 2 CỘT (TRÁI LIST - PHẢI NÚT) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Client V67.2" Width="1150" Height="800" WindowStartupLocation="CenterScreen" Background="Transparent" AllowsTransparency="True" WindowStyle="None" ResizeMode="CanResize" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome><WindowChrome GlassFrameThickness="0" CornerRadius="15" CaptionHeight="35" ResizeBorderThickness="7" /></WindowChrome.WindowChrome>
    <Border Background="#F4F7F9" CornerRadius="15" BorderBrush="#1565C0" BorderThickness="1.5">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="35"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            
            <Grid Name="TitleBar" Grid.Row="0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="VietToolbox Client V67.2 - Auto Installer" Foreground="#888" VerticalAlignment="Center" Margin="5,0,0,0" FontWeight="Bold"/>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Width="40" Background="Transparent" BorderThickness="0" Cursor="Hand"/><Button Name="btnClose" Grid.Column="2" Content="✕" Width="40" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#D32F2F" FontWeight="Bold"/>
            </Grid>

            <Grid Grid.Row="1" Margin="0,10,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>     <ColumnDefinition Width="260"/>   </Grid.ColumnDefinitions>

                <Grid Grid.Column="0" Margin="0,0,15,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="150"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Margin="0,0,0,15">
                        <TextBlock Text="CÀI ĐẶT PHẦN MỀM HÀNG LOẠT" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/>
                        <TextBlock Text="Tự động hóa - An toàn - Nhanh chóng" Foreground="#666" FontSize="13"/>
                    </StackPanel>

                    <Border Grid.Row="1" Background="White" CornerRadius="10" Padding="12" Margin="0,0,0,15" BorderBrush="#E0E0E0" BorderThickness="1">
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <TextBlock Name="TxtWinget" Grid.Column="0" Text="Winget: Đang check" FontWeight="Bold" FontSize="13" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtChoco" Grid.Column="1" Text="Choco: Đang check" FontWeight="Bold" FontSize="13" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtTLS" Grid.Column="2" Text="TLS 1.3: Active" FontWeight="Bold" FontSize="13" HorizontalAlignment="Center" Foreground="#1565C0"/>
                        </Grid>
                    </Border>

                    <Border Grid.Row="2" Background="White" CornerRadius="10" BorderBrush="#E0E0E0" BorderThickness="1" ClipToBounds="True">
                        <ListView Name="LstApps" BorderThickness="0" Background="Transparent">
                            <ListView.View><GridView>
                                <GridViewColumn Width="45"><GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}" HorizontalAlignment="Center" VerticalAlignment="Center"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                                <GridViewColumn Header="LOGO" Width="60"><GridViewColumn.CellTemplate><DataTemplate><Image Source="{Binding IconURL}" Width="28" Height="28" RenderOptions.BitmapScalingMode="HighQuality"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                                <GridViewColumn Header="TÊN PHẦN MỀM" Width="280"><GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" FontSize="13" VerticalAlignment="Center"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                                <GridViewColumn Header="TIẾN TRÌNH CÀI ĐẶT" Width="400"><GridViewColumn.CellTemplate><DataTemplate>
                                    <StackPanel VerticalAlignment="Center" Margin="0,5,0,5">
                                        <TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontSize="12" Margin="0,0,0,3" FontWeight="SemiBold"/>
                                        <ProgressBar Value="{Binding Progress}" Height="7" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0" Visibility="{Binding ProgressVisibility}">
                                            <ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="3"/></Style></ProgressBar.Resources>
                                        </ProgressBar>
                                    </StackPanel>
                                </DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                            </GridView></ListView.View>
                        </ListView>
                    </Border>

                    <ProgressBar Name="PbTotal" Grid.Row="3" Height="8" Margin="0,15,0,10" Foreground="#0288D1" Background="#E0E0E0" BorderThickness="0">
                        <ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></ProgressBar.Resources>
                    </ProgressBar>
                    
                    <Border Grid.Row="4" CornerRadius="10" ClipToBounds="True" BorderThickness="0">
                        <TextBox Name="TxtLog" Background="#1E1E1E" Foreground="#4CAF50" IsReadOnly="True" Padding="12" FontFamily="Consolas" FontSize="11" BorderThickness="0" VerticalScrollBarVisibility="Auto"/>
                    </Border>
                </Grid>

                <Border Grid.Column="1" Background="White" CornerRadius="12" Padding="20" BorderBrush="#E0E0E0" BorderThickness="1">
                    <StackPanel>
                        <TextBlock Text="BẢNG ĐIỀU KHIỂN" FontWeight="Bold" Foreground="#1A237E" FontSize="18" Margin="0,0,0,20" HorizontalAlignment="Center"/>
                        
                        <Button Name="BtnReload" Content="🔄 NẠP LẠI CLOUD" Height="50" Margin="0,0,0,15" Background="#00897B" Foreground="White" FontWeight="Bold" Cursor="Hand">
                             <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                        
                        <Button Name="BtnQuet" Content="🔍 QUÉT MÁY" Height="50" Margin="0,0,0,15" Background="#546E7A" Foreground="White" FontWeight="Bold" Cursor="Hand">
                             <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                        
                        <Button Name="BtnSelect" Content="☑ CHỌN TẤT CẢ" Height="50" Margin="0,0,0,30" Background="#3949AB" Foreground="White" FontWeight="Bold" Cursor="Hand">
                             <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>

                        <Border Height="1" Background="#E0E0E0" Margin="0,0,0,30"/>

                        <Button Name="BtnInstall" Content="🚀 CÀI ĐẶT NGAY" Height="70" Margin="0,0,0,15" Background="#E65100" Foreground="White" FontSize="16" FontWeight="Bold" Cursor="Hand">
                             <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></Button.Resources>
                        </Button>
                        
                        <Button Name="BtnStop" Content="🛑 DỪNG KHẨN CẤP" Height="55" Margin="0,0,0,0" Background="#D32F2F" Foreground="White" FontSize="14" FontWeight="Bold" Cursor="Hand">
                             <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                        </Button>
                    </StackPanel>
                </Border>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
    $txtLog = $window.FindName("TxtLog"); $lstApps = $window.FindName("LstApps"); $pbTotal = $window.FindName("PbTotal")
    $txtWinget = $window.FindName("TxtWinget"); $txtChoco = $window.FindName("TxtChoco"); $txtTLS = $window.FindName("TxtTLS")
    
    # --- KẾT NỐI SỰ KIỆN GIAO DIỆN ---
    $window.FindName("TitleBar").Add_MouseLeftButtonDown({ $window.DragMove() })
    $window.FindName("btnMinimize").Add_Click({ $window.WindowState = "Minimized" })
    $window.FindName("btnClose").Add_Click({ $window.Close() })
    $window.FindName("BtnReload").Add_Click({ Tai-DanhSach })
    
    # --- CHỨC NĂNG: QUÉT MÁY ---
    $window.FindName("BtnQuet").Add_Click({
        Ghi-Log "[*] Đang quét các phần mềm đã cài trên máy..."
        $reg = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue).DisplayName
        foreach ($app in $script:AppCollection) {
            if ($reg -match [regex]::Escape($app.Name)) { $app.Status="Đã có"; $app.StatusColor="Gray"; $app.Check=$false; $app.Progress=100; $app.ProgressVisibility="Hidden" }
            else { $app.Status="Sẵn sàng"; $app.StatusColor="Black"; $app.Check=$true; $app.Progress=0; $app.ProgressVisibility="Hidden" }
        }
        $lstApps.Items.Refresh()
        Ghi-Log "✅ Quét xong! Đã bỏ chọn các phần mềm có sẵn."
    })
    
    # --- CHỨC NĂNG: CHỌN TẤT CẢ ---
    $window.FindName("BtnSelect").Add_Click({
        $script:SelectAllState = !$script:SelectAllState
        foreach ($app in $script:AppCollection) { if ($app.StatusColor -ne "Gray") { $app.Check = $script:SelectAllState } }
        $window.FindName("BtnSelect").Content = if ($script:SelectAllState) { "☐ BỎ CHỌN" } else { "☑ CHỌN TẤT CẢ" }
        $lstApps.Items.Refresh()
    })
    
    # --- CHỨC NĂNG: DỪNG KHẨN CẤP ---
    $window.FindName("BtnStop").Add_Click({ 
        $script:HuyCaiDat = $true
        Ghi-Log "🛑 ĐANG HỦY CÀI ĐẶT... VUI LÒNG ĐỢI!"
        if ($script:CurrentProc) {
            Start-Process taskkill -ArgumentList "/F /T /PID $($script:CurrentProc.Id)" -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
    })

    # --- CHỨC NĂNG: CÀI ĐẶT (TRÁI TIM CỦA TOOL) ---
    $window.FindName("BtnInstall").Add_Click({
        $target = @($script:AppCollection | Where-Object { $_.Check -eq $true })
        if ($target.Count -eq 0) { [System.Windows.MessageBox]::Show("Chưa chọn phần mềm nào!"); return }
        
        $window.FindName("BtnInstall").IsEnabled = $false
        $script:HuyCaiDat = $false
        $done = 0
        
        foreach ($app in $target) {
            if ($script:HuyCaiDat) { $app.Status="Đã hủy!"; $app.StatusColor="#D32F2F"; continue }

            $app.Status = "Đang cài đặt..."; $app.StatusColor = "#E65100"; $app.ProgressVisibility = "Visible"; $lstApps.Items.Refresh()
            
            $exit = Run-InstallWithProgress $app "winget install --id `"$($app.WID)`" --silent --accept-package-agreements --accept-source-agreements --force"
            
            if ($exit -eq -1) {
                $app.Status="Bị dừng ép buộc!"; $app.StatusColor="#D32F2F"; $app.Progress=0; $app.ProgressVisibility="Hidden"
            } elseif ($exit -eq 0 -or $exit -eq 3010) { 
                $app.Status="Cài đặt Thành Công!"; $app.StatusColor="#2E7D32"; $app.Progress=100; $app.ProgressVisibility="Collapsed"
            } else { 
                $app.Status="Lỗi cài đặt (Mã: $exit)"; $app.StatusColor="#D32F2F"; $app.Progress=0; $app.ProgressVisibility="Hidden"
            }
            
            $done++; $pbTotal.Value = ($done / $target.Count) * 100; $lstApps.Items.Refresh()
        }
        $window.FindName("BtnInstall").IsEnabled = $true; Ghi-Log "🏁 HOÀN TẤT TIẾN TRÌNH."
    })

    # KHỞI ĐỘNG CÁC HÀM
    $window.Add_ContentRendered({ Tai-DanhSach; Check-MoiTruong })
    $window.ShowDialog() | Out-Null
}

&$LogicInstallerV67