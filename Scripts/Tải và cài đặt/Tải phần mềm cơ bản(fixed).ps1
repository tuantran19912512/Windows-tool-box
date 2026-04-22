# ==============================================================================
# BỘ CÔNG CỤ TỰ ĐỘNG CÀI ĐẶT VIETTOOLBOX V709
# Cải tiến: Nút Reload, Co giãn giao diện tự do, Nhận diện UWP/Portable, Tự xóa file khi xong, Nút tải lại luôn hiện
# ==============================================================================

# ------------------------------------------------------------------------------
# MODULE 1: THIẾT LẬP MÔI TRƯỜNG & TOÀN CỤC
# ------------------------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::DefaultConnectionLimit = 20
$TaiKhoanHienTai = [Security.Principal.WindowsIdentity]::GetCurrent()
$QuyenQuanTri    = [Security.Principal.WindowsPrincipal]$TaiKhoanHienTai
if (-not $QuyenQuanTri.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$Global:LienKetDuLieuGoc = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$Global:ThuMucLuuTru     = Join-Path $env:PUBLIC "LuuTruPhanMemViet"
$Global:TrangThaiBoNho   = [hashtable]::Synchronized(@{ TrangThai = "NhanhRoi" })

if (-not (Test-Path $Global:ThuMucLuuTru)) { New-Item -ItemType Directory -Path $Global:ThuMucLuuTru -Force | Out-Null }

function GiaiMa-ChuaKhoa ($ChuoiMaHoa) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ChuoiMaHoa)) }
$Global:DanhSachKhoaAPI = @(
    (GiaiMa-ChuaKhoa "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"),
    (GiaiMa-ChuaKhoa "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v")
)

# ------------------------------------------------------------------------------
# MODULE 2: KIỂU DỮ LIỆU
# ------------------------------------------------------------------------------
if (-not ("KieuDuLieuPhanMem" -as [type])) {
    Add-Type -Language CSharp @"
    using System; using System.ComponentModel;
    public class KieuDuLieuPhanMem : INotifyPropertyChanged {
        public event PropertyChangedEventHandler PropertyChanged;
        private void N(string p) { if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs(p)); }
        private bool   _chon;   public bool   Chon        { get{return _chon;}   set{_chon=value;N("Chon");}        }
        private string _ten;    public string Ten         { get{return _ten;}    set{_ten=value;N("Ten");}          }
        private string _bieu;   public string BieuTuong   { get{return _bieu;}   set{_bieu=value;N("BieuTuong");}   }
        private string _url;    public string DuongDanTai { get{return _url;}    set{_url=value;N("DuongDanTai");}  }
        private string _ts;     public string ThamSoNgam  { get{return _ts;}     set{_ts=value;N("ThamSoNgam");}    }
        private string _tt;     public string TrangThai   { get{return _tt;}     set{_tt=value;N("TrangThai");}     }
        private int    _tp;     public int    TienTrinh   { get{return _tp;}     set{_tp=value;N("TienTrinh");}     }
        private string _cat;    public string DanhMuc     { get{return _cat;}    set{_cat=value;N("DanhMuc");}      }
        private string _kq;     public string KetQua      { get{return _kq;}     set{_kq=value;N("KetQua");}        }
    }
"@
}

# ------------------------------------------------------------------------------
# MODULE 3: CÁC HÀM TIỆN ÍCH
# ------------------------------------------------------------------------------
function KiemTra-LoiFileNen ($DuongDan) {
    try {
        $f = [System.IO.File]::OpenRead($DuongDan)
        $b = New-Object byte[] 4; $f.Read($b, 0, 4) | Out-Null; $f.Close()
        $h = [System.BitConverter]::ToString($b)
        return ($h -match "50-4B-03-04|52-61-72-21|37-7A-BC-AF")
    } catch { return $false }
}

