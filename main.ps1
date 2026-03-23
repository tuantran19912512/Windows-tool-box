# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO - BẢNG ĐIỀU KHIỂN (V182.10 - PURE WPF EDITION)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

# 1. THIẾT LẬP MÔI TRƯỜNG & LOẠI BỎ HOÀN TOÀN WINDOWS FORMS
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

if ($PSScriptRoot -eq "" -or $null -eq $PSScriptRoot) { $Global:CurrentPath = $pwd } else { $Global:CurrentPath = $PSScriptRoot }
$scriptFolder = Join-Path $Global:CurrentPath "Scripts"
$logoPath = Join-Path $Global:CurrentPath "logo2.png"

# Nạp thư viện lõi WPF (Không dùng System.Windows.Forms nữa)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- TÍNH TOÁN KÍCH THƯỚC CỬA SỔ PHÙ HỢP VỚI MÀN HÌNH ---
$screenWidth = [System.Windows.SystemParameters]::WorkArea.Width
$screenHeight = [System.Windows.SystemParameters]::WorkArea.Height

# Kích thước gốc thiết kế là 1200x850
$winW = if ($screenWidth -lt 1250) { $screenWidth * 0.95 } else { 1200 }
$winH = if ($screenHeight -lt 900) { $screenHeight * 0.95 } else { 850 }

# --- GIẢI MÃ KEY AI ---
$EncStr = "B9vMDEyC5peZeIP4Wjc8u32aWyJN9xa9+pGS1p9iS4GQEfN1xAXtzTsaseDNR4vjFqKU065hbGBnMy5kMUlH3w=="
try {
    $S = [Text.Encoding]::UTF8.GetBytes("VietToolbox")
    $K = (New-Object Security.Cryptography.Rfc2898DeriveBytes "Admin@2512", $S, 1000).GetBytes(32)
    $I = (New-Object Security.Cryptography.Rfc2898DeriveBytes "Admin@2512", $S, 1000).GetBytes(16)
    $A = [Security.Cryptography.Aes]::Create(); $A.Key = $K; $A.IV = $I
    $D = $A.CreateDecryptor(); $EB = [Convert]::FromBase64String($EncStr)
    $DB = $D.TransformFinalBlock($EB, 0, $EB.Length)
    $Global:apiKey = [Text.Encoding]::UTF8.GetString($DB); $A.Dispose()
} catch { $Global:apiKey = "" }

$Global:ModelList = @("llama-3.3-70b-versatile", "llama3-8b-8192")
$Global:IsAiRunning = $false
$Global:DanhSachScript = @()

# 2. ẨN CỬA SỔ CONSOLE
$showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru
$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) { $showWindowAsync::ShowWindowAsync($hwnd, 0) | Out-Null }

