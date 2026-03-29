# ==============================================================================
# Tên công cụ: VIETTOOLBOX MASTER (V28.40) - PHIÊN BẢN CHUẨN CƠM MẸ NẤU
# Đặc trị: Fix lỗi 'copy /y', Hiện phân vùng EFI/OS, Ép Boot RAMDISK 100%
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ SANG Ổ KHÁC C: ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Other = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Other) {
        $Path = Join-Path ($Other.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $Path)) { New-Item $Path -Type Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $Path -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Path\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN XAML ĐẲNG CẤP ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Master V28.40" Width="750" Height="820" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <Border BorderBrush="#D1D5DB" BorderThickness="1">
        <StackPanel Margin="25">
            <TextBlock Text="VIETTOOLBOX - PROFESSIONAL REINSTALLER" FontSize="20" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="0,0,0,20"/>
            
            <TextBlock Text="1. CHỌN BỘ CÀI (WIM/ISO/ESD):" FontWeight="Bold" Margin="0,0,0,5"/>
            <Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBox Name="TxtFile" Height="30" VerticalContentAlignment="Center" IsReadOnly="True" Padding="5,0"/>
                <Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt File" Width="100" Margin="5,0,0,0" FontWeight="Bold"/></Grid>

            <TextBlock Text="2. PHÂN VÙNG HỆ THỐNG PHÁT HIỆN ĐƯỢC:" FontWeight="Bold" Margin="0,0,0,5"/>
            <UniformGrid Columns="2" Margin="0,0,0,20">
                <Border BorderBrush="#9CA3AF" BorderThickness="1" Background="White" Margin="0,0,5,0" Padding="10">
                    <StackPanel><TextBlock Text="Hệ thống (EFI):" FontSize="11" Foreground="#6B7280"/><TextBlock Name="TxtEFI" Text="..." FontSize="15" FontWeight="Bold" Foreground="#0369A1"/></StackPanel>
                </Border>
                <Border BorderBrush="#9CA3AF" BorderThickness="1" Background="White" Margin="5,0,0,0" Padding="10">
                    <StackPanel><TextBlock Text="Ổ cài Win (C:):" FontSize="11" Foreground="#6B7280"/><TextBlock Name="TxtOS" Text="..." FontSize="15" FontWeight="Bold" Foreground="#B91C1C"/></StackPanel>
                </Border>
            </UniformGrid>

            <TextBlock Text="3. TIẾN TRÌNH THỰC HIỆN:" FontWeight="Bold" Margin="0,0,0,5"/>
            <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="25" Foreground="#10B981"/>
            <TextBlock Name="TxtStep" Text="Đang chờ sếp..." HorizontalAlignment="Center" Margin="0,5,0,20" FontWeight="SemiBold"/>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,20">
                <CheckBox Name="OptDriver" Content="Bơm Drivers" IsChecked="True" Margin="15,0" FontWeight="Bold"/>
                <CheckBox Name="OptApps" Content="Cài Apps" IsChecked="True" Margin="15,0" FontWeight="Bold"/>
            </StackPanel>

            <Button Name="BtnRun" Content="🚀 BẮT ĐẦU CÀI ĐẶT" Height="65" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="18" Cursor="Hand"/>
        </StackPanel>
    </Border>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

# --- 3. LOGIC XỬ LÝ ---
$txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile")
$btnRun = $window.FindName("BtnRun"); $progBar = $window.FindName("ProgBar"); $txtStep = $window.FindName("TxtStep")
$txtEFI = $window.FindName("TxtEFI"); $txtOS = $window.FindName("TxtOS")
$optDriver = $window.FindName("OptDriver"); $optApps = $window.FindName("OptApps")

function Log ($val, $text) { $progBar.Value = $val; $txtStep.Text = $text; [System.Windows.Forms.Application]::DoEvents() }

# Quét ổ cứng
$osPart = Get-Partition -DriveLetter C -ErrorAction SilentlyContinue
if ($osPart) {
    $txtOS.Text = "C: ($([math]::Round($osPart.Size/1GB,1)) GB)"
    $efi = Get-Partition -DiskNumber $osPart.DiskNumber | Where-Object {$_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.IsActive} | Select-Object -First 1
    $txtEFI.Text = if($efi){ "Disk $($efi.DiskNumber) - EFI" } else { "Không thấy!" }
}

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") { $txtFile.Text = $fd.FileName }
})

