<#
.SYNOPSIS
    Công cụ hỗ trợ cài đặt Windows tự động (Tích hợp Patch lõi WinRE chạy ngầm)
#>

# Yêu cầu quyền quản trị
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Vui long chay kịch ban nay voi quyen Administrator!"
    Start-Sleep -Seconds 3
    Exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ==========================================
# 1. HÀM GIẢI MÃ API VÀ QUẢN LÝ XOAY VÒNG
# ==========================================
$DanhSachAPI_Base64 = @(
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR",
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v",
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv",
    "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR",
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
)

function GiaiMa-API ($ChuoiBase64) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ChuoiBase64))
}

$global:ChiSoAPI = 0
function Lay-API {
    $KhoaApi = GiaiMa-API $DanhSachAPI_Base64[$global:ChiSoAPI]
    $global:ChiSoAPI = ($global:ChiSoAPI + 1) % $DanhSachAPI_Base64.Count
    return $KhoaApi
}

# ==========================================
# HÀM GIAO DIỆN PHỤ VÀ LÀM MƯỚT UI
# ==========================================
function CapNhat-GiaoDien {
    $KhungChayDoi = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [System.Action]{ $KhungChayDoi.Continue = $false }) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($KhungChayDoi)
}

function Chon-ThuMucHienDai($TieuDe) {
    $HopThoai = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoai.Title = $TieuDe
    $HopThoai.ValidateNames = $false
    $HopThoai.CheckFileExists = $false
    $HopThoai.CheckPathExists = $true
    $HopThoai.FileName = "[Chon_Thu_Muc_Nay]" 
    
    if ($HopThoai.ShowDialog() -eq 'OK') {
        return [System.IO.Path]::GetDirectoryName($HopThoai.FileName)
    }
    return $null
}

# ==========================================
# 2. XÂY DỰNG GIAO DIỆN HIỆN ĐẠI BẰNG WPF
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Công Cụ Triển Khai Hệ Thống Tự Động" Height="780" Width="650" Background="#F8FAFC" FontFamily="Segoe UI" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button" x:Key="NutBamHienDai">
            <Setter Property="Background" Value="#3B82F6"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" x:Name="KhungVien">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="KhungVien" Property="Background" Value="#2563EB"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="KhungVien" Property="Background" Value="#1D4ED8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="Button" x:Key="NutTaiDong">
            <Setter Property="Background" Value="#10B981"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="15,12"/>
            <Setter Property="Margin" Value="0,0,10,10"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" x:Name="KhungVien">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,0"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="KhungVien" Property="Background" Value="#059669"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="8"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="BorderBrush" Value="#CBD5E1"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Background" Value="White"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" CornerRadius="4">
                            <ScrollViewer x:Name="PART_ContentHost"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="25">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="120"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="HỆ THỐNG CÀI ĐẶT WINDOWS" FontSize="22" FontWeight="Bold" Foreground="#1E293B" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <StackPanel Grid.Row="1" Margin="0,0,0,15">
            <TextBlock Text="1. File bộ cài (WIM / ESD / ISO) và Phiên bản:" FontWeight="SemiBold" Foreground="#475569" Margin="0,0,0,5"/>
            <Grid Margin="0,0,0,8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="100"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name="HopThoaiFileBoCai" Grid.Column="0" Margin="0,0,10,0" FontSize="13"/>
                <Button x:Name="NutChonFileBoCai" Grid.Column="1" Content="Chọn File" Style="{StaticResource NutBamHienDai}" Background="#64748B"/>
            </Grid>
            <ComboBox x:Name="DanhSachPhienBanWin" FontSize="13" Padding="6" IsEnabled="False">
                <ComboBoxItem IsSelected="True">Chưa có bộ cài nào được chọn...</ComboBoxItem>
            </ComboBox>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,15">
            <TextBlock Text="2. Hoặc tải nhanh từ máy chủ hệ thống:" FontWeight="SemiBold" Foreground="#475569" Margin="0,0,0,5"/>
            <Border Background="White" BorderBrush="#E2E8F0" BorderThickness="1" CornerRadius="6" Padding="15" MinHeight="150" MaxHeight="300">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <WrapPanel x:Name="KhungChuaNutWim" Orientation="Horizontal"/>
                </ScrollViewer>
            </Border>
        </StackPanel>

        <StackPanel Grid.Row="3" Margin="0,0,0,15">
            <TextBlock Text="3. Thư mục chứa Driver (Để xả tự động):" FontWeight="SemiBold" Foreground="#475569" Margin="0,0,0,5"/>
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="100"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name="HopThoaiThuMucDriver" Grid.Column="0" Margin="0,0,10,0" FontSize="13"/>
                <Button x:Name="NutChonThuMucDriver" Grid.Column="1" Content="Chọn Thư Mục" Style="{StaticResource NutBamHienDai}" Background="#64748B"/>
            </Grid>
        </StackPanel>

        <TextBox x:Name="HopThoaiNhatKy" Grid.Row="4" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="#0F172A" Foreground="#38BDF8" FontFamily="Consolas" FontSize="12" Margin="0,0,0,15"/>

        <Button x:Name="NutBatDauCaiDat" Grid.Row="5" Content="BẮT ĐẦU TỰ ĐỘNG HÓA HỆ THỐNG" Style="{StaticResource NutBamHienDai}" Background="#EF4444" FontSize="16" Height="50"/>
    </Grid>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML)
