# ==============================================================================
# Tên công cụ: VIETTOOLBOX - ULTIMATE REINSTALLER (V28.20)
# Tác giả: Kỹ Thuật Viên (Bản quyền dành riêng cho sếp Tuấn)
# Đặc trị: Tự săn WinRE, Bơm Driver Intel RST/VMD & AMD RAID, Terminal UI cực ngầu
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. TỰ ĐỘNG DI CƯ SANG Ổ AN TOÀN ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Other = Get-Volume | Where-Object { $_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 20GB } | Select-Object -First 1
    if ($Other) {
        $Path = Join-Path ($Other.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $Path -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Path\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN XAML CHUẨN WINTOHDD ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        Title="VietToolbox - Reinstall Windows" Width="750" Height="860" Background="#F3F4F6" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border BorderBrush="#D1D5DB" BorderThickness="1">
        <Grid>
            <Border Height="45" VerticalAlignment="Top" Background="White">
                <Grid>
                    <StackPanel Orientation="Horizontal" Margin="15,0">
                        <TextBlock Text="VietToolbox" Foreground="#0284C7" FontSize="18" FontWeight="Bold" VerticalAlignment="Center"/>
                        <TextBlock Text=" Reinstall Windows (V28.20)" Foreground="#0284C7" FontSize="16" VerticalAlignment="Center" Margin="5,0,0,0"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,10,0">
                        <Button Name="BtnMin" Content="—" Width="30" Background="Transparent" BorderThickness="0" Cursor="Hand"/>
                        <Button Name="BtnClose" Content="✕" Width="30" Background="Transparent" Foreground="Red" BorderThickness="0" Cursor="Hand"/>
                    </StackPanel>
                </Grid>
            </Border>

            <StackPanel Margin="30,65,30,20">
                <TextBlock Text="1. CHỌN FILE BỘ CÀI (WIM / ESD / ISO):" Margin="0,0,0,5" Foreground="#374151" FontWeight="Bold"/>
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtFile" Height="30" Background="White" BorderBrush="#9CA3AF" Padding="8,0" VerticalContentAlignment="Center" IsReadOnly="True"/>
                    <Button Name="BtnFile" Grid.Column="1" Content="📁 Duyệt file..." Width="110" Margin="5,0,0,0" Background="#E5E7EB" Cursor="Hand" FontWeight="Bold"/>
                </Grid>

                <TextBlock Text="2. CHỌN PHIÊN BẢN MUỐN CÀI:" Margin="0,0,0,5" Foreground="#374151" FontWeight="Bold"/>
                <ComboBox Name="ComboEdition" Height="30" Margin="0,0,0,20" Background="White" BorderBrush="#9CA3AF" Padding="5"/>

                <TextBlock Text="3. PHÂN VÙNG HỆ THỐNG (EFI):" Margin="0,0,0,5" Foreground="#374151" FontWeight="Bold"/>
                <Border BorderBrush="#9CA3AF" BorderThickness="1" Height="80" Margin="0,0,0,20" Background="White">
                    <ScrollViewer HorizontalScrollBarVisibility="Auto"><StackPanel Name="MapEFI" Orientation="Horizontal" Margin="5"/></ScrollViewer>
                </Border>

                <TextBlock Text="4. PHÂN VÙNG CÀI WINDOWS (C:):" Margin="0,0,0,5" Foreground="#374151" FontWeight="Bold"/>
                <Border BorderBrush="#9CA3AF" BorderThickness="1" Height="80" Margin="0,0,0,20" Background="White">
                    <ScrollViewer HorizontalScrollBarVisibility="Auto"><StackPanel Name="MapBoot" Orientation="Horizontal" Margin="5"/></ScrollViewer>
                </Border>

                <TextBlock Text="TÙY CHỌN NÂNG CAO:" Margin="0,0,0,10" Foreground="#374151" FontWeight="Bold"/>
                <StackPanel Margin="10,0,0,15">
                    <CheckBox Name="OptDriver" Content="Tự động bơm Driver Intel RST/VMD &amp; AMD RAID (Yêu cầu thư mục 'Drivers' nằm cạnh file cài)" IsChecked="True" Margin="0,0,0,10" FontWeight="Bold" Foreground="#0284C7"/>
                    <CheckBox Name="OptClean" Content="Tự động xóa dữ liệu tạm và dọn rác sau khi cài xong" IsChecked="True" Margin="0,0,0,10" FontWeight="Bold" Foreground="#374151"/>
                </StackPanel>

                <Separator Margin="0,5,0,20" Background="#D1D5DB"/>
                
                <Grid>
                    <TextBlock Name="TxtStatus" Text="Sẵn sàng." VerticalAlignment="Center" Foreground="#059669" FontWeight="Bold"/>
                    <Button Name="BtnRun" Content="🚀 BẮT ĐẦU CÀI ĐẶT" HorizontalAlignment="Right" Width="180" Height="45" Background="#10B981" Foreground="White" FontWeight="Bold" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                </Grid>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))

