# ==============================================================================
# BỘ TẢI VÀ CÀI ĐẶT PHẦN MỀM TỰ ĐỘNG (AUTO-INSTALLER V129)
# Đặc tính: Fix lỗi Shortcut dư thừa, Lọc file EXE chính xác bằng "Cân Ký".
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$MaLopDuLieu = @"
using System;
using System.ComponentModel;
public class PhanMem : INotifyPropertyChanged {
    public event PropertyChangedEventHandler PropertyChanged;
    private void ThongBao(string thuocTinh) { if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs(thuocTinh)); }

    private bool _chon; public bool Chon { get{return _chon;} set{_chon=value;ThongBao("Chon");} }
    private string _ten; public string Ten { get{return _ten;} set{_ten=value;ThongBao("Ten");} }
    private string _icon; public string IconURL { get{return _icon;} set{_icon=value;ThongBao("IconURL");} }
    private string _url; public string Url { get{return _url;} set{_url=value;ThongBao("Url");} }
    private string _args; public string Args { get{return _args;} set{_args=value;ThongBao("Args");} }
    private string _trangThai; public string TrangThai { get{return _trangThai;} set{_trangThai=value;ThongBao("TrangThai");} }
    private int _tienTrinh; public int TienTrinh { get{return _tienTrinh;} set{_tienTrinh=value;ThongBao("TienTrinh");} }
}
"@
Add-Type -TypeDefinition $MaLopDuLieu -Language CSharp

$DuongDanCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$ThuMucTaiVe = Join-Path $env:PUBLIC "LuuTruPhanMem"
if (-not (Test-Path $ThuMucTaiVe)) { New-Item -ItemType Directory -Path $ThuMucTaiVe | Out-Null }

$TrangThaiHeThong = "NhanhRoi"

function Tao-BieuTuongDesktop {
    param ([string]$TenPhanMem, [string]$DuongDanGoc)
    try {
        $DuongDanDesktop = [Environment]::GetFolderPath("Desktop")
        $TenSach = $TenPhanMem -replace '[\\/:\*\?"<>\|]', ''
        $DuongDanShortcut = Join-Path $DuongDanDesktop "$TenSach.lnk"
        $WshShell = New-Object -ComObject WScript.Shell
        $BieuTuong = $WshShell.CreateShortcut($DuongDanShortcut)
        $BieuTuong.TargetPath = $DuongDanGoc
        $BieuTuong.WorkingDirectory = [System.IO.Path]::GetDirectoryName($DuongDanGoc)
        $BieuTuong.Save()
    } catch { }
}

