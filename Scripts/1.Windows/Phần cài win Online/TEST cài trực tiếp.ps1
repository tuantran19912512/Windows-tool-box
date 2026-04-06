Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 1. CẤU HÌNH XOAY VÒNG API & GITHUB ---
$DanhSachKeyMaHoa = @(
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR",
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v",
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv",
    "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR",
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
)
# Giải mã toàn bộ danh sách Key
$script:DanhSachAPI = $DanhSachKeyMaHoa | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
$LinkCSV = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"

try {
    $PhanHoi = Invoke-WebRequest -Uri $LinkCSV -UseBasicParsing -ErrorAction Stop
    $NoiDung = if ($PhanHoi.Content -is [string]) { $PhanHoi.Content } else { [System.Text.Encoding]::UTF8.GetString($PhanHoi.Content) }
    $DanhSachWin = $NoiDung | ConvertFrom-Csv | Where-Object { $_.Name -match "\.wim" }
    if (!$DanhSachWin) { throw "Không có file .wim" }
} catch { [System.Windows.MessageBox]::Show("Lỗi tải danh sách bộ cài từ hệ thống!"); exit }

# --- 2. GIAO DIỆN XAML ---
$GiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cong Cu Trien Khai Windows" SizeToContent="Height" Width="430" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#1E1E1E"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="0,4"/>
            <Setter Property="MinHeight" Value="45"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" BorderBrush="#333333" BorderThickness="1" Padding="10,5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#252525"/>
                    <Setter Property="BorderBrush" Value="#00FF7F"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    <Border CornerRadius="15" Background="#121212" BorderBrush="#00FF7F" BorderThickness="1.5">
        <Grid Margin="20,20,20,25">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <TextBlock Grid.Row="0" Text="CÔNG CỤ TRIỂN KHAI WINDOWS" Foreground="#00FF7F" FontSize="18" FontWeight="Black" HorizontalAlignment="Center" Margin="0,0,0,15"/>
            
            <ScrollViewer Grid.Row="1" MaxHeight="250" VerticalScrollBarVisibility="Auto" Margin="0,5">
                <StackPanel Name="KhungChuaNut"/>
            </ScrollViewer>

            <StackPanel Grid.Row="2" Margin="0,15,0,10" Background="#1A1A1A" Name="KhungTienTrinh" Visibility="Collapsed">
                <TextBlock Name="buoc1" Text="○ 1. Chuẩn bị phân vùng lưu trữ" Foreground="#888888" Margin="10,4" FontSize="11"/>
                <TextBlock Name="buoc2" Text="○ 2. Tải dữ liệu (Tự động xoay API)" Foreground="#888888" Margin="10,4" FontSize="11"/>
                <TextBlock Name="buoc3" Text="○ 3. Cấu hình phân vùng khởi động" Foreground="#888888" Margin="10,4" FontSize="11"/>
                <TextBlock Name="buoc4" Text="○ 4. Nạp kịch bản tự động hóa" Foreground="#888888" Margin="10,4" FontSize="11"/>
            </StackPanel>

            <StackPanel Grid.Row="3" Margin="0,5,0,0">
                <Grid Margin="0,0,0,8">
                    <TextBlock Name="TrangThai" Text="Vui lòng chọn phiên bản để cài đặt..." Foreground="#00FF7F" FontSize="11"/>
                    <TextBlock Name="PhanTram" Text="0%" Foreground="#00FF7F" FontSize="11" HorizontalAlignment="Right"/>
                </Grid>
                <ProgressBar Name="ThanhTienDo" Height="8" Minimum="0" Maximum="100" Value="0" Foreground="#00FF7F" Background="#222222" BorderThickness="0"/>
                <Button Name="NutThoat" Content="THOÁT CHƯƠNG TRÌNH" Margin="0,15,0,0" MinHeight="35" Width="150" BorderBrush="#FF4D4D" Foreground="#FF4D4D" Padding="0,5"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$TrinhDoc = [System.Xml.XmlReader]::Create([System.IO.StringReader] $GiaoDien)
$CuaSo = [System.Windows.Markup.XamlReader]::Load($TrinhDoc)
$KhungChuaNut = $CuaSo.FindName("KhungChuaNut")
$TrangThai = $CuaSo.FindName("TrangThai")
$PhanTram = $CuaSo.FindName("PhanTram")
$ThanhTienDo = $CuaSo.FindName("ThanhTienDo")
$KhungTienTrinh = $CuaSo.FindName("KhungTienTrinh")

