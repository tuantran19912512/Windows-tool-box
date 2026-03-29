# ==============================================================================
# VIETTOOLBOX MASTER (V30.0) - PHIÊN BẢN FULL GIÁP CHO ANH EM THỢ
# Đặc trị: Hiện Map phân vùng, Tích chọn nạp Drivers/Apps, Ép Boot RAMDISK 100%
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ SANG Ổ D/E ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Target = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Target) {
        $TPath = Join-Path ($Target.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $TPath)) { New-Item $TPath -ItemType Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $TPath -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TPath\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN XAML FULL OPTION ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Master V30.0" Width="800" Height="880" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <StackPanel Margin="25">
        <TextBlock Text="VIETTOOLBOX - REINSTALLER CHUYÊN NGHIỆP" FontSize="20" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="0,0,0,20"/>
        
        <TextBlock Text="1. BẢN ĐỒ PHÂN VÙNG HIỆN TẠI:" FontWeight="Bold" Margin="0,0,0,5"/>
        <ListView Name="ListPart" Height="200" Background="White" BorderBrush="#9CA3AF" Margin="0,0,0,15">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Ổ" DisplayMemberBinding="{Binding Drive}" Width="40"/>
                    <GridViewColumn Header="Phân Loại" DisplayMemberBinding="{Binding Type}" Width="100"/>
                    <GridViewColumn Header="Dung Lượng" DisplayMemberBinding="{Binding Size}" Width="100"/>
                    <GridViewColumn Header="Hành Động" DisplayMemberBinding="{Binding Action}" Width="150"/>
                    <GridViewColumn Header="Ghi Chú" DisplayMemberBinding="{Binding Note}" Width="330"/>
                </GridView>
            </ListView.View>
        </ListView>

        <TextBlock Text="2. CHỌN BỘ CÀI (.WIM/.ISO):" FontWeight="Bold" Margin="0,5,0,5"/>
        <Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <TextBox Name="TxtFile" Height="30" VerticalContentAlignment="Center" IsReadOnly="True" Padding="5,0"/>
            <Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt" Width="80" Margin="5,0,0,0" FontWeight="Bold"/></Grid>

        <TextBlock Text="3. TÙY CHỌN NẠP THÊM:" FontWeight="Bold" Margin="0,0,0,5"/>
        <UniformGrid Columns="2" Margin="0,0,0,15">
            <CheckBox Name="OptDriver" Content="Nạp Driver (Thư mục Drivers)" IsChecked="True" FontWeight="Bold" Foreground="#0369A1"/>
            <CheckBox Name="OptApps" Content="Cài Apps (Thư mục Apps)" IsChecked="True" FontWeight="Bold" Foreground="#0369A1"/>
        </UniformGrid>

        <TextBlock Text="4. TIẾN TRÌNH THỰC HIỆN:" FontWeight="Bold" Margin="0,0,0,5"/>
        <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="25" Foreground="#10B981" Background="#E5E7EB"/>
        <TextBlock Name="TxtStep" Text="Đang chờ lệnh sếp..." HorizontalAlignment="Center" FontWeight="SemiBold" Margin="0,5,0,15"/>

        <Border BorderBrush="#F87171" BorderThickness="1" Background="#FEF2F2" Padding="10" Margin="0,0,0,15">
            <TextBlock Text="LƯU Ý: HỆ THỐNG SẼ FORMAT Ổ C ĐỂ CÀI WIN MỚI. DỮ LIỆU CÁC Ổ KHÁC SẼ GIỮ NGUYÊN." Foreground="#B91C1C" FontWeight="Bold" TextAlignment="Center" TextWrapping="Wrap"/>
        </Border>

        <Button Name="BtnRun" Content="🚀 BẮT ĐẦU (REINSTALL &amp; REBOOT)" Height="65" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="18"/>
    </StackPanel>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

# --- 3. QUÉT Ổ ĐĨA & LOGIC ---
$listPart = $window.FindName("ListPart"); $txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile")
$btnRun = $window.FindName("BtnRun"); $progBar = $window.FindName("ProgBar"); $txtStep = $window.FindName("TxtStep")
$optDriver = $window.FindName("OptDriver"); $optApps = $window.FindName("OptApps")

function Update-Step ($val, $txt) { $progBar.Value = $val; $txtStep.Text = $txt; [System.Windows.Forms.Application]::DoEvents() }

function Scan-Disk {
    $listPart.Items.Clear()
    $efi = Get-Partition | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.IsActive }
    Get-Volume | Where-Object {$_.DriveType -eq "Fixed"} | ForEach-Object {
        $d = $_.DriveLetter; $type = "DỮ LIỆU"; $act = "GIỮ NGUYÊN"; $note = "Ổ chứa dữ liệu khách hàng."
        if ($d -eq "C") { $type = "WIN CŨ"; $act = "FORMAT (XÓA)"; $note = "Sẽ cài đè Windows mới vào đây." }
        
        $isEFI = $false; foreach($e in $efi){ if($e.DriveLetter -eq $d){$isEFI=$true} }
        if ($isEFI -or $_.FileSystemLabel -like "*System*") { $type = "BOOT (EFI)"; $act = "GIỮ LẠI"; $note = "Phân vùng mồi Boot hệ thống." }

        $listPart.Items.Add([PSCustomObject]@{ Drive = if($d){$d+":"}else{"*"}; Type = $type; Size = "$([math]::Round($_.Size/1GB,1)) GB"; Action = $act; Note = $note })
    }
}
Scan-Disk

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") { $txtFile.Text = $fd.FileName }
})

