# ==============================================================================
# VIETTOOLBOX MASTER (V32.0) - PHIÊN BẢN CƯỠNG CHẾ BOOT TUYỆT ĐỐI
# Đặc trị: Restart vào thẳng Tool, Hỗ trợ màn hình nhỏ, Hút Driver
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. DI CƯ TỰ ĐỘNG (FIX QUYỀN TRUY CẬP) ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Target = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Target) {
        $TPath = Join-Path ($Target.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $TPath)) { New-Item $TPath -ItemType Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $TPath -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TPath\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN RESPONSIVE (MÀN HÌNH NHỎ) ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V32.0" Width="750" Height="600" MinHeight="500" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="VIETTOOLBOX - NUCLEAR REINSTALLER" FontSize="20" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="10"/>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,5">
            <StackPanel>
                <TextBlock Text="1. BẢN ĐỒ PHÂN VÙNG:" FontWeight="Bold"/><ListView Name="ListPart" Height="150" Background="White" Margin="0,5,0,15"><ListView.View><GridView>
                    <GridViewColumn Header="Ổ" DisplayMemberBinding="{Binding Drive}" Width="40"/><GridViewColumn Header="Loại" DisplayMemberBinding="{Binding Type}" Width="100"/>
                    <GridViewColumn Header="Dung Lượng" DisplayMemberBinding="{Binding Size}" Width="100"/><GridViewColumn Header="Hành Động" DisplayMemberBinding="{Binding Action}" Width="150"/>
                    <GridViewColumn Header="Ghi Chú" DisplayMemberBinding="{Binding Note}" Width="250"/></GridView></ListView.View></ListView>
                <TextBlock Text="2. BỘ CÀI (.WIM/.ISO):" FontWeight="Bold"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtFile" Height="30" IsReadOnly="True" VerticalContentAlignment="Center"/><Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt" Width="80" Margin="5,0,0,0" FontWeight="Bold"/></Grid>
                <TextBlock Text="3. PHIÊN BẢN:" FontWeight="Bold" Margin="0,10,0,5"/><ComboBox Name="ComboEdition" Height="30" Margin="0,0,0,15"/>
                <TextBlock Text="4. TÙY CHỌN NÂNG CAO:" FontWeight="Bold" Margin="0,5,0,5"/><UniformGrid Columns="2" Margin="0,0,0,10">
                    <CheckBox Name="OptDriver" Content="Nạp Driver" IsChecked="True" FontWeight="Bold"/><CheckBox Name="OptApps" Content="Cài Apps Silent" IsChecked="True" FontWeight="Bold"/>
                </UniformGrid>
                <Button Name="BtnBackup" Content="🔍 HÚT DRIVER TỪ MÁY HIỆN TẠI" Height="35" Background="#0369A1" Foreground="White" FontWeight="Bold" Margin="0,5,0,20"/>
            </StackPanel>
        </ScrollViewer>
        <StackPanel Grid.Row="2" Margin="10" Background="#F3F4F6">
            <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="20" Foreground="#10B981"/><TextBlock Name="TxtStep" Text="Chờ lệnh sếp..." HorizontalAlignment="Center" FontWeight="SemiBold" Margin="0,5"/>
            <Button Name="BtnRun" Content="🚀 BẮT ĐẦU REINSTALL (ÉP BOOT 100%)" Height="55" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="16"/>
        </StackPanel>
    </Grid>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

# --- 3. ÁNH XẠ BIẾN & LOGIC ---
$listPart = $window.FindName("ListPart"); $txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile")
$btnRun = $window.FindName("BtnRun"); $btnBackup = $window.FindName("BtnBackup"); $progBar = $window.FindName("ProgBar")
$txtStep = $window.FindName("TxtStep"); $comboEdition = $window.FindName("ComboEdition")
$optDriver = $window.FindName("OptDriver"); $optApps = $window.FindName("OptApps")

function Update-UI ($val, $txt) { $progBar.Value = $val; $txtStep.Text = $txt; [System.Windows.Forms.Application]::DoEvents() }

# Quét phân vùng
function Scan-Disk {
    $listPart.Items.Clear()
    $efi = Get-Partition | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.IsActive }
    Get-Volume | Where-Object {$_.DriveType -eq "Fixed"} | ForEach-Object {
        $d = $_.DriveLetter; $type = "DỮ LIỆU"; $act = "GIỮ NGUYÊN"; $note = "Dữ liệu sếp."
        if ($d -eq "C") { $type = "WIN CŨ"; $act = "FORMAT"; $note = "Sẽ cài đè Win mới." }
        $isEFI = $false; foreach($e in $efi){ if($e.DriveLetter -eq $d){$isEFI=$true} }
        if ($isEFI -or $_.FileSystemLabel -like "*System*") { $type = "BOOT (EFI)"; $act = "MƯỢN DANH"; $note = "Cổng vào bộ cài." }
        $listPart.Items.Add([PSCustomObject]@{ Drive = if($d){$d+":"}else{"*"}; Type = $type; Size = "$([math]::Round($_.Size/1GB,1)) GB"; Action = $act; Note = $note })
    }
}
Scan-Disk

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtFile.Text = $fd.FileName; Update-UI 0 "Đang quét danh sách bản Win..."
        $images = Get-WindowsImage -ImagePath $txtFile.Text -ErrorAction SilentlyContinue
        if (!$images) { $m = Mount-DiskImage $txtFile.Text -PassThru; $d = ($m|Get-Volume).DriveLetter; $w = "$($d):\sources\install.wim"; if(!(Test-Path $w)){$w="$($d):\sources\install.esd"}; $images = Get-WindowsImage -ImagePath $w; Dismount-DiskImage $txtFile.Text | Out-Null }
        $comboEdition.Items.Clear(); $images | ForEach-Object {[void]$comboEdition.Items.Add("Index $($_.ImageIndex): $($_.ImageName)")}; $comboEdition.SelectedIndex=0; Update-UI 0 "Sẵn sàng."
    }
})