$btnRun.Add_Click({
    if (!$txtFile.Text) { return }
    $btnRun.IsEnabled = $false
    $path = $txtFile.Text; $folderCai = Split-Path $path
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if (!(Test-Path $tmp)) { New-Item $tmp -Type Directory -Force }

    # BƯỚC 1: DI CHUYỂN
    Log 20 "Bước 1/4: Đang di chuyển bộ cài (install.wim)..."
    if ($path.EndsWith(".iso")) {
        Mount-DiskImage $path -PassThru | Out-Null
        $drive = (Get-DiskImage $path | Get-Volume).DriveLetter
        $src = if (Test-Path "$($drive):\sources\install.wim") { "$($drive):\sources\install.wim" } else { "$($drive):\sources\install.esd" }
        Copy-Item $src "$tmp\install.wim" -Force; Dismount-DiskImage $path | Out-Null
    } else { Copy-Item $path "$tmp\install.wim" -Force }

    # BƯỚC 2: CHUẨN BỊ BOOT (FIX LỖI MẤT WINRE)
    Log 40 "Bước 2/4: Đang chuẩn bị môi trường Boot RAMDISK..."
    $bootWim = "$tmp\boot.wim"
    reagentc /disable | Out-Null
    if (Test-Path "C:\Windows\System32\Recovery\Winre.wim") { 
        Copy-Item "C:\Windows\System32\Recovery\Winre.wim" $bootWim -Force 
    } elseif (Test-Path "$folderCai\boot.wim") { 
        Copy-Item "$folderCai\boot.wim" $bootWim -Force 
    } elseif (Test-Path "$PSScriptRoot\boot.wim") {
        Copy-Item "$PSScriptRoot\boot.wim" $bootWim -Force
    } else {
        [System.Windows.MessageBox]::Show("Sếp ơi, máy mất WinRE và em cũng không thấy file boot.wim sếp mang theo. Bỏ file boot.wim cạnh bộ cài đi sếp!", "Lỗi")
        $btnRun.IsEnabled = $true; return
    }

    # BƯỚC 3: CẤU HÌNH LỆNH TỰ ĐỘNG (INJECT)
    Log 70 "Bước 3/4: Đang bơm Drivers & cấu hình kịch bản..."
    $mDir = "$tmp\Mount"; if (!(Test-Path $mDir)) { New-Item $mDir -Type Directory }
    dism /Mount-Image /ImageFile:$bootWim /Index:1 /MountDir:$mDir /Quiet
    
    if ($optDriver.IsChecked -and (Test-Path "$folderCai\Drivers")) { dism /Image:$mDir /Add-Driver /Driver:"$folderCai\Drivers" /Recurse /ForceUnsigned /Quiet }
    if ($optApps.IsChecked -and (Test-Path "$folderCai\Apps")) { xcopy "$folderCai\Apps" "$mDir\Apps\" /e /y /i /q }

    $cmd = "@echo off`r`nwpeinit`r`n"
    $cmd += "for %%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%i:\VietToolbox_Setup\install.wim`" set `"W=%%i:\VietToolbox_Setup\install.wim`"`r`n"
    $cmd += "for %%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%j:\Windows\System32\cmd.exe`" if not exist `"%%j:\VietToolbox_Setup`" set `"OS=%%j:`"`r`n"
    $cmd += "format %OS% /fs:ntfs /q /y`r`ndism /Apply-Image /ImageFile:`"%W%`" /Index:1 /ApplyDir:%OS%\`r`nbcdboot %OS%\Windows /f ALL`r`n"
    $cmd += "md %OS%\Windows\Setup\Scripts`r`n(echo @echo off`r`nfor %%f in (X:\Apps\*.exe) do start /wait %%f /S /silent /install`r`nrd /s /q `"$($safe.DriveLetter):\VietToolbox_Setup`") > %OS%\Windows\Setup\Scripts\SetupComplete.cmd`r`nwpeutil reboot"
    Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
    dism /Unmount-Image /MountDir:$mDir /Commit /Quiet

    # BƯỚC 4: ÉP BOOT (FIX LỖI HÌNH 3)
    Log 90 "Bước 4/4: Đang cưỡng chế hệ thống nạp Boot RAMDISK..."
    # Dùng Copy-Item chuẩn PowerShell (Không dùng copy /y nữa)
    Copy-Item "C:\Windows\System32\boot.sdi" "$tmp\boot.sdi" -Force
    
    bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
    bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
    $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
    bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id systemroot \windows | Out-Null; bcdedit /set $id winpe yes | Out-Null
    bcdedit /bootsequence $id /addfirst | Out-Null
    bcdedit /timeout 30 | Out-Null

    Log 100 "✅ ĐÃ XONG! SẾP RESTART MÁY NGAY ĐI."
    [System.Windows.MessageBox]::Show("Xong rồi sếp ơi! Restart máy, nếu nó hiện Menu thì chọn 'VietToolbox_Setup' là xong.", "Thành công")
    $btnRun.IsEnabled = $true
})

$window.ShowDialog() | Out-Null