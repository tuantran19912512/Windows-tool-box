# ==============================================================================
# VIETTOOLBOX MASTER (V37.0) - PHIÊN BẢN QUYẾT ĐỊNH (BYPASS SECURE BOOT)
# Đặc trị: VirtualBox EFI, Secure Boot, Màn hình độ phân giải thấp
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ (NẾU CHẠY TRÊN Ổ C) ---
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
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V37.0" Width="780" Height="650" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="VIETTOOLBOX - BẢN DỨT ĐIỂM REINSTALL" FontSize="20" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="10"/>
        
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,5">
            <StackPanel>
                <TextBlock Text="1. BẢN ĐỒ PHÂN VÙNG (XÁC ĐỊNH Ổ CÀI):" FontWeight="Bold" Margin="0,0,0,5"/>
                <ListView Name="ListPart" Height="180" Background="White" BorderBrush="#9CA3AF">
                    <ListView.View><GridView>
                        <GridViewColumn Header="Ổ" DisplayMemberBinding="{Binding Drive}" Width="40"/>
                        <GridViewColumn Header="Loại" DisplayMemberBinding="{Binding Type}" Width="110"/>
                        <GridViewColumn Header="Dung Lượng" DisplayMemberBinding="{Binding Size}" Width="100"/>
                        <GridViewColumn Header="Hành Động" DisplayMemberBinding="{Binding Action}" Width="150"/>
                        <GridViewColumn Header="Ghi Chú" DisplayMemberBinding="{Binding Note}" Width="300"/>
                    </GridView></ListView.View>
                </ListView>

                <TextBlock Text="2. BỘ CÀI WINDOWS (.WIM/.ISO):" FontWeight="Bold" Margin="0,15,0,5"/>
                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtFile" Height="30" IsReadOnly="True" VerticalContentAlignment="Center" Padding="5,0"/>
                    <Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt" Width="80" Margin="5,0,0,0" FontWeight="Bold"/></Grid>

                <TextBlock Text="3. PHIÊN BẢN:" FontWeight="Bold" Margin="0,10,0,5"/>
                <ComboBox Name="ComboEdition" Height="30" Margin="0,0,0,15"/>

                <TextBlock Text="4. TÙY CHỌN NẠP THÊM:" FontWeight="Bold" Margin="0,5,0,5"/>
                <UniformGrid Columns="2">
                    <CheckBox Name="OptDriver" Content="Nạp Driver" IsChecked="True" FontWeight="Bold"/>
                    <CheckBox Name="OptApps" Content="Cài Apps Silent" IsChecked="True" FontWeight="Bold"/>
                </UniformGrid>
                <Button Name="BtnBackup" Content="🔍 HÚT DRIVER TỪ MÁY HIỆN TẠI" Height="35" Background="#0369A1" Foreground="White" FontWeight="Bold" Margin="0,10,0,20"/>
            </StackPanel>
        </ScrollViewer>

        <StackPanel Grid.Row="2" Margin="10" Background="#F3F4F6">
            <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="22" Foreground="#10B981"/>
            <TextBlock Name="TxtStep" Text="Đang chờ lệnh sếp Tuấn..." HorizontalAlignment="Center" FontWeight="SemiBold" Margin="0,5,0,10"/>
            <Button Name="BtnRun" Content="🚀 KHAI HỎA (ÉP BOOT TUYỆT ĐỐI)" Height="60" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="18"/>
        </StackPanel>
    </Grid>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

# --- 3. ÁNH XẠ BIẾN & QUÉT Ổ ---
$listPart = $window.FindName("ListPart"); $txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile")
$btnRun = $window.FindName("BtnRun"); $btnBackup = $window.FindName("BtnBackup"); $progBar = $window.FindName("ProgBar")
$txtStep = $window.FindName("TxtStep"); $comboEdition = $window.FindName("ComboEdition")
$optDriver = $window.FindName("OptDriver"); $optApps = $window.FindName("OptApps")

function Log ($val, $txt) { $progBar.Value = $val; $txtStep.Text = $txt; [System.Windows.Forms.Application]::DoEvents() }

function Scan-Disk {
    $listPart.Items.Clear()
    $efi = Get-Partition | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.IsActive }
    Get-Volume | Where-Object {$_.DriveType -eq "Fixed"} | ForEach-Object {
        $d = $_.DriveLetter; $type = "DỮ LIỆU"; $act = "GIỮ NGUYÊN"
        if ($d -eq "C") { $type = "WIN CŨ"; $act = "FORMAT" }
        $isEFI = $false; foreach($e in $efi){ if($e.DriveLetter -eq $d){$isEFI=$true} }
        if ($isEFI -or $_.FileSystemLabel -like "*System*") { $type = "BOOT (EFI)"; $act = "CẬP NHẬT" }
        $listPart.Items.Add([PSCustomObject]@{ Drive = if($d){$d+":"}else{"*"}; Type = $type; Size = "$([math]::Round($_.Size/1GB,1)) GB"; Action = $act; Note = "VietToolbox Master" })
    }
}
Scan-Disk

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtFile.Text = $fd.FileName; Log 0 "Đang quét danh sách Index..."
        $images = Get-WindowsImage -ImagePath $txtFile.Text -ErrorAction SilentlyContinue
        if (!$images) { $m = Mount-DiskImage $txtFile.Text -PassThru; $d = ($m|Get-Volume).DriveLetter; $w = "$($d):\sources\install.wim"; if(!(Test-Path $w)){$w="$($d):\sources\install.esd"}; $images = Get-WindowsImage -ImagePath $w; Dismount-DiskImage $txtFile.Text | Out-Null }
        $comboEdition.Items.Clear(); $images | ForEach-Object {[void]$comboEdition.Items.Add("Index $($_.ImageIndex): $($_.ImageName)")}; $comboEdition.SelectedIndex=0; Log 0 "Sẵn sàng."
    }
})

