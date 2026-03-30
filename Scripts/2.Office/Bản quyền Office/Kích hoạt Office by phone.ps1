# ==========================================================
# VIETTOOLBOX - OFFICE ACTIVATION V1.5 (DUAL-ENGINE)
# Đặc trị: Mất file ospp.vbs, Office Crack, Repack, C2R
# Tác giả: AI cộng sự của sếp Tuấn
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. GIAO DIỆN XAML (DARK MODE SIÊU CẤP)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Office Pro V1.5" Height="700" Width="650" 
        Background="#121212" WindowStyle="None" AllowsTransparency="True" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" Background="#1E1E1E" BorderBrush="#D83B01" BorderThickness="2">
        <Grid>
            <TextBlock Text="KÍCH HOẠT OFFICE - DUAL ENGINE (V1.5)" Foreground="#D83B01" FontSize="20" FontWeight="Bold" 
                       HorizontalAlignment="Center" Margin="0,20,0,0"/>
            
            <StackPanel Margin="35,60,35,20">
                <TextBlock Text="BƯỚC 0: Nhận diện phiên bản Office:" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <Button Name="BtnCheck" Content="🔍 KIỂM TRA OFFICE HIỆN TẠI" Height="40" Background="#444" Foreground="White" FontWeight="Bold" Margin="0,0,0,15" Cursor="Hand"/>

                <TextBlock Text="BƯỚC 1: Nhập Key Office (Retail/MAK):" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <Grid Margin="0,0,0,20">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtKey" Height="35" Background="#252525" Foreground="White" BorderThickness="1" BorderBrush="#444" Padding="5" FontSize="15" VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
                    <Button Name="BtnInstallKey" Grid.Column="1" Content="NẠP KEY" Margin="10,0,0,0" Background="#D83B01" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </Grid>

                <TextBlock Text="BƯỚC 2: Installation ID (IID) trích xuất:" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="TxtIID" Height="90" Background="#0F0F0F" Foreground="#00FF00" BorderThickness="1" BorderBrush="#333" IsReadOnly="True" Padding="10" FontSize="16" FontFamily="Consolas" TextWrapping="Wrap"/>
                
                <Grid Margin="0,10,0,20">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="BtnGetIID" Content="LẤY MÃ IID (QUÉT SÂU)" Height="40" Margin="0,0,5,0" Background="#0369A1" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                    <Button Name="BtnCopyIID" Grid.Column="1" Content="SAO CHÉP IID" Height="40" Margin="5,0,0,0" Background="#444" Foreground="White" Cursor="Hand"/>
                </Grid>

                <TextBlock Text="BƯỚC 3: Nhập mã Confirmation ID (CID):" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="TxtCID" Height="40" Background="#252525" Foreground="White" BorderThickness="1" BorderBrush="#D83B01" Padding="5" FontSize="18" VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>

                <Grid Margin="0,25,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="2*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="BtnActivate" Grid.Column="0" Content="KÍCH HOẠT OFFICE" Height="45" Margin="0,0,10,0" Background="#28A745" Foreground="White" FontWeight="Bold" FontSize="16" Cursor="Hand"/>
                    <Button Name="BtnExit" Grid.Column="1" Content="THOÁT" Height="45" Background="#DC3545" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </Grid>
                <TextBlock Name="TxtStatus" Text="Trạng thái: Sẵn sàng." Foreground="#888" FontSize="11" Margin="0,15,0,0" HorizontalAlignment="Center"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# 2. KHỞI TẠO UI
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$txtKey = $window.FindName("TxtKey"); $txtIID = $window.FindName("TxtIID"); $txtCID = $window.FindName("TxtCID")
$btnCheck = $window.FindName("BtnCheck"); $btnInstallKey = $window.FindName("BtnInstallKey")
$btnGetIID = $window.FindName("BtnGetIID"); $btnCopyIID = $window.FindName("BtnCopyIID")
$btnActivate = $window.FindName("BtnActivate"); $btnExit = $window.FindName("BtnExit"); $txtStatus = $window.FindName("TxtStatus")

# --- HÀM TÌM ĐƯỜNG DẪN OSPP (NẾU CÓ) ---
function Get-OSPP-Path {
    $paths = @("${env:ProgramFiles}\Microsoft Office\Office16", "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
               "${env:ProgramFiles}\Microsoft Office\Office15", "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
               "C:\Program Files\Common Files\microsoft shared\OfficeSoftwareProtectionPlatform")
    foreach ($p in $paths) { $f = "$p\ospp.vbs"; if (Test-Path $f) { return $f } }
    return $null
}

