# ==============================================================================
# Tên công cụ: VIETTOOLBOX - QUẢN LÝ QUYỀN TRUY CẬP (PHIÊN BẢN CHỐNG ĐƠ)
# Tác giả: Kỹ Thuật Viên
# Nâng cấp: Chạy đa luồng, có nút Dừng và thanh trạng thái động
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$laQuanTri = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($laQuanTri -eq $false) { 
    [System.Windows.MessageBox]::Show("Bạn phải chạy Script này bằng quyền Administrator!", "Thiếu quyền", 0, 48)
    exit 
}

$global:dangXuLy = $false

# --- GIAO DIỆN XAML WPF ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Permission Manager" Width="600" Height="500" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" Opacity="0">
    
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.3"/></Storyboard></BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="50" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="🛡️ QUẢN LÝ QUYỀN TRUY CẬP (ANTI-FREEZE)" Foreground="#38BDF8" FontWeight="Bold" FontSize="15" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDong" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>

            <StackPanel Margin="30,70,30,20">
                <TextBlock Text="ĐƯỜNG DẪN ĐANG CHỌN:" Foreground="#94A3B8" FontSize="13" Margin="0,0,0,5"/>
                <Grid Margin="0,0,0,20">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtDuongDan" Grid.Column="0" Height="30" VerticalContentAlignment="Center" Background="#1E293B" Foreground="White" BorderBrush="#334155" Padding="5,0"/>
                    <Button Name="NutChonFile" Grid.Column="1" Content="📁 Chọn" Width="60" Margin="5,0,0,0" Background="#334155" Foreground="White" Cursor="Hand"/>
                </Grid>

                <UniformGrid Columns="2" Margin="0,0,0,15">
                    <Button Name="NutTakeOwn" Content="🔑 Chiếm quyền" Height="45" Margin="0,0,5,5" Background="#3B82F6" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                    <Button Name="NutFullControl" Content="⚡ Toàn quyền" Height="45" Margin="5,0,0,5" Background="#10B981" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                    <Button Name="NutReset" Content="♻️ Reset Mặc định" Height="45" Margin="0,5,5,0" Background="#F59E0B" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                    <Button Name="NutCheck" Content="🔍 Kiểm tra Quyền" Height="45" Margin="5,5,0,0" Background="#6366F1" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </UniformGrid>
                
                <ProgressBar Name="ThanhChay" Height="3" Margin="0,15,0,10" IsIndeterminate="True" Visibility="Hidden" Foreground="#F59E0B" Background="Transparent" BorderThickness="0"/>

                <Border Background="#1E293B" CornerRadius="8" Padding="10" Height="100">
                    <ScrollViewer><TextBlock Name="TxtLog" Text="Hướng dẫn: Chọn thư mục rồi bấm chức năng. Nếu treo hãy bấm nút Dừng bên dưới." Foreground="#E2E8F0" FontSize="12" TextWrapping="Wrap"/></ScrollViewer>
                </Border>

                <Button Name="NutDung" Content="⏹ DỪNG LẠI (HỦY LỆNH)" Height="40" Margin="0,15,0,0" Background="#EF4444" Foreground="White" FontWeight="Bold" Cursor="Hand" Visibility="Hidden">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))
$txtDuongDan = $CuaSo.FindName("TxtDuongDan"); $txtLog = $CuaSo.FindName("TxtLog")
$nutChonFile = $CuaSo.FindName("NutChonFile"); $nutTakeOwn = $CuaSo.FindName("NutTakeOwn")
$nutFullControl = $CuaSo.FindName("NutFullControl"); $nutReset = $CuaSo.FindName("NutReset")
$nutCheck = $CuaSo.FindName("NutCheck"); $nutDong = $CuaSo.FindName("NutDong")
$thanhChay = $CuaSo.FindName("ThanhChay"); $nutDung = $CuaSo.FindName("NutDung")

$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDong.Add_Click({ $CuaSo.Close() })

$nutChonFile.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") { $txtDuongDan.Text = $dialog.SelectedPath }
})

# --- HÀM THỰC THI LỆNH HỆ THỐNG (CHỐNG TREO) ---
function Chay-LenhHeThong($FilePath, $Arguments, $Message) {
    $global:dangXuLy = $true
    $thanhChay.Visibility = "Visible"; $nutDung.Visibility = "Visible"
    $nutFullControl.IsEnabled = $false; $nutTakeOwn.IsEnabled = $false; $nutReset.IsEnabled = $false
    $txtLog.Text = "⏳ Đang xử lý: $Message...`n(Có thể mất vài phút nếu thư mục quá lớn)"
    
    $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = $Arguments
        $psi.WindowStyle = "Hidden"
        $psi.CreateNoWindow = $true
        $process = [System.Diagnostics.Process]::Start($psi)

        while (-not $process.HasExited) {
            $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
            if ($global:dangXuLy -eq $false) {
                Start-Process "taskkill.exe" -ArgumentList "/F /T /PID $($process.Id)" -WindowStyle Hidden -Wait
                break
            }
            Start-Sleep -Milliseconds 100
        }

        if ($global:dangXuLy) { $txtLog.Text = "✅ Hoàn tất: $Message" }
        else { $txtLog.Text = "⛔ Đã hủy lệnh theo yêu cầu của bạn!" }
    } catch {
        $txtLog.Text = "❌ Lỗi thực thi lệnh hệ thống!"
    } finally {
        $global:dangXuLy = $false
        $thanhChay.Visibility = "Hidden"; $nutDung.Visibility = "Hidden"
        $nutFullControl.IsEnabled = $true; $nutTakeOwn.IsEnabled = $true; $nutReset.IsEnabled = $true
    }
}

$nutDung.Add_Click({ $global:dangXuLy = $false })

$nutTakeOwn.Add_Click({
    $path = $txtDuongDan.Text
    if (!(Test-Path $path)) { return }
    Chay-LenhHeThong "takeown.exe" "/f `"$path`" /r /d y" "Chiếm quyền sở hữu"
    # Sau khi TakeOwn thì cấp quyền Admin luôn cho đồng bộ
    Chay-LenhHeThong "icacls.exe" "`"$path`" /grant administrators:F /t /q /c" "Cấp quyền Admin sau khi chiếm"
})

$nutFullControl.Add_Click({
    $path = $txtDuongDan.Text
    if (!(Test-Path $path)) { return }
    $user = $env:USERNAME
    Chay-LenhHeThong "icacls.exe" "`"$path`" /grant `"${user}:(OI)(CI)F`" /t /q /c" "Cấp Full Control cho User $user"
})

$nutReset.Add_Click({
    $path = $txtDuongDan.Text
    if (!(Test-Path $path)) { return }
    Chay-LenhHeThong "icacls.exe" "`"$path`" /reset /t /q /c" "Reset Permission về mặc định"
})

$nutCheck.Add_Click({
    $path = $txtDuongDan.Text
    if (!(Test-Path $path)) { return }
    $acl = Get-Acl $path
    $txtLog.Text = "🔍 Chủ sở hữu: $($acl.Owner)`n`nDanh sách quyền:`n"
    foreach ($access in $acl.Access) {
        $txtLog.Text += "- $($access.IdentityReference): $($access.FileSystemRights)`n"
    }
})

$CuaSo.ShowDialog() | Out-Null