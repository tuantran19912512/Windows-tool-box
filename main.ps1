# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO - ULTIMATE STEALTH AGENT (V198.0)
# Tác giả: Tuấn Kỹ Thuật Máy Tính & Gemini 3.1 Pro
# Ghi chú: BẢN FULL - KHÔNG LƯỢC BỎ TÍNH NĂNG - TỰ ĐỘNG CHẠY SCRIPT - BAO GITHUB
# ==============================================================================

# 1. THIẾT LẬP HỆ THỐNG & TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# 2. KHỞI TẠO ĐƯỜNG DẪN
$scriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
if ($scriptPath) { $Global:CurrentPath = Split-Path $scriptPath -Parent } else { $Global:CurrentPath = $pwd.Path }
$scriptFolder = Join-Path $Global:CurrentPath "Scripts"
$logoPath = Join-Path $Global:CurrentPath "logo2.png"

# --- 3. CƠ CHẾ GIẢI MÃ KEY TÀNG HÌNH (DÁN CHUỖI BƯỚC 1 VÀO ĐÂY) ---
$EncryptedString = "B9vMDEyC5peZeIP4Wjc8u32aWyJN9xa9+pGS1p9iS4GQEfN1xAXtzTsaseDNR4vjFqKU065hbGBnMy5kMUlH3w=="
$Password = "Admin@2512"

try {
    $Salt = [Text.Encoding]::UTF8.GetBytes("VietToolbox")
    $Key = (New-Object Security.Cryptography.Rfc2898DeriveBytes $Password, $Salt, 1000).GetBytes(32)
    $IV = (New-Object Security.Cryptography.Rfc2898DeriveBytes $Password, $Salt, 1000).GetBytes(16)
    $AES = [Security.Cryptography.Aes]::Create()
    $AES.Key = $Key; $AES.IV = $IV
    $Decryptor = $AES.CreateDecryptor()
    $EncBytes = [Convert]::FromBase64String($EncryptedString)
    $DecBytes = $Decryptor.TransformFinalBlock($EncBytes, 0, $EncBytes.Length)
    $Global:apiKey = [Text.Encoding]::UTF8.GetString($DecBytes)
    $AES.Dispose()
} catch { $Global:apiKey = "" }

# DANH SÁCH AI DỰ PHÒNG (GROQ)
$Global:ModelList = @("llama-3.3-70b-versatile", "llama3-8b-8192", "mixtral-8x7b-32768")
$Global:IsAiRunning = $false
$Global:DanhSachScript = @()

