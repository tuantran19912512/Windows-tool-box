<#
.SYNOPSIS
    CÔNG CỤ TRIỂN KHAI WINDOWS TỰ ĐỘNG - PHIÊN BẢN HOÀN THIỆN TỐI THƯỢNG (Fixed UI)
    Tác giả: Tuấn & AI Assistant
#>

# ==========================================
# 0. YÊU CẦU QUYỀN QUẢN TRỊ (ADMINISTRATOR)
# ==========================================
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "CẢNH BÁO: Phải chạy script này bằng quyền Run as Administrator!"
    Start-Sleep -Seconds 3
    Exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ==========================================
# 1. QUẢN LÝ API GOOGLE DRIVE (VƯỢT GIỚI HẠN)
# ==========================================
$DanhSachAPI_Base64 = @(
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR",
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v",
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv",
    "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR",
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
)

function GiaiMa-API ($ChuoiBase64) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ChuoiBase64)) }

$global:ChiSoAPI = 0
function Lay-API {
    $KhoaApi = GiaiMa-API $DanhSachAPI_Base64[$global:ChiSoAPI]
    $global:ChiSoAPI = ($global:ChiSoAPI + 1) % $DanhSachAPI_Base64.Count
    return $KhoaApi
}

# ==========================================
# 2. HÀM GIAO DIỆN PHỤ & LÀM MƯỢT UI
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
    $HopThoai.FileName = "[Vào_thư_mục_và_bấm_Open]" 
    if ($HopThoai.ShowDialog() -eq 'OK') { return [System.IO.Path]::GetDirectoryName($HopThoai.FileName) }
    return $null
}

# ==========================================
# 3. XÂY DỰNG GIAO DIỆN WPF (XAML)
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Hệ Thống Triển Khai Windows Tự Động (Zero-Touch)" Height="780" Width="680" Background="#F1F5F9" FontFamily="Segoe UI" WindowStartupLocation="CenterScreen">
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
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="KhungVien" Property="Background" Value="#2563EB"/></Trigger>
                            <Trigger Property="IsPressed" Value="True"><Setter TargetName="KhungVien" Property="Background" Value="#1D4ED8"/></Trigger>
                            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="KhungVien" Property="Background" Value="#94A3B8"/></Trigger>
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
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="KhungVien" Property="Background" Value="#059669"/></Trigger>
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
            <RowDefinition Height="140"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="HỆ THỐNG CÀI ĐẶT WINDOWS TỰ ĐỘNG" FontSize="22" FontWeight="Bold" Foreground="#0F172A" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="1. Chọn file bộ cài (WIM / ESD / ISO) và Phiên bản:" FontWeight="SemiBold" Foreground="#334155" Margin="0,0,0,8"/>
                <Grid Margin="0,0,0,10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="110"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="HopThoaiFileBoCai" Grid.Column="0" Margin="0,0,10,0" FontSize="13" IsReadOnly="True" Background="#F8FAFC"/>
                    <Button x:Name="NutChonFileBoCai" Grid.Column="1" Content="Duyệt File" Style="{StaticResource NutBamHienDai}" Background="#475569"/>
                </Grid>
                <ComboBox x:Name="DanhSachPhienBanWin" FontSize="13" Padding="8" IsEnabled="False">
                    <ComboBoxItem IsSelected="True">Chưa có bộ cài nào được nạp...</ComboBoxItem>
                </ComboBox>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="2. Hoặc kéo file trực tiếp từ Cloud Server:" FontWeight="SemiBold" Foreground="#334155" Margin="0,0,0,8"/>
                <ScrollViewer VerticalScrollBarVisibility="Auto" Height="120">
                    <WrapPanel x:Name="KhungChuaNutWim" Orientation="Horizontal"/>
                </ScrollViewer>
            </StackPanel>
        </Border>

        <Border Grid.Row="3" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="3. Thư mục chứa Driver (Tự động xả sau khi cài):" FontWeight="SemiBold" Foreground="#334155" Margin="0,0,0,8"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="110"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="HopThoaiThuMucDriver" Grid.Column="0" Margin="0,0,10,0" FontSize="13"/>
                    <Button x:Name="NutChonThuMucDriver" Grid.Column="1" Content="Chọn Thư Mục" Style="{StaticResource NutBamHienDai}" Background="#475569"/>
                </Grid>
            </StackPanel>
        </Border>

        <TextBox x:Name="HopThoaiNhatKy" Grid.Row="4" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="#020617" Foreground="#38BDF8" FontFamily="Consolas" FontSize="12" Margin="0,0,0,15"/>

        <Button x:Name="NutBatDauCaiDat" Grid.Row="5" Content="BẮT ĐẦU TỰ ĐỘNG HÓA HỆ THỐNG" Style="{StaticResource NutBamHienDai}" Background="#E11D48" FontSize="16" Height="55"/>
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
# 4. HÀM XỬ LÝ LÕI VÀ SỰ KIỆN UI
# ==========================================

