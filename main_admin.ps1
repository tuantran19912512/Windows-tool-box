# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO - ADMIN EDITION (V183)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Bản Admin - Có bảo mật Key khi mở thư mục nhạy cảm
# ==============================================================================

# 1. THIẾT LẬP MÔI TRƯỜNG & FIX LỖI CHẠY ONLINE (IEX)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if ($PSScriptRoot -eq "" -or $null -eq $PSScriptRoot) {
    $Global:CurrentPath = $pwd
} else {
    $Global:CurrentPath = $PSScriptRoot
}

$scriptFolder = Join-Path $Global:CurrentPath "Scripts"
$logoPath = Join-Path $Global:CurrentPath "logo2.png"

# 2. ẨN CỬA SỔ CONSOLE
$showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) { $showWindowAsync::ShowWindowAsync($hwnd, 0) | Out-Null }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# 3. YÊU CẦU QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 4. GIAO DIỆN XAML
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro - Admin Panel" Height="850" Width="1200" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" BorderBrush="#FFB300" BorderThickness="2">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#1A1305" Offset="0"/>
                <GradientStop Color="#0A0702" Offset="1"/>
            </LinearGradientBrush>
        </Border.Background>
        <Grid>
            <Grid VerticalAlignment="Top" Margin="30,30,30,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Image Grid.Column="0" Source="$logoPath" Height="140" Width="140" HorizontalAlignment="Left" Margin="0,0,30,0">
                    <Image.Effect><DropShadowEffect BlurRadius="20" Color="#FFB300" ShadowDepth="0" Opacity="0.8"/></Image.Effect>
                </Image>

                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="WINDOWS TOOL BOX PRO - ADMIN" Foreground="#FFB300" FontSize="36" FontWeight="Bold"/>
                    <TextBlock Text="Chế độ thợ máy chuyên nghiệp - Tuấn Kỹ Thuật Máy Tính" Foreground="#858585" FontSize="16" Margin="0,8,0,0"/>
                    
                    <TextBlock Name="TxtThongBao" Text="Đang bắt sóng Server..." Foreground="#00FF00" FontSize="15" FontWeight="Bold" Margin="0,10,0,0">
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
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="330"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <GroupBox Header="NHÓM CÔNG CỤ (FULL)" Foreground="#FFB300" BorderBrush="#333333">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel Name="GroupContainer" Margin="10"/>
                    </ScrollViewer>
                </GroupBox>

                <GroupBox Grid.Column="1" Header="NHẬT KÝ HỆ THỐNG" Foreground="#00FF00" BorderBrush="#333333" Margin="15,0,0,0">
                    <TextBox Name="TxtLog" Background="#050505" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" BorderThickness="0" Padding="15" Opacity="0.9"/>
                </GroupBox>
            </Grid>

            <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="25">
                <Button Name="BtnShutdown" Content="TẮT MÁY" Width="130" Height="45" Margin="0,0,10,0" Background="#D35400" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnRestart" Content="KHỞI ĐỘNG LẠI" Width="130" Height="45" Margin="0,0,10,0" Background="#2980B9" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnColor" Content="MÀU CHỮ" Width="110" Height="45" Margin="0,0,10,0" Background="#333337" Foreground="White" BorderThickness="1" BorderBrush="#FFB300" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnClose" Content="THOÁT ✕" Width="110" Height="45" Background="#CC1123" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# 5. KHỞI TẠO BIẾN
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $inputXML)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$groupContainer = $window.FindName("GroupContainer")
$txtLog = $window.FindName("TxtLog")
$btnClose = $window.FindName("BtnClose")
$btnColor = $window.FindName("BtnColor")
$btnShutdown = $window.FindName("BtnShutdown")
$btnRestart = $window.FindName("BtnRestart")
$txtThongBao = $window.FindName("TxtThongBao")

