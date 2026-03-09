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
                    <TextBox Name="TxtDetail" Background="#0F0F0F" Foreground="#00FF00" FontFamily="Consolas" FontSize="13" 
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

# 3. HÀM QUÉT DỮ LIỆU CÓ HIỆU ỨNG IN TỪNG MỤC
function Update-DetailText {
    $btnRefresh.IsEnabled = $false
    $txtDetail.Clear()
    [System.Windows.Forms.Application]::DoEvents()

    function Add-Live ($Text, $Delay = 300) {
        $txtDetail.AppendText($Text)
        $txtDetail.ScrollToEnd()
        [System.Windows.Forms.Application]::DoEvents()
        if ($Delay -gt 0) { Start-Sleep -Milliseconds $Delay }
    }

    Add-Live ">>> ĐANG KHỞI TẠO QUÉT HỆ THỐNG... VUI LÒNG ĐỢI <<<`r`n" 500

    # --- 1. BO MẠCH CHỦ ---
    $board = Get-CimInstance Win32_BaseBoard; $bios = Get-CimInstance Win32_BIOS
    $t1 = "`r`n>>> [ 1. BO MẠCH CHỦ & BIOS ] <<<`r`n"
    $t1 += ("{0,-22}: {1}`r`n" -f "Hãng sản xuất", $board.Manufacturer)
    $t1 += ("{0,-22}: {1}`r`n" -f "Model Mainboard", $board.Product)
    $t1 += ("{0,-22}: {1}`r`n" -f "Số Serial Main", $board.SerialNumber)
    $t1 += ("{0,-22}: {1} (Ngày: {2})`r`n" -f "Phiên bản BIOS", $bios.SMBIOSBIOSVersion, $bios.ReleaseDate.ToString('dd/MM/yyyy'))
    Add-Live $t1 300

    # --- 2. CPU ---
    $cpu = Get-CimInstance Win32_Processor
    $cpuCores = $cpu.NumberOfCores
    $t2 = "`r`n>>> [ 2. VI XỬ LÝ (CPU) ] <<<`r`n"
    $t2 += ("{0,-22}: {1}`r`n" -f "Tên CPU", $cpu.Name.Trim())
    $t2 += ("{0,-22}: {1} Nhân / {2} Luồng`r`n" -f "Cấu trúc", $cpuCores, $cpu.NumberOfLogicalProcessors)
    $t2 += ("{0,-22}: {1} MHz`r`n" -f "Xung nhịp tối đa", $cpu.MaxClockSpeed)
    $t2 += ("{0,-22}: {1} MB`r`n" -f "Bộ nhớ đệm L3", [Math]::Round($cpu.L3CacheSize / 1024, 0))
    Add-Live $t2 300

    # --- 3. RAM (ĐÃ BỔ SUNG SỐ KHE TRỐNG) ---
    $ramChips = Get-CimInstance Win32_PhysicalMemory
    $ramSlots = Get-CimInstance Win32_PhysicalMemoryArray | Select-Object -ExpandProperty MemoryDevices
    $ramTotal = 0; $i = 1
    
    # Tính số khe RAM còn trống
    $emptySlots = $ramSlots - $ramChips.Count
    if ($emptySlots -lt 0) { $emptySlots = 0 } # Đề phòng WMI báo lỗi số liệu ảo

    $t3 = "`r`n>>> [ 3. BỘ NHỚ TRONG (RAM) ] <<<`r`n"
    $t3 += ("{0,-22}: {1} khe (Đang cắm: {2} | Trống: {3})`r`n" -f "Tình trạng khe cắm", $ramSlots, $ramChips.Count, $emptySlots)
    
    foreach ($chip in $ramChips) {
        $v = switch($chip.Manufacturer.Trim()){"0198"{"Kingston"};"00CE"{"Samsung"};"029E"{"Hynix"};"04CB"{"ADATA"};"802C"{"Micron"};default{$chip.Manufacturer.Trim()}}
        $capGB = [Math]::Round($chip.Capacity/1GB,0); $ramTotal += $capGB
        $t3 += " + THANH RAM $i :`r`n"
        $t3 += ("   - Dung lượng     : {0} GB | BUS: {1} MHz`r`n" -f $capGB, $chip.Speed)
        $t3 += ("   - Hãng sản xuất  : {0}`r`n" -f $v)
        $t3 += ("   - Part Number    : {0}`r`n" -f $chip.PartNumber.Trim())
        $t3 += ("   - Số Serial      : {0}`r`n" -f $chip.SerialNumber.Trim())
        $i++
    }
    Add-Live $t3 400

    # --- 4. Ổ CỨNG ---
    $disks = Get-PhysicalDisk
    $t4 = "`r`n>>> [ 4. Ổ CỨNG (NIÊM YẾT VS THỰC TẾ) ] <<<`r`n"
    foreach ($d in $disks) {
        $realGB = [Math]::Round($d.Size / 1GB, 1)
        $marketRaw = $d.Size / 1000000000
        $label = switch ($marketRaw) { {$_ -le 128}{"120/128GB"}{$_ -le 256}{"240/256GB"}{$_ -le 512}{"480/512GB"}{$_ -le 1024}{"1TB"}default{[Math]::Round($marketRaw,0).ToString()+"GB"} }
        $t4 += " + Ổ CỨNG: $($d.FriendlyName) [$($d.MediaType)]`r`n"
        $t4 += ("   - Niêm yết       : {0}`r`n" -f $label)
        $t4 += ("   - Thực tế        : {0} GB (Hệ Windows)`r`n" -f $realGB)
        $t4 += ("   - Sức khỏe       : [{0}] | Serial: {1}`r`n" -f $d.HealthStatus, $d.SerialNumber.Trim())
    }
    Add-Live $t4 400

    # --- 5. ĐỒ HỌA GPU ---
    $gpus = Get-CimInstance Win32_VideoController
    $os = Get-CimInstance Win32_OperatingSystem
    $totalSysRam = $os.TotalVisibleMemorySize / 1MB
    $totalVRAM = 0
    $t5 = "`r`n>>> [ 5. ĐỒ HỌA (GPU) - BẢN FIX LỖI BINARY ] <<<`r`n"

    foreach ($g in $gpus) {
        $exactVRAM = 0; $method = ""

        if ($g.Name -match "NVIDIA") {
            $smiFile = "$env:TEMP\vram.txt"
            $smiProc = Start-Process "nvidia-smi" -ArgumentList "--query-gpu=memory.total --format=csv,noheader,nounits" -NoNewWindow -PassThru -RedirectStandardOutput $smiFile -ErrorAction SilentlyContinue
            if ($smiProc) {
                $smiProc.WaitForExit(3000)
                if (Test-Path $smiFile) {
                    $vramRaw = Get-Content $smiFile | Out-String
                    if ($vramRaw -match "\d+") {
                        $exactVRAM = [Math]::Round([float]$vramRaw.Trim() / 1024, 2); $method = "(NVIDIA SMI)"
                    }
                    Remove-Item $smiFile -Force -ErrorAction SilentlyContinue
                }
            }
        }

        if ($exactVRAM -le 0) {
            $regPaths = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\00*" -ErrorAction SilentlyContinue
            foreach ($reg in $regPaths) {
                if ($reg.DriverDesc -eq $g.Name) {
                    $val = $null
                    if ($reg."HardwareInformation.qwMemorySize") { $val = $reg."HardwareInformation.qwMemorySize" }
                    elseif ($reg."HardwareInformation.MemorySize") { $val = $reg."HardwareInformation.MemorySize" }

                    if ($val -is [System.Array]) {
                        if ($val.Length -ge 8) { $exactVRAM = [Math]::Round([System.BitConverter]::ToUInt64($val, 0) / 1GB, 2); $method = "(Reg-Bin64)" }
                        elseif ($val.Length -ge 4) { $exactVRAM = [Math]::Round([System.BitConverter]::ToUInt32($val, 0) / 1GB, 2); $method = "(Reg-Bin32)" }
                    }
                    elseif ($val -ne $null) {
                        $raw = [int64]$val
                        if ($raw -lt 0) { $raw += 4294967296 }
                        $exactVRAM = [Math]::Round($raw / 1GB, 2); $method = "(Reg-Num)"
                    }
                }
            }
        }

        if ($exactVRAM -le 0) {
            $raw = [int64]$g.AdapterRAM
            if ($raw -lt 0) { $raw += 4294967296 }
            $exactVRAM = [Math]::Round($raw / 1GB, 2); $method = "(WMI-Fix)"
        }

        $vramShared = [Math]::Round($totalSysRam / 2, 2)
        $vramTotal = $exactVRAM + $vramShared
        $totalVRAM += $exactVRAM

        $t5 += ("- GPU: {0} {1}`r`n" -f $g.Name, $method)
        $t5 += ("  + VRAM RIÊNG (Dedicated): {0} GB`r`n" -f $exactVRAM)
        $t5 += ("  + VRAM CHIA SẺ (Shared) : {0} GB`r`n" -f $vramShared)
        $t5 += ("  + TỔNG DUNG LƯỢNG VGA   : {0} GB`r`n" -f $vramTotal)
        $t5 += ("  + Driver: {0}`r`n" -f $g.DriverVersion)
        $t5 += " ----------------------------------------------------------`r`n"
    }
    Add-Live $t5 500

    # --- 6. PHÂN TÍCH NGHẼN CỔ CHAI ---
    $t6 = "`r`n==========================================================`r`n"
    $t6 += ">>> PHÂN TÍCH NGHẼN CỔ CHAI & TƯ VẤN NÂNG CẤP <<<`r`n"
    $t6 += "==========================================================`r`n"
    if ($cpuCores -le 4 -and $totalVRAM -ge 8) { $t6 += "[!!!] NGHẼN CPU: Vi xử lý quá yếu so với Card đồ họa.`r`n" }
    elseif ($cpuCores -ge 12 -and $totalVRAM -le 4) { $t6 += "[!!!] NGHẼN GPU: Card đồ họa quá yếu so với Vi xử lý.`r`n" }
    if ($ramTotal -lt 16 -and $totalVRAM -ge 8) { $t6 += "[!] NGHẼN RAM: Cần nâng cấp lên ít nhất 16-32GB RAM để render.`r`n" }
    if ($disks.MediaType -contains "HDD") { $t6 += "[!!!] NGHẼN Ổ CỨNG: Hãy thay SSD ngay để thoát cảnh giật lag.`r`n" }
    if ($emptySlots -gt 0) { $t6 += "[+] KHE RAM: Hệ thống còn trống $emptySlots khe cắm, có thể dễ dàng nâng cấp thêm RAM.`r`n" }
    
    Add-Live $t6 0

    $btnRefresh.IsEnabled = $true
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
$txtDetail.Text = ">>> HỆ THỐNG ĐÃ SẴN SÀNG... VUI LÒNG BẤM 'QUÉT LẠI CẤU HÌNH' ĐỂ BẮT ĐẦU PHÂN TÍCH <<<`r`n"
$timer.Start()
$btnRefresh.Add_Click({ Update-DetailText })
$btnExit.Add_Click({ $timer.Stop(); $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null