function Ghi-NhatKy($NoiDung) {
    $ThoiGian = Get-Date -Format "HH:mm:ss"
    $HopThoaiNhatKy.AppendText("[$ThoiGian] $NoiDung`n")
    $HopThoaiNhatKy.ScrollToEnd()
    CapNhat-GiaoDien
}

# --- HÀM QUÉT INDEX TỪ FILE BỘ CÀI ---
function Quet-VaCapNhatPhienBanWin {
    $DuongDanFile = $HopThoaiFileBoCai.Text
    if (-not (Test-Path $DuongDanFile)) { return }

    Ghi-NhatKy "Đang dùng DISM quét lõi bộ cài..."
    $DanhSachPhienBanWin.Items.Clear()
    $DanhSachPhienBanWin.IsEnabled = $false
    $DanhSachPhienBanWin.Items.Add("⏳ Đang phân tích file...") | Out-Null
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
            if (-not $KyTuODiaAo) { throw "Không tạo được ổ ảo từ ISO." }
            
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
                Ghi-NhatKy "✅ Tìm thấy $($CacPhienBan.Count) phiên bản hệ điều hành!"
            } else {
                $DanhSachPhienBanWin.Items.Add("❌ Không đọc được danh sách") | Out-Null
            }
        } else {
            $DanhSachPhienBanWin.Items.Clear()
            $DanhSachPhienBanWin.Items.Add("❌ Lỗi: ISO không chứa file WIM/ESD") | Out-Null
        }
    } catch {
        Ghi-NhatKy "Lỗi khi quét file: $_"
        $DanhSachPhienBanWin.Items.Clear()
        $DanhSachPhienBanWin.Items.Add("❌ Xảy ra lỗi khi đọc bộ cài") | Out-Null
    } finally {
        if ($DaMountIso) { Dismount-DiskImage -ImagePath $DuongDanFile | Out-Null }
    }
}

# --- CÁC NÚT DUYỆT THƯ MỤC/FILE ---
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
    $KetQua = Chon-ThuMucHienDai "Chọn thư mục chứa Driver cho máy này"
    if ($KetQua) { $HopThoaiThuMucDriver.Text = $KetQua }
})

