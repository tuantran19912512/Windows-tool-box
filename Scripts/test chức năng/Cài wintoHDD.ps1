# ==============================================================================
# VIETTOOLBOX MASTER (V34.0) - PHIÊN BẢN CHIẾM QUYỀN WINRE (VƯỢT SECURE BOOT)
# Đặc trị: Vượt Secure Boot như WinToHDD, Giao diện cuộn Low-Res, Hút Driver
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ (GIỮ NGUYÊN) ---
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
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V34.0" Width="750" Height="620" MinHeight="500" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="VIETTOOLBOX - SECURE BOOT BYPASS" FontSize="20" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="10"/>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,5">
            <StackPanel>
                <TextBlock Text="1. BẢN ĐỒ PHÂN VÙNG:" FontWeight="Bold"/><ListView Name="ListPart" Height="150" Background="White" Margin="0,5,0,15"><ListView.View><GridView>
                    <GridViewColumn Header="Ổ" DisplayMemberBinding="{Binding Drive}" Width="40"/><GridViewColumn Header="Loại" DisplayMemberBinding="{Binding Type}" Width="100"/>
                    <GridViewColumn Header="Dung Lượng" DisplayMemberBinding="{Binding Size}" Width="100"/><GridViewColumn Header="Hành Động" DisplayMemberBinding="{Binding Action}" Width="150"/>
                    <GridViewColumn Header="Ghi Chú" DisplayMemberBinding="{Binding Note}" Width="250"/></GridView></ListView.View></ListView>
                <TextBlock Text="2. BỘ CÀI (.WIM/.ISO):" FontWeight="Bold"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtFile" Height="30" IsReadOnly="True" VerticalContentAlignment="Center"/><Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt" Width="80" Margin="5,0,0,0" FontWeight="Bold"/></Grid>
                <TextBlock Text="3. PHIÊN BẢN:" FontWeight="Bold" Margin="0,10,0,5"/><ComboBox Name="ComboEdition" Height="30" Margin="0,0,0,15"/>
                <TextBlock Text="4. TÙY CHỌN NẠP THÊM:" FontWeight="Bold" Margin="0,5,0,5"/><UniformGrid Columns="2" Margin="0,0,0,10">
                    <CheckBox Name="OptDriver" Content="Nạp Driver" IsChecked="True" FontWeight="Bold"/><CheckBox Name="OptApps" Content="Cài Apps Silent" IsChecked="True" FontWeight="Bold"/>
                </UniformGrid>
                <Button Name="BtnBackup" Content="🔍 HÚT DRIVER TỪ MÁY HIỆN TẠI" Height="35" Background="#0369A1" Foreground="White" FontWeight="Bold" Margin="0,5,0,20"/>
            </StackPanel>
        </ScrollViewer>
        <StackPanel Grid.Row="2" Margin="10" Background="#F3F4F6">
            <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="20" Foreground="#10B981"/><TextBlock Name="TxtStep" Text="Đang chờ lệnh sếp..." HorizontalAlignment="Center" FontWeight="SemiBold" Margin="0,5"/>
            <Button Name="BtnRun" Content="🚀 KHAI HỎA (MƯỢN DANH WINRE)" Height="60" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="18"/>
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

function Update-UI ($val, $txt) { $progBar.Value = $val; $txtStep.Text = $txt; [System.Windows.Forms.Application]::DoEvents() }

function Scan-Disk {
    $listPart.Items.Clear()
    Get-Volume | Where-Object {$_.DriveType -eq "Fixed"} | ForEach-Object {
        $d = $_.DriveLetter; $type = "DỮ LIỆU"; $act = "GIỮ NGUYÊN"
        if ($d -eq "C") { $type = "WIN CŨ"; $act = "FORMAT" }
        $listPart.Items.Add([PSCustomObject]@{ Drive = if($d){$d+":"}else{"*"}; Type = $type; Size = "$([math]::Round($_.Size/1GB,1)) GB"; Action = $act; Note = "Mượn danh WinRE" })
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
    Update-UI 50 "Đang hút Driver... Sắp xong rồi sếp!"
    Export-WindowsDriver -Online -Destination $drPath | Out-Null
    Update-UI 100 "Đã hút xong!"
})

