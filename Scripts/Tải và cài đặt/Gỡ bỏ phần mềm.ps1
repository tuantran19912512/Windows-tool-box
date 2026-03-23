# ==========================================================
# TOOL GỠ PHẦN MỀM TẬN GỐC - GIAO DIỆN WPF (SẠCH BÓNG WINFORMS 100%)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# 1. ÉP CHẠY QUYỀN QUẢN TRỊ VIÊN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. KHỞI TẠO MÔI TRƯỜNG WPF & ĐỒ HỌA (CHỈ GỌI CÁC THƯ VIỆN LÕI)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 3. GIAO DIỆN XAML
$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - GỠ PHẦN MỀM TẬN GỐC (BẢN CHUẨN CONTROL PANEL)" Width="880" Height="650"
        WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.9"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="CÔNG CỤ GỠ PHẦN MỀM TẬN GỐC (REVO STYLE)" FontSize="24" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Quét ứng dụng, gỡ cài đặt và dọn dẹp sạch sẽ tàn dư trong Registry &amp; Thư mục" Foreground="#666666"/>
        </StackPanel>

        <ListView Name="BangPhanMem" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" BorderThickness="1" Margin="0,0,0,15">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="TÊN PHẦN MỀM" Width="380">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <StackPanel Orientation="Horizontal" Margin="0,3">
                                    <Image Source="{Binding AppIcon}" Width="20" Height="20" Margin="0,0,10,0" RenderOptions.BitmapScalingMode="HighQuality"/>
                                    <TextBlock Text="{Binding Name}" VerticalAlignment="Center" FontWeight="Medium" Foreground="#333333"/>
                                </StackPanel>
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="PHIÊN BẢN" DisplayMemberBinding="{Binding Version}" Width="100"/>
                    <GridViewColumn Header="NHÀ PHÁT HÀNH" DisplayMemberBinding="{Binding Publisher}" Width="150"/>
                    <GridViewColumn Header="DUNG LƯỢNG" DisplayMemberBinding="{Binding Size}" Width="90"/>
                    <GridViewColumn Header="LOẠI" DisplayMemberBinding="{Binding AppType}" Width="80"/>
                </GridView>
            </ListView.View>
        </ListView>

        <TextBlock Name="NhanTrangThai" Grid.Row="2" Text="Đang chờ..." FontWeight="SemiBold" Foreground="#1565C0" Margin="0,0,0,15"/>

        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button Name="NutLamMoi" Grid.Column="0" Content="🔄 LÀM MỚI DANH SÁCH" Width="200" Height="45" Background="#ECEFF1" Foreground="Black" FontWeight="Bold"/>
            <Button Name="NutGoBo" Grid.Column="2" Content="🗑️ GỠ BỎ TẬN GỐC" Width="250" Height="45" Background="#C62828" Foreground="White" FontSize="14" FontWeight="Bold"/>
        </Grid>
    </Grid>
</Window>
"@

$DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
$DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

$BangPhanMem = $CuaSo.FindName("BangPhanMem")
$NhanTrangThai = $CuaSo.FindName("NhanTrangThai")
$NutLamMoi = $CuaSo.FindName("NutLamMoi")
$NutGoBo = $CuaSo.FindName("NutGoBo")

$Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$BangPhanMem.ItemsSource = $Global:DanhSachDuLieu