# 3. TỰ ĐỘNG YÊU CẦU QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# 4. GIAO DIỆN XAML PURE WPF
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="$winW" Height="$winH" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    
    <Viewbox Stretch="Uniform">
        <Border Width="1200" Height="850" CornerRadius="15" BorderBrush="#007ACC" BorderThickness="2">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#0A1628" Offset="0"/><GradientStop Color="#02050A" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <Grid>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,15,20,0" Panel.ZIndex="999">
                    <TextBlock Name="TxtClock" Text="00:00:00" Foreground="#007ACC" FontSize="16" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,20,0"/>
                    <Button Name="BtnTopMin" Content=" 🗕 " Width="45" Height="30" Background="Transparent" Foreground="#858585" BorderThickness="0" FontSize="16" Cursor="Hand" ToolTip="Thu nhỏ"/>
                    <Button Name="BtnTopClose" Content=" ✕ " Width="45" Height="30" Background="Transparent" Foreground="#858585" BorderThickness="0" FontSize="16" Cursor="Hand" ToolTip="Đóng"/>
                </StackPanel>

                <Grid VerticalAlignment="Top" Margin="30,30,30,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Image Grid.Column="0" Source="$logoPath" Height="140" Width="140" HorizontalAlignment="Left" Margin="0,0,30,0">
                        <Image.Effect><DropShadowEffect BlurRadius="20" Color="#007ACC" ShadowDepth="0" Opacity="0.8"/></Image.Effect>
                    </Image>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="WINDOWS TOOL BOX PRO" Foreground="#007ACC" FontSize="36" FontWeight="Bold"/>
                        <TextBlock Text="Hệ thống quản trị chuyên nghiệp - Tuấn Kỹ Thuật Máy Tính" Foreground="#858585" FontSize="16" Margin="0,8,0,0"/>
                        <TextBlock Name="TxtThongBao" Text="Đang kiểm tra cập nhật..." Foreground="#FF3333" FontSize="15" FontWeight="Bold" Margin="0,10,0,0">
                            <TextBlock.Triggers>
                                <EventTrigger RoutedEvent="TextBlock.Loaded">
                                    <BeginStoryboard>
                                        <Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="1.0" To="0.2" Duration="0:0:0.8" AutoReverse="True" RepeatBehavior="Forever"/></Storyboard>
                                    </BeginStoryboard>
                                </EventTrigger>
                            </TextBlock.Triggers>
                        </TextBlock>
                    </StackPanel>
                </Grid>

                <Separator VerticalAlignment="Top" Background="#3E3E42" Margin="30,190,30,0" Opacity="0.5"/>
                
                <Grid Margin="20,210,20,85">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="350"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    
                    <GroupBox Header="NHÓM CÔNG CỤ" Foreground="#007ACC" BorderBrush="#333333" FontWeight="Bold">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,5,0,0">
                            <StackPanel Name="GroupContainer" Margin="10"/>
                        </ScrollViewer>
                    </GroupBox>
                    
                    <GroupBox Grid.Column="1" Header="BẢNG ĐIỀU KHIỂN" Foreground="#00FF00" BorderBrush="#333333" Margin="15,0,0,0" FontWeight="Bold">
                        <TabControl Name="MainTabControl" Background="Transparent" BorderThickness="0" Margin="0,5,0,0">
                            <TabItem Header=" THÔNG TIN MÁY " Foreground="#E67E22" FontWeight="Bold">
                                <TextBox Name="TxtSysInfo" Background="#050505" Foreground="#E67E22" FontFamily="Consolas" FontSize="15" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" BorderThickness="0" Padding="15" Opacity="0.9"/>
                            </TabItem>
                            <TabItem Header=" NHẬT KÝ HỆ THỐNG " Foreground="#00FF00" FontWeight="Bold">
                                <TextBox Name="TxtLog" Background="#050505" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" BorderThickness="0" Padding="15" Opacity="0.9"/>
                            </TabItem>
                            <TabItem Header=" TRỢ LÝ AI (AUTO RUN) " Foreground="#007ACC" FontWeight="Bold">
                                <Grid Margin="10">
                                    <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <TextBox Name="TxtChatBox" Grid.Row="0" Background="#0A101A" Foreground="#DCDCDC" FontSize="14" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderBrush="#333333" Padding="10"/>
                                    <Grid Grid.Row="1" Margin="0,10,0,0">
                                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                                        <TextBox Name="TxtInputAI" Grid.Column="0" Height="35" Background="#1A1A1A" Foreground="White" BorderBrush="#007ACC" VerticalContentAlignment="Center" Padding="10,0" FontSize="14"/>
                                        <Button Name="BtnSendAI" Grid.Column="1" Content="GỬI LỆNH" Margin="10,0,0,0" Background="#007ACC" Foreground="White" FontWeight="Bold" Cursor="Hand">
                                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                                        </Button>
                                    </Grid>
                                </Grid>
                            </TabItem>
                        </TabControl>
                    </GroupBox>
                </Grid>

                <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="25">
                    <Button Name="BtnShutdown" Content="TẮT MÁY" Width="130" Height="45" Margin="0,0,10,0" Background="#D35400" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                    <Button Name="BtnRestart" Content="KHỞI ĐỘNG LẠI" Width="130" Height="45" Margin="0,0,10,0" Background="#2980B9" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                    <Button Name="BtnColor" Content="MÀU CHỮ LOG" Width="120" Height="45" Margin="0,0,10,0" Background="#333337" Foreground="White" BorderThickness="1" BorderBrush="#007ACC" FontWeight="Bold" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>
        </Border>
    </Viewbox>
</Window>
"@

# 5. KHỞI TẠO GIAO DIỆN
$stringReader = New-Object System.IO.StringReader($inputXML)
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [Windows.Markup.XamlReader]::Load($xmlReader)

