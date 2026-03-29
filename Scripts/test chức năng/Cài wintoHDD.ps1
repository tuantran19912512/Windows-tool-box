# ==============================================================================
# Tên công cụ: VIETTOOLBOX MASTER (V28.35) - PHIÊN BẢN CHIẾN THẦN
# Đặc trị: Hiển thị phân vùng, Ép Boot RAMDISK 100%, Bơm Drivers & Apps
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ (GIỮ AN TOÀN DỮ LIỆU) ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Other = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Other) {
        $Path = Join-Path ($Other.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $Path)) { New-Item $Path -Type Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $Path -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Path\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN XAML CHUYÊN NGHIỆP ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Master V28.35" Width="750" Height="850" Background="#F3F4F6" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border BorderBrush="#D1D5DB" BorderThickness="1">
        <StackPanel Margin="25">
            <TextBlock Text="VIETTOOLBOX - HỆ THỐNG CÀI WIN TỰ ĐỘNG" FontSize="22" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="0,0,0,20"/>
            
            <TextBlock Text="1. CHỌN BỘ CÀI (WIM/ISO/ESD):" FontWeight="Bold" Margin="0,0,0,5"/>
            <Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBox Name="TxtFile" Height="30" VerticalContentAlignment="Center" IsReadOnly="True" Padding="5,0" Background="White"/>
                <Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt File" Width="100" Margin="5,0,0,0" Background="#E5E7EB" FontWeight="Bold"/></Grid>

            <TextBlock Text="2. PHIÊN BẢN MUỐN CÀI:" FontWeight="Bold" Margin="0,0,0,5"/>
            <ComboBox Name="ComboEdition" Height="30" Margin="0,0,0,20" Background="White"/>

            <TextBlock Text="3. THÔNG TIN PHÂN VÙNG HỆ THỐNG:" FontWeight="Bold" Margin="0,0,0,5"/>
            <Border BorderBrush="#9CA3AF" BorderThickness="1" Height="100" Background="White" Margin="0,0,0,20">
                <Grid Margin="10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="1*"/><ColumnDefinition Width="1*"/></Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" VerticalAlignment="Center">
                        <TextBlock Text="Hệ thống (EFI/MSR):" Foreground="#6B7280" FontSize="12"/>
                        <TextBlock Name="TxtEFI" Text="Đang quét..." FontSize="16" FontWeight="Bold" Foreground="#0369A1"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Phân vùng cài Win (C:):" Foreground="#6B7280" FontSize="12"/>
                        <TextBlock Name="TxtOS" Text="Đang quét..." FontSize="16" FontWeight="Bold" Foreground="#B91C1C"/>
                    </StackPanel>
                </Grid>
            </Border>

            <TextBlock Text="4. TIẾN TRÌNH THỰC HIỆN:" FontWeight="Bold" Margin="0,0,0,5"/>
            <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="25" Foreground="#10B981" Background="#E5E7EB"/>
            <TextBlock Name="TxtStep" Text="Chờ lệnh sếp..." HorizontalAlignment="Center" Margin="0,5,0,20" Foreground="#374151" FontWeight="SemiBold"/>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,20">
                <CheckBox Name="OptDriver" Content="Bơm Drivers" IsChecked="True" Margin="15,0" FontWeight="Bold"/>
                <CheckBox Name="OptApps" Content="Cài Apps Silent" IsChecked="True" Margin="15,0" FontWeight="Bold"/>
            </StackPanel>

            <Button Name="BtnRun" Content="🚀 BẮT ĐẦU QUÁ TRÌNH" Height="65" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="18" Cursor="Hand"/>
        </StackPanel>
    </Border>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

# --- 3. ÁNH XẠ BIẾN & QUÉT PHÂN VÙNG ---
$txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile"); $comboEdition = $window.FindName("ComboEdition")
$btnRun = $window.FindName("BtnRun"); $progBar = $window.FindName("ProgBar"); $txtStep = $window.FindName("TxtStep")
$txtEFI = $window.FindName("TxtEFI"); $txtOS = $window.FindName("TxtOS")
$optDriver = $window.FindName("OptDriver"); $optApps = $window.FindName("OptApps")

function Get-DiskInfo {
    $osPart = Get-Partition -DriveLetter C -ErrorAction SilentlyContinue
    if ($osPart) {
        $txtOS.Text = "C: ($([math]::Round($osPart.Size/1GB,1)) GB)"
        $efiPart = Get-Partition -DiskNumber $osPart.DiskNumber | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.IsActive } | Select-Object -First 1
        if ($efiPart) { $txtEFI.Text = "Disk $($efiPart.DiskNumber) - Part $($efiPart.PartitionNumber)" } else { $txtEFI.Text = "Không tìm thấy!" }
    }
}
Get-DiskInfo

function Log ($val, $text) { $progBar.Value = $val; $txtStep.Text = $text; [System.Windows.Forms.Application]::DoEvents() }

# --- 4. CHỌN BỘ CÀI ---
$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtFile.Text = $fd.FileName; Log 0 "Đang nạp danh sách Index..."
        $images = Get-WindowsImage -ImagePath $txtFile.Text -ErrorAction SilentlyContinue
        if (!$images) { $m = Mount-DiskImage $txtFile.Text -PassThru; $d = ($m|Get-Volume).DriveLetter; $w = "$($d):\sources\install.wim"; if(!(Test-Path $w)){$w="$($d):\sources\install.esd"}; $images = Get-WindowsImage -ImagePath $w; Dismount-DiskImage $txtFile.Text | Out-Null }
        $comboEdition.Items.Clear()
        $images | ForEach-Object {[void]$comboEdition.Items.Add("Index $($_.ImageIndex): $($_.ImageName)")}; $comboEdition.SelectedIndex=0; Log 0 "Sẵn sàng."
    }
})

