# ==============================================================================
# Tên công cụ: VIETTOOLBOX - ULTIMATE REINSTALLER (V28.26 - SMART BOOT)
# Đặc trị: Tự động dùng boot.wim ngoài nếu máy khách bị mất WinRE
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Other = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Other) {
        $Path = Join-Path ($Other.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $Path)) { New-Item $Path -Type Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $Path -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Path\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN (GIỮ NGUYÊN FULL OPTION) ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V28.26" Width="700" Height="750" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <Border BorderBrush="#D1D5DB" BorderThickness="1">
        <StackPanel Margin="30">
            <TextBlock Text="VIETTOOLBOX - SMART REINSTALL" FontSize="20" FontWeight="Bold" Foreground="#0284C7" Margin="0,0,0,20" HorizontalAlignment="Center"/>
            <TextBlock Text="BỘ CÀI (WIM/ISO):" FontWeight="Bold"/><Grid Margin="0,5,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBox Name="TxtFile" Height="30" IsReadOnly="True"/><Button Name="BtnFile" Grid.Column="1" Content="📁 Chọn file" Width="100" Margin="5,0,0,0"/></Grid>
            <TextBlock Text="PHIÊN BẢN:" FontWeight="Bold"/><ComboBox Name="ComboEdition" Height="30" Margin="0,5,0,20"/>
            <CheckBox Name="OptDriver" Content="Tự bơm Driver (Thư mục Drivers)" IsChecked="True" Margin="5" FontWeight="Bold"/>
            <CheckBox Name="OptApps" Content="Tự cài Phần mềm (Thư mục Apps)" IsChecked="True" Margin="5" FontWeight="Bold"/>
            <CheckBox Name="OptClean" Content="Tự dọn rác sau khi cài xong" IsChecked="True" Margin="5" FontWeight="Bold"/>
            <Separator Margin="0,20"/>
            <TextBlock Name="TxtStatus" Text="Sẵn sàng." Foreground="#059669" FontWeight="Bold" HorizontalAlignment="Center"/>
            <Button Name="BtnRun" Content="🚀 BẮT ĐẦU CÀI ĐẶT" Height="60" Background="#10B981" Foreground="White" FontWeight="Bold" Margin="0,20,0,0"/>
        </StackPanel>
    </Border>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))
$txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile"); $comboEdition = $window.FindName("ComboEdition")
$btnRun = $window.FindName("BtnRun"); $txtStatus = $window.FindName("TxtStatus")
$optDriver = $window.FindName("OptDriver"); $optApps = $window.FindName("OptApps"); $optClean = $window.FindName("OptClean")

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtFile.Text = $fd.FileName; $images = Get-WindowsImage -ImagePath $txtFile.Text -ErrorAction SilentlyContinue
        if (!$images) { $m = Mount-DiskImage $txtFile.Text -PassThru; $d = ($m|Get-Volume).DriveLetter; $w = "$($d):\sources\install.wim"; if(!(Test-Path $w)){$w="$($d):\sources\install.esd"}; $images = Get-WindowsImage -ImagePath $w; Dismount-DiskImage $txtFile.Text | Out-Null }
        $images | ForEach-Object {[void]$comboEdition.Items.Add("Index $($_.ImageIndex): $($_.ImageName)")}; $comboEdition.SelectedIndex=0
    }
})

