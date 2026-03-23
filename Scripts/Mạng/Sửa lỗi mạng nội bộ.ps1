# ==========================================================
# VIETTOOLBOX: CHUYÊN GIA MÁY IN & LAN (WPF - V64.1)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# 1. ÉP QUYỀN ADMINISTRATOR
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. NẠP THƯ VIỆN WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicFixMayInLAN_V64 = {
    # --- BIẾN ĐIỀU KHIỂN & BÁO CÁO ---
    $script:StopWatch = [System.Diagnostics.Stopwatch]::New()
    $script:IsRunning = $false
    $script:CurrentStep = 0 
    $script:SubProc = $null
    $script:LogReport = @("==========================================================","VIETTOOLBOX - BÁO CÁO FIX MÁY IN & LAN","Ngày: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')","==========================================================")

    # Icon Unicode
    $Icon_Medic = [char]::ConvertFromUtf32(0x1FA7A)
    $Icon_Rocket = [char]::ConvertFromUtf32(0x1F680)
    $Icon_Finish = [char]::ConvertFromUtf32(0x1F3C1)
    $Icon_Stop = [char]::ConvertFromUtf32(0x1F6D1)

    # --- 3. GIAO DIỆN XAML (THANH TIÊU ĐỀ + ANIMATION + MIN/CLOSE) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="550" Height="460"
        WindowStartupLocation="CenterScreen" Background="Transparent" FontFamily="Segoe UI" 
        AllowsTransparency="True" WindowStyle="None" ResizeMode="CanMinimize">
    
    <Window.Resources>
        <Storyboard x:Key="ScanAnimation" RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetName="ScanIcon" Storyboard.TargetProperty="(Canvas.Left)" From="20" To="420" Duration="0:0:2" AutoReverse="True">
                <DoubleAnimation.EasingFunction><QuadraticEase EasingMode="EaseInOut"/></DoubleAnimation.EasingFunction>
            </DoubleAnimation>
        </Storyboard>
        <Storyboard x:Key="RepairAnimation" RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetName="rotateRepair" Storyboard.TargetProperty="Angle" From="0" To="360" Duration="0:0:3"/>
        </Storyboard>

        <Style x:Key="TitleButtonStyle" TargetType="Button">
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
                <TextBlock Text="🖨️ VietToolbox: Chuyên Gia Máy In &amp; LAN" Foreground="Gray" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="11"/>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Style="{StaticResource TitleButtonStyle}"/>
                <Button Name="btnClose" Grid.Column="2" Content="✕" Style="{StaticResource CloseButtonStyle}" FontSize="14"/>
            </Grid>

            <Grid Grid.Row="1" Margin="25,10,25,25">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="60"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

                <DockPanel Grid.Row="0" Margin="0,0,0,15">
                    <TextBlock Name="txtStatusIcon" FontSize="20" Foreground="#00D4FF" VerticalAlignment="Center" Margin="0,0,8,0" FontFamily="Segoe UI Emoji">$Icon_Medic</TextBlock>
                    <TextBlock Name="iconRepair" FontSize="22" Margin="0,0,10,0" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5" Visibility="Collapsed" DockPanel.Dock="Left">
                        <TextBlock.RenderTransform><RotateTransform x:Name="rotateRepair" Angle="0"/></TextBlock.RenderTransform>
                        <Run FontFamily="Segoe UI Emoji" Text="&#x1F6E0;"/>
                    </TextBlock>
                    <TextBlock Name="txtStatus" Text="Sẵn sàng xử lý..." FontSize="18" FontWeight="Bold" Foreground="#00D4FF" VerticalAlignment="Center" DockPanel.Dock="Left"/>
                    <TextBlock Name="txtTimer" Text="00:00:00" FontSize="16" Foreground="Gray" HorizontalAlignment="Right" VerticalAlignment="Center" FontFamily="Consolas"/>
                </DockPanel>

                <Border Grid.Row="1" Height="15" Background="#424242" CornerRadius="7" ClipToBounds="True">
                    <ProgressBar Name="pgBar" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0" Foreground="#0078D7"/>
                </Border>

                <Canvas Grid.Row="2" VerticalAlignment="Center">
                    <TextBlock Name="ScanIcon" Text="🔍" FontSize="26" Canvas.Top="10" FontFamily="Segoe UI Emoji"/>
                </Canvas>

                <TextBlock Name="txtDetail" Grid.Row="3" Text="Sửa lỗi 0x0000011b, 0x00000709, LAN Guest và PrintNightmare." Foreground="#A0A0A0" FontSize="13" 
                           FontStyle="Italic" HorizontalAlignment="Center" VerticalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center"/>

                <Grid Grid.Row="4">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="btnStart" Grid.Column="0" Content="$Icon_Rocket BẮT ĐẦU FIX" Height="50" Background="#27AE60"/>
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
    $txtStatus = $window.FindName("txtStatus"); $txtTimer = $window.FindName("txtTimer"); $txtDetail = $window.FindName("txtDetail")
    $txtStatusIcon = $window.FindName("txtStatusIcon"); $iconRepair = $window.FindName("iconRepair")
    $pgBar = $window.FindName("pgBar"); $btnStart = $window.FindName("btnStart"); $btnStop = $window.FindName("btnStop")
    $ScanAnim = $window.Resources["ScanAnimation"]; $RepairAnim = $window.Resources["RepairAnimation"]

    # --- SỰ KIỆN GIAO DIỆN ---
    $TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
    $btnMinimize.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    $btnClose.Add_Click({
        if ($script:IsRunning) {
            if ([System.Windows.MessageBox]::Show("Đang chạy, ông muốn thoát không?", "Xác nhận", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "No") { return }
            if ($null -ne $script:SubProc) { try { Stop-Process -Id $script:SubProc.Id -Force } catch {} }
        }
        $window.Close()
    })

    # --- BỘ NÃO TIMER ---
    $MainTimer = New-Object System.Windows.Threading.DispatcherTimer
    $MainTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    
    $MainTimer.Add_Tick({
        $elapsed = $script:StopWatch.Elapsed
        $txtTimer.Text = "{0:00}:{1:00}:{2:00}" -f [math]::Floor($elapsed.TotalHours), $elapsed.Minutes, $elapsed.Seconds
        
        if ($script:IsRunning -and $null -ne $script:SubProc) {
            if ($script:SubProc.HasExited) {
                $script:SubProc = $null
                switch ($script:CurrentStep) {
                    1 { $script:CurrentStep = 2; $pgBar.Value = 30 }
                    3 { $script:CurrentStep = 4; $pgBar.Value = 80 }
                    4 { $script:CurrentStep = 5; $pgBar.Value = 100 }
                }
            } elseif ($pgBar.Value -lt 99) { $pgBar.Value += 0.05 }
        }

        if ($script:IsRunning -and $null -eq $script:SubProc) {
            switch ($script:CurrentStep) {
                1 {
                    $txtStatus.Text = "🌐 Đang nạp SMB 1.0..."; $txtDetail.Text = "Sử dụng DISM để kích hoạt SMB 1.0. Bước này có thể mất 2-5 phút."
                    $pgBar.IsIndeterminate = $true
                    $script:SubProc = Start-Process dism.exe -ArgumentList "/online /enable-feature /featurename:SMB1Protocol /all /norestart" -WindowStyle Hidden -PassThru
                }
                2 {
                    $txtStatusIcon.Visibility = "Collapsed"; $iconRepair.Visibility = "Visible"; $RepairAnim.Begin($window)
                    $txtStatus.Text = "🛠️ Vá Registry RPC/LAN..."; $txtDetail.Text = "Đang áp dụng bộ Registry Fix cho 0x0000011b và PrintNightmare..."
                    $pgBar.IsIndeterminate = $false
                    
                    # Chạy Registry Fix trực tiếp (Nhanh nên không cần luồng riêng)
                    $RegFix = {
                        function Set-Reg ($P, $N, $V, $T = "DWord") { if (!(Test-Path $P)) { New-Item $P -Force | Out-Null }; Set-ItemProperty $P $N $V -Type $T -Force }
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1
                        $P1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
                        Set-Reg $P1 "RpcUseNamedPipeProtocol" 1; Set-Reg $P1 "RpcTcpPort" 0; Set-Reg $P1 "RpcAuthentication" 0
                        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "RestrictDriverInstallationToAdministrators" 1
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Print" "RpcAuthnLevelPrivacyEnabled" 0
                        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LimitBlankPasswordUse" 0; Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "EveryoneIncludesAnonymous" 1
                    }
                    &$RegFix
                    $script:LogReport += "[$(Get-Date -Format 'HH:mm:ss')] Đã nạp xong bộ Registry Fix."
                    $script:CurrentStep = 3
                }
                3 {
                    $txtStatus.Text = "🚀 Tối ưu mạng LAN..."; $txtDetail.Text = "Đang tắt yêu cầu chữ ký số SMB Signing để tăng tốc độ kết nối..."
                    $script:SubProc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-SmbClientConfiguration -RequireSecuritySignature `$false -Force; Set-SmbServerConfiguration -RequireSecuritySignature `$false -Force`"" -WindowStyle Hidden -PassThru
                }
                4 {
                    $txtStatus.Text = "🖨️ Làm mới máy in..."; $txtDetail.Text = "Đang khởi động lại dịch vụ Print Spooler để nhận cấu hình mới..."
                    $script:SubProc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Service Spooler -StartupType Automatic; Restart-Service Spooler -Force`"" -WindowStyle Hidden -PassThru
                }
                5 {
                    $script:IsRunning = $false; $script:StopWatch.Stop(); $MainTimer.Stop(); $ScanAnim.Stop($window); $RepairAnim.Stop($window)
                    
                    # XUẤT BÁO CÁO
                    $DesktopPath = [System.Environment]::GetFolderPath('Desktop'); $FilePath = Join-Path $DesktopPath "Bao_Cao_Fix_In_LAN.txt"
                    $script:LogReport += "=========================================================="
                    $script:LogReport += "TỔNG KẾT: Sửa lỗi hoàn tất trong $($txtTimer.Text)."
                    $script:LogReport | Out-File -FilePath $FilePath -Encoding UTF8

                    $txtStatusIcon.Visibility = "Visible"; $iconRepair.Visibility = "Collapsed"; $txtStatusIcon.Text = $Icon_Finish
                    $txtStatus.Text = "🏁 HOÀN TẤT!"; $txtStatus.Foreground = "#27AE60"
                    $txtDetail.Text = "Xong! Hãy khởi động lại máy. Báo cáo đã lưu ở Desktop."
                    
                    [System.Windows.MessageBox]::Show("Tuyệt vời Tuấn ơi! Đã xử lý xong lỗi Máy in & LAN.`n`nBáo cáo chi tiết đã nằm trên Desktop của ông.", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    $btnStart.IsEnabled = $true; $btnStop.IsEnabled = $false
                }
            }
        }
    })

    # --- SỰ KIỆN NÚT BẤM ---
    $btnStart.Add_Click({
        $script:IsRunning = $true; $script:CurrentStep = 1; $script:StopWatch.Reset(); $script:StopWatch.Start(); $MainTimer.Start()
        $btnStart.IsEnabled = $false; $btnStop.IsEnabled = $true; $ScanAnim.Begin($window)
    })

    $btnStop.Add_Click({
        $script:IsRunning = $false; $MainTimer.Stop(); $ScanAnim.Stop($window); $RepairAnim.Stop($window)
        if ($null -ne $script:SubProc) { try { Stop-Process -Id $script:SubProc.Id -Force } catch {} }
        $txtStatusIcon.Visibility = "Visible"; $iconRepair.Visibility = "Collapsed"; $txtStatusIcon.Text = $Icon_Stop
        $txtStatus.Text = "⛔ ĐÃ HỦY!"; $pgBar.Value = 0; $btnStart.IsEnabled = $true; $btnStop.IsEnabled = $false
    })

    $window.ShowDialog() | Out-Null
}

&$LogicFixMayInLAN_V64