# --- 5. LÕI THI TRIỂN (ÉP BOOT TUYỆT ĐỐI) ---
$btnRun.Add_Click({
    if (!$txtFile.Text) { return }
    $btnRun.IsEnabled = $false
    $idx = [int]([regex]::Match($comboEdition.Text, "Index (\d+)").Groups[1].Value); $path = $txtFile.Text
    $folderCai = Split-Path $path; $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if (!(Test-Path $tmp)) { New-Item $tmp -Type Directory -Force }

    # BƯỚC 1: DI CHUYỂN
    Log 15 "Bước 1/5: Đang di chuyển bộ cài vào vùng an toàn..."
    if ($path.EndsWith(".iso")) {
        Mount-DiskImage $path -PassThru | Out-Null
        $drive = (Get-DiskImage $path | Get-Volume).DriveLetter
        $src = if (Test-Path "$($drive):\sources\install.wim") { "$($drive):\sources\install.wim" } else { "$($drive):\sources\install.esd" }
        Copy-Item $src "$tmp\install.wim" -Force; Dismount-DiskImage $path | Out-Null
    } else { Copy-Item $path "$tmp\install.wim" -Force }

    # BƯỚC 2: SĂN BOOT
    Log 35 "Bước 2/5: Đang săn tìm môi trường Boot (WinRE/Local)..."
    reagentc /disable | Out-Null
    if (Test-Path "C:\Windows\System32\Recovery\Winre.wim") { Copy-Item "C:\Windows\System32\Recovery\Winre.wim" "$tmp\boot.wim" -Force }
    elseif (Test-Path "$folderCai\boot.wim") { Copy-Item "$folderCai\boot.wim" "$tmp\boot.wim" -Force }
    else { [System.Windows.MessageBox]::Show("Sếp ơi quên vứt file boot.wim vào rồi!", "Lỗi"); $btnRun.IsEnabled = $true; return }

    # BƯỚC 3: MOUNT & INJECT
    Log 55 "Bước 3/5: Đang 'mổ bụng' Boot để bơm thuốc (Drivers/Apps)..."
    $mDir = "$tmp\Mount"; if (!(Test-Path $mDir)) { New-Item $mDir -Type Directory }
    dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:"$mDir" /Quiet
    if ($optDriver.IsChecked -and (Test-Path "$folderCai\Drivers")) { dism /Image:"$mDir" /Add-Driver /Driver:"$folderCai\Drivers" /Recurse /ForceUnsigned /Quiet }
    if ($optApps.IsChecked -and (Test-Path "$folderCai\Apps")) { xcopy "$folderCai\Apps" "$mDir\Apps\" /e /y /i /q }

    # BƯỚC 4: LỆNH THỰC THI WINPE
    Log 75 "Bước 4/5: Đang cấu hình kịch bản tự động cài Win..."
    $cmd = "@echo off`r`nwpeinit`r`n"
    $cmd += "for %%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%i:\VietToolbox_Setup\install.wim`" set `"W=%%i:\VietToolbox_Setup\install.wim`"`r`n"
    $cmd += "for %%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%j:\Windows\System32\cmd.exe`" if not exist `"%%j:\VietToolbox_Setup`" set `"OS=%%j:`"`r`n"
    $cmd += "format %OS% /fs:ntfs /q /y`r`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$idx /ApplyDir:%OS%\`r`nbcdboot %OS%\Windows /f ALL`r`n"
    $cmd += "md %OS%\Windows\Setup\Scripts`r`n(echo @echo off`r`nfor %%f in (X:\Apps\*.exe) do start /wait %%f /S /silent /install`r`nrd /s /q `"$($safe.DriveLetter):\VietToolbox_Setup`") > %OS%\Windows\Setup\Scripts\SetupComplete.cmd`r`nwpeutil reboot"
    Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
    dism /Unmount-Image /MountDir:"$mDir" /Commit /Quiet

    # BƯỚC 5: ÉP BOOT (QUAN TRỌNG NHẤT)
    Log 95 "Bước 5/5: Đang cưỡng chế hệ thống phải Boot vào Tool..."
    copy /y C:\Windows\System32\boot.sdi "$tmp\boot.sdi"
    bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
    bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
    $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
    bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id systemroot \windows | Out-Null; bcdedit /set $id winpe yes | Out-Null; bcdedit /set $id detecthal yes | Out-Null
    
    # Lệnh ép Boot tầng 2
    bcdedit /timeout 30 | Out-Null
    bcdedit /displayorder $id /addfirst | Out-Null
    bcdedit /bootsequence $id /addfirst | Out-Null
    bcdedit /default $id | Out-Null # Ép làm mặc định tạm thời

    Log 100 "✅ ĐÃ THI TRIỂN XONG! SẾP RESTART ĐỂ HƯỞNG THÀNH QUẢ."
    [System.Windows.MessageBox]::Show("Mọi thứ đã sẵn sàng! Khi Restart máy, nếu nó hiện Menu Boot, sếp chọn 'VietToolbox_Setup' nhé. Nếu nó tự chạy thì càng tốt!", "Thành công")
    $btnRun.IsEnabled = $true
})

$window.ShowDialog() | Out-Null