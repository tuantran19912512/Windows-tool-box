# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO - STANDARD EDITION (V182.2 - HIDE ADMIN)
# Tác giả: Tuấn Kỹ Thuật Máy Tính & Gemini 3.1 Pro
# Ghi chú: GIỮ NGUYÊN GIAO DIỆN GỐC - ẨN THƯ MỤC ADMIN KHỎI UI - AI VẪN CHẠY ĐƯỢC
# ==============================================================================

# 1. THIẾT LẬP MÔI TRƯỜNG
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

if ($PSScriptRoot -eq "" -or $null -eq $PSScriptRoot) { $Global:CurrentPath = $pwd } else { $Global:CurrentPath = $PSScriptRoot }
$scriptFolder = Join-Path $Global:CurrentPath "Scripts"
$logoPath = Join-Path $Global:CurrentPath "logo2.png"

# --- GIẢI MÃ KEY AI (DÁN CHUỖI MÃ HOÁ VÀO ĐÂY) ---
$EncStr = "B9vMDEyC5peZeIP4Wjc8u32aWyJN9xa9+pGS1p9iS4GQEfN1xAXtzTsaseDNR4vjFqKU065hbGBnMy5kMUlH3w=="
try {
    $S = [Text.Encoding]::UTF8.GetBytes("VietToolbox"); $K = (New-Object Security.Cryptography.Rfc2898DeriveBytes "Admin@2512", $S, 1000).GetBytes(32); $I = (New-Object Security.Cryptography.Rfc2898DeriveBytes "Admin@2512", $S, 1000).GetBytes(16); $A = [Security.Cryptography.Aes]::Create(); $A.Key = $K; $A.IV = $I; $D = $A.CreateDecryptor(); $EB = [Convert]::FromBase64String($EncStr); $DB = $D.TransformFinalBlock($EB, 0, $EB.Length); $Global:apiKey = [Text.Encoding]::UTF8.GetString($DB); $A.Dispose()
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

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# 3. TỰ ĐỘNG YÊU CẦU QUYỀN ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# 4. GIAO DIỆN XAML
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Height="850" Width="1200" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
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
                        <TabItem Header=" NHẬT KÝ HỆ THỐNG " Foreground="#00FF00"><TextBox Name="TxtLog" Background="#050505" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" BorderThickness="0" Padding="15" Opacity="0.9"/></TabItem>
                        <TabItem Header=" TRỢ LÝ AI (AUTO RUN) " Foreground="#007ACC"><Grid Margin="10"><Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                            <TextBox Name="TxtChatBox" Grid.Row="0" Background="#0A101A" Foreground="#DCDCDC" FontSize="14" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderBrush="#333333" Padding="10"/>
                            <Grid Grid.Row="1" Margin="0,10,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                                <TextBox Name="TxtInputAI" Grid.Column="0" Height="35" Background="#1A1A1A" Foreground="White" BorderBrush="#007ACC" VerticalContentAlignment="Center" Padding="10,0" /><Button Name="BtnSendAI" Grid.Column="1" Content="GỬI" Margin="10,0,0,0" Background="#007ACC" Foreground="White" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources></Button>
                            </Grid></Grid></TabItem>
                    </TabControl></GroupBox></Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="25">
                <Button Name="BtnMin" Content="THU NHỎ" Width="110" Height="45" Margin="0,0,10,0" Background="#1F3A5F" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
                <Button Name="BtnShutdown" Content="TẮT MÁY" Width="130" Height="45" Margin="0,0,10,0" Background="#D35400" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
                <Button Name="BtnRestart" Content="KHỞI ĐỘNG LẠI" Width="130" Height="45" Margin="0,0,10,0" Background="#2980B9" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
                <Button Name="BtnColor" Content="MÀU CHỮ" Width="110" Height="45" Margin="0,0,10,0" Background="#333337" Foreground="White" BorderThickness="1" BorderBrush="#007ACC" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
                <Button Name="BtnClose" Content="THOÁT ✕" Width="110" Height="45" Background="#CC1123" Foreground="White" BorderThickness="0" FontWeight="Bold"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources></Button>
            </StackPanel>
        </Grid></Border>
</Window>
"@

# 5. KHỞI TẠO GIAO DIỆN
$stringReader = New-Object System.IO.StringReader($inputXML); $xmlReader = [System.Xml.XmlReader]::Create($stringReader); $window = [Windows.Markup.XamlReader]::Load($xmlReader)
$groupContainer = $window.FindName("GroupContainer"); $txtLog = $window.FindName("TxtLog"); $btnClose = $window.FindName("BtnClose"); $btnColor = $window.FindName("BtnColor"); $btnMin = $window.FindName("BtnMin"); $btnShutdown = $window.FindName("BtnShutdown"); $btnRestart = $window.FindName("BtnRestart"); $txtThongBao = $window.FindName("TxtThongBao")
$txtChatBox = $window.FindName("TxtChatBox"); $txtInputAI = $window.FindName("TxtInputAI"); $btnSendAI = $window.FindName("BtnSendAI")

# 6. TẢI THÔNG BÁO TỪ GITHUB
try {
    $urlRaw = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/ThongBao.txt"
    $rawText = Invoke-RestMethod -Uri ($urlRaw + "?t=" + [DateTime]::Now.Ticks) -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    $foundKhach = ($rawText -split "`n" | Where-Object { $_ -match "Khách:" }) -replace ".*Khách:\s*", ""
    $txtThongBao.Text = if ($foundKhach.Trim() -ne "") { "🔥 " + $foundKhach.Trim() } else { "🔥 VietToolbox Pro - Sẵn sàng!" }
} catch { $txtThongBao.Text = "🔥 VietToolbox Pro - Hệ thống ổn định!" }

# 7. HÀM LOG
$Global:LogColorGreen = $true
function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{ $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n"); $txtLog.ScrollToEnd() })
    [System.Windows.Forms.Application]::DoEvents()
}

# 8. CẬP NHẬT DANH SÁCH SCRIPTS (ẨN THƯ MỤC ADMIN KHỎI GIAO DIỆN)
function Update-UI {
    $null = $groupContainer.Children.Clear(); $Global:DanhSachScript = @()
    if (!(Test-Path $scriptFolder)) { return }
    function Get-ScriptsRecursive ($Path, $ParentStack, $Level) {
        Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name | foreach {
            
            # --- CHỖ NÀY LÀ CÁI KHÓA: NẾU LÀ THƯ MỤC TÊN ADMIN THÌ KHÔNG VẼ LÊN GIAO DIỆN ---
            if ($_.PSIsContainer -and $_.Name -match "Admin") {
                # Nhưng vẫn chui vào trong để lấy danh sách file cho AI
                Get-ChildItem -Path $_.FullName -Recurse -Filter "*.ps1" | foreach { $Global:DanhSachScript += $_.FullName }
                return # Thoát vòng lặp hiện tại, không tạo Expander cho folder này
            }

            if ($_.PSIsContainer) {
                $subExp = New-Object System.Windows.Controls.Expander; $subExp.Header = $_.Name; $subExp.Foreground = if ($Level -eq 0) { "#007ACC" } else { "#858585" }; $subExp.FontWeight = "Bold"
                $subStack = New-Object System.Windows.Controls.StackPanel; $subStack.Margin = "15,0,0,5"
                Get-ScriptsRecursive $_.FullName $subStack ($Level + 1)
                $subExp.Content = $subStack; $null = $ParentStack.Children.Add($subExp)
            } else {
                if ($_.Extension -eq ".ps1") {
                    if ($Global:DanhSachScript -notcontains $_.FullName) { $Global:DanhSachScript += $_.FullName }
                    $btn = New-Object System.Windows.Controls.Button; $btn.Content = "● " + $_.BaseName; $btn.Height = 38; $btn.Background = "#2D2D2D"; $btn.Foreground = "#DCDCDC"; $btn.HorizontalContentAlignment = "Left"; $btn.Tag = $_.FullName
                    $btn.Add_Click({ param($sender, $e) $window.Dispatcher.Invoke([action]{ $txtLog.Clear() }); try { . $sender.Tag } catch { Ghi-Log "LỖI: $($_.Exception.Message)" } })
                    $null = $ParentStack.Children.Add($btn)
                }
            }
        }
    }
    Get-ScriptsRecursive $scriptFolder $groupContainer 0
}

# 9. HÀM AI (AUTO RUN)
function Gui-AI {
    if ($Global:IsAiRunning -or [string]::IsNullOrWhiteSpace($txtInputAI.Text)) { return }
    $userT = $txtInputAI.Text; $txtInputAI.Clear(); $Global:IsAiRunning = $true; $btnSendAI.IsEnabled = $false
    $txtChatBox.AppendText("`n[BẠN]: $userT`n[AI]: Đang nghĩ...`n"); $txtChatBox.ScrollToEnd(); [System.Windows.Forms.Application]::DoEvents()
    $fileList = ""; foreach($p in $Global:DanhSachScript) { $fileList += "- $(Split-Path $p -Leaf)`n" }
    $sysP = "Bạn là trợ lý VietToolbox. Có danh sách script: $fileList. Nếu người dùng muốn làm gì đó, hãy xuất duy nhất [RUN:Tên_File.ps1]. Nếu không, hãy trả lời ngắn gọn."

    foreach ($m in $Global:ModelList) {
        try {
            $body = @{ model = $m; messages = @(@{role="system";content=$sysP}, @{role="user";content=$userT}) } | ConvertTo-Json -Compress
            $req = [System.Net.WebRequest]::Create("https://api.groq.com/openai/v1/chat/completions")
            $req.Method = "POST"; $req.ContentType = "application/json"; $req.Headers.Add("Authorization", "Bearer $Global:apiKey")
            $bytes = [Text.Encoding]::UTF8.GetBytes($body); $req.ContentLength = $bytes.Length
            $st = $req.GetRequestStream(); $st.Write($bytes, 0, $bytes.Length); $st.Close()
            $resp = $req.GetResponse(); $rd = New-Object System.IO.StreamReader($resp.GetResponseStream()); $aiT = ($rd.ReadToEnd() | ConvertFrom-Json).choices[0].message.content
            if ($aiT -match "\[RUN:(.*?)\]") {
                $f = $matches[1].Trim()
                $path = $Global:DanhSachScript | Where-Object { $_ -match [regex]::Escape($f) } | Select-Object -First 1
                if ($path) { $window.Dispatcher.Invoke([action]{ $txtChatBox.AppendText("[AI]: Chạy $f...`n") }); . $path; $aiT = "Đã thực hiện xong lệnh $f!" }
            }
            $txtChatBox.AppendText("$aiT`n"); break
        } catch { if ($m -eq $Global:ModelList[-1]) { $txtChatBox.AppendText("LỖI KẾT NỐI API!`n") } }
    }
    $Global:IsAiRunning = $false; $btnSendAI.IsEnabled = $true; $txtChatBox.ScrollToEnd()
}

# 10. SỰ KIỆN
$btnMin.Add_Click({ $window.WindowState = "Minimized" })
$btnColor.Add_Click({ if ($Global:LogColorGreen) { $txtLog.Foreground = "#FFFFFF"; $Global:LogColorGreen = $false } else { $txtLog.Foreground = "#00FF00"; $Global:LogColorGreen = $true } })
$btnShutdown.Add_Click({ if ([System.Windows.Forms.MessageBox]::Show("Tuấn có chắc chắn TẮT MÁY?", "VietToolbox", 4, 48) -eq "Yes") { Stop-Computer -Force } })
$btnRestart.Add_Click({ if ([System.Windows.Forms.MessageBox]::Show("Tuấn có chắc chắn RESTART?", "VietToolbox", 4, 32) -eq "Yes") { Restart-Computer -Force } })
$btnClose.Add_Click({ $window.Close() }); $btnSendAI.Add_Click({ Gui-AI }); $txtInputAI.Add_KeyDown({ if ($_.Key -eq "Enter") { Gui-AI } })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# 11. KHỞI CHẠY
Update-UI; $window.ShowDialog() | Out-Null