function TuDong-NhanDienThamSoEXE ($TenPhanMem, $ThamSoTuCSV, $DuongDanFile) {
    if (-not [string]::IsNullOrWhiteSpace($ThamSoTuCSV)) { return $ThamSoTuCSV }

    if ($DuongDanFile -and (Test-Path $DuongDanFile)) {
        try {
            if ($DuongDanFile -match "(?i)\.msi$") { return "/quiet /norestart ALLUSERS=1" }
            $Raw  = [System.IO.File]::ReadAllBytes($DuongDanFile)
            $Gioi = [Math]::Min($Raw.Length, 524288)
            $Uni  = [System.Text.Encoding]::Unicode.GetString($Raw, 0, $Gioi)
            $Ansi = [System.Text.Encoding]::ASCII.GetString($Raw, 0, $Gioi)
            if ($Uni  -match "Inno Setup"      -or $Ansi -match "Inno Setup")      { return "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" }
            if ($Uni  -match "Nullsoft Install" -or $Ansi -match "Nullsoft|NSIS")   { return "/S" }
            if ($Uni  -match "InstallShield"    -or $Ansi -match "InstallShield")   { return "/s /v`"/qn /norestart`"" }
            if ($Uni  -match "WiX Toolset|Windows Installer XML")                    { return "/quiet /norestart" }
            if ($Uni  -match "Advanced Installer")                                   { return "/exenoui /qn /norestart" }
            if ($Uni  -match "Squirrel\.exe|squirrel-")                              { return "--silent" }
            if ($Uni  -match "WISE.*Install|Install.*WISE")                          { return "/s" }
            if ($Uni  -match "Setup Factory")                                        { return "/S" }
            if ($Uni  -match "msiexec|\.msi")                                        { return "/quiet /norestart" }
            if ($Ansi -match "7zS\.sfx|7-Zip")                                       { return "/S" }
        } catch {}
    }

    $ThuVien = [ordered]@{
        "(?i)wps"                                   = "/S /ACCEPTEULA=1 AutoRun=0"
        "(?i)foxit"                                 = "/quiet /force /lang en"
        "(?i)chrome"                                = "--silent --do-not-launch-chrome"
        "(?i)coccoc"                                = "--silent --do-not-launch-chrome"
        "(?i)brave"                                 = "--silent"
        "(?i)firefox"                               = "-ms"
        "(?i)edge(?!.*unin)"                        = "--silent"
        "(?i)opera"                                 = "--silent /install"
        "(?i)zalo"                                  = "/S"
        "(?i)telegram"                              = "/S"
        "(?i)discord"                               = "-s"
        "(?i)slack"                                 = "--silent"
        "(?i)skype"                                 = "/VERYSILENT /SUPPRESSMSGBOXES"
        "(?i)zoom"                                  = "/silent"
        "(?i)teams"                                 = "--silent"
        "(?i)winrar"                                = "/S"
        "(?i)7-?zip"                                = "/S"
        "(?i)bandizip"                              = "/S"
        "(?i)vlc"                                   = "/L=1033 /S"
        "(?i)k-?lite"                               = "/verysilent /norestart"
        "(?i)potplayer"                             = "/S /SUPPRESSMSGBOXES"
        "(?i)obs"                                   = "/S"
        "(?i)anydesk"                               = "--install `"$env:ProgramFiles\AnyDesk`" --start-with-win --silent"
        "(?i)teamviewer"                            = "/S"
        "(?i)ultraviewer"                           = "/silent"
        "(?i)unikey|evkey"                          = "/S"
        "(?i)java|jre\b|jdk\b"                      = "/s"
        "(?i)adobe.*reader|acrobat.*reader"         = "/sAll /rs /msi EULA_ACCEPT=YES"
        "(?i)adobe.*air"                            = "-silent"
        "(?i)notepad\+\+"                           = "/S"
        "(?i)vscode|visual.?studio.?code"           = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=!runcode"
        "(?i)git\b"                                 = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-"
        "(?i)node|nodejs"                           = "/quiet /norestart"
        "(?i)python"                                = "/quiet InstallAllUsers=1 PrependPath=1"
        "(?i)office|microsoft 365"                  = "/quiet"
        "(?i)malwarebytes"                          = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        "(?i)kaspersky"                             = "/s /pALL ACCEPT_LICENSE=1"
        "(?i)eset"                                  = "/silent /accepteula"
        "(?i)avast"                                 = "/silent /ws"
        "(?i)winpcap|npcap"                         = "/S"
        "(?i)wireshark"                             = "/S"
        "(?i)putty"                                 = "/quiet"
        "(?i)winscp"                                = "/VERYSILENT /SUPPRESSMSGBOXES"
        "(?i)filezilla"                             = "/S"
        "(?i)winmerge"                              = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        "(?i)virtualbox"                            = "--silent"
        "(?i)vmware"                                = "/s /v/qn"
        "(?i)handbrake"                             = "/S"
        "(?i)audacity"                              = "/S"
        "(?i)gimp"                                  = "/S"
        "(?i)inkscape"                              = "/S"
        "(?i)libreoffice"                           = "/quiet /norestart"
        "(?i)sumatra"                               = "/S"
        "(?i)irfanview"                             = "/silent"
        "(?i)paint\.net"                            = "/auto"
        "(?i)cpu-z|cpuz"                            = "/SILENT"
        "(?i)gpu-z|gpuz"                            = "/S"
        "(?i)hwinfo"                                = "/VERYSILENT"
        "(?i)crystaldisk"                           = "/VERYSILENT /SUPPRESSMSGBOXES"
        "(?i)speccy"                                = "/S"
        "(?i)ccleaner"                              = "/S"
        "(?i)everything"                            = "/S"
        "(?i)greenshot"                             = "/VERYSILENT /SUPPRESSMSGBOXES"
        "(?i)sharex"                                = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        "(?i)etcher|balena"                         = "--silent"
    }
    foreach ($K in $ThuVien.Keys) { if ($TenPhanMem -match $K) { return $ThuVien[$K] } }
    return "/S"
}

function Chay-TienTrinhChuan ($DuongDanFile, $ThamSo, $ThuMucLamViec) {
    try {
        $Info = New-Object System.Diagnostics.ProcessStartInfo
        $Info.FileName         = $DuongDanFile
        $Info.Arguments        = $ThamSo
        $Info.WorkingDirectory = $ThuMucLamViec
        $Info.UseShellExecute  = $true
        return [System.Diagnostics.Process]::Start($Info)
    } catch { return $null }
}

# ------------------------------------------------------------------------------
# MODULE 4: GIAO DIỆN XAML
# ------------------------------------------------------------------------------
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox Dashboard" Width="1150" Height="780" MinWidth="950" MinHeight="620"
        WindowStartupLocation="CenterScreen" Background="Transparent"
        AllowsTransparency="True" WindowStyle="None" FontFamily="Segoe UI"
        ResizeMode="CanResizeWithGrip">
    <Border CornerRadius="12" Background="#F8FAFC" ClipToBounds="True">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="300"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="#0F172A">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Margin="20,35,20,20">
                        <TextBlock Text="🚀" FontSize="42" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                        <TextBlock Text="VIETTOOLBOX" Foreground="White" FontSize="22" FontWeight="Black" HorizontalAlignment="Center"/>
                        <TextBlock Text="Auto Deploy Dashboard" Foreground="#94A3B8" FontSize="12" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                        <Rectangle Height="1" Fill="#1E293B" Margin="0,20,0,0"/>
                    </StackPanel>

                    <StackPanel Grid.Row="1" Margin="18,0">
                        <Button Name="NutKichHoat" Content="▶  BẮT ĐẦU CÀI ĐẶT"
                                Height="52" Background="#10B981" Foreground="White"
                                FontWeight="Bold" FontSize="14" Margin="0,12,0,10" Cursor="Hand">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                        <Button Name="NutHuyViec" Content="⏹  HỦY TIẾN TRÌNH"
                                Height="44" Background="#EF4444" Foreground="White"
                                FontWeight="Bold" FontSize="13" Margin="0,0,0,12" Cursor="Hand" IsEnabled="False">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>
                        <Button Name="NutTaiLai" Content="↻  TẢI LẠI TỪ ĐẦU"
                                Height="44" Background="#3B82F6" Foreground="White"
                                FontWeight="Bold" FontSize="13" Margin="0,0,0,12" Cursor="Hand">
                            <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                        </Button>

                        <Border Background="#1E293B" CornerRadius="8" Padding="14,10" Margin="0,0,0,10">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" HorizontalAlignment="Center">
                                    <TextBlock Name="SoLuongChon" Text="0" Foreground="#10B981"
                                               FontSize="26" FontWeight="Black" HorizontalAlignment="Center"/>
                                    <TextBlock Text="Đã chọn" Foreground="#64748B" FontSize="11" HorizontalAlignment="Center"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" HorizontalAlignment="Center">
                                    <TextBlock Name="TongSo" Text="0" Foreground="White"
                                               FontSize="26" FontWeight="Black" HorizontalAlignment="Center"/>
                                    <TextBlock Text="Tổng cộng" Foreground="#64748B" FontSize="11" HorizontalAlignment="Center"/>
                                </StackPanel>
                            </Grid>
                        </Border>
                    </StackPanel>

                    <Border Grid.Row="2" Background="#0D1526" CornerRadius="8" Margin="18,0,18,10">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Grid.Row="0" Background="#1E293B" CornerRadius="6,6,0,0" Padding="10,7">
                                <TextBlock Text="📋  Danh sách đã chọn" Foreground="#94A3B8"
                                           FontSize="11" FontWeight="SemiBold"/>
                            </Border>
                            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Name="LogScroll">
                                <StackPanel Name="LogPanel" Margin="8,6,8,6"/>
                            </ScrollViewer>
                        </Grid>
                    </Border>

                    <TextBlock Grid.Row="3" Text="V709 - Smart Silent Detect" Foreground="#475569"
                               FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,16"/>
                </Grid>
            </Border>

            <Grid Grid.Column="1">
                <Grid.RowDefinitions>
                    <RowDefinition Height="65"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Background="#FFFFFF" BorderBrush="#E2E8F0" BorderThickness="0,0,0,1" Name="KhungTieuDe">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0" Orientation="Horizontal" Margin="25,0,0,0" VerticalAlignment="Center">
                            <Button Name="NutChonToanBo" Content="☑  Chọn tất cả" Width="120" Height="36" Margin="0,0,10,0"
                                    Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1"
                                    Foreground="#334155" FontWeight="SemiBold" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                            <Button Name="NutHuyChon" Content="☐  Bỏ chọn" Width="110" Height="36"
                                    Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1"
                                    Foreground="#334155" FontWeight="SemiBold" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </StackPanel>
                        <StackPanel Grid.Column="2" Orientation="Horizontal" Margin="0,0,15,0"
                                    HorizontalAlignment="Right" VerticalAlignment="Center">
                            <Button Name="NutThuNho" Content="—" Width="40" Height="40"
                                    Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#64748B" Cursor="Hand"/>
                            <Button Name="NutPhongTo" Content="☐" Width="40" Height="40"
                                    Background="Transparent" BorderThickness="0" FontSize="18" Foreground="#64748B" Cursor="Hand"/>
                            <Button Name="NutThoat"  Content="✕" Width="40" Height="40"
                                    Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#EF4444" FontWeight="Bold" Cursor="Hand"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <ScrollViewer Grid.Row="1" Margin="20,15,10,20" VerticalScrollBarVisibility="Auto">
                    <ItemsControl Name="BangHienThiDuLieu">
                        <ItemsControl.ItemsPanel>
                            <ItemsPanelTemplate><WrapPanel Orientation="Horizontal"/></ItemsPanelTemplate>
                        </ItemsControl.ItemsPanel>
                        <ItemsControl.GroupStyle>
                            <GroupStyle>
                                <GroupStyle.HeaderTemplate>
                                    <DataTemplate>
                                        <TextBlock Text="{Binding Name}" FontWeight="Black" FontSize="17"
                                                   Foreground="#0F172A" Margin="5,18,10,12"/>
                                    </DataTemplate>
                                </GroupStyle.HeaderTemplate>
                            </GroupStyle>
                        </ItemsControl.GroupStyle>
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <Border Width="235" Height="92" Margin="5,5,14,14"
                                        Background="#FFFFFF" BorderBrush="#E2E8F0"
                                        BorderThickness="1.5" CornerRadius="10">
                                    <Grid Margin="10,8">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="28"/>
                                            <ColumnDefinition Width="42"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        <CheckBox IsChecked="{Binding Chon, UpdateSourceTrigger=PropertyChanged}"
                                                  VerticalAlignment="Center" Grid.Column="0">
                                            <CheckBox.LayoutTransform><ScaleTransform ScaleX="1.25" ScaleY="1.25"/></CheckBox.LayoutTransform>
                                        </CheckBox>
                                        <Image Source="{Binding BieuTuong}" Width="34" Height="34"
                                               VerticalAlignment="Center" HorizontalAlignment="Center" Grid.Column="1"/>
                                        <StackPanel Grid.Column="2" VerticalAlignment="Center" Margin="5,0,0,0">
                                            <TextBlock Text="{Binding Ten}" FontWeight="Bold" FontSize="12.5"
                                                       Foreground="#1E293B" TextTrimming="CharacterEllipsis" Margin="0,0,0,5"/>
                                            <ProgressBar Value="{Binding TienTrinh}" Height="7"
                                                         Foreground="#10B981" Background="#F1F5F9" BorderThickness="0">
                                                <ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="3"/></Style></ProgressBar.Resources>
                                            </ProgressBar>
                                            <TextBlock Text="{Binding TrangThai}" FontSize="10.5" Foreground="#64748B"
                                                       FontWeight="SemiBold" Margin="0,3,0,0" TextTrimming="CharacterEllipsis"/>
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

$CuaSoChinh   = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$XAML))
$BangDanhSach = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$BoLoc        = [System.Windows.Data.CollectionViewSource]::GetDefaultView($BangDanhSach)
$BoLoc.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription("DanhMuc")))
$CuaSoChinh.FindName("BangHienThiDuLieu").ItemsSource = $BoLoc
$Dispatcher = $CuaSoChinh.Dispatcher

