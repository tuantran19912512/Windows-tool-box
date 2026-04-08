# ==============================================================================
# VIETTOOLBOX AUTO-INSTALLER V150 - COMPLETE EDITION
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc tính: Giải mã API, Tải Drive/Direct, Xử lý ZIP + EXE + MSI, Săn Shortcut sâu.
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# --- GIẢI MÃ API (BẢO MẬT) ---
function GiaiMa-API ($c) {
    $b = [System.Convert]::FromBase64String($c)
    return [System.Text.Encoding]::UTF8.GetString($b)
}

$Global:DanhSachAPI = @(
    (GiaiMa-API "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR"),
    (GiaiMa-API "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v"),
    (GiaiMa-API "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv"),
    (GiaiMa-API "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR"),
    (GiaiMa-API "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0")
)
$Global:KeyHienTai = 0
$Global:DuongDanCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$Global:ThuMucTaiVe = Join-Path $env:PUBLIC "LuuTruPhanMem"
$Global:TrangThaiHeThong = "NhanhRoi"

if (-not (Test-Path $Global:ThuMucTaiVe)) { New-Item -ItemType Directory -Path $Global:ThuMucTaiVe | Out-Null }

# --- NẠP CLASS (FIX LỖI) ---
if (-not ("PhanMem" -as [type])) {
    $m = @"
    using System;
    using System.ComponentModel;
    public class PhanMem : INotifyPropertyChanged {
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
    Add-Type -TypeDefinition $m -Language CSharp
}

# --- HÀM TẠO SHORTCUT (CHUẨN V148) ---
function Tao-Shortcut {
    param ($t, $g)
    try {
        $d = [Environment]::GetFolderPath("Desktop")
        # Đảm bảo tên shortcut sạch sẽ
        $TenLnk = ($t -replace '[\\/:\*\?"<>\|]', '') + ".lnk"
        $s = Join-Path $d $TenLnk
        
        $w = New-Object -ComObject WScript.Shell
        $b = $w.CreateShortcut($s)
        
        # PHẢI DÙNG ĐƯỜNG DẪN THÔ (KHÔNG BAO NHÁY TRONG TARGETPATH)
        $b.TargetPath = $g
        $b.WorkingDirectory = [System.IO.Path]::GetDirectoryName($g)
        
        # --- ĐOẠN QUAN TRỌNG NHẤT ĐỂ HIỆN HÌNH ---
        # Chỉ định IconLocation chính là file EXE, lấy index 0
        $b.IconLocation = "$g,0"
        
        $b.Save()
        
        # Ép Windows cập nhật lại giao diện Desktop để hiện Icon ngay
        $w.SendKeys('{F5}') 
    } catch {
        Write-Host "Loi tao Shortcut: $_" -ForegroundColor Red
    }
}

function Quet-Silent {
    param ($p)
    try {
        $f = [System.IO.File]::OpenRead($p); $b = New-Object byte[] 1MB; $r = $f.Read($b, 0, $b.Length); $f.Close()
        $s = [System.Text.Encoding]::ASCII.GetString($b, 0, $r)
        if ($s -match "Inno Setup") { return "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" }
        if ($s -match "Nullsoft" -or $s -match "NSIS") { return "/S" }
        if ($s -match "InstallShield") { return '/s /v"/qn"' }
        return "/silent /quiet /qn"
    } catch { return "/silent" }
}

# --- GIAO DIỆN WPF ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        Title="VietToolbox V136" Width="950" Height="700" MinWidth="850" MinHeight="600" 
        WindowStartupLocation="CenterScreen" Background="#F1F5F9" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome><WindowChrome GlassFrameThickness="0" CornerRadius="15" CaptionHeight="40" ResizeBorderThickness="8" /></WindowChrome.WindowChrome>
    <Border Background="#F1F5F9" CornerRadius="15" BorderBrush="#334155" BorderThickness="1.5">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="45"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="90"/> </Grid.RowDefinitions>

            <Grid Name="TitleBar" Grid.Row="0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="40"/><ColumnDefinition Width="40"/><ColumnDefinition Width="40"/></Grid.ColumnDefinitions>
                <TextBlock Text="🚀 HỆ THỐNG CÀI ĐẶT TỰ ĐỘNG - V136 ULTIMATE" Foreground="#334155" VerticalAlignment="Center" FontWeight="Bold" FontSize="18" Margin="10,0,0,0"/>
                <Button Name="btnMin" Grid.Column="1" Content="—" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#64748B" FontSize="16"/>
                <Button Name="btnMax" Grid.Column="2" Content="⬜" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#64748B" FontSize="14"/>
                <Button Name="btnClose" Grid.Column="3" Content="✕" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#EF4444" FontWeight="Bold" FontSize="16"/>
            </Grid>

            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,10,0,15">
                <Button Name="btnAll" Content="☑ Chọn hết" Width="120" Height="35" Background="#FFFFFF" BorderBrush="#CBD5E1" BorderThickness="1" Cursor="Hand" Margin="0,0,12,0">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
                <Button Name="btnNone" Content="☐ Bỏ chọn" Width="120" Height="35" Background="#FFFFFF" BorderBrush="#CBD5E1" BorderThickness="1" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>
            </StackPanel>

            <DataGrid Name="dg" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" 
                      SelectionMode="Single" BorderThickness="1" BorderBrush="#CBD5E1" 
                      Background="White" RowHeight="60" HeadersVisibility="Column" 
                      GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#F1F5F9">
                <DataGrid.Resources>
                    <Style TargetType="DataGridColumnHeader">
                        <Setter Property="Background" Value="#F8FAFC"/><Setter Property="FontWeight" Value="Bold"/>
                        <Setter Property="Foreground" Value="#475569"/><Setter Property="Padding" Value="10,12"/>
                        <Setter Property="BorderThickness" Value="0,0,0,1"/><Setter Property="BorderBrush" Value="#CBD5E1"/>
                    </Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                    <DataGridCheckBoxColumn Header="Cài" Binding="{Binding Chon, UpdateSourceTrigger=PropertyChanged}" Width="50">
                        <DataGridCheckBoxColumn.ElementStyle><Style TargetType="CheckBox"><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridCheckBoxColumn.ElementStyle>
                    </DataGridCheckBoxColumn>
                    
                    <DataGridTemplateColumn Header="Logo" Width="70">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate><Image Source="{Binding IconURL}" Width="38" Height="38" Stretch="Uniform" Margin="5" VerticalAlignment="Center" HorizontalAlignment="Center"/></DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>

                    <DataGridTextColumn Header="Tên phần mềm" Binding="{Binding Ten}" Width="*" FontWeight="SemiBold" Foreground="#1E293B">
                        <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="15,0,0,0"/></Style></DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>

                    <DataGridTemplateColumn Header="Trạng thái &amp; Tiến độ" Width="300">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate>
                                <Grid Margin="15,8">
                                    <ProgressBar Value="{Binding TienTrinh}" Height="24" Background="#F1F5F9" Foreground="#10B981" BorderThickness="0">
                                        <ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></ProgressBar.Resources>
                                    </ProgressBar>
                                    <TextBlock Text="{Binding TrangThai}" VerticalAlignment="Center" HorizontalAlignment="Center" FontSize="11" FontWeight="Bold" Foreground="#1E293B"/>
                                </Grid>
                            </DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                </DataGrid.Columns>
            </DataGrid>

            <Border Grid.Row="3" Background="#1E293B" CornerRadius="15" Margin="0,20,0,0">
                <UniformGrid Columns="4" Margin="10,0">
                    <Button Name="btnRun" Content="▶ BẮT ĐẦU" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="16" Margin="10" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                    <Button Name="btnPause" Content="⏸ TẠM DỪNG" Background="#F59E0B" Foreground="White" FontWeight="Bold" FontSize="14" Margin="10" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                    <Button Name="btnResume" Content="⏯ TIẾP TỤC" Background="#3B82F6" Foreground="White" FontWeight="Bold" FontSize="14" Margin="10" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                    <Button Name="btnStop" Content="⏹ DỪNG HẲN" Background="#EF4444" Foreground="White" FontWeight="Bold" FontSize="14" Margin="10" Cursor="Hand" IsEnabled="False">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
                    </Button>
                </UniformGrid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$win = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml))