function Do-LenhSilentChuan {
    param ([string]$DuongDanExe)
    try {
        $LuotDoc = New-Object System.IO.FileStream($DuongDanExe, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $BoNhoDem = New-Object byte[] 1048576 
        $SoByteDoc = $LuotDoc.Read($BoNhoDem, 0, $BoNhoDem.Length)
        $LuotDoc.Close()
        $VanBanLoi = [System.Text.Encoding]::ASCII.GetString($BoNhoDem, 0, $SoByteDoc)

        if ($VanBanLoi -match "Inno Setup") { return "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" }
        if ($VanBanLoi -match "Nullsoft" -or $VanBanLoi -match "NSIS") { return "/S" }
        if ($VanBanLoi -match "InstallShield") { return '/s /v"/qn"' }
        if ($VanBanLoi -match "WiX") { return "/quiet /norestart" }
        if ($VanBanLoi -match "Squirrel") { return "--silent" }
    } catch { }
    return "/silent /quiet /qn" 
}

# --- GIAO DIỆN WPF ---
$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Trình Cài Đặt Tự Động V129" Width="900" Height="650" MinWidth="700" MinHeight="500" WindowStartupLocation="CenterScreen" Background="#F8FAFC" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome><WindowChrome GlassFrameThickness="0" CornerRadius="12" CaptionHeight="40" ResizeBorderThickness="7" /></WindowChrome.WindowChrome>
    <Border Background="#F8FAFC" CornerRadius="12" BorderBrush="#CBD5E1" BorderThickness="1.5">
        <Grid Margin="15">
            <Grid.RowDefinitions><RowDefinition Height="40"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="80"/></Grid.RowDefinitions>
            
            <Grid Name="KhungTieuDe" Grid.Row="0" Background="Transparent">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="🚀 BỘ CÀI ĐẶT ĐÁM MÂY (FIX SHORTCUT)" Foreground="#1E293B" VerticalAlignment="Center" Margin="10,0,0,0" FontWeight="Bold" FontSize="16"/>
                <Button Name="NutThuNho" Grid.Column="1" Content="—" Width="45" Background="Transparent" BorderThickness="0" Cursor="Hand" FontSize="16" Foreground="#64748B"/>
                <Button Name="NutThuPhong" Grid.Column="2" Content="⬜" Width="45" Background="Transparent" BorderThickness="0" Cursor="Hand" FontSize="14" Foreground="#64748B"/>
                <Button Name="NutDong" Grid.Column="3" Content="✕" Width="45" Background="Transparent" BorderThickness="0" Cursor="Hand" FontSize="16" Foreground="#EF4444" FontWeight="Bold"/>
            </Grid>

            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="5,10,0,10">
                <Button Name="NutChonHet" Content="☑ Chọn Tất Cả" Background="#E2E8F0" Foreground="#1E293B" FontWeight="Bold" Padding="12,6" Margin="0,0,10,0" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                </Button>
                <Button Name="NutBoChon" Content="☐ Bỏ Chọn Hết" Background="#E2E8F0" Foreground="#1E293B" FontWeight="Bold" Padding="12,6" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                </Button>
            </StackPanel>

            <DataGrid Name="BangDanhSach" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" SelectionMode="Single" BorderThickness="1" BorderBrush="#E2E8F0" Background="White" RowHeight="50" HeadersVisibility="Column" HorizontalGridLinesBrush="#F1F5F9" VerticalGridLinesBrush="Transparent">
                <DataGrid.Resources>
                    <Style TargetType="DataGridColumnHeader"><Setter Property="Background" Value="#F8FAFC"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Padding" Value="10,8"/><Setter Property="Foreground" Value="#475569"/></Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                    <DataGridCheckBoxColumn Header="Cài" Binding="{Binding Chon, UpdateSourceTrigger=PropertyChanged}" Width="50">
                        <DataGridCheckBoxColumn.ElementStyle><Style TargetType="CheckBox"><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridCheckBoxColumn.ElementStyle>
                    </DataGridCheckBoxColumn>
                    <DataGridTemplateColumn Header="Logo" Width="60">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate><Image Source="{Binding IconURL}" Width="32" Height="32" Stretch="Uniform" VerticalAlignment="Center" HorizontalAlignment="Center"/></DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                    <DataGridTextColumn Header="Tên Phần Mềm" Binding="{Binding Ten}" Width="*" FontWeight="SemiBold" Foreground="#0F172A">
                        <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="10,0,0,0"/></Style></DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTemplateColumn Header="Tiến Độ &amp; Trạng Thái" Width="250">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate>
                                <Grid Margin="10,0">
                                    <ProgressBar Minimum="0" Maximum="100" Value="{Binding TienTrinh}" Height="20" Background="#F1F5F9" Foreground="#10B981" BorderThickness="0"/>
                                    <TextBlock Text="{Binding TrangThai}" VerticalAlignment="Center" HorizontalAlignment="Center" FontSize="11" FontWeight="Bold" Foreground="#1E293B"/>
                                </Grid>
                            </DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                </DataGrid.Columns>
            </DataGrid>

            <Border Grid.Row="3" Background="#1E293B" CornerRadius="10" Margin="0,15,0,0">
                <Grid Margin="15,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="NutBatDau" Grid.Column="0" Content="▶ BẮT ĐẦU" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="15" Margin="5" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutTamDung" Grid.Column="1" Content="⏸ TẠM DỪNG" Background="#F59E0B" Foreground="White" FontWeight="Bold" FontSize="15" Margin="5" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutTiepTuc" Grid.Column="2" Content="⏯ TIẾP TỤC" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="15" Margin="5" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutDungLai" Grid.Column="3" Content="⏹ DỪNG HẲN" Background="#EF4444" Foreground="White" FontWeight="Bold" FontSize="15" Margin="5" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
$DanhSachLuuTru = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$BangDanhSach = $CuaSo.FindName("BangDanhSach"); $BangDanhSach.ItemsSource = $DanhSachLuuTru

$NutBatDau = $CuaSo.FindName("NutBatDau"); $NutTamDung = $CuaSo.FindName("NutTamDung")
$NutTiepTuc = $CuaSo.FindName("NutTiepTuc"); $NutDungLai = $CuaSo.FindName("NutDungLai")

$CuaSo.FindName("KhungTieuDe").Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$CuaSo.FindName("NutDong").Add_Click({ $CuaSo.Close() })
$CuaSo.FindName("NutThuNho").Add_Click({ $CuaSo.WindowState = "Minimized" })
$CuaSo.FindName("NutThuPhong").Add_Click({ 
    if ($CuaSo.WindowState -eq "Normal") { $CuaSo.WindowState = "Maximized" } else { $CuaSo.WindowState = "Normal" }
})

function TaiDuLieuTuBangCSV {
    try {
        $PhanHoi = Invoke-RestMethod -Uri $DuongDanCsv -UseBasicParsing
        $DuLieu = $PhanHoi | ConvertFrom-Csv
        foreach ($Dong in $DuLieu) {
            if (-not [string]::IsNullOrWhiteSpace($Dong.DownloadUrl)) {
                $DanhSachLuuTru.Add([PhanMem]@{
                    Chon = ($Dong.Check -match "True")
                    Ten = $Dong.Name
                    IconURL = $Dong.IconURL
                    Url = $Dong.DownloadUrl
                    Args = $Dong.SilentArgs
                    TrangThai = "Sẵn sàng"
                    TienTrinh = 0
                })
            }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi mạng! Không thể tải danh sách.", "Lỗi hệ thống") }
}

$CuaSo.FindName("NutChonHet").Add_Click({ foreach ($PhanMem in $DanhSachLuuTru) { $PhanMem.Chon = $true } })
$CuaSo.FindName("NutBoChon").Add_Click({ foreach ($PhanMem in $DanhSachLuuTru) { $PhanMem.Chon = $false } })

function TaiVaCaiDatPhanMem ($DoiTuong) {
    $DoiTuong.TrangThai = "Đang kết nối..."
    [System.Windows.Forms.Application]::DoEvents()

    $TenFile = [System.IO.Path]::GetFileName($DoiTuong.Url.Split('?')[0])
    if (-not $TenFile -or $TenFile -notmatch '\.(exe|msi|zip)$') { $TenFile = "$($DoiTuong.Ten -replace '[\\/:\*\?"<>\|]', '').exe" }
    $DuongDanLuu = Join-Path $ThuMucTaiVe $TenFile

    try {
        $YeuCau = [System.Net.WebRequest]::Create($DoiTuong.Url)
        $YeuCau.Method = "GET"
        $YeuCau.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        $PhanHoiTuMayChu = $YeuCau.GetResponse()
        $KenhDocDuLieu = $PhanHoiTuMayChu.GetResponseStream()
        $FileLuuTrenMay = New-Object System.IO.FileStream($DuongDanLuu, [System.IO.FileMode]::Create)
        
        $BoNhoTam = New-Object byte[] 16384
        $TongDungLuong = $PhanHoiTuMayChu.ContentLength
        $DaTaiVe = 0

        do {
            if ($Global:TrangThaiHeThong -eq "DungLai") { break }
            while ($Global:TrangThaiHeThong -eq "TamDung") {
                $DoiTuong.TrangThai = "Đã tạm dừng..."
                [System.Threading.Thread]::Sleep(500)
                [System.Windows.Forms.Application]::DoEvents()
            }
            if ($Global:TrangThaiHeThong -eq "DungLai") { break }

            $SoByteDocDuoc = $KenhDocDuLieu.Read($BoNhoTam, 0, $BoNhoTam.Length)
            if ($SoByteDocDuoc -gt 0) {
                $FileLuuTrenMay.Write($BoNhoTam, 0, $SoByteDocDuoc)
                $DaTaiVe += $SoByteDocDuoc
                if ($TongDungLuong -gt 0) {
                    $DoiTuong.TienTrinh = [math]::Round(($DaTaiVe / $TongDungLuong) * 100)
                    $DoiTuong.TrangThai = "Đang tải: $($DoiTuong.TienTrinh)%"
                }
                [System.Windows.Forms.Application]::DoEvents()
            }
        } while ($SoByteDocDuoc -gt 0)

        $FileLuuTrenMay.Close(); $KenhDocDuLieu.Close(); $PhanHoiTuMayChu.Close()

        if ($Global:TrangThaiHeThong -eq "DungLai") {
            $DoiTuong.TrangThai = "Bị hủy bỏ"; $DoiTuong.TienTrinh = 0
            Remove-Item $DuongDanLuu -ErrorAction SilentlyContinue
            return
        }

        # --- GIAI ĐOẠN 2: CÀI ĐẶT ---
        $DoiTuong.TrangThai = "Đang cài đặt..."
        $DoiTuong.TienTrinh = 100
        [System.Windows.Forms.Application]::DoEvents()

        $ThamSoCaiDat = ""
        if (-not [string]::IsNullOrWhiteSpace($DoiTuong.Args)) {
            $ThamSoCaiDat = $DoiTuong.Args
        } elseif ($TenFile -match '(?i)\.exe$') {
            $ThamSoCaiDat = Do-LenhSilentChuan -DuongDanExe $DuongDanLuu
        } else {
            $ThamSoCaiDat = "/silent"
        }

        $TuKhoaTimKiem = $DoiTuong.Ten.Split(' ')[0]
        $DuongDanDesktop = [Environment]::GetFolderPath("Desktop")

        if ($TenFile -match '(?i)\.zip$') {
            $DoiTuong.TrangThai = "Đang bung nén..."
            $TenSach = $DoiTuong.Ten -replace '[\\/:\*\?"<>\|]', ''
            $ThuMucGiaiNen = Join-Path "C:\" $TenSach
            Expand-Archive -Path $DuongDanLuu -DestinationPath $ThuMucGiaiNen -Force -ErrorAction SilentlyContinue
            
            # CÂN KÝ FILE ZIP: Lấy file EXE lớn nhất
            $FileChayZip = Get-ChildItem -Path $ThuMucGiaiNen -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 1
            if ($FileChayZip) {
                Tao-BieuTuongDesktop -TenPhanMem $DoiTuong.Ten -DuongDanGoc $FileChayZip.FullName
            }
        } 
        else {
            if ($TenFile -match '(?i)\.msi$') {
                if ($ThamSoCaiDat -notmatch '(?i)/i') { $ThamSoCaiDat = "/i `"$DuongDanLuu`" /quiet /norestart" }
                Start-Process "msiexec.exe" -ArgumentList $ThamSoCaiDat -Wait -NoNewWindow
            } else {
                Start-Process $DuongDanLuu -ArgumentList $ThamSoCaiDat -Wait -NoNewWindow
            }

            # --- SĂN SHORTCUT DESKTOP ĐÃ NÂNG CẤP ---
            $DoiTuong.TrangThai = "Đang tạo Shortcut..."
            
            # 1. NHÌN TRƯỚC NGÓ SAU: Xem bộ cài có đẻ Shortcut chưa
            $ShortcutDaCo = Get-ChildItem -Path $DuongDanDesktop -Filter "*.lnk" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "(?i)$TuKhoaTimKiem" }
            
            if (-not $ShortcutDaCo) {
                # 2. CHƯA CÓ THÌ BẮT ĐẦU SĂN
                $CacKhuVucSan = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs", "$env:LOCALAPPDATA")
                $FileSanDuoc = $null
                
                foreach ($KhuVuc in $CacKhuVucSan) {
                    $ThuMucNghiVan = Get-ChildItem -Path $KhuVuc -Directory -Filter "*$TuKhoaTimKiem*" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($ThuMucNghiVan) {
                        # 3. LỌC TỪ KHÓA RÁC VÀ CÂN KÝ (LẤY FILE NẶNG NHẤT)
                        $FileSanDuoc = Get-ChildItem -Path $ThuMucNghiVan.FullName -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | 
                                       Where-Object { $_.Name -notmatch "(?i)uninstall|setup|unins|update|crash|agent|helper|service|sender|broker|elevate|pingsender" } | 
                                       Sort-Object Length -Descending | Select-Object -First 1
                        if ($FileSanDuoc) { break }
                    }
                }
                if ($FileSanDuoc) { 
                    Tao-BieuTuongDesktop -TenPhanMem $DoiTuong.Ten -DuongDanGoc $FileSanDuoc.FullName 
                }
            }
        }

        $DoiTuong.TrangThai = "Hoàn tất ✔️"
        
    } catch {
        $DoiTuong.TrangThai = "Lỗi cài đặt"
        if ($FileLuuTrenMay) { $FileLuuTrenMay.Close() }
        if ($KenhDocDuLieu) { $KenhDocDuLieu.Close() }
    }
}

$NutBatDau.Add_Click({
    $Global:TrangThaiHeThong = "DangChay"
    $NutBatDau.IsEnabled = $false; $NutTamDung.IsEnabled = $true; $NutDungLai.IsEnabled = $true; $NutTiepTuc.IsEnabled = $false

    foreach ($PhanMem in $DanhSachLuuTru) {
        if ($PhanMem.Chon -and $Global:TrangThaiHeThong -ne "DungLai") { TaiVaCaiDatPhanMem $PhanMem }
    }

    if ($Global:TrangThaiHeThong -ne "DungLai") { [System.Windows.Forms.MessageBox]::Show("Toàn bộ tiến trình đã hoàn tất tuyệt đối!", "Hoàn thành", 0, 64) }
    $Global:TrangThaiHeThong = "NhanhRoi"
    $NutBatDau.IsEnabled = $true; $NutTamDung.IsEnabled = $false; $NutDungLai.IsEnabled = $false; $NutTiepTuc.IsEnabled = $false
})

$NutTamDung.Add_Click({ $Global:TrangThaiHeThong = "TamDung"; $NutTamDung.IsEnabled = $false; $NutTiepTuc.IsEnabled = $true })
$NutTiepTuc.Add_Click({ $Global:TrangThaiHeThong = "DangChay"; $NutTamDung.IsEnabled = $true; $NutTiepTuc.IsEnabled = $false })
$NutDungLai.Add_Click({ $Global:TrangThaiHeThong = "DungLai"; $NutBatDau.IsEnabled = $true; $NutTamDung.IsEnabled = $false; $NutTiepTuc.IsEnabled = $false; $NutDungLai.IsEnabled = $false })

TaiDuLieuTuBangCSV
$CuaSo.ShowDialog() | Out-Null