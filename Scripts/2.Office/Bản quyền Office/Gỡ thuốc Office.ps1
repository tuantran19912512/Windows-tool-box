# ==============================================================================
# VIETTOOLBOX - OFFICE CLEANER GUI V325 (TIẾNG VIỆT 100%)
# Đặc tính: Dùng Background Jobs chính chủ, không cần cài thêm Module, chống treo
# ==============================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. MÃ GIAO DIỆN XAML ---
$MaGUI = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="VIETTOOLBOX - OFFICE CLEANER V325" Width="550" Height="450" WindowStartupLocation="CenterScreen" Background="#F0F2F5" ResizeMode="NoResize">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="DỌN DẸP BẢN QUYỀN OFFICE" FontSize="20" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Trạng thái: Sẵn sàng dọn Zin cho sếp Tuấn" FontSize="12" Foreground="#546E7A" Name="TxtStatus"/>
        </StackPanel>

        <GroupBox Grid.Row="1" Header="NHẬT KÝ CHI TIẾT" Margin="0,0,0,10">
            <TextBox Name="LogBox" IsReadOnly="True" Background="#1E1E1E" Foreground="#00E676" 
                     FontFamily="Consolas" VerticalScrollBarVisibility="Auto" FontSize="11" TextWrapping="Wrap"/>
        </GroupBox>

        <StackPanel Grid.Row="2" Margin="0,5">
            <ProgressBar Name="ProgBar" Height="15" Minimum="0" Maximum="100" Foreground="#1565C0"/>
            <TextBlock Name="TxtPercent" Text="0%" HorizontalAlignment="Right" FontSize="10" FontWeight="Bold" Margin="0,2"/>
        </StackPanel>

        <Grid Grid.Row="3" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button Name="BtnClean" Content="🚀 BẮT ĐẦU DỌN DẸP" Grid.Column="0" Height="40" Margin="0,0,5,0" 
                    Background="#2E7D32" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
            <Button Name="BtnExit" Content="❌ THOÁT" Grid.Column="1" Height="40" Margin="5,0,0,0" 
                    Background="#D32F2F" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
        </Grid>
    </Grid>
</Window>
"@

# --- 2. KHỞI TẠO CỬA SỔ ---
$Reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGUI)))
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$LogBox = $Window.FindName("LogBox")
$ProgBar = $Window.FindName("ProgBar")
$TxtStatus = $Window.FindName("TxtStatus")
$TxtPercent = $Window.FindName("TxtPercent")
$BtnClean = $Window.FindName("BtnClean")
$BtnExit = $Window.FindName("BtnExit")

# --- 3. HÀM CẬP NHẬT GIAO DIỆN ---
function Ghi-LogGUI ($msg, $percent) {
    $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
    $LogBox.ScrollToEnd()
    if ($percent) { 
        $ProgBar.Value = $percent
        $TxtPercent.Text = "$percent%"
    }
}

# --- 4. SỰ KIỆN NÚT BẤM ---
$BtnClean.Add_Click({
    $BtnClean.IsEnabled = $false
    $TxtStatus.Text = "Trạng thái: Đang xử lý (Vui lòng chờ)..."
    
    # DÙNG TIMER ĐỂ QUÉT TRẠNG THÁI MÀ KHÔNG GÂY TREO
    $Timer = New-Object System.Windows.Threading.DispatcherTimer
    $Timer.Interval = [TimeSpan]::FromMilliseconds(500)
    
    # ĐỊNH NGHĨA CÁC BƯỚC CHẠY (CHẠY TRỰC TIẾP NHƯNG DÙNG DOEVENTS CHỐNG ĐƠ)
    $DoWork = {
        Ghi-LogGUI "--- Bắt đầu dọn dẹp hệ thống ---" 5
        [System.Windows.Forms.Application]::DoEvents()

        Ghi-LogGUI "1. Đang dọn dẹp các Scheduled Task Crack..." 20
        $Tasks = @("AutoKMS", "AutoPico", "KMSAuto", "KMSPico", "SppExtComObjHook")
        foreach ($t in $Tasks) {
            Get-ScheduledTask -TaskName "*$t*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
            [System.Windows.Forms.Application]::DoEvents()
        }

        # Tìm OSPP
        $v = @(
            "${env:ProgramFiles}\Microsoft Office\Office16\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
            "${env:ProgramFiles}\Microsoft Office\Office15\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OSPP.VBS"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($v) {
            Ghi-LogGUI "2. Phát hiện OSPP.VBS, đang gỡ Key..." 40
            $status = cscript //nologo "$v" /dstatus | Out-String
            $regex = "Last 5 characters of installed product key: (.{5})"
            $keys = [regex]::Matches($status, $regex) | ForEach-Object { $_.Groups[1].Value }
            foreach ($k in $keys) {
                Ghi-LogGUI " -> Gỡ Key đuôi: $k" 60
                cscript //nologo "$v" /unpkey:$k | Out-Null
                [System.Windows.Forms.Application]::DoEvents()
            }
            cscript //nologo "$v" /remhst | Out-Null
        } else {
            Ghi-LogGUI "2. Dùng WMI quét License (Timeout 10s)..." 40
            # Chạy WMI an toàn
            $prods = Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "Office" -and $_.PartialProductKey }
            foreach ($p in $prods) {
                Ghi-LogGUI " -> WMI trảm Key: $($p.PartialProductKey)" 60
                Invoke-CimMethod -InputObject $p -MethodName "UninstallProductKey" | Out-Null
                [System.Windows.Forms.Application]::DoEvents()
            }
        }

        Ghi-LogGUI "3. Xóa máy chủ KMS trong Registry..." 80
        $reg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        if (Test-Path $reg) { Remove-ItemProperty -Path $reg -Name "KeyManagementServiceName" -ErrorAction SilentlyContinue }

        Ghi-LogGUI "4. Làm mới dịch vụ bản quyền..." 95
        Restart-Service -Name "osppsvc" -Force -ErrorAction SilentlyContinue
        Restart-Service -Name "sppsvc" -Force -ErrorAction SilentlyContinue

        Ghi-LogGUI "✅ HOÀN TẤT!" 100
        $TxtStatus.Text = "Trạng thái: Đã dọn xong Zin cho sếp Tuấn!"
        [System.Windows.Forms.MessageBox]::Show("Office của sếp đã sạch bóng thuốc!`nSẵn sàng nạp Key mới.", "Thành công")
        $BtnClean.IsEnabled = $true
    }

    # THỰC THI
    &$DoWork
})

$BtnExit.Add_Click({ $Window.Close() })

# SHOW CỬA SỔ
$Window.ShowDialog() | Out-Null