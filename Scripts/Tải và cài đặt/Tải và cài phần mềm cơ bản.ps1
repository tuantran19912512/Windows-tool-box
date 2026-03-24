# ==========================================================
# VIETTOOLBOX PRO INSTALLER (V53.6 - FIX SYNTAX ERROR)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# 1. ÉP QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$LogicInstallerV53_6 = {
    # Icon Unicode (Fix lỗi ô vuông)
    $Icon_Wrench = [char]::ConvertFromUtf32(0x1F6E0); $Icon_Rocket = [char]::ConvertFromUtf32(0x1F680) 
    $Icon_Check  = [char]::ConvertFromUtf32(0x2705); $Icon_Wait   = [char]::ConvertFromUtf32(0x23F3)  
    $Icon_Stop   = [char]::ConvertFromUtf32(0x1F6D1); $Icon_Gear   = [char]::ConvertFromUtf32(0x2699)

    # --- HÀM DOEVENTS CHUẨN (FIX LỖI CÚ PHÁP) ---
    $WPFDoEvents = {
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        $callback = [System.Windows.Threading.DispatcherOperationCallback] {
            param($f)
            $f.Continue = $false
            return $null
        }
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, $callback, $frame)
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }

    function Get-SmartIcon($name) {
        $Library = @{
            "Zalo"          = "https://stc-zalopro.zdn.vn/v2/pc/logo.png"
            "Chrome"        = "https://cdn-icons-png.flaticon.com/512/888/888846.png"
            "Coc Coc"       = "https://upload.wikimedia.org/wikipedia/vi/3/3b/Coccoc_logo.png"
            "Unikey"        = "https://www.unikey.org/assets/img/unikey_logo.png"
            "UltraViewer"   = "https://ultraviewer.net/favicon.ico"
            "TeamViewer"    = "https://cdn-icons-png.flaticon.com/512/888/888871.png"
            "Office"        = "https://cdn-icons-png.flaticon.com/512/732/732228.png"
        }
        foreach ($key in $Library.Keys) { if ($name -match $key) { return $Library[$key] } }
        return "https://cdn-icons-png.flaticon.com/512/1243/1243968.png"
    }

    # --- 2. GIAO DIỆN XAML ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="1050" Height="850" 
        WindowStartupLocation="CenterScreen" Background="Transparent" 
        AllowsTransparency="True" WindowStyle="None" FontFamily="Segoe UI">
    
    <Window.Resources>
        <Storyboard x:Key="RepairAnimation" RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetName="rotateRepair" Storyboard.TargetProperty="Angle" From="0" To="360" Duration="0:0:3"/>
        </Storyboard>
        <Style x:Key="TitleButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#858585"/><Setter Property="Width" Value="45"/><Setter Property="Height" Value="35"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>

    <Border Background="#F4F7F9" CornerRadius="15" BorderBrush="#007ACC" BorderThickness="1">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="35"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="150"/><RowDefinition Height="70"/>
            </Grid.RowDefinitions>

            <Grid Name="TitleBar" Grid.Row="0" Background="Transparent" Margin="-20,-20,-20,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="20,0,0,0">
                    <TextBlock Name="iconRepair" FontSize="18" Margin="0,0,10,0" RenderTransformOrigin="0.5,0.5" Visibility="Collapsed" FontFamily="Segoe UI Emoji">
                        <TextBlock.RenderTransform><RotateTransform x:Name="rotateRepair" Angle="0"/></TextBlock.RenderTransform>
                        <Run Text="&#x1F6E0;"/>
                    </TextBlock>
                    <TextBlock Foreground="#666" FontSize="12" FontWeight="Bold" Text="VietToolbox Pro Installer 2026"/>
                </StackPanel>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Style="{StaticResource TitleButtonStyle}"/>
                <Button Name="btnClose" Grid.Column="2" Content="✕" FontSize="14">
                    <Button.Style><Style TargetType="Button" BasedOn="{StaticResource TitleButtonStyle}"><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#E81123"/><Setter Property="Foreground" Value="White"/></Trigger></Style.Triggers></Style></Button.Style>
                </Button>
            </Grid>

            <StackPanel Grid.Row="1" Margin="0,15,0,15">
                <TextBlock Text="HỆ THỐNG CÀI ĐẶT TỰ ĐỘNG PRO" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/>
                <TextBlock Text="Đại tu môi trường &amp; Fix lỗi WinGet 0x8a15005e" Foreground="#666"/>
            </StackPanel>

            <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#DDD" BorderThickness="1">
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <TextBlock Name="TxtWinget" Grid.Column="0" FontWeight="Bold" FontFamily="Segoe UI Emoji, Segoe UI"/>
                    <TextBlock Name="TxtChoco" Grid.Column="1" FontWeight="Bold" FontFamily="Segoe UI Emoji, Segoe UI"/>
                </Grid>
            </Border>

            <ListView Name="LstApps" Grid.Row="3" Background="White" BorderThickness="1" BorderBrush="#DDD">
                <ListView.View>
                    <GridView>
                        <GridViewColumn Width="45">
                            <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="LOGO" Width="65">
                            <GridViewColumn.CellTemplate><DataTemplate><Image Source="{Binding IconURL}" Width="32" Height="32" RenderOptions.BitmapScalingMode="HighQuality"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="TÊN PHẦN MỀM" DisplayMemberBinding="{Binding Name}" Width="350"/>
                        <GridViewColumn Header="TRẠNG THÁI" Width="220">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="Bold"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                    </GridView>
                </ListView.View>
            </ListView>

            <ProgressBar Name="PbTotal" Grid.Row="4" Height="10" Margin="0,15,0,5" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>
            <TextBox Name="TxtLog" Grid.Row="5" Background="#1E1E1E" Foreground="#00FF00" IsReadOnly="True" FontFamily="Consolas" FontSize="12" Padding="10"/>

            <Grid Grid.Row="6" Margin="0,10,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="150"/><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="60"/></Grid.ColumnDefinitions>
                <Button Name="BtnReload" Content="NẠP LẠI" Height="45" Background="#2E7D32" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
                <Button Name="BtnQuet" Grid.Column="1" Content="QUÉT MÁY" Height="45" Background="#455A64" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
                <Button Name="BtnSelect" Grid.Column="2" Content="CHỌN TẤT CẢ" Height="45" Background="#1565C0" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
                <Button Name="BtnInstall" Grid.Column="3" Height="45" Background="#E65100" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
                <Button Name="BtnStop" Grid.Column="4" Height="45" Background="#C62828" Foreground="White" FontWeight="Bold"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))

    # Ánh xạ & Gán nội dung
    $txtWinget = $window.FindName("TxtWinget"); $txtChoco = $window.FindName("TxtChoco")
    $btnInstall = $window.FindName("BtnInstall"); $btnInstall.Content = "$Icon_Rocket BẮT ĐẦU CÀI ĐẶT"
    $btnStop = $window.FindName("BtnStop"); $btnStop.Content = $Icon_Stop
    $lstApps = $window.FindName("LstApps"); $txtLog = $window.FindName("TxtLog")
    $RepairAnim = $window.Resources["RepairAnimation"]; $iconRepair = $window.FindName("iconRepair")
    
    $window.FindName("TitleBar").Add_MouseLeftButtonDown({ $window.DragMove() })
    $window.FindName("btnMinimize").Add_Click({ $window.WindowState = "Minimized" })
    $window.FindName("btnClose").Add_Click({ $window.Close() })

    function Ghi-Log($msg) {
        $window.Dispatcher.Invoke([action]{ $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n"); $txtLog.ScrollToEnd() })
        &$WPFDoEvents
    }

    function CaiDat-MoiTruong {
        $iconRepair.Visibility = "Visible"; $RepairAnim.Begin($window)
        $txtWinget.Text = "$Icon_Wait Đang check Winget..."
        $txtChoco.Text = "$Icon_Wait Đang check Choco..."
        &$WPFDoEvents

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $txtWinget.Text = "$Icon_Check Winget: Sẵn sàng"; $txtWinget.Foreground = "Green"
            $Global:WingetReady = $true
        } else {
            Ghi-Log "[*] Đang fix lỗi Winget 0x8a15005e..."
            try {
                $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                (New-Object System.Net.WebClient).DownloadFile($url, "$env:TEMP\winget.msixbundle")
                Add-AppxPackage -Path "$env:TEMP\winget.msixbundle" -ErrorAction Stop
                $Global:WingetReady = $true
                $txtWinget.Text = "$Icon_Check Winget: Đã Fix!"; $txtWinget.Foreground = "Green"
            } catch { $txtWinget.Text = "❌ Lỗi Winget"; $txtWinget.Foreground = "Red" }
        }

        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $txtChoco.Text = "$Icon_Check Choco: Sẵn sàng"; $txtChoco.Foreground = "Green"; $Global:ChocoReady = $true
        } else {
            $txtChoco.Text = "$Icon_Gear Đang nạp Choco..."; Ghi-Log "[*] Đang cài Chocolatey..."
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"; $Global:ChocoReady = $true
                $txtChoco.Text = "$Icon_Check Choco: Sẵn sàng"; $txtChoco.Foreground = "Green"
            } catch { $txtChoco.Text = "❌ Lỗi Choco"; $txtChoco.Foreground = "Red" }
        }
        $RepairAnim.Stop($window); $iconRepair.Visibility = "Collapsed"
    }

    function Tai-DanhSach {
        try {
            $url = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhSachPhanMem.csv"
            $data = (New-Object System.Net.WebClient).DownloadString($url + "?t=" + (Get-Date).Ticks) | ConvertFrom-Csv
            $appList = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
            foreach ($item in $data) {
                $finalIcon = if ($item.IconURL -and $item.IconURL -match "http") { $item.IconURL } else { Get-SmartIcon $item.Name }
                $appList.Add([PSCustomObject]@{ Check = $true; IconURL = $finalIcon; Name = $item.Name; Status = "Chờ..."; StatusColor = "Black"; WID = $item.WingetID; CID = $item.ChocoID; GID = $item.GDriveID; Args = $item.SilentArgs })
            }
            $lstApps.ItemsSource = $appList
            Ghi-Log "✓ Đã nạp xong danh sách App."
        } catch { Ghi-Log "❌ Lỗi nạp danh sách App!" }
    }

    # --- KHỞI CHẠY ---
    $window.Add_ContentRendered({ 
        Tai-DanhSach
        CaiDat-MoiTruong 
    })

    $window.ShowDialog() | Out-Null
}

&$LogicInstallerV53_6