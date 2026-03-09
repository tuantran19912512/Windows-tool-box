# ==============================================================================
# Tên công cụ: VIETTOOLBOX PRO (BẢN CẬP NHẬT QUICK POWER)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# 1. Đoạn code ẩn cửa sổ Console
$showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) { 
    $showWindowAsync::ShowWindowAsync($hwnd, 0) | Out-Null 
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# 2. Tự động kiểm tra và yêu cầu quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 3. Cấu hình đường dẫn
$scriptFolder = Join-Path $PSScriptRoot "Scripts"
$logoPath = Join-Path $PSScriptRoot "logo2.png"

# 4. Giao diện XAML (Logo 140x140 + 4 Nút chức năng ở Footer)
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

                <Image Grid.Column="0" Source="$logoPath" 
                       Height="140" Width="140" HorizontalAlignment="Left" Margin="0,0,30,0">
                    <Image.Effect>
                        <DropShadowEffect BlurRadius="20" Color="#007ACC" ShadowDepth="0" Opacity="0.8"/>
                    </Image.Effect>
                </Image>

                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="WINDOWS TOOL BOX PRO" Foreground="#007ACC" FontSize="36" FontWeight="Bold"/>
                    <TextBlock Text="Hệ thống quản trị chuyên nghiệp - Tuấn Kỹ Thuật Máy Tính" Foreground="#858585" FontSize="16" Margin="0,8,0,0"/>
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
                    <TextBox Name="TxtLog" Background="#050505" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" 
                             IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" 
                             BorderThickness="0" Padding="15" Opacity="0.9"/>
                </GroupBox>
            </Grid>

            <StackPanel Orientation="Horizontal" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="25">
                
                <Button Name="BtnShutdown" Content="TẮT MÁY" Width="130" Height="45" Margin="0,0,10,0" 
                        Background="#D35400" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>

                <Button Name="BtnRestart" Content="KHỞI ĐỘNG LẠI" Width="130" Height="45" Margin="0,0,10,0" 
                        Background="#2980B9" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>

                <Button Name="BtnColor" Content="MÀU CHỮ" Width="110" Height="45" Margin="0,0,10,0" 
                        Background="#333337" Foreground="White" BorderThickness="1" BorderBrush="#007ACC" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>

                <Button Name="BtnClose" Content="THOÁT ✕" Width="110" Height="45" 
                        Background="#CC1123" Foreground="White" BorderThickness="0" FontWeight="Bold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                </Button>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# 5. Khởi tạo Giao diện
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $inputXML)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$groupContainer = $window.FindName("GroupContainer")
$txtLog = $window.FindName("TxtLog")
$btnClose = $window.FindName("BtnClose")
$btnColor = $window.FindName("BtnColor")
$btnShutdown = $window.FindName("BtnShutdown")
$btnRestart = $window.FindName("BtnRestart")

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
    
    # --- HÀM ĐỆ QUY ĐỂ QUÉT SÂU VÀO THƯ MỤC CON ---
    function Get-ScriptsRecursive ($Path, $ParentStack, $Level) {
        # Lấy tất cả thư mục con và file ps1 trong đường dẫn hiện tại
        $items = Get-ChildItem -Path $Path | Sort-Object @{Expression={!$_.PSIsContainer}}, Name

        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                # --- NẾU LÀ THƯ MỤC: TẠO EXPANDER CON (HOẶC TEXTBLOCK) ---
                $subExpander = New-Object System.Windows.Controls.Expander
                # Xử lý tên hiển thị (Bỏ phần số thứ tự phía trước nếu có)
                $displayName = if ($item.Name -match "_") { $item.Name.Substring($item.Name.IndexOf('_') + 1).Replace('_',' ') } else { $item.Name }
                
                $subExpander.Header = $displayName
                $subExpander.Foreground = if ($Level -eq 0) { "#007ACC" } else { "#858585" } # Cấp 1 màu xanh, cấp sâu hơn màu xám
                $subExpander.FontWeight = "Bold"
                $subExpander.FontSize = if ($Level -eq 0) { 16 } else { 14 }
                $subExpander.Margin = "0,5,0,5"
                $subExpander.IsExpanded = $false # Mặc định đóng cho gọn

                # Xử lý bảo mật: CHỈ HỎI Ở THƯ MỤC CẤP CAO NHẤT CÓ TÊN ADMIN
                if ($item.Name -like "*Admin*" -and $Level -eq 0) {
                    $subExpander.Add_Expanded({
                        param($sender, $e)
                        # Nếu chưa có Token thì mới hiện bảng hỏi
                        if (-not $Global:GH_TOKEN) {
                            Add-Type -AssemblyName Microsoft.VisualBasic
                            $tokenDauVao = [Microsoft.VisualBasic.Interaction]::InputBox("Vui lòng nhập Key Admin:", "Xác thực VietToolbox", "")
                            
                            if ($tokenDauVao -and $tokenDauVao.Trim() -ne "") {
                                $Global:GH_TOKEN = $tokenDauVao.Trim()
                                Ghi-Log ">>> Xác thực Admin thành công."
                            } else {
                                # Nếu hủy hoặc nhập trống thì đóng lại ngay
                                $sender.IsExpanded = $false
                                [System.Windows.Forms.MessageBox]::Show("Truy cập bị từ chối!", "Cảnh báo")
                            }
                        }
                    })
                }

                $subStack = New-Object System.Windows.Controls.StackPanel
                $subStack.Margin = "15,0,0,5" # Thụt đầu dòng để phân cấp
                
                # Đệ quy: Chui tiếp vào thư mục con này
                Get-ScriptsRecursive $item.FullName $subStack ($Level + 1)
                
                $subExpander.Content = $subStack
                $null = $ParentStack.Children.Add($subExpander)

            } else {
                # --- NẾU LÀ FILE PS1: TẠO NÚT BẤM ---
                if ($item.Extension -eq ".ps1") {
                    $btn = New-Object System.Windows.Controls.Button
                    $cleanName = if ($item.BaseName -match "_") { $item.BaseName.Substring($item.BaseName.IndexOf('_') + 1).Replace('_',' ') } else { $item.BaseName }
                    
                    $btn.Content = "● " + $cleanName
                    $btn.Height = 38
                    $btn.Margin = "0,2,0,2"
                    $btn.Background = "#2D2D30"
                    $btn.Foreground = "#DCDCDC"
                    $btn.HorizontalContentAlignment = "Left"
                    $btn.Padding = "10,0,0,0"
                    $btn.Tag = $item.FullName # Lưu đường dẫn file để chạy
                    
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

    # Bắt đầu gọi đệ quy từ thư mục gốc Scripts
    Get-ScriptsRecursive $scriptFolder $groupContainer 0
}

# --- XỬ LÝ SỰ KIỆN ĐỔI MÀU CHỮ ---
$btnColor.Add_Click({
    if ($Global:LogColorGreen) {
        $txtLog.Foreground = "#FFFFFF"; $btnColor.Content = "MÀU CHỮ: TRẮNG"; $Global:LogColorGreen = $false
    } else {
        $txtLog.Foreground = "#00FF00"; $btnColor.Content = "MÀU CHỮ: XANH"; $Global:LogColorGreen = $true
    }
})

# --- XỬ LÝ SỰ KIỆN TẮT MÁY ---
$btnShutdown.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show("Toàn có chắc chắn muốn TẮT MÁY không?", "VietToolbox", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -eq "Yes") { 
        Ghi-Log ">>> ĐANG THỰC HIỆN TẮT MÁY..."
        Stop-Computer -Force 
    }
})

# --- XỬ LÝ SỰ KIỆN KHỞI ĐỘNG LẠI ---
$btnRestart.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show("Toàn có chắc chắn muốn KHỞI ĐỘNG LẠI không?", "VietToolbox", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($confirm -eq "Yes") { 
        Ghi-Log ">>> ĐANG THỰC HIỆN KHỞI ĐỘNG LẠI..."
        Restart-Computer -Force 
    }
})

# Khởi chạy
Update-UI
$btnClose.Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null