# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO - AI AGENT EDITION (V194.0)
# Tác giả: Tuấn Kỹ Thuật Máy Tính & Gemini 3.1 Pro
# Ghi chú: CƠ CHẾ BẢO MẬT API KEY KÉP ĐỂ AN TOÀN TUYỆT ĐỐI KHI UP LÊN GITHUB
# ==============================================================================

# 1. THIẾT LẬP MÔI TRƯỜNG & BẢO MẬT MẠNG
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 3072
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# KHÓA CỨNG ĐƯỜNG DẪN THƯ MỤC GỐC
$scriptPath = ""
if ($MyInvocation.MyCommand.Path) { $scriptPath = $MyInvocation.MyCommand.Path }
elseif ($PSCommandPath) { $scriptPath = $PSCommandPath }

if ($scriptPath) {
    $Global:CurrentPath = Split-Path $scriptPath -Parent
} else {
    $Global:CurrentPath = $pwd.Path
}

$scriptFolder = Join-Path $Global:CurrentPath "Scripts"
$logoPath = Join-Path $Global:CurrentPath "logo2.png"
$keyFile = Join-Path $Global:CurrentPath "apikey.txt"

# --- CƠ CHẾ BẢO MẬT KEY KÉP (CHỐNG LỘ TRÊN GITHUB) ---
# Dòng này để làm cảnh báo cho người tải source code trên GitHub
$Global:apiKey = "gsk_NHAP_MA_GROQ_CUA_BAN_VAO_DAY"

# Ưu tiên đọc Key thật từ file apikey.txt (File này đã bị .gitignore chặn, rất an toàn)
if (Test-Path $keyFile) {
    $Global:apiKey = (Get-Content -Path $keyFile -Raw).Trim()
}

# DANH SÁCH AI DỰ PHÒNG CỦA GROQ
$Global:ModelList = @(
    "llama-3.3-70b-versatile",
    "llama3-8b-8192",
    "mixtral-8x7b-32768",
    "gemma2-9b-it"
)
$Global:IsAiRunning = $false

# 2. ẨN CỬA SỔ CONSOLE
$showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) { $showWindowAsync::ShowWindowAsync($hwnd, 0) | Out-Null }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# 3. TỰ ĐỘNG YÊU CẦU QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# 4. GIAO DIỆN XAML TỐI GIẢN
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Height="850" Width="1200" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" BorderBrush="#007ACC" BorderThickness="2">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#0A1628" Offset="0"/>
                <GradientStop Color="#02050A" Offset="1"/>
            </LinearGradientBrush>
        </Border.Background>
        <Grid>
            <Grid VerticalAlignment="Top" Margin="30,30,30,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
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
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="330"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <GroupBox Header="NHÓM CÔNG CỤ" Foreground="#007ACC" BorderBrush="#333333">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel Name="GroupContainer" Margin="10"/>
                    </ScrollViewer>
                </GroupBox>
                <GroupBox Grid.Column="1" Header="BẢNG ĐIỀU KHIỂN" Foreground="#00FF00" BorderBrush="#333333" Margin="15,0,0,0">
                    <TabControl Background="Transparent" BorderThickness="0">
                        <TabItem Header=" NHẬT KÝ HỆ THỐNG " Foreground="#00FF00">
                             <TextBox Name="TxtLog" Background="#050505" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" BorderThickness="0" Padding="15" Opacity="0.9"/>
                        </TabItem>
                        <TabItem Header=" TRỢ LÝ AI THÔNG MINH " Foreground="#007ACC">
                            <Grid Margin="10">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <TextBox Name="TxtChatBox" Grid.Row="0" Background="#0A101A" Foreground="#DCDCDC" FontSize="14" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderBrush="#333333" Padding="10"/>
                                
                                <Grid Grid.Row="1" Margin="0,10,0,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="100"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBox Name="TxtInputAI" Grid.Column="0" Height="35" Background="#1A1A1A" Foreground="White" BorderBrush="#007ACC" VerticalContentAlignment="Center" Padding="10,0" />
                                    <Button Name="BtnSendAI" Grid.Column="1" Content="GỬI" Margin="10,0,0,0" Background="#007ACC" Foreground="White" FontWeight="Bold">
                                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                                    </Button>
                                </Grid>
                            </Grid>
                        </TabItem>
                    </TabControl>
                </GroupBox>
            </Grid>

            <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="25">
                <Button Name="BtnMin" Content="THU NHỎ" Width="110" Height="45" Margin="0,0,10,0" Background="#1F3A5F" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnShutdown" Content="TẮT MÁY" Width="130" Height="45" Margin="0,0,10,0" Background="#D35400" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnRestart" Content="KHỞI ĐỘNG LẠI" Width="130" Height="45" Margin="0,0,10,0" Background="#2980B9" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
                <Button Name="BtnColor" Content="MÀU CHỮ" Width="110" Height="45" Margin="0,0,10,0" Background="#333337" Foreground="White" BorderThickness="1" BorderBrush="#007ACC" FontWeight="Bold">
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

