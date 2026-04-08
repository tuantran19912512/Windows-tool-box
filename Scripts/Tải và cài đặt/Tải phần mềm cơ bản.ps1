# ==============================================================================
# VIETTOOLBOX AUTO-INSTALLER V500 - THE ARCHITECT EDITION
# Tác giả: Tối ưu hóa toàn diện cho Kỹ Thuật Viên.
# Cốt lõi: Xoay API, Radar Shortcut 4 Lớp, Non-Blocking UI, Auto Cleanup.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. THIẾT LẬP MÔI TRƯỜNG & PHÂN QUYỀN
# ------------------------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# ------------------------------------------------------------------------------
# 2. CẤU HÌNH BIẾN TOÀN CỤC & TÀI NGUYÊN
# ------------------------------------------------------------------------------
$Global:DuongDanCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$Global:ThuMucTaiVe = Join-Path $env:PUBLIC "LuuTruPhanMem"
$Global:TrangThaiHeThong = "NhanhRoi" # Trạng thái: NhanhRoi, DangChay, TamDung, DungLai

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
# 3. LỚP DỮ LIỆU BINDING (MODEL)
# ------------------------------------------------------------------------------
if (-not ("PhanMemModel" -as [type])) {
    $CodeClass = @"
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
    }
"@
    Add-Type -TypeDefinition $CodeClass -Language CSharp
}

# ------------------------------------------------------------------------------
# 4. MODULE CỐT LÕI (SHORTCUT & TÌM KIẾM FILE)
# ------------------------------------------------------------------------------
function Tao-ShortcutChuan ($TenApp, $DuongDanExe) {
    try {
        $DesktopPath = [Environment]::GetFolderPath("Desktop")
        $FileShortcut = Join-Path $DesktopPath (($TenApp -replace '[\\/:\*\?"<>\|]', '') + ".lnk")
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($FileShortcut)
        $Shortcut.TargetPath = $DuongDanExe
        $Shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($DuongDanExe)
        $Shortcut.IconLocation = "$DuongDanExe,0" # Ép lấy Icon chuẩn
        $Shortcut.Save()
    } catch {}
}