# Ánh xạ các biến XAML
$mainTabControl = $window.FindName("MainTabControl")
$groupContainer = $window.FindName("GroupContainer")
$txtLog = $window.FindName("TxtLog")
$btnColor = $window.FindName("BtnColor")
$btnShutdown = $window.FindName("BtnShutdown")
$btnRestart = $window.FindName("BtnRestart")
$txtThongBao = $window.FindName("TxtThongBao")
$txtChatBox = $window.FindName("TxtChatBox")
$txtInputAI = $window.FindName("TxtInputAI")
$btnSendAI = $window.FindName("BtnSendAI")
$txtSysInfo = $window.FindName("TxtSysInfo") 
$btnTopMin = $window.FindName("BtnTopMin")
$btnTopClose = $window.FindName("BtnTopClose")
$txtClock = $window.FindName("TxtClock")

# --- HÀM DOEVENTS CHUẨN WPF (CHỐNG ĐƠ GIAO DIỆN) ---
$CapNhatGiaoDien = {
    $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

# --- KHỞI ĐỘNG BỘ ĐẾM ĐỒNG HỒ TÍCH HỢP WPF ---
$clockTimer = New-Object System.Windows.Threading.DispatcherTimer
$clockTimer.Interval = [TimeSpan]::FromSeconds(1)
$clockTimer.Add_Tick({ $txtClock.Text = (Get-Date).ToString("HH:mm:ss  |  dd/MM/yyyy") })
$clockTimer.Start()
$txtClock.Text = (Get-Date).ToString("HH:mm:ss  |  dd/MM/yyyy") 

# 6. TẢI THÔNG BÁO TỪ GITHUB
try {
    $urlRaw = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/ThongBao.txt"
    $rawText = Invoke-RestMethod -Uri ($urlRaw + "?t=" + [DateTime]::Now.Ticks) -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    $foundKhach = ($rawText -split "`n" | Where-Object { $_ -match "Khách:" }) -replace ".*Khách:\s*", ""
    $txtThongBao.Text = if ($foundKhach.Trim() -ne "") { "🔥 " + $foundKhach.Trim() } else { "🔥 VietToolbox Pro - Sẵn sàng!" }
} catch { $txtThongBao.Text = "🔥 VietToolbox Pro - Hệ thống ổn định!" }

# 7. HÀM LOG (ĐÃ FIX SANG CHUẨN WPF)
$Global:LogColorGreen = $true
function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{ 
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
        $txtLog.ScrollToEnd() 
    })
    &$CapNhatGiaoDien
}

# 8. CẬP NHẬT DANH SÁCH SCRIPTS (CÂY THƯ MỤC WPF)
function Update-UI {
    $null = $groupContainer.Children.Clear(); $Global:DanhSachScript = @()
    if (!(Test-Path $scriptFolder)) { return }
    function Get-ScriptsRecursive ($Path, $ParentStack, $Level) {
        Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name | foreach {
            
            if ($_.PSIsContainer -and $_.Name -match "Admin") {
                Get-ChildItem -Path $_.FullName -Recurse -Filter "*.ps1" | foreach { $Global:DanhSachScript += $_.FullName }
                return 
            }

            if ($_.PSIsContainer) {
                $subExp = New-Object System.Windows.Controls.Expander
                $subExp.Header = $_.Name
                $subExp.Foreground = if ($Level -eq 0) { "#007ACC" } else { "#858585" } 
                $subExp.FontWeight = "Bold"; $subExp.FontSize = 15; $subExp.Margin = "0,5,0,5"
                $subStack = New-Object System.Windows.Controls.StackPanel; $subStack.Margin = "15,0,0,5"
                Get-ScriptsRecursive $_.FullName $subStack ($Level + 1)
                $subExp.Content = $subStack
                $null = $ParentStack.Children.Add($subExp)
            } else {
                if ($_.Extension -eq ".ps1") {
                    if ($Global:DanhSachScript -notcontains $_.FullName) { $Global:DanhSachScript += $_.FullName }
                    
                    $btn = New-Object System.Windows.Controls.Button
                    $btn.Content = "● " + $_.BaseName 
                    $btn.Height = 40; $btn.FontSize = 14; $btn.Background = "#2D2D2D"; $btn.Foreground = "#DCDCDC" 
                    $btn.HorizontalContentAlignment = "Left"; $btn.Padding = "10,0,0,0"; $btn.Margin = "0,2,0,2"; $btn.Tag = $_.FullName
                    $btn.Cursor = [System.Windows.Input.Cursors]::Hand
                    
                    # LOGIC KHI BẤM NÚT CÔNG CỤ
                    $btn.Add_Click({ 
                        param($sender, $e) 
                        $window.Dispatcher.Invoke([action]{ 
                            $mainTabControl.SelectedIndex = 1 # TỰ CHUYỂN TAB NHẬT KÝ
                            $txtLog.Clear() 
                        })
                        try { . $sender.Tag } catch { Ghi-Log "LỖI: $($_.Exception.Message)" } 
                    })
                    $null = $ParentStack.Children.Add($btn)
                }
            }
        }
    }
    Get-ScriptsRecursive $scriptFolder $groupContainer 0
}