# 5. KHỞI TẠO GIAO DIỆN
$stringReader = New-Object System.IO.StringReader($inputXML)
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [Windows.Markup.XamlReader]::Load($xmlReader)

$groupContainer = $window.FindName("GroupContainer")
$txtLog = $window.FindName("TxtLog")
$btnClose = $window.FindName("BtnClose")
$btnColor = $window.FindName("BtnColor")
$btnMin = $window.FindName("BtnMin")
$btnShutdown = $window.FindName("BtnShutdown")
$btnRestart = $window.FindName("BtnRestart")
$txtThongBao = $window.FindName("TxtThongBao")
$txtChatBox = $window.FindName("TxtChatBox")
$txtInputAI = $window.FindName("TxtInputAI")
$btnSendAI = $window.FindName("BtnSendAI")

# 6. TẢI THÔNG BÁO TỪ GITHUB
try {
    $urlRaw = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/ThongBao.txt"
    $urlTurbo = $urlRaw + "?t=" + [DateTime]::Now.Ticks
    $rawText = Invoke-RestMethod -Uri $urlTurbo -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    $lines = $rawText -split "`n"
    $foundKhach = ($lines | Where-Object { $_ -match "Khách:" }) -replace ".*Khách:\s*", ""
    if ($foundKhach.Trim() -ne "") { $txtThongBao.Text = "🔥 " + $foundKhach.Trim() } 
    else { $txtThongBao.Text = "🔥 VietToolbox Pro - Hệ thống ổn định!" }
} catch { $txtThongBao.Text = "🔥 VietToolbox Pro - Hệ thống ổn định!" }

# 7. HÀM LOG
$Global:LogColorGreen = $true
function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
        $txtLog.ScrollToEnd()
    })
    [System.Windows.Forms.Application]::DoEvents()
}

