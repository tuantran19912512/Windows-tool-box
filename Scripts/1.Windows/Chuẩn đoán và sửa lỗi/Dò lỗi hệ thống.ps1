# ==========================================================
# VIETTOOLBOX: CHẨN ĐOÁN PRO (WPF V69.6 - FIX ĐƠ & KÍNH LÚP CHẠY)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicChanDoanProV69_6 = {
    $script:ReportData = [PSCustomObject]@{ SFC = "Chưa quét"; DISM = "Chưa quét"; Latency = 0; Processes = 0; Status = "OK" }
    $script:StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $script:UserStopped = $false
    $script:CurrentStep = 0 # 0: SFC, 1: DISM, 2: Done
    $script:SubProcess = $null

    # --- 1. GIAO DIỆN XAML PURE WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="520" Height="380"
        WindowStartupLocation="CenterScreen" Background="Transparent" FontFamily="Segoe UI" 
        AllowsTransparency="True" WindowStyle="None">
    
    <Window.Resources>
        <Storyboard x:Key="ScanAnimation" RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetName="ScanIcon" 
                             Storyboard.TargetProperty="(Canvas.Left)"
                             From="20" To="420" Duration="0:0:2" AutoReverse="True">
                <DoubleAnimation.EasingFunction>
                    <QuadraticEase EasingMode="EaseInOut"/>
                </DoubleAnimation.EasingFunction>
            </DoubleAnimation>
        </Storyboard>

        <Style x:Key="TitleBarButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#0078D7"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="Width" Value="40"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="#2D2D2D" CornerRadius="12" BorderBrush="#3F3F3F" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid Name="TitleBar" Grid.Row="0" Background="#252526" Height="35">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="VietToolbox Pro - Chẩn Đoán Hệ Thống" Foreground="Gray" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="11"/>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Style="{StaticResource TitleBarButtonStyle}" Margin="0,0,5,0"/>
            </Grid>

            <Grid Grid.Row="1" Margin="25,15,25,25">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="50"/> <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <DockPanel Grid.Row="0" Margin="0,0,0,15">
                    <TextBlock Name="txtStatus" Text="🔍 Đang khởi tạo..." FontSize="18" FontWeight="Bold" Foreground="#0078D7" VerticalAlignment="Center"/>
                    <TextBlock Name="txtTimer" Text="00:00" FontFamily="Consolas" FontSize="16" Foreground="#0078D7" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </DockPanel>

                <Border Grid.Row="1" Height="15" Background="#424242" CornerRadius="7" ClipToBounds="True">
                    <ProgressBar Name="pgBar" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0" Foreground="#0078D7" IsIndeterminate="True"/>
                </Border>

                <Canvas Grid.Row="2" VerticalAlignment="Center">
                    <TextBlock Name="ScanIcon" Text="🔍" FontSize="26" Canvas.Top="5"/>
                </Canvas>

                <TextBlock Name="txtDetail" Grid.Row="3" Text="Đang chuẩn bị nội soi..." Foreground="#A0A0A0" FontSize="13" 
                           FontStyle="Italic" HorizontalAlignment="Center" VerticalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center"/>

                <Button Name="btnHuy" Grid.Row="4" Content="⛔ HỦY BỎ QUÉT" Width="160" Height="40" Background="#D32F2F" Foreground="White" FontWeight="Bold" Margin="0,15,0,10">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>

                <TextBlock Grid.Row="5" Text="Tiến trình dự kiến 3-10 phút. Vui lòng không tắt máy." Foreground="#666666" FontSize="11" HorizontalAlignment="Center"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $window = [Windows.Markup.XamlReader]::Load($DocXml)

    $TitleBar = $window.FindName("TitleBar")
    $btnMinimize = $window.FindName("btnMinimize")
    $txtStatus = $window.FindName("txtStatus")
    $txtTimer = $window.FindName("txtTimer")
    $txtDetail = $window.FindName("txtDetail")
    $pgBar = $window.FindName("pgBar")
    $btnHuy = $window.FindName("btnHuy")
    $ScanAnim = $window.Resources["ScanAnimation"]

    # --- SỰ KIỆN GIAO DIỆN ---
    $TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
    $btnMinimize.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    $btnHuy.Add_Click({ 
        $script:UserStopped = $true
        if ($null -ne $script:SubProcess) { try { Stop-Process -Id $script:SubProcess.Id -Force } catch {} }
        $window.Close() 
    })

    # --- BỘ NÃO XỬ LÝ (KHÔNG GÂY ĐƠ) ---
    $MainTimer = New-Object System.Windows.Threading.DispatcherTimer
    $MainTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $MainTimer.Add_Tick({
        # 1. Cập nhật đồng hồ
        $txtTimer.Text = "{0:00}:{1:00}" -f $script:StopWatch.Elapsed.Minutes, $script:StopWatch.Elapsed.Seconds

        # 2. Quản lý các bước quét (State Machine)
        if ($script:UserStopped) { $MainTimer.Stop(); return }

        switch ($script:CurrentStep) {
            0 { # BẮT ĐẦU QUÉT SFC
                $txtStatus.Text = "📊 Đang nội soi File hệ thống..."
                $txtDetail.Text = "SFC đang kiểm tra tính toàn vẹn của tệp tin hệ thống Windows."
                $script:SubProcess = Start-Process "cmd.exe" -ArgumentList "/c sfc /verifyonly" -WindowStyle Hidden -PassThru
                $script:CurrentStep = 0.5 # Trạng thái đang đợi SFC
            }
            0.5 { # ĐỢI SFC XONG
                if ($script:SubProcess.HasExited) {
                    $script:ReportData.SFC = if ($script:SubProcess.ExitCode -eq 0) { "Tốt" } else { "Bị lỗi" }
                    if ($script:SubProcess.ExitCode -ne 0) { $script:ReportData.Status = "FAIL" }
                    $script:CurrentStep = 1 # Chuyển sang DISM
                    $pgBar.Value = 50; $pgBar.IsIndeterminate = $false
                }
            }
            1 { # BẮT ĐẦU QUÉT DISM
                $txtStatus.Text = "💾 Đang quét kho ảnh Windows..."
                $txtDetail.Text = "DISM đang kiểm tra lỗi trong Component Store (Kho ảnh nguồn)."
                $pgBar.IsIndeterminate = $true
                $script:SubProcess = Start-Process "cmd.exe" -ArgumentList "/c dism /online /cleanup-image /checkhealth" -WindowStyle Hidden -PassThru
                $script:CurrentStep = 1.5 # Trạng thái đang đợi DISM
            }
            1.5 { # ĐỢI DISM XONG
                if ($script:SubProcess.HasExited) {
                    $script:ReportData.DISM = if ($script:SubProcess.ExitCode -eq 0) { "Sạch" } else { "Bị hỏng" }
                    if ($script:SubProcess.ExitCode -ne 0) { $script:ReportData.Status = "FAIL" }
                    $script:CurrentStep = 2 # Hoàn tất
                }
            }
            2 { # TỔNG HỢP VÀ KẾT THÚC
                $MainTimer.Stop()
                $perf = Get-Counter -Counter "\PhysicalDisk(_Total)\Avg. Disk sec/Read" -MaxSamples 1 -ErrorAction SilentlyContinue
                $script:ReportData.Latency = if ($perf) { [int]($perf.CounterSamples[0].CookedValue * 1000) } else { 0 }
                $script:ReportData.Processes = (Get-Process).Count
                $window.Close()
                Show-Ket-Qua-Pro
            }
        }
    })

    $window.Add_ContentRendered({
        $ScanAnim.Begin($window) # Chạy kính lúp
        $MainTimer.Start()       # Chạy bộ não xử lý
    })

    $window.ShowDialog() | Out-Null
}

