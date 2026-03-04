Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# 1. Khởi tạo đối tượng đo hiệu năng siêu nhanh (Fix lag)
$cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total")
$null = $cpuCounter.NextValue()

# 2. Giao diện XAML (Nới rộng 1200x800 để chứa toàn bộ dữ liệu)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - System Center Ultra Pro" Height="800" Width="1200" 
        Background="#121212" WindowStyle="None" AllowsTransparency="True" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" Background="#1E1E1E" BorderBrush="#007ACC" BorderThickness="2">
        <Grid>
            <TextBlock Text="TRUNG TÂM PHÂN TÍCH HỆ THỐNG TOÀN DIỆN (BẢN FULL CHI TIẾT)" Foreground="#007ACC" FontSize="22" FontWeight="Bold" 
                       HorizontalAlignment="Center" Margin="0,15,0,0"/>
            
            <Grid Margin="20,70,20,100">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="330"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" VerticalAlignment="Top" Margin="0,10,0,0">
                    <GroupBox Header="GIÁM SÁT TẢI (%)" Foreground="#007ACC" BorderBrush="#333333" Margin="5">
                        <StackPanel Margin="10">
                            <DockPanel LastChildFill="False">
                                <TextBlock Text="CPU USAGE" Foreground="White" DockPanel.Dock="Left"/>
                                <TextBlock Name="CpuPct" Text="0%" Foreground="#FF3B30" FontWeight="Bold" DockPanel.Dock="Right"/>
                            </DockPanel>
                            <ProgressBar Name="CpuBar" Height="10" Margin="0,5,0,15" Minimum="0" Maximum="100" Foreground="#FF3B30" Background="#333333"/>
                            
                            <DockPanel LastChildFill="False">
                                <TextBlock Text="RAM USAGE" Foreground="White" DockPanel.Dock="Left"/>
                                <TextBlock Name="RamPct" Text="0%" Foreground="#4CD964" FontWeight="Bold" DockPanel.Dock="Right"/>
                            </DockPanel>
                            <ProgressBar Name="RamBar" Height="10" Margin="0,5,0,15" Minimum="0" Maximum="100" Foreground="#4CD964" Background="#333333"/>
                            
                            <DockPanel LastChildFill="False">
                                <TextBlock Text="DISK C: USAGE" Foreground="White" DockPanel.Dock="Left"/>
                                <TextBlock Name="DiskPct" Text="0%" Foreground="#007ACC" FontWeight="Bold" DockPanel.Dock="Right"/>
                            </DockPanel>
                            <ProgressBar Name="DiskBar" Height="10" Margin="0,5,0,0" Minimum="0" Maximum="100" Foreground="#007ACC" Background="#333333"/>
                        </StackPanel>
                    </GroupBox>
                    
                    <GroupBox Header="SỨC KHỎE PIN" Name="BoxPin" Foreground="#007ACC" BorderBrush="#333333" Margin="5" Visibility="Collapsed">
                        <StackPanel Margin="10">
                            <TextBlock Name="PinText" Text="Sức khỏe: 0%" Foreground="White" HorizontalAlignment="Center" FontWeight="Bold"/>
                            <ProgressBar Name="PinBar" Height="10" Margin="0,5,0,0" Minimum="0" Maximum="100" Foreground="#FFCC00" Background="#333333"/>
                        </StackPanel>
                    </GroupBox>
                </StackPanel>

                <GroupBox Grid.Column="1" Header="HỒ SƠ PHẦN CỨNG CHI TIẾT &amp; CHẨN ĐOÁN" Foreground="#007ACC" BorderBrush="#333333" Margin="10,0,0,0">
                    <TextBox Name="TxtDetail" Background="#0F0F0F" Foreground="#00FF00" FontFamily="Consolas" FontSize="12" 
                             IsReadOnly="True" BorderThickness="0" VerticalScrollBarVisibility="Auto" Padding="15" AcceptsReturn="True"/>
                </GroupBox>
            </Grid>

            <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Center" Margin="0,0,0,30">
                <Button Name="BtnRefresh" Content="QUÉT LẠI CẤU HÌNH" Height="45" Width="220" Margin="10,0" Background="#007ACC" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnExit" Content="THOÁT TRUNG TÂM" Height="45" Width="220" Margin="10,0" Background="#333333" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Ánh xạ UI
$cpuBar = $window.FindName("CpuBar"); $cpuPct = $window.FindName("CpuPct")
$ramBar = $window.FindName("RamBar"); $ramPct = $window.FindName("RamPct")
$diskBar = $window.FindName("DiskBar"); $diskPct = $window.FindName("DiskPct")
$pinBar = $window.FindName("PinBar"); $pinText = $window.FindName("PinText"); $boxPin = $window.FindName("BoxPin")
$txtDetail = $window.FindName("TxtDetail"); $btnExit = $window.FindName("BtnExit"); $btnRefresh = $window.FindName("BtnRefresh")

