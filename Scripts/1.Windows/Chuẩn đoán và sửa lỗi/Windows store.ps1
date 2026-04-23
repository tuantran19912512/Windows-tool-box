# ==============================================================================
# CÔNG CỤ TỰ ĐỘNG PHỤC HỒI MICROSOFT STORE & APP INSTALLER (WINGET)
# Tính năng: Giao diện XAML, Progress Bar, Cài đặt thư viện lõi tự động
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. THIẾT LẬP MÔI TRƯỜNG & QUYỀN QUẢN TRỊ
# ------------------------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$TaiKhoanHienTai = [Security.Principal.WindowsIdentity]::GetCurrent()
$QuyenQuanTri    = [Security.Principal.WindowsPrincipal]$TaiKhoanHienTai
if (-not $QuyenQuanTri.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ------------------------------------------------------------------------------
# 2. GIAO DIỆN WPF (XAML)
# ------------------------------------------------------------------------------
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Công Cụ Phục Hồi Store" Width="550" Height="320" 
        WindowStartupLocation="CenterScreen" Background="Transparent"
        AllowsTransparency="True" WindowStyle="None" FontFamily="Segoe UI">
    <Border CornerRadius="12" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" Padding="20">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="🛠️" FontSize="24" Margin="0,0,10,0"/>
                    <TextBlock Text="PHỤC HỒI HỆ SINH THÁI MICROSOFT" Foreground="White" FontSize="18" FontWeight="Black" VerticalAlignment="Center"/>
                </StackPanel>
                <Button Name="NutThoat" Content="✕" Width="30" Height="30" HorizontalAlignment="Right" 
                        Background="Transparent" BorderThickness="0" Foreground="#EF4444" FontSize="16" FontWeight="Bold" Cursor="Hand"/>
            </Grid>
            <Rectangle Grid.Row="1" Height="1" Fill="#334155" Margin="0,15,0,20"/>

            <StackPanel Grid.Row="2" VerticalAlignment="Center">
                <TextBlock Text="Công cụ này sẽ giúp bạn:" Foreground="#94A3B8" FontSize="13" Margin="0,0,0,10"/>
                <TextBlock Text="1. Khôi phục và đăng ký lại Microsoft Store." Foreground="#E2E8F0" FontSize="13" Margin="10,0,0,5"/>
                <TextBlock Text="2. Cài đặt thư viện nền tảng VCLibs &amp; UI.Xaml." Foreground="#E2E8F0" FontSize="13" Margin="10,0,0,5"/>
                <TextBlock Text="3. Cài đặt App Installer (Trình quản lý gói Winget)." Foreground="#E2E8F0" FontSize="13" Margin="10,0,0,20"/>

                <TextBlock Name="NhanTrangThai" Text="Trạng thái: Đang chờ lệnh..." Foreground="#38BDF8" FontSize="13" FontWeight="SemiBold" Margin="0,0,0,5"/>
                <ProgressBar Name="ThanhTienTrinh" Minimum="0" Maximum="100" Value="0" Height="12" Background="#0F172A" Foreground="#10B981" BorderThickness="0">
                    <ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></ProgressBar.Resources>
                </ProgressBar>
            </StackPanel>

            <Button Name="NutBatDau" Grid.Row="3" Content="🚀 BẮT ĐẦU PHỤC HỒI" Height="45" Margin="0,15,0,0" 
                    Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="14" Cursor="Hand">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
            </Button>
        </Grid>
    </Border>
</Window>
"@

$CuaSo        = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$XAML))
$NutBatDau    = $CuaSo.FindName("NutBatDau")
$NutThoat     = $CuaSo.FindName("NutThoat")
$TrangThai    = $CuaSo.FindName("NhanTrangThai")
$TienTrinh    = $CuaSo.FindName("ThanhTienTrinh")
$Dispatcher   = $CuaSo.Dispatcher

$NutThoat.Add_Click({ $CuaSo.Close() })
$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })

