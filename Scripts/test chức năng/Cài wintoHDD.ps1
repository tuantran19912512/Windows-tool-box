# ==============================================================================
# Tên công cụ: VIETTOOLBOX - REINSTALLER (V28.23 - FIX BOOT & SHOW PROCESS)
# Đặc trị: Hiện bảng đen để sếp theo dõi tiến trình, Fix lỗi không vào được Boot RAM
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ (GIỮ NGUYÊN) ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Other = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Other) {
        $Path = Join-Path ($Other.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $Path)) { New-Item $Path -Type Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $Path -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Path\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN (LƯỢC BỚT CHO NHẸ) ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V28.23" Width="600" Height="500" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <StackPanel Margin="20">
        <TextBlock Text="TRÌNH CÀI WIN MA GIÁO - BẢN FIX LỖI" FontSize="18" FontWeight="Bold" Foreground="#0284C7" HorizontalAlignment="Center" Margin="0,0,0,20"/>
        <TextBlock Text="Chọn file cài (WIM/ISO):" FontWeight="Bold"/><Grid Margin="0,5,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBox Name="TxtFile" Height="25" IsReadOnly="True"/><Button Name="BtnFile" Grid.Column="1" Content="📁 Chọn" Width="60" Margin="5,0,0,0"/></Grid>
        <TextBlock Text="Chọn phiên bản:" FontWeight="Bold"/><ComboBox Name="ComboEdition" Height="25" Margin="0,5,0,20"/>
        <TextBlock Name="TxtStatus" Text="Lưu ý: Khi bấm Bắt đầu, bảng đen sẽ hiện lên. ĐỪNG TẮT NÓ!" Foreground="Red" FontWeight="Bold" TextWrapping="Wrap" HorizontalAlignment="Center"/>
        <Button Name="BtnRun" Content="🚀 BẮT ĐẦU CÀI ĐẶT (HIỆN TIẾN TRÌNH)" Height="50" Background="#10B981" Foreground="White" FontWeight="Bold" Margin="0,20,0,0"/>
    </StackPanel>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))
$txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile"); $comboEdition = $window.FindName("ComboEdition"); $btnRun = $window.FindName("BtnRun")

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtFile.Text = $fd.FileName; $images = Get-WindowsImage -ImagePath $txtFile.Text -ErrorAction SilentlyContinue
        if (!$images) { # Nếu là ISO thì Mount tạm để đọc
            $m = Mount-DiskImage $txtFile.Text -PassThru; $d = ($m|Get-Volume).DriveLetter; $w = "$($d):\sources\install.wim"; if(!(Test-Path $w)){$w="$($d):\sources\install.esd"}
            $images = Get-WindowsImage -ImagePath $w; Dismount-DiskImage $txtFile.Text | Out-Null
        }
        $images | ForEach-Object {[void]$comboEdition.Items.Add("Index $($_.ImageIndex): $($_.ImageName)")}; $comboEdition.SelectedIndex=0
    }
})

