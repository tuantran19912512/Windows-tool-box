Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 1. CẤU HÌNH API & GITHUB ---
$API_KEY = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"))
$csvUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"

try {
    $res = Invoke-WebRequest -Uri $csvUrl -UseBasicParsing -ErrorAction Stop
    $raw = if ($res.Content -is [string]) { $res.Content } else { [System.Text.Encoding]::UTF8.GetString($res.Content) }
    $ListWin = $raw | ConvertFrom-Csv | Where-Object { $_.Name -match "\.wim" }
    if (!$ListWin) { throw "Không có file .wim" }
} catch { [System.Windows.MessageBox]::Show("Lỗi tải danh sách bộ cài!"); exit }

# --- 2. GIAO DIỆN XAML (TỰ ĐỘNG CO GIÃN CHIỀU CAO) ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinDeploy" SizeToContent="Height" Width="430" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#1E1E1E"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="0,4"/>
            <Setter Property="MinHeight" Value="45"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" BorderBrush="#333333" BorderThickness="1" Padding="10,5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#252525"/>
                    <Setter Property="BorderBrush" Value="#00FF7F"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    <Border CornerRadius="15" Background="#121212" BorderBrush="#00FF7F" BorderThickness="1.5">
        <Grid Margin="20,20,20,25">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <TextBlock Grid.Row="0" Text="WINDOWS CLOUD INSTALLER" Foreground="#00FF7F" FontSize="18" FontWeight="Black" HorizontalAlignment="Center" Margin="0,0,0,15"/>
            
            <ScrollViewer Grid.Row="1" MaxHeight="250" VerticalScrollBarVisibility="Auto" Margin="0,5">
                <StackPanel Name="ButtonContainer"/>
            </ScrollViewer>

            <StackPanel Grid.Row="2" Margin="0,15,0,10" Background="#1A1A1A" Name="StepPanel" Visibility="Collapsed">
                <TextBlock Name="step1" Text="○ 1. Chuẩn bị phân vùng lưu trữ" Foreground="#888888" Margin="10,5" FontSize="11"/>
                <TextBlock Name="step2" Text="○ 2. Tải WIM từ Cloud (%)" Foreground="#888888" Margin="10,5" FontSize="11"/>
                <TextBlock Name="step3" Text="○ 3. Tạo kịch bản &amp; Reboot" Foreground="#888888" Margin="10,5" FontSize="11"/>
            </StackPanel>

            <StackPanel Grid.Row="3" Margin="0,5,0,0">
                <Grid Margin="0,0,0,8">
                    <TextBlock Name="lblStatus" Text="Chọn bản Win để cài đặt..." Foreground="#00FF7F" FontSize="11"/>
                    <TextBlock Name="lblPercent" Text="0%" Foreground="#00FF7F" FontSize="11" HorizontalAlignment="Right"/>
                </Grid>
                <ProgressBar Name="progBar" Height="8" Minimum="0" Maximum="100" Value="0" Foreground="#00FF7F" Background="#222222" BorderThickness="0"/>
                <Button Name="btnExit" Content="THOÁT" Margin="0,15,0,0" MinHeight="35" Width="120" BorderBrush="#FF4D4D" Foreground="#FF4D4D" Padding="0,5"/>
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

function Update-Step ($num, $status) {
    $txt = $window.FindName("step$num")
    if ($status -eq "Running") { $txt.Foreground = "#00FF7F"; $txt.Text = $txt.Text.Replace("○", "▶") }
    if ($status -eq "Done") { $txt.Foreground = "#AAAAAA"; $txt.Text = $txt.Text.Replace("▶", "✅") }
}

# --- 3. LOGIC XỬ LÝ Ổ ĐĨA & CÀI ĐẶT ---
function Start-Deploy ($win) {
    $stepPanel.Visibility = "Visible"
    $container.Children | ForEach-Object { $_.IsEnabled = $false }
    
    $cPart = Get-Partition -DriveLetter C
    $script:diskNum = $cPart.DiskNumber
    $script:partNum = $cPart.PartitionNumber

    Update-Step 1 "Running"
    
    $drive = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" -and $_.Name -ne "X" -and $_.Free -gt 6GB } | Select-Object -First 1
    
    if (!$drive) {
        $lblStatus.Text = "Đang cắt ổ đĩa tạm 6GB..."
        "select disk $($script:diskNum)`nselect partition $($script:partNum)`nshrink minimum=6144`ncreate partition primary`nformat quick fs=ntfs label='WinSetup'`nassign letter=T" | diskpart
        $script:dataDriveLetter = "T"
    } else {
        $script:dataDriveLetter = $drive.Name
    }

    "select disk $($script:diskNum)`nselect partition $($script:partNum)`nshrink minimum=1124`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S`ncreate partition primary`nformat quick fs=ntfs label='Recovery'`nset id='de94bba4-06d1-4d40-a16a-bfd50179d6ac'" | diskpart
    Update-Step 1 "Done"

    Update-Step 2 "Running"
    $script:wimPath = "$($script:dataDriveLetter):\install.wim"
    $url = "https://www.googleapis.com/drive/v3/files/$($win.FileID)?alt=media&key=$API_KEY"
    $script:job = Start-Job -ScriptBlock { param($url, $path) curl.exe -L -o $path $url } -ArgumentList $url, $script:wimPath
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    
    $timer.Add_Tick({
        if (Test-Path $script:wimPath) {
            $size = (Get-Item $script:wimPath).Length / 1MB
            $p = [math]::Min(99, [math]::Round(($size / 4500) * 100))
            $progBar.Value = $p; $lblPercent.Text = "$p %"; $lblStatus.Text = "Đang tải: $([math]::Round($size)) MB"
        }
        
        if ((Get-Job -Id $script:job.Id).State -eq "Completed") {
            $timer.Stop(); Update-Step 2 "Done"
            
            Update-Step 3 "Running"
            $bat = @"
@echo off
(echo select disk $($script:diskNum) & echo select partition $($script:partNum) & echo format quick fs=ntfs label='Windows' & echo assign letter=W & echo exit) | diskpart
for %%I in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%I:\install.wim" (
        dism /Apply-Image /ImageFile:%%I:\install.wim /Index:1 /ApplyDir:W:\
        goto done
    )
)
:done
bcdboot W:\Windows /s S: /f UEFI
wpeutil reboot
"@
            $bat | Out-File -FilePath "$($script:dataDriveLetter):\auto_install.bat" -Encoding ASCII
            Update-Step 3 "Done"
            
            reagentc /boottore
            shutdown /r /t 5
        }
    }.GetNewClosure())
    $timer.Start()
}

foreach ($win in $ListWin) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "💾  $($win.Name)"
    $btn.Add_Click({ Start-Deploy $win })
    $container.Children.Add($btn)
}

$window.FindName("btnExit").Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null