# ------------------------------------------------------------------------------
# MODULE 5: HÀM CẬP NHẬT LOG & BỘ ĐẾM
# ------------------------------------------------------------------------------
$NhanSoLuong = $CuaSoChinh.FindName("SoLuongChon")
$NhanTong    = $CuaSoChinh.FindName("TongSo")
$LogPanel    = $CuaSoChinh.FindName("LogPanel")
$LogScroll   = $CuaSoChinh.FindName("LogScroll")

function CapNhat-LogChon {
    $Dispatcher.Invoke([action]{
        # Cập nhật số đếm
        $SoChon = ($BangDanhSach | Where-Object { $_.Chon }).Count
        $NhanSoLuong.Text = $SoChon

        # Vẽ lại log panel
        $LogPanel.Children.Clear()
        $DaChon = $BangDanhSach | Where-Object { $_.Chon }
        if ($DaChon.Count -eq 0) {
            $Trong = New-Object System.Windows.Controls.TextBlock
            $Trong.Text       = "Chưa chọn phần mềm nào"
            $Trong.Foreground = [System.Windows.Media.Brushes]::Gray
            $Trong.FontSize   = 11
            $Trong.FontStyle  = [System.Windows.FontStyles]::Italic
            $Trong.Margin     = [System.Windows.Thickness]::new(4, 2, 4, 2)
            $LogPanel.Children.Add($Trong) | Out-Null
        } else {
            $STT = 1
            $BoChuyenMau = New-Object System.Windows.Media.BrushConverter
            
            foreach ($PM in $DaChon) {
                $Hang = New-Object System.Windows.Controls.Border
                $Hang.CornerRadius = [System.Windows.CornerRadius]::new(5)
                $Hang.Background  = $BoChuyenMau.ConvertFromString("#1E293B")
                $Hang.Margin      = [System.Windows.Thickness]::new(0, 2, 0, 2)
                $Hang.Padding     = [System.Windows.Thickness]::new(8, 5, 8, 5)

                $Stack = New-Object System.Windows.Controls.StackPanel
                $Stack.Orientation = [System.Windows.Controls.Orientation]::Horizontal

                # 1. Khởi tạo lại Số thứ tự
                $SttLabel = New-Object System.Windows.Controls.TextBlock
                $SttLabel.Text       = "$STT. "
                $SttLabel.Foreground = $BoChuyenMau.ConvertFromString("#64748B")
                $SttLabel.FontSize   = 11
                $SttLabel.VerticalAlignment = "Center"

                # 2. Khởi tạo Tên phần mềm
                $TenLabel = New-Object System.Windows.Controls.TextBlock
                $TenLabel.Text       = $PM.Ten
                $TenLabel.Foreground = [System.Windows.Media.Brushes]::White
                $TenLabel.FontSize   = 11
                $TenLabel.FontWeight = [System.Windows.FontWeights]::SemiBold
                $TenLabel.TextTrimming = "CharacterEllipsis"
                $TenLabel.MaxWidth   = 175
                $TenLabel.VerticalAlignment = "Center"

                # 3. Khởi tạo Tích xanh Data Binding
                $TichXanhLabel = New-Object System.Windows.Controls.TextBlock
                $TichXanhLabel.Foreground = $BoChuyenMau.ConvertFromString("#10B981")
                $TichXanhLabel.FontSize   = 12
                $TichXanhLabel.FontWeight = [System.Windows.FontWeights]::Bold
                $TichXanhLabel.Margin     = [System.Windows.Thickness]::new(5, 0, 0, 0)
                $TichXanhLabel.VerticalAlignment = "Center"
                
                $BindKetQua = New-Object System.Windows.Data.Binding("KetQua")
                $BindKetQua.Source = $PM
                $TichXanhLabel.SetBinding([System.Windows.Controls.TextBlock]::TextProperty, $BindKetQua) | Out-Null

                # Đẩy tất cả vào Stack
                $Stack.Children.Add($SttLabel) | Out-Null
                $Stack.Children.Add($TenLabel) | Out-Null
                $Stack.Children.Add($TichXanhLabel) | Out-Null
                
                $Hang.Child = $Stack
                $LogPanel.Children.Add($Hang) | Out-Null
                $STT++
            }
        }
        # Auto scroll xuống cuối
        $LogScroll.ScrollToBottom()
    })
}
# ------------------------------------------------------------------------------
# MODULE 6: SỰ KIỆN GIAO DIỆN
# ------------------------------------------------------------------------------
$CuaSoChinh.FindName("KhungTieuDe").Add_MouseLeftButtonDown({
    param($NguoiGui, $SuKien)
    if ($SuKien.ClickCount -eq 2) {
        if ($CuaSoChinh.WindowState -eq "Normal") { $CuaSoChinh.WindowState = "Maximized" }
        else { $CuaSoChinh.WindowState = "Normal" }
    } else {
        $CuaSoChinh.DragMove()
    }
})