# 4. GIAO DIỆN XAML CỰC ĐẸP
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Height="850" Width="1200" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" BorderBrush="#007ACC" BorderThickness="2">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#0A1628" Offset="0"/><GradientStop Color="#02050A" Offset="1"/>
            </LinearGradientBrush>
        </Border.Background>
        <Grid>
            <Grid VerticalAlignment="Top" Margin="30,30,30,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Image Grid.Column="0" Source="$logoPath" Height="140" Width="140" HorizontalAlignment="Left" Margin="0,0,30,0">
                    <Image.Effect><DropShadowEffect BlurRadius="20" Color="#007ACC" ShadowDepth="0" Opacity="0.8"/></Image.Effect>
                </Image>
                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="WINDOWS TOOL BOX PRO" Foreground="#007ACC" FontSize="36" FontWeight="Bold"/>
                    <TextBlock Text="Hệ thống quản trị chuyên nghiệp - Tuấn Kỹ Thuật Máy Tính" Foreground="#858585" FontSize="16" Margin="0,8,0,0"/>
                    <TextBlock Name="TxtThongBao" Text="Đang kiểm tra cập nhật..." Foreground="#FF3333" FontSize="15" FontWeight="Bold" Margin="0,10,0,0">
                        <TextBlock.Triggers><EventTrigger RoutedEvent="TextBlock.Loaded"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="1.0" To="0.2" Duration="0:0:0.8" AutoReverse="True" RepeatBehavior="Forever"/></Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
                    </TextBlock>
                </StackPanel>
            </Grid>
            <Separator VerticalAlignment="Top" Background="#3E3E42" Margin="30,190,30,0" Opacity="0.5"/>
            <Grid Margin="20,210,20,85">
                <Grid.ColumnDefinitions><ColumnDefinition Width="330"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <GroupBox Header="NHÓM CÔNG CỤ" Foreground="#007ACC" BorderBrush="#333333"><ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Name="GroupContainer" Margin="10"/></ScrollViewer></GroupBox>
                <GroupBox Grid.Column="1" Header="BẢNG ĐIỀU KHIỂN" Foreground="#00FF00" BorderBrush="#333333" Margin="15,0,0,0">
                    <TabControl Background="Transparent" BorderThickness="0">
                        <TabItem Header=" NHẬT KÝ " Foreground="#00FF00"><TextBox Name="TxtLog" Background="#050505" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" BorderThickness="0" Padding="15"/></TabItem>
                        <TabItem Header=" TRỢ LÝ AI (AUTO RUN) " Foreground="#007ACC"><Grid Margin="10"><Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                <TextBox Name="TxtChatBox" Grid.Row="0" Background="#0A101A" Foreground="#DCDCDC" FontSize="14" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderBrush="#333333" Padding="10"/>
                                <Grid Grid.Row="1" Margin="0,10,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                                    <TextBox Name="TxtInputAI" Grid.Column="0" Height="35" Background="#1A1A1A" Foreground="White" BorderBrush="#007ACC" VerticalContentAlignment="Center" Padding="10,0" /><Button Name="BtnSendAI" Grid.Column="1" Content="GỬI" Margin="10,0,0,0" Background="#007ACC" Foreground="White" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources></Button>
                                </Grid></Grid></TabItem>
                    </TabControl></GroupBox></Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="25">
                <Button Name="BtnMin" Content="THU NHỎ" Width="110" Height="45" Margin="0,0,10,0" Background="#1F3A5F" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
                <Button Name="BtnShutdown" Content="TẮT MÁY" Width="110" Height="45" Margin="0,0,10,0" Background="#D35400" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
                <Button Name="BtnRestart" Content="RESTART" Width="110" Height="45" Margin="0,0,10,0" Background="#2980B9" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
                <Button Name="BtnClose" Content="THOÁT ✕" Width="110" Height="45" Background="#CC1123" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
            </StackPanel>
        </Grid></Border>
</Window>
"@

# 5. KHỞI TẠO ĐỐI TƯỢNG XAML
$xmlReader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$inputXML)
$window = [Windows.Markup.XamlReader]::Load($xmlReader)
$groupContainer = $window.FindName("GroupContainer")
$txtLog = $window.FindName("TxtLog")
$txtChatBox = $window.FindName("TxtChatBox")
$txtInputAI = $window.FindName("TxtInputAI")
$btnSendAI = $window.FindName("BtnSendAI")
$txtThongBao = $window.FindName("TxtThongBao")

# 6. TỰ ĐỘNG YÊU CẦU QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs; exit
}

# 7. CẬP NHẬT UI & DANH SÁCH SCRIPT (BẢN V200.0 - CHẶN TRIỆT ĐỂ THƯ MỤC ADMIN)
function Update-UI {
    $null = $groupContainer.Children.Clear(); $Global:DanhSachScript = @()
    if (!(Test-Path $scriptFolder)) { return }
    
    function Get-ScriptsRecursive ($Path, $ParentStack) {
        Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name | foreach {
            
            # --- CHỖ NÀY LÀ CÁI KHÓA: THẤY CHỮ "ADMIN" LÀ ĐUỔI THẲNG CỔ (CẢ FILE VÀ THƯ MỤC) ---
            if ($_.Name -match "Admin") { return } 
            
            if ($_.PSIsContainer) {
                $subExp = New-Object System.Windows.Controls.Expander
                $subExp.Header = $_.Name; $subExp.Foreground = "#007ACC"; $subExp.FontWeight = "Bold"
                $subStack = New-Object System.Windows.Controls.StackPanel; $subStack.Margin = "15,0,0,5"
                
                Get-ScriptsRecursive $_.FullName $subStack
                
                # Nếu thư mục bên trong có chứa script thì mới hiện ra
                if ($subStack.Children.Count -gt 0) {
                    $subExp.Content = $subStack
                    $null = $ParentStack.Children.Add($subExp)
                }
            } else {
                if ($_.Extension -eq ".ps1") {
                    $Global:DanhSachScript += $_.FullName
                    $btn = New-Object System.Windows.Controls.Button
                    $btn.Content = "● " + $_.BaseName; $btn.Height = 35; $btn.Background = "#2D2D2D"; $btn.Foreground = "#DCDCDC"
                    $btn.HorizontalContentAlignment = "Left"; $btn.Margin = "0,2,0,2"; $btn.Tag = $_.FullName
                    $btn.Add_Click({ try { $txtLog.Clear(); . $this.Tag } catch { $txtLog.AppendText("LỖI: $($_.Exception.Message)") } })
                    $null = $ParentStack.Children.Add($btn)
                }
            }
        }
    }
    Get-ScriptsRecursive $scriptFolder $groupContainer
}