# --- HÀM HIỆN KẾT QUẢ ---
function Show-Ket-Qua-Pro {
    $xamlRes = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Kết Quả Chẩn Đoán" Width="500" Height="500" WindowStartupLocation="CenterScreen" 
        Background="#1E1E1E" FontFamily="Segoe UI" ResizeMode="NoResize">
    <Grid Margin="30">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <RowDefinition Height="*"/>    <RowDefinition Height="Auto"/> </Grid.RowDefinitions>

        <TextBlock Text="KẾT QUẢ CHẨN ĐOÁN PRO" FontSize="22" FontWeight="Bold" Foreground="#0078D7" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <Border Grid.Row="1" Background="#2D2D2D" CornerRadius="10" Padding="25" VerticalAlignment="Stretch">
            <StackPanel VerticalAlignment="Center">
                <TextBlock Text="✅ File hệ thống: $($script:ReportData.SFC)" FontSize="16" Foreground="White" Margin="0,8"/>
                <TextBlock Text="📦 Kho ảnh Windows: $($script:ReportData.DISM)" FontSize="16" Foreground="White" Margin="0,8"/>
                <TextBlock Text="💾 Độ trễ ổ cứng: $($script:ReportData.Latency) ms" FontSize="16" Foreground="#A0A0A0" Margin="0,8"/>
                <TextBlock Text="📊 Tiến trình ngầm: $($script:ReportData.Processes) cái" FontSize="16" Foreground="#A0A0A0" Margin="0,8"/>
                
                <Separator Background="#3F3F3F" Margin="0,20"/>
                
                <TextBlock Text="$(if ($script:ReportData.Status -eq 'OK') { 'MÁY ĐANG HOẠT ĐỘNG TỐT' } else { 'CẦN CHẠY BỘ SỬA LỖI CHUYÊN SÂU' })" 
                           FontSize="18" FontWeight="Bold" 
                           Foreground="$(if ($script:ReportData.Status -eq 'OK') { '#388E3C' } else { '#D32F2F' })" 
                           HorizontalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap"/>
            </StackPanel>
        </Border>

        <Button Name="btnOk" Grid.Row="2" Content="ĐÃ HIỂU" Width="150" Height="45" Background="#0078D7" Foreground="White" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,25,0,0">
            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
        </Button>
    </Grid>
</Window>
"@
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xamlRes)
    $resWindow = [Windows.Markup.XamlReader]::Load($reader)
    
    # Tìm và gán sự kiện cho nút OK
    $btnOk = $resWindow.FindName("btnOk")
    $btnOk.Add_Click({ $resWindow.Close() })
    
    $resWindow.ShowDialog() | Out-Null
}

&$LogicChanDoanProV69_6