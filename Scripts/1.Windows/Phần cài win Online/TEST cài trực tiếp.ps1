Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 1. CẤU HÌNH ---
$API_KEY = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"))
$csvUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"

# --- 2. GIAO DIỆN XAML (Cập nhật thêm TextBlock hiển thị %) ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinDeploy Pro" Height="550" Width="420" Background="Transparent" AllowsTransparency="True" WindowStyle="None">
    <Border CornerRadius="20" Background="#121212" BorderBrush="#00FF7F" BorderThickness="2">
        <Grid Margin="25">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="WINDOWS AUTO-DEPLOY" Foreground="#00FF7F" FontSize="22" FontWeight="Black" HorizontalAlignment="Center" Margin="0,0,0,20"/>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Hidden"><StackPanel Name="ButtonContainer"/></ScrollViewer>
            <StackPanel Grid.Row="2" Margin="0,15,0,0">
                <DockPanel>
                    <TextBlock Name="lblStatus" Text="Sẵn sàng..." Foreground="#00FF7F" FontSize="12"/>
                    <TextBlock Name="lblPercent" Text="0%" Foreground="#00FF7F" FontSize="12" HorizontalAlignment="Right" DockPanel.Dock="Right"/>
                </DockPanel>
                <ProgressBar Name="progBar" Height="12" Foreground="#00FF7F" Background="#222222" BorderThickness="0" Minimum="0" Maximum="100" Margin="0,5"/>
                <Button Name="btnExit" Content="THOÁT" Margin="0,10,0,0" Height="30" Width="80" Background="Transparent" Foreground="#FF4D4D" BorderBrush="#FF4D4D" Cursor="Hand"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$container = $window.FindName("ButtonContainer")
$lblStatus = $window.FindName("lblStatus")
$lblPercent = $window.FindName("lblPercent")
$progBar = $window.FindName("progBar")

# --- 3. HÀM TẢI FILE CÓ TIẾN TRÌNH (%) ---
function Start-Deployment ($win) {
    $container.Children | ForEach-Object { $_.IsEnabled = $false }
    $progBar.IsIndeterminate = $false
    $progBar.Value = 0

    # Lấy ổ đĩa chứa file tạm
    $dataDrive = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" -and $_.Free -gt 10GB } | Select-Object -First 1).Name
    $wimPath = "$($dataDrive):\install.wim"
    $url = "https://www.googleapis.com/drive/v3/files/$($win.FileID)?alt=media&key=$API_KEY"

    # Chạy tiến trình tải và xử lý đĩa trong Job ngầm
    $job = Start-Job -ScriptBlock {
        param($url, $path, $cPartNum)
        
        # Hàm tải file và ghi đè để báo tiến trình
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $path) # Ghi chú: WebClient bản chuẩn sẽ block, nhưng Job sẽ xử lý
        
        # [Sau khi tải xong sẽ thực hiện Diskpart]
        "select disk 0`nselect partition $cPartNum`nshrink minimum=1124`ncreate partition efi size=100`nformat quick fs=fat32`ncreate partition primary`nformat quick fs=ntfs label='Recovery'`nset id='de94bba4-06d1-4d40-a16a-bfd50179d6ac'" | diskpart
        return "DONE"
    } -ArgumentList $url, $wimPath, (Get-Partition -DriveLetter C).PartitionNumber

    # Timer kiểm tra dung lượng file để cập nhật % lên UI
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    
    # Giả định dung lượng file WIM khoảng 5GB (Tuấn có thể lấy dung lượng thực tế từ API nếu muốn)
    # Ở đây mình sẽ check dung lượng file đang tăng dần trên ổ đĩa
    $timer.Add_Tick({
        if (Test-Path $wimPath) {
            $file = Get-Item $wimPath
            $currentSize = $file.Length / 1MB
            $totalSize = 5000 # Giả định 5GB, Tuấn có thể điều chỉnh
            $percent = [math]::Min(99, [math]::Round(($currentSize / $totalSize) * 100))
            
            $progBar.Value = $percent
            $lblPercent.Text = "$percent %"
            $lblStatus.Text = "Đang tải: $([math]::Round($currentSize)) MB / $totalSize MB"
        }

        if ((Get-Job).State -eq "Completed") {
            $timer.Stop()
            $progBar.Value = 100
            $lblPercent.Text = "100%"
            $lblStatus.Text = "Hoàn tất! Chuẩn bị Restart..."
            Start-Sleep -Seconds 2
            # Ghi file kịch bản và Reboot
            reagentc /boottore
            shutdown /r /t 5
        }
    })
    $timer.Start()
}

# --- 4. NẠP DANH SÁCH ---
$res = Invoke-WebRequest -Uri $csvUrl -UseBasicParsing
$content = if ($res.Content -is [string]) { $res.Content } else { [System.Text.Encoding]::UTF8.GetString($res.Content) }
$ListWin = $content | ConvertFrom-Csv | Where-Object { $_.Name -match "wim" }

foreach ($win in $ListWin) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "💾  $($win.Name)"
    $btn.Height = 55; $btn.Margin = "0,5"; $btn.Foreground = "White"; $btn.Background = "#1E1E1E"; $btn.FontWeight = "Bold"
    $btn.Add_Click({ Start-Deployment $win })
    $container.Children.Add($btn)
}

$window.FindName("btnExit").Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null