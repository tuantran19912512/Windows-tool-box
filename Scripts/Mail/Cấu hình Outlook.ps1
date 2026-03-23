# ==========================================================
# VIETTOOLBOX - OUTLOOK QUICK CONFIG V1.3 (PURE WPF EDITION)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# ÉP POWERSHELL HIỂU TIẾNG VIỆT 100% VÀ NẠP THƯ VIỆN WPF
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$CongCuOutlookV1_3 = {
    # --- GIAO DIỆN XAML PURE WPF (DARK MODE) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - OUTLOOK QUICK CONFIG V1.3" Width="500" Height="550"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" FontFamily="Segoe UI" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Height" Value="48"/>
            <Setter Property="Margin" Value="0,8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.85"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Opacity" Value="0.6"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="30,20,30,20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="HỖ TRỢ CẤU HÌNH OUTLOOK NHANH" FontSize="18" FontWeight="Bold" Foreground="#00D4FF" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <StackPanel Grid.Row="1" VerticalAlignment="Center">
            <Button Name="NutMoCauHinh" Content="1. MỞ CẤU HÌNH ACCOUNT (THỬ LẠI)" Background="#2980B9"/>
            <Button Name="NutSuaLoi" Content="2. FIX LỖI AUTODISCOVER (TREO / HỎI PASS)" Background="#D35400"/>
            <Button Name="NutDonRac" Content="3. DỌN SẠCH CACHE &amp; TEMP" Background="#27AE60"/>
            <Button Name="NutXoaProfile" Content="4. RESET PROFILE (LÀM LẠI TỪ ĐẦU)" Background="#C0392B"/>
            <Button Name="NutKhoiPhuc" Content="5. KHÔI PHỤC AUTODISCOVER (VỀ MẶC ĐỊNH)" Background="#8E44AD"/>
        </StackPanel>

        <Button Name="NutThoat" Grid.Row="2" Content="THOÁT CÔNG CỤ" Background="#333333" Width="150" Height="40" Margin="0,15,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@

    # --- KHỞI TẠO CỬA SỔ & ÁNH XẠ BIẾN ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    $NutMoCauHinh = $CuaSo.FindName("NutMoCauHinh")
    $NutSuaLoi = $CuaSo.FindName("NutSuaLoi")
    $NutDonRac = $CuaSo.FindName("NutDonRac")
    $NutXoaProfile = $CuaSo.FindName("NutXoaProfile")
    $NutKhoiPhuc = $CuaSo.FindName("NutKhoiPhuc")
    $NutThoat = $CuaSo.FindName("NutThoat")

    # --- NÚT 1: MỞ CẤU HÌNH (THUẬT TOÁN DÒ TÌM) ---
    $NutMoCauHinh.Add_Click({
        $TienTrinh = Start-Process "control.exe" -ArgumentList "mlcfg32.cpl" -PassThru -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        
        if ($TienTrinh.HasExited -or !$TienTrinh) {
            $DanhSachDuongDan = @(
                "C:\Program Files\Microsoft Office\root\Office16\MLCFG32.CPL",
                "C:\Program Files (x86)\Microsoft Office\root\Office16\MLCFG32.CPL",
                "C:\Program Files\Microsoft Office\Office16\MLCFG32.CPL",
                "C:\Program Files (x86)\Microsoft Office\Office16\MLCFG32.CPL"
            )
            $DaTimThay = $false
            foreach ($DuongDan in $DanhSachDuongDan) {
                if (Test-Path $DuongDan) {
                    Start-Process "control.exe" -ArgumentList "`"$DuongDan`""
                    $DaTimThay = $true; break
                }
            }
            
            if (-not $DaTimThay) {
                Start-Process "outlook.exe" -ArgumentList "/profiles" -ErrorAction SilentlyContinue
            }
        }
    })

    # --- NÚT 2: SỬA LỖI AUTODISCOVER ---
    $NutSuaLoi.Add_Click({
        $DuongDanReg = "HKCU:\Software\Microsoft\Office\16.0\Outlook\AutoDiscover"
        if (!(Test-Path $DuongDanReg)) { New-Item -Path $DuongDanReg -Force | Out-Null }
        Set-ItemProperty -Path $DuongDanReg -Name "ExcludeHttpsRootDomain" -Value 1
        Set-ItemProperty -Path $DuongDanReg -Name "ExcludeHttpsLookupDomain" -Value 1
        Set-ItemProperty -Path $DuongDanReg -Name "ExcludeSrvRecord" -Value 1
        [System.Windows.MessageBox]::Show("Đã nạp Registry Fix AutoDiscover thành công!`nOutlook sẽ ưu tiên lấy cấu hình từ Office 365 nhanh hơn.", "Hoàn tất", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })

    # --- NÚT 3: DỌN RÁC ---
    $NutDonRac.Add_Click({
        $DuongDanRac = "$env:LOCALAPPDATA\Microsoft\Outlook"
        if (Test-Path $DuongDanRac) {
            Get-ChildItem -Path $DuongDanRac -Include *.dat, *.tmp -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
            [System.Windows.MessageBox]::Show("Đã dọn sạch bộ nhớ đệm (Cache) của Outlook!", "Hoàn tất", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            [System.Windows.MessageBox]::Show("Không tìm thấy thư mục Cache của Outlook trên máy này.", "Thông báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })

    # --- NÚT 4: XÓA PROFILE ---
    $NutXoaProfile.Add_Click({
        $LoiNhan = "Việc này sẽ xóa hết Profile hiện tại, ông có chắc chắn muốn làm lại từ đầu không?"
        $HoiDap = [System.Windows.MessageBox]::Show($LoiNhan, "Cảnh báo nguy hiểm", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        
        if ($HoiDap -eq "Yes") {
            Remove-Item -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\*" -Recurse -Force -ErrorAction SilentlyContinue
            [System.Windows.MessageBox]::Show("Đã thiết lập lại (Reset)! Hãy mở Outlook để tạo Profile mới.", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })

    # --- NÚT 5: KHÔI PHỤC AUTODISCOVER (MỚI THÊM) ---
    $NutKhoiPhuc.Add_Click({
        $DuongDanReg = "HKCU:\Software\Microsoft\Office\16.0\Outlook\AutoDiscover"
        if (Test-Path $DuongDanReg) {
            # Xóa các key đã tạo ở bước Fix
            Remove-ItemProperty -Path $DuongDanReg -Name "ExcludeHttpsRootDomain" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $DuongDanReg -Name "ExcludeHttpsLookupDomain" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $DuongDanReg -Name "ExcludeSrvRecord" -ErrorAction SilentlyContinue
            [System.Windows.MessageBox]::Show("Đã xóa các bản ghi Fix.`nCơ chế AutoDiscover đã trở về trạng thái mặc định của Microsoft!", "Khôi phục thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            [System.Windows.MessageBox]::Show("Máy này chưa từng chạy Fix AutoDiscover nên không cần khôi phục.", "Thông báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })

    # Nút thoát
    $NutThoat.Add_Click({ $CuaSo.Close() })

    # Khởi chạy cửa sổ
    $CuaSo.ShowDialog() | Out-Null
}

&$CongCuOutlookV1_3