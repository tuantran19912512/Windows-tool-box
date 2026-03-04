[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Đoạn code ẩn cửa sổ Console (màn hình xanh/đen)
$showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

$hwnd = (Get-Process -Id $PID).MainWindowHandle
if ($hwnd -ne [IntPtr]::Zero) {
    # 0 = Ẩn, 1 = Hiện
    $showWindowAsync::ShowWindowAsync($hwnd, 0) | Out-Null
}
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# 1. Tự động quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$scriptFolder = Join-Path $PSScriptRoot "Scripts"

# 2. Giao diện XAML (Group Style)
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Pro" Height="750" Width="1200" 
        Background="#1E1E1E" WindowStyle="None" AllowsTransparency="True" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="12" Background="#252526" BorderBrush="#007ACC" BorderThickness="2">
        <Grid>
            <StackPanel VerticalAlignment="Top" Margin="20,15,20,0">
                <TextBlock Text="WINDOWS TOOL BOX PRO" Foreground="#007ACC" FontSize="28" FontWeight="Bold" HorizontalAlignment="Center"/>
                <TextBlock Text="Hệ thống quản trị chuyên nghiệp theo nhóm" Foreground="#858585" FontSize="13" HorizontalAlignment="Center" Margin="0,5"/>
                <Separator Background="#3E3E42" Margin="0,10"/>
            </StackPanel>

            <Grid Margin="20,95,20,75">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="320"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <GroupBox Header="NHÓM CÔNG CỤ" Foreground="#007ACC" BorderBrush="#3E3E42">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel Name="GroupContainer" Margin="5"/>
                    </ScrollViewer>
                </GroupBox>

                <GroupBox Grid.Column="1" Header="NHẬT KÝ HỆ THỐNG" Foreground="#00FF00" BorderBrush="#3E3E42" Margin="15,0,0,0">
                    <TextBox Name="TxtLog" Background="#0F0F0F" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" 
                             IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" 
                             BorderThickness="0" Padding="15"/>
                </GroupBox>
            </Grid>

            <Button Name="BtnClose" Content="THOÁT ✕" VerticalAlignment="Bottom" HorizontalAlignment="Right" 
                    Width="140" Height="45" Margin="20" Background="#E81123" Foreground="White" BorderThickness="0" FontWeight="Bold">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
            </Button>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $inputXML)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$groupContainer = $window.FindName("GroupContainer")
$txtLog = $window.FindName("TxtLog")
$btnClose = $window.FindName("BtnClose")

function Global:Ghi-Log($msg) {
    $window.Dispatcher.Invoke([action]{
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
        $txtLog.ScrollToEnd()
    })
    [System.Windows.Forms.Application]::DoEvents()
}
function Global:ChayTacVu($tenTacVu, $logic) {
    $window.Dispatcher.Invoke([action]{
        # Bước 1: Xóa sạch màn hình log cũ cho gọn
        $txtLog.Clear()
    })
    
    Ghi-Log "=========================================="
    Ghi-Log ">>> ĐANG THỰC HIỆN: $tenTacVu"
    Ghi-Log "=========================================="

    try {
        # Bước 2: Chạy logic của script (ScriptBlock)
        &$logic
    } catch {
        Ghi-Log "!!! LỖI HỆ THỐNG: $($_.Exception.Message)"
    }
}
# 3. Hàm tạo Group và Button tự động
function Update-UI {
    $groupContainer.Children.Clear()
    if (!(Test-Path $scriptFolder)) { return }
    
    $subFolders = Get-ChildItem -Path $scriptFolder -Directory | Sort-Object Name
    foreach ($folder in $subFolders) {
        # Tạo Expander (Nhóm mở rộng)
        $expander = New-Object System.Windows.Controls.Expander
        $expander.Header = $folder.Name.Substring($folder.Name.IndexOf('_') + 1).Replace('_',' ')
        $expander.Foreground = "#007ACC"
        $expander.FontWeight = "Bold"
        $expander.FontSize = 15
        $expander.Margin = "0,0,0,10"
        
        # SỬA TẠI ĐÂY: Chuyển thành $false để mặc định đóng lại
        $expander.IsExpanded = $false 

        $stack = New-Object System.Windows.Controls.StackPanel
        $stack.Margin = "10,5,0,0"

        $files = Get-ChildItem -Path $folder.FullName -Filter "*.ps1" | Sort-Object Name
        foreach ($file in $files) {
            $btn = New-Object System.Windows.Controls.Button
            $btn.Content = "● " + $file.BaseName.Substring($file.BaseName.IndexOf('_') + 1).Replace('_',' ')
            $btn.Height = 40
            $btn.Margin = "0,0,0,5"
            $btn.Background = "#333337"
            $btn.Foreground = "White"
            $btn.HorizontalContentAlignment = "Left"
            $btn.Padding = "10,0,0,0"
            $btn.Tag = $file.FullName

            $btn.Add_Click({
                param($sender, $e)
                $path = $sender.Tag
                Ghi-Log "------------------------------------------"
                Ghi-Log "BẮT ĐẦU: $(Split-Path $path -Leaf)"
                try { . $path } catch { Ghi-Log "LỖI: $($_.Exception.Message)" }
            })
            $stack.Children.Add($btn)
        }
        $expander.Content = $stack
        $groupContainer.Children.Add($expander)
    }
}

Update-UI
$btnClose.Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null