# 8. CẬP NHẬT DANH SÁCH SCRIPTS & LƯU LẠI VÀO BIẾN ĐỂ BÁO CHO AI
$Global:DanhSachScript = @()
function Update-UI {
    $null = $groupContainer.Children.Clear()
    $Global:DanhSachScript = @()
    if (!(Test-Path $scriptFolder)) { return }
    
    function Get-ScriptsRecursive ($Path, $ParentStack, $Level) {
        $items = Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name
        foreach ($item in $items) {
            if ($item.Name -match "Admin") { continue }
            if ($item.PSIsContainer) {
                $subExpander = New-Object System.Windows.Controls.Expander
                $displayName = if ($item.Name -match "_") { $item.Name.Substring($item.Name.IndexOf('_') + 1).Replace('_',' ') } else { $item.Name }
                $subExpander.Header = $displayName
                $subExpander.Foreground = if ($Level -eq 0) { "#007ACC" } else { "#858585" } 
                $subExpander.FontWeight = "Bold"; $subExpander.FontSize = if ($Level -eq 0) { 16 } else { 14 }
                $subExpander.Margin = "0,5,0,5"; $subExpander.IsExpanded = $false 
                $subStack = New-Object System.Windows.Controls.StackPanel
                $subStack.Margin = "15,0,0,5" 
                Get-ScriptsRecursive $item.FullName $subStack ($Level + 1)
                $subExpander.Content = $subStack
                $null = $ParentStack.Children.Add($subExpander)
            } else {
                if ($item.Extension -eq ".ps1") {
                    $Global:DanhSachScript += $item.FullName
                    
                    $btn = New-Object System.Windows.Controls.Button
                    $cleanName = if ($item.BaseName -match "_") { $item.BaseName.Substring($item.BaseName.IndexOf('_') + 1).Replace('_',' ') } else { $item.BaseName }
                    $btn.Content = "● " + $cleanName; $btn.Height = 38; $btn.Margin = "0,2,0,2"
                    $btn.Background = "#2D2D2D"; $btn.Foreground = "#DCDCDC"; $btn.Padding = "10,0,0,0"
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
    Get-ScriptsRecursive $scriptFolder $groupContainer 0
}

# 9. LOGIC XỬ LÝ CHAT AI (TÍCH HỢP NÃO BỘ AI AGENT ĐỂ TỰ CHẠY SCRIPT)
function Gui-Tin-Nhan-AI {
    if ($Global:IsAiRunning) { return }
    $userText = $txtInputAI.Text
    if ([string]::IsNullOrWhiteSpace($userText)) { return }
    
    $cleanKey = $Global:apiKey -replace '\s+', ''
    if ([string]::IsNullOrEmpty($cleanKey) -or $cleanKey -eq "gsk_NHAP_MA_GROQ_CUA_BAN_VAO_DAY") {
        $window.Dispatcher.Invoke([action]{
            $txtChatBox.AppendText("`n[HỆ THỐNG]: LỖI! Hệ thống không tìm thấy API Key. Hãy đảm bảo bạn đã cấu hình đúng.`n")
            $txtChatBox.ScrollToEnd()
        })
        return
    }

    $Global:IsAiRunning = $true
    $btnSendAI.IsEnabled = $false
    
    $txtChatBox.AppendText("`n[BẠN]: $userText`n")
    $txtInputAI.Clear()
    $txtChatBox.AppendText("[TRỢ LÝ AI]: Đang suy nghĩ...`n")
    $txtChatBox.ScrollToEnd()

    [System.Windows.Forms.Application]::DoEvents()

    # THU THẬP TÊN CÁC SCRIPT ĐỂ DẠY AI
    $danhSachTenFile = ""
    foreach ($path in $Global:DanhSachScript) {
        $tenFile = Split-Path $path -Leaf
        $danhSachTenFile += "- $tenFile`n"
    }

    # VIẾT SYSTEM PROMPT DẠY AI TRỞ THÀNH AGENT
    $systemPrompt = @"
Bạn là trợ lý ảo của VietToolbox Pro. Nếu người dùng hỏi các câu hỏi thông thường, hãy trả lời bình thường. 
NHƯNG, nếu người dùng yêu cầu thực hiện một hành động (như dọn rác, kiểm tra ổ cứng, sửa lỗi, v.v.), hãy quét danh sách các công cụ (script) dưới đây xem có file nào phù hợp với yêu cầu không:
$danhSachTenFile
Nếu tìm thấy file phù hợp, bạn KHÔNG cần giải thích gì thêm, MÀ CHỈ CẦN xuất ra duy nhất từ khóa: [RUN:Tên_File.ps1].
Ví dụ: Người dùng nói "Dọn rác cho tôi", bạn xuất ra: [RUN:ClearTemp.ps1]
"@

    $url = "https://api.groq.com/openai/v1/chat/completions"
    $aiText = ""
    $finalError = ""

    foreach ($modelID in $Global:ModelList) {
        $bodyObj = @{
            model = $modelID
            messages = @( 
                @{ role = "system"; content = $systemPrompt },
                @{ role = "user"; content = $userText } 
            )
        }
        $bodyJson = ConvertTo-Json $bodyObj -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)

        try {
            $request = [System.Net.WebRequest]::Create($url)
            $request.Method = "POST"
            $request.ContentType = "application/json; charset=utf-8"
            $request.Headers.Add("Authorization", "Bearer $cleanKey")
            $request.ContentLength = $bytes.Length

            $stream = $request.GetRequestStream()
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Close()

            $asyncResult = $request.BeginGetResponse($null, $null)
            
            while (-not $asyncResult.IsCompleted) {
                [System.Threading.Thread]::Sleep(50)
                [System.Windows.Forms.Application]::DoEvents()
            }

            $response = $request.EndGetResponse($asyncResult)
            $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
            $jsonResponse = $reader.ReadToEnd()
            $reader.Close()
            $response.Close()
            
            $obj = $jsonResponse | ConvertFrom-Json
            $aiText = $obj.choices[0].message.content
            break 
        } catch {
            $finalError = "LỖI KẾT NỐI! Máy chủ hiện tại đang quá tải."
        }
    }

    if ($aiText -eq "") { $aiText = $finalError }

    # CƠ CHẾ INTERCEPT: NẾU THẤY TỪ KHÓA LÀ BÓP CÒ CHẠY SCRIPT LUÔN
    if ($aiText -match "\[RUN:(.*?)\]") {
        $tenFileCanChay = $matches[1].Trim()
        $duongDanThucTe = ""
        
        foreach ($path in $Global:DanhSachScript) {
            if ($path -match $tenFileCanChay) {
                $duongDanThucTe = $path
                break
            }
        }

        if ($duongDanThucTe -ne "") {
            $window.Dispatcher.Invoke([action]{
                $txtChatBox.AppendText("[HỆ THỐNG AI]: Đã phân tích xong yêu cầu! Tự động kích hoạt công cụ: $tenFileCanChay...`n")
                $txtChatBox.ScrollToEnd()
                $txtLog.Clear()
            })
            
            try {
                . $duongDanThucTe
                $aiText = "Đã thực thi thành công lệnh $tenFileCanChay cho bạn rồi đó!"
            } catch {
                $aiText = "Cố gắng chạy $tenFileCanChay nhưng gặp lỗi hệ thống: $($_.Exception.Message)"
                Ghi-Log "LỖI AI AUTO-RUN: $($_.Exception.Message)"
            }
        } else {
            $aiText = "Tôi hiểu ý bạn muốn chạy $tenFileCanChay, nhưng tôi không tìm thấy file này trong thư mục Scripts!"
        }
    }

    $window.Dispatcher.Invoke([action]{
        $txtChatBox.AppendText("$aiText`n")
        $txtChatBox.ScrollToEnd()
        $Global:IsAiRunning = $false
        $btnSendAI.IsEnabled = $true
    })
}

# 10. SỰ KIỆN NÚT BẤM 
$btnSendAI.Add_Click({ Gui-Tin-Nhan-AI })

$txtInputAI.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq "Enter" -or $e.Key -eq "Return") { Gui-Tin-Nhan-AI }
})