# --- 3. ÁNH XẠ BIẾN ---
$txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile")
$comboEdition = $window.FindName("ComboEdition"); $mapEFI = $window.FindName("MapEFI")
$mapBoot = $window.FindName("MapBoot"); $btnRun = $window.FindName("BtnRun")
$txtStatus = $window.FindName("TxtStatus"); $optDriver = $window.FindName("OptDriver")
$optClean = $window.FindName("OptClean")

$Global:EFI_PartNum = $null; $Global:Boot_PartNum = $null
$Global:UI_EFI_Blocks = @(); $Global:UI_Boot_Blocks = @()

# --- 4. VẼ DISK MAP ---
function Draw-Map {
    $os = Get-Partition -DriveLetter "C" -ErrorAction SilentlyContinue
    $disk = if ($os) { $os.DiskNumber } else { 0 }
    $parts = Get-Partition -DiskNumber $disk | Sort-Object Offset
    foreach ($p in $parts) {
        if ($p.Size -lt 20MB) { continue }
        $w = [math]::Max(90, [math]::Min(350, ($p.Size/100GB)*400))
        $letter = if ($p.DriveLetter) { "$($p.DriveLetter):" } else { "(*:)" }
        $label = if ($p.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $p.IsActive) { "SYSTEM" } else { "DATA" }
        
        # UI cho EFI
        $bE = New-Object System.Windows.Controls.Border
        $bE.Width = $w; $bE.Background = "#0891B2"; $bE.Margin = "0,0,5,0"; $bE.BorderThickness = if ($label -eq "SYSTEM") { 2 } else { 1 }
        $bE.BorderBrush = if ($label -eq "SYSTEM") { "Red" } else { "White" }
        $tE = New-Object System.Windows.Controls.TextBlock; $tE.Text = "$letter`n$label`n$([math]::Round($p.Size/1GB,1))GB"; $tE.Foreground="White"; $tE.TextAlignment="Center"; $bE.Child=$tE
        $null = $mapEFI.Children.Add($bE); $Global:UI_EFI_Blocks += $bE
        if ($label -eq "SYSTEM") { $Global:EFI_PartNum = $p.PartitionNumber }
        $bE.Add_MouseDown({ foreach($b in $Global:UI_EFI_Blocks){$b.BorderBrush="White";$b.BorderThickness=1}; $this.BorderBrush="Red";$this.BorderThickness=2; $Global:EFI_PartNum = $p.PartitionNumber })

        # UI cho Boot
        $bB = New-Object System.Windows.Controls.Border
        $bB.Width = $w; $bB.Background = "#0891B2"; $bB.Margin = "0,0,5,0"; $bB.BorderThickness = if ($p.DriveLetter -eq "C") { 2 } else { 1 }
        $bB.BorderBrush = if ($p.DriveLetter -eq "C") { "Red" } else { "White" }
        $tB = New-Object System.Windows.Controls.TextBlock; $tB.Text = "$letter`n$label`n$([math]::Round($p.Size/1GB,1))GB"; $tB.Foreground="White"; $tB.TextAlignment="Center"; $bB.Child=$tB
        $null = $mapBoot.Children.Add($bB); $Global:UI_Boot_Blocks += $bB
        if ($p.DriveLetter -eq "C") { $Global:Boot_PartNum = $p.PartitionNumber }
        $bB.Add_MouseDown({ foreach($b in $Global:UI_Boot_Blocks){$b.BorderBrush="White";$b.BorderThickness=1}; $this.BorderBrush="Red";$this.BorderThickness=2; $Global:Boot_PartNum = $p.PartitionNumber })
    }
}
Draw-Map