$CuaSoChinh.FindName("NutPhongTo").Add_Click({
    if ($CuaSoChinh.WindowState -eq "Normal") { $CuaSoChinh.WindowState = "Maximized" }
    else { $CuaSoChinh.WindowState = "Normal" }
})

$CuaSoChinh.FindName("NutThoat").Add_Click({ $Global:TrangThaiBoNho.TrangThai = "DungLai"; $CuaSoChinh.Close() })
$CuaSoChinh.FindName("NutThuNho").Add_Click({ $CuaSoChinh.WindowState = "Minimized" })

$CuaSoChinh.FindName("NutChonToanBo").Add_Click({
    foreach ($M in $BangDanhSach) { $M.Chon = $true }
    CapNhat-LogChon
})
$CuaSoChinh.FindName("NutHuyChon").Add_Click({
    foreach ($M in $BangDanhSach) { $M.Chon = $false }
    CapNhat-LogChon
})

$DieuKhienKichHoat = $CuaSoChinh.FindName("NutKichHoat")
$DieuKhienHuyViec  = $CuaSoChinh.FindName("NutHuyViec")
$DieuKhienTaiLai   = $CuaSoChinh.FindName("NutTaiLai")

function CapNhat-NutBam ($TT) {
    $DieuKhienKichHoat.IsEnabled = ($TT -eq "NhanhRoi")
    $DieuKhienHuyViec.IsEnabled  = ($TT -eq "DangChay")
    $DieuKhienTaiLai.IsEnabled   = $true # CẬP NHẬT: Luôn bật nút tải lại
}