# --- KẾT NỐI CLOUD VÀ TẠO NÚT TẢI ---
$GiaoDien.Add_ContentRendered({
    Ghi-NhatKy "Khởi động hệ thống. Đang tải dữ liệu Cloud..."
    try {
        $MayKhachWeb = New-Object System.Net.WebClient
        $MayKhachWeb.Encoding = [System.Text.Encoding]::UTF8
        $DuLieuCsv = $MayKhachWeb.DownloadString("https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv") | ConvertFrom-Csv

        $Dem = 0
        foreach ($Dong in $DuLieuCsv) {
            $TenFile = ""; $MaGGDrive = ""
            foreach ($ThuocTinh in $Dong.psobject.properties) {
                if ($ThuocTinh.Name -match '(?i)^Name$') { $TenFile = $ThuocTinh.Value.Trim() }
                if ($ThuocTinh.Name -match '(?i)^FileID$') { $MaGGDrive = $ThuocTinh.Value.Trim() }
            }

            if ($TenFile -match '(?i)\.wim$' -and $MaGGDrive) {
                $NutMoi = New-Object System.Windows.Controls.Button
                $NutMoi.Content = "⬇ Tải: " + $TenFile
                $NutMoi.Style = $GiaoDien.FindResource("NutTaiDong")
                $NutMoi.Tag = $MaGGDrive 
                
                $NutMoi.Add_Click({
                    $IDFile = $this.Tag
                    $TenHienThi = $this.Content -replace "^⬇ Tải: ", ""

                    $NoiLuu = Chon-ThuMucHienDai "Chọn NƠI LƯU bản Win (Không chọn ổ C)"
                    if (-not $NoiLuu) { return }
                    
                    $DuongDanLuu = Join-Path $NoiLuu $TenFile
                    $APIKey = Lay-API
                    $LinkTai = "https://www.googleapis.com/drive/v3/files/$IDFile?alt=media&key=$APIKey"

                    Ghi-NhatKy "Đang kéo '$TenHienThi' qua Google API..."
                    $GiaoDien.IsEnabled = $false
                    $this.Content = "⏳ Đang tải..."
                    $this.Background = "#F59E0B"
                    
                    try {
                        (New-Object System.Net.WebClient).DownloadFile($LinkTai, $DuongDanLuu)
                        Ghi-NhatKy "✅ Tải xong! Tự động nạp vào hệ thống."
                        $HopThoaiFileBoCai.Text = $DuongDanLuu
                        $this.Content = "✅ Đã tải"
                        $this.Background = "#3B82F6" 
                        Quet-VaCapNhatPhienBanWin 
                    } catch {
                        Ghi-NhatKy "❌ Lỗi kéo file: $_"
                        $this.Content = "❌ Lỗi mạng"
                        $this.Background = "#EF4444" 
                    }
                    $GiaoDien.IsEnabled = $true
                })

                $KhungChuaNutWim.Children.Add($NutMoi) | Out-Null
                $Dem++
            }
        }
        if ($Dem -gt 0) { Ghi-NhatKy "✅ Đã kết nối Cloud, bắt được $Dem bản Windows." } 
    } catch {
        Ghi-NhatKy "❌ Lỗi kết nối Cloud: $_"
    }
})

# ==========================================
# 5. KHỐI LÕI: CAN THIỆP PHÂN VÙNG VÀ WINRE
# ==========================================

function ChuanBi-PhanVungHeThong {
    Ghi-NhatKy "Đang kiểm tra cấu trúc EFI & Recovery..."
    
    try {
        # 1. Tự động tìm ký tự ổ đĩa chứa Windows (thường là C:)
        $ChuCaiO_Win = [System.IO.Path]::GetPathRoot($env:windir).Substring(0,1)
        
        # 2. Lấy thông tin phân vùng một cách an toàn
        $PhanVungOS = Get-Partition -DriveLetter $ChuCaiO_Win -ErrorAction Stop
        $global:OsDiskNum = $PhanVungOS.DiskNumber
        $global:OsPartNum = $PhanVungOS.PartitionNumber # Lưu lại để dùng cho bước sau

        Ghi-NhatKy "Xác nhận OS nằm trên Disk: $global:OsDiskNum, Partition: $global:OsPartNum"

        # 3. Kiểm tra xem đã có phân vùng EFI (System) và Recovery chưa
        $CacPhanVung = Get-Partition -DiskNumber $global:OsDiskNum
        $CoEFI = $CacPhanVung | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -or $_.Type -eq 'System' }
        $CoRec = $CacPhanVung | Where-Object { $_.GptType -eq '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -or $_.Type -eq 'Recovery' }

        if (-not $CoEFI -or -not $CoRec) {
            Ghi-NhatKy "⚠️ Thiếu phân vùng hệ thống. Đang tách 1GB từ ổ $ChuCaiO_Win để tạo..."
            
            # Tính toán kích thước mới (Size hiện tại trừ đi 1GB)
            $KichThuocHienTai = $PhanVungOS.Size
            $KichThuocMoi = $KichThuocHienTai - 1GB
            
            Resize-Partition -DriveLetter $ChuCaiO_Win -Size $KichThuocMoi -ErrorAction Stop
            
            # Chạy Diskpart để tạo phân vùng
            $ScriptDiskpart = @"
select disk $global:OsDiskNum
create partition efi size=260
format quick fs=fat32 label="System"
assign letter=S
create partition primary size=740
format quick fs=ntfs label="Recovery"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
assign letter=R
"@
            $PathDiskpart = "$env:TEMP\diskpart_auto.txt"
            $ScriptDiskpart | Out-File $PathDiskpart -Encoding ascii
            Start-Process "diskpart.exe" "/s $PathDiskpart" -Wait -WindowStyle Hidden
            
            Ghi-NhatKy "✅ Đã cấu trúc lại phân vùng EFI & Recovery thành công."
        } else {
            Ghi-NhatKy "✅ Hệ thống đã có đủ phân vùng cần thiết."
        }
    } catch {
        $Loi = $_.Exception.Message
        Ghi-NhatKy "❌ LỖI PHÂN VÙNG: $Loi"
        throw "Không thể chuẩn bị phân vùng: $Loi"
    }
}