function CapNhat-Buoc ($So, $TinhTrang) {
    $Chu = $CuaSo.FindName("buoc$So")
    if ($TinhTrang -eq "DangChay") { $Chu.Foreground = "#00FF7F"; $Chu.Text = $Chu.Text.Replace("○", "▶").Replace("❌", "▶") }
    if ($TinhTrang -eq "HoanTat") { $Chu.Foreground = "#AAAAAA"; $Chu.Text = $Chu.Text.Replace("▶", "✅") }
    if ($TinhTrang -eq "Loi") { $Chu.Foreground = "#FF4D4D"; $Chu.Text = $Chu.Text.Replace("▶", "❌") }
}

# --- 3. LOGIC XỬ LÝ TRIỂN KHAI ---
function BatDau-TrienKhai ($Win) {
    $KhungTienTrinh.Visibility = "Visible"
    $KhungChuaNut.Children | ForEach-Object { $_.IsEnabled = $false }
    $ThanhTienDo.Value = 0; $PhanTram.Text = "0%"
    
    $PhanVungC = Get-Partition -DriveLetter C
    $script:SoODia = $PhanVungC.DiskNumber
    $script:SoPhanVung = $PhanVungC.PartitionNumber

    # --- BƯỚC 1: TÌM CHỖ CHỨA ---
    CapNhat-Buoc 1 "DangChay"
    $TrangThai.Text = "Đang kiểm tra không gian lưu trữ an toàn..."
    
    $ODiaTrong = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" -and $_.Name -ne "X" -and $_.Free -gt 6GB } | Select-Object -First 1
    
    if (!$ODiaTrong) {
        $TrangThai.Text = "Hệ thống đang trích xuất 6GB từ phân vùng chính..."
        "select disk $($script:SoODia)`nselect partition $($script:SoPhanVung)`nshrink minimum=6144`ncreate partition primary`nformat quick fs=ntfs label='WinSetup'`nassign letter=T" | diskpart
        Start-Sleep -Seconds 3 
        $script:KyTuODiaDuLieu = "T"
    } else {
        $script:KyTuODiaDuLieu = $ODiaTrong.Name
    }
    CapNhat-Buoc 1 "HoanTat"

    # --- BƯỚC 2: TẢI WIM VỚI CƠ CHẾ XOAY VÒNG API ---
    CapNhat-Buoc 2 "DangChay"
    $script:DuongDanWim = "$($script:KyTuODiaDuLieu):\install.wim"
    
    $script:TienTrinhTai = Start-Job -ScriptBlock { 
        param($MaTapTin, $DanhSachKhoa, $DuongDanLuu) 
        foreach ($Khoa in $DanhSachKhoa) {
            $LienKet = "https://www.googleapis.com/drive/v3/files/$MaTapTin?alt=media&key=$Khoa"
            curl.exe -L -o $DuongDanLuu $LienKet
            if ((Test-Path $DuongDanLuu) -and (Get-Item $DuongDanLuu).Length -gt 100MB) {
                return "THANH_CONG"
            }
        }
        return "THAT_BAI"
    } -ArgumentList $Win.FileID, $script:DanhSachAPI, $script:DuongDanWim
    
    $CuaSo.Tag = @{ WimPath = $script:DuongDanWim; DriveLetter = $script:KyTuODiaDuLieu; DiskNum = $script:SoODia; PartNum = $script:SoPhanVung; JobId = $script:TienTrinhTai.Id }

    $BoDem = New-Object System.Windows.Threading.DispatcherTimer
    $BoDem.Interval = [TimeSpan]::FromSeconds(1)
    
    $BoDem.Add_Tick({
        $TrangThaiHeThong = $CuaSo.Tag
        
        if (Test-Path $TrangThaiHeThong.WimPath) {
            $KichThuoc = (Get-Item $TrangThaiHeThong.WimPath).Length / 1MB
            $TienDo = [math]::Min(99, [math]::Round(($KichThuoc / 4500) * 100))
            $ThanhTienDo.Value = $TienDo; $PhanTram.Text = "$TienDo %"; $TrangThai.Text = "Đang nạp dữ liệu: $([math]::Round($KichThuoc)) MB"
        }
        
        $TienTrinhHienTai = Get-Job -Id $TrangThaiHeThong.JobId
        if ($TienTrinhHienTai.State -eq "Completed") {
            $BoDem.Stop()
            
            if (!(Test-Path $TrangThaiHeThong.WimPath) -or (Get-Item $TrangThaiHeThong.WimPath).Length -lt 100MB) {
                $TrangThai.Text = "LỖI: Toàn bộ API đã quá tải. Vui lòng thử lại sau!"
                CapNhat-Buoc 2 "Loi"
                $KhungChuaNut.Children | ForEach-Object { $_.IsEnabled = $true }
                return 
            }

            CapNhat-Buoc 2 "HoanTat"
            
            # --- BƯỚC 3: PHẪU THUẬT HỆ THỐNG ---
            CapNhat-Buoc 3 "DangChay"
            $TrangThai.Text = "Dữ liệu toàn vẹn. Đang cấu hình Boot & Recovery..."
            "select disk $($TrangThaiHeThong.DiskNum)`nselect partition $($TrangThaiHeThong.PartNum)`nshrink minimum=1124`ncreate partition efi size=100`nformat quick fs=fat32 label='System'`nassign letter=S`ncreate partition primary`nformat quick fs=ntfs label='Recovery'`nset id='de94bba4-06d1-4d40-a16a-bfd50179d6ac'" | diskpart
            CapNhat-Buoc 3 "HoanTat"

            # --- BƯỚC 4: SINH KỊCH BẢN TỰ ĐỘNG HÓA ---
            CapNhat-Buoc 4 "DangChay"
            $TrangThai.Text = "Đang thiết lập kịch bản tự động hóa (Bypass, Anydesk, Bitlocker)..."
            
            $KichBanBat = @"
@echo off
(echo select disk $($TrangThaiHeThong.DiskNum) & echo select partition $($TrangThaiHeThong.PartNum) & echo format quick fs=ntfs label='Windows' & echo assign letter=W & echo exit) | diskpart

for %%I in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%I:\install.wim" set SETUP_DRIVE=%%I:
)

dism /Apply-Image /ImageFile:%SETUP_DRIVE%\install.wim /Index:1 /ApplyDir:W:\

:: Bo qua kiem tra Internet
reg load HKLM\zSOFTWARE W:\Windows\System32\config\SOFTWARE
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f
reg unload HKLM\zSOFTWARE

:: Tao tap lenh chay ngam sau khi cai dat de xy ly BitLocker & Anydesk
md W:\Windows\Setup\Scripts
(
echo @echo off
echo manage-bde -off C:
echo reg add "HKLM\System\CurrentControlSet\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d "1" /f
echo net accounts /maxpwage:unlimited
echo curl.exe -L -o C:\AnyDesk.exe https://download.anydesk.com/AnyDesk.exe
echo C:\AnyDesk.exe --install "C:\Program Files\AnyDesk" --start-with-win --create-shortcuts --create-desktop-icon --silent
echo del "%%~f0"
) > W:\Windows\Setup\Scripts\SetupComplete.cmd

:: Cau hinh loai bo cac cau hoi rieng tu
(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo   ^<settings pass="oobeSystem"^>
echo     ^<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"^>
echo       ^<OOBE^>
echo         ^<HideEULAPage^>true^</HideEULAPage^>
echo         ^<HideOEMRegistrationScreen^>true^</HideOEMRegistrationScreen^>
echo         ^<HideOnlineAccountScreens^>true^</HideOnlineAccountScreens^>
echo         ^<HideWirelessSetupInOOBE^>true^</HideWirelessSetupInOOBE^>
echo         ^<ProtectYourPC^>3^</ProtectYourPC^>
echo       ^</OOBE^>
echo     ^</component^>
echo   ^</settings^>
echo ^</unattend^>
) > W:\Windows\System32\Sysprep\unattend.xml

bcdboot W:\Windows /s S: /f UEFI
wpeutil reboot
"@
            $KichBanBat | Out-File -FilePath "$($TrangThaiHeThong.DriveLetter):\auto_install.bat" -Encoding ASCII
            CapNhat-Buoc 4 "HoanTat"
            
            $TrangThai.Text = "Xử lý hoàn tất! Hệ thống sẽ khởi động lại sau 5 giây."
            reagentc /boottore
            shutdown /r /t 5
        } elseif ($TienTrinhHienTai.State -eq "Failed") {
            $BoDem.Stop()
            CapNhat-Buoc 2 "Loi"
            $TrangThai.Text = "LỖI: Trình xử lý ngầm gặp sự cố!"
            $KhungChuaNut.Children | ForEach-Object { $_.IsEnabled = $true }
        }
    }.GetNewClosure())
    $BoDem.Start()
}

foreach ($Win in $DanhSachWin) {
    $Nut = New-Object System.Windows.Controls.Button
    $Nut.Content = "💾  $($Win.Name)"
    $Nut.Add_Click({ BatDau-TrienKhai $Win })
    $KhungChuaNut.Children.Add($Nut)
}

$CuaSo.FindName("NutThoat").Add_Click({ $CuaSo.Close() })
$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$CuaSo.ShowDialog() | Out-Null