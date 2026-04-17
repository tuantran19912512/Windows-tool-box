# ==============================================================================
# BỘ CÔNG CỤ TỰ ĐỘNG CÀI ĐẶT VIETTOOLBOX V604 - MẮT THẦN XUYÊN THẤU
# Khắc phục: Đọc lõi nhị phân (Magic Bytes) để ép xả nén kể cả khi bị sai đuôi file. Báo lỗi xả nén rõ ràng.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. THIẾT LẬP MÔI TRƯỜNG & PHÂN QUYỀN HỆ THỐNG
# ------------------------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$TaiKhoanHienTai = [Security.Principal.WindowsIdentity]::GetCurrent()
$QuyenQuanTri = [Security.Principal.WindowsPrincipal]$TaiKhoanHienTai
if (-not $QuyenQuanTri.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# ------------------------------------------------------------------------------
# 2. CẤU HÌNH BIẾN TOÀN CỤC & TÀI NGUYÊN MẠNG
# ------------------------------------------------------------------------------
$Global:LienKetDuLieuGoc = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$Global:ThuMucLuuTru = Join-Path $env:PUBLIC "LuuTruPhanMemViet"
$Global:TrangThaiHeThong = "NhanhRoi" 

if (-not (Test-Path $Global:ThuMucLuuTru)) { New-Item -ItemType Directory -Path $Global:ThuMucLuuTru -Force | Out-Null }

function GiaiMa-ChuaKhoa ($ChuoiMaHoa) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ChuoiMaHoa)) }
$Global:DanhSachKhoaAPI = @(
    (GiaiMa-ChuaKhoa "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"),
    (GiaiMa-ChuaKhoa "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v"),
    (GiaiMa-ChuaKhoa "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv"),
    (GiaiMa-ChuaKhoa "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR"),
    (GiaiMa-ChuaKhoa "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0")
)

# ------------------------------------------------------------------------------
# 3. ĐỊNH NGHĨA KIỂU DỮ LIỆU HIỂN THỊ
# ------------------------------------------------------------------------------
if (-not ("KieuDuLieuPhanMem" -as [type])) {
    $MaNguonKieuDuLieu = @"
    using System; using System.ComponentModel;
    public class KieuDuLieuPhanMem : INotifyPropertyChanged {
        public event PropertyChangedEventHandler PropertyChanged;
        private void CapNhatUI(string p) { if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs(p)); }
        
        private bool _chon; public bool Chon { get{return _chon;} set{_chon=value;CapNhatUI("Chon");} }
        private string _ten; public string Ten { get{return _ten;} set{_ten=value;CapNhatUI("Ten");} }
        private string _bieutuong; public string BieuTuong { get{return _bieutuong;} set{_bieutuong=value;CapNhatUI("BieuTuong");} }
        private string _duongdantai; public string DuongDanTai { get{return _duongdantai;} set{_duongdantai=value;CapNhatUI("DuongDanTai");} }
        private string _thamso; public string ThamSoNgam { get{return _thamso;} set{_thamso=value;CapNhatUI("ThamSoNgam");} }
        private string _trangthai; public string TrangThai { get{return _trangthai;} set{_trangthai=value;CapNhatUI("TrangThai");} }
        private int _tientrinh; public int TienTrinh { get{return _tientrinh;} set{_tientrinh=value;CapNhatUI("TienTrinh");} }
        private string _danhmuc; public string DanhMuc { get{return _danhmuc;} set{_danhmuc=value;CapNhatUI("DanhMuc");} }
    }
"@
    Add-Type -TypeDefinition $MaNguonKieuDuLieu -Language CSharp
}

function Tao-LoiTatNhanh ($TenCuaPhanMem, $DuongDanFileChay) {
    try {
        $ThuMucManHinh = [Environment]::GetFolderPath("Desktop")
        $TenLoiTatSach = ($TenCuaPhanMem -replace '[\\/:\*\?"<>\|]', '') + ".lnk"
        $DuongDanLoiTat = Join-Path $ThuMucManHinh $TenLoiTatSach
        $HeThongPhimTat = New-Object -ComObject WScript.Shell
        $LoiTat = $HeThongPhimTat.CreateShortcut($DuongDanLoiTat)
        $LoiTat.TargetPath = $DuongDanFileChay
        $LoiTat.WorkingDirectory = [System.IO.Path]::GetDirectoryName($DuongDanFileChay)
        $LoiTat.IconLocation = "$DuongDanFileChay,0"
        $LoiTat.Save()
    } catch {}
}