function Do-WinRE_Va_KichNo {
    param($WimPath, $Index, $DriverPath)
    
    Ghi-NhatKy "Đang trích xuất thông tin định tuyến ổ đĩa..."
    # 1. Lấy số thứ tự chính xác của phân vùng OS hiện tại để vứt vào WinRE
    $PhanVungOS = Get-Partition -DriveLetter "C"
    $OsDiskNum = $PhanVungOS.DiskNumber
    $OsPartNum = $PhanVungOS.PartitionNumber

    # 2. Lấy đường dẫn tương đối của file WIM (bỏ ký tự ổ đĩa gốc)
    # Ví dụ: "D:\Images\install.wim" -> "Images\install.wim"
    $DuongDanTuongDoi = $WimPath.Substring(3)

    Ghi-NhatKy "Đang Reset và mở khóa WinRE..."
    reagentc.exe /enable | Out-Null; Start-Sleep 2
    reagentc.exe /disable | Out-Null; Start-Sleep 2

    $WinRE_Goc = "C:\Windows\System32\Recovery\winre.wim"
    if (-not (Test-Path $WinRE_Goc)) { throw "Lỗi Chí Mạng: Mất file winre.wim gốc!" }

    Ghi-NhatKy "Đang dọn dẹp các tiến trình DISM bị kẹt..."
    dism.exe /Cleanup-Wim | Out-Null
    CapNhat-GiaoDien

    $ThuMucMount = "C:\MountRE"
    if (Test-Path $ThuMucMount) { 
        dism.exe /Unmount-Image /MountDir:$ThuMucMount /Discard | Out-Null
        Remove-Item -Path $ThuMucMount -Recurse -Force 
    }
    New-Item -ItemType Directory -Path $ThuMucMount | Out-Null

    $ThuMucXuLy = "C:\WinRE_XuLy"
    if (-not (Test-Path $ThuMucXuLy)) { New-Item -ItemType Directory -Path $ThuMucXuLy | Out-Null }
    
    $WinRE_Copy = "$ThuMucXuLy\winre.wim"
    Copy-Item -Path $WinRE_Goc -Destination $WinRE_Copy -Force
    Set-ItemProperty -Path $WinRE_Copy -Name IsReadOnly -Value $false

    Ghi-NhatKy "Đang Mount WinRE an toàn (Xin đợi 30s-1p)..."
    CapNhat-GiaoDien
    $MntRes = dism.exe /Mount-Image /ImageFile:$WinRE_Copy /Index:1 /MountDir:$ThuMucMount | Out-String
    if ($MntRes -notmatch "completed successfully") { throw "DISM không thể Mount: $MntRes" }

    Ghi-NhatKy "Đang cấy kịch bản tự động hóa MỚI vào não WinRE..."
    
    # Kịch bản SetupComplete (Không đổi)
    @"
@echo off
echo Xa Driver vao he thong...
pnputil /add-driver "$DriverPath\*.inf" /subdirs /install
echo Phat hanh Anydesk...
powershell -Command "Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'"
start "" "C:\Users\Public\Desktop\AnyDesk.exe"
del %0
"@ | Out-File "$ThuMucMount\Windows\System32\LenhCaiXong_TamThoi.cmd" -Encoding oem

    # KỊCH BẢN WINRE ĐƯỢC THIẾT KẾ LẠI (TÌM Ổ THÔNG MINH + BREAK LOOP)
    @"
@echo off
echo ==============================================
echo KHOI DONG HE THONG ZERO-TOUCH DEPLOYMENT
echo ==============================================

echo 1. Quet tim file bo cai tren tat ca cac o dia...
set "WIM_THUC_TE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\$DuongDanTuongDoi" (
        set "WIM_THUC_TE=%%D:\$DuongDanTuongDoi"
        goto :TimThayWim
    )
)

