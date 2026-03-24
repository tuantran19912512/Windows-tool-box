# ==========================================================
# VIETTOOLBOX PRO INSTALLER (V66.0 - TRUE FULL OPTION)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc trị: Full Môi Trường + Multi-Progress + Fix Font + TLS 1.3
# ==========================================================

# 1. BẢO HIỂM KẾT NỐI (TLS 1.2 + 1.3)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# 2. ÉP QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$LogicInstallerV66 = {
    $script:AppCollection = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $script:HuyCaiDat = $false; $script:CurrentProc = $null; $script:SelectAllState = $true

    $Icon_Rocket = [char]::ConvertFromUtf32(0x1F680); $Icon_Stop = [char]::ConvertFromUtf32(0x1F6D1)
    $Icon_Check = [char]::ConvertFromUtf32(0x2705); $Icon_Wait = [char]::ConvertFromUtf32(0x23F3)

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

    # --- HÀM CHẠY LỆNH LIVE LOG & BẮT % TIẾN TRÌNH ---
    function Run-InstallWithProgress($App, $FullCommand) {
        $pInfo = New-Object System.Diagnostics.ProcessStartInfo
        $pInfo.FileName = "cmd.exe"; $pInfo.Arguments = "/c `"$FullCommand`""; $pInfo.RedirectStandardOutput = $true; $pInfo.RedirectStandardError = $true
        $pInfo.UseShellExecute = $false; $pInfo.CreateNoWindow = $true
        $script:CurrentProc = New-Object System.Diagnostics.Process
        $script:CurrentProc.StartInfo = $pInfo
        try {
            [void]$script:CurrentProc.Start()
            while (!$script:CurrentProc.HasExited) {
                if ($script:HuyCaiDat) { Start-Process taskkill -ArgumentList "/F /T /PID $($script:CurrentProc.Id)" -WindowStyle Hidden -ErrorAction SilentlyContinue; return -1 }
                $line = $script:CurrentProc.StandardOutput.ReadLine()
                if ($line) { 
                    Ghi-Log "   > $($line.Trim())" 
                    if ($line -match '(\d+)%') { 
                        $percent = $matches[1]
                        $window.Dispatcher.Invoke([action]{ $App.Progress = [int]$percent; $App.ProgressVisibility = "Visible" })
                    }
                }
                Do-Events
            }
            return [int]$script:CurrentProc.ExitCode
        } catch { return -99 } finally { $script:CurrentProc = $null }
    }

    # --- GIAO DIỆN XAML (ĐÃ ĐƯA KHUNG KIỂM TRA MÔI TRƯỜNG TRỞ LẠI) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="1100" Height="880" WindowStartupLocation="CenterScreen" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" ResizeMode="CanMinimize" FontFamily="Segoe UI">
    <Border Background="#F4F7F9" CornerRadius="15" BorderBrush="#007ACC" BorderThickness="1">
        <Grid Margin="20">
            <Grid.RowDefinitions><RowDefinition Height="35"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="150"/><RowDefinition Height="70"/></Grid.RowDefinitions>
            
            <Grid Name="TitleBar" Grid.Row="0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="VietToolbox Pro Installer V66.0 - Full Option" Foreground="#666" VerticalAlignment="Center" Margin="15,0,0,0" FontWeight="Bold"/>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Width="45" Background="Transparent" BorderThickness="0"/><Button Name="btnClose" Grid.Column="2" Content="✕" Width="45" Background="Transparent" BorderThickness="0"/>
            </Grid>

            <StackPanel Grid.Row="1" Margin="0,5,0,10"><TextBlock Text="HỆ THỐNG CÀI ĐẶT THÔNG MINH" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/><TextBlock Text="Đầy đủ: Kiểm tra môi trường + Live Progress + Fix Font Cốc Cốc" Foreground="#666"/></StackPanel>
            
            <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#DDD" BorderThickness="1">
                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <TextBlock Name="TxtWinget" Grid.Column="0" FontWeight="Bold" VerticalAlignment="Center"/><TextBlock Name="TxtChoco" Grid.Column="1" FontWeight="Bold" VerticalAlignment="Center"/><TextBlock Name="TxtTLS" Grid.Column="2" FontWeight="Bold" VerticalAlignment="Center"/></Grid>
            </Border>

            <ListView Name="LstApps" Grid.Row="3" Background="White" BorderThickness="1" BorderBrush="#DDD">
                <ListView.View><GridView>
                    <GridViewColumn Width="40"><GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}" VerticalAlignment="Center"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                    <GridViewColumn Header="LOGO" Width="60"><GridViewColumn.CellTemplate><DataTemplate><Image Source="{Binding IconURL}" Width="28" Height="28" RenderOptions.BitmapScalingMode="HighQuality"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                    <GridViewColumn Header="TÊN PHẦN MỀM" Width="300"><GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" VerticalAlignment="Center" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                    <GridViewColumn Header="TIẾN TRÌNH CHI TIẾT" Width="280"><GridViewColumn.CellTemplate><DataTemplate>
                        <StackPanel VerticalAlignment="Center" Width="250">
                            <TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontSize="11" Margin="0,0,0,2"/><ProgressBar Value="{Binding Progress}" Height="6" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0" Visibility="{Binding ProgressVisibility}"/>
                        </StackPanel>
                    </DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                </GridView></ListView.View>
            </ListView>

            <ProgressBar Name="PbTotal" Grid.Row="4" Height="10" Margin="0,15,0,5" Foreground="#0277BD" Background="#DDD" BorderThickness="0"/>
            <TextBox Name="TxtLog" Grid.Row="5" Background="#1E1E1E" Foreground="#00FF00" IsReadOnly="True" Padding="10" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"/>

            <Grid Grid.Row="6" Margin="0,10,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="150"/><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="60"/></Grid.ColumnDefinitions>
                <Button Name="BtnReload" Content="NẠP LẠI" Height="45" Background="#2E7D32" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/><Button Name="BtnQuet" Grid.Column="1" Content="QUÉT MÁY" Height="45" Background="#455A64" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/><Button Name="BtnSelect" Grid.Column="2" Content="CHỌN TẤT CẢ" Height="45" Background="#1565C0" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/><Button Name="BtnInstall" Grid.Column="3" Content="CÀI ĐẶT NGAY" Height="45" Background="#E65100" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand"/><Button Name="BtnStop" Grid.Column="4" Content="DỪNG" Height="45" Background="#C62828" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
    $txtLog = $window.FindName("TxtLog"); $lstApps = $window.FindName("LstApps"); $pbTotal = $window.FindName("PbTotal")
    $txtWinget = $window.FindName("TxtWinget"); $txtChoco = $window.FindName("TxtChoco"); $txtTLS = $window.FindName("TxtTLS")
    
    # --- HÀM TỰ ĐỘNG CÀI ĐẶT MÔI TRƯỜNG (WINGET + CHOCO) ---
function Check-MoiTruong {
    $txtTLS.Text = "🛡️ TLS 1.3: Active"; $txtTLS.Foreground = "Blue"
    Ghi-Log "[*] Đang kiểm tra môi trường hệ thống..."

    # 1. KIỂM TRA & CÀI ĐẶT WINGET (Dành cho Win 10/11)
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        $txtWinget.Text = "⏳ Đang cài Winget..."; $txtWinget.Foreground = "Orange"
        Ghi-Log "[!] Không tìm thấy Winget. Đang tự động cài đặt từ Microsoft Store..."
        try {
            # Tải gói cài đặt App Installer trực tiếp từ MS Server
            $urlWinget = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $pathWinget = "$env:TEMP\WingetInstaller.msixbundle"
            (New-Object System.Net.WebClient).DownloadFile($urlWinget, $pathWinget)
            Add-AppxPackage -Path $pathWinget
            $txtWinget.Text = "$Icon_Check Winget: OK"; $txtWinget.Foreground = "Green"
            Ghi-Log "✅ Cài đặt Winget thành công."
        } catch {
            Ghi-Log "❌ Lỗi cài Winget: $($_.Exception.Message)"
            $txtWinget.Text = "❌ Winget Lỗi"; $txtWinget.Foreground = "Red"
        }
    } else {
        $txtWinget.Text = "$Icon_Check Winget: OK"; $txtWinget.Foreground = "Green"
    }

    # 2. KIỂM TRA & CÀI ĐẶT CHOCOLATEY (Dùng để bổ trợ khi Winget thiếu app)
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        $txtChoco.Text = "⏳ Đang cài Choco..."; $txtChoco.Foreground = "Orange"
        Ghi-Log "[!] Đang cài đặt Chocolatey (Môi trường bổ trợ)..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $txtChoco.Text = "$Icon_Check Choco: OK"; $txtChoco.Foreground = "Green"
            Ghi-Log "✅ Cài đặt Chocolatey thành công."
        } catch {
            Ghi-Log "❌ Lỗi cài Choco: $($_.Exception.Message)"
            $txtChoco.Text = "❌ Choco Lỗi"; $txtChoco.Foreground = "Red"
        }
    } else {
        $txtChoco.Text = "$Icon_Check Choco: OK"; $txtChoco.Foreground = "Green"
    }
    
    Do-Events
}

    # --- KẾT NỐI NÚT BẤM (HÀN CHẾT) ---
    $window.FindName("TitleBar").Add_MouseLeftButtonDown({ $window.DragMove() })
    $window.FindName("btnMinimize").Add_Click({ $window.WindowState = "Minimized" })
    $window.FindName("btnClose").Add_Click({ $window.Close() })
    $window.FindName("BtnReload").Add_Click({ Tai-DanhSach })
    $window.FindName("BtnQuet").Add_Click({
        Ghi-Log "[*] Đang quét máy..."
        $reg = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue).DisplayName
        foreach ($app in $script:AppCollection) {
            if ($reg -match [regex]::Escape($app.Name)) { $app.Status="Đã có"; $app.StatusColor="Gray"; $app.Check=$false; $app.Progress=100 }
            else { $app.Status="Sẵn sàng"; $app.StatusColor="Black"; $app.Check=$true; $app.Progress=0 }
        }
        $lstApps.Items.Refresh()
    })
    $window.FindName("BtnSelect").Add_Click({
        $script:SelectAllState = !$script:SelectAllState
        foreach ($app in $script:AppCollection) { if ($app.StatusColor -ne "Gray") { $app.Check = $script:SelectAllState } }
        $window.FindName("BtnSelect").Content = if ($script:SelectAllState) { "BỎ CHỌN" } else { "CHỌN TẤT CẢ" }
        $lstApps.Items.Refresh()
    })
    $window.FindName("BtnStop").Add_Click({ $script:HuyCaiDat = $true; Ghi-Log "🛑 ĐÃ DỪNG LỆNH!" })

    $window.FindName("BtnInstall").Add_Click({
        $target = @($script:AppCollection | Where-Object { $_.Check -eq $true })
        if ($target.Count -eq 0) { return }
        $window.FindName("BtnInstall").IsEnabled = $false; $script:HuyCaiDat = $false; $done = 0
        foreach ($app in $target) {
            if ($script:HuyCaiDat) { $app.Status="Đã hủy"; $app.StatusColor="Red"; continue }
            $app.Status = "Đang tải..."; $app.StatusColor = "#E65100"; $app.ProgressVisibility = "Visible"; $lstApps.Items.Refresh()
            $exit = Run-InstallWithProgress $app "winget install --id `"$($app.WID)`" --silent --accept-package-agreements --accept-source-agreements --force"
            if ($exit -eq 0 -or $exit -eq 3010) { $app.Status="Xong!"; $app.StatusColor="Green"; $app.Progress=100 }
            else { $app.Status="Lỗi!"; $app.StatusColor="Red"; $app.Progress=0 }
            $done++; $pbTotal.Value = ($done / $target.Count) * 100; $lstApps.Items.Refresh()
        }
        $window.FindName("BtnInstall").IsEnabled = $true; Ghi-Log "🏁 HOÀN TẤT."
    })

    function Tai-DanhSach {
        try {
            $wc = New-Object System.Net.WebClient; $wc.Encoding = [System.Text.Encoding]::UTF8
            $data = $wc.DownloadString("https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv?t=" + (Get-Date).Ticks) | ConvertFrom-Csv
            $script:AppCollection.Clear()
            foreach ($item in $data) {
                $icon = if($item.IconURL -match "http"){$item.IconURL} else {"https://cdn-icons-png.flaticon.com/512/1243/1243968.png"}
                $script:AppCollection.Add([PSCustomObject]@{ Check=$true; IconURL=$icon; Name=$item.Name; Status="Sẵn sàng"; StatusColor="Black"; WID=$item.WingetID; Progress=0; ProgressVisibility="Hidden" })
            }
            $lstApps.ItemsSource = $script:AppCollection; Ghi-Log "✓ Đã nạp danh sách App Cloud."
        } catch { Ghi-Log "❌ Lỗi nạp dữ liệu!" }
    }

    $window.Add_ContentRendered({ Tai-DanhSach; Check-MoiTruong })
    $window.ShowDialog() | Out-Null
}

&$LogicInstallerV66