# 9. HÀM AI (ĐÃ FIX CHỐNG ĐƠ BẰNG WPF DOEVENTS)
function Gui-AI {
    if ($Global:IsAiRunning -or [string]::IsNullOrWhiteSpace($txtInputAI.Text)) { return }
    $userT = $txtInputAI.Text; $txtInputAI.Clear(); $Global:IsAiRunning = $true; $btnSendAI.IsEnabled = $false
    
    $txtChatBox.AppendText("`n[BẠN]: $userT`n[AI]: Đang nghĩ...`n")
    $txtChatBox.ScrollToEnd()
    &$CapNhatGiaoDien
    
    $fileList = ""; foreach($p in $Global:DanhSachScript) { $fileList += "- $(Split-Path $p -Leaf)`n" }
    $sysP = "Bạn là trợ lý VietToolbox. Có danh sách script: $fileList. Nếu người dùng muốn làm gì đó, hãy xuất duy nhất [RUN:Tên_File.ps1]. Nếu không, hãy trả lời ngắn gọn."

    foreach ($m in $Global:ModelList) {
        try {
            $body = @{ model = $m; messages = @(@{role="system";content=$sysP}, @{role="user";content=$userT}) } | ConvertTo-Json -Compress
            $req = [System.Net.WebRequest]::Create("https://api.groq.com/openai/v1/chat/completions")
            $req.Method = "POST"; $req.ContentType = "application/json"; $req.Headers.Add("Authorization", "Bearer $Global:apiKey")
            $bytes = [Text.Encoding]::UTF8.GetBytes($body); $req.ContentLength = $bytes.Length
            $st = $req.GetRequestStream(); $st.Write($bytes, 0, $bytes.Length); $st.Close()
            
            $resp = $req.GetResponse(); $rd = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $aiT = ($rd.ReadToEnd() | ConvertFrom-Json).choices[0].message.content
            
            if ($aiT -match "\[RUN:(.*?)\]") {
                $f = $matches[1].Trim()
                $path = $Global:DanhSachScript | Where-Object { $_ -match [regex]::Escape($f) } | Select-Object -First 1
                if ($path) { 
                    $window.Dispatcher.Invoke([action]{ $txtChatBox.AppendText("[AI]: Chạy $f...`n") })
                    . $path
                    $aiT = "Đã thực hiện xong lệnh $f!" 
                }
            }
            $txtChatBox.AppendText("$aiT`n"); break
        } catch { if ($m -eq $Global:ModelList[-1]) { $txtChatBox.AppendText("LỖI KẾT NỐI API!`n") } }
    }
    $Global:IsAiRunning = $false; $btnSendAI.IsEnabled = $true; $txtChatBox.ScrollToEnd()
}