:TimThayWim
if "%WIM_THUC_TE%"=="" (
    echo [LOI] Khong tim thay file $DuongDanTuongDoi tren bat ky o dia nao!
    goto :DungHienTruong
)
echo [OK] Phat hien bo cai tai: %WIM_THUC_TE%

echo.
echo 2. Format dung phan vung he dieu hanh (Disk $OsDiskNum - Part $OsPartNum)...
echo select disk $OsDiskNum > X:\dinhdang.txt
echo select partition $OsPartNum >> X:\dinhdang.txt
echo assign letter=W >> X:\dinhdang.txt
echo format quick fs=ntfs label="Windows" >> X:\dinhdang.txt
diskpart /s X:\dinhdang.txt

echo.
echo 3. Dang trien khai Windows (DISM) - Vui long doi...
dism /apply-image /imagefile:"%WIM_THUC_TE%" /index:$Index /applydir:W:\
if %errorlevel% neq 0 (
    echo [LOI] DISM ap dung Image that bai. Ma loi: %errorlevel%
    goto :DungHienTruong
)

echo.
echo 4. Tao boot cho Windows...
bcdboot W:\Windows

echo.
echo 5. Dua lenh hau cai dat vao he thong moi...
mkdir W:\Windows\Setup\Scripts
copy /Y X:\Windows\System32\LenhCaiXong_TamThoi.cmd W:\Windows\Setup\Scripts\SetupComplete.cmd

echo.
echo 6. XOA CONFIG WINRE DE PHA VONG LAP KHOI DONG...
if exist X:\Windows\System32\winpeshl.ini del X:\Windows\System32\winpeshl.ini /F /Q

echo Thanh cong! Khoi dong lai trong 5 giay...
timeout /t 5
wpeutil reboot
exit

:DungHienTruong
echo ==============================================
echo [CANH BAO] XAY RA LOI! TIEN TRINH BI DUNG LAI.
echo Huy bo tu dong reboot de tranh vong lap vo tan.
if exist X:\Windows\System32\winpeshl.ini del X:\Windows\System32\winpeshl.ini /F /Q
echo Nhan phim bat ky de mo CMD...
pause >nul
cmd.exe
"@ | Out-File "$ThuMucMount\Windows\System32\LenhChayTrongRE.cmd" -Encoding oem

    "[LaunchApps]`r`nX:\Windows\System32\LenhChayTrongRE.cmd" | Out-File "$ThuMucMount\Windows\System32\winpeshl.ini" -Encoding ascii

    Ghi-NhatKy "Đang khâu vết mổ và lưu lại WinRE..."
    CapNhat-GiaoDien
    $UnmntRes = dism.exe /Unmount-Image /MountDir:$ThuMucMount /Commit | Out-String
    if ($UnmntRes -notmatch "completed successfully") {
        dism.exe /Unmount-Image /MountDir:$ThuMucMount /Discard | Out-Null
        throw "Lỗi lưu WinRE: $UnmntRes"
    }
    Remove-Item -Path $ThuMucMount -Force

    Ghi-NhatKy "Đang nạp WinRE siêu cấp vào lại hệ thống..."
    Set-ItemProperty -Path $WinRE_Goc -Name IsReadOnly -Value $false
    Copy-Item -Path $WinRE_Copy -Destination $WinRE_Goc -Force
    Remove-Item -Path $ThuMucXuLy -Recurse -Force

    reagentc.exe /enable | Out-Null
    Ghi-NhatKy "Ra lệnh chốt hạ: Ép khởi động vào Recovery!"
    reagentc.exe /boottore | Out-Null
}

