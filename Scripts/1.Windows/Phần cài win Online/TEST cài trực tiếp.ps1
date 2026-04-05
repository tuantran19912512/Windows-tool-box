# ==============================================================================
# VIETTOOLBOX V40.4 - FIX COMBOBOX DROPDOWN TEXT COLOR
# ==============================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. GIAO DIỆN XAML ĐÃ SỬA MÀU CHỮ DANH SÁCH ---
$MaXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V40.4 - Full Setup" Height="700" Width="650" 
        WindowStartupLocation="CenterScreen" Background="#0A0A0A" ResizeMode="NoResize">
    <Grid Margin="25">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,25">
            <TextBlock Text="VIETTOOLBOX V40.4" FontSize="36" FontWeight="Black" Foreground="#00adb5" />
            <TextBlock Text="HỆ THỐNG TRIỂN KHAI WINDOWS TỰ ĐỘNG - KÈM REMOTE" FontSize="11" Foreground="#444" Margin="2,0,0,0"/>
        </StackPanel>

        <TabControl Grid.Row="1" Background="#111" BorderBrush="#222" BorderThickness="1">
            <TabItem Header=" CÀI ĐẶT " Padding="15,8">
                <StackPanel Margin="20">
                    <TextBlock Text="FILE NGUỒN (ISO/WIM/ESD):" Foreground="#888" Margin="0,0,0,8" FontSize="10" FontWeight="Bold"/>
                    <Grid Margin="0,0,0,20">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                        <TextBox Name="txtWim" IsReadOnly="True" Height="38" Background="#050505" Foreground="#00adb5" VerticalContentAlignment="Center" Padding="10,0" BorderBrush="#222"/>
                        <Button Name="btnWim" Grid.Column="1" Content="CHỌN FILE" Margin="10,0,0,0" Cursor="Hand" Background="#00adb5" Foreground="White" FontWeight="Bold"/>
                    </Grid>
                    <TextBlock Text="PHIÊN BẢN HỆ ĐIỀU HÀNH:" Foreground="#888" Margin="0,0,0,8" FontSize="10" FontWeight="Bold"/>
                    
                    <ComboBox Name="cmbIndex" Height="38" Background="#1A1A1A" Foreground="White" BorderBrush="#222" Margin="0,0,0,20">
                        <ComboBox.ItemContainerStyle>
                            <Style TargetType="ComboBoxItem">
                                <Setter Property="Foreground" Value="Black"/>
                                <Setter Property="Padding" Value="5"/>
                            </Style>
                        </ComboBox.ItemContainerStyle>
                    </ComboBox>
                </StackPanel>
            </TabItem>
            <TabItem Header=" TỰ ĐỘNG HÓA " Padding="15,8">
                <Grid Margin="20">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0">
                        <CheckBox Name="chkBitLocker" Content="Vô hiệu BitLocker" Foreground="#FFB300" IsChecked="True" Margin="0,0,0,18" FontWeight="Bold"/>
                        <CheckBox Name="chkOOBE" Content="Bypass TPM 2.0 / NRO" Foreground="White" IsChecked="True" Margin="0,0,0,18"/>
                        <CheckBox Name="chkAnydesk" Content="Cài AnyDesk tự bật" Foreground="#4CAF50" IsChecked="True" Margin="0,0,0,18"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1">
                        <CheckBox Name="chkActive" Content="Kích hoạt Win/Office" Foreground="#00adb5" IsChecked="True" Margin="0,0,0,18"/>
                        <CheckBox Name="chkApps" Content="Cài Chrome + WinRAR" Foreground="White" IsChecked="True"/>
                    </StackPanel>
                </Grid>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="2" Margin="0,25,0,0">
            <ProgressBar Name="pgBar" Height="4" Background="#111" Foreground="#00adb5" BorderThickness="0" Margin="0,0,0,15"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng." Foreground="#555" HorizontalAlignment="Center" FontSize="11" Margin="0,0,0,15"/>
            <Button Name="btnStart" Content="BẮT ĐẦU QUY TRÌNH MASTER" Height="60" Background="#D32F2F" Foreground="White" FontSize="18" FontWeight="Black" IsEnabled="False" Cursor="Hand"/>
        </StackPanel>
    </Grid>
</Window>
"@

try {
    $DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaXAML)))
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)
} catch {
    [System.Windows.MessageBox]::Show("Lỗi cấu trúc XAML: $($_.Exception.Message)"); exit
}

# --- 2. LIÊN KẾT GIAO DIỆN VỚI CODE ---
$txtWim = $CuaSo.FindName("txtWim"); $btnWim = $CuaSo.FindName("btnWim"); $cmbIndex = $CuaSo.FindName("cmbIndex")
$chkBitLocker = $CuaSo.FindName("chkBitLocker"); $chkOOBE = $CuaSo.FindName("chkOOBE")
$chkAnydesk = $CuaSo.FindName("chkAnydesk"); $chkActive = $CuaSo.FindName("chkActive")
$chkApps = $CuaSo.FindName("chkApps")
$pgBar = $CuaSo.FindName("pgBar"); $lblStatus = $CuaSo.FindName("lblStatus"); $btnStart = $CuaSo.FindName("btnStart")