# HÀM MẮT THẦN: Kiểm tra lõi tệp tin (Magic Bytes) để ép xả nén
function KiemTra-LoiFileNen ($DuongDanKiemTra) {
    try {
        $DongDocNhiPhan = [System.IO.File]::OpenRead($DuongDanKiemTra)
        $MaLoi = New-Object byte[] 4
        $DongDocNhiPhan.Read($MaLoi, 0, 4) | Out-Null
        $DongDocNhiPhan.Close()
        $ChuoiHexa = [System.BitConverter]::ToString($MaLoi)
        # 50-4B-03-04 (ZIP) | 52-61-72-21 (RAR) | 37-7A-BC-AF (7Z)
        if ($ChuoiHexa -match "50-4B-03-04" -or $ChuoiHexa -match "52-61-72-21" -or $ChuoiHexa -match "37-7A-BC-AF") { return $true }
    } catch {}
    return $false
}

# ------------------------------------------------------------------------------
# 4. XÂY DỰNG KHUNG GIAO DIỆN (WPF XAML)
# ------------------------------------------------------------------------------
$MaNguonGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox V604" Width="1000" Height="750" MinWidth="850" MinHeight="600" WindowStartupLocation="CenterScreen" Background="#F8FAFC" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome>
        <WindowChrome GlassFrameThickness="0" CornerRadius="12" CaptionHeight="50" ResizeBorderThickness="8"/>
    </WindowChrome.WindowChrome>
    <Border BorderBrush="#CBD5E1" BorderThickness="1.5" CornerRadius="12">
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="50"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="90"/></Grid.RowDefinitions>
            
            <Border Grid.Row="0" Background="#0F172A" CornerRadius="11,11,0,0" Name="KhungTieuDe">
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="45"/><ColumnDefinition Width="45"/><ColumnDefinition Width="45"/></Grid.ColumnDefinitions>
                    <TextBlock Text="🚀 BỘ CÔNG CỤ VIETTOOLBOX V604 - MẮT THẦN XUYÊN THẤU" Foreground="White" VerticalAlignment="Center" FontWeight="Bold" FontSize="16" Margin="20,0,0,0"/>
                    <Button Name="NutThuNho" Grid.Column="1" Content="—" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#94A3B8" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                    <Button Name="NutPhongTo" Grid.Column="2" Content="⬜" Background="Transparent" BorderThickness="0" FontSize="14" Foreground="#94A3B8" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                    <Button Name="NutThoat" Grid.Column="3" Content="✕" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#F87171" FontWeight="Bold" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                </Grid>
            </Border>

            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="20,15,20,10">
                <Button Name="NutChonToanBo" Content="☑ Chọn tất cả" Width="130" Height="38" Margin="0,0,12,0" Background="#FFFFFF" BorderBrush="#E2E8F0" BorderThickness="1" Foreground="#334155" FontWeight="SemiBold" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                <Button Name="NutHuyChon" Content="☐ Bỏ chọn" Width="130" Height="38" Background="#FFFFFF" BorderBrush="#E2E8F0" BorderThickness="1" Foreground="#334155" FontWeight="SemiBold" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
            </StackPanel>

            <Border Grid.Row="2" Margin="20,0,20,0" BorderBrush="#E2E8F0" BorderThickness="1" CornerRadius="8" Background="White">
                <DataGrid Name="BangHienThiDuLieu" AutoGenerateColumns="False" CanUserAddRows="False" Background="Transparent" RowHeight="65" HeadersVisibility="Column" BorderThickness="0" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#F1F5F9" SelectionMode="Single">
                    <DataGrid.GroupStyle>
                        <GroupStyle>
                            <GroupStyle.ContainerStyle>
                                <Style TargetType="{x:Type GroupItem}">
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="{x:Type GroupItem}">
                                                <StackPanel>
                                                    <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="0,1,0,1" Padding="15,8">
                                                        <TextBlock Text="{Binding Name}" FontWeight="Black" FontSize="15" Foreground="#0F172A" VerticalAlignment="Center"/>
                                                    </Border>
                                                    <ItemsPresenter />
                                                </StackPanel>
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </GroupStyle.ContainerStyle>
                        </GroupStyle>
                    </DataGrid.GroupStyle>

                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader"><Setter Property="Background" Value="#F8FAFC"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Foreground" Value="#475569"/><Setter Property="Padding" Value="15,12"/><Setter Property="BorderThickness" Value="0,0,0,1"/><Setter Property="BorderBrush" Value="#E2E8F0"/></Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridCheckBoxColumn Header="Cài" Binding="{Binding Chon, UpdateSourceTrigger=PropertyChanged}" Width="65"><DataGridCheckBoxColumn.ElementStyle><Style TargetType="CheckBox"><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridCheckBoxColumn.ElementStyle></DataGridCheckBoxColumn>
                        <DataGridTemplateColumn Header="Biểu tượng" Width="90"><DataGridTemplateColumn.CellTemplate><DataTemplate><Image Source="{Binding BieuTuong}" Width="42" Height="42" Margin="5" VerticalAlignment="Center"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn>
                        <DataGridTextColumn Header="Tên phần mềm" Binding="{Binding Ten}" Width="*" FontWeight="SemiBold" FontSize="14" Foreground="#1E293B"><DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="10,0,0,0"/></Style></DataGridTextColumn.ElementStyle></DataGridTextColumn>
                        <DataGridTemplateColumn Header="Tiến trình xử lý" Width="350"><DataGridTemplateColumn.CellTemplate><DataTemplate>
                            <Grid Margin="15,10">
                                <ProgressBar Value="{Binding TienTrinh}" Height="26" Foreground="#10B981" Background="#F1F5F9" BorderThickness="0"><ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="13"/></Style></ProgressBar.Resources></ProgressBar>
                                <TextBlock Text="{Binding TrangThai}" VerticalAlignment="Center" HorizontalAlignment="Center" FontSize="12" FontWeight="Bold" Foreground="#0F172A"/>
                            </Grid>
                        </DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </Border>

            <Border Grid.Row="3" Background="#F8FAFC" BorderBrush="#E2E8F0" BorderThickness="0,1,0,0" CornerRadius="0,0,11,11">
                <UniformGrid Columns="4" Margin="15">
                    <Button Name="NutKichHoat" Content="▶ BẮT ĐẦU CÀI ĐẶT" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="NutTamNgang" Content="⏸ TẠM DỪNG" Background="#F59E0B" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="NutTiepDien" Content="⏯ TIẾP TỤC" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="NutHuyViec" Content="⏹ HỦY BỎ" Background="#EF4444" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                </UniformGrid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$CuaSoChinh = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaNguonGiaoDien))
