Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 1. CẤU HÌNH ---
$API_KEY = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"))
$csvUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"

# Tải danh sách
try {
    $res = Invoke-WebRequest -Uri $csvUrl -UseBasicParsing
    $raw = if ($res.Content -is [string]) { $res.Content } else { [System.Text.Encoding]::UTF8.GetString($res.Content) }
    $ListWin = $raw | ConvertFrom-Csv | Where-Object { $_.Name -match "wim" -or $_.FileID -match "wim" }
} catch { [System.Windows.MessageBox]::Show("Lỗi lấy danh sách!"); exit }

# --- 2. GIAO DIỆN XAML (FIX CO DÃN) ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinDeploy Master" SizeToContent="Height" Width="450" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" Background="#121212" BorderBrush="#00FF7F" BorderThickness="1.5">
        <Grid Margin="25">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> </Grid.RowDefinitions>

            <TextBlock Grid.Row="0" Text="WINDOWS AUTO-INSTALLER" Foreground="#00FF7F" FontSize="20" FontWeight="Black" HorizontalAlignment="Center" Margin="0,0,0,15"/>
            
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" MaxHeight="300" Margin="0,5">
                <StackPanel Name="ButtonContainer"/>
            </ScrollViewer>

            <StackPanel Grid.Row="2" Margin="0,10" Background="#1A1A1A" Name="StepPanel" Visibility="Collapsed">
                <TextBlock Name="step1" Text="○ 1. Chuẩn bị phân vùng (EFI/RE)" Foreground="#888888" Margin="10,4" FontSize="11"/>
                <TextBlock Name="step2" Text="○ 2. Tải bộ cài WIM từ Cloud" Foreground="#888888" Margin="10,4" FontSize="11"/>
                <TextBlock Name="step3" Text="○ 3. Tạo kịch bản tự động bung Win" Foreground="#888888" Margin="10,4" FontSize="11"/>
                <TextBlock Name="step4" Text="○ 4. Cấu hình Boot &amp; Restart" Foreground="#888888" Margin="10,4" FontSize="11"/>
            </StackPanel>

            <StackPanel Grid.Row="3" Margin="0,10,0,0">
                <Grid Margin="0,0,0,5">
                    <TextBlock Name="lblStatus" Text="Sẵn sàng..." Foreground="#00FF7F" FontSize="11"/>
                    <TextBlock Name="lblPercent" Text="0%" Foreground="#00FF7F" FontSize="11" HorizontalAlignment="Right"/>
                </Grid>
                <ProgressBar Name="progBar" Height="8" Minimum="0" Maximum="100" Value="0" Foreground="#00FF7F" Background="#222222" BorderThickness="0"/>
                <Button Name="btnExit" Content="THOÁT" Margin="0,15,0,0" Height="30" Width="100" Background="Transparent" Foreground="#FF4D4D" BorderBrush="#FF4D4D" Cursor="Hand"/>
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
$stepPanel = $window.FindName("StepPanel")

# --- 3. HÀM CẬP NHẬT BƯỚC ---
function Update-Step ($stepNum, $status) {
    $txt = $window.FindName("step$stepNum")
    if ($status -eq "Running") { $txt.Foreground = "#00FF7F"; $txt.Text = $txt.Text.Replace("○", "▶") + " (Đang chạy...)" }
    if ($status -eq "Done") { $txt.Foreground = "#AAAAAA"; $txt.Text = $txt.Text.Split("(")[0].Replace("▶", "✅") }
}

# --- 4. LOGIC TRIỂN KHAI ---
function Start-Deploy ($win) {
    $stepPanel.Visibility = "Visible"
    $container.Children | ForEach-Object { $_.IsEnabled = $false }
    $dataDrive = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" -and $_.Free -gt 8GB } | Select-Object -First 1).Name
    $wimPath = "$($dataDrive):\install.wim"
    $url = "https://www.googleapis.com/drive/v3/files/$($win.FileID)?alt=media&key=$API_KEY"

    Update-Step 1 "Running"
    $cPart = Get-Partition -DriveLetter C
    "select disk 0`nselect partition $($cPart.PartitionNumber)`nshrink minimum=1124`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S`ncreate partition primary`nformat quick fs=ntfs label='Recovery'`nset id='de94bba4-06d1-4d40-a16a-bfd50179d6ac'" | diskpart
    Update-Step 1 "Done"

    Update-Step 2 "Running"
    $job = Start-Job -ScriptBlock { param($url, $path) curl.exe -L -o $path $url } -ArgumentList $url, $wimPath
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({
        if (Test-Path $wimPath) {
            $size = (Get-Item $wimPath).Length / 1MB
            $p = [math]::Min(99, [math]::Round(($size / 4800) * 100)) # Giả định 4.8GB
            $progBar.Value = $p; $lblPercent.Text = "$p %"; $lblStatus.Text = "Đang tải: $([math]::Round($size)) MB"
        }
        if ((Get-Job -Id $job.Id).State -eq "Completed") {
            $timer.Stop(); Update-Step 2 "Done"
            Update-Step 3 "Running"
            $bat = "@echo off`n(echo select disk 0 & echo select partition $($cPart.PartitionNumber) & echo format quick fs=ntfs label='Windows' & echo assign letter=C & echo exit) | diskpart`ndism /Apply-Image /ImageFile:$wimPath /Index:1 /ApplyDir:C:\`nbcdboot C:\Windows /s S: /f UEFI`nwpeutil reboot"
            $bat | Out-File -FilePath "$($dataDrive):\auto_install.bat" -Encoding ASCII
            Update-Step 3 "Done"; Update-Step 4 "Running"
            reagentc /boottore; Update-Step 4 "Done"
            [System.Windows.MessageBox]::Show("Xong! Máy sẽ Restart sau 5s.")
            shutdown /r /t 5
        }
    })
    $timer.Start()
}

# --- 5. NẠP NÚT BẤM ---
foreach ($win in $ListWin) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "💾  $($win.Name)"
    $btn.Height = 45; $btn.Margin = "0,3"; $btn.Foreground = "White"; $btn.Background = "#1E1E1E"; $btn.BorderBrush = "#333333"; $btn.Cursor = "Hand"
    $btn.Add_Click({ Start-Deploy $win })
    $container.Children.Add($btn)
}

$window.FindName("btnExit").Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null