# ==========================================
# 6. KÍCH NỔ HỆ THỐNG
# ==========================================
$NutBatDauCaiDat.Add_Click({
    try {
        $FileCai = $HopThoaiFileBoCai.Text
        $FileDriver = $HopThoaiThuMucDriver.Text
        $ChonIndex = $DanhSachPhienBanWin.SelectedItem

        if (-not (Test-Path $FileCai)) { throw "CHẶN: Chưa có file bộ cài hợp lệ!" }
        if ($ChonIndex -notmatch 'Index (\d+):') { throw "CHẶN: Vui lòng chọn một phiên bản Win!" }
        $IndexLoi = $matches[1]

        if ([System.IO.Path]::GetPathRoot($FileCai) -match "(?i)^C:") {
            throw "NGUY HIỂM: File cài nằm trên ổ C:\ ! Hệ thống sẽ format ổ C, file cài sẽ bị xoá. Vui lòng dời sang ổ khác."
        }

        $XacNhan = [System.Windows.Forms.MessageBox]::Show("BẠN SẮP FORMAT Ổ C VÀ CÀI LẠI WIN.`nPhiên bản: $ChonIndex`n`nDữ liệu ổ C sẽ mất sạch. Khởi chạy?", "ĐIỂM KHÔNG QUAY ĐẦU", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Stop)
        if ($XacNhan -ne 'Yes') { return }

        $NutBatDauCaiDat.IsEnabled = $false
        $GiaoDien.Cursor = [System.Windows.Input.Cursors]::Wait

        # XỬ LÝ ISO
        if ($FileCai -match '(?i)\.iso$') {
            Ghi-NhatKy "Đang xả nén file ruột từ ISO..."
            $MntIso = Mount-DiskImage -ImagePath $FileCai -PassThru
            Start-Sleep 1
            $KyTuIso = (Get-DiskImage -ImagePath $FileCai | Get-Volume).DriveLetter[0]
            
            $Wim = "$($KyTuIso):\sources\install.wim"
            $Esd = "$($KyTuIso):\sources\install.esd"
            $FileTrich = if (Test-Path $Wim) { $Wim } elseif (Test-Path $Esd) { $Esd } else { $null }

            if (-not $FileTrich) { throw "ISO này không có file install.wim/esd" }

            $FileCai = Join-Path ([System.IO.Path]::GetDirectoryName($FileCai)) ("install_extracted" + [System.IO.Path]::GetExtension($FileTrich))
            Copy-Item -Path $FileTrich -Destination $FileCai -Force
            Dismount-DiskImage -ImagePath $HopThoaiFileBoCai.Text | Out-Null
            Ghi-NhatKy "✅ Trích xuất ruột ISO thành công!"
        }

        ChuanBi-PhanVungHeThong
        Do-WinRE_Va_KichNo -WimPath $FileCai -Index $IndexLoi -DriverPath $FileDriver
        
        Ghi-NhatKy "🚀 HOÀN TẤT! HỆ THỐNG SẼ TỰ RESET TRONG 5 GIÂY ĐỂ VÀO QUY TRÌNH ZERO-TOUCH."
        Start-Sleep -Seconds 5
        
        # [MỞ KHÓA KHI ĐEM ĐI SỬ DỤNG THỰC TẾ]
        # Restart-Computer -Force
    } catch {
        $Loi = $_.Exception.Message
        Ghi-NhatKy "❌ LỖI HỆ THỐNG CHẶN ĐƯỢC: $Loi"
        [System.Windows.Forms.MessageBox]::Show($Loi, "Tiến Trình Bị Hủy Bỏ Tự Động", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $NutBatDauCaiDat.IsEnabled = $true
        $GiaoDien.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

$GiaoDien.ShowDialog() | Out-Null