$BangDanhSach = New-Object System.Collections.ObjectModel.ObservableCollection[Object]

$BoLocGocNhin = [System.Windows.Data.CollectionViewSource]::GetDefaultView($BangDanhSach)
$BoLocGocNhin.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription("DanhMuc")))
$CuaSoChinh.FindName("BangHienThiDuLieu").ItemsSource = $BoLocGocNhin

# ------------------------------------------------------------------------------
# 5. QUẢN LÝ SỰ KIỆN GIAO DIỆN
# ------------------------------------------------------------------------------
$CuaSoChinh.FindName("KhungTieuDe").Add_MouseLeftButtonDown({ $CuaSoChinh.DragMove() })
$CuaSoChinh.FindName("NutThoat").Add_Click({ $CuaSoChinh.Close() })
$CuaSoChinh.FindName("NutThuNho").Add_Click({ $CuaSoChinh.WindowState = "Minimized" })
$CuaSoChinh.FindName("NutPhongTo").Add_Click({ 
    if ($CuaSoChinh.WindowState -eq "Normal") { $CuaSoChinh.WindowState = "Maximized" } else { $CuaSoChinh.WindowState = "Normal" } 
})
$CuaSoChinh.FindName("NutChonToanBo").Add_Click({ foreach ($Muc in $BangDanhSach) {$Muc.Chon=$true} })
$CuaSoChinh.FindName("NutHuyChon").Add_Click({ foreach ($Muc in $BangDanhSach) {$Muc.Chon=$false} })

$DieuKhienKichHoat = $CuaSoChinh.FindName("NutKichHoat")
$DieuKhienTamNgang = $CuaSoChinh.FindName("NutTamNgang")
$DieuKhienTiepDien = $CuaSoChinh.FindName("NutTiepDien")
$DieuKhienHuyViec = $CuaSoChinh.FindName("NutHuyViec")

function CapNhat-TrangThaiNutBam ($TrangThaiMoi) {
    if ($TrangThaiMoi -eq "DangChay") { $DieuKhienKichHoat.IsEnabled=$false; $DieuKhienTamNgang.IsEnabled=$true; $DieuKhienTiepDien.IsEnabled=$false; $DieuKhienHuyViec.IsEnabled=$true }
    elseif ($TrangThaiMoi -eq "TamDung") { $DieuKhienKichHoat.IsEnabled=$false; $DieuKhienTamNgang.IsEnabled=$false; $DieuKhienTiepDien.IsEnabled=$true; $DieuKhienHuyViec.IsEnabled=$true }
    elseif ($TrangThaiMoi -eq "NhanhRoi") { $DieuKhienKichHoat.IsEnabled=$true; $DieuKhienTamNgang.IsEnabled=$false; $DieuKhienTiepDien.IsEnabled=$false; $DieuKhienHuyViec.IsEnabled=$false }
}

$DieuKhienTamNgang.Add_Click({ $Global:TrangThaiHeThong = "TamDung"; CapNhat-TrangThaiNutBam "TamDung" })
$DieuKhienTiepDien.Add_Click({ $Global:TrangThaiHeThong = "DangChay"; CapNhat-TrangThaiNutBam "DangChay" })
$DieuKhienHuyViec.Add_Click({ $Global:TrangThaiHeThong = "DungLai"; CapNhat-TrangThaiNutBam "NhanhRoi" })