function Tim-ExeRadar ($ThuMucGoc, $TenApp) {
    $TuKhoa = ($TenApp.Split(' ')[0]).Trim()
    $BoLocRac = "unins|setup|update|agent|crash|codec|report|fix"
    $BoLocThuMuc = "\[.*\]"

    # Lớp 1: Khớp tên chính xác ở mặt tiền
    $Exe = Get-ChildItem $ThuMucGoc -Filter "$TuKhoa.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($Exe) { return $Exe.FullName }
    
    # Lớp 2: Bất kỳ file exe nào ở mặt tiền (Né rác)
    $Exe = Get-ChildItem $ThuMucGoc -Filter "*.exe" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch $BoLocRac } | Sort-Object Length -Descending | Select-Object -First 1
    if ($Exe) { return $Exe.FullName }
    
    # Lớp 3: Khớp tên chính xác sâu 1 tầng (Né thư mục Version)
    $Exe = Get-ChildItem $ThuMucGoc -Filter "$TuKhoa.exe" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -notmatch $BoLocThuMuc } | Select-Object -First 1
    if ($Exe) { return $Exe.FullName }
    
    # Lớp 4: Bất kỳ file exe nặng nhất sâu 1 tầng
    $Exe = Get-ChildItem $ThuMucGoc -Filter "*.exe" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch $BoLocRac -and $_.DirectoryName -notmatch $BoLocThuMuc } | Sort-Object Length -Descending | Select-Object -First 1
    if ($Exe) { return $Exe.FullName }
    
    return $null
}
function Dong-CuaSoBungKem ($TenApp) {
    try {
        # Lấy từ khóa là chữ đầu tiên của tên App (VD: "Chi" trong "Chi Dung Fonts")
        $TuKhoa = ($TenApp.Split(' ')[0]).Trim() 
        
        # Dùng Shell Application để tìm đúng cái cửa sổ thư mục vừa bật lên
        $Shell = New-Object -ComObject Shell.Application
        foreach ($Win in $Shell.Windows()) {
            if ($Win.Name -match "Explorer" -and $Win.LocationName -match "(?i)$TuKhoa") {
                $Win.Quit() # Đóng cái thư mục đó lại nhẹ nhàng
            }
        }
        
        # Tiện tay đập luôn mấy cái file Readme (Notepad) nếu nó dám tự mở
        Stop-Process -Name notepad -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ------------------------------------------------------------------------------
# 5. GIAO DIỆN WPF (CO GIÃN & THẨM MỸ)
# ------------------------------------------------------------------------------
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V500" Width="1000" Height="750" MinWidth="850" MinHeight="600" WindowStartupLocation="CenterScreen" Background="#F8FAFC" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome>
        <WindowChrome GlassFrameThickness="0" CornerRadius="12" CaptionHeight="50" ResizeBorderThickness="8"/>
    </WindowChrome.WindowChrome>
    <Border BorderBrush="#CBD5E1" BorderThickness="1.5" CornerRadius="12">
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="50"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="90"/></Grid.RowDefinitions>
            
            <Border Grid.Row="0" Background="#0F172A" CornerRadius="11,11,0,0" Name="TitleBar">
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="45"/><ColumnDefinition Width="45"/><ColumnDefinition Width="45"/></Grid.ColumnDefinitions>
                    <TextBlock Text="🚀 VIETTOOLBOX V500 - THE ARCHITECT EDITION" Foreground="White" VerticalAlignment="Center" FontWeight="Bold" FontSize="16" Margin="20,0,0,0"/>
                    <Button Name="btnMin" Grid.Column="1" Content="—" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#94A3B8" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                    <Button Name="btnMax" Grid.Column="2" Content="⬜" Background="Transparent" BorderThickness="0" FontSize="14" Foreground="#94A3B8" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                    <Button Name="btnClose" Grid.Column="3" Content="✕" Background="Transparent" BorderThickness="0" FontSize="16" Foreground="#F87171" FontWeight="Bold" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True"/>
                </Grid>
            </Border>

            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="20,15,20,10">
                <Button Name="btnAll" Content="☑ Chọn tất cả" Width="130" Height="38" Margin="0,0,12,0" Background="#FFFFFF" BorderBrush="#E2E8F0" BorderThickness="1" Foreground="#334155" FontWeight="SemiBold" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                <Button Name="btnNone" Content="☐ Bỏ chọn" Width="130" Height="38" Background="#FFFFFF" BorderBrush="#E2E8F0" BorderThickness="1" Foreground="#334155" FontWeight="SemiBold" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
            </StackPanel>

            <Border Grid.Row="2" Margin="20,0,20,0" BorderBrush="#E2E8F0" BorderThickness="1" CornerRadius="8" Background="White">
                <DataGrid Name="dg" AutoGenerateColumns="False" CanUserAddRows="False" Background="Transparent" RowHeight="65" HeadersVisibility="Column" BorderThickness="0" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#F1F5F9" SelectionMode="Single">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader"><Setter Property="Background" Value="#F8FAFC"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Foreground" Value="#475569"/><Setter Property="Padding" Value="15,12"/><Setter Property="BorderThickness" Value="0,0,0,1"/><Setter Property="BorderBrush" Value="#E2E8F0"/></Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridCheckBoxColumn Header="Cài" Binding="{Binding Chon, UpdateSourceTrigger=PropertyChanged}" Width="65"><DataGridCheckBoxColumn.ElementStyle><Style TargetType="CheckBox"><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridCheckBoxColumn.ElementStyle></DataGridCheckBoxColumn>
                        <DataGridTemplateColumn Header="Biểu tượng" Width="90"><DataGridTemplateColumn.CellTemplate><DataTemplate><Image Source="{Binding IconURL}" Width="42" Height="42" Margin="5" VerticalAlignment="Center"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn>
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
                    <Button Name="btnRun" Content="▶ BẮT ĐẦU CÀI ĐẶT" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="btnPause" Content="⏸ TẠM DỪNG" Background="#F59E0B" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="btnResume" Content="⏯ TIẾP TỤC" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                    <Button Name="btnStop" Content="⏹ HỦY BỎ" Background="#EF4444" Foreground="White" FontWeight="Bold" FontSize="14" Margin="8,0" Cursor="Hand" IsEnabled="False"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources></Button>
                </UniformGrid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$Win = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$Xaml))
