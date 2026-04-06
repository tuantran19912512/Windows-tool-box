# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO - BẢNG ĐIỀU KHIỂN (V182.24 - ULTRA LITE)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc trị: Giao diện Modern Dark tối giản, Bỏ hoàn toàn SysInfo, Tốc độ bàn thờ
# ==============================================================================

# 1. THIẾT LẬP MÔI TRƯỜNG
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

if ($PSScriptRoot -eq "" -or $null -eq $PSScriptRoot) { $Global:CurrentPath = $pwd } else { $Global:CurrentPath = $PSScriptRoot }
$scriptFolder = Join-Path $Global:CurrentPath "Scripts"
$logoPath = Join-Path $Global:CurrentPath "logo2.png"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$screenWidth = [System.Windows.SystemParameters]::WorkArea.Width
$screenHeight = [System.Windows.SystemParameters]::WorkArea.Height
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

# 4. GIAO DIỆN XAML MỚI (PHẲNG, HIỆN ĐẠI, KHÔNG RƯỜM RÀ)
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Width="$winW" Height="$winH" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    
    <Window.Resources>
        <Style x:Key="ScriptButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#0F172A"/>
            <Setter Property="Foreground" Value="#CBD5E1"/>
            <Setter Property="Height" Value="35"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Padding" Value="10,0,0,0"/>
            <Setter Property="Margin" Value="0,2,0,2"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="BgBorder" Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BgBorder" Property="Background" Value="#1E293B"/> <Setter Property="Foreground" Value="#38BDF8"/> </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BgBorder" Property="Background" Value="#334155"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Viewbox Stretch="Uniform">
        <Border Width="1200" Height="850" CornerRadius="15" BorderBrush="#1E293B" BorderThickness="1" Background="#0F172A">
            <Grid>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,15,20,0" Panel.ZIndex="999">
                    <TextBlock Name="TxtClock" Text="00:00:00" Foreground="#64748B" FontSize="14" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,20,0"/>
                    <Button Name="BtnTopMin" Content="—" Width="40" Height="30" Background="Transparent" Foreground="#94A3B8" BorderThickness="0" FontSize="14" Cursor="Hand" FontWeight="Bold" ToolTip="Thu nhỏ"/>
                    <Button Name="BtnTopClose" Content="✕" Width="40" Height="30" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="14" Cursor="Hand" FontWeight="Bold" ToolTip="Đóng"/>
                </StackPanel>

                <Grid VerticalAlignment="Top" Margin="30,30,30,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    
                    <Border Grid.Column="0" Width="100" Height="100" CornerRadius="12" Background="#1E293B" Margin="0,0,25,0" Padding="10" BorderBrush="#334155" BorderThickness="1">
                        <Image Source="$logoPath" Stretch="Uniform">
                            <Image.Effect><DropShadowEffect BlurRadius="15" Color="#3B82F6" ShadowDepth="0" Opacity="0.5"/></Image.Effect>
                        </Image>
                    </Border>
                    
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="CÔNG CỤ HỖ TRỢ KỸ THUẬT ONLINE" Foreground="#F8FAFC" FontSize="34" FontWeight="Bold"/>
                        <TextBlock Text="Hệ thống quản trị chuyên nghiệp - Tuấn Kỹ Thuật Máy Tính" Foreground="#94A3B8" FontSize="15" Margin="0,5,0,0"/>
                        <TextBlock Name="TxtThongBao" Text="Đang kiểm tra cập nhật..." Foreground="#10B981" FontSize="14" FontWeight="SemiBold" Margin="0,10,0,0">
                            <TextBlock.Triggers>
                                <EventTrigger RoutedEvent="TextBlock.Loaded">
                                    <BeginStoryboard>
                                        <Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="1.0" To="0.4" Duration="0:0:1.2" AutoReverse="True" RepeatBehavior="Forever"/></Storyboard>
                                    </BeginStoryboard>
                                </EventTrigger>
                            </TextBlock.Triggers>
                        </TextBlock>
                    </StackPanel>
                </Grid>

                <Separator VerticalAlignment="Top" Background="#1E293B" Margin="30,160,30,0" Height="2" BorderThickness="0"/>
                
                <Grid Margin="30,190,30,90">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="320"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    
                    <Border Grid.Column="0" Background="#1E293B" CornerRadius="12" BorderBrush="#334155" BorderThickness="1" Padding="15">
                        <StackPanel>
                            <TextBlock Text="🗂️ DANH MỤC CÔNG CỤ" Foreground="#38BDF8" FontWeight="Bold" FontSize="16" Margin="5,0,0,15"/>
                            <ScrollViewer VerticalScrollBarVisibility="Auto" Height="480">
                                <StackPanel Name="GroupContainer" Margin="0,0,10,0"/>
                            </ScrollViewer>
                        </StackPanel>
                    </Border>
                    
                    <Border Grid.Column="1" Background="#1E293B" CornerRadius="12" BorderBrush="#334155" BorderThickness="1" Margin="20,0,0,0" Padding="15">
                        <TabControl Name="MainTabControl" Background="Transparent" BorderThickness="0">
                            <TabControl.Resources>
                                <Style TargetType="TabItem">
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="TabItem">
                                                <Border Name="Border" Padding="20,10" Margin="0,0,10,10" CornerRadius="8" Background="#0F172A" BorderThickness="1" BorderBrush="#334155" Cursor="Hand">
                                                    <ContentPresenter x:Name="ContentSite" VerticalAlignment="Center" HorizontalAlignment="Center" ContentSource="Header"/>
                                                </Border>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsSelected" Value="True">
                                                        <Setter TargetName="Border" Property="Background" Value="#3B82F6"/>
                                                        <Setter TargetName="Border" Property="BorderBrush" Value="#3B82F6"/>
                                                        <Setter Property="Foreground" Value="White"/>
                                                    </Trigger>
                                                    <Trigger Property="IsSelected" Value="False">
                                                        <Setter Property="Foreground" Value="#94A3B8"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </TabControl.Resources>

                            <TabItem Header="📋 NHẬT KÝ HỆ THỐNG" FontWeight="Bold" FontSize="14">
                                <Border Background="#0B1120" CornerRadius="8" Padding="15" BorderBrush="#334155" BorderThickness="1">
                                    <TextBox Name="TxtLog" Background="Transparent" Foreground="#10B981" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
                                </Border>
                            </TabItem>
                            
                            <TabItem Header="✨ TRỢ LÝ AI (AUTO RUN)" FontWeight="Bold" FontSize="14">
                                <Grid>
                                    <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Border Grid.Row="0" Background="#0B1120" CornerRadius="8" Padding="15" BorderBrush="#334155" BorderThickness="1" Margin="0,0,0,15">
                                        <TextBox Name="TxtChatBox" Background="Transparent" Foreground="#E2E8F0" FontSize="14" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
                                    </Border>
                                    <Grid Grid.Row="1">
                                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="120"/></Grid.ColumnDefinitions>
                                        <TextBox Name="TxtInputAI" Grid.Column="0" Height="45" Background="#1E293B" Foreground="White" BorderBrush="#334155" VerticalContentAlignment="Center" Padding="15,0" FontSize="14">
                                            <TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></TextBox.Resources>
                                        </TextBox>
                                        <Button Name="BtnSendAI" Grid.Column="1" Content="🚀 GỬI LỆNH" Margin="10,0,0,0" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="14" Cursor="Hand">
                                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                                        </Button>
                                    </Grid>
                                </Grid>
                            </TabItem>
                        </TabControl>
                    </Border>
                </Grid>

                <Border VerticalAlignment="Bottom" Background="#1E293B" Height="70" CornerRadius="0,0,15,15" BorderBrush="#334155" BorderThickness="0,1,0,0">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,30,0">
                        <Button Name="BtnClearLog" Content="🧹 XOÁ NHẬT KÝ" Width="140" Height="40" Margin="0,0,15,0" Background="#475569" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                        <Button Name="BtnColor" Content="🎨 MÀU CHỮ LOG" Width="140" Height="40" Margin="0,0,15,0" Background="#334155" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                        <Button Name="BtnRestart" Content="🔄 KHỞI ĐỘNG LẠI" Width="140" Height="40" Margin="0,0,15,0" Background="#0288D1" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                        <Button Name="BtnShutdown" Content="⏻ TẮT MÁY" Width="120" Height="40" Background="#EF4444" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                    </StackPanel>
                </Border>
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
$btnClearLog = $window.FindName("BtnClearLog")
$btnShutdown = $window.FindName("BtnShutdown")
$btnRestart = $window.FindName("BtnRestart")
$txtThongBao = $window.FindName("TxtThongBao")
$txtChatBox = $window.FindName("TxtChatBox")
$txtInputAI = $window.FindName("TxtInputAI")
$btnSendAI = $window.FindName("BtnSendAI")
$btnTopMin = $window.FindName("BtnTopMin")
$btnTopClose = $window.FindName("BtnTopClose")
$txtClock = $window.FindName("TxtClock")

