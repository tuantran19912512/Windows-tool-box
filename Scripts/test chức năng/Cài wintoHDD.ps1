# ==============================================================================
# VIETTOOLBOX MASTER (V35.0) - PHIÊN BẢN CHỐT HẠ (BYPASS SECURE BOOT)
# Đặc trị: Lỗi 'No valid image', Lỗi vào lại Win cũ, Hỗ trợ màn hình thấp
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. DI CƯ TỰ ĐỘNG ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Target = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Target) {
        $TPath = Join-Path ($Target.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $TPath)) { New-Item $TPath -ItemType Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $TPath -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TPath\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN RESPONSIVE ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V35.0" Width="780" Height="650" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="VIETTOOLBOX - PROFESSIONAL REINSTALLER" FontSize="20" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="10"/>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,5">
            <StackPanel>
                <TextBlock Text="1. BẢN ĐỒ PHÂN VÙNG (TRƯỚC KHI CÀI):" FontWeight="Bold" Margin="0,0,0,5"/>
                <ListView Name="ListPart" Height="180" Background="White" BorderBrush="#9CA3AF">
                    <ListView.View><GridView>
                        <GridViewColumn Header="Ổ" DisplayMemberBinding="{Binding Drive}" Width="40"/>
                        <GridViewColumn Header="Loại" DisplayMemberBinding="{Binding Type}" Width="100"/>
                        <GridViewColumn Header="Dung Lượng" DisplayMemberBinding="{Binding Size}" Width="100"/>
                        <GridViewColumn Header="Hành Động" DisplayMemberBinding="{Binding Action}" Width="150"/>
                        <GridViewColumn Header="Ghi Chú" DisplayMemberBinding="{Binding Note}" Width="300"/>
                    </GridView></ListView.View>
                </ListView>

                <TextBlock Text="2. BỘ CÀI WINDOWS (.WIM/.ISO):" FontWeight="Bold" Margin="0,15,0,5"/>
                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtFile" Height="30" IsReadOnly="True" VerticalContentAlignment="Center" Padding="5,0"/>
                    <Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt" Width="80" Margin="5,0,0,0" FontWeight="Bold"/></Grid>

                <TextBlock Text="3. TÙY CHỌN NẠP THÊM:" FontWeight="Bold" Margin="0,15,0,5"/>
                <UniformGrid Columns="2">
                    <CheckBox Name="OptDriver" Content="Nạp Driver" IsChecked="True" FontWeight="Bold"/>
                    <CheckBox Name="OptApps" Content="Cài Apps Silent" IsChecked="True" FontWeight="Bold"/>
                </UniformGrid>
                <Button Name="BtnBackup" Content="🔍 HÚT DRIVER TỪ MÁY HIỆN TẠI" Height="35" Background="#0369A1" Foreground="White" FontWeight="Bold" Margin="0,10,0,20"/>
            </StackPanel>
        </ScrollViewer>
        <StackPanel Grid.Row="2" Margin="10" Background="#F3F4F6">
            <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="22" Foreground="#10B981"/>
            <TextBlock Name="TxtStep" Text="Đang chờ lệnh sếp..." HorizontalAlignment="Center" FontWeight="SemiBold" Margin="0,5,0,10"/>
            <Button Name="BtnRun" Content="🚀 BẮT ĐẦU CÀI ĐẶT (FORCE BOOT)" Height="60" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="18"/>
        </StackPanel>
    </Grid>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

# --- 3. LOGIC ---
$listPart = $window.FindName("ListPart"); $txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile")
$btnRun = $window.FindName("BtnRun"); $btnBackup = $window.FindName("BtnBackup"); $progBar = $window.FindName("ProgBar")
$txtStep = $window.FindName("TxtStep"); $optDriver = $window.FindName("OptDriver"); $optApps = $window.FindName("OptApps")

function Log ($val, $txt) { $progBar.Value = $val; $txtStep.Text = $txt; [System.Windows.Forms.Application]::DoEvents() }

function Scan-Disk {
    $listPart.Items.Clear()
    $efi = Get-Partition | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.IsActive }
    Get-Volume | Where-Object {$_.DriveType -eq "Fixed"} | ForEach-Object {
        $d = $_.DriveLetter; $type = "DỮ LIỆU"; $act = "GIỮ NGUYÊN"
        if ($d -eq "C") { $type = "WIN CŨ"; $act = "FORMAT" }
        $isEFI = $false; foreach($e in $efi){ if($e.DriveLetter -eq $d){$isEFI=$true} }
        if ($isEFI -or $_.FileSystemLabel -like "*System*") { $type = "BOOT (EFI)"; $act = "CẬP NHẬT" }
        $listPart.Items.Add([PSCustomObject]@{ Drive = if($d){$d+":"}else{"*"}; Type = $type; Size = "$([math]::Round($_.Size/1GB,1)) GB"; Action = $act; Note = "VietToolbox Check" })
    }
}
Scan-Disk

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") { $txtFile.Text = $fd.FileName }
})