$GiaoDien = [Windows.Markup.XamlReader]::Load($TrinhDoc)

$HopThoaiFileBoCai = $GiaoDien.FindName("HopThoaiFileBoCai")
$NutChonFileBoCai = $GiaoDien.FindName("NutChonFileBoCai")
$DanhSachPhienBanWin = $GiaoDien.FindName("DanhSachPhienBanWin")
$KhungChuaNutWim = $GiaoDien.FindName("KhungChuaNutWim")
$HopThoaiThuMucDriver = $GiaoDien.FindName("HopThoaiThuMucDriver")
$NutChonThuMucDriver = $GiaoDien.FindName("NutChonThuMucDriver")
$HopThoaiNhatKy = $GiaoDien.FindName("HopThoaiNhatKy")
$NutBatDauCaiDat = $GiaoDien.FindName("NutBatDauCaiDat")

# ==========================================
# CÁC HÀM XỬ LÝ VÀ NHẬT KÝ
# ==========================================

function Ghi-NhatKy($NoiDung) {
    $ThoiGian = Get-Date -Format "HH:mm:ss"
    $HopThoaiNhatKy.AppendText("[$ThoiGian] $NoiDung`n")
    $HopThoaiNhatKy.ScrollToEnd()
    CapNhat-GiaoDien
}

# ==========================================
# HÀM QUÉT BỘ CÀI VÀ XUẤT DANH SÁCH RA GIAO DIỆN
# ==========================================
function Quet-VaCapNhatPhienBanWin {
    $DuongDanFile = $HopThoaiFileBoCai.Text
    if (-not (Test-Path $DuongDanFile)) { return }

    Ghi-NhatKy "Đang quét các phiên bản Windows bên trong lõi..."
    $DanhSachPhienBanWin.Items.Clear()
    $DanhSachPhienBanWin.IsEnabled = $false
    $DanhSachPhienBanWin.Items.Add("⏳ Đang phân tích file bộ cài...") | Out-Null
    $DanhSachPhienBanWin.SelectedIndex = 0
    CapNhat-GiaoDien

    $FileWimCanQuet = $DuongDanFile
    $DaMountIso = $false
    $KyTuODiaAo = $null

    try {
        if ($DuongDanFile -match '(?i)\.iso$') {
            $ThongTinMount = Mount-DiskImage -ImagePath $DuongDanFile -PassThru
            Start-Sleep -Seconds 1 
            $KyTuODiaAo = (Get-DiskImage -ImagePath $DuongDanFile | Get-Volume).DriveLetter
            
            if ($KyTuODiaAo -is [array]) { $KyTuODiaAo = $KyTuODiaAo[0] }
            if (-not $KyTuODiaAo) { throw "Không nhận dạng được ổ đĩa ảo ISO." }
            
            $FileWimCanQuet = "$($KyTuODiaAo):\sources\install.wim"
            if (-not (Test-Path $FileWimCanQuet)) { $FileWimCanQuet = "$($KyTuODiaAo):\sources\install.esd" }
            $DaMountIso = $true
        }

        if (Test-Path $FileWimCanQuet) {
            $ThongTinWim = dism.exe /Get-WimInfo /WimFile:$FileWimCanQuet /English
            $CacPhienBan = @()
            $ChiSoHienTai = $null
            
            foreach ($Dong in $ThongTinWim) {
                if ($Dong -match 'Index : (\d+)') { $ChiSoHienTai = $matches[1] }
                if ($Dong -match 'Name : (.*)') {
                    if ($ChiSoHienTai) {
                        $CacPhienBan += [PSCustomObject]@{ Index = $ChiSoHienTai; Ten = $matches[1] }
                        $ChiSoHienTai = $null
                    }
                }
            }

            $DanhSachPhienBanWin.Items.Clear()
            if ($CacPhienBan.Count -gt 0) {
                foreach ($BanWin in $CacPhienBan) {
                    $DanhSachPhienBanWin.Items.Add("Index $($BanWin.Index): $($BanWin.Ten)") | Out-Null
                }
                $DanhSachPhienBanWin.IsEnabled = $true
                $DanhSachPhienBanWin.SelectedIndex = 0
                Ghi-NhatKy "✅ Tìm thấy $($CacPhienBan.Count) phiên bản. Đã hiển thị ra danh sách chọn!"
            } else {
                $DanhSachPhienBanWin.Items.Add("❌ Không đọc được danh sách phiên bản") | Out-Null
            }
        } else {
            $DanhSachPhienBanWin.Items.Clear()
            $DanhSachPhienBanWin.Items.Add("❌ Lỗi: ISO không chứa install.wim / install.esd") | Out-Null
            Ghi-NhatKy "Lỗi: ISO thiếu file lõi."
        }
    } catch {
        Ghi-NhatKy "Lỗi khi quét file: $_"
        $DanhSachPhienBanWin.Items.Clear()
        $DanhSachPhienBanWin.Items.Add("❌ Xảy ra lỗi khi đọc file bộ cài") | Out-Null
    } finally {
        if ($DaMountIso) {
            Dismount-DiskImage -ImagePath $DuongDanFile | Out-Null
        }
    }
}