$CapNhatGiaoDien = {
    $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

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
    $txtThongBao.Text = if ($foundKhach.Trim() -ne "") { "🔥 " + $foundKhach.Trim() } else { "🔥 VietToolbox Pro - Sẵn sàng phục vụ!" }
} catch { $txtThongBao.Text = "🔥 VietToolbox Pro - Hệ thống ổn định!" }

# 7. HÀM LOG
$Global:LogColorGreen = $true
function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{ 
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
        $txtLog.ScrollToEnd() 
    })
    &$CapNhatGiaoDien
}

# 8. CẬP NHẬT DANH SÁCH SCRIPTS
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
                $subExp.Header = "📁 " + $_.Name
                $subExp.Foreground = if ($Level -eq 0) { "#F8FAFC" } else { "#94A3B8" } 
                $subExp.FontWeight = "Bold"; $subExp.FontSize = 14; $subExp.Margin = "0,5,0,5"
                $subStack = New-Object System.Windows.Controls.StackPanel; $subStack.Margin = "25,5,0,5"
                Get-ScriptsRecursive $_.FullName $subStack ($Level + 1)
                $subExp.Content = $subStack
                $null = $ParentStack.Children.Add($subExp)
            } else {
                if ($_.Extension -eq ".ps1") {
                    if ($Global:DanhSachScript -notcontains $_.FullName) { $Global:DanhSachScript += $_.FullName }
                    
                    $btn = New-Object System.Windows.Controls.Button
                    $btn.Content = "⚡ " + $_.BaseName 
                    $btn.Tag = $_.FullName
                    
                    # Áp dụng Style đã định nghĩa trong XAML để xử lý lỗi rê chuột trắng xóa
                    $btn.Style = $window.Resources["ScriptButtonStyle"]
                    
                    $btn.Add_Click({ 
                        param($sender, $e) 
                        $window.Dispatcher.Invoke([action]{ 
                            $mainTabControl.SelectedIndex = 0 
                            $txtLog.Clear() 
                            $mainTabControl.Focus() | Out-Null
                            Ghi-Log "▶ ĐANG KHỞI CHẠY: $($sender.Content -replace '⚡ ', '')"
                        })
                        &$CapNhatGiaoDien
                        try { . $sender.Tag } catch { Ghi-Log "❌ LỖI KHỞI CHẠY: $($_.Exception.Message)" } 
                    })
                    $null = $ParentStack.Children.Add($btn)
                }
            }
        }
    }
    Get-ScriptsRecursive $scriptFolder $groupContainer 0
}

# 9. HÀM AI
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

# 10. SỰ KIỆN NÚT BẤM (WPF)
$btnTopMin.Add_Click({ $window.WindowState = "Minimized" })
$btnTopClose.Add_Click({ $window.Close() })

$btnClearLog.Add_Click({ $txtLog.Clear(); Ghi-Log "🧹 Đã xóa sạch nhật ký." })

$brushConverter = New-Object System.Windows.Media.BrushConverter
$btnColor.Add_Click({ 
    if ($Global:LogColorGreen) { 
        $txtLog.Foreground = $brushConverter.ConvertFromString("#F8FAFC")
        $Global:LogColorGreen = $false 
    } else { 
        $txtLog.Foreground = $brushConverter.ConvertFromString("#10B981")
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
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# 11. KHỞI CHẠY
$window.Add_ContentRendered({
    Update-UI
    Ghi-Log "Hệ thống đã sẵn sàng hoạt động!"
})

$window.ShowDialog() | Out-Null