# ==============================================================================
# BỘ CÔNG CỤ TỰ ĐỘNG CÀI ĐẶT VIETTOOLBOX V706 - BẮT ĐÚNG ĐỊNH DẠNG
# Fix: Khôi phục chức năng tự động nhận diện đuôi file (zip, msi, rar) cho Direct Link.
# ==============================================================================

# ------------------------------------------------------------------------------
# MODULE 1: THIẾT LẬP MÔI TRƯỜNG & TOÀN CỤC
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

$Global:LienKetDuLieuGoc = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$Global:ThuMucLuuTru = Join-Path $env:PUBLIC "LuuTruPhanMemViet"
$Global:TrangThaiBoNho = [hashtable]::Synchronized(@{ TrangThai = "NhanhRoi" })

if (-not (Test-Path $Global:ThuMucLuuTru)) { New-Item -ItemType Directory -Path $Global:ThuMucLuuTru -Force | Out-Null }

function GiaiMa-ChuaKhoa ($ChuoiMaHoa) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ChuoiMaHoa)) }
$Global:DanhSachKhoaAPI = @(
    (GiaiMa-ChuaKhoa "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"),
    (GiaiMa-ChuaKhoa "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v")
)

# ------------------------------------------------------------------------------
# MODULE 2: CÁC HÀM TIỆN ÍCH
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

function KiemTra-LoiFileNen ($DuongDanKiemTra) {
    try {
        $DongDocNhiPhan = [System.IO.File]::OpenRead($DuongDanKiemTra)
        $MaLoi = New-Object byte[] 4
        $DongDocNhiPhan.Read($MaLoi, 0, 4) | Out-Null
        $DongDocNhiPhan.Close()
        $ChuoiHexa = [System.BitConverter]::ToString($MaLoi)
        if ($ChuoiHexa -match "50-4B-03-04" -or $ChuoiHexa -match "52-61-72-21" -or $ChuoiHexa -match "37-7A-BC-AF") { return $true }
    } catch {}
    return $false
}