# 6. TẢI THÔNG BÁO (CACHE BUSTER)
try {
    $urlRaw = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/ThongBao.txt"
    $urlTurbo = $urlRaw + "?t=" + [DateTime]::Now.Ticks
    $rawText = Invoke-RestMethod -Uri $urlTurbo -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    $lines = $rawText -split "`n"
    $foundAdmin = ($lines | Where-Object { $_ -match "Admin:" }) -replace ".*Admin:\s*", ""
    if ($foundAdmin.Trim() -ne "") { $txtThongBao.Text = "🚨 ADMIN: " + $foundAdmin.Trim() } 
    else { $txtThongBao.Text = "🚨 HỆ THỐNG ADMIN ĐÃ SẴN SÀNG" }
} catch { $txtThongBao.Text = "🚨 ĐANG CHẠY CHẾ ĐỘ OFFLINE" }

# 7. HÀM HỆ THỐNG
$Global:LogColorGreen = $true

function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
        $txtLog.ScrollToEnd()
    })
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-UI {
    $null = $groupContainer.Children.Clear()
    if (!(Test-Path $scriptFolder)) { Ghi-Log "!!! CẢNH BÁO: Thư mục Scripts không tồn tại."; return }
    
    function Get-ScriptsRecursive ($Path, $ParentStack, $Level) {
        $items = Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                $subExpander = New-Object System.Windows.Controls.Expander
                $displayName = if ($item.Name -match "_") { $item.Name.Substring($item.Name.IndexOf('_') + 1).Replace('_',' ') } else { $item.Name }
                $subExpander.Header = $displayName
                $subExpander.Foreground = if ($Level -eq 0) { "#FFB300" } else { "#858585" } 
                $subExpander.FontWeight = "Bold"; $subExpander.FontSize = if ($Level -eq 0) { 16 } else { 14 }
                $subExpander.Margin = "0,5,0,5"; $subExpander.IsExpanded = $false 
                
                # --- CHÈN LẠI Ô NHẬP KEY CHO THƯ MỤC ADMIN ---
                if ($item.Name -like "*Admin*" -and $Level -eq 0) {
                    $subExpander.Add_Expanded({
                        param($sender, $e)
                        if (-not $Global:GH_TOKEN) {
                            $inputKey = [Microsoft.VisualBasic.Interaction]::InputBox("Vui lòng nhập Key xác thực Admin:", "Xác thực VietToolbox", "")
                            if ($inputKey -and $inputKey.Trim() -ne "") {
                                $Global:GH_TOKEN = $inputKey.Trim()
                                Ghi-Log ">>> Xác thực Admin thành công."
                            } else {
                                $sender.IsExpanded = $false
                                [System.Windows.Forms.MessageBox]::Show("Truy cập bị từ chối!", "Lỗi xác thực")
                            }
                        }
                    })
                }

                $subStack = New-Object System.Windows.Controls.StackPanel
                $subStack.Margin = "15,0,0,5" 
                Get-ScriptsRecursive $item.FullName $subStack ($Level + 1)
                $subExpander.Content = $subStack
                $null = $ParentStack.Children.Add($subExpander)
            } else {
                if ($item.Extension -eq ".ps1") {
                    $btn = New-Object System.Windows.Controls.Button
                    $cleanName = if ($item.BaseName -match "_") { $item.BaseName.Substring($item.BaseName.IndexOf('_') + 1).Replace('_',' ') } else { $item.BaseName }
                    $btn.Content = "● " + $cleanName; $btn.Height = 38; $btn.Margin = "0,2,0,2"
                    $btn.Background = "#2D2D30"; $btn.Foreground = "#DCDCDC"; $btn.Padding = "10,0,0,0"
                    $btn.HorizontalContentAlignment = "Left"; $btn.Tag = $item.FullName 
                    $btn.Add_Click({ 
                        param($sender, $e) 
                        $window.Dispatcher.Invoke([action]{ $txtLog.Clear() })
                        try { . $sender.Tag } catch { Ghi-Log "LỖI: $($_.Exception.Message)" } 
                    })
                    $null = $ParentStack.Children.Add($btn)
                }
            }
        }
    }
    Get-ScriptsRecursive $scriptFolder $groupContainer 0# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO - ADMIN EDITION (V183.8)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Fix lỗi đếm file (PS Array) + Chọn thư mục quét khi Tải Về
# ==============================================================================

# 1. THIẾT LẬP MÔI TRƯỜNG & THÔNG TIN GITHUB
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if ($PSScriptRoot -eq "" -or $null -eq $PSScriptRoot) { $Global:CurrentPath = $pwd } else { $Global:CurrentPath = $PSScriptRoot }
$scriptFolder = Join-Path $Global:CurrentPath "Scripts"
$logoPath = Join-Path $Global:CurrentPath "logo2.png"

