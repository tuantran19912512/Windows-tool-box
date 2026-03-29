# ==============================================================================
# Tên công cụ: VIETTOOLBOX - REINSTALLER (V28.24 - ANTI-HANG)
# Đặc trị: Fix lỗi treo khi nạp Driver, Hiện tiến trình DISM chi tiết
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

# --- 2. GIAO DIỆN ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V28.24" Width="600" Height="400" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <StackPanel Margin="25">
        <TextBlock Text="TRÌNH CÀI WIN MA GIÁO (ANTI-HANG)" FontSize="18" FontWeight="Bold" Foreground="#C2185B" HorizontalAlignment="Center" Margin="0,0,0,20"/>
        <TextBlock Text="File cài (WIM/ISO):" FontWeight="Bold"/><TextBox Name="TxtFile" Height="25" IsReadOnly="True" Margin="0,5,0,15"/>
        <Button Name="BtnFile" Content="📁 Duyệt File..." Height="30" Margin="0,0,0,15"/>
        <TextBlock Name="TxtStatus" Text="Trạng thái: Sẵn sàng." Foreground="#059669" FontWeight="Bold" HorizontalAlignment="Center"/>
        <Button Name="BtnRun" Content="🔥 THỰC THI (XEM TIẾN TRÌNH CHI TIẾT)" Height="60" Background="#C2185B" Foreground="White" FontWeight="Bold" Margin="0,20,0,0"/>
    </StackPanel>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))
$txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile"); $btnRun = $window.FindName("BtnRun")

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") { $txtFile.Text = $fd.FileName }
})

$btnRun.Add_Click({
    if(!$txtFile.Text){ return }
    $path = $txtFile.Text
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if(!(Test-Path $tmp)){New-Item $tmp -Type Directory -Force}

    $batchScript = @"
@echo off
setlocal enabledelayedexpansion
title DANG THI TRIEN - KHONG DUOC TAT CUA SO NAY!
color 0E
echo ========================================================
echo   [1/4] CHUAN BI BO CAI VA WINRE...
echo ========================================================
:: Copy file cài (dùng robocopy cho ổn định)
if /i "%~x1"==".iso" (
    powershell -command "Mount-DiskImage '%path%'"
    for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%i:\sources\install.wim" set "src=%%i:\sources\install.wim"
    for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%i:\sources\install.esd" set "src=%%i:\sources\install.esd"
    copy /y "!src!" "$tmp\install.wim"
    powershell -command "Dismount-DiskImage '%path%'"
) else (
    copy /y "%path%" "$tmp\install.wim"
)

:: Săn WinRE
reagentc /disable
copy /y C:\Windows\System32\Recovery\Winre.wim "$tmp\boot.wim"
if not exist "$tmp\boot.wim" ( echo LỖI: KHÔNG TÌM THẤY WINRE! & pause & exit )

echo ========================================================
echo   [2/4] MO BUNG BOOT.WIM VA BOM DRIVER
echo ========================================================
if not exist "$tmp\Mount" md "$tmp\Mount"
dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:"$tmp\Mount"

:: Bơm Driver (Sếp nhìn kỹ chỗ này, nó sẽ hiện danh sách chạy)
if exist "$(Split-Path $path)\Drivers" (
    echo [!!!] DANG BOM DRIVER... VUI LONG DOI DISM CHAY XONG...
    dism /Image:"$tmp\Mount" /Add-Driver /Driver:"$(Split-Path $path)\Drivers" /Recurse /ForceUnsigned
)

:: Bơm Apps (Nếu có)
if exist "$(Split-Path $path)\Apps" (
    echo [!!!] DANG BOM APPS...
    xcopy "$(Split-Path $path)\Apps" "$tmp\Mount\Apps\" /e /y /i /q
)

echo ========================================================
echo   [3/4] CAY LENH TU DONG VA DONG FILE BOOT
echo ========================================================
(
echo @echo off
echo wpeinit
echo for %%%%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%%%i:\VietToolbox_Setup\install.wim" set "W=%%%%i:\VietToolbox_Setup\install.wim"
echo for %%%%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%%%j:\Windows\System32\cmd.exe" if not exist "%%%%j:\VietToolbox_Setup" set "OS=%%%%j:"
echo format %%OS%% /fs:ntfs /q /y
echo dism /Apply-Image /ImageFile:"%%W%%" /Index:1 /ApplyDir:%%OS%%\
echo bcdboot %%OS%%\Windows /f ALL
echo wpeutil reboot
) > "$tmp\Mount\Windows\System32\startnet.cmd"

dism /Unmount-Image /MountDir:"$tmp\Mount" /Commit

echo ========================================================
echo   [4/4] NAP LENH KHOI DONG VAO RAMDISK
echo ========================================================
copy /y C:\Windows\System32\boot.sdi "$tmp\boot.sdi"
bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$($safe.DriveLetter):
bcdedit /set {ramdiskoptions} ramdisksdipath \VietToolbox_Setup\boot.sdi
for /f "tokens=2 delims={}" %%g in ('bcdedit /create /d "VietToolbox_Setup" /application osloader') do set "guid={%%g}"
bcdedit /set {^!guid^!} device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}"
bcdedit /set {^!guid^!} osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}"
bcdedit /set {^!guid^!} systemroot \windows
bcdedit /set {^!guid^!} winpe yes
bcdedit /set {^!guid^!} detecthal yes
bcdedit /bootsequence {^!guid^!} /addfirst

echo --------------------------------------------------------
echo   XONG ROI SEP OI! MOI THU DA NAP VAO RAM.
echo   BAM PHIM BAT KY DE KET THUC ROI RESTART MAY.
echo --------------------------------------------------------
pause
exit
"@
    $batchPath = "$tmp\Execute.bat"
    Set-Content $batchPath $batchScript -Encoding Ascii
    Start-Process cmd.exe -ArgumentList "/c `"$batchPath`"" -Verb RunAs -Wait
    [System.Windows.MessageBox]::Show("Nếu bảng đen chạy xong không lỗi, sếp Restart máy nhé!", "Kết quả")
})
$window.ShowDialog() | Out-Null