$DieuKhienHuyViec.Add_Click({
    $Global:TrangThaiBoNho.TrangThai = "DungLai"
    CapNhat-NutBam "NhanhRoi"
})

$DieuKhienTaiLai.Add_Click({
    # CẬP NHẬT: Ngắt tiến trình đang chạy (nếu có) trước khi tải lại
    $Global:TrangThaiBoNho.TrangThai = "DungLai"
    
    # Reset nút bấm và trạng thái
    $DieuKhienKichHoat.Content = "▶  BẮT ĐẦU CÀI ĐẶT"
    $Global:TrangThaiBoNho.TrangThai = "NhanhRoi"
    CapNhat-NutBam "NhanhRoi"
    
    # Xóa sạch dữ liệu cũ và tải lại mới từ CSV
    $BangDanhSach.Clear()
    TaiDuLieuTuCSV
})

# ------------------------------------------------------------------------------
# MODULE 7: ĐỘNG CƠ CÀI ĐẶT (RUNSPACE)
# ------------------------------------------------------------------------------
$DieuKhienKichHoat.Add_Click({
    $Global:TrangThaiBoNho.TrangThai = "DangChay"
    CapNhat-NutBam "DangChay"

    $CuaSoChinh.Dispatcher.Invoke([action]{ $DieuKhienKichHoat.Content = "🧹 Dọn rác lần trước..." })
    try {
        Get-ChildItem -Path $Global:ThuMucLuuTru -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        if (Test-Path "C:\VietToolbox_Temp") { Remove-Item "C:\VietToolbox_Temp" -Recurse -Force -ErrorAction SilentlyContinue }
    } catch {}
    $CuaSoChinh.Dispatcher.Invoke([action]{ $DieuKhienKichHoat.Content = "⏳ Đang xử lý..." })

    $RS = [runspacefactory]::CreateRunspace()
    $RS.ApartmentState = "STA"; $RS.ThreadOptions = "ReuseThread"; $RS.Open()
    $RS.SessionStateProxy.SetVariable("BangDanhSach",    $BangDanhSach)
    $RS.SessionStateProxy.SetVariable("ThuMucLuuTru",    $Global:ThuMucLuuTru)
    $RS.SessionStateProxy.SetVariable("DanhSachKhoaAPI", $Global:DanhSachKhoaAPI)
    $RS.SessionStateProxy.SetVariable("TrangThaiBoNho",  $Global:TrangThaiBoNho)
    $RS.SessionStateProxy.SetVariable("Dispatcher",      $Dispatcher)
    $RS.SessionStateProxy.SetVariable("F_KiemTra",       ${Function:KiemTra-LoiFileNen})
    $RS.SessionStateProxy.SetVariable("F_TuDong",        ${Function:TuDong-NhanDienThamSoEXE})
    $RS.SessionStateProxy.SetVariable("F_Chay",          ${Function:Chay-TienTrinhChuan})

    $PS = [powershell]::Create(); $PS.Runspace = $RS
    [void]$PS.AddScript({
        Set-Item "Function:KiemTra-LoiFileNen"       $F_KiemTra
        Set-Item "Function:TuDong-NhanDienThamSoEXE" $F_TuDong
        Set-Item "Function:Chay-TienTrinhChuan"      $F_Chay

       function UI ($PM, $TT, $TP) {
            # Dùng lại Invoke để bắt chết biến trong bộ nhớ
            $Dispatcher.Invoke([action]{
                if ($null -ne $TT) { 
                    $PM.TrangThai = $TT 
                    if ($TT -match "Hoàn tất") { $PM.KetQua = " ✔" }
                    elseif ($TT -match "Lỗi") { $PM.KetQua = " ❌" }
                    elseif ($TT -match "Đang phân tích|Quét Drive") { $PM.KetQua = "" }
                }
                if ($null -ne $TP) { $PM.TienTrinh = $TP }
            })
        }

        # Đóng các cửa sổ Explorer mới xuất hiện sau khi cài
        function DongExplorerMoi ($DanhSachHwndCu) {
            try {
                Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
public class WinHelper {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lp, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    public delegate bool EnumWindowsProc(IntPtr h, IntPtr lParam);
    public static List<IntPtr> GetExplorerWindows() {
        var list = new List<IntPtr>();
        EnumWindows((h, l) => {
            var sb = new System.Text.StringBuilder(256);
            GetClassName(h, sb, 256);
            if ((sb.ToString() == "CabinetWClass" || sb.ToString() == "ExploreWClass") && IsWindowVisible(h))
                list.Add(h);
            return true;
        }, IntPtr.Zero);
        return list;
    }
    public static void CloseWindow(IntPtr h) { PostMessage(h, 0x0010, IntPtr.Zero, IntPtr.Zero); }
}
"@ -Language CSharp -ErrorAction SilentlyContinue
            } catch {}

            try {
                $DanhSachMoi = [WinHelper]::GetExplorerWindows()
                foreach ($Hwnd in $DanhSachMoi) {
                    if ($DanhSachHwndCu -notcontains $Hwnd) {
                        [WinHelper]::CloseWindow($Hwnd)
                    }
                }
            } catch {}
        }

        # Lấy snapshot Explorer hiện tại trước khi bắt đầu cài bất kỳ gì
        $ExplorerTruocToanBo = try { [WinHelper]::GetExplorerWindows() } catch { @() }

        function CaiDat ($PM) {
            UI $PM "Đang phân tích..." 5
            $TenSach    = $PM.Ten -replace '[\\/:\*\?"<>\|]', ''
            $DuoiFile   = ".exe"
            $DuongDanLT = Join-Path $ThuMucLuuTru "$TenSach$DuoiFile"
            $DaXong     = $false

            $IDDrive = ""
            if ($PM.DuongDanTai -match "id=([^&]+)")      { $IDDrive = $Matches[1] }
            elseif ($PM.DuongDanTai -match "/d/([^/]+)")  { $IDDrive = $Matches[1] }

            if ($IDDrive) {
                foreach ($Key in $DanhSachKhoaAPI) {
                    try {
                        UI $PM "Quét Drive..." $null
                        $Meta = Invoke-RestMethod "https://www.googleapis.com/drive/v3/files/$IDDrive`?fields=name&key=$Key" -UseBasicParsing
                        if ($Meta.name) {
                            $Ext = [System.IO.Path]::GetExtension($Meta.name)
                            if ($Ext -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle|appx)") {
                                $DuoiFile = $Ext; $DuongDanLT = Join-Path $ThuMucLuuTru $Meta.name
                            }
                        }
                        $Goi = [System.Net.HttpWebRequest]::Create("https://www.googleapis.com/drive/v3/files/$IDDrive`?alt=media&key=$Key")
                        $PH  = $Goi.GetResponse()
                        $Dong = $PH.GetResponseStream()
                        $File = New-Object System.IO.FileStream($DuongDanLT, [System.IO.FileMode]::Create)
                        
                        # Tối ưu hóa Buffer và bộ đếm thời gian
                        $Buf = New-Object byte[] 4194304; $Tong = $PH.ContentLength; $Da = 0
                        $DongHo = [System.Diagnostics.Stopwatch]::StartNew()
                        do {
                            if ($TrangThaiBoNho.TrangThai -eq "DungLai") { break }
                            $n = $Dong.Read($Buf, 0, $Buf.Length)
                            if ($n -gt 0) {
                                $File.Write($Buf, 0, $n); $Da += $n
                                
                                # Logic cập nhật UI 150ms và chống lỗi khi không rõ dung lượng
                                if ($Tong -gt 0) {
                                    if ($DongHo.ElapsedMilliseconds -gt 150 -or $Da -eq $Tong) { 
                                        $p = [math]::Round(($Da/$Tong)*100)
                                        UI $PM "Đang tải: $p%" $p
                                        $DongHo.Restart()
                                    }
                                } else {
                                    if ($DongHo.ElapsedMilliseconds -gt 500) {
                                        UI $PM "Đang tải: $([math]::Round($Da/1MB, 1)) MB" 50
                                        $DongHo.Restart()
                                    }
                                }
                            }
                        } while ($n -gt 0)
                        $File.Close(); $Dong.Close(); $PH.Close()
                        
                        if ($Tong -gt 0 -and $TrangThaiBoNho.TrangThai -ne "DungLai") { UI $PM "Đang tải: 100%" 100 }
                        if ((Get-Item $DuongDanLT -EA SilentlyContinue).Length -ge 1MB) { $DaXong = $true; break }
                    } catch { if ($File) { $File.Close() } }
                }
            } else {
                try {
                    $Goi = [System.Net.HttpWebRequest]::Create($PM.DuongDanTai)
					$Goi.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                    $PH  = $Goi.GetResponse()
                    $CD  = $PH.Headers["Content-Disposition"]
                    if ($CD -match 'filename="?([^";]+)"?') {
                        $TenGoc = [System.Net.WebUtility]::UrlDecode($Matches[1])
                        $ExtGoc = [System.IO.Path]::GetExtension($TenGoc)
                        if ($ExtGoc -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle)") { $DuoiFile = $ExtGoc; $DuongDanLT = Join-Path $ThuMucLuuTru $TenGoc }
                    } else {
                        $ExtUrl = [System.IO.Path]::GetExtension($PM.DuongDanTai.Split('?')[0])
                        if ($ExtUrl -match "(?i)\.(zip|rar|7z|msi|exe|msixbundle)") { $DuoiFile = $ExtUrl; $DuongDanLT = Join-Path $ThuMucLuuTru "$TenSach$DuoiFile" }
                    }
                    $Dong = $PH.GetResponseStream()
                    $File = New-Object System.IO.FileStream($DuongDanLT, [System.IO.FileMode]::Create)
                    
                    # Thay bằng Buffer 4MB (4194304)
                    $Buf = New-Object byte[] 4194304; $Tong = $PH.ContentLength; $Da = 0
                    $DongHo = [System.Diagnostics.Stopwatch]::StartNew()
                    do {
                        if ($TrangThaiBoNho.TrangThai -eq "DungLai") { break }
                        $n = $Dong.Read($Buf, 0, $Buf.Length)
                        if ($n -gt 0) {
                            $File.Write($Buf, 0, $n); $Da += $n
                            
                            # Logic cập nhật UI 150ms và chống lỗi khi không rõ dung lượng
                            if ($Tong -gt 0) {
                                if ($DongHo.ElapsedMilliseconds -gt 150 -or $Da -eq $Tong) { 
                                    $p = [math]::Round(($Da/$Tong)*100)
                                    UI $PM "Đang tải: $p%" $p
                                    $DongHo.Restart()
                                }
                            } else {
                                if ($DongHo.ElapsedMilliseconds -gt 500) {
                                    UI $PM "Đang tải: $([math]::Round($Da/1MB, 1)) MB" 50
                                    $DongHo.Restart()
                                }
                            }
                        }
                    } while ($n -gt 0)
                    $File.Close(); $Dong.Close(); $PH.Close()
                    
                    if ($Tong -gt 0 -and $TrangThaiBoNho.TrangThai -ne "DungLai") { UI $PM "Đang tải: 100%" 100 }
                    if ($TrangThaiBoNho.TrangThai -ne "DungLai") { $DaXong = $true }
                } catch { if ($File) { $File.Close() } }
            }

            if (-not $DaXong) { UI $PM "❌ Lỗi tải xuống" 0; return }
            if ($TrangThaiBoNho.TrangThai -eq "DungLai") { return }

            Unblock-File -Path $DuongDanLT -ErrorAction SilentlyContinue
            UI $PM "🔍 Phân tích file..." 50

            $FileThucThi = $DuongDanLT
            $ThuMucTemp  = "C:\VietToolbox_Temp\$($TenSach -replace ' ','')"

            if ((KiemTra-LoiFileNen $DuongDanLT) -or ($DuoiFile -match "(?i)\.(zip|rar|7z)")) {
                UI $PM "📦 Đang giải nén..." $null
                if (-not (Test-Path $ThuMucTemp)) { New-Item -ItemType Directory $ThuMucTemp -Force | Out-Null }
                $Exe7z = Join-Path $env:TEMP "7za.exe"
                if (-not (Test-Path $Exe7z)) { Invoke-WebRequest "https://github.com/develar/7zip-bin/raw/master/win/x64/7za.exe" -OutFile $Exe7z -UseBasicParsing }
                $P7z = Start-Process $Exe7z -ArgumentList "x `"$DuongDanLT`" -pAdmin@2512 -o`"$ThuMucTemp`" -y" -PassThru -WindowStyle Hidden
                $P7z.WaitForExit()

                $DsMsi = Get-ChildItem $ThuMucTemp -Filter "*.msi" -Recurse | Sort-Object Length -Descending
                if ($DsMsi) { $FileThucThi = $DsMsi[0].FullName }
                else {
                    $DsExe = Get-ChildItem $ThuMucTemp -Filter "*.exe" -Recurse |
                             Where-Object { $_.Name -notmatch "(?i)unin|remove" } |
                             Sort-Object Length -Descending
                    if ($DsExe) { $FileThucThi = $DsExe[0].FullName }
                }
            }

            $ThamSo = TuDong-NhanDienThamSoEXE -TenPhanMem $PM.Ten -ThamSoTuCSV $PM.ThamSoNgam -DuongDanFile $FileThucThi

            # Xử lý file MSI
            if ($FileThucThi -match "(?i)\.msi$") {
                $ThamSo      = "/i `"$FileThucThi`" /quiet /norestart ALLUSERS=1"
                $FileThucThi = "msiexec.exe"
            }

            # Xử lý file MSIX/APPX (UWP từ Windows Store như WhatsApp)
            if ($FileThucThi -match "(?i)\.(msix|appx|msixbundle|appxbundle)$") {
                $ThamSo      = "-NoProfile -NonInteractive -Command `"Add-AppxPackage -Path '$FileThucThi'`""
                $FileThucThi = "powershell.exe"
            }

            # --- TỰ ĐỘNG NHẬN DIỆN ỨNG DỤNG PORTABLE (CHẠY TRỰC TIẾP) ---
            $TenExeChinh = [System.IO.Path]::GetFileNameWithoutExtension($FileThucThi)
            $LaAppPortable = ($TenExeChinh -notmatch "(?i)setup|install|msiexec") -and ($PM.Ten -match "(?i)unikey|evkey|rufus|anydesk" -or $DuoiFile -match "(?i)\.(zip|rar|7z)")

            if ($LaAppPortable) {
                UI $PM "Chép vào ổ C & Tạo Shortcut..." 70
                $ThuMucDich = Join-Path $env:ProgramFiles $TenSach
                if (-not (Test-Path $ThuMucDich)) { New-Item -ItemType Directory -Path $ThuMucDich -Force | Out-Null }
                
                # Dời nhà cho file từ Temp sang ổ C
                if ($DuoiFile -match "(?i)\.(zip|rar|7z)" -and (Test-Path $ThuMucTemp)) {
                    Copy-Item -Path "$ThuMucTemp\*" -Destination $ThuMucDich -Recurse -Force
                } else {
                    Copy-Item -Path $FileThucThi -Destination $ThuMucDich -Force
                }

                $ExeTrongOC = Get-ChildItem -Path $ThuMucDich -Filter "*.exe" -Recurse | Where-Object { $_.Name -notmatch "(?i)unin|remove" } | Sort-Object Length -Descending | Select-Object -First 1
                
                if ($ExeTrongOC) {
                    try {
                        $WshShell = New-Object -ComObject WScript.Shell
                        $DuongDanLnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "$($PM.Ten).lnk"
                        $LoiTat = $WshShell.CreateShortcut($DuongDanLnk)
                        $LoiTat.TargetPath = $ExeTrongOC.FullName
                        $LoiTat.WorkingDirectory = $ExeTrongOC.DirectoryName
                        $LoiTat.Save()
                    } catch {}
                    
                    Start-Process -FilePath $ExeTrongOC.FullName -ErrorAction SilentlyContinue
                    UI $PM "✅ Hoàn tất!" 100

                    # TỰ ĐỘNG XÓA RÁC KHI XONG (APP PORTABLE)
                    try {
                        if (Test-Path $DuongDanLT) { Remove-Item -Path $DuongDanLT -Force -ErrorAction SilentlyContinue }
                        if (Test-Path $ThuMucTemp) { Remove-Item -Path $ThuMucTemp -Recurse -Force -ErrorAction SilentlyContinue }
                    } catch {}

                    return 
                }
            }
            # -----------------------------------------------------------------------------

            UI $PM "🛠️ Đang cài đặt..." $null
            try {
                $ExplorerTruocCaiNay = @()
                try {
                    $SA_Init = New-Object -ComObject Shell.Application
                    foreach ($Win in $SA_Init.Windows()) { $ExplorerTruocCaiNay += $Win.HWND }
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($SA_Init) | Out-Null
                } catch {}

                $ThoiDiemBatDauCai = Get-Date

                function DonRacNgayLapTuc {
                    try {
                        $SA = New-Object -ComObject Shell.Application
                        foreach ($Win in $SA.Windows()) {
                            if ($Win.Name -match "Explorer|Cabinet" -and $ExplorerTruocCaiNay -notcontains $Win.HWND) {
                                $Win.Quit()
                            }
                        }
                        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($SA) | Out-Null
                    } catch {}

                    # Danh sách các app "cầm đèn chạy trước ô tô" tự động mở cửa sổ sau khi xả nén
                    $DanhSachAppRac = "notepad", "hh", "cmd", "viber", "zalo", "telegram", "skype", "discord", "chrome", "msedge", "brave", "coccoc"
                    foreach ($App in $DanhSachAppRac) {
                        Get-Process $App -ErrorAction SilentlyContinue | 
                            Where-Object { $_.StartTime -ge $ThoiDiemBatDauCai } | 
                            Stop-Process -Force -ErrorAction SilentlyContinue
                    }
                }

                $TienTrinh = Chay-TienTrinhChuan $FileThucThi $ThamSo (Split-Path $FileThucThi)
                
                $GiayUocTinh = 60
                if ($PM.Ten -match "(?i)office|visual|studio|sql|adobe|autocad") { $GiayUocTinh = 420 }
                elseif ($PM.Ten -match "(?i)chrome|browser|unikey|evkey|zalo") { $GiayUocTinh = 45 }
                
                $GiayConLai = $GiayUocTinh
                
                if ($TienTrinh) {
                    while (-not $TienTrinh.HasExited) {
                        Start-Sleep -Seconds 2
                        $GiayConLai -= 2
                        
                        if ($GiayConLai -gt 0) {
                            UI $PM "Còn khoảng: $($GiayConLai)s..." ([math]::Max(0, [math]::Round((($GiayUocTinh - $GiayConLai) / $GiayUocTinh) * 90)))
                        } else {
                            UI $PM "Đang về đích..." 95
                        }
                        DonRacNgayLapTuc 
                        if ($GiayUocTinh - $GiayConLai -ge 600 -or $TrangThaiBoNho.TrangThai -eq "DungLai") { break }
                    }

                    $ChoPhu = 0
                    while ($ChoPhu -lt 30 -and $TrangThaiBoNho.TrangThai -ne "DungLai") {
                        Start-Sleep -Seconds 2; $ChoPhu += 2
                        $Con = Get-Process -EA SilentlyContinue | Where-Object { $_.Name -match "(?i)setup|install|msiexec|unins" }
                        if (-not $Con) { break }
                        UI $PM "Đang dọn dẹp..." 98
                        DonRacNgayLapTuc 
                    }
                }

                $ChoXuatHien = 0
                while ($ChoXuatHien -lt 8) {
                    Start-Sleep -Milliseconds 500; $ChoXuatHien++
                    DonRacNgayLapTuc
                }

                UI $PM "✅ Hoàn tất!" 100

                # TỰ ĐỘNG XÓA RÁC KHI XONG (APP SETUP BÌNH THƯỜNG)
                try {
                    if (Test-Path $DuongDanLT) { Remove-Item -Path $DuongDanLT -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $ThuMucTemp) { Remove-Item -Path $ThuMucTemp -Recurse -Force -ErrorAction SilentlyContinue }
                } catch {}

            } catch { UI $PM "⚠️ Lỗi cài đặt" 0 }
        }

        foreach ($PM in $BangDanhSach) {
            if ($PM.Chon -and $TrangThaiBoNho.TrangThai -ne "DungLai") { CaiDat $PM }
        }
    })

    $KenhChay = $PS.BeginInvoke()
    $Timer = New-Object System.Windows.Threading.DispatcherTimer
    $Timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $Timer.Add_Tick({
        if ($KenhChay.IsCompleted) {
            $PS.EndInvoke($KenhChay); $PS.Dispose(); $RS.Close(); $RS.Dispose()
            $Timer.Stop()
            
            $CuaSoChinh.Dispatcher.Invoke([action]{ $DieuKhienKichHoat.Content = "🧹 Đang dọn rác giải phóng ổ cứng..." })
            try {
                Get-ChildItem -Path $Global:ThuMucLuuTru -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                if (Test-Path "C:\VietToolbox_Temp") { Remove-Item "C:\VietToolbox_Temp" -Recurse -Force -ErrorAction SilentlyContinue }
            } catch {}

            $Global:TrangThaiBoNho.TrangThai = "NhanhRoi"
            CapNhat-NutBam "NhanhRoi"
            $CuaSoChinh.Dispatcher.Invoke([action]{ $DieuKhienKichHoat.Content = "▶  BẮT ĐẦU CÀI ĐẶT" })
        }
    })
    $Timer.Start()
})