# --- 4. THỰC THI (CHIÊU MƯỢN DANH WINRE NHƯ WINTOHDD) ---
$btnRun.Add_Click({
    if (!$txtFile.Text) { return }
    $btnRun.IsEnabled = $false
    $path = $txtFile.Text; $folderGoc = Split-Path $path; $idx = [int]([regex]::Match($comboEdition.Text, "Index (\d+)").Groups[1].Value)
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if (!(Test-Path $tmp)) { New-Item $tmp -ItemType Directory -Force }

    # BƯỚC 1: COPY
    Update-UI 25 "Bước 1/4: Đang chuẩn bị bộ cài..."
    if ($path.EndsWith(".iso")) {
        Mount-DiskImage $path -PassThru | Out-Null
        $drv = (Get-DiskImage $path | Get-Volume).DriveLetter
        Copy-Item "$($drv):\sources\install.wim" "$tmp\install.wim" -Force; Dismount-DiskImage $path | Out-Null
    } else { Copy-Item $path "$tmp\install.wim" -Force }

    # BƯỚC 2: MÓC BOOT.WIM (CHIÊM QUYỀN WINRE)
    Update-UI 50 "Bước 2/4: Đang mượn danh Windows Recovery (WinRE)..."
    reagentc /disable | Out-Null
    if (Test-Path "C:\Windows\System32\Recovery\Winre.wim") { Copy-Item "C:\Windows\System32\Recovery\Winre.wim" "$tmp\boot.wim" -Force }
    elseif (Test-Path "$folderGoc\boot.wim") { Copy-Item "$folderGoc\boot.wim" "$tmp\boot.wim" -Force }
    else { [System.Windows.MessageBox]::Show("Mất file Boot rồi sếp!"); return }

    # BƯỚC 3: CẤU HÌNH LỆNH TỰ ĐỘNG
    Update-UI 75 "Bước 3/4: Đang cấu hình kịch bản tự động..."
    $mDir = "$tmp\Mount"; if(!(Test-Path $mDir)){New-Item $mDir -ItemType Directory}
    dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:$mDir /Quiet
    if ($optDriver.IsChecked -and (Test-Path "$folderGoc\Drivers")) { dism /Image:$mDir /Add-Driver /Driver:"$folderGoc\Drivers" /Recurse /ForceUnsigned /Quiet }
    if ($optApps.IsChecked -and (Test-Path "$folderGoc\Apps")) { xcopy "$folderGoc\Apps" "$mDir\Apps\" /e /y /i /q }
    $cmd = "@echo off`r`nwpeinit`r`nfor %%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%i:\VietToolbox_Setup\install.wim`" set `"W=%%i:\VietToolbox_Setup\install.wim`"`r`nfor %%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%j:\Windows\System32\cmd.exe`" if not exist `"%%j:\VietToolbox_Setup`" set `"OS=%%j:`"`r`nformat %OS% /fs:ntfs /q /y`r`ndism /Apply-Image /ImageFile:`"%W%`" /Index:$idx /ApplyDir:%OS%\`r`nbcdboot %OS%\Windows /f ALL`r`nwpeutil reboot"
    Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
    dism /Unmount-Image /MountDir:$mDir /Commit /Quiet

    # BƯỚC 4: CHIÊU MƯỢN DANH (BYPASS SECURE BOOT)
    Update-UI 95 "Bước 4/4: Đang ép máy phi thẳng vào bộ cài..."
    # 1. Thiết lập file của mình làm file Recovery chính thức
    reagentc /setreimage /path "$tmp" /target C:\Windows | Out-Null
    reagentc /enable | Out-Null
    
    # 2. Ép máy lần sau khởi động PHẢI vào Recovery
    reagentc /boottore | Out-Null

    Update-UI 100 "✅ XONG RỒI SẾP TUẤN!"
    [System.Windows.MessageBox]::Show("Em đã dùng chiêu 'Mượn danh WinRE'. Secure Boot sẽ cho qua 100%.", "Thành công")
    # Restart cưỡng chế để áp dụng
    shutdown /r /f /t 00
})

$window.ShowDialog() | Out-Null