# 3. HÀM QUÉT DỮ LIỆU SIÊU CHI TIẾT (VÉT CẠN)
function Update-DetailText {
    $out = ">>> [ 1. BO MẠCH CHỦ & BIOS ] <<<`r`n"
    $board = Get-CimInstance Win32_BaseBoard; $bios = Get-CimInstance Win32_BIOS
    $out += ("{0,-22}: {1}`r`n" -f "Hãng sản xuất", $board.Manufacturer)
    $out += ("{0,-22}: {1}`r`n" -f "Model Mainboard", $board.Product)
    $out += ("{0,-22}: {1}`r`n" -f "Số Serial Main", $board.SerialNumber)
    $out += ("{0,-22}: {1} (Ngày: {2})`r`n" -f "Phiên bản BIOS", $bios.SMBIOSBIOSVersion, $bios.ReleaseDate.ToString('dd/MM/yyyy'))
    
    $out += "`r`n>>> [ 2. VI XỬ LÝ (CPU) ] <<<`r`n"
    $cpu = Get-CimInstance Win32_Processor
    $cpuCores = $cpu.NumberOfCores
    $out += ("{0,-22}: {1}`r`n" -f "Tên CPU", $cpu.Name.Trim())
    $out += ("{0,-22}: {1} Nhân / {2} Luồng`r`n" -f "Cấu trúc", $cpuCores, $cpu.NumberOfLogicalProcessors)
    $out += ("{0,-22}: {1} MHz`r`n" -f "Xung nhịp tối đa", $cpu.MaxClockSpeed)
    $out += ("{0,-22}: {1} MB`r`n" -f "Bộ nhớ đệm L3", [Math]::Round($cpu.L3CacheSize / 1024, 0))

    $out += "`r`n>>> [ 3. CHI TIẾT TỪNG THANH RAM ] <<<`r`n"
    $ramChips = Get-CimInstance Win32_PhysicalMemory
    $ramSlots = Get-CimInstance Win32_PhysicalMemoryArray | Select-Object -ExpandProperty MemoryDevices
    $ramTotal = 0; $i = 1
    foreach ($chip in $ramChips) {
        $v = switch($chip.Manufacturer.Trim()){"0198"{"Kingston"};"00CE"{"Samsung"};"029E"{"Hynix"};"04CB"{"ADATA"};"802C"{"Micron"};default{$chip.Manufacturer.Trim()}}
        $capGB = [Math]::Round($chip.Capacity/1GB,0); $ramTotal += $capGB
        $out += " + THANH RAM $i :`r`n"
        $out += ("   - Dung lượng     : {0} GB | BUS: {1} MHz`r`n" -f $capGB, $chip.Speed)
        $out += ("   - Hãng sản xuất  : {0}`r`n" -f $v)
        $out += ("   - Part Number    : {0}`r`n" -f $chip.PartNumber.Trim())
        $out += ("   - Số Serial      : {0}`r`n" -f $chip.SerialNumber.Trim())
        $i++
    }

    $out += "`r`n>>> [ 4. Ổ CỨNG (NIÊM YẾT VS THỰC TẾ) ] <<<`r`n"
    $disks = Get-PhysicalDisk
    foreach ($d in $disks) {
        $realGB = [Math]::Round($d.Size / 1GB, 1)
        $marketRaw = $d.Size / 1000000000
        $label = switch ($marketRaw) { {$_ -le 128}{"120/128GB"}{$_ -le 256}{"240/256GB"}{$_ -le 512}{"480/512GB"}{$_ -le 1024}{"1TB"}default{[Math]::Round($marketRaw,0).ToString()+"GB"} }
        $out += " + Ổ CỨNG: $($d.FriendlyName) [$($d.MediaType)]`r`n"
        $out += ("   - Niêm yết       : {0}`r`n" -f $label)
        $out += ("   - Thực tế        : {0} GB (Hệ Windows)`r`n" -f $realGB)
        $out += ("   - Sức khỏe       : [{0}] | Serial: {1}`r`n" -f $d.HealthStatus, $d.SerialNumber.Trim())
    }

    $out += "`r`n>>> [ 5. ĐỒ HỌA (GPU) - CHI TIẾT CHÍNH XÁC ] <<<`r`n"
    
    # Hàm lấy VRAM chính xác từ Registry (Bỏ qua giới hạn WMI 32-bit)
    $GpuRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\00*"
    $GpuData = Get-ItemProperty -Path $GpuRegPath -ErrorAction SilentlyContinue
    
    $gpus = Get-CimInstance Win32_VideoController
    $totalSysRam = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB

    foreach ($g in $gpus) {
        # Dò tìm VRAM chuẩn từ Registry dựa trên tên Card
        $MatchReg = $GpuData | Where-Object { $_.DriverDesc -eq $g.Name }
        $ExactVRAM = 0
        
        if ($MatchReg -and $MatchReg."HardwareInformation.AdapterMemorySize") {
            # Lấy giá trị từ Registry (Dạng 64-bit Unsigned)
            $ExactVRAM = [Math]::Round($MatchReg."HardwareInformation.AdapterMemorySize" / 1GB, 2)
        } else {
            # Fallback nếu Registry lỗi (Dùng cách tính cũ nhưng ép kiểu 64-bit)
            $raw = [int64]$g.AdapterRAM
            if ($raw -lt 0) { $raw += 4294967296 }
            $ExactVRAM = [Math]::Round($raw / 1GB, 2)
        }

        # Shared Memory (RAM chia sẻ - Thường là 50% System RAM)
        $vramShared = [Math]::Round($totalSysRam / 2, 2)
        $vramTotal = $ExactVRAM + $vramShared

        $out += ("- Tên Card      : {0}`r`n" -f $g.Name)
        $out += ("  + VRAM RIÊNG  : {0} GB (Dedicated - Hàng thật)`r`n" -f $ExactVRAM)
        $out += ("  + VRAM CHIA SẺ: {0} GB (Shared - Mượn RAM)`r`n" -f $vramShared)
        $out += ("  + TỔNG CỘNG   : {0} GB (Total Graphics Memory)`r`n" -f $vramTotal)
        $out += ("  + Trình điều khiển: {0} (Ngày: {1})`r`n" -f $g.DriverVersion, $g.DriverDate.ToString('dd/MM/yyyy'))
        $out += " ----------------------------------------------------------`r`n"
    }

    $out += "`r`n==========================================================`r`n"
    $out += ">>> PHÂN TÍCH NGHẼN CỔ CHAI & TƯ VẤN NÂNG CẤP <<<`r`n"
    $out += "==========================================================`r`n"
    if ($cpuCores -le 4 -and $totalVRAM -ge 8) { $out += "[!!!] NGHẼN CPU: Vi xử lý quá yếu so với Card đồ họa.`r`n" }
    elseif ($cpuCores -ge 12 -and $totalVRAM -le 4) { $out += "[!!!] NGHẼN GPU: Card đồ họa quá yếu so với Vi xử lý.`r`n" }
    if ($ramTotal -lt 16 -and $totalVRAM -ge 8) { $out += "[!] NGHẼN RAM: Cần nâng cấp lên ít nhất 16-32GB RAM để render.`r`n" }
    if ($disks.MediaType -contains "HDD") { $out += "[!!!] NGHẼN Ổ CỨNG: Hãy thay SSD ngay để thoát cảnh giật lag.`r`n" }
    if ($ramSlots -gt $ramChips.Count) { $out += "[+] KHE RAM: Còn trống $(($ramSlots - $ramChips.Count)) khe cắm. Nâng cấp rất dễ.`r`n" }

    $txtDetail.Text = $out
}