# ------------------------------------------------------------------------------
# 6. ĐỘNG CƠ CỐT LÕI: TẢI XUỐNG & CÀI ĐẶT
# ------------------------------------------------------------------------------
function TienHanh-CaiDatToanDien ($PhanMemHienTai) {
    $PhanMemHienTai.TrangThai = "Đang phân tích..."; $PhanMemHienTai.TienTrinh = 5; [System.Windows.Forms.Application]::DoEvents()
    
    $MaLuuTruDrive = ""; if ($PhanMemHienTai.DuongDanTai -match "id=([^&]+)") {$MaLuuTruDrive=$Matches[1]} elseif ($PhanMemHienTai.DuongDanTai -match "/d/([^/]+)") {$MaLuuTruDrive=$Matches[1]}
    
    $DuoiDinhDang = ".exe" 
    $TenFileLuuTam = $PhanMemHienTai.Ten -replace '[\\/:\*\?"<>\|]', ''
    $DuongDanFileTrenMay = Join-Path $Global:ThuMucLuuTru "$TenFileLuuTam$DuoiDinhDang"
    $DaTaiThanhCong = $false
    
    # --- GIAI ĐOẠN 1: TẢI DỮ LIỆU ---
    if ($MaLuuTruDrive) {
        foreach ($KhoaTruyCap in $Global:DanhSachKhoaAPI) {
            try {
                $PhanMemHienTai.TrangThai = "Quét Drive..."; [System.Windows.Forms.Application]::DoEvents()
                
                $UrlKiemTra = "https://www.googleapis.com/drive/v3/files/$($MaLuuTruDrive)?fields=name&key=$KhoaTruyCap"
                $GoiKiemTra = [System.Net.HttpWebRequest]::Create($UrlKiemTra)
                $PhanHoiKiemTra = $GoiKiemTra.GetResponse()
                $DongDuLieuChu = New-Object System.IO.StreamReader($PhanHoiKiemTra.GetResponseStream())
                $NoiDungJson = $DongDuLieuChu.ReadToEnd()
                $PhanHoiKiemTra.Close()

                if ($NoiDungJson -match '"name"\s*:\s*"([^"]+)"') {
                    $TenFileGoc = $Matches[1]
                    $DuoiMoRongGoc = [System.IO.Path]::GetExtension($TenFileGoc)
                    if ($DuoiMoRongGoc -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle|appx)") {
                        $DuoiDinhDang = $DuoiMoRongGoc
                        $DuongDanFileTrenMay = Join-Path $Global:ThuMucLuuTru $TenFileGoc
                    }
                }

                $UrlTaiChinhThuc = "https://www.googleapis.com/drive/v3/files/$($MaLuuTruDrive)?alt=media&key=$KhoaTruyCap"
                $GoiTaiVe = [System.Net.HttpWebRequest]::Create($UrlTaiChinhThuc); $PhanHoiTaiVe = $GoiTaiVe.GetResponse()
                
                if ($PhanHoiTaiVe.ContentLength -lt 1MB) { $PhanHoiTaiVe.Close(); continue }

                $DongDuLieuNhiPhan = $PhanHoiTaiVe.GetResponseStream(); $FileDuLieuGhi = New-Object System.IO.FileStream($DuongDanFileTrenMay, [System.IO.FileMode]::Create)
                $KhoangNhoTam = New-Object byte[] 4MB; $TongKichThuocFile = $PhanHoiTaiVe.ContentLength; $DungLuongDaTai = 0
                
                do {
                    while ($Global:TrangThaiHeThong -eq "TamDung") { Start-Sleep -Milliseconds 200; [System.Windows.Forms.Application]::DoEvents() }
                    if ($Global:TrangThaiHeThong -eq "DungLai") { break }

                    $SoByteDocDuoc = $DongDuLieuNhiPhan.Read($KhoangNhoTam, 0, $KhoangNhoTam.Length)
                    if ($SoByteDocDuoc -gt 0) {
                        $FileDuLieuGhi.Write($KhoangNhoTam, 0, $SoByteDocDuoc); $DungLuongDaTai += $SoByteDocDuoc
                        if ($TongKichThuocFile -gt 0) { $PhanMemHienTai.TienTrinh = [math]::Round(($DungLuongDaTai/$TongKichThuocFile)*100) }
                        $PhanMemHienTai.TrangThai = "Đang tải: $($PhanMemHienTai.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents()
                    }
                } while ($SoByteDocDuoc -gt 0)
                
                $FileDuLieuGhi.Close(); $DongDuLieuNhiPhan.Close(); $PhanHoiTaiVe.Close()
                if ($Global:TrangThaiHeThong -eq "DungLai") { $PhanMemHienTai.TrangThai = "Đã Hủy ⛔"; $PhanMemHienTai.TienTrinh = 0; return }
                $DaTaiThanhCong = $true; break 
            } catch { if ($FileDuLieuGhi) {$FileDuLieuGhi.Close()} }
        }
    } else {
        try {
            $GoiTaiVe = [System.Net.HttpWebRequest]::Create($PhanMemHienTai.DuongDanTai); $PhanHoiTaiVe = $GoiTaiVe.GetResponse()
            
            $KhaiBaoHeader = $PhanHoiTaiVe.Headers["Content-Disposition"]
            if ($KhaiBaoHeader -match 'filename="?([^";]+)"?') {
                $TenFileGoc = [System.Net.WebUtility]::UrlDecode($Matches[1])
                $DuoiMoRongGoc = [System.IO.Path]::GetExtension($TenFileGoc)
                if ($DuoiMoRongGoc -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle)") {
                    $DuoiDinhDang = $DuoiMoRongGoc
                    $DuongDanFileTrenMay = Join-Path $Global:ThuMucLuuTru $TenFileGoc
                }
            }

            $DongDuLieuNhiPhan = $PhanHoiTaiVe.GetResponseStream(); $FileDuLieuGhi = New-Object System.IO.FileStream($DuongDanFileTrenMay, [System.IO.FileMode]::Create)
            $KhoangNhoTam = New-Object byte[] 4MB; $TongKichThuocFile = $PhanHoiTaiVe.ContentLength; $DungLuongDaTai = 0
            
            do {
                while ($Global:TrangThaiHeThong -eq "TamDung") { Start-Sleep -Milliseconds 200; [System.Windows.Forms.Application]::DoEvents() }
                if ($Global:TrangThaiHeThong -eq "DungLai") { break }

                $SoByteDocDuoc = $DongDuLieuNhiPhan.Read($KhoangNhoTam, 0, $KhoangNhoTam.Length)
                if ($SoByteDocDuoc -gt 0) {
                    $FileDuLieuGhi.Write($KhoangNhoTam, 0, $SoByteDocDuoc); $DungLuongDaTai += $SoByteDocDuoc
                    if ($TongKichThuocFile -gt 0) { $PhanMemHienTai.TienTrinh = [math]::Round(($DungLuongDaTai/$TongKichThuocFile)*100) }
                    $PhanMemHienTai.TrangThai = "Đang tải (Direct): $($PhanMemHienTai.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents()
                }
            } while ($SoByteDocDuoc -gt 0)
            
            $FileDuLieuGhi.Close(); $DongDuLieuNhiPhan.Close(); $PhanHoiTaiVe.Close()
            if ($Global:TrangThaiHeThong -eq "DungLai") { $PhanMemHienTai.TrangThai = "Đã Hủy ⛔"; $PhanMemHienTai.TienTrinh = 0; return }
            $DaTaiThanhCong = $true
        } catch { if ($FileDuLieuGhi) {$FileDuLieuGhi.Close()} }
    }

    if (-not $DaTaiThanhCong -and $Global:TrangThaiHeThong -ne "DungLai") { $PhanMemHienTai.TrangThai = "❌ Lỗi mạng/Không tải được"; $PhanMemHienTai.TienTrinh = 0; return }
    
    # Kiểm tra an toàn: File quá nhỏ (rác HTML)
    try {
        $KichThuocThucTe = (Get-Item $DuongDanFileTrenMay -ErrorAction SilentlyContinue).Length
        if ($KichThuocThucTe -lt 100KB) { $PhanMemHienTai.TrangThai = "❌ Tải xịt (File rỗng/Bị chặn)"; $PhanMemHienTai.TienTrinh = 0; return }
    } catch {}

    if ($Global:TrangThaiHeThong -eq "DungLai") { return }

    # --- GIAI ĐOẠN 2: THỰC THI (MẮT THẦN SOI LÕI) ---
    Unblock-File -Path $DuongDanFileTrenMay; $PhanMemHienTai.TienTrinh = 50; [System.Windows.Forms.Application]::DoEvents()

    $PhanMemHienTai.TrangThai = "🔍 Soi lõi tệp tin..."; [System.Windows.Forms.Application]::DoEvents()
    $BatBuocXaNen = KiemTra-LoiFileNen -DuongDanKiemTra $DuongDanFileTrenMay

    if ($DuoiDinhDang -match "(?i)\.msixbundle|\.appx") {
        $PhanMemHienTai.TrangThai = "⚡ Ép cài hệ thống..."; [System.Windows.Forms.Application]::DoEvents()
        try { Add-AppxPackage -Path $DuongDanFileTrenMay -ErrorAction Stop; $PhanMemHienTai.TrangThai = "Hoàn tất ✔️"; $PhanMemHienTai.TienTrinh = 100 } 
        catch { $PhanMemHienTai.TrangThai = "❌ Lỗi Win cũ"; $PhanMemHienTai.TienTrinh = 0 }
    }
    elseif ($BatBuocXaNen -or $DuoiDinhDang -match "(?i)\.(zip|rar|7z)") {
        $PhanMemHienTai.TrangThai = "📦 Đang xả nén..."; [System.Windows.Forms.Application]::DoEvents()
        
        $ThuMucGiaiNenCuaPhanMem = "C:\VietToolbox_Temp\$($TenFileLuuTam -replace ' ', '')"
        if (-not (Test-Path $ThuMucGiaiNenCuaPhanMem)) { New-Item -ItemType Directory -Path $ThuMucGiaiNenCuaPhanMem -Force | Out-Null }
        
        $DuongDan7zChuan1 = "$env:ProgramFiles\7-Zip\7z.exe"; $DuongDan7zChuan2 = "${env:ProgramFiles(x86)}\7-Zip\7z.exe"; $File7zLuuTam = Join-Path $env:TEMP "7za.exe"; $BoGiaiNenChinh = $null
        if (Test-Path $DuongDan7zChuan1) { $BoGiaiNenChinh = $DuongDan7zChuan1 } 
        elseif (Test-Path $DuongDan7zChuan2) { $BoGiaiNenChinh = $DuongDan7zChuan2 } 
        elseif (Test-Path $File7zLuuTam) { $BoGiaiNenChinh = $File7zLuuTam }
        else { try { Invoke-WebRequest "https://github.com/develar/7zip-bin/raw/master/win/x64/7za.exe" -OutFile $File7zLuuTam -UseBasicParsing; $BoGiaiNenChinh = $File7zLuuTam } catch {} }

        if ($BoGiaiNenChinh) {
            # ÉP CHUỖI THAM SỐ AN TOÀN TUYỆT ĐỐI (KHÔNG KHOẢNG TRẮNG BỊ LỖI)
            $ChuoiThamSo7z = "x `"$DuongDanFileTrenMay`" -pAdmin@2512 -o$ThuMucGiaiNenCuaPhanMem -y -bsp0 -bso0"
            $TienTrinhXaNen = Start-Process -FilePath $BoGiaiNenChinh -ArgumentList $ChuoiThamSo7z -PassThru -WindowStyle Hidden
            
            while (-not $TienTrinhXaNen.HasExited) { 
                [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 300 
                if ($Global:TrangThaiHeThong -eq "DungLai") { try { Stop-Process -Id $TienTrinhXaNen.Id -Force -ErrorAction SilentlyContinue } catch {}; $PhanMemHienTai.TrangThai = "Đã Hủy ⛔"; $PhanMemHienTai.TienTrinh = 0; return }
            }
            
            # Kiểm tra nếu xả nén xịt (thường mã ExitCode của 7z là 0 hoặc 1 là OK, 2 trở lên là lỗi pass/hỏng)
            if ($TienTrinhXaNen.ExitCode -ne 0 -and $TienTrinhXaNen.ExitCode -ne 1) {
                $PhanMemHienTai.TrangThai = "❌ Lỗi xả nén/Sai pass"
                $PhanMemHienTai.TienTrinh = 0
                return
            }
        } else {
            Expand-Archive -Path $DuongDanFileTrenMay -DestinationPath $ThuMucGiaiNenCuaPhanMem -Force -ErrorAction SilentlyContinue
        }
        
        if ($Global:TrangThaiHeThong -eq "DungLai") { return }
        
        $PhanMemHienTai.TrangThai = "🔍 Truy tìm bộ cài..."; [System.Windows.Forms.Application]::DoEvents()
        $FileThucThiCuoiCung = $null

        try {
            $TatCaFileExe = Get-ChildItem $ThuMucGiaiNenCuaPhanMem -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "(?i)unins|crash|report|update" } | Sort-Object Length -Descending
            if ($TatCaFileExe) { $FileThucThiCuoiCung = $TatCaFileExe[0].FullName }
        } catch { }

        if ($FileThucThiCuoiCung) {
            $PhanMemHienTai.TrangThai = "🛠️ Đang cài đặt..."; [System.Windows.Forms.Application]::DoEvents()
            
            $LenhThamSoAn = $PhanMemHienTai.ThamSoNgam
            if (-not $LenhThamSoAn) { 
                if ($PhanMemHienTai.Ten -match "(?i)wps") { $LenhThamSoAn = "/S" }
                elseif ($PhanMemHienTai.Ten -match "(?i)foxit") { $LenhThamSoAn = "/quiet /force /lang en" }
                else { $LenhThamSoAn = "/S" }
            }
            
            if ($PhanMemHienTai.Ten -match "(?i)Portable") { 
                $LenhThamSoAn = ""
                Tao-LoiTatNhanh -TenCuaPhanMem $PhanMemHienTai.Ten -DuongDanFileChay $FileThucThiCuoiCung 
            }

            try {
                $ThuMucChuaFile = Split-Path $FileThucThiCuoiCung
                $DanhSachPIDTruoc = Get-Process -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id
                
                $QuaTrinhChayMay = Start-Process -FilePath $FileThucThiCuoiCung -ArgumentList $LenhThamSoAn -WorkingDirectory $ThuMucChuaFile -PassThru 
                
                if ($QuaTrinhChayMay) {
                    $DongHoDemGiay = 0
                    $DanhSachTheoDoi = @($QuaTrinhChayMay.Id)
                    
                    Start-Sleep -Milliseconds 2500
                    $DongHoDemGiay += 2.5
                    
                    $TienTrinhMoi = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $DanhSachPIDTruoc }
                    foreach ($TienTrinh in $TienTrinhMoi) {
                        try {
                            $PathThucTe = $TienTrinh.Path
                            if ($PathThucTe -match "VietToolbox_Temp" -or $TienTrinh.Name -match "(?i)setup|install|wps") {
                                $DanhSachTheoDoi += $TienTrinh.Id
                            }
                        } catch {}
                    }
                    $DanhSachTheoDoi = $DanhSachTheoDoi | Select-Object -Unique

                    while ($DanhSachTheoDoi.Count -gt 0) {
                        [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 1000; $DongHoDemGiay += 1
                        $PhanMemHienTai.TrangThai = "Cài ngầm ($([int]$DongHoDemGiay)s)"
                        
                        $NhungKeConSong = @()
                        foreach ($PIDKiemTra in $DanhSachTheoDoi) {
                            if (Get-Process -Id $PIDKiemTra -ErrorAction SilentlyContinue) {
                                $NhungKeConSong += $PIDKiemTra
                            }
                        }
                        $DanhSachTheoDoi = $NhungKeConSong

                        if ($DongHoDemGiay -ge 300) { break } 
                        if ($Global:TrangThaiHeThong -eq "DungLai") {
                            foreach ($PIDXoaBo in $DanhSachTheoDoi) { try { Stop-Process -Id $PIDXoaBo -Force -ErrorAction SilentlyContinue } catch {} }
                            $PhanMemHienTai.TrangThai = "Đã Hủy ⛔"; $PhanMemHienTai.TienTrinh = 0; return
                        }
                    }
                }
            } catch {
                $PhanMemHienTai.TrangThai = "Lỗi khởi chạy ⚠️"; Start-Sleep -Seconds 2
            }
        } else {
            $PhanMemHienTai.TrangThai = "⚠️ Trống/Không có Exe"; Start-Sleep -Seconds 3
        }
        
        $PhanMemHienTai.TrangThai = "Hoàn tất ✔️"; $PhanMemHienTai.TienTrinh = 100
    }
    else {
        $PhanMemHienTai.TrangThai = "🛠️ Đang cài đặt..."; [System.Windows.Forms.Application]::DoEvents()
        
        $LenhThamSoAn = $PhanMemHienTai.ThamSoNgam
        if (-not $LenhThamSoAn) { 
            if ($PhanMemHienTai.Ten -match "(?i)wps") { $LenhThamSoAn = "/S" }
            elseif ($PhanMemHienTai.Ten -match "(?i)foxit") { $LenhThamSoAn = "/quiet /force /lang en" }
            else { $LenhThamSoAn = "/S" }
        }

        try {
            $ThuMucChuaFile = Split-Path $DuongDanFileTrenMay
            $DanhSachPIDTruoc = Get-Process -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id

            if ($DuoiDinhDang -eq ".msi") { 
                $QuaTrinhChayMay = Start-Process "msiexec.exe" -ArgumentList "/i `"$DuongDanFileTrenMay`" /quiet /norestart" -WorkingDirectory $ThuMucChuaFile -PassThru 
            } else { 
                $QuaTrinhChayMay = Start-Process -FilePath $DuongDanFileTrenMay -ArgumentList $LenhThamSoAn -WorkingDirectory $ThuMucChuaFile -PassThru 
            }
            
            if ($QuaTrinhChayMay) {
                $DongHoDemGiay = 0
                $DanhSachTheoDoi = @($QuaTrinhChayMay.Id)
                
                Start-Sleep -Milliseconds 2500
                $DongHoDemGiay += 2.5
                
                $TienTrinhMoi = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $DanhSachPIDTruoc }
                foreach ($TienTrinh in $TienTrinhMoi) {
                    try { if ($TienTrinh.Name -match "(?i)setup|install|wps") { $DanhSachTheoDoi += $TienTrinh.Id } } catch {}
                }
                $DanhSachTheoDoi = $DanhSachTheoDoi | Select-Object -Unique

                while ($DanhSachTheoDoi.Count -gt 0) {
                    [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 1000; $DongHoDemGiay += 1
                    $PhanMemHienTai.TrangThai = "Cài ngầm ($([int]$DongHoDemGiay)s)"
                    
                    $NhungKeConSong = @()
                    foreach ($PIDKiemTra in $DanhSachTheoDoi) {
                        if (Get-Process -Id $PIDKiemTra -ErrorAction SilentlyContinue) { $NhungKeConSong += $PIDKiemTra }
                    }
                    $DanhSachTheoDoi = $NhungKeConSong

                    if ($DongHoDemGiay -ge 300) { break }
                    if ($Global:TrangThaiHeThong -eq "DungLai") {
                        foreach ($PIDXoaBo in $DanhSachTheoDoi) { try { Stop-Process -Id $PIDXoaBo -Force -ErrorAction SilentlyContinue } catch {} }
                        $PhanMemHienTai.TrangThai = "Đã Hủy ⛔"; $PhanMemHienTai.TienTrinh = 0; return
                    }
                }
            }
        } catch { }
        
        if ($Global:TrangThaiHeThong -eq "DungLai") { return }
        $PhanMemHienTai.TrangThai = "Hoàn tất ✔️"; $PhanMemHienTai.TienTrinh = 100
    }
}

