# ==========================================================
# VIETTOOLBOX - OFFLINE ACTIVATION V4.9 (DEEP CLEANER)
# Đặc trị: Lỗi không lấy được IID bằng cách dọn sạch License
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. GIAO DIỆN XAML (VERSION 4.9 - DARK MODE)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Deep Clean Activation V4.9" Height="650" Width="680" 
        Background="#121212" WindowStyle="None" AllowsTransparency="True" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" Background="#1E1E1E" BorderBrush="#007ACC" BorderThickness="2">
        <Grid>
            <TextBlock Text="KÍCH HOẠT WINDOWS - DEEP CLEAN (V4.9)" Foreground="#007ACC" FontSize="20" FontWeight="Bold" 
                       HorizontalAlignment="Center" Margin="0,20,0,0"/>
            
            <StackPanel Margin="35,60,35,20">
                <TextBlock Text="BƯỚC 1: Nhập Key Windows (Retail/MAK):" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <Grid Margin="0,0,0,20">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtKey" Height="35" Background="#252525" Foreground="White" BorderThickness="1" BorderBrush="#444" Padding="5" FontSize="15" VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
                    <Button Name="BtnCleanInstall" Grid.Column="1" Content="DỌN SẠCH &amp; NẠP" Margin="10,0,0,0" Background="#007ACC" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </Grid>

                <TextBlock Text="BƯỚC 2: Installation ID (IID) của máy:" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="TxtIID" Height="90" Background="#0F0F0F" Foreground="#00FF00" BorderThickness="1" BorderBrush="#333" TextWrapping="Wrap" IsReadOnly="True" Padding="10" FontSize="16" FontFamily="Consolas"/>
                
                <Grid Margin="0,10,0,20">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="BtnCopyIID" Content="SAO CHÉP IID" Height="35" Margin="0,0,5,0" Background="#444" Foreground="White" Cursor="Hand"/>
                    <Button Name="BtnOpenWeb" Grid.Column="1" Content="MỞ TRANG LẤY CID" Height="35" Margin="5,0,0,0" Background="#444" Foreground="White" Cursor="Hand"/>
                </Grid>

                <TextBlock Text="BƯỚC 3: Nhập mã Confirmation ID (CID):" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="TxtCID" Height="40" Background="#252525" Foreground="White" BorderThickness="1" BorderBrush="#007ACC" Padding="5" FontSize="18" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" FontFamily="Consolas"/>

                <Grid Margin="0,25,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="2*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="BtnActivate" Grid.Column="0" Content="KÍCH HOẠT NGAY" Height="45" Margin="0,0,10,0" Background="#28A745" Foreground="White" FontWeight="Bold" FontSize="16" Cursor="Hand"/>
                    <Button Name="BtnExit" Grid.Column="1" Content="THOÁT" Height="45" Background="#DC3545" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </Grid>
                <TextBlock Name="TxtStatus" Text="Trạng thái: Sẵn sàng dọn dẹp hệ thống." Foreground="#888" FontSize="12" Margin="0,15,0,0" HorizontalAlignment="Center"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# 2. Khởi tạo UI
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$txtKey = $window.FindName("TxtKey"); $txtIID = $window.FindName("TxtIID"); $txtCID = $window.FindName("TxtCID")
$btnCleanInstall = $window.FindName("BtnCleanInstall"); $btnCopyIID = $window.FindName("BtnCopyIID")
$btnOpenWeb = $window.FindName("BtnOpenWeb"); $btnActivate = $window.FindName("BtnActivate")
$btnExit = $window.FindName("BtnExit"); $txtStatus = $window.FindName("TxtStatus")

# --- HÀM LẤY IID BẰNG PHƯƠNG PHÁP CỦA SẾP TUẤN ---
function Get-IID-TuanStyle {
    $txtStatus.Text = "Đang trích xuất IID..."
    [System.Windows.Forms.Application]::DoEvents()
    
    $tempFile = "C:\IID_Temp.txt"
    # Ép lệnh dti ra file như cách của sếp
    Start-Process "cscript" -ArgumentList "//nologo $env:windir\system32\slmgr.vbs /dti" -RedirectStandardOutput $tempFile -Wait -WindowStyle Hidden
    
    if (Test-Path $tempFile) {
        $content = Get-Content $tempFile -Raw
        if ($content -match "(\d{10,})") {
            $txtIID.Text = $matches[1]
            $txtStatus.Text = "✅ Đã bốc IID thành công!"
        } else {
            $txtIID.Text = "Không tìm thấy IID trong kết quả trả về!"
            $txtStatus.Text = "❌ Lỗi trích xuất."
        }
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

# 3. Sự kiện
$btnCleanInstall.Add_Click({
    $k = $txtKey.Text.Trim()
    if ($k.Length -lt 5) { [System.Windows.Forms.MessageBox]::Show("Nhập Key cho đàng hoàng sếp ơi!"); return }
    
    $txtStatus.Text = "Đang dọn dẹp License & nạp Key..."
    [System.Windows.Forms.Application]::DoEvents()

    # --- QUY TRÌNH "THUỐC TẨY" CỦA SẾP TUẤN ---
    $vbs = "$env:windir\system32\slmgr.vbs"
    cscript //nologo $vbs /rilc | Out-Null
    cscript //nologo $vbs /upk | Out-Null
    cscript //nologo $vbs /ckms | Out-Null
    cscript //nologo $vbs /cpky | Out-Null
    
    # Ép chạy các dịch vụ linh hồn
    sc.exe config Winmgmt start= demand | Out-Null; net start Winmgmt | Out-Null
    sc.exe config LicenseManager start= auto | Out-Null; net start LicenseManager | Out-Null
    sc.exe config wuauserv start= auto | Out-Null; net start wuauserv | Out-Null

    # Nạp Key mới
    cscript //nologo $vbs /ipk $k | Out-Null
    
    Start-Sleep -Seconds 2
    Get-IID-TuanStyle
    [System.Windows.Forms.MessageBox]::Show("Đã dọn dẹp và nạp Key xong!")
})

$btnCopyIID.Add_Click({
    if ($txtIID.Text -match "\d") {
        [System.Windows.Forms.Clipboard]::SetText($txtIID.Text)
        [System.Windows.Forms.MessageBox]::Show("Đã copy IID!")
    }
})

$btnOpenWeb.Add_Click({ Start-Process "https://visualsupport.microsoft.com/" })

$btnActivate.Add_Click({
    $c = $txtCID.Text.Trim() -replace "\s", ""
    if ($c.Length -lt 10) { [System.Windows.Forms.MessageBox]::Show("CID này in thiếu à sếp?"); return }
    
    cscript //nologo $env:windir\system32\slmgr.vbs /atp $c | Out-Null
    cscript //nologo $env:windir\system32\slmgr.vbs /ato | Out-Null
    
    $txtStatus.Text = "Kích hoạt hoàn tất!"
    [System.Windows.Forms.MessageBox]::Show("Đã gửi mã CID. Sếp kiểm tra lại bản quyền nhé!")
})

$btnExit.Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Chạy lần đầu để xem có IID sẵn không
Get-IID-TuanStyle
$window.ShowDialog() | Out-Null