# ------------------------------------------------------------------------------
# 3. ĐỘNG CƠ XỬ LÝ (RUNSPACE)
# ------------------------------------------------------------------------------
$NutBatDau.Add_Click({
    $NutBatDau.IsEnabled = $false
    $NutBatDau.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
    $NutThoat.IsEnabled = $false

    $RS = [runspacefactory]::CreateRunspace()
    $RS.ApartmentState = "STA"; $RS.Open()
    $RS.SessionStateProxy.SetVariable("Dispatcher", $Dispatcher)
    $RS.SessionStateProxy.SetVariable("TrangThai",  $TrangThai)
    $RS.SessionStateProxy.SetVariable("TienTrinh",  $TienTrinh)

    $PS = [powershell]::Create(); $PS.Runspace = $RS
    [void]$PS.AddScript({
        function UI ($VanBan, $PhanTram) {
            $Dispatcher.Invoke([action]{
                if ($null -ne $VanBan)   { $TrangThai.Text = "Trạng thái: " + $VanBan }
                if ($null -ne $PhanTram) { $TienTrinh.Value = $PhanTram }
            })
        }

        function TaiVaCaiDat ($LienKet, $TenFile, $Loai) {
            $DuongDan = Join-Path $env:TEMP $TenFile
            try {
                if ($Loai -eq "VCLibs" -or $Loai -eq "UIXaml") {
                    Invoke-WebRequest -Uri $LienKet -OutFile $DuongDan -UseBasicParsing -ErrorAction SilentlyContinue
                } else {
                    $Goi = [System.Net.HttpWebRequest]::Create($LienKet)
                    $PH  = $Goi.GetResponse(); $Dong = $PH.GetResponseStream()
                    $File = New-Object System.IO.FileStream($DuongDan, [System.IO.FileMode]::Create)
                    $Buf = New-Object byte[] 65536; $Tong = $PH.ContentLength; $Da = 0
                    do {
                        $n = $Dong.Read($Buf, 0, $Buf.Length)
                        if ($n -gt 0) { $File.Write($Buf, 0, $n); $Da += $n }
                    } while ($n -gt 0)
                    $File.Close(); $Dong.Close(); $PH.Close()
                }

                if (Test-Path $DuongDan) {
                    Add-AppxPackage -Path $DuongDan -ErrorAction SilentlyContinue
                    Remove-Item $DuongDan -Force -ErrorAction SilentlyContinue
                }
            } catch {}
        }

        try {
            # BƯỚC 1: XÓA CACHE VÀ ĐĂNG KÝ LẠI STORE
            UI "Đang xóa bộ nhớ đệm Microsoft Store (wsreset)..." 10
            Start-Process "wsreset.exe" -ArgumentList "-i" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
            
            UI "Đang đăng ký lại nhân ứng dụng Store..." 25
            Get-AppxPackage -allusers Microsoft.WindowsStore -ErrorAction SilentlyContinue | Foreach-Object {
                Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
            }

            # BƯỚC 2: CÀI ĐẶT CÁC THƯ VIỆN LÕI BẮT BUỘC
            UI "Đang tải thư viện nền tảng VCLibs (x64)..." 40
            TaiVaCaiDat "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" "VCLibs.appx" "VCLibs"

            UI "Đang tải giao diện hệ thống UI.Xaml 2.8..." 55
            TaiVaCaiDat "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx" "UIXaml.appx" "UIXaml"

            # BƯỚC 3: CÀI ĐẶT APP INSTALLER (CHỨA WINGET)
            UI "Đang tải trình quản lý gói App Installer (Winget)..." 70
            TaiVaCaiDat "https://aka.ms/getwinget" "AppInstaller.msixbundle" "Winget"

            # BƯỚC 4: HOÀN TẤT
            UI "Đang cấu hình hệ thống..." 90
            Start-Sleep -Seconds 2
            UI "Hoàn tất! Hệ sinh thái Microsoft đã được phục hồi." 100

        } catch {
            UI "Có lỗi xảy ra trong quá trình phục hồi." 0
        }
    })

    $KenhChay = $PS.BeginInvoke()
    $Timer = New-Object System.Windows.Threading.DispatcherTimer
    $Timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $Timer.Add_Tick({
        if ($KenhChay.IsCompleted) {
            $Timer.Stop()
            $PS.Dispose(); $RS.Close(); $RS.Dispose()
            
            $NutBatDau.Content = "✅ ĐÃ PHỤC HỒI XONG"
            $NutThoat.IsEnabled = $true
            [System.Windows.Forms.MessageBox]::Show("Toàn bộ Microsoft Store, App Installer và Winget đã được khôi phục thành công.`n`nBây giờ bạn có thể cài đặt các ứng dụng đuôi .msixbundle bình thường.", "Hoàn Thành")
        }
    })
    $Timer.Start()
})

$CuaSo.ShowDialog() | Out-Null