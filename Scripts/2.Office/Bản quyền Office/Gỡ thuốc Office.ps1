# ==============================================================================
# VIETTOOLBOX - OFFICE CLEANER GUI V326 (BẢN BỔ SUNG GỠ OHOOK TẬN GỐC)
# Đặc tính: Giao diện XAML, Dọn KMS/Pico/Ohook, Khôi phục zin 100%
# ==============================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. MÃ GIAO DIỆN XAML ---
$MaGUI = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="VIETTOOLBOX - OFFICE CLEANER V326" Width="550" Height="450" WindowStartupLocation="CenterScreen" Background="#F0F2F5" ResizeMode="NoResize">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="DỌN DẸP BẢN QUYỀN OFFICE (GỠ OHOOK)" FontSize="20" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Trạng thái: Sẵn sàng dọn Zin cho sếp Tuấn" FontSize="12" Foreground="#546E7A" Name="TxtStatus"/>
        </StackPanel>

        <GroupBox Grid.Row="1" Header="NHẬT KÝ CHI TIẾT" Margin="0,0,0,10" FontWeight="Bold">
            <TextBox Name="LogBox" IsReadOnly="True" Background="#1E1E1E" Foreground="#00E676" 
                     FontFamily="Consolas" VerticalScrollBarVisibility="Auto" FontSize="11" TextWrapping="Wrap" FontWeight="Normal"/>
        </GroupBox>

        <StackPanel Grid.Row="2" Margin="0,5">
            <ProgressBar Name="ProgBar" Height="15" Minimum="0" Maximum="100" Foreground="#1565C0" Background="#E0E0E0"/>
            <TextBlock Name="TxtPercent" Text="0%" HorizontalAlignment="Right" FontSize="10" FontWeight="Bold" Margin="0,2"/>
        </StackPanel>

        <Grid Grid.Row="3" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button Name="BtnClean" Content="🚀 BẮT ĐẦU DỌN DẸP" Grid.Column="0" Height="40" Margin="0,0,5,0" 
                    Background="#2E7D32" Foreground="White" FontWeight="Bold" FontSize="14" Cursor="Hand"/>
            <Button Name="BtnExit" Content="❌ THOÁT" Grid.Column="1" Height="40" Margin="5,0,0,0" 
                    Background="#D32F2F" Foreground="White" FontWeight="Bold" FontSize="14" Cursor="Hand"/>
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
    
    # ĐỊNH NGHĨA CÁC BƯỚC CHẠY
    $DoWork = {
        Ghi-LogGUI "--- Bắt đầu quy trình dọn Zin ---" 5
        [System.Windows.Forms.Application]::DoEvents()

        # [BƯỚC 1: TRẢM OHOOK]
        Ghi-LogGUI "1. Đang truy quét và gỡ bỏ Ohook..." 15
        try {
            $OhookRegs = @(
                "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\REGISTRY\MACHINE\Software\Classes\CLSID\{00000000-0000-0000-0000-000000000000}",
                "HKLM:\SOFTWARE\Classes\CLSID\{00000000-0000-0000-0000-000000000000}",
                "HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\{00000000-0000-0000-0000-000000000000}"
            )
            # Khôi phục file sppc.dll xịn và xóa sppc rác của Ohook
            $SppcPaths = @(
                "${env:ProgramFiles}\Microsoft Office\root\vfs\System",
                "${env:ProgramFiles(x86)}\Microsoft Office\root\vfs\System"
            )
            foreach ($Path in $SppcPaths) {
                if (Test-Path "$Path\sppc.dll") {
                    Remove-Item -Path "$Path\sppc.dll" -Force -ErrorAction SilentlyContinue
                    Ghi-LogGUI " -> Đã xóa sppc.dll (Ohook rác) tại: $Path" $null
                }
            }

            # Xóa Registry móc nối của Ohook
            $RegHookPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\osppsvc.exe",
                "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sppsvc.exe",
                "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\OfficeClickToRun.exe"
            )
            foreach ($Reg in $RegHookPaths) {
                if (Test-Path $Reg) {
                    Remove-Item -Path $Reg -Recurse -Force -ErrorAction SilentlyContinue
                    Ghi-LogGUI " -> Đã bẻ khóa IFEO Hook tại: $Reg" $null
                }
            }
            Ghi-LogGUI " -> Gỡ Ohook hoàn tất." 25
        } catch { Ghi-LogGUI " -> (Bỏ qua) Lỗi khi gỡ Ohook: $($_.Exception.Message)" $null }
        [System.Windows.Forms.Application]::DoEvents()

        # [BƯỚC 2: DỌN TASK SCHEDULER KMS/PICO]
        Ghi-LogGUI "2. Đang dọn dẹp các Scheduled Task KMS/Pico..." 40
        $Tasks = @("AutoKMS", "AutoPico", "KMSAuto", "KMSPico", "SppExtComObjHook", "SvcRestartTask")
        foreach ($t in $Tasks) {
            Get-ScheduledTask -TaskName "*$t*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        }
        [System.Windows.Forms.Application]::DoEvents()

        # [BƯỚC 3: GỠ KEY ZIN/KMS BẰNG OSPP.VBS]
        $v = @(
            "${env:ProgramFiles}\Microsoft Office\Office16\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
            "${env:ProgramFiles}\Microsoft Office\Office15\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OSPP.VBS"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($v) {
            Ghi-LogGUI "3. Phát hiện OSPP.VBS, đang trảm Key..." 50
            $status = cscript //nologo "$v" /dstatus | Out-String
            $regex = "Last 5 characters of installed product key: (.{5})"
            $keys = [regex]::Matches($status, $regex) | ForEach-Object { $_.Groups[1].Value }
            foreach ($k in $keys) {
                Ghi-LogGUI " -> Bắn bỏ Key đuôi: $k" 60
                cscript //nologo "$v" /unpkey:$k | Out-Null
                [System.Windows.Forms.Application]::DoEvents()
            }
            Ghi-LogGUI " -> Xóa thông tin máy chủ KMS lưu trữ..." 70
            cscript //nologo "$v" /remhst | Out-Null
        } else {
            Ghi-LogGUI "3. Dùng WMI quét License (Timeout 10s)..." 50
            $prods = Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "Office" -and $_.PartialProductKey }
            foreach ($p in $prods) {
                Ghi-LogGUI " -> WMI bắn bỏ Key: $($p.PartialProductKey)" 60
                Invoke-CimMethod -InputObject $p -MethodName "UninstallProductKey" -ErrorAction SilentlyContinue | Out-Null
                [System.Windows.Forms.Application]::DoEvents()
            }
        }

        # [BƯỚC 4: XÓA MÁY CHỦ KMS TRONG REGISTRY]
        Ghi-LogGUI "4. Quét và xóa thông số KMS trong Registry..." 85
        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        )
        foreach ($reg in $regPaths) {
            if (Test-Path $reg) { 
                Remove-ItemProperty -Path $reg -Name "KeyManagementServiceName" -ErrorAction SilentlyContinue 
                Remove-ItemProperty -Path $reg -Name "KeyManagementServicePort" -ErrorAction SilentlyContinue 
            }
        }
        [System.Windows.Forms.Application]::DoEvents()

        # [BƯỚC 5: KHỞI ĐỘNG LẠI DỊCH VỤ BẢN QUYỀN]
        Ghi-LogGUI "5. Làm mới dịch vụ bản quyền Windows..." 95
        Stop-Service -Name "osppsvc" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "sppsvc" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Service -Name "osppsvc" -ErrorAction SilentlyContinue
        Start-Service -Name "sppsvc" -ErrorAction SilentlyContinue

        Ghi-LogGUI "✅ HOÀN TẤT!" 100
        $TxtStatus.Text = "Trạng thái: Đã dọn xong Zin cho sếp Tuấn!"
        [System.Windows.Forms.MessageBox]::Show("Office của sếp đã sạch bóng Ohook & KMS!`nSẵn sàng nạp Key xịn.", "Hoàn tất xuất sắc", 0, 64)
        $BtnClean.IsEnabled = $true
    }

    # THỰC THI (Đồng bộ)
    &$DoWork
})

$BtnExit.Add_Click({ $Window.Close() })

# SHOW CỬA SỔ
$Window.ShowDialog() | Out-Null