$btnRun.Add_Click({
    if(!$txtFile.Text){return}
    $idx = [int]([regex]::Match($comboEdition.Text, "Index (\d+)").Groups[1].Value); $path = $txtFile.Text
    $injDr = $optDriver.IsChecked; $injAp = $optApps.IsChecked; $doCl = $optClean.IsChecked
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if(!(Test-Path $tmp)){New-Item $tmp -Type Directory -Force}

    $batchScript = @"
@echo off
setlocal enabledelayedexpansion
title DANG THI TRIEN - SMART BOOT MODE
color 0B
echo [1/4] DICH CHUYEN BO CAI...
if /i "%~x1"==".iso" (
    powershell -command "Mount-DiskImage '$path'"
    for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%i:\sources\install.wim" set "src=%%i:\sources\install.wim"
    for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%i:\sources\install.esd" set "src=%%i:\sources\install.esd"
    copy /y "!src!" "$tmp\install.wim"
    powershell -command "Dismount-DiskImage '$path'"
) else ( copy /y "$path" "$tmp\install.wim" )

echo [2/4] CHUAN BI MOI TRUONG BOOT...
reagentc /disable
copy /y C:\Windows\System32\Recovery\Winre.wim "$tmp\boot.wim"

if not exist "$tmp\boot.wim" (
    echo [CANH BAO] Khong thay WinRE trong may. Dang tim file boot.wim cua sep...
    if exist "$(Split-Path $PSScriptRoot)\boot.wim" (
        copy /y "$(Split-Path $PSScriptRoot)\boot.wim" "$tmp\boot.wim"
        echo [OK] Da tim thay boot.wim ben ngoai!
    ) else (
        echo [LOI] Khong tim thay bat ky file Boot nao!
        echo Vui long vut file boot.wim ben canh script nay.
        pause & exit
    )
)

md "$tmp\Mount"
dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:"$tmp\Mount"

if "$injDr"=="True" (
    if exist "$(Split-Path $path)\Drivers" (
        echo Dang bom Driver...
        dism /Image:"$tmp\Mount" /Add-Driver /Driver:"$(Split-Path $path)\Drivers" /Recurse /ForceUnsigned
    )
)
if "$injAp"=="True" (
    if exist "$(Split-Path $path)\Apps" (
        echo Dang bom Apps...
        xcopy "$(Split-Path $path)\Apps" "$tmp\Mount\Apps\" /e /y /i /q
    )
)

echo [3/4] CAY LENH TU DONG...
(
echo @echo off
echo wpeinit
echo for %%%%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%%%i:\VietToolbox_Setup\install.wim" set "W=%%%%i:\VietToolbox_Setup\install.wim"
echo for %%%%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%%%j:\Windows\System32\cmd.exe" if not exist "%%%%j:\VietToolbox_Setup" set "OS=%%%%j:"
echo format %%OS%% /fs:ntfs /q /y
echo dism /Apply-Image /ImageFile:"%%W%%" /Index:$idx /ApplyDir:%%OS%%\
echo bcdboot %%OS%%\Windows /f ALL
echo md %%OS%%\Windows\Setup\Scripts
echo (
echo @echo off
echo for %%%%f in (X:\Apps\*.exe) do start /wait %%%%f /S /silent /install
if "$doCl"=="True" echo rd /s /q "$($safe.DriveLetter):\VietToolbox_Setup"
echo ) ^> %%OS%%\Windows\Setup\Scripts\SetupComplete.cmd
echo wpeutil reboot
) > "$tmp\Mount\Windows\System32\startnet.cmd"

dism /Unmount-Image /MountDir:"$tmp\Mount" /Commit

echo [4/4] NAP BOOT RAMDISK...
copy /y C:\Windows\System32\boot.sdi "$tmp\boot.sdi"
bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$($safe.DriveLetter):
bcdedit /set {ramdiskoptions} ramdisksdipath \VietToolbox_Setup\boot.sdi
for /f "tokens=2 delims={}" %%g in ('bcdedit /create /d "VietToolbox_Setup" /application osloader') do set "guid={%%g}"
bcdedit /set {%%g} device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}"
bcdedit /set {%%g} osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}"
bcdedit /set {%%g} systemroot \windows
bcdedit /set {%%g} winpe yes
bcdedit /set {%%g} detecthal yes
bcdedit /bootsequence {%%g} /addfirst

echo === XONG! BAM PHIM BAT KY DE RESTART ===
pause
exit
"@
    $batchPath = "$tmp\Execute.bat"
    Set-Content $batchPath $batchScript -Encoding Ascii
    Start-Process cmd.exe -ArgumentList "/c `"$batchPath`"" -Verb RunAs -Wait
    [System.Windows.MessageBox]::Show("Nếu bảng đen không báo lỗi, mời sếp Restart!", "Kết quả")
})
$window.ShowDialog() | Out-Null