# ==============================================================================
# VIETTOOLBOX V37.2 - FAST INJECT (TỐI ƯU TỐC ĐỘ NẠP LÕI - REBUILD)
# Chức năng: Mount WinRE thay vì Update để tăng tốc, Hiện tiến trình nạp lõi.
# ==============================================================================

# Yêu cầu quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# Ép giao thức mạng TLS 1.2 để tải Wimlib không bị lỗi trên máy cũ
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- GIAO DIỆN ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V37.2 - Fast Inject" Height="700" Width="800" 
        WindowStartupLocation="CenterScreen" Background="#050505">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="TRIỂN KHAI WINDOWS SIÊU TỐC" FontSize="34" FontWeight="Black" Foreground="#00adb5" HorizontalAlignment="Center"/>
            <TextBlock Text="FIX LỖI ĐỨNG IM - TỐI ƯU NẠP LÕI NHƯ WINTOHDD" FontSize="11" Foreground="#555" HorizontalAlignment="Center"/>
        </StackPanel>
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions><ColumnDefinition Width="1.2*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <GroupBox Header=" 1. NGUỒN CÀI ĐẶT " Foreground="#00adb5" BorderBrush="#222" Margin="0,0,10,0" FontSize="14" FontWeight="Bold">
                <StackPanel Margin="15">
                    <TextBlock Text="File cài đặt (.wim, .iso, .esd):" Foreground="#AAA" Margin="0,0,0,5"/>
                    <Grid Margin="0,0,0,15">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                        <TextBox Name="txtPath" IsReadOnly="True" Height="35" Background="#111" Foreground="#00adb5" VerticalContentAlignment="Center" Padding="5,0"/>
                        <Button Name="btnBrowse" Grid.Column="1" Content="CHỌN" Background="#00adb5" Foreground="White" FontWeight="Bold" Margin="5,0,0,0"/>
                    </Grid>
                    <TextBlock Text="Index:" Foreground="#AAA" Margin="0,0,0,5"/>
                    <ComboBox Name="cmbIndex" Height="35" Background="#111" Foreground="#00adb5"/>
                </StackPanel>
            </GroupBox>
            <GroupBox Grid.Column="1" Header=" 2. TÙY CHỌN " Foreground="#E91E63" BorderBrush="#222" Margin="10,0,0,0" FontSize="14" FontWeight="Bold">
                <StackPanel Margin="20">
                    <CheckBox Name="chkDriver" Content="Nạp Driver máy cũ" Foreground="#00adb5" IsChecked="True" FontSize="13" Margin="0,0,0,18"/>
                    <CheckBox Name="chkBitLocker" Content="Tắt BitLocker" Foreground="#FFB300" IsChecked="True" FontSize="13" Margin="0,0,0,18"/>
                    <CheckBox Name="chkOOBE" Content="Bypass All" Foreground="White" IsChecked="True" FontSize="13" Margin="0,0,0,18"/>
                    <CheckBox Name="chkAnydesk" Content="Auto AnyDesk" Foreground="#4CAF50" IsChecked="True" FontSize="13"/>
                </StackPanel>
            </GroupBox>
        </Grid>
        <StackPanel Grid.Row="2" Margin="0,20,0,0">
            <ProgressBar Name="pgBar" Height="15" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,10"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Đang chờ..." Foreground="#888" HorizontalAlignment="Center" FontSize="13" FontWeight="Bold"/>
            <Button Name="btnStart" Content="BẮT ĐẦU CÀI ĐẶT" Height="60" Background="#D32F2F" Foreground="White" FontSize="20" FontWeight="Black" Margin="0,10,0,0" IsEnabled="False"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Nạp XAML
$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