# --- HÀM DOEVENTS CHUẨN WPF CHỐNG ĐƠ GIAO DIỆN ---
$CapNhatGiaoDien = {
    $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

# --- HÀM CHUYỂN ĐỔI ICON SANG WPF ---
function Lay-BieuTuongWPF ($DuongDan) {
    try {
        if ([string]::IsNullOrWhiteSpace($DuongDan)) { return $null }
        if (-not (Test-Path -LiteralPath $DuongDan -ErrorAction SilentlyContinue)) { return $null }
        
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($DuongDan)
        if ($null -eq $icon) { return $null }
        
        $bmpSrc = [System.Windows.Interop.Imaging]::CreateBitmapSourceFromHIcon(
            $icon.Handle,
            [System.Windows.Int32Rect]::Empty,
            [System.Windows.Media.Imaging.BitmapSizeOptions]::FromEmptyOptions()
        )
        $bmpSrc.Freeze()
        $icon.Dispose()
        return $bmpSrc
    } catch {
        return $null
    }
}

$Global:IconMacDinh = Lay-BieuTuongWPF "$env:windir\explorer.exe"

# 4. HÀM QUÉT PHẦN MỀM (VÉT CẠN HỆ THỐNG)
function Tai-DanhSachPhanMem {
    $Global:DanhSachDuLieu.Clear()
    $NhanTrangThai.Text = "Đang vét cạn toàn bộ dữ liệu Registry của tất cả User..."
    $NhanTrangThai.Foreground = "#FF9800"
    &$CapNhatGiaoDien

    $DanhSachTam = @()
    $DaThem = @{}

    $Paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
    $UserKeys = Get-ChildItem -Path "HKU:\" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "S-1-5-21-\d+-\d+-\d+-\d+$" -and $_.Name -notmatch "_Classes" }
    
    foreach ($U in $UserKeys) {
        $SID = $U.PSChildName
        $Paths += "HKU:\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $Paths += "HKU:\$SID\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }

    $Paths += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $Paths += "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    $Paths = $Paths | Select-Object -Unique

    foreach ($Path in $Paths) {
        $Apps = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue

        foreach ($App in $Apps) {
            $Name = $App.DisplayName
            if ([string]::IsNullOrWhiteSpace($Name)) { continue }

            if ($Name -match "(?i)^KB\d{5,}") { continue }
            if ($Name -match "(?i)^Security Update for") { continue }
            if ($Name -match "(?i)^Update for Windows") { continue }
            if ($App.SystemComponent -eq 1) { continue }
            if (-not [string]::IsNullOrWhiteSpace($App.ParentKeyName)) { continue }

            $Uninst = $App.UninstallString
            if ([string]::IsNullOrWhiteSpace($Uninst)) { $Uninst = $App.QuietUninstallString }
            if ([string]::IsNullOrWhiteSpace($Uninst) -and $App.WindowsInstaller -eq 1) {
                $Uninst = "msiexec.exe /x `"$($App.PSChildName)`""
            }

            if ([string]::IsNullOrWhiteSpace($Uninst)) { continue }

            $UniqueKey = "$Name|$Uninst"
            if ($DaThem.ContainsKey($UniqueKey)) { continue }
            $DaThem[$UniqueKey] = $true

            $Ver = if ($App.DisplayVersion) { [string]$App.DisplayVersion } else { "N/A" }
            $Pub = if ($App.Publisher) { [string]$App.Publisher } else { "N/A" }

            $SizeStr = "N/A"
            if ($App.EstimatedSize -match '^\d+$') {
                $SizeMB = [math]::Round($App.EstimatedSize / 1024, 2)
                $SizeStr = if ($SizeMB -ge 1024) { "$([math]::Round($SizeMB / 1024, 2)) GB" } else { "$SizeMB MB" }
            }

            $TargetPath = ""
            if ($App.DisplayIcon) {
                $TargetPath = $App.DisplayIcon.ToString().Trim() -replace '"', '' -replace ',\s*-?\d+$', ''
                $TargetPath = [System.Environment]::ExpandEnvironmentVariables($TargetPath)
            }

            $KiemTraTonTai = $false
            if (-not [string]::IsNullOrWhiteSpace($TargetPath)) {
                $KiemTraTonTai = Test-Path -LiteralPath $TargetPath -ErrorAction SilentlyContinue
            }

            if (-not $KiemTraTonTai -and -not [string]::IsNullOrWhiteSpace($Uninst)) {
                if (($Uninst.ToString().Trim() -replace '"', '') -match '^(.*?\.exe)') { 
                    $TargetPath = [System.Environment]::ExpandEnvironmentVariables($matches[1]) 
                    if (-not [string]::IsNullOrWhiteSpace($TargetPath)) {
                        $KiemTraTonTai = Test-Path -LiteralPath $TargetPath -ErrorAction SilentlyContinue
                    }
                }
            }

            $FinalIcon = $Global:IconMacDinh
            if ($KiemTraTonTai) {
                $ExtractedIcon = Lay-BieuTuongWPF $TargetPath
                if ($null -ne $ExtractedIcon) { $FinalIcon = $ExtractedIcon }
            }

            $DanhSachTam += [PSCustomObject]@{
                AppIcon = $FinalIcon
                Name = $Name
                RawName = $Name
                Version = $Ver
                Publisher = $Pub
                Size = $SizeStr
                AppType = "Desktop"
                UninstallString = $Uninst
                IsUWP = $false
            }
        }
    }

    $NhanTrangThai.Text = "Đang đồng bộ các ứng dụng từ Microsoft Store..."
    &$CapNhatGiaoDien
    
    $uwpApps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.IsFramework -eq $false -and $_.NonRemovable -eq $false }
    foreach ($app in $uwpApps) {
        try {
            if ($DaThem.ContainsKey("$($app.Name)|$($app.PackageFullName)")) { continue }

            $DanhSachTam += [PSCustomObject]@{
                AppIcon = $Global:IconMacDinh
                Name = $app.Name
                RawName = $app.Name
                Version = $app.Version
                Publisher = if ($app.Publisher) { ($app.Publisher -split ',')[0] -replace 'CN=', '' } else { "Microsoft" }
                Size = "N/A"
                AppType = "Store App"
                UninstallString = $app.PackageFullName
                IsUWP = $true
            }
        } catch {}
    }

    $DanhSachTam = $DanhSachTam | Sort-Object RawName
    foreach ($item in $DanhSachTam) { $Global:DanhSachDuLieu.Add($item) }

    $NhanTrangThai.Text = "✅ Đã tải xong $($Global:DanhSachDuLieu.Count) phần mềm."
    $NhanTrangThai.Foreground = "#2E7D32"
}

# 5. NÚT LÀM MỚI
$NutLamMoi.Add_Click({ Tai-DanhSachPhanMem })

# 6. GỠ CÀI ĐẶT
$NutGoBo.Add_Click({
    $app = $BangPhanMem.SelectedItem
    if ($null -eq $app) { 
        [System.Windows.MessageBox]::Show("Tuấn vui lòng chọn 1 phần mềm trong danh sách để gỡ!", "Nhắc nhở", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return 
    }
    
    $appName = $app.RawName
    $HoiDap = [System.Windows.MessageBox]::Show("Khởi động trình gỡ cài đặt cho '$appName'?", "Xác nhận gỡ", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($HoiDap -eq "No") { return }

    $NhanTrangThai.Text = "Đang chờ trình gỡ cài đặt hoàn tất..."
    $NhanTrangThai.Foreground = "#FF9800"
    &$CapNhatGiaoDien
    
    if ($app.IsUWP) {
        try { Remove-AppxPackage -Package $app.UninstallString -AllUsers -ErrorAction Stop } catch {}
    } else {
        if (-not [string]::IsNullOrWhiteSpace($app.UninstallString)) {
            $uninst = $app.UninstallString -replace "msiexec.exe /I", "msiexec.exe /X"
            try { Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninst`"" -Wait -WindowStyle Hidden } catch {}
        }
    }

    $msg = "Trình gỡ cài đặt gốc đã chạy xong.`n`nBạn có muốn QUÉT VÀ XOÁ SẠCH RÁC (thư mục, registry) của '$appName' không?`n`n👉 Chọn 'Yes' nếu phần mềm đã gỡ xong.`n👉 Chọn 'No' nếu bạn vừa huỷ việc gỡ cài đặt."
    $cleanup = [System.Windows.MessageBox]::Show($msg, "Dọn dẹp tàn dư (Revo Cleaner)", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)

    if ($cleanup -eq "Yes") {
        $NhanTrangThai.Text = "Đang quét và tiêu diệt tàn dư..."
        &$CapNhatGiaoDien
        
        $trashPaths = @("$env:ProgramFiles\$appName", "${env:ProgramFiles(x86)}\$appName", "$env:AppData\$appName", "$env:LocalAppData\$appName")
        foreach ($p in $trashPaths) { if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } }

        $regPaths = @("HKLM:\SOFTWARE", "HKCU:\Software", "HKLM:\SOFTWARE\WOW6432Node")
        foreach ($reg in $regPaths) {
            $subKey = Get-ChildItem -Path $reg -ErrorAction SilentlyContinue | Where-Object { $_.Name -match [regex]::Escape($appName) }
            if ($subKey) { $subKey | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
        }
        [System.Windows.MessageBox]::Show("Đã xoá sạch phần mềm và rác của '$appName'!", "Hoàn tất", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } else {
        [System.Windows.MessageBox]::Show("Đã bỏ qua bước dọn rác do người dùng chọn huỷ.", "Thông báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }

    Tai-DanhSachPhanMem
})

# 7. CHẠY GIAO DIỆN
$CuaSo.Add_ContentRendered({ Tai-DanhSachPhanMem })
$CuaSo.ShowDialog() | Out-Null