# SỰ KIỆN: Người dùng tự chọn file từ máy
$NutChonFileBoCai.Add_Click({
    $HopThoaiFile = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoaiFile.Title = "Chọn file bộ cài (WIM, ESD, ISO)"
    $HopThoaiFile.Filter = "Windows Setup Files (*.wim;*.esd;*.iso)|*.wim;*.esd;*.iso|All Files (*.*)|*.*"
    if ($HopThoaiFile.ShowDialog() -eq 'OK') { 
        $HopThoaiFileBoCai.Text = $HopThoaiFile.FileName 
        Quet-VaCapNhatPhienBanWin
    }
})

$NutChonThuMucDriver.Add_Click({
    $KetQua = Chon-ThuMucHienDai "Vào thư mục chứa Driver và bấm OPEN (MỞ)"
    if ($KetQua) { $HopThoaiThuMucDriver.Text = $KetQua }
})

# ==========================================
# BỘ QUÉT CSV VÀ TẠO NÚT TẢI API
# ==========================================
$GiaoDien.Add_ContentRendered({
    Ghi-NhatKy "Đang tải dữ liệu và phân tích cấu trúc CSV..."
    
    $DuongDanTrucTuyen = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"
    
    try {
        $MayKhachWeb = New-Object System.Net.WebClient
        $MayKhachWeb.Encoding = [System.Text.Encoding]::UTF8
        $NoiDungTho = $MayKhachWeb.DownloadString($DuongDanTrucTuyen)
        $DuLieuCsv = $NoiDungTho | ConvertFrom-Csv

        $SoLuongNutDaTao = 0

        foreach ($DongDuLieu in $DuLieuCsv) {
            $TenFile = ""
            $MaGGDrive = ""

            foreach ($ThuocTinh in $DongDuLieu.psobject.properties) {
                $TenCot = [string]$ThuocTinh.Name.Trim()
                $GiaTri = [string]$ThuocTinh.Value.Trim()

                if ($TenCot -match '(?i)^Name$') { $TenFile = $GiaTri }
                if ($TenCot -match '(?i)^FileID$') { $MaGGDrive = $GiaTri }
            }

            if ($TenFile -match '(?i)\.wim$' -and -not [string]::IsNullOrWhiteSpace($MaGGDrive)) {
                
                $NutBamMoi = New-Object System.Windows.Controls.Button
                $NutBamMoi.Content = "⬇ Tải: " + $TenFile
                $NutBamMoi.Style = $GiaoDien.FindResource("NutTaiDong")
                $NutBamMoi.Tag = $MaGGDrive 
                
                $NutBamMoi.Add_Click({
                    $MaFileHienTai = $this.Tag
                    $TenHienThiCuaNut = $this.Content -replace "^⬇ Tải: ", ""

                    $KetQuaChonLuu = Chon-ThuMucHienDai "Chọn thư mục lưu bản Win tải về (Lưu ý: Không chọn ổ C)"
                    if (-not $KetQuaChonLuu) { return }
                    
                    $DuongDanLuuFile = Join-Path $KetQuaChonLuu $TenFile
                    $KhoaApiThucTe = Lay-API
                    $LinkTaiQuaApi = "https://www.googleapis.com/drive/v3/files/$MaFileHienTai?alt=media&key=$KhoaApiThucTe"

                    Ghi-NhatKy "Đang kéo bản '$TenHienThiCuaNut' qua Google API..."
                    $GiaoDien.IsEnabled = $false
                    $this.Content = "⏳ Đang kéo dữ liệu..."
                    $this.Background = "#F59E0B"
                    
                    try {
                        $TrinhTaiTaiLieu = New-Object System.Net.WebClient
                        $TrinhTaiTaiLieu.DownloadFile($LinkTaiQuaApi, $DuongDanLuuFile)
                        
                        Ghi-NhatKy "✅ Kéo thành công! Tự động nạp file vào ô số 1."
                        $HopThoaiFileBoCai.Text = $DuongDanLuuFile
                        $this.Content = "✅ Đã tải xong"
                        $this.Background = "#3B82F6" 

                        Quet-VaCapNhatPhienBanWin 
                    } catch {
                        Ghi-NhatKy "❌ Lỗi kéo file: $_"
                        $this.Content = "❌ Lỗi mạng/API"
                        $this.Background = "#EF4444" 
                    }
                    
                    $GiaoDien.IsEnabled = $true
                })

                $KhungChuaNutWim.Children.Add($NutBamMoi) | Out-Null
                $SoLuongNutDaTao++
            }
        }

        if ($SoLuongNutDaTao -gt 0) { Ghi-NhatKy "Đã móc được $SoLuongNutDaTao bản WIM thành công." } 
    } catch {
        Ghi-NhatKy "Lỗi kết nối máy chủ dữ liệu: $_"
    }
})