$btnBackup.Add_Click({
    $drPath = Join-Path (Split-Path $PSCommandPath) "Drivers"
    if (!(Test-Path $drPath)) { New-Item $drPath -ItemType Directory | Out-Null }
    Log 50 "Đang hút Driver... Đợi tí sếp Tuấn ơi!"
    Export-WindowsDriver -Online -Destination $drPath | Out-Null
    Log 100 "Đã hút xong!"
})

# --- 4. THỰC THI (CHIÊU GHI ĐÈ EFI TUYỆT ĐỐI) ---
$btnRun.Add_Click({
    if (!$txtFile.Text) { return }
    $btnRun.IsEnabled = $false
    $path = $txtFile.Text; $folderGoc = Split-Path $path
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if (!(Test-Path $tmp)) { New-Item $tmp -ItemType Directory -Force }

    # BƯỚC 1: COPY BỘ CÀI
    Log 25 "Bước 1/4: Đang chuẩn bị bộ cài..."
    if ($path.EndsWith(".iso")) {
        Mount-DiskImage $path -PassThru | Out-Null
        $drv = (Get-DiskImage $path | Get-Volume).DriveLetter
        Copy-Item -Path "$($drv):\sources\install.wim" -Destination "$tmp\install.wim" -Force; Dismount-DiskImage $path | Out-Null
    } else { Copy-Item -Path $path -Destination "$tmp\install.wim" -Force }

    # BƯỚC 2: CHUẨN BỊ BOOT.WIM (FIX LỖI HÌNH 1, 4)
    Log 50 "Bước 2/4: Đang bốc file Boot (WinRE Hijack)..."
    reagentc /disable | Out-Null
    $bootWim = "$tmp\boot.wim"
    if (Test-Path "C:\Windows\System32\Recovery\Winre.wim") { Copy-Item -Path "C:\Windows\System32\Recovery\Winre.wim" -Destination $bootWim -Force }
    elseif (Test-Path "$folderGoc\boot.wim") { Copy-Item -Path "$folderGoc\boot.wim" -Destination $bootWim -Force }
    else { [System.Windows.MessageBox]::Show("Sếp Tuấn ơi, máy mất WinRE rồi. Quăng file boot.wim vào cạnh bộ cài đi!"); return }

    # BƯỚC 3: CẤU HÌNH KỊCH BẢN
    Log 75 "Bước 3/4: Đang chích lệnh tự động cài Win..."
    $mDir = "$tmp\Mount"; if(!(Test-Path $mDir)){New-Item $mDir -ItemType Directory}
    dism /Mount-Image /ImageFile:$bootWim /Index:1 /MountDir:$mDir /Quiet
    if ($optDriver.IsChecked -and (Test-Path "$folderGoc\Drivers")) { dism /Image:$mDir /Add-Driver /Driver:"$folderGoc\Drivers" /Recurse /ForceUnsigned /Quiet }
    $cmd = "@echo off`r`nwpeinit`r`nfor %%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%i:\VietToolbox_Setup\install.wim`" set `"W=%%i:\VietToolbox_Setup\install.wim`"`r`nfor %%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%j:\Windows\System32\cmd.exe`" if not exist `"%%j:\VietToolbox_Setup`" set `"OS=%%j:`"`r`nformat %OS% /fs:ntfs /q /y`r`ndism /Apply-Image /ImageFile:`"%W%`" /Index:1 /ApplyDir:%OS%\`r`nbcdboot %OS%\Windows /f ALL`r`nwpeutil reboot"
    Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
    dism /Unmount-Image /MountDir:$mDir /Commit /Quiet

    # BƯỚC 4: ÉP BOOT (FIX LỖI VÀO WIN CŨ)
    Log 95 "Bước 4/4: Đang cưỡng chế nạp Boot tuyệt đối..."
    # Copy file sdi chuẩn PowerShell (Fix hình 2)
    Copy-Item -Path "C:\Windows\System32\boot.sdi" -Destination "$tmp\boot.sdi" -Force
    
    bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
    bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
    
    $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
    bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id systemroot \windows | Out-Null; bcdedit /set $id winpe yes | Out-Null
    
    # LỆNH ÉP CHẾT: Đẩy Tool lên Default và xóa Timeout để nó phi vào luôn
    bcdedit /set "{bootmgr}" displayorder $id /addfirst | Out-Null
    bcdedit /set "{bootmgr}" default $id | Out-Null
    bcdedit /set "{bootmgr}" timeout 5 | Out-Null
    bcdedit /bootsequence $id /addfirst | Out-Null

    Log 100 "✅ XONG! RESTART ĐI SẾP."
    [System.Windows.MessageBox]::Show("Đã nạp xong! Sếp Restart máy là nó phi thẳng vào bộ cài. Nếu VirtualBox vẫn lỳ, sếp nhớ tắt Secure Boot trong Settings của VM nhé!", "Thành công")
    shutdown /r /f /t 00
})

$window.ShowDialog() | Out-Null