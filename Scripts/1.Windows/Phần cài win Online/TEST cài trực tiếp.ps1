Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 1. CẤU HÌNH TOKEN & GITHUB ---
$EncodedKeys = @("QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR","QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v")
$API_KEY = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedKeys[0]))
$csvUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"

# Tải danh sách (Fix lỗi Convert Byte)
try {
    $res = Invoke-WebRequest -Uri $csvUrl -UseBasicParsing
    $content = if ($res.Content -is [string]) { $res.Content } else { [System.Text.Encoding]::UTF8.GetString($res.Content) }
    # Lọc lấy các dòng có chứa chữ .wim
    $ListWin = $content | ConvertFrom-Csv | Where-Object { $_.Name -match "wim" -or $_.FileID -match "wim" }
    if (!$ListWin) { $ListWin = $content | ConvertFrom-Csv | Select-Object -First 3 }
} catch { [System.Windows.MessageBox]::Show("Lỗi kết nối GitHub!"); exit }

# --- 2. GIAO DIỆN XAML ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Win Auto-Deploy" Height="550" Width="420" Background="Transparent" AllowsTransparency="True" WindowStyle="None">
    <Border CornerRadius="20" Background="#121212" BorderBrush="#00FF7F" BorderThickness="1.5">
        <Grid Margin="20">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="WINDOWS CLOUD TOOL" Foreground="#00FF7F" FontSize="22" FontWeight="Black" HorizontalAlignment="Center" Margin="0,0,0,20"/>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Hidden"><StackPanel Name="ButtonContainer"/></ScrollViewer>
            <StackPanel Grid.Row="2">
                <TextBlock Name="lblStatus" Text="Sẵn sàng..." Foreground="#666666" HorizontalAlignment="Center" Margin="0,10"/>
                <ProgressBar Name="progBar" Height="6" Foreground="#00FF7F" Background="#222222" BorderThickness="0"/>
                <Button Name="btnExit" Content="THOÁT" Margin="0,10,0,0" Height="30" Width="80" Background="Transparent" Foreground="#FF4D4D" BorderBrush="#FF4D4D"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$container = $window.FindName("ButtonContainer")
$lblStatus = $window.FindName("lblStatus")
$progBar = $window.FindName("progBar")

# --- 3. HÀM XỬ LÝ Ổ ĐĨA & CÀI ĐẶT ---
function Start-UltimateDeploy ($win) {
    # Kiểm tra ổ đĩa phụ D hoặc E để chứa file tạm (Cần > 10GB)
    $dataDrive = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" -and $_.Free -gt 10GB } | Select-Object -First 1).Name
    if (!$dataDrive) { [System.Windows.MessageBox]::Show("Lỗi: Cần ổ D hoặc E trống 10GB!"); return }

    $lblStatus.Text = "Đang kiểm tra Partition & tải WIM..."
    $progBar.IsIndeterminate = $true

    # [BƯỚC A] Kiểm tra/Tạo Boot EFI & Recovery
    $cPart = Get-Partition -DriveLetter C
    # Check EFI
    if (!(Get-Partition -DiskNumber 0 | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" })) {
        "select disk 0`nselect partition $($cPart.PartitionNumber)`nshrink minimum=100`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S" | diskpart
    }
    # Check WinRE
    if ((reagentc /info) -match "Disabled") {
        "select disk 0`nselect partition $($cPart.PartitionNumber)`nshrink minimum=1024`ncreate partition primary`nformat quick fs=ntfs label='Recovery'`nset id='de94bba4-06d1-4d40-a16a-bfd50179d6ac'`ngpt attributes=0x8000000000000001" | diskpart
        reagentc /enable
    }

    # [BƯỚC B] Tải file WIM bằng curl
    $wimPath = "$($dataDrive):\install.wim"
    $url = "https://www.googleapis.com/drive/v3/files/$($win.FileID)?alt=media&key=$API_KEY"
    Start-ThreadJob { param($u, $p) curl.exe -L -o $p $u } -ArgumentList $url, $wimPath | Wait-Job

    # [BƯỚC C] Tạo kịch bản auto_install.bat
    $batScript = @"
@echo off
(echo select disk 0 & echo select partition $($cPart.PartitionNumber) & echo format quick fs=ntfs label='Windows' & echo assign letter=C & echo exit) | diskpart
dism /Apply-Image /ImageFile:$wimPath /Index:1 /ApplyDir:C:\
bcdboot C:\Windows /s S: /f UEFI
wpeutil reboot
"@
    $batScript | Out-File -FilePath "$($dataDrive):\auto_install.bat" -Encoding ASCII

    # [BƯỚC D] REBOOT
    $lblStatus.Text = "Xong! Máy sẽ Restart cài Win sau 5s..."
    [System.Windows.MessageBox]::Show("Mọi thứ đã sẵn sàng. Tuấn hãy nhấn OK để máy tự Restart và bung lụa!")
    reagentc /boottore
    shutdown /r /t 5
}

# --- 4. ĐỔ DỮ LIỆU ---
foreach ($win in $ListWin) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "💾  $($win.Name)"
    $btn.Height = 55; $btn.Margin = "0,5"; $btn.Foreground = "White"; $btn.Background = "#1E1E1E"; $btn.FontWeight = "Bold"; $btn.Cursor = "Hand"
    $btn.Add_Click({ Start-UltimateDeploy $win })
    $container.Children.Add($btn)
}

$window.FindName("btnExit").Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null