# ==========================================
# CÁC HÀM XỬ LÝ LÕI VÀ PHẪU THUẬT WINRE
# ==========================================

function KiemTra-Va-TaoPhanVungHeThong {
    Ghi-NhatKy "Đang rà soát lại cấu trúc phân vùng khởi động..."
    $PhanVungHienTai = Get-Partition -DriveLetter "C"
    $MaSoODia = $PhanVungHienTai.DiskNumber

    $TonTaiEFI = Get-Partition -DiskNumber $MaSoODia | Where-Object { $_.Type -eq 'System' }
    $TonTaiRE = Get-Partition -DiskNumber $MaSoODia | Where-Object { $_.Type -eq 'Recovery' }

    if (-not $TonTaiEFI -or -not $TonTaiRE) {
        Ghi-NhatKy "Hệ thống thiếu phân vùng chuẩn. Tiến hành chia lại ổ đĩa..."
        $KichThuocMoiCuaC = $PhanVungHienTai.Size - 1GB
        Resize-Partition -DriveLetter "C" -Size $KichThuocMoiCuaC
        
        $NoiDungDiskpart = @"
select disk $MaSoODia
create partition efi size=260
format quick fs=fat32 label="System"
assign letter=S
create partition primary size=750
format quick fs=ntfs label="Recovery"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
assign letter=R
"@
        $NoiDungDiskpart | Out-File "$env:TEMP\lenh_diskpart_tam.txt" -Encoding ascii
        Start-Process -FilePath "diskpart.exe" -ArgumentList "/s $env:TEMP\lenh_diskpart_tam.txt" -Wait -WindowStyle Hidden
        Ghi-NhatKy "Đã định dạng thành công phân vùng EFI và RE."
    } else {
        Ghi-NhatKy "Cấu trúc phân vùng đã đáp ứng đủ tiêu chuẩn."
    }
}

