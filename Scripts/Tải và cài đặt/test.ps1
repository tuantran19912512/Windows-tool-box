# ==============================================================================
# VIETTOOLBOX AUTO-INSTALLER V700 - THE DASHBOARD EDITION (MODIFIED)
# Nâng cấp: Phân nhóm danh mục (Group Category) + Tự động giải nén Zip có Pass
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. THIẾT LẬP MÔI TRƯỜNG & BẢO MẬT
# ------------------------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 3072
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
Add-Type -AssemblyName System.Net.Http

# ------------------------------------------------------------------------------
# 2. CẤU HÌNH HỆ THỐNG & TÀI NGUYÊN
# ------------------------------------------------------------------------------
$Global:DuongDanCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$Global:ThuMucTaiVe = Join-Path $env:PUBLIC "LuuTruPhanMem"
$Global:TrangThaiHeThong = "NhanhRoi"

if (-not (Test-Path $Global:ThuMucTaiVe)) { New-Item -ItemType Directory -Path $Global:ThuMucTaiVe -Force | Out-Null }

function GiaiMa-API ($ChuoiMaHoa) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ChuoiMaHoa)) }
$Global:DanhSachAPI = @(
    (GiaiMa-API "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"),
    (GiaiMa-API "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v"),
    (GiaiMa-API "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv"),
    (GiaiMa-API "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR"),
    (GiaiMa-API "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0")
)

# ------------------------------------------------------------------------------
# 3. LỚP DỮ LIỆU BINDING (DATA MODEL) - THÊM 'DANHMUC'
# ------------------------------------------------------------------------------
if (-not ("PhanMemModel" -as [type])) {
    Add-Type -TypeDefinition @"
    using System; using System.ComponentModel;
    public class PhanMemModel : INotifyPropertyChanged {
        public event PropertyChangedEventHandler PropertyChanged;
        private void ThongBao(string p) { if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs(p)); }
        private bool _c; public bool Chon { get{return _c;} set{_c=value;ThongBao("Chon");} }
        private string _n; public string Ten { get{return _n;} set{_n=value;ThongBao("Ten");} }
        private string _i; public string IconURL { get{return _i;} set{_i=value;ThongBao("IconURL");} }
        private string _u; public string Url { get{return _u;} set{_u=value;ThongBao("Url");} }
        private string _a; public string Args { get{return _a;} set{_a=value;ThongBao("Args");} }
        private string _s; public string TrangThai { get{return _s;} set{_s=value;ThongBao("TrangThai");} }
        private int _p; public int TienTrinh { get{return _p;} set{_p=value;ThongBao("TienTrinh");} }
        private string _d; public string DanhMuc { get{return _d;} set{_d=value;ThongBao("DanhMuc");} }
    }
"@ -Language CSharp
}