function TuDong-NhanDienThamSoEXE ($TenPhanMem, $ThamSoTuCSV) {
    if (-not [string]::IsNullOrWhiteSpace($ThamSoTuCSV)) { return $ThamSoTuCSV }
    $ThuVienThamSo = [ordered]@{
        "(?i)wps" = "/S /ACCEPTEULA=1 AutoRun=0"
        "(?i)foxit" = "/quiet /force /lang en"
        "(?i)chrome|coccoc|brave|edge" = "--silent --do-not-launch-chrome"
        "(?i)zalo" = "/S"
        "(?i)winrar" = "/S"
        "(?i)7-?zip" = "/S"
        "(?i)vlc" = "/L=1033 /S"
        "(?i)k-?lite" = "/verysilent /norestart"
        "(?i)anydesk" = "--install `"$env:ProgramFiles\AnyDesk`" --start-with-win --silent"
        "(?i)teamviewer" = "/S"
        "(?i)ultraviewer" = "/silent"
        "(?i)unikey|evkey" = "/S"
        "(?i)java|jre|jdk" = "/s"
        "(?i)adobe.*reader" = "/sAll /rs /msi EULA_ACCEPT=YES"
        "(?i)zoom" = "/silent"
    }
    foreach ($MauNhanDien in $ThuVienThamSo.Keys) {
        if ($TenPhanMem -match $MauNhanDien) { return $ThuVienThamSo[$MauNhanDien] }
    }
    return "/S"
}

function Chay-TienTrinhChuan ($DuongDanFile, $ThamSo, $ThuMucLamViec) {
    try {
        $ThongTinChay = New-Object System.Diagnostics.ProcessStartInfo
        $ThongTinChay.FileName = $DuongDanFile
        $ThongTinChay.Arguments = $ThamSo
        $ThongTinChay.WorkingDirectory = $ThuMucLamViec
        $ThongTinChay.UseShellExecute = $true
        return [System.Diagnostics.Process]::Start($ThongTinChay)
    } catch { return $null }
}

# ------------------------------------------------------------------------------
# MODULE 3: GIAO DIỆN (DASHBOARD XAML)
# ------------------------------------------------------------------------------
$MaNguonGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Dashboard" Width="1100" Height="750" MinWidth="900" MinHeight="600" WindowStartupLocation="CenterScreen" 
        Background="Transparent" AllowsTransparency="True" WindowStyle="None" FontFamily="Segoe UI">
    <Border CornerRadius="12" Background="#F8FAFC" ClipToBounds="True">
        <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="280"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border Grid.Column="0" Background="#0F172A">
                <Grid>
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <StackPanel Grid.Row="0" Margin="20,40,20,30">
                        <TextBlock Text="🚀" FontSize="45" HorizontalAlignment="Center" Margin="0,0,0,15"/>
                        <TextBlock Text="VIETTOOLBOX" Foreground="White" FontSize="24" FontWeight="Black" HorizontalAlignment="Center"/>
                        <TextBlock Text="Auto Deploy Dashboard" Foreground="#94A3B8" FontSize="13" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                        <Rectangle Height="1" Fill="#1E293B" Margin="0,30,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Row="1" Margin="20,0,20,0" VerticalAlignment="Top">
                        <Button Name="NutKichHoat" Content="▶ BẮT ĐẦU CÀI ĐẶT" Height="55" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="15" Margin="0,0,0,15" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                        <Button Name="NutHuyViec" Content="⏹ HỦY TIẾN TRÌNH" Height="48" Background="#EF4444" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,0,0,12" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    </StackPanel>
                    <TextBlock Grid.Row="2" Text="Phiên bản V706 - Bắt Đúng Định Dạng" Foreground="#475569" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,20"/>
                </Grid>
            </Border>
            <Grid Grid.Column="1">
                <Grid.RowDefinitions><RowDefinition Height="65"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <Border Grid.Row="0" Background="#FFFFFF" BorderBrush="#E2E8F0" BorderThickness="0,0,0,1" Name="KhungTieuDe">
                    <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0" Orientation="Horizontal" Margin="25,0,0,0" VerticalAlignment="Center">
                            <Button Name="NutChonToanBo" Content="☑ Chọn tất cả" Width="110" Height="36" Margin="0,0,12,0" Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" Foreground="#334155" FontWeight="SemiBold" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                            <Button Name="NutHuyChon" Content="☐ Bỏ chọn" Width="110" Height="36" Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" Foreground="#334155" FontWeight="SemiBold" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                        </StackPanel>
                        <StackPanel Grid.Column="2" Orientation="Horizontal" Margin="0,0,15,0" HorizontalAlignment="Right" VerticalAlignment="Center">
                            <Button Name="NutThuNho" Content="—" Width="40" Height="40" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#64748B" Cursor="Hand"/>
                            <Button Name="NutThoat" Content="✕" Width="40" Height="40" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#EF4444" FontWeight="Bold" Cursor="Hand"/>
                        </StackPanel>
                    </Grid>
                </Border>
                <ScrollViewer Grid.Row="1" Margin="20,15,10,20" VerticalScrollBarVisibility="Auto">
                    <ItemsControl Name="BangHienThiDuLieu">
                        <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel Orientation="Horizontal" /></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                        <ItemsControl.GroupStyle><GroupStyle><GroupStyle.HeaderTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="Black" FontSize="18" Foreground="#0F172A" Margin="5,20,10,15"/></DataTemplate></GroupStyle.HeaderTemplate></GroupStyle></ItemsControl.GroupStyle>
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <Border Width="240" Height="95" Margin="5,5,15,15" Background="#FFFFFF" BorderBrush="#E2E8F0" BorderThickness="1.5" CornerRadius="10">
                                    <Grid Margin="12,10">
                                        <Grid.ColumnDefinitions><ColumnDefinition Width="30"/><ColumnDefinition Width="45"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                        <CheckBox IsChecked="{Binding Chon, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Grid.Column="0"><CheckBox.LayoutTransform><ScaleTransform ScaleX="1.3" ScaleY="1.3"/></CheckBox.LayoutTransform></CheckBox>
                                        <Image Source="{Binding BieuTuong}" Width="36" Height="36" VerticalAlignment="Center" HorizontalAlignment="Center" Grid.Column="1"/>
                                        <StackPanel Grid.Column="2" VerticalAlignment="Center" Margin="5,0,0,0">
                                            <TextBlock Text="{Binding Ten}" FontWeight="Bold" FontSize="13" Foreground="#1E293B" TextTrimming="CharacterEllipsis" Margin="0,0,0,6"/>
                                            <ProgressBar Value="{Binding TienTrinh}" Height="8" Foreground="#10B981" Background="#F1F5F9" BorderThickness="0"><ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></ProgressBar.Resources></ProgressBar>
                                            <TextBlock Text="{Binding TrangThai}" FontSize="11" Foreground="#64748B" FontWeight="SemiBold" Margin="0,4,0,0" TextTrimming="CharacterEllipsis"/>
                                        </StackPanel>
                                    </Grid>
                                </Border>
                            </DataTemplate>
                        </ItemsControl.ItemTemplate>
                    </ItemsControl>
                </ScrollViewer>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$CuaSoChinh = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaNguonGiaoDien))
$BangDanhSach = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$BoLocGocNhin = [System.Windows.Data.CollectionViewSource]::GetDefaultView($BangDanhSach)
$BoLocGocNhin.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription("DanhMuc")))
$CuaSoChinh.FindName("BangHienThiDuLieu").ItemsSource = $BoLocGocNhin
$Dispatcher = $CuaSoChinh.Dispatcher

# ------------------------------------------------------------------------------
# MODULE 4: SỰ KIỆN GIAO DIỆN
# ------------------------------------------------------------------------------
$CuaSoChinh.FindName("KhungTieuDe").Add_MouseLeftButtonDown({ $CuaSoChinh.DragMove() })
$CuaSoChinh.FindName("NutThoat").Add_Click({ $Global:TrangThaiBoNho.TrangThai = "DungLai"; $CuaSoChinh.Close() })
$CuaSoChinh.FindName("NutThuNho").Add_Click({ $CuaSoChinh.WindowState = "Minimized" })
$CuaSoChinh.FindName("NutChonToanBo").Add_Click({ foreach ($Muc in $BangDanhSach) {$Muc.Chon=$true} })
$CuaSoChinh.FindName("NutHuyChon").Add_Click({ foreach ($Muc in $BangDanhSach) {$Muc.Chon=$false} })

$DieuKhienKichHoat = $CuaSoChinh.FindName("NutKichHoat")
$DieuKhienHuyViec = $CuaSoChinh.FindName("NutHuyViec")

function CapNhat-TrangThaiNutBam ($TrangThaiMoi) {
    if ($TrangThaiMoi -eq "DangChay") { $DieuKhienKichHoat.IsEnabled=$false; $DieuKhienHuyViec.IsEnabled=$true }
    elseif ($TrangThaiMoi -eq "NhanhRoi") { $DieuKhienKichHoat.IsEnabled=$true; $DieuKhienHuyViec.IsEnabled=$false }
}

$DieuKhienHuyViec.Add_Click({ $Global:TrangThaiBoNho.TrangThai = "DungLai"; CapNhat-TrangThaiNutBam "NhanhRoi" })

# ------------------------------------------------------------------------------
# MODULE 5: ĐỘNG CƠ CÀI ĐẶT (XỬ LÝ LUỒNG NGẦM)
# ------------------------------------------------------------------------------
$DieuKhienKichHoat.Add_Click({
    $Global:TrangThaiBoNho.TrangThai = "DangChay"; CapNhat-TrangThaiNutBam "DangChay"
    $CuaSoChinh.Dispatcher.Invoke([action]{ $DieuKhienKichHoat.Content = "🧹 DỌN RÁC LẦN TRƯỚC..." })
    try {
        if (Test-Path $Global:ThuMucLuuTru) { Get-ChildItem -Path $Global:ThuMucLuuTru -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
        if (Test-Path "C:\VietToolbox_Temp") { Remove-Item -Path "C:\VietToolbox_Temp" -Recurse -Force -ErrorAction SilentlyContinue }
    } catch {}

    $CuaSoChinh.Dispatcher.Invoke([action]{ $DieuKhienKichHoat.Content = "⏳ HỆ THỐNG ĐANG XỬ LÝ..." })

    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $Runspace.Open()

    $Runspace.SessionStateProxy.SetVariable("BangDanhSach", $BangDanhSach)
    $Runspace.SessionStateProxy.SetVariable("ThuMucLuuTru", $Global:ThuMucLuuTru)
    $Runspace.SessionStateProxy.SetVariable("DanhSachKhoaAPI", $Global:DanhSachKhoaAPI)
    $Runspace.SessionStateProxy.SetVariable("TrangThaiBoNho", $Global:TrangThaiBoNho)
    $Runspace.SessionStateProxy.SetVariable("Dispatcher", $Dispatcher)
    
    $Runspace.SessionStateProxy.SetVariable("F_KiemTra", ${Function:KiemTra-LoiFileNen})
    $Runspace.SessionStateProxy.SetVariable("F_TuDong", ${Function:TuDong-NhanDienThamSoEXE})
    $Runspace.SessionStateProxy.SetVariable("F_Chay", ${Function:Chay-TienTrinhChuan})

    $PowerShell = [powershell]::Create()
    $PowerShell.Runspace = $Runspace
    
    [void]$PowerShell.AddScript({
        Set-Item "Function:KiemTra-LoiFileNen" $F_KiemTra
        Set-Item "Function:TuDong-NhanDienThamSoEXE" $F_TuDong
        Set-Item "Function:Chay-TienTrinhChuan" $F_Chay

        function CapNhat-PhanMemUI ($PhanMem, $TrangThaiMoi, $TienTrinhMoi) {
            $Dispatcher.Invoke([action]{
                if ($TrangThaiMoi -ne $null) { $PhanMem.TrangThai = $TrangThaiMoi }
                if ($TienTrinhMoi -ne $null) { $PhanMem.TienTrinh = $TienTrinhMoi }
            })
        }

        function TienHanh-CaiDatToanDien ($PhanMemHienTai) {
            CapNhat-PhanMemUI $PhanMemHienTai "Đang phân tích..." 5
            
            $MaLuuTruDrive = ""; if ($PhanMemHienTai.DuongDanTai -match "id=([^&]+)") {$MaLuuTruDrive=$Matches[1]} elseif ($PhanMemHienTai.DuongDanTai -match "/d/([^/]+)") {$MaLuuTruDrive=$Matches[1]}
            $DuoiDinhDang = ".exe"; $TenFileLuuTam = $PhanMemHienTai.Ten -replace '[\\/:\*\?"<>\|]', ''
            $DuongDanFileTrenMay = Join-Path $ThuMucLuuTru "$TenFileLuuTam$DuoiDinhDang"; $DaTaiThanhCong = $false
            
            # --- TẢI XUỐNG ---
            if ($MaLuuTruDrive) {
                foreach ($KhoaTruyCap in $DanhSachKhoaAPI) {
                    try {
                        CapNhat-PhanMemUI $PhanMemHienTai "Quét Drive..." $null
                        $UrlKiemTra = "https://www.googleapis.com/drive/v3/files/$($MaLuuTruDrive)?fields=name&key=$KhoaTruyCap"
                        $GoiKiemTra = [System.Net.HttpWebRequest]::Create($UrlKiemTra); $PhanHoiKiemTra = $GoiKiemTra.GetResponse()
                        $DongDuLieuChu = New-Object System.IO.StreamReader($PhanHoiKiemTra.GetResponseStream()); $NoiDungJson = $DongDuLieuChu.ReadToEnd(); $PhanHoiKiemTra.Close()

                        if ($NoiDungJson -match '"name"\s*:\s*"([^"]+)"') {
                            $TenFileGoc = $Matches[1]; $DuoiMoRongGoc = [System.IO.Path]::GetExtension($TenFileGoc)
                            if ($DuoiMoRongGoc -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle|appx)") { 
                                $DuoiDinhDang = $DuoiMoRongGoc; $DuongDanFileTrenMay = Join-Path $ThuMucLuuTru $TenFileGoc 
                            }
                        }

                        $UrlTaiChinhThuc = "https://www.googleapis.com/drive/v3/files/$($MaLuuTruDrive)?alt=media&key=$KhoaTruyCap"
                        $GoiTaiVe = [System.Net.HttpWebRequest]::Create($UrlTaiChinhThuc); $PhanHoiTaiVe = $GoiTaiVe.GetResponse()
                        if ($PhanHoiTaiVe.ContentLength -lt 1MB) { $PhanHoiTaiVe.Close(); continue }

                        $DongDuLieuNhiPhan = $PhanHoiTaiVe.GetResponseStream(); $FileDuLieuGhi = New-Object System.IO.FileStream($DuongDanFileTrenMay, [System.IO.FileMode]::Create)
                        $KhoangNhoTam = New-Object byte[] 4MB; $TongKichThuocFile = $PhanHoiTaiVe.ContentLength; $DungLuongDaTai = 0
                        
                        $PhanTramCu = -1
                        do {
                            if ($TrangThaiBoNho.TrangThai -eq "DungLai") { break }
                            $SoByteDocDuoc = $DongDuLieuNhiPhan.Read($KhoangNhoTam, 0, $KhoangNhoTam.Length)
                            if ($SoByteDocDuoc -gt 0) {
                                $FileDuLieuGhi.Write($KhoangNhoTam, 0, $SoByteDocDuoc); $DungLuongDaTai += $SoByteDocDuoc
                                if ($TongKichThuocFile -gt 0) { 
                                    $PhanTram = [math]::Round(($DungLuongDaTai/$TongKichThuocFile)*100)
                                    if ($PhanTram -ne $PhanTramCu) {
                                        CapNhat-PhanMemUI $PhanMemHienTai "Đang tải: $PhanTram%" $PhanTram
                                        $PhanTramCu = $PhanTram
                                    }
                                }
                            }
                        } while ($SoByteDocDuoc -gt 0)
                        $FileDuLieuGhi.Close(); $DongDuLieuNhiPhan.Close(); $PhanHoiTaiVe.Close()
                        if ($TrangThaiBoNho.TrangThai -eq "DungLai") { return }
                        $DaTaiThanhCong = $true; break 
                    } catch { if ($FileDuLieuGhi) {$FileDuLieuGhi.Close()} }
                }
            } else {
                try {
                    $GoiTaiVe = [System.Net.HttpWebRequest]::Create($PhanMemHienTai.DuongDanTai)
                    $PhanHoiTaiVe = $GoiTaiVe.GetResponse()

                    # KHÔI PHỤC: LẤY ĐÚNG ĐUÔI FILE TỪ HEADER HOẶC URL CHO DIRECT LINK
                    $KhaiBaoHeader = $PhanHoiTaiVe.Headers["Content-Disposition"]
                    if ($KhaiBaoHeader -match 'filename="?([^";]+)"?') {
                        $TenFileGoc = [System.Net.WebUtility]::UrlDecode($Matches[1])
                        $DuoiMoRongGoc = [System.IO.Path]::GetExtension($TenFileGoc)
                        if ($DuoiMoRongGoc -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle)") {
                            $DuoiDinhDang = $DuoiMoRongGoc
                            $DuongDanFileTrenMay = Join-Path $ThuMucLuuTru $TenFileGoc
                        }
                    } else {
                        $DuoiTuUrl = [System.IO.Path]::GetExtension($PhanMemHienTai.DuongDanTai.Split('?')[0])
                        if ($DuoiTuUrl -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle)") {
                            $DuoiDinhDang = $DuoiTuUrl
                            $DuongDanFileTrenMay = Join-Path $ThuMucLuuTru "$TenFileLuuTam$DuoiDinhDang"
                        }
                    }

                    $DongDuLieuNhiPhan = $PhanHoiTaiVe.GetResponseStream()
                    $FileDuLieuGhi = New-Object System.IO.FileStream($DuongDanFileTrenMay, [System.IO.FileMode]::Create)
                    $KhoangNhoTam = New-Object byte[] 4MB; $TongKichThuocFile = $PhanHoiTaiVe.ContentLength; $DungLuongDaTai = 0
                    
                    $PhanTramCu = -1
                    do {
                        if ($TrangThaiBoNho.TrangThai -eq "DungLai") { break }
                        $SoByteDocDuoc = $DongDuLieuNhiPhan.Read($KhoangNhoTam, 0, $KhoangNhoTam.Length)
                        if ($SoByteDocDuoc -gt 0) {
                            $FileDuLieuGhi.Write($KhoangNhoTam, 0, $SoByteDocDuoc); $DungLuongDaTai += $SoByteDocDuoc
                            if ($TongKichThuocFile -gt 0) { 
                                $PhanTram = [math]::Round(($DungLuongDaTai/$TongKichThuocFile)*100)
                                if ($PhanTram -ne $PhanTramCu) {
                                    CapNhat-PhanMemUI $PhanMemHienTai "Đang tải: $PhanTram%" $PhanTram
                                    $PhanTramCu = $PhanTram
                                }
                            }
                        }
                    } while ($SoByteDocDuoc -gt 0)
                    $FileDuLieuGhi.Close(); $DongDuLieuNhiPhan.Close(); $PhanHoiTaiVe.Close()
                    if ($TrangThaiBoNho.TrangThai -eq "DungLai") { return }
                    $DaTaiThanhCong = $true
                } catch { if ($FileDuLieuGhi) {$FileDuLieuGhi.Close()} }
            }

            if (-not $DaTaiThanhCong) { CapNhat-PhanMemUI $PhanMemHienTai "❌ Lỗi tải" 0; return }

            # --- THỰC THI (RADAR THÔNG MINH) ---
            Unblock-File -Path $DuongDanFileTrenMay; CapNhat-PhanMemUI $PhanMemHienTai "🔍 Phân tích lõi..." 50
            
            $FileThucThiChinh = $DuongDanFileTrenMay
            $ThuMucTempGiaiNen = "C:\VietToolbox_Temp\$($TenFileLuuTam -replace ' ', '')"

            if (KiemTra-LoiFileNen -DuongDanKiemTra $DuongDanFileTrenMay -or $DuoiDinhDang -match "(?i)\.(zip|rar|7z)") {
                CapNhat-PhanMemUI $PhanMemHienTai "📦 Đang xả nén..." $null
                if (-not (Test-Path $ThuMucTempGiaiNen)) { New-Item -ItemType Directory -Path $ThuMucTempGiaiNen -Force | Out-Null }
                $File7z = Join-Path $env:TEMP "7za.exe"; if (-not (Test-Path $File7z)) { Invoke-WebRequest "https://github.com/develar/7zip-bin/raw/master/win/x64/7za.exe" -OutFile $File7z -UseBasicParsing }
                $Process7z = Start-Process -FilePath $File7z -ArgumentList "x `"$DuongDanFileTrenMay`" -pAdmin@2512 -o$ThuMucTempGiaiNen -y" -PassThru -WindowStyle Hidden
                $Process7z.WaitForExit()
                $TatCaExe = Get-ChildItem $ThuMucTempGiaiNen -Filter "*.exe" -Recurse | Sort-Object Length -Descending
                if ($TatCaExe) { $FileThucThiChinh = $TatCaExe[0].FullName }
            }

            $LenhThamSo = TuDong-NhanDienThamSoEXE -TenPhanMem $PhanMemHienTai.Ten -ThamSoTuCSV $PhanMemHienTai.ThamSoNgam
            CapNhat-PhanMemUI $PhanMemHienTai "🛠️ Đang cài đặt..." $null

            try {
                $ThuMucGoc = Split-Path $FileThucThiChinh
                $TienTrinhGoc = Chay-TienTrinhChuan -DuongDanFile $FileThucThiChinh -ThamSo $LenhThamSo -ThuMucLamViec $ThuMucGoc
                
                $DongHoDem = 0
                if ($TienTrinhGoc) {
                    while (-not $TienTrinhGoc.HasExited) {
                        Start-Sleep -Seconds 2; $DongHoDem += 2
                        CapNhat-PhanMemUI $PhanMemHienTai "Cài ngầm ($($DongHoDem)s)..." $null
                        if ($DongHoDem -ge 300 -or $TrangThaiBoNho.TrangThai -eq "DungLai") { break }
                    }

                    $ThoiGianChoPhu = 0
                    while ($true) {
                        Start-Sleep -Seconds 2; $DongHoDem += 2; $ThoiGianChoPhu += 2
                        $TienTrinhConSot = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "(?i)setup|install|msiexec|unins" }
                        
                        if (-not $TienTrinhConSot -or $ThoiGianChoPhu -ge 30 -or $TrangThaiBoNho.TrangThai -eq "DungLai") { break }
                        CapNhat-PhanMemUI $PhanMemHienTai "Hoàn thiện ($($DongHoDem)s)..." $null
                    }
                }
                CapNhat-PhanMemUI $PhanMemHienTai "Hoàn tất ✔️" 100
            } catch { CapNhat-PhanMemUI $PhanMemHienTai "Lỗi cài ⚠️" 0 }
        }
        
        foreach ($PhanMem in $BangDanhSach) { 
            if ($PhanMem.Chon -and $TrangThaiBoNho.TrangThai -ne "DungLai") { 
                TienHanh-CaiDatToanDien $PhanMem 
            } 
        }
    })
    
    $KenhDangChay = $PowerShell.BeginInvoke()
    
    $KiemTraHoanThanh = New-Object System.Windows.Threading.DispatcherTimer
    $KiemTraHoanThanh.Interval = [TimeSpan]::FromMilliseconds(500)
    $KiemTraHoanThanh.Add_Tick({
        if ($KenhDangChay.IsCompleted) {
            $PowerShell.EndInvoke($KenhDangChay)
            $PowerShell.Dispose(); $Runspace.Close(); $Runspace.Dispose()
            $KiemTraHoanThanh.Stop()
            
            $Global:TrangThaiBoNho.TrangThai = "NhanhRoi"; CapNhat-TrangThaiNutBam "NhanhRoi"
            $CuaSoChinh.Dispatcher.Invoke([action]{ $DieuKhienKichHoat.Content = "▶ XONG - CHẠY LẠI?" })
        }
    })
    $KiemTraHoanThanh.Start()
})

# ------------------------------------------------------------------------------
# MODULE 6: LẤY DỮ LIỆU
# ------------------------------------------------------------------------------
try {
    $CSV = (Invoke-RestMethod $Global:LienKetDuLieuGoc -UseBasicParsing) | ConvertFrom-Csv
    foreach ($D in $CSV) { 
        if ($D.DownloadUrl) {
            $Icon = $D.IconURL; if (-not $Icon) { $Icon = "https://cdn-icons-png.flaticon.com/512/2589/2589174.png" }
            $Cat = "Chung"; if ($D.catologi) { $Cat = $D.catologi } elseif ($D.Category) { $Cat = $D.Category }
            $BangDanhSach.Add([KieuDuLieuPhanMem]@{ Chon = ($D.Check -match "True"); Ten = $D.Name; BieuTuong = $Icon; DuongDanTai = $D.DownloadUrl; ThamSoNgam = $D.SilentArgs; TrangThai = "Sẵn sàng"; TienTrinh = 0; DanhMuc = $Cat }) 
        } 
    }
} catch {}
$CuaSoChinh.ShowDialog() | Out-Null