# --- [BẢO MẬT] DÁN CHUỖI TOKEN MÃ HÓA VÀ MẬT KHẨU CỦA ÔNG VÀO ĐÂY ---
$EncGitHubToken = "drwAY0tiWvJb31vhT7EiXbLtG1Dur3m8HGySPTK+q1mugvsfmeFBNxFF83neiMPz"
$AdminPassword  = "Tuan@Admin123"

# --- [CẤU HÌNH GITHUB] ---
$Global:GHOwner  = "tuantran19912512"   
$Global:GHRepo   = "Windows-tool-box"   
$Global:GHBranch = "main"               

# 2. ẨN CỬA SỔ CONSOLE
$showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) { $showWindowAsync::ShowWindowAsync($hwnd, 0) | Out-Null }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

# 3. YÊU CẦU QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 4. GIAO DIỆN XAML 
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro - Admin Panel" Height="850" Width="1200" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" BorderBrush="#FFB300" BorderThickness="2">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#1A1305" Offset="0"/>
                <GradientStop Color="#0A0702" Offset="1"/>
            </LinearGradientBrush>
        </Border.Background>
        <Grid>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,15,20,0" Panel.ZIndex="999">
                <Button Name="BtnTopMin" Content=" 🗕 " Width="45" Height="30" Background="Transparent" Foreground="#858585" BorderThickness="0" FontSize="16" Cursor="Hand" ToolTip="Thu nhỏ"/>
                <Button Name="BtnTopClose" Content=" ✕ " Width="45" Height="30" Background="Transparent" Foreground="#858585" BorderThickness="0" FontSize="16" Cursor="Hand" ToolTip="Đóng"/>
            </StackPanel>

            <Grid VerticalAlignment="Top" Margin="30,30,30,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Image Grid.Column="0" Source="$logoPath" Height="140" Width="140" HorizontalAlignment="Left" Margin="0,0,30,0">
                    <Image.Effect><DropShadowEffect BlurRadius="20" Color="#FFB300" ShadowDepth="0" Opacity="0.8"/></Image.Effect>
                </Image>
                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="WINDOWS TOOL BOX PRO - ADMIN" Foreground="#FFB300" FontSize="36" FontWeight="Bold"/>
                    <TextBlock Text="Hệ thống quản trị chuyên nghiệp - Tuấn Kỹ Thuật Máy Tính" Foreground="#858585" FontSize="16" Margin="0,8,0,0"/>
                    <TextBlock Name="TxtThongBao" Text="Đang bắt sóng Server..." Foreground="#00FF00" FontSize="15" FontWeight="Bold" Margin="0,10,0,0">
                        <TextBlock.Triggers><EventTrigger RoutedEvent="TextBlock.Loaded"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="1.0" To="0.2" Duration="0:0:0.8" AutoReverse="True" RepeatBehavior="Forever"/></Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
                    </TextBlock>
                </StackPanel>
            </Grid>

            <Separator VerticalAlignment="Top" Background="#3E3E42" Margin="30,190,30,0" Opacity="0.5"/>

            <Grid Margin="20,210,20,85">
                <Grid.ColumnDefinitions><ColumnDefinition Width="350"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <GroupBox Header="NHÓM CÔNG CỤ (FULL)" Foreground="#FFB300" BorderBrush="#333333"><ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Name="GroupContainer" Margin="10"/></ScrollViewer></GroupBox>
                <GroupBox Grid.Column="1" Header="NHẬT KÝ HỆ THỐNG" Foreground="#00FF00" BorderBrush="#333333" Margin="15,0,0,0">
                    <TextBox Name="TxtLog" Background="#050505" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" BorderThickness="0" Padding="15" Opacity="0.9"/>
                </GroupBox>
            </Grid>

            <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="25">
                <Button Name="BtnSync" Content="☁️ ĐỒNG BỘ CLOUD" Width="150" Height="45" Margin="0,0,10,0" Background="#8E44AD" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnShutdown" Content="TẮT MÁY" Width="130" Height="45" Margin="0,0,10,0" Background="#D35400" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnRestart" Content="KHỞI ĐỘNG LẠI" Width="130" Height="45" Margin="0,0,10,0" Background="#2980B9" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnColor" Content="MÀU CHỮ" Width="110" Height="45" Margin="0,0,10,0" Background="#333337" Foreground="White" BorderThickness="1" BorderBrush="#FFB300" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# 5. KHỞI TẠO BIẾN UI
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $inputXML)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$groupContainer = $window.FindName("GroupContainer"); $txtLog = $window.FindName("TxtLog"); $btnColor = $window.FindName("BtnColor"); $btnShutdown = $window.FindName("BtnShutdown"); $btnRestart = $window.FindName("BtnRestart"); $btnSync = $window.FindName("BtnSync"); $txtThongBao = $window.FindName("TxtThongBao")
$btnTopMin = $window.FindName("BtnTopMin"); $btnTopClose = $window.FindName("BtnTopClose")
$brushConverter = New-Object System.Windows.Media.BrushConverter