# Gán biến UI
$txtPath = $CuaSo.FindName("txtPath"); $btnBrowse = $CuaSo.FindName("btnBrowse"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$lblStatus = $CuaSo.FindName("lblStatus"); $pgBar = $CuaSo.FindName("pgBar"); $btnStart = $CuaSo.FindName("btnStart")
$chkDriver = $CuaSo.FindName("chkDriver"); $chkBitLocker = $CuaSo.FindName("chkBitLocker")
$chkOOBE = $CuaSo.FindName("chkOOBE"); $chkAnydesk = $CuaSo.FindName("chkAnydesk")

function Update-UI { [System.Windows.Forms.Application]::DoEvents() }

# --- SỰ KIỆN NÚT CHỌN FILE ---
$btnBrowse.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.wim;*.iso;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtPath.Text = $fd.FileName; $cmbIndex.Items.Clear()
        try {
            $path = $fd.FileName
            if ($path.EndsWith(".iso")) {
                $m = Mount-DiskImage -ImagePath $path -PassThru; $dv = ($m | Get-Volume).DriveLetter
                $w = "$dv`:\sources\install.wim"; if (!(Test-Path $w)) { $w = "$dv`:\sources\install.esd" }
                (Get-WindowsImage -ImagePath $w) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
                Dismount-DiskImage -ImagePath $path | Out-Null
            } else { 
                (Get-WindowsImage -ImagePath $path) | ForEach-Object { $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") } 
            }
            $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true
        } catch { 
            [System.Windows.MessageBox]::Show("Lỗi khi đọc file Image: $_")
        }
    }
})