$btnBackup.Add_Click({
    $drPath = Join-Path (Split-Path $PSCommandPath) "Drivers"
    if (!(Test-Path $drPath)) { New-Item $drPath -ItemType Directory | Out-Null }
    Update-UI 50 "Đang hút Driver... Đợi tí sếp nhé!"
    Export-WindowsDriver -Online -Destination $drPath | Out-Null
    Update-UI 100 "Đã hút xong!"
    [System.Windows.MessageBox]::Show("Đã hút Driver từ máy hiện tại vào folder Drivers!", "VietToolbox")
})

# --- 4. THỰC THI (CHIÊU NUCLEAR BOOT) ---
$btnRun.Add_Click({
    if (!$txtFile.Text) { return }
    $btnRun.IsEnabled = $false
    $path = $txtFile.Text; $folderGoc = Split-Path $path; $idx = [int]([regex]::Match($comboEdition.Text, "Index (\d+)").Groups[1].Value)
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if (!(Test-Path $tmp)) { New-Item $tmp -ItemType Directory -Force }

    # BƯỚC 1: CHUẨN BỊ
    Update-UI 30 "Bước 1/4: Đang chuẩn bị bộ cài và file Boot..."
    if ($path.EndsWith(".iso")) {
        Mount-DiskImage $path -PassThru | Out-Null
        $drv = (Get-DiskImage $path | Get-Volume).DriveLetter
        Copy-Item "$($drv):\sources\install.wim" "$tmp\install.wim" -Force; Dismount-DiskImage $path | Out-Null
    } else { Copy-Item $path "$tmp\install.wim" -Force }

    reagentc /disable | Out-Null
    if (Test-Path "C:\Windows\System32\Recovery\Winre.wim") { Copy-Item "C:\Windows\System32\Recovery\Winre.wim" "$tmp\boot.wim" -Force }
    elseif (Test-Path "$folderGoc\boot.wim") { Copy-Item "$folderGoc\boot.wim" "$tmp\boot.wim" -Force }
    else { [System.Windows.MessageBox]::Show("Mất WinRE rồi sếp! Vứt file boot.wim vào cạnh bộ cài đi."); return }

    # BƯỚC 2: CẤU HÌNH WINPE
    Update-UI 60 "Bước 2/4: Đang cấu hình kịch bản tự động..."
    $mDir = "$tmp\Mount"; if(!(Test-Path $mDir)){New-Item $mDir -ItemType Directory}
    dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:$mDir /Quiet
    if ($optDriver.IsChecked -and (Test-Path "$folderGoc\Drivers")) { dism /Image:$mDir /Add-Driver /Driver:"$folderGoc\Drivers" /Recurse /ForceUnsigned /Quiet }
    if ($optApps.IsChecked -and (Test-Path "$folderGoc\Apps")) { xcopy "$folderGoc\Apps" "$mDir\Apps\" /e /y /i /q }

    $cmd = "@echo off`r`nwpeinit`r`n"
    $cmd += "for %%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%i:\VietToolbox_Setup\install.wim`" set `"W=%%i:\VietToolbox_Setup\install.wim`"`r`n"
    $cmd += "for %%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%j:\Windows\System32\cmd.exe`" if not exist `"%%j:\VietToolbox_Setup`" set `"OS=%%j:`"`r`n"
    $cmd += "format %OS% /fs:ntfs /q /y`r`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$idx /ApplyDir:%OS%\`r`nbcdboot %OS%\Windows /f ALL`r`n"
    $cmd += "md %OS%\Windows\Setup\Scripts`r`n(echo @echo off`r`nfor %%f in (X:\Apps\*.exe) do start /wait %%f /S /silent /install`r`nrd /s /q `"$($safe.DriveLetter):\VietToolbox_Setup`") > %OS%\Windows\Setup\Scripts\SetupComplete.cmd`r`nwpeutil reboot"
    Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
    dism /Unmount-Image /MountDir:$mDir /Commit /Quiet

    # BƯỚC 3: CHIÊU NUCLEAR BOOT (ÉP CHẾT THỨ TỰ KHỞI ĐỘNG)
    Update-UI 90 "Bước 3/4: Đang ép máy phải khởi động vào Tool..."
    Copy-Item "C:\Windows\System32\boot.sdi" "$tmp\boot.sdi" -Force
    bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
    bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
    
    $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
    bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id systemroot \windows | Out-Null; bcdedit /set $id winpe yes | Out-Null; bcdedit /set $id detecthal yes | Out-Null
    
    # ÉP THỨ TỰ ƯU TIÊN TUYỆT ĐỐI
    bcdedit /set "{bootmgr}" displayorder $id /addfirst | Out-Null
    bcdedit /set "{bootmgr}" default $id | Out-Null
    bcdedit /set "{bootmgr}" timeout 30 | Out-Null
    bcdedit /bootsequence $id /addfirst | Out-Null

    Update-UI 100 "✅ THÀNH CÔNG!"
    [System.Windows.MessageBox]::Show("Xong rồi sếp Tuấn! Restart máy là nó phi thẳng vào bộ cài.", "VietToolbox")
    # Lệnh restart cưỡng chế bypass Fast Startup
    shutdown /r /f /t 00
})

$window.ShowDialog() | Out-Null