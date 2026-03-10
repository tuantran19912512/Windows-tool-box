# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO (BẢN KHÁCH / TIÊU CHUẨN)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) { $showWindowAsync::ShowWindowAsync($hwnd, 0) | Out-Null }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$scriptFolder = Join-Path $PSScriptRoot "Scripts"
$logoPath = Join-Path $PSScriptRoot "logo2.png"

$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro - Standard Edition" Height="850" Width="1200" 
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
                    <TextBlock Text="Hệ thống tối ưu tự động - Tuấn Kỹ Thuật Máy Tính" Foreground="#858585" FontSize="16" Margin="0,8,0,0"/>
                    
                    <TextBlock Name="TxtThongBao" Text="Đang kết nối hệ thống..." Foreground="#FF3333" FontSize="15" FontWeight="Bold" Margin="0,10,0,0">
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

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $inputXML)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$groupContainer = $window.FindName("GroupContainer")
$txtLog = $window.FindName("TxtLog")
$btnClose = $window.FindName("BtnClose")
$btnColor = $window.FindName("BtnColor")
$btnShutdown = $window.FindName("BtnShutdown")
$btnRestart = $window.FindName("BtnRestart")
$txtThongBao = $window.FindName("TxtThongBao")

# ==========================================================
# CƠ CHẾ TẢI THÔNG BÁO V180 - BẢN FIX LỖI BYTES
# ==========================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    $urlRaw = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/ThongBao.txt"
    $urlTurbo = $urlRaw + "?t=" + [DateTime]::Now.Ticks
    
    # 1. Tải thẳng nội dung về dạng chữ (String)
    $rawText = Invoke-RestMethod -Uri $urlTurbo -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    
    # 2. Xử lý tách dòng và lọc tin Khách
    $lines = $rawText -split "`n"
    $foundLine = ""
    foreach ($line in $lines) {
        if ($line -match "Khách:") {
            $foundLine = $line -replace ".*Khách:\s*", ""
            break
        }
    }

    if ($foundLine.Trim() -ne "") {
        $txtThongBao.Text = "🔥 " + $foundLine.Trim()
    } else {
        # Nếu file không có chữ Khách:, hiện dòng đầu tiên cho nó máu
        $txtThongBao.Text = "🔥 " + $lines[0].Trim()
    }
} catch {
    # Nếu ổn rồi thì ông đổi lại câu chào: "🔥 VietToolbox Pro - Hệ thống ổn định!"
    $txtThongBao.Text = "❌ Lỗi kết nối Server: " + $_.Exception.Message
}

$Global:LogColorGreen = $true

function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
        $txtLog.ScrollToEnd()
    })
    [System.Windows.Forms.Application]::DoEvents()
}

function Global:ChayTacVu($tenTacVu, $logic) {
    $window.Dispatcher.Invoke([action]{ $txtLog.Clear() })
    Ghi-Log "=========================================="
    Ghi-Log ">>> ĐANG THỰC HIỆN: $tenTacVu"
    Ghi-Log "=========================================="
    try { &$logic } catch { Ghi-Log "!!! LỖI: $($_.Exception.Message)" }
}

function Update-UI {
    $null = $groupContainer.Children.Clear()
    if (!(Test-Path $scriptFolder)) { return }
    
    function Get-ScriptsRecursive ($Path, $ParentStack, $Level) {
        $items = Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name

        foreach ($item in $items) {
            # 🚨 BỘ LỌC TÀNG HÌNH: TỰ ĐỘNG BỎ QUA MỌI THỨ CÓ CHỮ "ADMIN" 🚨
            if ($item.Name -match "Admin" -or $item.Name -match "admin") { continue }

            if ($item.PSIsContainer) {
                $subExpander = New-Object System.Windows.Controls.Expander
                $displayName = if ($item.Name -match "_") { $item.Name.Substring($item.Name.IndexOf('_') + 1).Replace('_',' ') } else { $item.Name }
                
                $subExpander.Header = $displayName
                $subExpander.Foreground = if ($Level -eq 0) { "#007ACC" } else { "#858585" } 
                $subExpander.FontWeight = "Bold"
                $subExpander.FontSize = if ($Level -eq 0) { 16 } else { 14 }
                $subExpander.Margin = "0,5,0,5"
                $subExpander.IsExpanded = $false 

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
                    $btn.Background = "#2D2D30"; $btn.Foreground = "#DCDCDC"
                    $btn.HorizontalContentAlignment = "Left"; $btn.Padding = "10,0,0,0"
                    $btn.Tag = $item.FullName 
                    
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

Update-UI
$btnClose.Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null