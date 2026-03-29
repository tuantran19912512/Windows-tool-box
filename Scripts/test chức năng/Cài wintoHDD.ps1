# ==============================================================================
# Tên công cụ: VIETTOOLBOX MASTER (V28.45) - BẢN CƯỠNG CHẾ THÀNH CÔNG
# Đặc trị: Khắc phục lỗi Restart vào lại Win cũ, Tắt Fast Startup, Ép hiện Menu
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. DI CƯ SANG Ổ KHÁC C: ---
if ($PSScriptRoot.StartsWith("C:", "CurrentCultureIgnoreCase")) {
    $Other = Get-Volume | Where-Object {$_.DriveLetter -ne "C" -and $_.DriveType -eq "Fixed" -and $_.SizeRemaining -gt 25GB} | Select-Object -First 1
    if ($Other) {
        $Path = Join-Path ($Other.DriveLetter + ":\") "VietToolbox_Temp"
        if (!(Test-Path $Path)) { New-Item $Path -Type Directory | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $Path -Recurse -Force
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Path\$(Split-Path $PSCommandPath -Leaf)`"" -Verb RunAs; exit
    }
}

# --- 2. GIAO DIỆN (SẾP GIỮ NGUYÊN) ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Master V28.45" Width="700" Height="700" Background="#F3F4F6" WindowStartupLocation="CenterScreen">
    <StackPanel Margin="30">
        <TextBlock Text="VIETTOOLBOX - FORCE BOOT EDITION" FontSize="20" FontWeight="Bold" Foreground="#1E40AF" HorizontalAlignment="Center" Margin="0,0,0,20"/>
        <TextBlock Text="1. CHỌN BỘ CÀI (WIM/ISO):" FontWeight="Bold" Margin="0,0,0,5"/>
        <TextBox Name="TxtFile" Height="30" IsReadOnly="True" Margin="0,0,0,10"/>
        <Button Name="BtnFile" Content="📁 Duyệt File" Height="30" Margin="0,0,0,20"/>
        
        <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Height="25" Foreground="#10B981"/>
        <TextBlock Name="TxtStep" Text="Đang chờ lệnh..." HorizontalAlignment="Center" Margin="0,5,0,20" FontWeight="SemiBold"/>

        <Button Name="BtnRun" Content="🚀 BẮT ĐẦU CÀI ĐẶT &amp; ÉP BOOT" Height="65" Background="#1E40AF" Foreground="White" FontWeight="Bold" FontSize="18"/>
    </StackPanel>
</Window>
"@
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML))))
$txtFile = $window.FindName("TxtFile"); $btnFile = $window.FindName("BtnFile"); $btnRun = $window.FindName("BtnRun")
$progBar = $window.FindName("ProgBar"); $txtStep = $window.FindName("TxtStep")

function Log ($val, $text) { $progBar.Value = $val; $txtStep.Text = $text; [System.Windows.Forms.Application]::DoEvents() }

$btnFile.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter = "Windows Image|*.iso;*.wim;*.esd"
    if ($fd.ShowDialog() -eq "OK") { $txtFile.Text = $fd.FileName }
})

# --- CHỈ SỬA ĐOẠN LÕI THỰC THI (BƯỚC 5) TRONG BUTTON RUN ---
$btnRun.Add_Click({
    # ... (Các bước 1 đến 4 sếp giữ nguyên) ...

    # BƯỚC 5: ÉP BOOT RAMDISK (BẢN TRỊ VIRTUALBOX)
    Log 95 "🚩 Bước 5/5: Đang cưỡng chế nạp Boot vào Máy Ảo..."
    
    # 1. Tắt Fast Startup (Hibernate)
    powercfg /h off | Out-Null
    
    # 2. Chuẩn bị file
    Copy-Item "C:\Windows\System32\boot.sdi" "$tmp\boot.sdi" -Force
    
    # 3. Tạo Menu Boot RAMDISK
    bcdedit /set "{ramdiskoptions}" ramdisksdidevice partition=$($safe.DriveLetter): | Out-Null
    bcdedit /set "{ramdiskoptions}" ramdisksdipath \VietToolbox_Setup\boot.sdi | Out-Null
    
    $id = ((bcdedit /create /d "VietToolbox_Setup" /application osloader) -match '\{.*\}')[0]
    bcdedit /set $id device "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id osdevice "ramdisk=[$($safe.DriveLetter):]\VietToolbox_Setup\boot.wim,{ramdiskoptions}" | Out-Null
    bcdedit /set $id systemroot \windows | Out-Null
    bcdedit /set $id winpe yes | Out-Null
    bcdedit /set $id detecthal yes | Out-Null
    
    # CHIÊU CUỐI CHO VIRTUALBOX:
    # Ép hiện Menu kiểu Legacy (Đen trắng) để nó không bỏ qua được
    bcdedit /set "{current}" bootmenupolicy legacy | Out-Null
    bcdedit /timeout 30 | Out-Null
    bcdedit /displayorder $id /addfirst | Out-Null
    bcdedit /default $id | Out-Null # Đẩy Tool làm mặc định
    
    Log 100 "✅ ĐÃ XONG! SẾP RESTART VM NGAY."
    
    # Thông báo đặc biệt cho VirtualBox
    $msg = "Sếp lưu ý:`r`n1. Nếu máy ảo vào thẳng Win cũ, hãy tắt Secure Boot trong Settings của VirtualBox.`r`n2. Khi khởi động, nếu thấy Menu đen trắng, hãy chọn 'VietToolbox_Setup'."
    [System.Windows.MessageBox]::Show($msg, "Thông báo")
    
    # Restart cưỡng chế
    Restart-Computer -Force
})

$window.ShowDialog() | Out-Null