function Refresh-UI { [System.Windows.Forms.Application]::DoEvents() }

# --- 3. XỬ LÝ CHỌN FILE ---
$btnWim.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $path = $fd.FileName; $cmbIndex.Items.Clear(); $lblStatus.Text = "Đang quét thông tin Image..."; Refresh-UI
        try {
            $ext = [System.IO.Path]::GetExtension($path).ToLower()
            if ($ext -eq ".iso") {
                $m = Mount-DiskImage -ImagePath $path -PassThru; $dv = ($m | Get-Volume).DriveLetter; $w = "$dv`:\sources\install.wim"
                if (!(Test-Path $w)) { $w = "$dv`:\sources\install.esd" }
                Get-WindowsImage -ImagePath $w | ForEach-Object { $null = $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
                Dismount-DiskImage -ImagePath $path | Out-Null
            } else {
                Get-WindowsImage -ImagePath $path | ForEach-Object { $null = $cmbIndex.Items.Add("$($_.ImageIndex) - $($_.ImageName)") }
            }
            $txtWim.Text = $path; $cmbIndex.SelectedIndex = 0; $btnStart.IsEnabled = $true; $lblStatus.Text = "Sẵn sàng."
        } catch { [System.Windows.MessageBox]::Show("Không thể đọc tệp Image.") }
    }
})