$DanhSachApp = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Win.FindName("dg").ItemsSource = $DanhSachApp

# ------------------------------------------------------------------------------
# 6. QUẢN LÝ SỰ KIỆN GIAO DIỆN (UI EVENTS)
# ------------------------------------------------------------------------------
$Win.FindName("TitleBar").Add_MouseLeftButtonDown({ $Win.DragMove() })
$Win.FindName("btnClose").Add_Click({ $Win.Close() })
$Win.FindName("btnMin").Add_Click({ $Win.WindowState = "Minimized" })
$Win.FindName("btnMax").Add_Click({ 
    if ($Win.WindowState -eq "Normal") { $Win.WindowState = "Maximized" } else { $Win.WindowState = "Normal" } 
})
$Win.FindName("btnAll").Add_Click({ foreach ($p in $DanhSachApp) {$p.Chon=$true} })
$Win.FindName("btnNone").Add_Click({ foreach ($p in $DanhSachApp) {$p.Chon=$false} })

$BtnRun = $Win.FindName("btnRun"); $BtnPause = $Win.FindName("btnPause"); $BtnResume = $Win.FindName("btnResume"); $BtnStop = $Win.FindName("btnStop")

function CapNhat-NutDieuKhien ($TrangThai) {
    if ($TrangThai -eq "DangChay") { $BtnRun.IsEnabled=$false; $BtnPause.IsEnabled=$true; $BtnResume.IsEnabled=$false; $BtnStop.IsEnabled=$true }
    elseif ($TrangThai -eq "TamDung") { $BtnRun.IsEnabled=$false; $BtnPause.IsEnabled=$false; $BtnResume.IsEnabled=$true; $BtnStop.IsEnabled=$true }
    elseif ($TrangThai -eq "NhanhRoi") { $BtnRun.IsEnabled=$true; $BtnPause.IsEnabled=$false; $BtnResume.IsEnabled=$false; $BtnStop.IsEnabled=$false }
}

$BtnPause.Add_Click({ $Global:TrangThaiHeThong = "TamDung"; CapNhat-NutDieuKhien "TamDung" })
$BtnResume.Add_Click({ $Global:TrangThaiHeThong = "DangChay"; CapNhat-NutDieuKhien "DangChay" })
$BtnStop.Add_Click({ $Global:TrangThaiHeThong = "DungLai"; CapNhat-NutDieuKhien "NhanhRoi" })