# --- SỰ KIỆN NÚT BẮT ĐẦU ---
$btnStart.Add_Click({
    # Validate dữ liệu
    if ([string]::IsNullOrWhiteSpace($txtPath.Text) -or $null -eq $cmbIndex.SelectedItem) {
        [System.Windows.MessageBox]::Show("Vui lòng chọn file cài đặt và phiên bản Windows (Index) trước khi bắt đầu!")
        return
    }

    $btnStart.IsEnabled = $false; 
    $VietBoot = "C:\VietBoot"; 
    if (!(Test-Path $VietBoot)) { New-Item $VietBoot -ItemType Directory -Force | Out-Null }
    
    $SelPath = $txtPath.Text; 
    $SelIdx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()

    try {
        # [1] KIỂM TRA PHÂN VÙNG EFI
        $pgBar.Value = 10; $lblStatus.Text = "Kiểm tra Boot và phân vùng..."; Update-UI
        if (!(Get-Partition | Where-Object { $_.IsSystem })) {
            $disk = Get-Disk | Where-Object { $_.Number -eq 0 }
            "select disk $($disk.Number)`nclean`nconvert gpt`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S`ncreate partition msr size=16`ncreate partition primary`nformat quick fs=ntfs label='Windows'`nassign letter=C" | diskpart | Out-Null
        }
        
        # [2] TẮT BITLOCKER
        $pgBar.Value = 20; $lblStatus.Text = "Giải mã BitLocker..."; Update-UI
        manage-bde -off C: | Out-Null

        # [3] COPY BỘ CÀI VÀO VIETBOOT
        $pgBar.Value = 40; $lblStatus.Text = "Nạp bộ cài vào VietBoot..."; Update-UI
        $WimName = [System.IO.Path]::GetFileName($SelPath); $FinalWim = "$VietBoot\$WimName"
        if (!(Test-Path $FinalWim)) { Copy-Item $SelPath $FinalWim -Force }

        # [4] LẤY WINRE.WIM TỪ HỆ THỐNG
        $pgBar.Value = 60; $lblStatus.Text = "Đang chuẩn bị lõi cứu hộ WinRE..."; Update-UI
        $BootWim = "$VietBoot\boot.wim"
        
        # Tắt ReAgentc để file WinRE.wim hiện hình
        reagentc /disable | Out-Null
        if (Test-Path "C:\Windows\System32\Recovery\WinRE.wim") {
            Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" $BootWim -Force
        } else {
            reagentc /enable | Out-Null 
            throw "Hệ điều hành hiện tại bị thiếu lõi Recovery (WinRE.wim)!"
        }
        reagentc /enable | Out-Null
        
        # [5] TẠO KỊCH BẢN SETUP & STARTNET
        $Conf = "$VietBoot\Conf"; New-Item $Conf -ItemType Directory -Force | Out-Null
        "@echo off`nmanage-bde -off C:`nnet accounts /maxpwage:unlimited`nbcdedit /timeout 0`nrd /s /q `"C:\VietBoot`"`ndel `"%~f0`"" | Out-File "$Conf\SetupComplete.cmd" -Encoding ASCII
        
        $sn = "@echo off`nwpeinit`nfor %%i in (C D E F G H I J K L M N O P) do (if exist `"%%i:\VietBoot\$WimName`" set `"W=%%i:\VietBoot\$WimName`")`nfor /d %%a in (C:\*) do if /i not `"%%~nxa`"==`"VietBoot`" rd /s /q `"%%a`"`ndel /f /q C:\*.*`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$SelIdx /ApplyDir:C:\`nbcdboot C:\Windows /s C: /f ALL`nwpeutil reboot"
        $sn | Out-File "$Conf\s.cmd" -Encoding ASCII

        # [6] TẢI VÀ CHUẨN BỊ WIMLIB
        $pgBar.Value = 75; $lblStatus.Text = "Kiểm tra công cụ Wimlib..."; Update-UI
        $exeW = "$VietBoot\wimlib-imagex.exe" 
        if (!(Test-Path $exeW)) { 
            Start-BitsTransfer -Source "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip" -Destination "$VietBoot\w.zip"
            Expand-Archive "$VietBoot\w.zip" "$VietBoot\wim" -Force
            # Lấy cả EXE và DLL
            Copy-Item "$VietBoot\wim\*\wimlib-imagex.exe" $exeW -Force
            Copy-Item "$VietBoot\wim\*\libwim-15.dll" "$VietBoot\libwim-15.dll" -Force
        }
        
        # [7] TIÊM LÕI VÀO BOOT.WIM BẰNG WIMLIB
        $pgBar.Value = 85; $lblStatus.Text = "Đang tiêm kịch bản vào lõi (Xem cửa sổ CMD)..."; Update-UI
        $T = "$VietBoot\t.txt"
        "add `"$Conf\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$Conf\s.cmd`" `"\Windows\System32\startnet.cmd`"" | Out-File $T -Encoding utf8
        
        # Chạy cửa sổ Normal để xem tiến trình
        Start-Process $exeW -ArgumentList "update `"$BootWim`" 1 < `"$T`"" -Wait -WindowStyle Normal

        # [8] CẤU HÌNH BOOT VÀ KHỞI ĐỘNG LẠI
        $pgBar.Value = 100; $lblStatus.Text = "Hoàn tất! Hệ thống chuẩn bị khởi động lại..."; Update-UI
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$VietBoot\boot.sdi" -Force
        
        $ram = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $ram /d "VB" /device | Out-Null
        bcdedit /set $ram ramdisksdidevice partition=C: | Out-Null
        bcdedit /set $ram ramdisksdipath "\VietBoot\boot.sdi" | Out-Null
        $os = "{$( [guid]::NewGuid().ToString() )}"; bcdedit /create $os /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $os device "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os osdevice "ramdisk=[C:]\VietBoot\boot.wim,$ram" | Out-Null
        bcdedit /set $os winpe yes | Out-Null
        bcdedit /displayorder $os /addfirst | Out-Null; bcdedit /default $os | Out-Null; bcdedit /timeout 0 | Out-Null
        
        Start-Sleep -Seconds 2
        Restart-Computer -Force

    } catch { 
        [System.Windows.MessageBox]::Show("Có lỗi xảy ra: $_")
        $btnStart.IsEnabled = $true 
        $lblStatus.Text = "Lỗi! Đã hủy tác vụ."
    }
})

$CuaSo.ShowDialog() | Out-Null