# --- HÀM QUÉT IID THÔNG MINH (CHỐT HẠ) ---
function Get-IID-Smart {
    $txtStatus.Text = "Đang quét IID hệ thống..."
    [System.Windows.Forms.Application]::DoEvents()
    
    $finalIID = ""
    # Cách 1: Dùng OSPP.VBS (Nếu tìm thấy)
    $ospp = Get-OSPP-Path
    if ($ospp) {
        $out = cscript //nologo "$ospp" /dinstid
        if ($out -match "Installation ID: (\d+)") { $finalIID = $matches[1] }
    }

    # Cách 2: Quét thẳng vào WMI (Bất chấp mất file ospp)
    if (-not $finalIID) {
        $OfficeAppID = "59a52881-a989-479d-af46-f275c6370663"
        $prod = Get-CimInstance -Query "SELECT InstallationID FROM SoftwareLicensingProduct WHERE ApplicationID = '$OfficeAppID' AND PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue
        if ($prod) { $finalIID = $prod.InstallationID }
    }

    if ($finalIID) {
        $txtIID.Text = $finalIID
        $txtStatus.Text = "✅ Đã tìm thấy mã IID!"
    } else {
        $txtIID.Text = "Không tìm thấy IID! Hãy nạp Key ở Bước 1 trước."
        $txtStatus.Text = "❌ Lỗi: Máy chưa nạp Key hoặc không có bản quyền."
    }
}

# 3. SỰ KIỆN NÚT BẤM
$btnCheck.Add_Click({
    $ospp = Get-OSPP-Path
    if ($ospp) {
        $out = cscript //nologo "$ospp" /dstatus
        [System.Windows.Forms.MessageBox]::Show($out, "Chi tiết Office")
    } else {
        # Nếu mất ospp, dùng PowerShell quét sơ bộ
        $OfficeAppID = "59a52881-a989-479d-af46-f275c6370663"
        $prod = Get-CimInstance -Query "SELECT Name, LicenseStatus FROM SoftwareLicensingProduct WHERE ApplicationID = '$OfficeAppID' AND PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue
        if ($prod) { [System.Windows.Forms.MessageBox]::Show("Tìm thấy qua WMI: $($prod.Name)", "Kết quả") }
        else { [System.Windows.Forms.MessageBox]::Show("Không tìm thấy Office chuẩn trên máy này!", "Cảnh báo") }
    }
})

$btnInstallKey.Add_Click({
    $ospp = Get-OSPP-Path
    $k = $txtKey.Text.Trim()
    if ($k.Length -lt 5) { [System.Windows.Forms.MessageBox]::Show("Nhập Key đi sếp!"); return }
    
    if ($ospp) {
        cscript //nologo "$ospp" /inpkey:$k | Out-Null
    } else {
        # Nạp Key qua slmgr nếu ospp mất (Nhiều bản Win cho phép làm vậy)
        cscript //nologo $env:windir\system32\slmgr.vbs /ipk $k | Out-Null
    }
    Start-Sleep -Seconds 2
    Get-IID-Smart
    [System.Windows.Forms.MessageBox]::Show("Đã nạp Key. Sếp kiểm tra IID nhé!")
})

$btnGetIID.Add_Click({ Get-IID-Smart })

$btnCopyIID.Add_Click({ if ($txtIID.Text) { [System.Windows.Forms.Clipboard]::SetText($txtIID.Text); [System.Windows.Forms.MessageBox]::Show("Đã copy IID!") } })

$btnActivate.Add_Click({
    $ospp = Get-OSPP-Path
    $cid = $txtCID.Text.Trim() -replace "\s",""
    if ($cid.Length -lt 10) { return }

    if ($ospp) {
        cscript //nologo "$ospp" /actcid:$cid | Out-Null
        cscript //nologo "$ospp" /act | Out-Null
    } else {
        cscript //nologo $env:windir\system32\slmgr.vbs /atp $cid | Out-Null
        cscript //nologo $env:windir\system32\slmgr.vbs /ato | Out-Null
    }
    [System.Windows.Forms.MessageBox]::Show("Đã gửi mã CID kích hoạt Office!")
})

$btnExit.Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Khởi động: Tự quét IID
Get-IID-Smart
$window.ShowDialog() | Out-Null