# ------------------------------------------------------------------------------
# MODULE 8: LẤY DỮ LIỆU CSV + GẮN SỰ KIỆN CHECKBOX
# ------------------------------------------------------------------------------
function TaiDuLieuTuCSV {
    try {
        $CSV = (Invoke-RestMethod $Global:LienKetDuLieuGoc -UseBasicParsing) | ConvertFrom-Csv
        foreach ($D in $CSV) {
            if (-not $D.DownloadUrl) { continue }
            $Icon = if ($D.IconURL)    { $D.IconURL }    else { "https://cdn-icons-png.flaticon.com/512/2589/2589174.png" }
            $Cat  = if ($D.catologi)   { $D.catologi }   elseif ($D.Category) { $D.Category } else { "Chung" }
            $Obj  = [KieuDuLieuPhanMem]@{
                Chon        = ($D.Check -match "True")
                Ten         = $D.Name
                BieuTuong   = $Icon
                DuongDanTai = $D.DownloadUrl
                ThamSoNgam  = $D.SilentArgs
                TrangThai   = "Sẵn sàng"
                TienTrinh   = 0
                DanhMuc     = $Cat
                KetQua      = ""
            }
            $Obj.add_PropertyChanged({
                param($s, $e)
                if ($e.PropertyName -eq "Chon") { CapNhat-LogChon }
            })
            $BangDanhSach.Add($Obj)
        }
        $NhanTong.Text = $BangDanhSach.Count
        CapNhat-LogChon 
    } catch {}
}

TaiDuLieuTuCSV

$CuaSoChinh.ShowDialog() | Out-Null