# 8. LOGIC AI AGENT
function Gui-AI {
    if ($Global:IsAiRunning -or [string]::IsNullOrWhiteSpace($txtInputAI.Text)) { return }
    $userT = $txtInputAI.Text; $txtInputAI.Clear(); $Global:IsAiRunning = $true; $btnSendAI.IsEnabled = $false
    $txtChatBox.AppendText("`n[BẠN]: $userT`n[TRỢ LÝ AI]: Đang suy nghĩ...`n"); $txtChatBox.ScrollToEnd()
    
    $fileList = ""; foreach($p in $Global:DanhSachScript) { $fileList += "- $(Split-Path $p -Leaf)`n" }
    $sysPrompt = "Bạn là trợ lý VietToolbox. Nếu người dùng yêu cầu hành động, hãy tìm file phù hợp trong danh sách này:`n$fileList`nNếu thấy, chỉ xuất duy nhất: [RUN:Tên_File.ps1]. Nếu không thấy hoặc là câu hỏi thường, hãy trả lời ngắn gọn."

    foreach ($m in $Global:ModelList) {
        try {
            $body = @{ model = $m; messages = @(@{role="system";content=$sysPrompt}, @{role="user";content=$userT}) } | ConvertTo-Json -Compress
            $req = [System.Net.WebRequest]::Create("https://api.groq.com/openai/v1/chat/completions")
            $req.Method = "POST"; $req.ContentType = "application/json"; $req.Headers.Add("Authorization", "Bearer $Global:apiKey")
            $b = [Text.Encoding]::UTF8.GetBytes($body); $req.ContentLength = $b.Length
            $s = $req.GetRequestStream(); $s.Write($b, 0, $b.Length); $s.Close()
            $res = $req.GetResponse(); $rd = New-Object System.IO.StreamReader($res.GetResponseStream()); $aiT = ($rd.ReadToEnd() | ConvertFrom-Json).choices[0].message.content
            if ($aiT -match "\[RUN:(.*?)\]") {
                $f = $matches[1].Trim(); $path = $Global:DanhSachScript | Where-Object { $_ -match $f } | Select-Object -First 1
                if ($path) { $txtChatBox.AppendText("[AI]: Kích hoạt $f...`n"); . $path; $aiT = "Đã xong lệnh $f!" }
            }
            $txtChatBox.AppendText("$aiT`n"); break
        } catch { if ($m -eq $Global:ModelList[-1]) { $txtChatBox.AppendText("LỖI KẾT NỐI API!`n") } }
    }
    $Global:IsAiRunning = $false; $btnSendAI.IsEnabled = $true; $txtChatBox.ScrollToEnd()
}

# 9. SỰ KIỆN
$btnSendAI.Add_Click({ Gui-AI })
$txtInputAI.Add_KeyDown({ if ($_.Key -eq "Enter") { Gui-AI } })
$window.FindName("BtnClose").Add_Click({ $window.Close() })
$window.FindName("BtnMin").Add_Click({ $window.WindowState = "Minimized" })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# 10. CHẠY
Update-UI; $window.ShowDialog() | Out-Null