# ------------------------------------------------------------------------------
# 4. HÀM BỔ TRỢ CỐT LÕI
# ------------------------------------------------------------------------------
function Tao-ShortcutChuan ($TenApp, $DuongDanExe) {
    try {
        $DesktopPath = [Environment]::GetFolderPath("Desktop")
        $FileShortcut = Join-Path $DesktopPath (($TenApp -replace '[\\/:\*\?"<>\|]', '') + ".lnk")
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($FileShortcut)
        $Shortcut.TargetPath = $DuongDanExe; $Shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($DuongDanExe)
        $Shortcut.IconLocation = "$DuongDanExe,0"; $Shortcut.Save()
    } catch {}
}
function Lay-ThamSoThongMinh ($DuongDanFile, $TenApp) {
    # 1. Nếu file là MSI - Luôn luôn dùng bộ này
    if ($DuongDanFile -match "\.msi$") { return "/i `"$DuongDanFile`" /quiet /qn /norestart" }
    
    # 2. Nếu là EXE, dùng tool nhận diện nhanh "họ" bộ cài
    # Ưu tiên các app hay cứng đầu
    if ($TenApp -match "Zoom") { return "/S /ZNoAutoStart" }
    if ($TenApp -match "Foxit") { return "/VERYSILENT /NORESTART /Clean" }
    if ($TenApp -match "Chrome|Google") { return "/silent /install" }
    
    # 3. Mặc định cho EXE (Dùng bộ tham số an toàn nhất, không nhồi nhét)
    # Hầu hết các bộ cài hiện nay nhận diện được /VERYSILENT (InnoSetup) hoặc /S (NSIS)
    return "/S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
}
function Tim-ExeRadar ($ThuMucGoc, $TenApp) {
    $TuKhoa = ($TenApp.Split(' ')[0]).Trim(); $BoLocRac = "unins|setup|update|agent|crash|codec|report|fix"; $BoLocThuMuc = "\[.*\]"
    $Exe = Get-ChildItem $ThuMucGoc -Filter "$TuKhoa.exe" -ErrorAction SilentlyContinue | Select-Object -First 1; if ($Exe) { return $Exe.FullName }
    $Exe = Get-ChildItem $ThuMucGoc -Filter "*.exe" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch $BoLocRac } | Sort-Object Length -Descending | Select-Object -First 1; if ($Exe) { return $Exe.FullName }
    $Exe = Get-ChildItem $ThuMucGoc -Filter "$TuKhoa.exe" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -notmatch $BoLocThuMuc } | Select-Object -First 1; if ($Exe) { return $Exe.FullName }
    $Exe = Get-ChildItem $ThuMucGoc -Filter "*.exe" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch $BoLocRac -and $_.DirectoryName -notmatch $BoLocThuMuc } | Sort-Object Length -Descending | Select-Object -First 1; return if ($Exe) { $Exe.FullName } else { $null }
}

function Dong-CuaSoBungKem ($TenApp) {
    try {
        $TuKhoa = ($TenApp.Split(' ')[0]).Trim(); $Shell = New-Object -ComObject Shell.Application
        foreach ($Win in $Shell.Windows()) { if ($Win.Name -match "Explorer" -and $Win.LocationName -match "(?i)$TuKhoa") { $Win.Quit() } }
        Stop-Process -Name notepad -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ------------------------------------------------------------------------------
# 5. GIAO DIỆN WPF - APP STORE HORIZONTAL LAYOUT (WITH GROUPING)
# ------------------------------------------------------------------------------
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V700" Width="1050" Height="700" MinWidth="850" MinHeight="500" WindowStartupLocation="CenterScreen" Background="#020617" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome><WindowChrome GlassFrameThickness="0" CornerRadius="12" CaptionHeight="45" ResizeBorderThickness="8"/></WindowChrome.WindowChrome>
    <Border BorderBrush="#1E293B" BorderThickness="1.5" CornerRadius="12">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="45"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="260"/> <ColumnDefinition Width="*"/>   </Grid.ColumnDefinitions>
            
            <Border Grid.Row="0" Grid.ColumnSpan="2" Background="#020617" Name="TitleBar">
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="45"/><ColumnDefinition Width="45"/><ColumnDefinition Width="45"/></Grid.ColumnDefinitions>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="20,0,0,0">
                        <TextBlock Text="⚡ VIETTOOLBOX" Foreground="#38BDF8" FontWeight="Black" FontSize="16" Margin="0,0,5,0"/>
                        <TextBlock Text="V700 DASHBOARD" Foreground="#94A3B8" FontWeight="Bold" FontSize="16"/>
                    </StackPanel>
                    <Button Name="btnMin" Grid.Column="1" Content="—" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#94A3B8" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                    <Button Name="btnMax" Grid.Column="2" Content="⬜" Background="Transparent" BorderThickness="0" FontSize="14" Foreground="#94A3B8" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                    <Button Name="btnClose" Grid.Column="3" Content="✕" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#EF4444" FontWeight="Bold" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                </Grid>
            </Border>

            <Border Grid.Row="1" Grid.Column="0" Background="#0F172A" BorderBrush="#1E293B" BorderThickness="0,1,1,0" CornerRadius="0,0,0,11">
                <StackPanel Margin="20,25,20,20">
                    <TextBlock Text="LỰA CHỌN" Foreground="#64748B" FontSize="12" FontWeight="Bold" Margin="0,0,0,10"/>
                    <Button Name="btnAll" Content="☑ Chọn tất cả" Height="40" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" Foreground="#F8FAFC" FontWeight="Bold" Margin="0,0,0,10" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button Name="btnNone" Content="☐ Bỏ chọn hết" Height="40" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" Foreground="#F8FAFC" FontWeight="Bold" Margin="0,0,0,25" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>

                    <TextBlock Text="ĐIỀU KHIỂN" Foreground="#64748B" FontSize="12" FontWeight="Bold" Margin="0,0,0,10"/>
                    <Button Name="btnRun" Content="▶ BẮT ĐẦU" Height="45" Background="#10B981" BorderThickness="0" Foreground="White" FontWeight="Black" FontSize="14" Margin="0,0,0,10" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="btnPause" Content="⏸ TẠM DỪNG" Height="40" Background="#F59E0B" BorderThickness="0" Foreground="White" FontWeight="Bold" Margin="0,0,0,10" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="btnResume" Content="⏯ TIẾP TỤC" Height="40" Background="#3B82F6" BorderThickness="0" Foreground="White" FontWeight="Bold" Margin="0,0,0,10" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="btnStop" Content="⏹ HỦY BỎ" Height="40" Background="#EF4444" BorderThickness="0" Foreground="White" FontWeight="Bold" Margin="0,0,0,10" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                </StackPanel>
            </Border>

            <Border Grid.Row="1" Grid.Column="1" Background="#1E293B" BorderBrush="#1E293B" BorderThickness="0,1,0,0" CornerRadius="0,0,11,0">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Background="Transparent" Margin="5">
                    <ItemsControl Name="ListApp">
                        <ItemsControl.GroupStyle>
                            <GroupStyle>
                                <GroupStyle.HeaderTemplate>
                                    <DataTemplate>
                                        <Border BorderThickness="0,0,0,1" BorderBrush="#334155" Margin="15,20,15,5" Padding="0,0,0,8">
                                            <TextBlock Text="{Binding Name}" Foreground="#38BDF8" FontSize="16" FontWeight="Black"/>
                                        </Border>
                                    </DataTemplate>
                                </GroupStyle.HeaderTemplate>
                                <GroupStyle.Panel>
                                    <ItemsPanelTemplate>
                                        <WrapPanel Orientation="Horizontal" Margin="5,0,5,10"/>
                                    </ItemsPanelTemplate>
                                </GroupStyle.Panel>
                            </GroupStyle>
                        </ItemsControl.GroupStyle>
                        
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <Border Width="235" Height="90" Background="#0F172A" CornerRadius="8" Margin="8" BorderBrush="#334155" BorderThickness="1">
                                    <Grid Margin="10">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="45"/>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="25"/>
                                        </Grid.ColumnDefinitions>
                                        
                                        <Image Grid.Column="0" Source="{Binding IconURL}" Width="36" Height="36" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                                        
                                        <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="10,0,5,0">
                                            <TextBlock Text="{Binding Ten}" Foreground="#F8FAFC" FontSize="13" FontWeight="Bold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Ten}"/>
                                            <TextBlock Text="{Binding TrangThai}" Foreground="#38BDF8" FontSize="11" FontWeight="SemiBold" Margin="0,5,0,5" TextTrimming="CharacterEllipsis"/>
                                            <ProgressBar Value="{Binding TienTrinh}" Height="4" Background="#1E293B" Foreground="#10B981" BorderThickness="0">
                                                <ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="2"/></Style></ProgressBar.Resources>
                                            </ProgressBar>
                                        </StackPanel>
                                        
                                        <CheckBox Grid.Column="2" IsChecked="{Binding Chon, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Top" HorizontalAlignment="Right" Margin="0,2,0,0"/>
                                    </Grid>
                                </Border>
                            </DataTemplate>
                        </ItemsControl.ItemTemplate>
                    </ItemsControl>
                </ScrollViewer>
            </Border>
        </Grid>
    </Border>
</Window>
"@
$Win = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$Xaml))
$DanhSachApp = New-Object System.Collections.ObjectModel.ObservableCollection[Object]

# Khởi tạo Grouping (Phân nhóm danh mục)
$CollectionView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($DanhSachApp)
$GroupDescription = New-Object System.Windows.Data.PropertyGroupDescription("DanhMuc")
$CollectionView.GroupDescriptions.Add($GroupDescription)
$Win.FindName("ListApp").ItemsSource = $CollectionView

# ------------------------------------------------------------------------------
# 6. QUẢN LÝ SỰ KIỆN NÚT BẤM
# ------------------------------------------------------------------------------
$Win.FindName("TitleBar").Add_MouseLeftButtonDown({ $Win.DragMove() })
$Win.FindName("btnClose").Add_Click({ $Win.Close() })
$Win.FindName("btnMin").Add_Click({ $Win.WindowState = "Minimized" })
$Win.FindName("btnMax").Add_Click({ if ($Win.WindowState -eq "Normal") { $Win.WindowState = "Maximized" } else { $Win.WindowState = "Normal" } })
$Win.FindName("btnAll").Add_Click({ foreach ($p in $DanhSachApp) {$p.Chon=$true} })
$Win.FindName("btnNone").Add_Click({ foreach ($p in $DanhSachApp) {$p.Chon=$false} })

$BtnRun = $Win.FindName("btnRun"); $BtnPause = $Win.FindName("btnPause"); $BtnResume = $Win.FindName("btnResume"); $BtnStop = $Win.FindName("btnStop")

function CapNhat-NutDieuKhien ($TrangThai) {
    if ($TrangThai -eq "DangChay") { $BtnRun.IsEnabled=$false; $BtnPause.IsEnabled=$true; $BtnResume.IsEnabled=$false; $BtnStop.IsEnabled=$true }
    elseif ($TrangThai -eq "TamDung") { $BtnRun.IsEnabled=$false; $BtnPause.IsEnabled=$false; $BtnResume.IsEnabled=$true; $BtnStop.IsEnabled=$true }
    elseif ($TrangThai -eq "NhanhRoi") { $BtnRun.IsEnabled=$true; $BtnPause.IsEnabled=$false; $BtnResume.IsEnabled=$false; $BtnStop.IsEnabled=$false }
    elseif ($TrangThai -eq "DangHuy") { $BtnRun.IsEnabled=$false; $BtnPause.IsEnabled=$false; $BtnResume.IsEnabled=$false; $BtnStop.IsEnabled=$false }
}

$BtnPause.Add_Click({ $Global:TrangThaiHeThong = "TamDung"; CapNhat-NutDieuKhien "TamDung" })
$BtnResume.Add_Click({ $Global:TrangThaiHeThong = "DangChay"; CapNhat-NutDieuKhien "DangChay" })
$BtnStop.Add_Click({ $Global:TrangThaiHeThong = "DungLai"; CapNhat-NutDieuKhien "DangHuy"; $BtnStop.Content = "ĐANG HỦY..." })

# ------------------------------------------------------------------------------
# 7. LÕI MẠNG CHỐNG TREO TUYỆT ĐỐI (ASYNC POLLING CORE)
# ------------------------------------------------------------------------------
try {
    $Handler = New-Object System.Net.Http.HttpClientHandler
    $Handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
    $Handler.AllowAutoRedirect = $true 
    $Global:HttpClient = New-Object System.Net.Http.HttpClient($Handler)
} catch {
    $Global:HttpClient = New-Object System.Net.Http.HttpClient
}

$Global:HttpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")
$Global:HttpClient.DefaultRequestHeaders.Add("Accept", "*/*")
$Global:HttpClient.Timeout = [System.TimeSpan]::FromSeconds(60)

function XuLy-MotPhanMem ($App) {
    $App.TrangThai = "Chuẩn bị..."; $App.TienTrinh = 5; [System.Windows.Forms.Application]::DoEvents()
    
    $DriveId = ""; if ($App.Url -match "id=([^&]+)") {$DriveId=$Matches[1]} elseif ($App.Url -match "/d/([^/]+)") {$DriveId=$Matches[1]}
    $DuoiMoRong = ".exe"
    
    if ($App.Ten -match "(?i)WhatsApp|Store" -or $App.Url -match "(?i)\.msixbundle|\.appx") { $DuoiMoRong = ".msixbundle" }
    elseif ($App.Ten -match "(?i)Unikey|EVKey|WeChat|Portable" -or $App.Url -match "(?i)\.zip") { $DuoiMoRong = ".zip" }
    elseif ($App.Url -match "(?i)\.msi") { $DuoiMoRong = ".msi" }
    
    $DuongDanFileLuu = Join-Path $Global:ThuMucTaiVe "$($App.Ten -replace '[\\/:\*\?"<>\|]', '')$DuoiMoRong"
    $TaiThanhCong = $false
    
    $DanhSachLinkThu = @()
    if ($DriveId) { foreach ($KeyAPI in $Global:DanhSachAPI) { $DanhSachLinkThu += "https://www.googleapis.com/drive/v3/files/$($DriveId)?alt=media&key=$KeyAPI&acknowledgeAbuse=true" } }
    $DanhSachLinkThu += $App.Url 

    $SoThuTuLink = 1; $TongLink = $DanhSachLinkThu.Count

    foreach ($UrlTai in $DanhSachLinkThu) {
        if ($Global:TrangThaiHeThong -eq "DungLai") { break }
        try {
            $App.TrangThai = "Kết nối ($SoThuTuLink/$TongLink)..."; [System.Windows.Forms.Application]::DoEvents()
            
            $TaskGet = $Global:HttpClient.GetAsync($UrlTai, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
            
            while (-not $TaskGet.IsCompleted) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 30
                if ($Global:TrangThaiHeThong -eq "DungLai") { break }
            }
            if ($Global:TrangThaiHeThong -eq "DungLai") { break }
            if ($TaskGet.IsFaulted -or $TaskGet.IsCanceled) { $SoThuTuLink++; continue }
            
            $Response = $TaskGet.Result
            if (-not $Response.IsSuccessStatusCode) { $SoThuTuLink++; continue }
            
            $TongDungLuong = $Response.Content.Headers.ContentLength
            if ($null -ne $TongDungLuong -and $TongDungLuong -lt 1MB -and $UrlTai -match "googleapis") { $SoThuTuLink++; continue }
            
            $InStream = $Response.Content.ReadAsStreamAsync().Result
            $OutStream = New-Object System.IO.FileStream($DuongDanFileLuu, [System.IO.FileMode]::Create)
            
            $Buffer = New-Object byte[] 2097152 
            $DaTai = 0
            $DongHoUI = [System.Diagnostics.Stopwatch]::StartNew() 
            
            while (($SoByteDoc = $InStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
                while ($Global:TrangThaiHeThong -eq "TamDung") { Start-Sleep -Milliseconds 200; [System.Windows.Forms.Application]::DoEvents() }
                if ($Global:TrangThaiHeThong -eq "DungLai") { break }
                
                $OutStream.Write($Buffer, 0, $SoByteDoc); $DaTai += $SoByteDoc
                
                if ($DongHoUI.ElapsedMilliseconds -ge 100) {
                    if ($null -ne $TongDungLuong -and $TongDungLuong -gt 0) { 
                        $App.TienTrinh = [math]::Round(($DaTai/$TongDungLuong)*100)
                        $App.TrangThai = "$($App.TienTrinh)%"
                    } else {
                        $DaTaiMB = [math]::Round($DaTai / 1MB, 1)
                        $App.TrangThai = "$DaTaiMB MB"
                        if ($App.TienTrinh -lt 95) { $App.TienTrinh += 1 } 
                    }
                    [System.Windows.Forms.Application]::DoEvents()
                    $DongHoUI.Restart()
                }
            }
            
            if ($null -ne $TongDungLuong -and $TongDungLuong -gt 0 -and $Global:TrangThaiHeThong -ne "DungLai") { 
                $App.TienTrinh = 100; $App.TrangThai = "Tải xong!"; [System.Windows.Forms.Application]::DoEvents() 
            }
            
            $OutStream.Close(); $InStream.Close(); 
            if ($Global:TrangThaiHeThong -ne "DungLai") { $TaiThanhCong = $true; break }
        } catch { if ($OutStream) { $OutStream.Close() }; $SoThuTuLink++ }
    }

    if (-not $TaiThanhCong -and $Global:TrangThaiHeThong -ne "DungLai") { $App.TrangThai = "Lỗi mạng!"; $App.TienTrinh = 0; return }
    if ($Global:TrangThaiHeThong -eq "DungLai") { $App.TrangThai = "Đã Hủy"; $App.TienTrinh = 0; return }

    # 7.3 BẮT ĐẦU CÀI ĐẶT
    Unblock-File -Path $DuongDanFileLuu; $App.TienTrinh = 50; [System.Windows.Forms.Application]::DoEvents()

    if ($DuoiMoRong -eq ".msixbundle") {
        $App.TrangThai = "Đang cài đặt..."; [System.Windows.Forms.Application]::DoEvents()
        try { Add-AppxPackage -Path $DuongDanFileLuu -ErrorAction Stop; $App.TrangThai = "Hoàn tất"; $App.TienTrinh = 100 } 
        catch { $App.TrangThai = "Lỗi Win"; $App.TienTrinh = 0 }
    }
    elseif ($DuoiMoRong -eq ".zip") {
        $App.TrangThai = "Giải nén..."; [System.Windows.Forms.Application]::DoEvents()
        $ThuMucGiaiNen = "C:\$($App.Ten -replace ' ', '')"
        $MatKhau = "Admin@2512"
        
        # TÌM HOẶC TẢI 7-ZIP (HỖ TRỢ GIẢI NÉN CÓ PASS)
        $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
        $7zaTemp = Join-Path $env:TEMP "7za.exe"
        $Exe7z = $null

        if (Test-Path $7zPath) { $Exe7z = $7zPath }
        elseif (Test-Path $7zaTemp) { $Exe7z = $7zaTemp }
        else {
            try { 
                $App.TrangThai = "Đang tải 7z..."; [System.Windows.Forms.Application]::DoEvents()
                Invoke-WebRequest -Uri "https://github.com/develar/7zip-bin/raw/master/win/x64/7za.exe" -OutFile $7zaTemp -UseBasicParsing -ErrorAction SilentlyContinue
                if (Test-Path $7zaTemp) { $Exe7z = $7zaTemp }
            } catch {}
        }

        # THỰC THI GIẢI NÉN
        if ($Exe7z) {
            $App.TrangThai = "Giải nén (Pass)..."; [System.Windows.Forms.Application]::DoEvents()
            $TienTrinh7z = Start-Process -FilePath $Exe7z -ArgumentList "x `"$DuongDanFileLuu`" -p`"$MatKhau`" -o`"$ThuMucGiaiNen`" -y" -Wait -NoNewWindow -PassThru
        } else {
            # Fallback nếu tải 7z thất bại (sẽ không bung được nếu file có pass thực sự)
            Expand-Archive -Path $DuongDanFileLuu -DestinationPath $ThuMucGiaiNen -Force -ErrorAction SilentlyContinue
        }
        
        if ($Global:TrangThaiHeThong -eq "DungLai") { return }
        $FileExeChinh = Tim-ExeRadar -ThuMucGoc $ThuMucGiaiNen -TenApp $App.Ten
        if ($FileExeChinh) { Tao-ShortcutChuan -TenApp $App.Ten -DuongDanExe $FileExeChinh }
        $App.TrangThai = "Hoàn tất"; $App.TienTrinh = 100
    }
   else {
        # 1. XỬ LÝ THAM SỐ THÔNG MINH
        $ThamSoCai = $App.Args
        if ($App.Ten -match "(?i)Foxit") { $ThamSoCai = "/quiet /force /lang en" } 
        elseif ($App.Ten -match "(?i)Zoom") { $ThamSoCai = "/S /ZNoAutoStart" } # Chặn Zoom tự mở
        elseif ($App.Ten -match "(?i)Wechat") { $ThamSoCai = "/S" }
        
        if (-not $ThamSoCai) { $ThamSoCai = "/S" }

        # 2. KHỞI CHẠY TIẾN TRÌNH
        if ($DuoiMoRong -eq ".msi") { 
            $TienTrinhCaiDat = Start-Process "msiexec.exe" -ArgumentList "/i `"$DuongDanFileLuu`" /quiet /norestart" -PassThru 
        } else { 
            $TienTrinhCaiDat = Start-Process $DuongDanFileLuu -ArgumentList $ThamSoCai -PassThru 
        }
        
        if ($TienTrinhCaiDat) {
            $ThoiGianCho = 0
            $ThoiGianToiDa = 300000 # 5 phút

            while ((Get-Process -Id $TienTrinhCaiDat.Id -ErrorAction SilentlyContinue)) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 500
                $ThoiGianCho += 500
                
                if ($ThoiGianCho % 1000 -eq 0) {
                    $SoGiay = $ThoiGianCho / 1000
                    $App.TrangThai = "Cài đặt ($SoGiay s)"
                    if ($App.TienTrinh -lt 90) { $App.TienTrinh += 1 }
                    [System.Windows.Forms.Application]::DoEvents()

                    # --- CƠ CHẾ QUÉT THỰC TẾ (SMART CHECK) ---
                    # Nếu đã cài quá 15s, bắt đầu quét xem file EXE của App đã xuất hiện chưa
                    if ($SoGiay -gt 15) {
                        $CheckExe = $null
                        $TuKhoa = $App.Ten.Split(' ')[0]
                        # Quét nhanh trong Program Files
                        $Paths = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)
                        foreach ($P in $Paths) {
                            if (Test-Path "$P\*$TuKhoa*\*.exe") { $CheckExe = $true; break }
                        }

                        if ($CheckExe) {
                            # Nếu thấy file EXE xuất hiện, đợi thêm 3s cho chắc rồi ngắt tiến trình mẹ
                            Start-Sleep -Seconds 3
                            try { Stop-Process -Id $TienTrinhCaiDat.Id -Force -ErrorAction SilentlyContinue } catch {}
                            break 
                        }
                    }
                }

                # Xử lý Timeout hoặc Nhấn Dừng
                if ($ThoiGianCho -ge $ThoiGianToiDa) {
                    try { Stop-Process -Id $TienTrinhCaiDat.Id -Force -ErrorAction SilentlyContinue } catch {}
                    $App.TrangThai = "Hoàn tất (T)"; break # Coi như xong nếu quá lâu
                }
                if ($Global:TrangThaiHeThong -eq "DungLai") {
                    try { Stop-Process -Id $TienTrinhCaiDat.Id -Force -ErrorAction SilentlyContinue } catch {}
                    $App.TrangThai = "Đã Hủy"; return
                }
            }
        }
        
        # 3. DỌN DẸP VÀ TẠO SHORTCUT
        Dong-CuaSoBungKem -TenApp $App.Ten
        $App.TrangThai = "Hoàn tất"; $App.TienTrinh = 100
        
        # Tìm lại file EXE chính xác để tạo Shortcut
        $TuKhoaTimKiem = $App.Ten.Split(' ')[0]
        $DanhSachVungQuet = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA, $env:APPDATA)
        $FileExeChinh = $null
        foreach ($Vung in $DanhSachVungQuet) {
            $ThuMucCha = Get-ChildItem $Vung -Directory -Filter "*$TuKhoaTimKiem*" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($ThuMucCha) { $FileExeChinh = Tim-ExeRadar -ThuMucGoc $ThuMucCha.FullName -TenApp $App.Ten; if ($FileExeChinh) { break } }
        }
        if ($FileExeChinh) { Tao-ShortcutChuan -TenApp $App.Ten -DuongDanExe $FileExeChinh }
    }
}