# --- 4. THỰC THI (FIX CẢ LỖI BOOT & COPY) ---
$btnRun.Add_Click({
    if (!$txtFile.Text) { return }
    $btnRun.IsEnabled = $false
    $path = $txtFile.Text; $folderGoc = Split-Path $path
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if (!(Test-Path $tmp)) { New-Item $tmp -ItemType Directory -Force }

    # BƯỚC 1: COPY
    Update-Step 20 "Bước 1/4: Đang chuẩn bị bộ cài Windows..."
    if ($path.EndsWith(".iso")) {
        Mount-DiskImage $path -PassThru | Out-Null
        $drv = (Get-DiskImage $path | Get-Volume).DriveLetter
        Copy-Item -Path "$($drv):\sources\install.wim" -Destination "$tmp\install.wim" -Force; Dismount-DiskImage $path | Out-Null
    } else { Copy-Item -Path $path -Destination "$tmp\install.wim" -Force }

    # BƯỚC 2: CHUẨN BỊ BOOT.WIM (Môi trường trung gian)
    Update-Step 45 "Bước 2/4: Đang nạp môi trường cài đặt..."
    reagentc /disable | Out-Null
    if (Test-Path "C:\Windows\System32\Recovery\Winre.wim") { Copy-Item -Path "C:\Windows\System32\Recovery\Winre.wim" -Destination "$tmp\boot.wim" -Force }
    elseif (Test-Path "$folderGoc\boot.wim") { Copy-Item -Path "$folderGoc\boot.wim" -Destination "$tmp\boot.wim" -Force }
    else { [System.Windows.MessageBox]::Show("Sếp ơi thiếu file boot.wim rồi!"); return }

    # BƯỚC 3: NẠP DRIVERS & APPS (CÔNG ĐOẠN SẾP CẦN)
    Update-Step 70 "Bước 3/4: Đang bơm Drivers & Apps sếp chọn..."
    $mDir = "$tmp\Mount"; if(!(Test-Path $mDir)){New-Item $mDir -ItemType Directory}
    dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:$mDir /Quiet
    
    # Lệnh bơm Drivers
    if ($optDriver.IsChecked -and (Test-Path "$folderGoc\Drivers")) {
        dism /Image:$mDir /Add-Driver /Driver:"$folderGoc\Drivers" /Recurse /ForceUnsigned /Quiet
    }
    
    # Lệnh copy thư mục Apps
    if ($optApps.IsChecked -and (Test-Path "$folderGoc\Apps")) {
        xcopy "$folderGoc\Apps" "$mDir\Apps\" /e /y /i /q
    }

    $cmd = "@echo off`r`nwpeinit`r`n"
    $cmd += "for %%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%i:\VietToolbox_Setup\install.wim`" set `"W=%%i:\VietToolbox_Setup\install.wim`"`r`n"
    $cmd += "for %%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%j:\Windows\System32\cmd.exe`" if not exist `"%%j:\VietToolbox_Setup`" set `"OS=%%j:`"`r`n"
    $cmd += "format %OS% /fs:ntfs /q /y`r`ndism /Apply-Image /ImageFile:`"%W%`" /Index:1 /ApplyDir:%OS%\`r`nbcdboot %OS%\Windows /f ALL`r`n"
    $cmd += "md %OS%\Windows\Setup\Scripts`r`n(echo @echo off`r`nfor %%f in (X:\Apps\*.exe) do start /wait %%f /S /silent /install`r`nrd /s /q `"$($safe.DriveLetter):\VietToolbox_Setup`") > %OS%\Windows\Setup\Scripts\SetupComplete.cmd`r`nwpeutil reboot"
    Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
    dism /Unmount-Image /MountDir:$mDir /Commit /Quiet

    # BƯỚC 4: ÉP BOOT RAMDISK
    Update-Step 95 "Bước 4/4: Đang cưỡng chế nạp Boot..."
    Copy-Item -Path "C:\Windows\System32\boot.sdi" -Destination "$tmp\boot.sdi" -Force
    bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
    bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
    $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
    bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id systemroot \windows | Out-Null; bcdedit /set $id winpe yes | Out-Null
    bcdedit /bootsequence $id /addfirst | Out-Null
    bcdedit /timeout 30 | Out-Null

    Update-Step 100 "✅ THÀNH CÔNG!"
    [System.Windows.MessageBox]::Show("Mọi thứ đã sẵn sàng! Restart máy để bắt đầu Reinstall.", "VietToolbox")
    Restart-Computer -Force
})

$window.ShowDialog() | Out-Null