# ------------------------------------------------------------------------------
# 7. VÒNG LẶP CHÍNH & KIỂM SOÁT DỌN RÁC
# ------------------------------------------------------------------------------
$DieuKhienKichHoat.Add_Click({
    $Global:TrangThaiHeThong = "DangChay"; CapNhat-TrangThaiNutBam "DangChay"
    
    $DieuKhienKichHoat.Content = "🧹 DỌN RÁC LẦN TRƯỚC..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        if (Test-Path $Global:ThuMucLuuTru) { Get-ChildItem -Path $Global:ThuMucLuuTru -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
        if (Test-Path "C:\VietToolbox_Temp") { Remove-Item -Path "C:\VietToolbox_Temp" -Recurse -Force -ErrorAction SilentlyContinue }
    } catch {}
    Start-Sleep -Milliseconds 500

    $DieuKhienKichHoat.Content = "⏳ HỆ THỐNG ĐANG XỬ LÝ..."
    
    foreach ($PhanMemTruyXuat in $BangDanhSach) { 
        if ($PhanMemTruyXuat.Chon -and $Global:TrangThaiHeThong -ne "DungLai") { TienHanh-CaiDatToanDien $PhanMemTruyXuat } 
    }

    if ($Global:TrangThaiHeThong -ne "DungLai") {
        $DieuKhienKichHoat.Content = "▶ HOÀN THÀNH - CHẠY LẠI?"
    } else {
        $DieuKhienKichHoat.Content = "▶ ĐÃ HỦY - CHẠY LẠI?"
    }

    $Global:TrangThaiHeThong = "NhanhRoi"; CapNhat-TrangThaiNutBam "NhanhRoi"
})