# 4. TIMER CẬP NHẬT (%) SIÊU MƯỢT
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(800)
$timer.Add_Tick({
    try {
        $cpuVal = $cpuCounter.NextValue(); $cpuBar.Value = $cpuVal; $cpuPct.Text = "$([Math]::Round($cpuVal, 0))%"
        $os = Get-CimInstance Win32_OperatingSystem
        $ramVal = (($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100
        $ramBar.Value = $ramVal; $ramPct.Text = "$([Math]::Round($ramVal, 0))%"
        $driveC = Get-PSDrive C; $diskVal = ($driveC.Used / ($driveC.Used + $driveC.Free)) * 100
        $diskBar.Value = $diskVal; $diskPct.Text = "$([Math]::Round($diskVal, 0))%"
        
        $batt = Get-CimInstance -Namespace root/wmi -ClassName MsBattery_FullChargeCapacity -ErrorAction SilentlyContinue
        if ($batt) {
            $design = Get-CimInstance -Namespace root/wmi -ClassName MsBattery_DesignCapacity -ErrorAction SilentlyContinue
            $boxPin.Visibility = "Visible"; $h = [Math]::Round(($batt.FullChargeCapacity / $design.DesignCapacity) * 100, 1)
            $pinBar.Value = $h; $pinText.Text = "Sức khỏe Pin: $h%"
        }
    } catch {}
})

# 5. KHỞI CHẠY
Update-DetailText
$timer.Start()
$btnRefresh.Add_Click({ Update-DetailText })
$btnExit.Add_Click({ $timer.Stop(); $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null