function Nhap-KichBanVaoMoiTruongRE {
    param($DuongDanTapTinWim, $ChiSoIndex, $DuongDanThuMucDriver)
    
    Ghi-NhatKy "Tắt WinRE tạm thời để kéo file lõi về C:\..."
    reagentc.exe /disable | Out-Null
    Start-Sleep -Seconds 3

    $WinREPath = "C:\Windows\System32\Recovery\winre.wim"
    if (-not (Test-Path $WinREPath)) {
        # Quét dự phòng nếu winre.wim bị giấu ở chỗ khác
        Ghi-NhatKy "Đang dò tìm vị trí winre.wim..."
        $WinREPath = (Get-ChildItem -Path C:\ -Recurse -Filter "winre.wim" -Hidden -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
        if (-not $WinREPath) { throw "Tuyệt vọng: Không tìm thấy file winre.wim trong hệ thống!" }
    }

    $ThuMucMount = "C:\MountRE"
    if (Test-Path $ThuMucMount) { Remove-Item -Path $ThuMucMount -Recurse -Force }
    New-Item -ItemType Directory -Path $ThuMucMount | Out-Null

    Ghi-NhatKy "Đang Mount (mở bụng) lõi WinRE. Quá trình này mất khoảng 1-2 phút..."
    CapNhat-GiaoDien
    dism.exe /Mount-Image /ImageFile:$WinREPath /Index:1 /MountDir:$ThuMucMount | Out-Null

    Ghi-NhatKy "Đang tiêm kịch bản cài đặt tự động vào não WinRE..."
    
    # 1. Kịch bản xả Driver và tải Anydesk (Lưu thẳng vào WinRE để không bị mất khi format ổ C)
    $NoiDungCaiXong = @"
@echo off
echo Tien hanh xa driver vao he thong moi...
pnputil /add-driver "$DuongDanThuMucDriver\*.inf" /subdirs /install

echo Phat hanh Anydesk...
powershell -Command "Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'"
start "" "C:\Users\Public\Desktop\AnyDesk.exe"

del %0
"@
    $NoiDungCaiXong | Out-File "$ThuMucMount\Windows\System32\LenhCaiXong_TamThoi.cmd" -Encoding oem

    # 2. Kịch bản Gốc: Chạy bên trong WinRE (Format, Cài Win, Copy lệnh SetupComplete)
    $NoiDungTrongRE = @"
@echo off
echo Format o C va trien khai Windows moi...
echo select volume c > X:\dinhdang_o_c.txt
echo format quick fs=ntfs >> X:\dinhdang_o_c.txt
diskpart /s X:\dinhdang_o_c.txt

dism /apply-image /imagefile:"$DuongDanTapTinWim" /index:$ChiSoIndex /applydir:C:\
bcdboot C:\Windows

mkdir C:\Windows\Setup\Scripts
copy /Y X:\Windows\System32\LenhCaiXong_TamThoi.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd

wpeutil reboot
"@
    $NoiDungTrongRE | Out-File "$ThuMucMount\Windows\System32\LenhChayTrongRE.cmd" -Encoding oem

    # 3. Ép WinRE chạy thẳng kịch bản thay vì hiện Menu xanh
    $WinpeshlIni = @"
[LaunchApps]
X:\Windows\System32\LenhChayTrongRE.cmd
"@
    $WinpeshlIni | Out-File "$ThuMucMount\Windows\System32\winpeshl.ini" -Encoding ascii

    Ghi-NhatKy "Đang khâu lại vết mổ và đóng gói WinRE..."
    CapNhat-GiaoDien
    dism.exe /Unmount-Image /MountDir:$ThuMucMount /Commit | Out-Null
    Remove-Item -Path $ThuMucMount -Force

    Ghi-NhatKy "Đang nạp lại WinRE đã độ vào hệ thống..."
    reagentc.exe /enable | Out-Null
}

# ----------------- NÚT THỰC THI CUỐI -----------------
$NutBatDauCaiDat.Add_Click({
    $DuongDanBoCaiThucTe = $HopThoaiFileBoCai.Text
    $DuongDanDriverTuyetDoi = $HopThoaiThuMucDriver.Text
    $ChonPhienBanText = $DanhSachPhienBanWin.SelectedItem

    if ([string]::IsNullOrWhiteSpace($DuongDanBoCaiThucTe) -or !(Test-Path $DuongDanBoCaiThucTe)) {
        [System.Windows.Forms.MessageBox]::Show("Chưa tìm thấy file bộ cài hợp lệ. Vui lòng chọn file hoặc tải từ máy chủ!", "Cảnh Báo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $ChiSoIndexCanCai = $null
    if ($ChonPhienBanText -match 'Index (\d+):') {
        $ChiSoIndexCanCai = $matches[1]
    } else {
        [System.Windows.Forms.MessageBox]::Show("Vui lòng đợi quét danh sách hoặc chọn phiên bản Win cụ thể trước khi ấn Bắt đầu!", "Lỗi Chọn Bản Win", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $KyTuOChuaBoCai = [System.IO.Path]::GetPathRoot($DuongDanBoCaiThucTe)
    if ($KyTuOChuaBoCai -match "(?i)^C:") {
        [System.Windows.Forms.MessageBox]::Show("Tuyệt đối không được để file bộ cài trên ổ C:\ !`nVì quy trình này sẽ format sạch sẽ toàn bộ ổ C. Vui lòng chuyển file sang ổ khác.", "Lỗi Nghiêm Trọng", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $HopThoaiXacNhan = [System.Windows.Forms.MessageBox]::Show("Xác nhận Cài Đặt: $($ChonPhienBanText)`n`nNGUY HIỂM: Quá trình này sẽ format sạch ổ C và nạp lại hệ điều hành. Mọi dữ liệu trên ổ C sẽ bốc hơi.`nTiếp tục tiến trình?", "Cảnh Báo An Toàn", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Stop)
    
    if ($HopThoaiXacNhan -eq 'Yes') {
        $NutBatDauCaiDat.IsEnabled = $false
        
        if ($DuongDanBoCaiThucTe -match '(?i)\.iso$') {
            Ghi-NhatKy "Phát hiện file ISO. Đang trích xuất file lõi (Vui lòng đợi 1-2 phút)..."
            try {
                $ThongTinMount = Mount-DiskImage -ImagePath $DuongDanBoCaiThucTe -PassThru
                Start-Sleep -Seconds 1
                $KyTuODiaAo = (Get-DiskImage -ImagePath $DuongDanBoCaiThucTe | Get-Volume).DriveLetter
                if ($KyTuODiaAo -is [array]) { $KyTuODiaAo = $KyTuODiaAo[0] }
                
                $DuongDanODiaAo = "$($KyTuODiaAo):\"
                $DuongDanWimAo = Join-Path $DuongDanODiaAo "sources\install.wim"
                $DuongDanEsdAo = Join-Path $DuongDanODiaAo "sources\install.esd"

                $FileCanTrichXuat = $null
                $DuoiFileTrichXuat = ".wim"
                if (Test-Path $DuongDanWimAo) { $FileCanTrichXuat = $DuongDanWimAo }
                elseif (Test-Path $DuongDanEsdAo) { $FileCanTrichXuat = $DuongDanEsdAo; $DuoiFileTrichXuat = ".esd" }

                if ($FileCanTrichXuat) {
                    $ThuMucChuaIso = [System.IO.Path]::GetDirectoryName($DuongDanBoCaiThucTe)
                    $DuongDanTrichXuatXong = Join-Path $ThuMucChuaIso "install_extracted$DuoiFileTrichXuat"
                    
                    Copy-Item -Path $FileCanTrichXuat -Destination $DuongDanTrichXuatXong -Force
                    $DuongDanBoCaiThucTe = $DuongDanTrichXuatXong 
                    Ghi-NhatKy "Trích xuất ISO thành công!"
                } else {
                    throw "Bản ISO này không chứa file install.wim hay install.esd hợp lệ."
                }
            } catch {
                Ghi-NhatKy "❌ Lỗi trích xuất ISO: $_"
                Dismount-DiskImage -ImagePath $DuongDanBoCaiThucTe | Out-Null
                $NutBatDauCaiDat.IsEnabled = $true
                return
            }
            Dismount-DiskImage -ImagePath $DuongDanBoCaiThucTe | Out-Null
        }

        KiemTra-Va-TaoPhanVungHeThong
        
        # BƯỚC ĐỘ WINRE
        Nhap-KichBanVaoMoiTruongRE -DuongDanTapTinWim $DuongDanBoCaiThucTe -ChiSoIndex $ChiSoIndexCanCai -DuongDanThuMucDriver $DuongDanDriverTuyetDoi
        
        Ghi-NhatKy "Ép máy tính vào chế độ Recovery ở lần khởi động tới..."
        reagentc.exe /boottore | Out-Null
        
        Ghi-NhatKy "CHUẨN BỊ XONG. MÁY SẼ TỰ RESET TRONG 5 GIÂY NỮA!"
        Start-Sleep -Seconds 5
        
        # MỞ KHÓA DÒNG DƯỚI ĐỂ TỰ ĐỘNG KHỞI ĐỘNG LẠI
        # Restart-Computer -Force
    }
})

$GiaoDien.ShowDialog() | Out-Null