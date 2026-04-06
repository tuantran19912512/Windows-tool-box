Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# --- 0. FIX KẾT NỐI TLS 1.2 ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 1. CẤU HÌNH TOKEN & GITHUB ---
$EncodedKeys = @(
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR",
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v"
)
$API_KEY = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedKeys[0]))
$csvUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"

# --- 2. TẢI DANH SÁCH (SỬA LỖI CONVERT) ---
try {
    $response = Invoke-WebRequest -Uri $csvUrl -UseBasicParsing
    
    # Nếu Content đã là String thì lấy luôn, nếu là Byte thì mới Convert
    if ($response.Content -is [string]) {
        $content = $response.Content
    } else {
        $content = [System.Text.Encoding]::UTF8.GetString($response.Content)
    }
    
    # Lọc: Chỉ lấy cái nào tên có chữ ".wim" (không phân biệt hoa thường)
    $ListWin = $content | ConvertFrom-Csv | Where-Object { $_.Name -like "*.wim*" -or $_.FileID -like "*.wim*" }
    
    if ($null -eq $ListWin -or ($ListWin | Measure-Object).Count -eq 0) {
        # Nếu lọc theo .wim không ra gì, lấy tạm 2 dòng đầu để Tuấn test giao diện
        $ListWin = $content | ConvertFrom-Csv | Select-Object -First 3
    }
} catch {
    [System.Windows.MessageBox]::Show("LỖI: $($_.Exception.Message)")
    exit
}

# --- 3. GIAO DIỆN XAML ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Win Auto-Deploy" Height="550" Width="420" Background="Transparent" AllowsTransparency="True" WindowStyle="None">
    <Border CornerRadius="20" Background="#121212" BorderBrush="#00FF7F" BorderThickness="1.5">
        <Grid Margin="20">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="WINDOWS CLOUD TOOL" Foreground="#00FF7F" FontSize="22" FontWeight="Black" HorizontalAlignment="Center" Margin="0,0,0,20"/>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Hidden"><StackPanel Name="ButtonContainer"/></ScrollViewer>
            <StackPanel Grid.Row="2">
                <TextBlock Name="lblStatus" Text="Sẵn sàng..." Foreground="#666666" HorizontalAlignment="Center" Margin="0,10"/>
                <Button Name="btnExit" Content="THOÁT" Height="30" Width="80" Background="Transparent" Foreground="#FF4D4D" BorderBrush="#FF4D4D"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$container = $window.FindName("ButtonContainer")

# --- 4. TẠO NÚT BẤM ---
foreach ($win in $ListWin) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "📦  $($win.Name)"
    $btn.Height = 55; $btn.Margin = "0,5"; $btn.Foreground = "White"; $btn.Background = "#1E1E1E"; $btn.FontWeight = "Bold"
    
    $btn.Add_Click({
        # Sử dụng đúng tên cột FileID từ CSV của Tuấn
        [System.Windows.MessageBox]::Show("Đang tải: $($win.Name)`nID: $($win.FileID)")
    })
    $container.Children.Add($btn)
}

$window.FindName("btnExit").Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null