$btnMin.Add_Click({ $window.WindowState = "Minimized" })

$btnColor.Add_Click({
    if ($Global:LogColorGreen) { 
        $txtLog.Foreground = "#FFFFFF"
        $btnColor.Content = "MÀU CHỮ: TRẮNG"
        $Global:LogColorGreen = $false 
    } else { 
        $txtLog.Foreground = "#00FF00"
        $btnColor.Content = "MÀU CHỮ: XANH"
        $Global:LogColorGreen = $true 
    }
})

$btnShutdown.Add_Click({
    $msg = "Bạn có chắc chắn muốn TẮT MÁY không?"
    $title = "VietToolbox"
    if ([System.Windows.Forms.MessageBox]::Show($msg, $title, 4, 48) -eq "Yes") { 
        Stop-Computer -Force 
    }
})

$btnRestart.Add_Click({
    $msg = "Bạn có chắc chắn muốn KHỞI ĐỘNG LẠI không?"
    $title = "VietToolbox"
    if ([System.Windows.Forms.MessageBox]::Show($msg, $title, 4, 32) -eq "Yes") { 
        Restart-Computer -Force 
    }
})

$btnClose.Add_Click({ $window.Close() })

$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# 11. KHỞI CHẠY
Update-UI
$window.ShowDialog() | Out-Null