# --- 5. CHỌN FILE & ĐỌC INDEX ---
$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "Windows Image (*.iso;*.wim;*.esd)|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") {
        $txtFile.Text = $fd.FileName; $btnFile.IsEnabled = $false; $comboEdition.Items.Clear()
        $txtStatus.Text = "⏳ Đang quét danh sách phiên bản..."
        Start-Job -ScriptBlock {
            param($f)
            $w=$f; $m=$false; if($f.EndsWith(".iso")){$m=Mount-DiskImage $f -PassThru; $d=($m|Get-Volume).DriveLetter; $w="$($d):\sources\install.wim"; if(!(Test-Path $w)){$w="$($d):\sources\install.esd"}}
            $res = Get-WindowsImage -ImagePath $w | ForEach-Object { "Index $($_.ImageIndex): $($_.ImageName)" }
            if($m){Dismount-DiskImage $f | Out-Null}; return $res
        } -ArgumentList $txtFile.Text | Wait-Job | Receive-Job | ForEach-Object { [void]$comboEdition.Items.Add($_) }
        if($comboEdition.Items.Count -gt 0){$comboEdition.SelectedIndex=0}; $btnFile.IsEnabled=$true; $txtStatus.Text="Sẵn sàng."
    }
})

# --- 6. THỰC THI (MA GIÁO + DRIVER + TERMINAL UI) ---
$btnRun.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtFile.Text) -or $comboEdition.SelectedIndex -lt 0) { return }
    if ([System.Windows.MessageBox]::Show("Xác nhận Restart để FORMAT C và cài lại Windows?", "Cảnh báo", 4, 32) -eq "Yes") {
        $btnRun.IsEnabled = $false; $txtStatus.Text = "⏳ Đang chuẩn bị môi trường RAMDISK... Vui lòng đợi!"
        $idx = [int]([regex]::Match($comboEdition.Text, "Index (\d+)").Groups[1].Value)
        $inj = $optDriver.IsChecked; $clean = $optClean.IsChecked

        Start-Job -ScriptBlock {
            param($path, $index, $inject, $doClean)
            # A. Tạo Folder tạm trên ổ D/E
            $safe = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 15GB} | Select-Object -First 1
            $tmp = "$($safe.DriveLetter):\VietToolbox_Setup"; if(!(Test-Path $tmp)){New-Item $tmp -Type Directory}
            
            # B. Di tản Bộ cài
            $wimDest = "$tmp\install.wim"; if($path.EndsWith(".iso")){ $m=Mount-DiskImage $path -PassThru; $d=($m|Get-Volume).DriveLetter; $s="$($d):\sources\install.wim"; if(!(Test-Path $s)){$s="$($d):\sources\install.esd"; $wimDest="$tmp\install.esd"}; Copy-Item $s $wimDest -Force; Dismount-DiskImage $path | Out-Null }
            else { if($path.EndsWith(".esd")){$wimDest="$tmp\install.esd"}; Copy-Item $path $wimDest -Force }

            # C. Săn WinRE làm Boot
            reagentc /disable | Out-Null; $re = "C:\Windows\System32\Recovery\Winre.wim"; if(!(Test-Path $re)){$re=(Get-ChildItem "C:\Recovery" -Filter "Winre.wim" -Recurse -Hidden | Select-Object -First 1).FullName}
            Copy-Item $re "$tmp\boot.wim" -Force

            # D. Mổ bụng Boot.wim để bơm Driver & Lệnh tự động
            $mDir = "$tmp\Mount"; New-Item $mDir -Type Directory | Out-Null
            dism /Mount-Image /ImageFile:"$tmp\boot.wim" /Index:1 /MountDir:"$mDir" | Out-Null
            
            # Bơm Driver nếu sếp yêu cầu
            if($inject){ $dFolder = Join-Path (Split-Path $path) "Drivers"; if(Test-Path $dFolder){ dism /Image:"$mDir" /Add-Driver /Driver:"$dFolder" /Recurse /ForceUnsigned | Out-Null } }

            # Viết Script Terminal cho WinPE
            $cmd = "@echo off`r`ncolor 0B`r`ncls`r`necho ========================================================`r`n"
            $cmd += "echo       VIETTOOLBOX AUTO INSTALLER - TERMINAL UI`r`necho ========================================================`r`n"
            $cmd += "wpeinit`r`nfor %%I in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%I:\VietToolbox_Setup\install*`" set W=%%I:\VietToolbox_Setup\install`r`n"
            $cmd += "if exist %W%.wim (set WF=%W%.wim) else (set WF=%W%.esd)`r`n"
            $cmd += "for %%J in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist `"%%J:\Windows\System32\cmd.exe`" if not exist `"%%J:\VietToolbox_Setup`" set OS=%%J:`r`n"
            $cmd += "echo [STEP 1/3] FORMATTING %OS%...`r`nformat %OS% /fs:ntfs /q /y >nul`r`n"
            $cmd += "echo [STEP 2/3] APPLYING WINDOWS IMAGE...`r`ndism /Apply-Image /ImageFile:`"%WF%`" /Index:$index /ApplyDir:%OS%\`r`n"
            $cmd += "echo [STEP 3/3] REBUILDING BOOT MANAGER...`r`nbcdboot %OS%\Windows /f ALL >nul`r`n"
            # Lệnh tự dọn rác sau khi vào Win
            if($doClean){ $cmd += "echo rd /s /q `"$($safe.DriveLetter):\VietToolbox_Setup`" > %OS%\Windows\Setup\Scripts\ErrorHandler.cmd`r`n" }
            $cmd += "echo [DONE] RESTARTING IN 5 SECONDS...`r`ntimeout /t 5 >nul`r`nwpeutil reboot"
            Set-Content "$mDir\Windows\System32\startnet.cmd" $cmd -Encoding Ascii
            dism /Unmount-Image /MountDir:"$mDir" /Commit | Out-Null

            # E. Cấu hình BCD Boot vào RAM
            Copy-Item "$env:windir\System32\boot.sdi" "$tmp\boot.sdi" -Force
            bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
            bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
            $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
            bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
            bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
            bcdedit /set $id systemroot \windows | Out-Null; bcdedit /set $id winpe yes | Out-Null
            bcdedit /bootsequence $id /addfirst | Out-Null
        } -ArgumentList $txtFile.Text, $idx, $inj, $clean | Wait-Job
        
        $txtStatus.Text = "✅ Hoàn tất! Hãy Restart máy để bắt đầu."
        [System.Windows.MessageBox]::Show("Mọi thứ đã sẵn sàng! Bấm OK để Restart máy. Quá trình cài đặt sẽ tự chạy 100%.", "Thành công")
    }
})

$window.FindName("BtnClose").Add_Click({ $window.Close() })
$window.FindName("BtnMin").Add_Click({ $window.WindowState = "Minimized" })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })
$window.ShowDialog() | Out-Null