# ------------------------------------------------------------------------------
# 8. VÒNG LẶP HỆ THỐNG
# ------------------------------------------------------------------------------
$BtnRun.Add_Click({
    $Global:TrangThaiHeThong = "DangChay"; CapNhat-NutDieuKhien "DangChay"
    
    foreach ($App in $DanhSachApp) { if ($App.Chon -and $Global:TrangThaiHeThong -ne "DungLai") { XuLy-MotPhanMem $App } }

    if ($Global:TrangThaiHeThong -ne "DungLai") {
        $BtnRun.Content = "🧹 ĐANG DỌN RÁC..."; [System.Windows.Forms.Application]::DoEvents()
        try { if (Test-Path $Global:ThuMucTaiVe) { Get-ChildItem -Path $Global:ThuMucTaiVe -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue } } catch {}
        Start-Sleep -Seconds 1; $BtnRun.Content = "▶ CHẠY LẠI?"
    } else { $BtnRun.Content = "▶ CHẠY LẠI?" }

    $BtnStop.Content = "⏹ HỦY BỎ"; $Global:TrangThaiHeThong = "NhanhRoi"; CapNhat-NutDieuKhien "NhanhRoi"
})

# ------------------------------------------------------------------------------
# 9. KHỞI CHẠY GIAO DIỆN
# ------------------------------------------------------------------------------
try {
    $DuLieuCsv = (Invoke-RestMethod $Global:DuongDanCsv -UseBasicParsing) | ConvertFrom-Csv
    foreach ($Dong in $DuLieuCsv) { 
        if ($Dong.DownloadUrl) {
            $IconMacDinh = $Dong.IconURL; if (-not $IconMacDinh) { $IconMacDinh = "https://cdn-icons-png.flaticon.com/512/2589/2589174.png" }
            
            # Đọc cột Category/DanhMuc từ file CSV. Nếu không có tự cho vào "Phần mềm chung"
            $PhanLoai = if ($Dong.Category) { $Dong.Category } elseif ($Dong.DanhMuc) { $Dong.DanhMuc } else { "Phần mềm chung" }

            $DanhSachApp.Add([PhanMemModel]@{
                Chon=($Dong.Check -match "True"); 
                Ten=$Dong.Name; 
                IconURL=$IconMacDinh; 
                Url=$Dong.DownloadUrl; 
                Args=$Dong.SilentArgs; 
                TrangThai="Đang chờ"; 
                TienTrinh=0;
                DanhMuc=$PhanLoai
            }) 
        } 
    }
} catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải danh sách phần mềm từ mạng!", "Cảnh báo", 0, 16) }

try { $Win.ShowDialog() | Out-Null } catch {}