# ------------------------------------------------------------------------------
# 8. LẤY DỮ LIỆU TỪ MẠNG (FILE CSV) VÀ KHỞI ĐỘNG GIAO DIỆN
# ------------------------------------------------------------------------------
try {
    $DuLieuCsvTho = (Invoke-RestMethod $Global:LienKetDuLieuGoc -UseBasicParsing) | ConvertFrom-Csv
    foreach ($DongDuLieu in $DuLieuCsvTho) { 
        if ($DongDuLieu.DownloadUrl) {
            $HinhAnhDaiDien = $DongDuLieu.IconURL
            if (-not $HinhAnhDaiDien) { $HinhAnhDaiDien = "https://cdn-icons-png.flaticon.com/512/2589/2589174.png" }
            
            $TenNhomPhanLoai = "Phần mềm chung"
            if ($DongDuLieu.catologi) { $TenNhomPhanLoai = $DongDuLieu.catologi } 
            elseif ($DongDuLieu.Category) { $TenNhomPhanLoai = $DongDuLieu.Category } 
            elseif ($DongDuLieu.DanhMuc) { $TenNhomPhanLoai = $DongDuLieu.DanhMuc }

            $BangDanhSach.Add([KieuDuLieuPhanMem]@{
                Chon = ($DongDuLieu.Check -match "True"); 
                Ten = $DongDuLieu.Name; 
                BieuTuong = $HinhAnhDaiDien; 
                DuongDanTai = $DongDuLieu.DownloadUrl; 
                ThamSoNgam = $DongDuLieu.SilentArgs; 
                TrangThai = "Sẵn sàng"; 
                TienTrinh = 0; 
                DanhMuc = $TenNhomPhanLoai
            }) 
        } 
    }
} catch { [System.Windows.Forms.MessageBox]::Show("Không thể tải danh sách phần mềm từ mạng!", "Lỗi Kết Nối", 0, 16) }

try { $CuaSoChinh.ShowDialog() | Out-Null } catch {}