# ==========================================================
# VIETTOOLBOX - OFFLINE ACTIVATION PRO (FIXED IID)
# Đặc trị: Lỗi không lấy được Installation ID (IID)
# ==========================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Giao diện XAML (Đã làm sạch và tối ưu)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Offline Activation" Height="620" Width="680" 
        Background="#121212" WindowStyle="None" AllowsTransparency="True" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="15" Background="#1E1E1E" BorderBrush="#007ACC" BorderThickness="2">
        <Grid>
            <TextBlock Text="KÍCH HOẠT WINDOWS OFFLINE (BY PHONE)" Foreground="#007ACC" FontSize="20" FontWeight="Bold" 
                       HorizontalAlignment="Center" Margin="0,20,0,0"/>
            
            <StackPanel Margin="35,60,35,20">
                <TextBlock Text="BƯỚC 1: Nhập Key Windows (Retail/MAK):" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <Grid Margin="0,0,0,20">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="150"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="TxtKey" Height="35" Background="#252525" Foreground="White" BorderThickness="1" 
                             BorderBrush="#444" Padding="5" FontSize="15" VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
                    <Button Name="BtnInstallKey" Grid.Column="1" Content="NẠP KEY" Margin="10,0,0,0" Background="#007ACC" Foreground="White" FontWeight="Bold">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <TextBlock Text="BƯỚC 2: Installation ID (IID) của máy:" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="TxtIID" Height="90" Background="#0F0F0F" Foreground="#00FF00" BorderThickness="1" 
                         BorderBrush="#333" TextWrapping="Wrap" IsReadOnly="True" Padding="10" FontSize="16" FontFamily="Consolas"/>
                
                <Grid Margin="0,10,0,20">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button Name="BtnCopyIID" Content="SAO CHÉP IID" Height="35" Margin="0,0,5,0" Background="#444" Foreground="White">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                    <Button Name="BtnRefresh" Grid.Column="1" Content="LÀM MỚI IID" Height="35" Margin="5,0,0,0" Background="#444" Foreground="White">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <TextBlock Text="BƯỚC 3: Nhập mã Confirmation ID (CID) để kết thúc:" Foreground="#FFCC00" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="TxtCID" Height="40" Background="#252525" Foreground="White" BorderThickness="1" 
                         BorderBrush="#007ACC" Padding="5" FontSize="18" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" FontFamily="Consolas"/>

                <Grid Margin="0,25,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="2*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button Name="BtnActivate" Grid.Column="0" Content="KÍCH HOẠT NGAY" Height="45" Margin="0,0,10,0" Background="#28A745" Foreground="White" FontWeight="Bold" FontSize="16">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                    <Button Name="BtnExit" Grid.Column="1" Content="THOÁT" Height="45" Background="#DC3545" Foreground="White" FontWeight="Bold">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                </Grid>
                <TextBlock Text="Ghi chú: Copy IID rồi dán vào trang lấy CID (visualsupport.microsoft.com)" Foreground="#888" FontSize="11" Margin="0,15,0,0" HorizontalAlignment="Center"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# 2. Khởi tạo UI
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$txtKey = $window.FindName("TxtKey"); $txtIID = $window.FindName("TxtIID"); $txtCID = $window.FindName("TxtCID")
$btnInstallKey = $window.FindName("BtnInstallKey"); $btnCopyIID = $window.FindName("BtnCopyIID")
$btnRefresh = $window.FindName("BtnRefresh"); $btnActivate = $window.FindName("BtnActivate")
$btnExit = $window.FindName("BtnExit")

# --- HÀM LẤY IID MỚI (CHỐT HẠ) ---
function Refresh-IID {
    try {
        # Cách 1: Dùng Service Class (Cực nhanh và chuẩn)
        $iid = (Get-CimInstance SoftwareLicensingService -ErrorAction Stop).OfflineInstallationId
        if ($null -eq $iid -or $iid -eq "") {
            # Cách 2: Fallback nếu cách 1 rỗng
            $obj = Get-CimInstance -Query 'SELECT InstallationID FROM SoftwareLicensingProduct WHERE ApplicationID = "55c92734-d682-4d71-983e-d6ec3f16059f" AND PartialProductKey IS NOT NULL' -ErrorAction SilentlyContinue
            $iid = $obj.InstallationID
        }
        
        if ($iid) { 
            $txtIID.Text = $iid 
        } else { 
            $txtIID.Text = "Chưa có IID. Hãy nạp Key ở Bước 1 trước!" 
        }
    } catch {
        $txtIID.Text = "Lỗi hệ thống khi truy xuất IID!"
    }
}

# 3. Sự kiện
$btnInstallKey.Add_Click({
    $k = $txtKey.Text.Trim()
    if ($k.Length -lt 5) { [System.Windows.Forms.MessageBox]::Show("Nhập Key cho chuẩn sếp ơi!"); return }
    
    # Nạp Key bằng slmgr
    Start-Process -FilePath "cscript" -ArgumentList "//nologo $env:windir\system32\slmgr.vbs /ipk $k" -Wait -WindowStyle Hidden
    
    # Nghỉ 1 giây cho Windows kịp nhận diện rồi mới load IID
    Start-Sleep -Seconds 1
    Refresh-IID
    [System.Windows.Forms.MessageBox]::Show("Đã nạp Key xong! Sếp kiểm tra mã IID ở Bước 2 nhé.")
})

$btnCopyIID.Add_Click({
    if ($txtIID.Text -match "[0-9]") {
        [System.Windows.Forms.Clipboard]::SetText($txtIID.Text)
        [System.Windows.Forms.MessageBox]::Show("Đã copy mã IID!")
    }
})

$btnRefresh.Add_Click({ Refresh-IID })

$btnActivate.Add_Click({
    $c = $txtCID.Text.Trim() -replace "\s", "" # Xóa khoảng trắng nếu sếp lỡ tay copy nhầm
    if ($c.Length -lt 40) { [System.Windows.Forms.MessageBox]::Show("Mã CID thường dài 48 số, sếp kiểm tra lại nhé!"); return }
    
    Start-Process -FilePath "cscript" -ArgumentList "//nologo $env:windir\system32\slmgr.vbs /atp $c" -Wait -WindowStyle Hidden
    Start-Process -FilePath "cscript" -ArgumentList "//nologo $env:windir\system32\slmgr.vbs /ato" -Wait -WindowStyle Hidden
    
    [System.Windows.MessageBox]::Show("Đã gửi lệnh kích hoạt. Sếp kiểm tra lại System Properties nhé!")
})

$btnExit.Add_Click({ $window.Close() })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Chạy lần đầu
Refresh-IID
$window.ShowDialog() | Out-Null