$btnRun.Add_Click({
    if(!$txtFile.Text){ return }
    $idx = [int]([regex]::Match($comboEdition.Text, "Index (\d+)").Groups[1].Value)
    $path = $txtFile.Text
    
    # --- THỰC THI TRỰC TIẾP (KHÔNG DÙNG JOB) ---
    # 1. Tìm ổ an toàn
    $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
    $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if(!(Test-Path $tmp)){New-Item $tmp -Type Directory -Force}

    # 2. Tạo file Batch để chạy nổi lên màn hình cho sếp xem
    $batchScript = @"
@echo off
title DANG THI TRIEN MA GIAO - VUI LONG DOI...
color 0B
echo --------------------------------------------------------
echo   BUOC 1: DICH CHUYEN BO CAI (DANG COPY, CHO TI...)
echo --------------------------------------------------------
if /i "%~x1"==".iso" (
    powershell -command "Mount-DiskImage '%path%'"
    for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%i:\sources\install.wim" set "src=%%i:\sources\install.wim"
    for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%i:\sources\install.esd" set "src=%%i:\sources\install.esd"
    copy /y "!src!" "$tmp\install.wim"
    powershell -command "Dismount-DiskImage '%path%'"
) else (
    copy /y "%path%" "$tmp\install.wim"
)

echo --------------------------------------------------------
echo   BUOC 2: SAN TIM WINRE (MOI TRUONG BOOT)
echo --------------------------------------------------------
reagentc /disable
copy /y C:\Windows\System32\Recovery\Winre.wim "$tmp\boot.wim"
if not exist "$tmp\boot.wim" (
    echo [LOI] Khong tim thay WinRE.wim! Vui long vut file boot.wim goc vao canh script.
    pause
    exit
)

echo --------------------------------------------------------
echo   BUOC 3: MO BUNG BOOT.WIM DE CAY LENH TU DONG
echo --------------------------------------------------------
if not exist "$tmp\Mount" md "$tmp\Mount"
dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:"$tmp\Mount"

:: Bơm Driver nếu có
if exist "$(Split-Path $path)\Drivers" (
    echo Dang bom Driver Intel/AMD...
    dism /Image:"$tmp\Mount" /Add-Driver /Driver:"$(Split-Path $path)\Drivers" /Recurse /ForceUnsigned
)

:: Bơm Apps nếu có
if exist "$(Split-Path $path)\Apps" (
    echo Dang bom Apps vao WinPE...
    xcopy "$(Split-Path $path)\Apps" "$tmp\Mount\Apps\" /e /y /i
)

:: Tạo file Startnet cho WinPE
(
echo @echo off
echo wpeinit
echo for %%%%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%%%i:\VietToolbox_Setup\install.wim" set "W=%%%%i:\VietToolbox_Setup\install.wim"
echo for %%%%j in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%%%j:\Windows\System32\cmd.exe" if not exist "%%%%j:\VietToolbox_Setup" set "OS=%%%%j:"
echo format %%OS%% /fs:ntfs /q /y
echo dism /Apply-Image /ImageFile:"%%W%%" /Index:$idx /ApplyDir:%%OS%%\
echo bcdboot %%OS%%\Windows /f ALL
echo echo [XONG] MAY SE RESTART SAU 5 GIAY...
echo timeout /t 5
echo wpeutil reboot
) > "$tmp\Mount\Windows\System32\startnet.cmd"

dism /Unmount-Image /MountDir:"$tmp\Mount" /Commit

echo --------------------------------------------------------
echo   BUOC 4: NAP MENU BOOT RAMDISK (QUAN TRONG NHAT)
echo --------------------------------------------------------
copy /y C:\Windows\System32\boot.sdi "$tmp\boot.sdi"
bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$($safe.DriveLetter):
bcdedit /set {ramdiskoptions} ramdisksdipath \VietToolbox_Setup\boot.sdi
for /f "tokens=2 delims={}" %%g in ('bcdedit /create /d "VietToolbox_Setup" /application osloader') do set "guid={%%g}"
bcdedit /set %guid% device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}"
bcdedit /set %guid% osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}"
bcdedit /set %guid% systemroot \windows
bcdedit /set %guid% winpe yes
bcdedit /set %guid% detecthal yes
bcdedit /bootsequence %guid% /addfirst

echo.
echo === [THANH CONG BÁ ĐAO] ===
echo Moi thu da san sang. Sep co the tat bang nay va Restart may!
pause
exit
"@
    $batchPath = "$tmp\Execute.bat"
    Set-Content $batchPath $batchScript -Encoding Ascii
    
    # Chạy file Batch bằng quyền Admin và HIỆN CỬA SỔ
    Start-Process cmd.exe -ArgumentList "/c `"$batchPath`"" -Verb RunAs -Wait
    
    [System.Windows.MessageBox]::Show("Đã thi triển xong! Nếu bảng đen báo 'Thành công' thì sếp Restart máy ngay nhé.", "Kết quả")
})
$window.ShowDialog() | Out-Null