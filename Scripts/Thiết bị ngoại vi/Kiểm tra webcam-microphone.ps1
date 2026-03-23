# ==========================================================
# VIETTOOLBOX - KIỂM TRA WEBCAM & MICROPHONE (PURE WPF EDITION)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# --- NẠP THƯ VIỆN ĐIỀU KHIỂN MULTIMEDIA ---
if (-not ([Ref].Assembly.GetType("VietToolbox.HardwareAPI"))) {
    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    namespace VietToolbox {
        public class HardwareAPI {
            [DllImport("winmm.dll")]
            public static extern int mciSendString(string command, StringBuilder buffer, int bufferSize, IntPtr hwndCallback);
            
            [DllImport("avicap32.dll")] 
            public static extern IntPtr capCreateCaptureWindowA(string lpszWindowName, int dwStyle, int x, int y, int nWidth, int nHeight, IntPtr hWndParent, int nID);
            
            [DllImport("user32.dll")] 
            public static extern bool SendMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);
        }
    }
"@
    try { Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue } catch { }
}

$LogicNgoaiVi = {
    # --- 1. GIAO DIỆN XAML PURE WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Kiểm tra Webcam &amp; Microphone" Width="820" Height="540"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#FFFFFF" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Opacity" Value="0.6"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="20"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <Border Grid.Column="0" Background="#F4F5F7" CornerRadius="8" Padding="20">
            <StackPanel>
                <TextBlock Text="KIỂM TRA MICROPHONE" FontSize="20" FontWeight="Bold" Foreground="#394E60" Margin="0,0,0,10"/>
                <TextBlock Text="Hệ thống sẽ ghi âm 3 giây và phát lại để xác nhận thiết bị thu âm hoạt động tốt." Foreground="#666666" TextWrapping="Wrap" Margin="0,0,0,20"/>
                
                <ComboBox Name="cbMic" Height="35" FontSize="14" Margin="0,0,0,20" VerticalContentAlignment="Center"/>
                
                <Button Name="btnRecord" Content="GHI ÂM &amp; PHÁT LẠI (3s)" Height="45" Background="#0068FF" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,0,0,15"/>
                <Button Name="btnOpenSound" Content="Mở Cài đặt Âm thanh" Height="35" Background="#E1E4E8" Foreground="#394E60" FontWeight="SemiBold"/>
            </StackPanel>
        </Border>

        <Border Grid.Column="2" Background="#F4F5F7" CornerRadius="8" Padding="20">
            <StackPanel>
                <TextBlock Text="KIỂM TRA WEBCAM" FontSize="20" FontWeight="Bold" Foreground="#394E60" Margin="0,0,0,15"/>
                
                <ComboBox Name="cbCam" Height="35" FontSize="14" Margin="0,0,0,15" VerticalContentAlignment="Center"/>
                
                <Border Name="CamScreen" Height="260" Background="#1A1A1A" Margin="0,0,0,15" CornerRadius="4"/>
                
                <Button Name="btnStartCam" Content="BẬT MÁY ẢNH" Height="45" Background="#0068FF" Foreground="White" FontWeight="Bold" FontSize="14"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@

    # --- 2. KHỞI TẠO CỬA SỔ & ÁNH XẠ BIẾN ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $form = [Windows.Markup.XamlReader]::Load($DocXml)

    $cbMic = $form.FindName("cbMic")
    $btnRecord = $form.FindName("btnRecord")
    $btnOpenSound = $form.FindName("btnOpenSound")
    
    $cbCam = $form.FindName("cbCam")
    $CamScreen = $form.FindName("CamScreen")
    $btnStartCam = $form.FindName("btnStartCam")

    # --- 3. ĐỔ DỮ LIỆU THIẾT BỊ ---
    # Đổ dữ liệu Mic
    $mics = Get-CimInstance Win32_PnPEntity | Where-Object { $_.Caption -match "Microphone" -or $_.Caption -match "Audio Input" }
    foreach ($m in $mics) { [void]$cbMic.Items.Add($m.Caption) }
    if ($cbMic.Items.Count -eq 0) { [void]$cbMic.Items.Add("Thiết bị mặc định của Windows") }
    $cbMic.SelectedIndex = 0

    # Đổ dữ liệu Cam
    $cams = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -match "Camera|Image" -or $_.Caption -match "Camera|Webcam" }
    foreach ($c in $cams) { [void]$cbCam.Items.Add($c.Caption) }
    if ($cbCam.Items.Count -eq 0) { 
        [void]$cbCam.Items.Add("Không có thiết bị Webcam")
        $cbCam.IsEnabled = $false
        $btnStartCam.IsEnabled = $false
        $btnStartCam.Background = "#999999"
    } else {
        $cbCam.SelectedIndex = 0
    }

    $btnOpenSound.Add_Click({ Start-Process "mmsys.cpl" })

    # --- 4. LOGIC GHI ÂM (DÙNG DISPATCHER TIMER CHỐNG ĐƠ) ---
    $tempWav = "$($env:TEMP)\viettoolbox_mic_test.wav"
    
    $recTimer = New-Object System.Windows.Threading.DispatcherTimer
    $recTimer.Interval = [TimeSpan]::FromSeconds(3)
    $recTimer.Add_Tick({
        $recTimer.Stop()
        
        $btnRecord.Content = "ĐANG PHÁT LẠI..."
        $btnRecord.Background = "#2ECC71"
        
        [VietToolbox.HardwareAPI]::mciSendString("save recsound $tempWav", $null, 0, [IntPtr]::Zero) | Out-Null
        [VietToolbox.HardwareAPI]::mciSendString("close recsound", $null, 0, [IntPtr]::Zero) | Out-Null
        
        if (Test-Path $tempWav) {
            $player = New-Object System.Media.SoundPlayer $tempWav
            $player.PlaySync()
            $player.Dispose()
            Remove-Item -Path $tempWav -Force -ErrorAction SilentlyContinue
        }

        $btnRecord.Content = "GHI ÂM & PHÁT LẠI (3s)"
        $btnRecord.Background = "#0068FF"
        $btnRecord.IsEnabled = $true
    })

    $btnRecord.Add_Click({
        $btnRecord.IsEnabled = $false
        $btnRecord.Content = "ĐANG THU ÂM... NÓI GÌ ĐÓ ĐI!"
        $btnRecord.Background = "#E74C3C"
        
        [VietToolbox.HardwareAPI]::mciSendString("open new Type waveaudio Alias recsound", $null, 0, [IntPtr]::Zero) | Out-Null
        [VietToolbox.HardwareAPI]::mciSendString("record recsound", $null, 0, [IntPtr]::Zero) | Out-Null
        
        # Kích hoạt bộ đếm ngầm 3 giây thay vì dùng Start-Sleep
        $recTimer.Start()
    })

    # --- 5. LOGIC MỞ WEBCAM (TÍNH TỌA ĐỘ ẢO CHO WPF) ---
    $btnStartCam.Add_Click({
        if ($btnStartCam.Content -eq "BẬT MÁY ẢNH") {
            $idx = $cbCam.SelectedIndex
            
            # Lấy HWND của cửa sổ WPF chính
            $interop = New-Object System.Windows.Interop.WindowInteropHelper($form)
            $hwnd = $interop.Handle
            
            # Tính toán DPI và Tọa độ thực tế của khung nền đen
            $source = [System.Windows.PresentationSource]::FromVisual($form)
            $dpiX = $source.CompositionTarget.TransformToDevice.M11
            $dpiY = $source.CompositionTarget.TransformToDevice.M22
            
            $point = $CamScreen.TranslatePoint([System.Windows.Point]::new(0,0), $form)
            $x = [int]($point.X * $dpiX)
            $y = [int]($point.Y * $dpiY)
            $w = [int]($CamScreen.ActualWidth * $dpiX)
            $h = [int]($CamScreen.ActualHeight * $dpiY)

            # Khởi tạo cửa sổ Capture đè lên tọa độ đã tính
            $camHandle = [VietToolbox.HardwareAPI]::capCreateCaptureWindowA("Webcam", 0x50000000, $x, $y, $w, $h, $hwnd, 0)
            $btnStartCam.Tag = $camHandle 
            
            # Kết nối & Cấu hình luồng ảnh
            [VietToolbox.HardwareAPI]::SendMessage($camHandle, 0x40a, $idx, 0) | Out-Null
            [VietToolbox.HardwareAPI]::SendMessage($camHandle, 0x435, 40, 0) | Out-Null # 40ms Preview rate
            [VietToolbox.HardwareAPI]::SendMessage($camHandle, 0x433, 1, 0) | Out-Null  # Co giãn theo khung
            [VietToolbox.HardwareAPI]::SendMessage($camHandle, 0x432, 1, 0) | Out-Null  # Mở Preview
            
            $btnStartCam.Content = "TẮT MÁY ẢNH"; $btnStartCam.Background = "#E74C3C"
            $cbCam.IsEnabled = $false
        } else {
            $camHandle = $btnStartCam.Tag
            if ($null -ne $camHandle) { 
                [VietToolbox.HardwareAPI]::SendMessage($camHandle, 0x40b, 0, 0) | Out-Null 
            }
            $btnStartCam.Tag = $null
            $btnStartCam.Content = "BẬT MÁY ẢNH"; $btnStartCam.Background = "#0068FF"
            $cbCam.IsEnabled = $true
        }
    })

    # Dọn dẹp thiết bị khi đóng cửa sổ
    $form.Add_Closing({
        $camHandle = $btnStartCam.Tag
        if ($null -ne $camHandle) { [VietToolbox.HardwareAPI]::SendMessage($camHandle, 0x40b, 0, 0) | Out-Null }
        [VietToolbox.HardwareAPI]::mciSendString("close recsound", $null, 0, [IntPtr]::Zero) | Out-Null
    })

    $form.ShowDialog() | Out-Null
}

&$LogicNgoaiVi