$list = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$dg = $win.FindName("dg"); $dg.ItemsSource = $list
$win.FindName("TitleBar").Add_MouseLeftButtonDown({ $win.DragMove() })
$win.FindName("btnClose").Add_Click({ $win.Close() })
$win.FindName("btnMin").Add_Click({ $win.WindowState = "Minimized" })
$win.FindName("btnMax").Add_Click({ if ($win.WindowState -eq "Normal") {$win.WindowState="Maximized"} else {$win.WindowState="Normal"} })

# --- HÀM TẢI VÀ CÀI (XỬ LÝ ĐA LUỒNG + SĂN SHORTCUT) ---
function Tai-File ($obj) {
    $obj.TrangThai = "Đang kết nối..."
    $id = ""; if ($obj.Url -match "id=([^&]+)") {$id=$Matches[1]} elseif ($obj.Url -match "/d/([^/]+)") {$id=$Matches[1]}
    $ext = ".exe"; if ($obj.Url -match "\.zip") {$ext=".zip"} elseif ($obj.Url -match "\.msi") {$ext=".msi"}
    $path = Join-Path $Global:ThuMucTaiVe "$($obj.Ten -replace '[\\/:\*\?"<>\|]', '')$ext"
    
    $success = $false
    # 1. TẢI FILE
    if ($id) {
        foreach ($Key in $Global:DanhSachAPI) {
            try {
                $url = "https://www.googleapis.com/drive/v3/files/$($id)?alt=media&key=$Key"
                $req = [System.Net.HttpWebRequest]::Create($url); $res = $req.GetResponse()
                if ($res.ContentLength -lt 1MB) { $res.Close(); continue }
                $stm = $res.GetResponseStream(); $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Create)
                $buf = New-Object byte[] 4MB; $total = $res.ContentLength; $done = 0
                do {
                    $read = $stm.Read($buf, 0, $buf.Length)
                    if ($read -gt 0) { $fs.Write($buf, 0, $read); $done += $read; $obj.TienTrinh = [math]::Round(($done/$total)*100); $obj.TrangThai = "Drive: $($obj.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents() }
                } while ($read -gt 0)
                $fs.Close(); $stm.Close(); $res.Close(); $success = $true; break
            } catch { if ($fs) {$fs.Close()} }
        }
    } else {
        try {
            $req = [System.Net.HttpWebRequest]::Create($obj.Url); $res = $req.GetResponse()
            $stm = $res.GetResponseStream(); $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Create)
            $buf = New-Object byte[] 4MB; $total = $res.ContentLength; $done = 0
            do {
                $read = $stm.Read($buf, 0, $buf.Length)
                if ($read -gt 0) { $fs.Write($buf, 0, $read); $done += $read; if ($total -gt 0) {$obj.TienTrinh=[math]::Round(($done/$total)*100)}; $obj.TrangThai = "Direct: $($obj.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents() }
            } while ($read -gt 0)
            $fs.Close(); $stm.Close(); $res.Close(); $success = $true
        } catch { if ($fs) {$fs.Close()} }
    }

    # 2. XỬ LÝ SAU TẢI
    if ($success) {
        $obj.TrangThai = "🛠️ Đang cài đặt..."; $obj.TienTrinh = 40; [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Seconds 2
        
        $arg = $obj.Args
        if ($obj.Ten -match "Foxit") { $arg = "/quiet /force /lang en" }
        if (-not $arg) { $arg = Quet-Silent $path }

        # --- TRƯỜNG HỢP ZIP (EVKEY, UNIKEY...) ---
        if ($path -match "\.zip") {
            try {
                $obj.TrangThai = "📦 Đang xả nén..."; $obj.TienTrinh = 60; [System.Windows.Forms.Application]::DoEvents()
                $TenThuMuc = $obj.Ten -replace '[\\/:\*\?"<>\| ]', ''
                $dest = "C:\$TenThuMuc"
                Expand-Archive -Path $path -DestinationPath $dest -Force -ErrorAction SilentlyContinue
                
               # --- BỘ LỌC SHORTCUT THÔNG MINH V156 ---
				# Tìm tất cả file .exe nhưng loại bỏ mấy thằng "phá đám"
				$exe = Get-ChildItem $dest -Filter "*.exe" -Recurse | Where-Object { 
					$_.Name -notmatch "unins|setup|update|agent|crash|helper|install|setup|fix|report|driver" 
				} | Sort-Object Length -Descending | Select-Object -First 1

				if ($exe) { 
					Tao-Shortcut -t $obj.Ten -g $exe.FullName 
				}
            } catch {}
        } 
        # --- TRƯỜNG HỢP EXE/MSI ---
        else {
            if ($path -match "\.msi") { Start-Process "msiexec.exe" -ArgumentList "/i `"$path`" /quiet /norestart" -Wait }
            else { Start-Process $path -ArgumentList $arg -Wait }
            
            $obj.TrangThai = "🔍 Tạo Shortcut..."; $obj.TienTrinh = 85; [System.Windows.Forms.Application]::DoEvents()
            $key = $obj.Ten.Split(' ')[0]; $scan = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs")
            $best = $null; foreach ($khu in $scan) {
                $dir = Get-ChildItem $khu -Directory -Filter "*$key*" -ErrorAction SilentlyContinue | Select -First 1
                if ($dir) { $best = Get-ChildItem $dir.FullName -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Where {$_.Name -notmatch "unins|setup|update|agent"} | Sort Length -Descending | Select -First 1 }
                if ($best) {break}
            }
            if ($best) { Tao-Shortcut $obj.Ten $best.FullName }
        }
        $obj.TrangThai = "Hoàn tất ✔️"; $obj.TienTrinh = 100
    } else { $obj.TrangThai = "❌ Lỗi"; $obj.TienTrinh = 0 }
}

# --- NÚT BẤM VÀ NẠP DỮ LIỆU ---
$win.FindName("btnAll").Add_Click({ foreach ($p in $list) {$p.Chon=$true} })
$win.FindName("btnNone").Add_Click({ foreach ($p in $list) {$p.Chon=$false} })
$win.FindName("btnRun").Add_Click({
    $Global:TrangThaiHeThong = "DangChay"; $win.FindName("btnRun").IsEnabled=$false; $win.FindName("btnPause").IsEnabled=$true; $win.FindName("btnStop").IsEnabled=$true
    foreach ($p in $list) { if ($p.Chon -and $Global:TrangThaiHeThong -ne "DungLai") { Tai-File $p } }
    $Global:TrangThaiHeThong = "NhanhRoi"; $win.FindName("btnRun").IsEnabled=$true; $win.FindName("btnPause").IsEnabled=$false; $win.FindName("btnStop").IsEnabled=$false
})
$win.FindName("btnPause").Add_Click({ $Global:TrangThaiHeThong="TamDung"; $win.FindName("btnPause").IsEnabled=$false; $win.FindName("btnResume").IsEnabled=$true })
$win.FindName("btnResume").Add_Click({ $Global:TrangThaiHeThong="DangChay"; $win.FindName("btnPause").IsEnabled=$true; $win.FindName("btnResume").IsEnabled=$false })
$win.FindName("btnStop").Add_Click({ $Global:TrangThaiHeThong="DungLai" })

try {
    $csv = (Invoke-RestMethod $Global:DuongDanCsv -UseBasicParsing) | ConvertFrom-Csv
    foreach ($d in $csv) { if ($d.DownloadUrl) { $list.Add([PhanMem]@{Chon=($d.Check -match "True"); Ten=$d.Name; IconURL=$d.IconURL; Url=$d.DownloadUrl; Args=$d.SilentArgs; TrangThai="Sẵn sàng"; TienTrinh=0}) } }
} catch {}
$win.ShowDialog() | Out-Null