# ------------------------------------------------------------------------------
# 7. HỆ THỐNG XỬ LÝ CHÍNH (TẢI & CÀI ĐẶT)
# ------------------------------------------------------------------------------
function XuLy-MotPhanMem ($App) {
    $App.TrangThai = "Đang phân tích..."; $App.TienTrinh = 5; [System.Windows.Forms.Application]::DoEvents()
    
    # 7.1 Phân tích Link & Định dạng
    $DriveId = ""; if ($App.Url -match "id=([^&]+)") {$DriveId=$Matches[1]} elseif ($App.Url -match "/d/([^/]+)") {$DriveId=$Matches[1]}
    $DuoiMoRong = ".exe"
    
    if ($App.Ten -match "(?i)WhatsApp|Store" -or $App.Url -match "(?i)\.msixbundle|\.appx") { $DuoiMoRong = ".msixbundle" }
    elseif ($App.Ten -match "(?i)Unikey|EVKey|WeChat|Portable" -or $App.Url -match "(?i)\.zip") { $DuoiMoRong = ".zip" }
    elseif ($App.Url -match "(?i)\.msi") { $DuoiMoRong = ".msi" }
    
    $DuongDanFileLuu = Join-Path $Global:ThuMucTaiVe "$($App.Ten -replace '[\\/:\*\?"<>\|]', '')$DuoiMoRong"
    $TaiThanhCong = $false
    
    # 7.2 Tải File (Xoay API Google Drive / Direct Link)
    if ($DriveId) {
        foreach ($KeyAPI in $Global:DanhSachAPI) {
            try {
                $UrlDownload = "https://www.googleapis.com/drive/v3/files/$($DriveId)?alt=media&key=$KeyAPI"
                $Request = [System.Net.HttpWebRequest]::Create($UrlDownload); $Response = $Request.GetResponse()
                
                # Check Limit: Quota vượt quá sẽ trả JSON lỗi (<1MB)
                if ($Response.ContentLength -lt 1MB) { $Response.Close(); continue }

                $Stream = $Response.GetResponseStream(); $FileStream = New-Object System.IO.FileStream($DuongDanFileLuu, [System.IO.FileMode]::Create)
                $Buffer = New-Object byte[] 4MB; $TongDungLuong = $Response.ContentLength; $DaTai = 0
                
                do {
                    while ($Global:TrangThaiHeThong -eq "TamDung") { Start-Sleep -Milliseconds 200; [System.Windows.Forms.Application]::DoEvents() }
                    if ($Global:TrangThaiHeThong -eq "DungLai") { break }

                    $DocDuoc = $Stream.Read($Buffer, 0, $Buffer.Length)
                    if ($DocDuoc -gt 0) {
                        $FileStream.Write($Buffer, 0, $DocDuoc); $DaTai += $DocDuoc
                        if ($TongDungLuong -gt 0) { $App.TienTrinh = [math]::Round(($DaTai/$TongDungLuong)*100) }
                        $App.TrangThai = "Đang tải (API): $($App.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents()
                    }
                } while ($DocDuoc -gt 0)
                
                $FileStream.Close(); $Stream.Close(); $Response.Close()
                if ($Global:TrangThaiHeThong -eq "DungLai") { $App.TrangThai = "Đã Hủy ⛔"; $App.TienTrinh = 0; return }
                $TaiThanhCong = $true; break 
            } catch { if ($FileStream) {$FileStream.Close()} }
        }
    } else {
        try {
            $Request = [System.Net.HttpWebRequest]::Create($App.Url); $Response = $Request.GetResponse()
            $Stream = $Response.GetResponseStream(); $FileStream = New-Object System.IO.FileStream($DuongDanFileLuu, [System.IO.FileMode]::Create)
            $Buffer = New-Object byte[] 4MB; $TongDungLuong = $Response.ContentLength; $DaTai = 0
            
            do {
                while ($Global:TrangThaiHeThong -eq "TamDung") { Start-Sleep -Milliseconds 200; [System.Windows.Forms.Application]::DoEvents() }
                if ($Global:TrangThaiHeThong -eq "DungLai") { break }

                $DocDuoc = $Stream.Read($Buffer, 0, $Buffer.Length)
                if ($DocDuoc -gt 0) {
                    $FileStream.Write($Buffer, 0, $DocDuoc); $DaTai += $DocDuoc
                    if ($TongDungLuong -gt 0) { $App.TienTrinh = [math]::Round(($DaTai/$TongDungLuong)*100) }
                    $App.TrangThai = "Đang tải (Direct): $($App.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents()
                }
            } while ($DocDuoc -gt 0)
            
            $FileStream.Close(); $Stream.Close(); $Response.Close()
            if ($Global:TrangThaiHeThong -eq "DungLai") { $App.TrangThai = "Đã Hủy ⛔"; $App.TienTrinh = 0; return }
            $TaiThanhCong = $true
        } catch { if ($FileStream) {$FileStream.Close()} }
    }

    if (-not $TaiThanhCong -and $Global:TrangThaiHeThong -ne "DungLai") { $App.TrangThai = "❌ Lỗi mạng / API chết"; $App.TienTrinh = 0; return }
    if ($Global:TrangThaiHeThong -eq "DungLai") { return }

    # 7.3 Bắt đầu Cài Đặt
    Unblock-File -Path $DuongDanFileLuu; $App.TienTrinh = 50; [System.Windows.Forms.Application]::DoEvents()

    # Nhánh A: Windows Store App (MSIX)
    if ($DuoiMoRong -eq ".msixbundle") {
        $App.TrangThai = "⚡ Ép cài đặt hệ thống..."; [System.Windows.Forms.Application]::DoEvents()
        try { Add-AppxPackage -Path $DuongDanFileLuu -ErrorAction Stop; $App.TrangThai = "Hoàn tất ✔️"; $App.TienTrinh = 100 } 
        catch { $App.TrangThai = "❌ Lỗi Win cũ"; $App.TienTrinh = 0 }
    }
    # Nhánh B: Portable Software (ZIP)
    elseif ($DuoiMoRong -eq ".zip") {
        $App.TrangThai = "📦 Đang bung lụa (Xả nén)..."; [System.Windows.Forms.Application]::DoEvents()
        $ThuMucGiaiNen = "C:\$($App.Ten -replace ' ', '')"
        Expand-Archive -Path $DuongDanFileLuu -DestinationPath $ThuMucGiaiNen -Force -ErrorAction SilentlyContinue
        
        if ($Global:TrangThaiHeThong -eq "DungLai") { return }
        
        $FileExeChinh = Tim-ExeRadar -ThuMucGoc $ThuMucGiaiNen -TenApp $App.Ten
        if ($FileExeChinh) { Tao-ShortcutChuan -TenApp $App.Ten -DuongDanExe $FileExeChinh }
        $App.TrangThai = "Hoàn tất ✔️"; $App.TienTrinh = 100
    }
    # Nhánh C: Installer Truyền Thống (EXE/MSI) - Chống Not Responding
    else {
        $App.TrangThai = "🛠️ Đang thực thi cài đặt..."; [System.Windows.Forms.Application]::DoEvents()
        $ThamSoCai = $App.Args
        if ($App.Ten -match "(?i)Foxit") { $ThamSoCai = "/quiet /force /lang en" } elseif ($App.Ten -match "(?i)Wechat") { $ThamSoCai = "/S" }
        if (-not $ThamSoCai) { $ThamSoCai = "/S /silent /quiet /qn" }

        # Khởi chạy Tiến trình
        if ($DuoiMoRong -eq ".msi") { 
            $TienTrinhCaiDat = Start-Process "msiexec.exe" -ArgumentList "/i `"$DuongDanFileLuu`" /quiet /norestart" -PassThru 
        } else { 
            $TienTrinhCaiDat = Start-Process $DuongDanFileLuu -ArgumentList $ThamSoCai -PassThru 
        }
        
        # Vòng lặp Hô hấp nhân tạo cho UI
        if ($TienTrinhCaiDat) {
            while (-not $TienTrinhCaiDat.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 200
                
                # Cho phép ép chết bộ cài nếu bấm Hủy Bỏ
                if ($Global:TrangThaiHeThong -eq "DungLai") {
                    try { Stop-Process -Id $TienTrinhCaiDat.Id -Force -ErrorAction SilentlyContinue } catch {}
                    $App.TrangThai = "Đã Hủy ⛔"; $App.TienTrinh = 0; return
                }
            }
        }
        
        if ($Global:TrangThaiHeThong -eq "DungLai") { return }
        # --- GỌI SÁT THỦ ĐÓNG CỬA SỔ RÁC (THƯ MỤC / NOTEPAD) ---
        Dong-CuaSoBungKem -TenApp $App.Ten
        # Săn Shortcut sau cài đặt
        $TuKhoaTimKiem = $App.Ten.Split(' ')[0]; $DanhSachVungQuet = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA, $env:APPDATA)
        $FileExeChinh = $null
        foreach ($Vung in $DanhSachVungQuet) {
            $ThuMucCha = Get-ChildItem $Vung -Directory -Filter "*$TuKhoaTimKiem*" -Recurse -Depth 1 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($ThuMucCha) { $FileExeChinh = Tim-ExeRadar -ThuMucGoc $ThuMucCha.FullName -TenApp $App.Ten; if ($FileExeChinh) { break } }
        }
        if ($FileExeChinh) { Tao-ShortcutChuan -TenApp $App.Ten -DuongDanExe $FileExeChinh }
        
        $App.TrangThai = "Hoàn tất ✔️"; $App.TienTrinh = 100
    }
}

# ------------------------------------------------------------------------------
# 8. KÍCH HOẠT VÒNG LẶP CHÍNH & TỰ ĐỘNG DỌN RÁC
# ------------------------------------------------------------------------------
$BtnRun.Add_Click({
    $Global:TrangThaiHeThong = "DangChay"; CapNhat-NutDieuKhien "DangChay"
    $BtnRun.Content = "⏳ HỆ THỐNG ĐANG XỬ LÝ..."
    
    foreach ($App in $DanhSachApp) { 
        if ($App.Chon -and $Global:TrangThaiHeThong -ne "DungLai") { XuLy-MotPhanMem $App } 
    }

    # BƯỚC CUỐI: DỌN DẸP Ổ CỨNG SẠCH SẼ
    if ($Global:TrangThaiHeThong -ne "DungLai") {
        $BtnRun.Content = "🧹 ĐANG TỰ ĐỘNG DỌN RÁC..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            if (Test-Path $Global:ThuMucTaiVe) {
                Get-ChildItem -Path $Global:ThuMucTaiVe -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        } catch {}
        Start-Sleep -Seconds 1
        $BtnRun.Content = "▶ HOÀN THÀNH - CHẠY LẠI?"
    } else {
        $BtnRun.Content = "▶ ĐÃ HỦY - CHẠY LẠI?"
    }

    $Global:TrangThaiHeThong = "NhanhRoi"; CapNhat-NutDieuKhien "NhanhRoi"
})

# ------------------------------------------------------------------------------
# 9. KHỞI TẠO DỮ LIỆU VÀ CHẠY TOOL
# ------------------------------------------------------------------------------
try {
    $DuLieuCsv = (Invoke-RestMethod $Global:DuongDanCsv -UseBasicParsing) | ConvertFrom-Csv
    foreach ($Dong in $DuLieuCsv) { 
        if ($Dong.DownloadUrl) {
            $IconMacDinh = $Dong.IconURL
            if (-not $IconMacDinh) { $IconMacDinh = "https://cdn-icons-png.flaticon.com/512/2589/2589174.png" }
            $DanhSachApp.Add([PhanMemModel]@{Chon=($Dong.Check -match "True"); Ten=$Dong.Name; IconURL=$IconMacDinh; Url=$Dong.DownloadUrl; Args=$Dong.SilentArgs; TrangThai="Sẵn sàng"; TienTrinh=0}) 
        } 
    }
} catch { [System.Windows.Forms.MessageBox]::Show("Không thể tải danh sách phần mềm từ mạng!", "Lỗi Kết Nối", 0, 16) }

try { $Win.ShowDialog() | Out-Null } catch {}