$btnBackup.Add_Click({
    $drPath = Join-Path (Split-Path $PSCommandPath) "Drivers"
    if (!(Test-Path $drPath)) { New-Item $drPath -ItemType Directory | Out-Null }
    Log 50 "Đang hút Driver... Sếp đợi tí nhé!"
    Export-WindowsDriver -Online -Destination $drPath | Out-Null
    Log 100 "Đã hút xong!"
})

# --- 4. THỰC THI (CHIÊU ÉP BOOT TUYỆT ĐỐI) ---
$btnRun.Add_Click({
    if (!$txtFile.Text) { return }
    $btnRun.IsEnabled = $false
    $path = $txtFile.Text; $folderGoc = Split-Path $path; $idx = [int]([regex]::Match($comboEdition.Text, "Index (\d+)").Groups[1].Value)
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if (!(Test-Path $tmp)) { New-Item $tmp -ItemType Directory -Force }

    # BƯỚC 1: COPY BỘ CÀI
    Log 25 "Bước 1/4: Đang chuẩn bị bộ cài..."
    if ($path.EndsWith(".iso")) {
        Mount-DiskImage $path -PassThru | Out-Null
        $drv = (Get-DiskImage $path | Get-Volume).DriveLetter
        Copy-Item -Path "$($drv):\sources\install.wim" -Destination "$tmp\install.wim" -Force; Dismount-DiskImage $path | Out-Null
    } else { Copy-Item -Path $path -Destination "$tmp\install.wim" -Force }

    # BƯỚC 2: CHUẨN BỊ WINRE (Môi trường cứu hộ chính chủ)
    Log 50 "Bước 2/4: Đang săn tìm WinRE..."
    reagentc /disable | Out-Null
    if (Test-Path "C:\Windows\System32\Recovery\Winre.wim") { Copy-Item -Path "C:\Windows\System32\Recovery\Winre.wim" -Destination "$tmp\boot.wim" -Force }
    elseif (Test-Path "$folderGoc\boot.wim") { Copy-Item -Path "$folderGoc\boot.wim" -Destination "$tmp\boot.wim" -Force }
    else { [System.Windows.MessageBox]::Show("Máy mất WinRE. Sếp vứt file boot.wim vào cạnh bộ cài đi!"); return }

    # BƯỚC 3: CẤU HÌNH LỆNH TỰ ĐỘNG
    Log 70 "Bước 3/4: Đang 'chích' lệnh cài tự động..."
    $mDir = "$tmp\Mount"; if(!(Test-Path $mDir)){New-Item $mDir -ItemType Directory}
    dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:$mDir /Quiet
    if ($optDriver.IsChecked -and (Test-Path "$folderGoc\Drivers")) { dism /Image:$mDir /Add-Driver /Driver:"$folderGoc\Drivers" /Recurse /ForceUnsigned /Quiet }
    $cmd = "@echo off`r`nwpeinit`r`nfor %%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%i:\VietToolbox_Setup\install.wim`" set `"W=%%i:\VietToolbox_Setup\install.wim`"`r`nfor %%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%j:\Windows\System32\cmd.exe`" if not exist `"%%j:\VietToolbox_Setup`" set `"OS=%%j:`"`r`nformat %OS% /fs:ntfs /q /y`r`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$idx /ApplyDir:%OS%\`r`nbcdboot %OS%\Windows /f ALL`r`nwpeutil reboot"
    Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
    dism /Unmount-Image /MountDir:$mDir /Commit /Quiet

    # BƯỚC 4: ÉP BOOT TUYỆT ĐỐI (CHIÊU CHỐT HẠ)
    Log 90 "Bước 4/4: Đang cưỡng chế hệ thống phải phi vào Tool..."
    Copy-Item -Path "C:\Windows\System32\boot.sdi" -Destination "$tmp\boot.sdi" -Force
    
    bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
    bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
    
    $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
    bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id systemroot \windows | Out-Null; bcdedit /set $id winpe yes | Out-Null; bcdedit /set $id detecthal yes | Out-Null
    
    # ÉP DEFAULT VÀ BOOTSEQUENCE
    bcdedit /set "{bootmgr}" displayorder $id /addfirst | Out-Null
    bcdedit /set "{bootmgr}" default $id | Out-Null
    bcdedit /set "{bootmgr}" timeout 30 | Out-Null
    bcdedit /bootsequence $id /addfirst | Out-Null # Ép duy nhất 1 lần khởi động vào đây

    Log 100 "✅ XONG RỒI SẾP TUẤN!"
    [System.Windows.MessageBox]::Show("Đã nạp xong! Sếp Restart máy là nó phi thẳng vào bộ cài. Nếu vẫn vào Win cũ thì sếp mắng em tiếp!", "Thành công")
    shutdown /r /f /t 00
})

$window.ShowDialog() | Out-Null