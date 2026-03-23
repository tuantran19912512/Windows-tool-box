# ==========================================================
# VIETTOOLBOX: BÁC SĨ WINDOWS (WPF - V63.7 FULL MIN/CLOSE)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# 1. ÉP QUYỀN ADMINISTRATOR
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. NẠP THƯ VIỆN WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicBacSiWindows_V63_7 = {
    $script:StopWatch = [System.Diagnostics.Stopwatch]::New()
    $script:IsRunning = $false
    $script:CurrentStep = 0 
    $script:SubProc = $null
    $script:LogContent = @("==========================================================","VIETTOOLBOX - BÁO CÁO SỬA LỖI WINDOWS","Ngày: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')","==========================================================")

    $Icon_Medic = [char]::ConvertFromUtf32(0x1FA7A); $Icon_Rocket = [char]::ConvertFromUtf32(0x1F680)
    $Icon_Finish = [char]::ConvertFromUtf32(0x1F3C1); $Icon_Stop = [char]::ConvertFromUtf32(0x1F6D1)

    # --- 3. GIAO DIỆN XAML (THANH TIÊU ĐỀ + MIN + CLOSE) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="550" Height="450"
        WindowStartupLocation="CenterScreen" Background="Transparent" FontFamily="Segoe UI" 
        AllowsTransparency="True" WindowStyle="None" ResizeMode="CanMinimize">
    
    <Window.Resources>
        <Storyboard x:Key="RepairAnimation" RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetName="rotateRepair" Storyboard.TargetProperty="Angle" From="0" To="360" Duration="0:0:3"/>
        </Storyboard>

        <Style x:Key="MinButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#0078D7"/>
            <Setter Property="Width" Value="40"/><Setter Property="Height" Value="35"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
            <Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#33FFFFFF"/></Trigger></Style.Triggers>
        </Style>

        <Style x:Key="CloseButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="Width" Value="45"/><Setter Property="Height" Value="35"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
            <Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#E81123"/></Trigger></Style.Triggers>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Foreground" Value="White"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>

    <Border Background="#2D2D2D" CornerRadius="12" BorderBrush="#3F3F3F" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="35"/><RowDefinition Height="*"/></Grid.RowDefinitions>

            <Grid Name="TitleBar" Grid.Row="0" Background="#252526">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="🩺 VietToolbox: Bác Sĩ Windows" Foreground="Gray" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="11"/>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Style="{StaticResource MinButtonStyle}"/>
                <Button Name="btnClose" Grid.Column="2" Content="✕" Style="{StaticResource CloseButtonStyle}" FontSize="14"/>
            </Grid>

            <Grid Grid.Row="1" Margin="25,10,25,25">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

                <DockPanel Grid.Row="0" Margin="0,0,0,20">
                    <TextBlock Name="txtStatusIcon" FontSize="20" Foreground="#00D4FF" VerticalAlignment="Center" Margin="0,0,8,0" FontFamily="Segoe UI Emoji">$Icon_Medic</TextBlock>
                    <TextBlock Name="iconRepair" FontSize="22" Margin="0,0,10,0" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5" Visibility="Collapsed" DockPanel.Dock="Left">
                        <TextBlock.RenderTransform><RotateTransform x:Name="rotateRepair" Angle="0"/></TextBlock.RenderTransform>
                        <Run FontFamily="Segoe UI Emoji" Text="&#x1F6E0;"/>
                    </TextBlock>
                    <TextBlock Name="txtStatus" Text="Sẵn sàng đại tu Windows..." FontSize="18" FontWeight="Bold" Foreground="#00D4FF" VerticalAlignment="Center" DockPanel.Dock="Left"/>
                    <TextBlock Name="txtTimer" Text="00:00" FontSize="16" Foreground="Gray" HorizontalAlignment="Right" VerticalAlignment="Center" FontFamily="Consolas"/>
                </DockPanel>

                <StackPanel Grid.Row="1" Margin="0,0,0,20">
                    <ProgressBar Name="pgBar" Height="25" Background="#333333" Foreground="#00D4FF" BorderThickness="0"/>
                    <TextBlock Name="txtDetail" Text="Bấm Bắt đầu để sửa lỗi và xuất báo cáo Desktop" Foreground="Gray" FontSize="12" FontStyle="Italic" Margin="0,8,0,0" HorizontalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap"/>
                </StackPanel>

                <GroupBox Grid.Row="2" Header="Sau khi hoàn tất sẽ:" Foreground="Gray" BorderBrush="#333333" Padding="10" Margin="0,0,0,20">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <RadioButton Name="rbNone" Content="Để nguyên" Foreground="#A0A0A0" Margin="10,0" IsChecked="True"/>
                        <RadioButton Name="rbRestart" Content="Khởi động lại" Foreground="#A0A0A0" Margin="10,0"/>
                        <RadioButton Name="rbShutdown" Content="Tắt máy" Foreground="#A0A0A0" Margin="10,0"/>
                    </StackPanel>
                </GroupBox>

                <Grid Grid.Row="3">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="btnStart" Grid.Column="0" Content="$Icon_Rocket BẮT ĐẦU SỬA LỖI" Height="50" Background="#27AE60"/>
                    <Button Name="btnStop" Grid.Column="2" Content="$Icon_Stop DỪNG LẠI" Height="50" Background="#D32F2F" IsEnabled="False"/>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $window = [Windows.Markup.XamlReader]::Load($DocXml)

    # Ánh xạ
    $TitleBar = $window.FindName("TitleBar"); $btnMinimize = $window.FindName("btnMinimize"); $btnClose = $window.FindName("btnClose")
    $txtStatusIcon = $window.FindName("txtStatusIcon"); $iconRepair = $window.FindName("iconRepair")
    $txtStatus = $window.FindName("txtStatus"); $txtTimer = $window.FindName("txtTimer")
    $txtDetail = $window.FindName("txtDetail"); $pgBar = $window.FindName("pgBar")
    $btnStart = $window.FindName("btnStart"); $btnStop = $window.FindName("btnStop")
    $rbRestart = $window.FindName("rbRestart"); $rbShutdown = $window.FindName("rbShutdown")
    $RepairAnim = $window.Resources["RepairAnimation"]

    # --- SỰ KIỆN THANH TIÊU ĐỀ ---
    $TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
    $btnMinimize.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    
    # Nút X đóng cửa sổ (Có dọn dẹp tiến trình ngầm)
    $btnClose.Add_Click({
        if ($script:IsRunning) {
            $Hoi = [System.Windows.MessageBox]::Show("Tiến trình đang chạy, ông có chắc muốn thoát không? (Lệnh sửa lỗi sẽ bị ngắt)", "Xác nhận thoát", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($Hoi -eq "No") { return }
            Start-Process cmd.exe -ArgumentList "/c taskkill /F /IM dism.exe /T 2>nul & taskkill /F /IM sfc.exe /T 2>nul" -WindowStyle Hidden
        }
        $window.Close()
    })

    # --- BỘ NÃO TIMER ---
    $MainTimer = New-Object System.Windows.Threading.DispatcherTimer
    $MainTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    
    $MainTimer.Add_Tick({
        $txtTimer.Text = "{0:00}:{1:00}" -f [math]::Floor($script:StopWatch.Elapsed.TotalMinutes), $script:StopWatch.Elapsed.Seconds
        if ($script:IsRunning -and $null -ne $script:SubProc) {
            if ($script:SubProc.HasExited) {
                $ExitCode = $script:SubProc.ExitCode
                switch ($script:CurrentStep) {
                    1 { $script:CurrentStep = 2; $pgBar.Value = 25 }
                    2 { if ($ExitCode -ne 0) { $script:CurrentStep = 3 } else { $script:CurrentStep = 4 }; $pgBar.Value = 50 }
                    3 { $script:CurrentStep = 4; $pgBar.Value = 75 }
                    4 { $script:CurrentStep = 5; $pgBar.Value = 100 }
                }
                $script:SubProc = $null
            } elseif ($pgBar.Value -lt 99) { $pgBar.Value += 0.05 }
        }

        if ($script:IsRunning -and $null -eq $script:SubProc) {
            switch ($script:CurrentStep) {
                1 { $script:CurrentStep = 2 } # Bỏ qua bước dọn dẹp Component (Rất lâu) để tăng tốc
                2 { $txtStatusIcon.Visibility = "Collapsed"; $iconRepair.Visibility = "Visible"; $txtStatus.Text = "🚀 Đang sửa lỗi (Tầng Offline)..."; $script:SubProc = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth /LimitAccess" -WindowStyle Hidden -PassThru }
                3 { $txtStatus.Text = "⚠️ Đang sửa lỗi (Tầng Online)..."; $script:SubProc = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -WindowStyle Hidden -PassThru }
                4 { $txtStatus.Text = "🔍 Đang chốt hạ file (SFC)..."; $script:SubProc = Start-Process "sfc.exe" -ArgumentList "/scannow" -WindowStyle Hidden -PassThru }
                5 {
                    $script:IsRunning = $false; $script:StopWatch.Stop(); $MainTimer.Stop(); $RepairAnim.Stop($window)
                    $DesktopPath = [System.Environment]::GetFolderPath('Desktop'); $FilePath = Join-Path $DesktopPath "Bao_Cao_Sua_Loi_Windows.txt"
                    $script:LogContent += "=========================================================="; $script:LogContent += "TỔNG KẾT: Xong trong $($txtTimer.Text)."; $script:LogContent | Out-File -FilePath $FilePath -Encoding UTF8
                    $txtStatusIcon.Visibility = "Visible"; $iconRepair.Visibility = "Collapsed"; $txtStatusIcon.Text = $Icon_Finish; $txtStatus.Text = "🏁 HOÀN TẤT!"; $txtStatus.Foreground = "#27AE60"
                    [System.Windows.MessageBox]::Show("Xong! Báo cáo ở Desktop.", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    if ($rbRestart.IsChecked) { Restart-Computer -Force } elseif ($rbShutdown.IsChecked) { Stop-Computer -Force }
                }
            }
        }
    })

    $btnStart.Add_Click({
        if ([System.Windows.MessageBox]::Show("Chạy sửa lỗi chuyên sâu (30-60p)?", "Xác nhận", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "Yes") {
            $script:IsRunning = $true; $script:CurrentStep = 2; $script:StopWatch.Start(); $MainTimer.Start()
            $btnStart.IsEnabled = $false; $btnStop.IsEnabled = $true; $RepairAnim.Begin($window)
        }
    })

    $btnStop.Add_Click({
        $script:IsRunning = $false; $MainTimer.Stop(); $RepairAnim.Stop($window)
        $txtStatusIcon.Visibility = "Visible"; $iconRepair.Visibility = "Collapsed"
        Start-Process cmd.exe -ArgumentList "/c taskkill /F /IM dism.exe /T 2>nul & taskkill /F /IM sfc.exe /T 2>nul" -WindowStyle Hidden
        $txtStatus.Text = "⛔ ĐÃ HỦY!"; $pgBar.Value = 0; $btnStart.IsEnabled = $true; $btnStop.IsEnabled = $false
    })

    $window.ShowDialog() | Out-Null
}

&$LogicBacSiWindows_V63_7