# 6. HÀM GIẢI MÃ TOKEN NGẦM 
function Global:Unlock-Token {
    if ($Global:GH_TOKEN) { return $true }
    try {
        $S = [Text.Encoding]::UTF8.GetBytes("VietToolboxGH")
        $K = (New-Object Security.Cryptography.Rfc2898DeriveBytes $AdminPassword, $S, 1000).GetBytes(32)
        $I = (New-Object Security.Cryptography.Rfc2898DeriveBytes $AdminPassword, $S, 1000).GetBytes(16)
        $A = [Security.Cryptography.Aes]::Create(); $A.Key = $K; $A.IV = $I
        $D = $A.CreateDecryptor(); $EB = [Convert]::FromBase64String($EncGitHubToken)
        $DB = $D.TransformFinalBlock($EB, 0, $EB.Length)
        $Global:GH_TOKEN = [Text.Encoding]::UTF8.GetString($DB); $A.Dispose()
        return $true
    } catch { return $false }
}

# 7. HÀM LOG & UPDATE UI
$Global:LogColorGreen = $true
function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{ $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n"); $txtLog.ScrollToEnd() })
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-UI {
    $null = $groupContainer.Children.Clear()
    if (!(Test-Path $scriptFolder)) { Ghi-Log "!!! CẢNH BÁO: Thư mục Scripts không tồn tại."; return }
    function Get-ScriptsRecursive ($Path, $ParentStack, $Level) {
        Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name | foreach {
            if ($_.PSIsContainer) {
                $subExpander = New-Object System.Windows.Controls.Expander
                $displayName = if ($_.Name -match "_") { $_.Name.Substring($_.Name.IndexOf('_') + 1).Replace('_',' ') } else { $_.Name }
                $subExpander.Header = $displayName; $subExpander.Foreground = if ($Level -eq 0) { "#FFB300" } else { "#858585" } 
                $subExpander.FontWeight = "Bold"; $subExpander.FontSize = if ($Level -eq 0) { 16 } else { 14 }
                $subExpander.Margin = "0,5,0,5"; $subExpander.IsExpanded = $false 
                
                if ($_.Name -like "*Admin*" -and $Level -eq 0) {
                    $subExpander.Add_Expanded({
                        param($sender, $e)
                        if (Unlock-Token) { Ghi-Log ">>> [BẢO MẬT] Đã mở khóa mã hóa Token an toàn." }
                        else { $sender.IsExpanded = $false; [System.Windows.Forms.MessageBox]::Show("Giải mã Token thất bại!", "Lỗi", 0, 16) }
                    })
                }
                $subStack = New-Object System.Windows.Controls.StackPanel; $subStack.Margin = "15,0,0,5" 
                Get-ScriptsRecursive $_.FullName $subStack ($Level + 1)
                $subExpander.Content = $subStack; $null = $ParentStack.Children.Add($subExpander)
            } elseif ($_.Extension -eq ".ps1") {
                $btn = New-Object System.Windows.Controls.Button
                $cleanName = if ($_.BaseName -match "_") { $_.BaseName.Substring($_.BaseName.IndexOf('_') + 1).Replace('_',' ') } else { $_.BaseName }
                $btn.Content = "● " + $cleanName; $btn.Height = 38; $btn.Margin = "0,2,0,2"; $btn.FontSize = 14
                $btn.Background = "#2D2D30"; $btn.Foreground = "#DCDCDC"; $btn.Padding = "10,0,0,0"
                $btn.HorizontalContentAlignment = "Left"; $btn.Tag = $_.FullName 
                $btn.Add_Click({ param($sender, $e) $window.Dispatcher.Invoke([action]{ $txtLog.Clear() }); try { . $sender.Tag } catch { Ghi-Log "LỖI: $($_.Exception.Message)" } })
                $null = $ParentStack.Children.Add($btn)
            }
        }
    }
    Get-ScriptsRecursive $scriptFolder $groupContainer 0
}

# --- BÍ KÍP: API TẢI, ĐẨY VÀ KIỂM TRA FILE GITHUB ---
function Global:Tai-File-Private ($RawUrl, $SavePath) {
    try {
        $headers = @{ "Authorization" = "token $($Global:GH_TOKEN)" }
        Invoke-RestMethod -Uri $RawUrl -Headers $headers -OutFile $SavePath -UseBasicParsing
        return $true
    } catch { return $false }
}

function Global:Day-File-Private ($LocalFilePath, $GitHubPath) {
    try {
        $apiUri = "https://api.github.com/repos/$Global:GHOwner/$Global:GHRepo/contents/$GitHubPath"
        $headers = @{ "Authorization" = "token $($Global:GH_TOKEN)"; "Accept" = "application/vnd.github.v3+json" }
        $sha = $null
        try { $existingFile = Invoke-RestMethod -Uri $apiUri -Headers $headers -Method Get -ErrorAction Stop; $sha = $existingFile.sha } catch {}
        
        $fileBytes = [System.IO.File]::ReadAllBytes($LocalFilePath)
        $base64Content = [Convert]::ToBase64String($fileBytes)
        
        $bodyData = @{ message = "VietToolbox: Upload $(Split-Path $LocalFilePath -Leaf)"; content = $base64Content; branch = $Global:GHBranch }
        if ($null -ne $sha) { $bodyData.Add("sha", $sha) }
        
        $jsonBody = $bodyData | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $apiUri -Headers $headers -Method Put -Body $jsonBody -ContentType "application/json" | Out-Null
        return $true
    } catch { return $false }
}

function Global:Kiem-Tra-Cap-Nhat {
    if (-not (Unlock-Token)) { $window.Dispatcher.Invoke([action]{ $txtThongBao.Text = "🚨 ĐANG CHẠY CHẾ ĐỘ OFFLINE" }); return }
    try {
        $apiUri = "https://api.github.com/repos/$Global:GHOwner/$Global:GHRepo/contents/Scripts"
        $headers = @{ "Authorization" = "token $($Global:GH_TOKEN)"; "Accept" = "application/vnd.github.v3+json" }
        $cloudFiles = Invoke-RestMethod -Uri $apiUri -Headers $headers -Method Get -ErrorAction Stop
        
        # [FIX] Thêm @() để bọc lại, tránh lỗi đếm khi chỉ có 1 file
        $cloudPs1 = @($cloudFiles | Where-Object { $_.type -eq "file" -and $_.name -like "*.ps1" } | Select-Object -ExpandProperty name)
        
        $localPs1 = @()
        if (Test-Path $scriptFolder) { $localPs1 = Get-ChildItem -Path $scriptFolder -Filter "*.ps1" | Select-Object -ExpandProperty Name }

        $newFilesCount = 0; foreach ($cFile in $cloudPs1) { if ($localPs1 -notcontains $cFile) { $newFilesCount++ } }

        $window.Dispatcher.Invoke([action]{
            if ($newFilesCount -gt 0) {
                $txtThongBao.Text = "⚠️ CÓ $newFilesCount SCRIPT MỚI TRÊN CLOUD! HÃY ĐỒNG BỘ!"
                $txtThongBao.Foreground = $brushConverter.ConvertFromString("#FFFF00") 
            } else {
                $txtThongBao.Text = "✅ HỆ THỐNG ĐÃ CẬP NHẬT MỚI NHẤT"
                $txtThongBao.Foreground = $brushConverter.ConvertFromString("#00FF00") 
            }
        })
    } catch { $window.Dispatcher.Invoke([action]{ $txtThongBao.Text = "🚨 KHÔNG THỂ KIỂM TRA MẠNG (HOẶC CHƯA TẠO FOLDER SCRIPTS)" }) }
}

# 8. SỰ KIỆN NÚT BẤM
$btnTopMin.Add_Click({ $window.WindowState = "Minimized" })
$btnTopClose.Add_Click({ $window.Close() })
$btnColor.Add_Click({
    if ($Global:LogColorGreen) { $txtLog.Foreground = $brushConverter.ConvertFromString("#FFFFFF"); $btnColor.Content = "MÀU CHỮ: TRẮNG"; $Global:LogColorGreen = $false } 
    else { $txtLog.Foreground = $brushConverter.ConvertFromString("#00FF00"); $btnColor.Content = "MÀU CHỮ: XANH"; $Global:LogColorGreen = $true }
})
$btnShutdown.Add_Click({ if ([System.Windows.Forms.MessageBox]::Show("Tắt máy?", "VietToolbox", 4, 48) -eq "Yes") { Stop-Computer -Force } })
$btnRestart.Add_Click({ if ([System.Windows.Forms.MessageBox]::Show("Khởi động lại?", "VietToolbox", 4, 32) -eq "Yes") { Restart-Computer -Force } })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# --- XỬ LÝ NÚT ĐỒNG BỘ 2 CHIỀU (GIAO DIỆN CHỌN FILE) ---
$btnSync.Add_Click({
    if (-not (Unlock-Token)) { [System.Windows.Forms.MessageBox]::Show("Lỗi giải mã Token. Từ chối kết nối Cloud!", "Bảo mật", 0, 16); return }

    $chon = [System.Windows.Forms.MessageBox]::Show("Bạn muốn làm gì?`n`n[YES] - TẢI VỀ (Từ Cloud -> Máy)`n[NO] - ĐẨY LÊN (Từ Máy -> Cloud)", "Đồng Bộ Cloud 2 Chiều", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($chon -eq "Yes") {
        # [FIX] Hỏi ông muốn quét thư mục nào trên Cloud
        $gitFolder = [Microsoft.VisualBasic.Interaction]::InputBox("Bạn muốn TẢI VỀ từ thư mục nào trên Cloud?`n(Mặc định là 'Scripts'. Nếu ông lưu ở ngoài cùng thì XÓA TRẮNG ô này đi)", "Thư mục Cloud", "Scripts")
        if ($gitFolder -eq $null) { return } # Hủy bỏ
        
        $gitFolder = $gitFolder.Trim('/')
        $apiUri = if ($gitFolder -eq "") { "https://api.github.com/repos/$Global:GHOwner/$Global:GHRepo/contents" } 
                  else { "https://api.github.com/repos/$Global:GHOwner/$Global:GHRepo/contents/$gitFolder" }

        Ghi-Log "🔍 Đang lấy danh sách Script từ Cloud ($gitFolder)..."
        $headers = @{ "Authorization" = "token $($Global:GH_TOKEN)"; "Accept" = "application/vnd.github.v3+json" }
        try {
            $cloudFiles = Invoke-RestMethod -Uri $apiUri -Headers $headers -Method Get -ErrorAction Stop
            # [FIX] Thêm @() để bọc kết quả lại
            $cloudPs1 = @($cloudFiles | Where-Object { $_.type -eq "file" -and $_.name -like "*.ps1" } | Select-Object -ExpandProperty name)
        } catch { 
            Ghi-Log "❌ Không thể kết nối hoặc không tồn tại thư mục '$gitFolder'!"
            [System.Windows.Forms.MessageBox]::Show("Không tìm thấy thư mục này trên Cloud! (Hoặc Repo trống)", "Lỗi", 0, 16)
            return 
        }

        if ($cloudPs1.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Không có Script nào ở đây để tải về!", "Trống", 0, 64); return }

        # TẠO GIAO DIỆN CHỌN SCRIPT TẢI VỀ
        $dlForm = New-Object System.Windows.Forms.Form
        $dlForm.Text = "☁️ Danh sách Script trên Cloud"
        $dlForm.Size = "400,500"; $dlForm.StartPosition = "CenterScreen"; $dlForm.FormBorderStyle = "FixedDialog"; $dlForm.MaximizeBox = $false
        
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "Tick chọn các file muốn tải về máy:"; $lbl.AutoSize = $true; $lbl.Location = "10,10"
        
        $clb = New-Object System.Windows.Forms.CheckedListBox
        $clb.Location = "10,35"; $clb.Size = "360,370"; $clb.CheckOnClick = $true
        foreach ($file in $cloudPs1) { $null = $clb.Items.Add($file) }

        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "TẢI VỀ"; $btnOK.Location = "140,415"; $btnOK.Size = "100,35"
        $btnOK.BackColor = "#007ACC"; $btnOK.ForeColor = "White"; $btnOK.FlatStyle = "Flat"; $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK

        $dlForm.Controls.AddRange(@($lbl, $clb, $btnOK)); $dlForm.AcceptButton = $btnOK

        if ($dlForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $downloadCount = 0
            foreach ($checkedItem in $clb.CheckedItems) {
                $rawUrl = if ($gitFolder -eq "") { "https://raw.githubusercontent.com/$Global:GHOwner/$Global:GHRepo/$Global:GHBranch/$checkedItem" }
                          else { "https://raw.githubusercontent.com/$Global:GHOwner/$Global:GHRepo/$Global:GHBranch/$gitFolder/$checkedItem" }
                
                $saveDest = Join-Path $scriptFolder $checkedItem
                Ghi-Log "☁️ Đang kéo: $checkedItem ..."
                if (Tai-File-Private -RawUrl $rawUrl -SavePath $saveDest) { Ghi-Log "✅ Thành công: $checkedItem"; $downloadCount++ }
            }
            if ($downloadCount -gt 0) { Update-UI; Kiem-Tra-Cap-Nhat; Ghi-Log "🎉 Hoàn tất tải $downloadCount file!" }
        }
        
    } elseif ($chon -eq "No") {
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.InitialDirectory = $scriptFolder; $openFileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
        $openFileDialog.Title = "Chọn các file để đẩy (Upload) lên Cloud"; $openFileDialog.Multiselect = $true 
        
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $filesToUpload = $openFileDialog.FileNames
            $gitFolder = [Microsoft.VisualBasic.Interaction]::InputBox("Lưu vào thư mục nào trên Cloud?`n(Xóa trắng nếu muốn lưu thẳng ngoài Root)", "Đẩy Lô File (PUSH)", "Scripts")
            if ($gitFolder -eq $null) { return }
            
            $gitFolder = $gitFolder.Trim('/'); $thanhCongCount = 0
            foreach ($localFile in $filesToUpload) {
                $fileName = Split-Path $localFile -Leaf
                $gitPath = if ($gitFolder -eq "") { $fileName } else { "$gitFolder/$fileName" }
                Ghi-Log "🚀 Đang đẩy: $fileName ..."
                if (Day-File-Private -LocalFilePath $localFile -GitHubPath $gitPath) { Ghi-Log "✅ Đã lên mây: $fileName"; $thanhCongCount++ }
            }
            Ghi-Log "🎉 Hoàn tất đẩy $thanhCongCount / $($filesToUpload.Count) file lên mây!"
            Kiem-Tra-Cap-Nhat
        }
    }
})

# 10. KHỞI CHẠY GIAO DIỆN & CHECK UPDATE
Update-UI
$window.Dispatcher.InvokeAsync([action]{ Kiem-Tra-Cap-Nhat }) | Out-Null
$window.ShowDialog() | Out-Null
}

# 8. SỰ KIỆN NÚT BẤM
$btnColor.Add_Click({
    if ($Global:LogColorGreen) { $txtLog.Foreground = "#FFFFFF"; $btnColor.Content = "MÀU CHỮ: TRẮNG"; $Global:LogColorGreen = $false } 
    else { $txtLog.Foreground = "#00FF00"; $btnColor.Content = "MÀU CHỮ: XANH"; $Global:LogColorGreen = $true }
})
$btnShutdown.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Tắt máy?", "VietToolbox", 4, 48) -eq "Yes") { Stop-Computer -Force }
})
$btnRestart.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Khởi động lại?", "VietToolbox", 4, 32) -eq "Yes") { Restart-Computer -Force }
})
$btnClose.Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# 9. KHỞI CHẠY
Update-UI
$window.ShowDialog() | Out-Null