# 10. HÀM ĐỌC THÔNG TIN PHẦN CỨNG (WPF SAFE)
function Load-SysInfo {
    try {
        $txtSysInfo.Text = "Đang rà quét phần cứng..."
        &$CapNhatGiaoDien

        $osData = Get-WmiObject Win32_OperatingSystem
        $os = "$($osData.Caption) ($($osData.OSArchitecture))"
        $mbData = Get-WmiObject Win32_BaseBoard
        $mainboard = "$($mbData.Manufacturer) $($mbData.Product)"
        $cpuData = Get-WmiObject Win32_Processor | Select-Object -First 1
        $cpu = "$($cpuData.Name) ($($cpuData.NumberOfCores) Nhân / $($cpuData.NumberOfLogicalProcessors) Luồng)"

        $totalSlots = "Không rõ"
        try { $totalSlots = (Get-WmiObject Win32_PhysicalMemoryArray).MemoryDevices } catch {}
        $ramSticks = @(Get-WmiObject Win32_PhysicalMemory)
        $usedSlots = $ramSticks.Count
        $totalRam = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
        
        $ramDetails = ""
        foreach($stick in $ramSticks) {
            $stickGB = [math]::Round($stick.Capacity / 1GB, 1)
            $nsx = $stick.Manufacturer
            if ([string]::IsNullOrWhiteSpace($nsx) -or $nsx -match "0000" -or $nsx -match "Unknown") { $nsx = "Generic/Chưa rõ" }
            $ramDetails += "[$nsx - $stickGB GB - $($stick.Speed) MHz] "
        }

        $gpus = Get-WmiObject Win32_VideoController | ForEach-Object { $_.Name }
        $gpuStr = $gpus -join "`n           "

        $physicalDisks = Get-WmiObject Win32_DiskDrive | ForEach-Object { 
            $szReal = [math]::Round($_.Size / 1GB, 1) 
            $szAd = [math]::Round($_.Size / 1000000000) 
            if ($szAd -ge 118 -and $szAd -le 128) { $szAd = 120; if($szReal -gt 115) {$szAd = 128} }
            elseif ($szAd -ge 235 -and $szAd -le 256) { $szAd = 240; if($szReal -gt 235) {$szAd = 250}; if($szReal -gt 240) {$szAd = 256} }
            elseif ($szAd -ge 470 -and $szAd -le 512) { $szAd = 480; if($szReal -gt 460) {$szAd = 500}; if($szReal -gt 470) {$szAd = 512} }
            elseif ($szAd -ge 950 -and $szAd -le 1024) { $szAd = "1 TB" }
            else { $szAd = "$szAd GB" }
            "[$szAd Niêm yết | $szReal GB Thực tế] Hãng/Model: $($_.Model)" 
        }
        $pDiskStr = $physicalDisks -join "`n           "

        $logicalDisks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object { 
            "$($_.DeviceID) $([math]::Round($_.FreeSpace/1GB,1))GB Trống / $([math]::Round($_.Size/1GB,1))GB Tổng" 
        }
        $lDiskStr = $logicalDisks -join "`n           "
        $net = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=$true" | Select-Object -First 1
        $ip = if ($net) { $net.IPAddress[0] } else { "Không kết nối mạng" }

        $info = @"
=========================================================
          BÁO CÁO CẤU HÌNH MÁY TÍNH CHUYÊN SÂU
=========================================================

 💻 HĐH     : $os
 🛠️ MAIN     : $mainboard
 🧠 CPU     : $cpu
 
 🚀 RAM TỔNG : $totalRam GB 
 📊 CHI TIẾT : $ramDetails
 🔌 KHE CẮM  : Tổng $totalSlots khe | Đang cắm $usedSlots khe

 🎮 GPU     : 
           $gpuStr

 💿 Ổ VẬT LÝ : 
           $pDiskStr

 💾 PHÂN VÙNG: 
           $lDiskStr

 🌐 MẠNG (IP): $ip

=========================================================
"@
        $txtSysInfo.Text = $info
    } catch {
        $txtSysInfo.Text = "Lỗi khi đọc thông tin phần cứng hệ thống! $($_.Exception.Message)"
    }
}

# 11. SỰ KIỆN WPF (THAY THẾ WINDOWS FORMS MESSAGEBOX BẰNG WPF MESSAGEBOX)
$btnTopMin.Add_Click({ $window.WindowState = "Minimized" })
$btnTopClose.Add_Click({ $window.Close() })

$brushConverter = New-Object System.Windows.Media.BrushConverter
$btnColor.Add_Click({ 
    if ($Global:LogColorGreen) { 
        $txtLog.Foreground = $brushConverter.ConvertFromString("#FFFFFF")
        $Global:LogColorGreen = $false 
    } else { 
        $txtLog.Foreground = $brushConverter.ConvertFromString("#00FF00")
        $Global:LogColorGreen = $true 
    } 
})

$btnShutdown.Add_Click({ 
    $hoiDap = [System.Windows.MessageBox]::Show("Bạn có chắc chắn TẮT MÁY?", "VietToolbox", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($hoiDap -eq "Yes") { Stop-Computer -Force } 
})

$btnRestart.Add_Click({ 
    $hoiDap = [System.Windows.MessageBox]::Show("Bạn có chắc chắn RESTART?", "VietToolbox", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($hoiDap -eq "Yes") { Restart-Computer -Force } 
})

$btnSendAI.Add_Click({ Gui-AI })
$txtInputAI.Add_KeyDown({ if ($_.Key -eq "Enter") { Gui-AI } })

# Cho phép kéo thả cửa sổ bằng cách bấm giữ chuột ở bất cứ đâu trên nền
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# 12. KHỞI CHẠY (RENDER XONG MỚI LOAD DATA ĐỂ GIAO DIỆN HIỆN NHANH HƠN)
$window.Add_ContentRendered({
    Update-UI
    Load-SysInfo
})

$window.ShowDialog() | Out-Null