# --- 4. LOGIC CÀI ĐẶT CHÍNH ---
$btnStart.Add_Click({
    $btnStart.IsEnabled = $false; $bootDir = "C:\VietBoot"
    if (!(Test-Path $bootDir)) { New-Item $bootDir -ItemType Directory -Force | Out-Null }
    
    try {
        $lblStatus.Text = "Đang gỡ BitLocker hệ thống (nếu có)..."; Refresh-UI
        manage-bde -off C: | Out-Null
        $timeout = 0; while ($timeout -lt 5) { $st = manage-bde -status C:; if ($st -match "Fully Decrypted|None") { break }; Start-Sleep -Seconds 2; $timeout++ }

        $wimPath = $txtWim.Text; $targetWimName = "install_core.wim"
        $lblStatus.Text = "Đang Turbo Copy bộ cài (Robocopy /J)..."; Refresh-UI
        if ($wimPath.EndsWith(".iso")) {
            $m = Mount-DiskImage -ImagePath $wimPath -PassThru; $dv = ($m | Get-Volume).DriveLetter
            $srcPath = "$dv`:\sources"; $srcFile = "install.wim"; if (!(Test-Path "$srcPath\install.wim")) { $srcFile = "install.esd" }
            Start-Process robocopy.exe -ArgumentList "`"$srcPath`" `"$bootDir`" $srcFile /J /MT:16" -Wait -WindowStyle Hidden
            Dismount-DiskImage -ImagePath $wimPath | Out-Null
            $targetWimName = if ($srcFile -eq "install.esd") { "install_core.esd" } else { "install_core.wim" }
            Rename-Item "$bootDir\$srcFile" $targetWimName -Force
        } else {
            $fName = Split-Path $wimPath -Leaf
            Start-Process robocopy.exe -ArgumentList "`"$(Split-Path $wimPath)`" `"$bootDir`" $fName /J" -Wait -WindowStyle Hidden
            Rename-Item "$bootDir\$fName" $targetWimName -Force
        }

        $temp = "$bootDir\Data"; New-Item $temp -ItemType Directory -Force | Out-Null

        # --- Tạo SetupComplete.cmd ---
        $sc = "@echo off`n"
        if ($chkBitLocker.IsChecked) { $sc += "manage-bde -off C:`n" }
        if ($chkActive.IsChecked) { $sc += "powershell -c `"irm https://get.activated.win | iex`" /HWID`n" }
        if ($chkApps.IsChecked) {
            $sc += "winget install --id Google.Chrome --silent --accept-source-agreements`n"
            $sc += "winget install --id WinRAR.WinRAR --silent`n"
        }
        $sc += "rd /s /q `"C:\VietBoot`"`ndel `"%~f0`""
        $sc | Out-File "$temp\SetupComplete.cmd" -Encoding ASCII

        # --- Tạo Script Tự bật AnyDesk ---
        if ($chkAnydesk.IsChecked) {
            $any = "@echo off`n:check_net`nping 8.8.8.8 -n 1 >nul`nif errorlevel 1 (timeout /t 5 >nul & goto check_net)`n"
            $any += "curl -L -o `"%public%\Desktop\AnyDesk.exe`" `"https://download.anydesk.com/AnyDesk.exe`"`n"
            $any += "start `"`" `"%public%\Desktop\AnyDesk.exe`"`ndel `"%~f0`""
            $any | Out-File "$temp\Any.cmd" -Encoding ASCII
        }

        # --- Tạo Unattend.xml (Bypass User + Auto Logon Admin) ---
        $u = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><NetworkLocation>Work</NetworkLocation><ProtectYourPC>3</ProtectYourPC></OOBE>
            <UserAccounts><LocalAccounts><LocalAccount action="Add"><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts>
            <AutoLogon><Enabled>true</Enabled><Username>Admin</Username></AutoLogon>
        </component>
    </settings>
</unattend>
"@
        $u | Out-File "$temp\u.xml" -Encoding UTF8

        # --- Tạo Startnet.cmd (Môi trường WinPE) ---
        $idx = $cmbIndex.SelectedItem.ToString().Split('-')[0].Trim()
        $sn = "@echo off`nwpeinit`necho [VIETTOOLBOX] DANG TIM BO CAI...`n"
        $sn += "for %%i in (C D E F G H I J K L) do (if exist %%i:\VietBoot\$targetWimName set W=%%i:\VietBoot\$targetWimName)`n"
        $sn += "format C: /q /y /v:Windows`ndism /Apply-Image /ImageFile:%W% /Index:$idx /ApplyDir:C:\`n"
        if ($chkOOBE.IsChecked) {
            $sn += "reg load HKLM\O_S C:\Windows\System32\config\SOFTWARE`n"
            $sn += "reg add HKLM\O_S\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f`n"
            $sn += "reg unload HKLM\O_S`n"
        }
        $sn += "mkdir C:\Windows\Panther >nul & copy X:\Windows\System32\u.xml C:\Windows\Panther\unattend.xml /Y`n"
        $sn += "mkdir C:\Windows\Setup\Scripts >nul & copy X:\Windows\System32\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y`n"
        
        if ($chkAnydesk.IsChecked) {
            $sn += "mkdir `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup`" >nul 2>&1`n"
            $sn += "copy X:\Windows\System32\Any.cmd `"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Any.cmd`" /Y`n"
        }
        
        $sn += "bcdboot C:\Windows /s C: /f ALL`nwpeutil reboot"
        $sn | Out-File "$temp\s.cmd" -Encoding ASCII

        # --- Nhúng vào Boot.wim ---
        $lblStatus.Text = "Đang xây dựng môi trường Boot..."; Refresh-UI
        Copy-Item "C:\Windows\System32\Recovery\WinRE.wim" "$bootDir\boot.wim" -Force
        Copy-Item "C:\Windows\Boot\EFI\boot.sdi" "$bootDir\boot.sdi" -Force

        if (!(Test-Path "$bootDir\wimlib-imagex.exe")) {
            Invoke-WebRequest -Uri "https://wimlib.net/downloads/wimlib-1.14.5-windows-x86_64-bin.zip" -OutFile "$bootDir\w.zip"
            Expand-Archive "$bootDir\w.zip" "$bootDir\wim" -Force
            Move-Item "$bootDir\wim\*\wimlib-imagex.exe" "$bootDir\wimlib-imagex.exe" -Force
            Move-Item "$bootDir\wim\*\*.dll" "$bootDir\" -Force; Remove-Item "$bootDir\wim" -Recurse -Force
        }

        $fT = "$bootDir\task.txt"
        "add `"$temp\u.xml`" `"\Windows\System32\u.xml`"`nadd `"$temp\SetupComplete.cmd`" `"\Windows\System32\SetupComplete.cmd`"`nadd `"$temp\s.cmd`" `"\Windows\System32\startnet.cmd`"" | Out-File $fT -Encoding utf8
        if ($chkAnydesk.IsChecked) { "add `"$temp\Any.cmd`" `"\Windows\System32\Any.cmd`"" | Out-File $fT -Append -Encoding utf8 }
        
        Start-Process "$bootDir\wimlib-imagex.exe" "update `"$bootDir\boot.wim`" 1 < `"$fT`"" -Wait -WindowStyle Hidden

        # --- Đăng ký BCD ---
        $lblStatus.Text = "Đang đăng ký lệnh Boot... Sắp khởi động lại!"; Refresh-UI
        $guid = "{$( [guid]::NewGuid().ToString() )}"
        bcdedit /create $guid /d "VietInstaller" /application osloader | Out-Null
        bcdedit /set $guid device "ramdisk=[C:]\VietBoot\boot.wim,{76127444-6666-4444-5555-222222222222}" | Out-Null
        bcdedit /set $guid osdevice "ramdisk=[C:]\VietBoot\boot.wim,{76127444-6666-4444-5555-222222222222}" | Out-Null
        bcdedit /set $guid path "\windows\system32\boot\winload.efi" | Out-Null
        bcdedit /set $guid systemroot \windows | Out-Null
        bcdedit /set $guid winpe yes | Out-Null
        bcdedit /displayorder $guid /addfirst | Out-Null; bcdedit /default $guid | Out-Null; bcdedit /timeout 0 | Out-Null

        $lblStatus.Text = "HOÀN TẤT! Máy sẽ khởi động lại trong giây lát..."; $pgBar.Value = 100; Refresh-UI
        Start-Sleep -Seconds 3; Restart-Computer -Force
    } catch {
        [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)")
        $btnStart.IsEnabled = $true
    }
})

$CuaSo.ShowDialog() | Out-Null