# ==============================================================================
# VIETTOOLBOX AUTO-INSTALLER V135 - ULTIMATE EDITION
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc tính: Giao diện Modern, API Google Drive 5 Keys, Tự động Silent, Săn Shortcut.
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# --- CẤU HÌNH HỆ THỐNG ---
$Global:DanhSachAPI = @(
    "AIzaSyCuJRBZL6gQO-uVN1eotxf2ZiMsmc-ljwQ",
    "AIzaSyBTaVdPviKiBrGBTVM-RTbUnuAGES4VrMo",
    "AIzaSyBB44CNjkGFGPJ8AiVZ1DqdRgss9078A8o",
    "AIzaSyCb3hMKQSNjkvlSJmIaLkXqSrlZVhSRM8Q",
    "AIzaSyCetIYVW4lBiT-7wO7MABhZSUCGJGZnA34"
)
$Global:KeyHienTai = 0
$Global:DuongDanCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
$Global:ThuMucTaiVe = Join-Path $env:PUBLIC "LuuTruPhanMem"
$Global:TrangThaiHeThong = "NhanhRoi" # NhanhRoi, DangChay, TamDung, DungLai

if (-not (Test-Path $Global:ThuMucTaiVe)) { New-Item -ItemType Directory -Path $Global:ThuMucTaiVe | Out-Null }

# --- LỚP DỮ LIỆU ĐIỀU KHIỂN GIAO DIỆN ---
$MaLopC = @"
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
if (-not ("PhanMem" -as [type])) {
    Add-Type -TypeDefinition $MaLopC -Language CSharp
}

# --- HÀM HỖ TRỢ HỆ THỐNG ---
function Tao-BieuTuongDesktop {
    param ($Ten, $Goc)
    try {
        $D = [Environment]::GetFolderPath("Desktop")
        $S = Join-Path $D "$($Ten -replace '[\\/:\*\?"<>\|]', '').lnk"
        $W = New-Object -ComObject WScript.Shell
        $B = $W.CreateShortcut($S)
        $B.TargetPath = $Goc
        $B.WorkingDirectory = [System.IO.Path]::GetDirectoryName($Goc)
        $B.Save()
    } catch {}
}

function Do-LenhSilent {
    param ($P)
    try {
        $F = [System.IO.File]::OpenRead($P); $B = New-Object byte[] 1048576; $R = $F.Read($B, 0, $B.Length); $F.Close()
        $T = [System.Text.Encoding]::ASCII.GetString($B, 0, $R)
        if ($T -match "Inno Setup") { return "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" }
        if ($T -match "Nullsoft" -or $T -match "NSIS") { return "/S" }
        if ($T -match "InstallShield") { return '/s /v"/qn"' }
        if ($T -match "WiX") { return "/quiet /norestart" }
    } catch {}
    return "/silent /quiet /qn"
}

# --- GIAO DIỆN WPF HIỆN ĐẠI ---
$X = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox V135" Width="950" Height="700" MinWidth="750" MinHeight="550" WindowStartupLocation="CenterScreen" Background="#F1F5F9" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome><WindowChrome GlassFrameThickness="0" CornerRadius="15" CaptionHeight="40" ResizeBorderThickness="8" /></WindowChrome.WindowChrome>
    <Border Background="#F1F5F9" CornerRadius="15" BorderBrush="#334155" BorderThickness="1.5">
        <Grid Margin="15">
            <Grid.RowDefinitions><RowDefinition Height="45"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="85"/></Grid.RowDefinitions>
            <Grid Name="TitleBar" Grid.Row="0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="40"/><ColumnDefinition Width="40"/><ColumnDefinition Width="40"/></Grid.ColumnDefinitions>
                <TextBlock Text="🚀 HỆ THỐNG CÀI ĐẶT TỰ ĐỘNG - V135 ULTIMATE" Foreground="#334155" VerticalAlignment="Center" FontWeight="Bold" FontSize="17" Margin="10,0,0,0"/>
                <Button Name="btnMin" Grid.Column="1" Content="—" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#64748B"/>
                <Button Name="btnMax" Grid.Column="2" Content="⬜" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#64748B"/>
                <Button Name="btnClose" Grid.Column="3" Content="✕" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#EF4444" FontWeight="Bold"/>
            </Grid>
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="5,10">
                <Button Name="btnAll" Content="☑ Chọn hết" Width="110" Height="32" Background="#E2E8F0" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0"/>
                <Button Name="btnNone" Content="☐ Bỏ chọn" Width="110" Height="32" Background="#E2E8F0" BorderThickness="0" Cursor="Hand"/>
            </StackPanel>
            <DataGrid Name="dg" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" SelectionMode="Single" BorderThickness="1" BorderBrush="#CBD5E1" Background="White" RowHeight="55" HeadersVisibility="Column">
                <DataGrid.Columns>
                    <DataGridCheckBoxColumn Header="Cài" Binding="{Binding Chon, UpdateSourceTrigger=PropertyChanged}" Width="50"/>
                    <DataGridTemplateColumn Header="Logo" Width="60">
                        <DataGridTemplateColumn.CellTemplate><DataTemplate><Image Source="{Binding IconURL}" Width="35" Height="35" Stretch="Uniform" Margin="5"/></DataTemplate></DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                    <DataGridTextColumn Header="Tên phần mềm" Binding="{Binding Ten}" Width="*" FontWeight="SemiBold" Foreground="#1E293B"/>
                    <DataGridTemplateColumn Header="Trạng thái" Width="280">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate><Grid Margin="10,5">
                                <ProgressBar Value="{Binding TienTrinh}" Height="22" Background="#F1F5F9" Foreground="#10B981" BorderThickness="0"/>
                                <TextBlock Text="{Binding TrangThai}" VerticalAlignment="Center" HorizontalAlignment="Center" FontSize="11" FontWeight="Bold" Foreground="#1E293B"/>
                            </Grid></DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                </DataGrid.Columns>
            </DataGrid>
            <Border Grid.Row="3" Background="#1E293B" CornerRadius="12" Margin="0,15,0,0">
                <UniformGrid Columns="4" Margin="10,0">
                    <Button Name="btnRun" Content="▶ BẮT ĐẦU" Background="#10B981" Foreground="White" FontWeight="Bold" Margin="8" Cursor="Hand"/>
                    <Button Name="btnPause" Content="⏸ TẠM DỪNG" Background="#F59E0B" Foreground="White" FontWeight="Bold" Margin="8" Cursor="Hand" IsEnabled="False"/>
                    <Button Name="btnResume" Content="⏯ TIẾP TỤC" Background="#3B82F6" Foreground="White" FontWeight="Bold" Margin="8" Cursor="Hand" IsEnabled="False"/>
                    <Button Name="btnStop" Content="⏹ DỪNG HẲN" Background="#EF4444" Foreground="White" FontWeight="Bold" Margin="8" Cursor="Hand" IsEnabled="False"/>
                </UniformGrid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$W = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$X))
$S = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$dg = $W.FindName("dg"); $dg.ItemsSource = $S
$W.FindName("TitleBar").Add_MouseLeftButtonDown({ $W.DragMove() })
$W.FindName("btnClose").Add_Click({ $W.Close() })
$W.FindName("btnMin").Add_Click({ $W.WindowState = "Minimized" })
$W.FindName("btnMax").Add_Click({ if ($W.WindowState -eq "Normal") {$W.WindowState="Maximized"} else {$W.WindowState="Normal"} })

# --- BỘ TẢI FILE SIÊU CẤP (API GD + CHIA NHỎ BUFFER) ---
function Tai-File ($D) {
    $D.TrangThai = "Đang kết nối..."
    $ID = ""; if ($D.Url -match "id=([^&]+)") {$ID=$Matches[1]} elseif ($D.Url -match "/d/([^/]+)") {$ID=$Matches[1]}
    $Ext = ".exe"; if ($D.Url -match "\.zip") {$Ext=".zip"} elseif ($D.Url -match "\.msi") {$Ext=".msi"}
    $Path = Join-Path $Global:ThuMucTaiVe "$($D.Ten -replace '[\\/:\*\?"<>\|]', '')$Ext"
    
    $Success = $false
    if ($ID) { # CHẾ ĐỘ TẢI API GOOGLE DRIVE
        for ($i = $Global:KeyHienTai; $i -lt $Global:DanhSachAPI.Count; $i++) {
            try {
                $Url = "https://www.googleapis.com/drive/v3/files/$($ID)?alt=media&key=$($Global:DanhSachAPI[$i])"
                $Req = [System.Net.HttpWebRequest]::Create($Url); $Res = $Req.GetResponse()
                $Stm = $Res.GetResponseStream(); $Fs = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Create)
                $Buf = New-Object byte[] 4194304; $Total = $Res.ContentLength; $Done = 0
                do {
                    if ($Global:TrangThaiHeThong -eq "DungLai") {break}
                    while ($Global:TrangThaiHeThong -eq "TamDung") { [System.Threading.Thread]::Sleep(500); [System.Windows.Forms.Application]::DoEvents() }
                    $Read = $Stm.Read($Buf, 0, $Buf.Length)
                    if ($Read -gt 0) { $Fs.Write($Buf, 0, $Read); $Done += $Read; $D.TienTrinh = [math]::Round(($Done/$Total)*100); $D.TrangThai = "API Drive: $($D.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents() }
                } while ($Read -gt 0)
                $Fs.Close(); $Stm.Close(); $Res.Close(); $Global:KeyHienTai = $i; $Success = $true; break
            } catch { if ($Fs) {$Fs.Close()}; continue }
        }
    } else { # CHẾ ĐỘ TẢI LINK TRỰC TIẾP NGOÀI
        try {
            $Req = [System.Net.HttpWebRequest]::Create($D.Url); $Res = $Req.GetResponse()
            $Stm = $Res.GetResponseStream(); $Fs = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Create)
            $Buf = New-Object byte[] 4194304; $Total = $Res.ContentLength; $Done = 0
            do {
                if ($Global:TrangThaiHeThong -eq "DungLai") {break}
                while ($Global:TrangThaiHeThong -eq "TamDung") { [System.Threading.Thread]::Sleep(500); [System.Windows.Forms.Application]::DoEvents() }
                $Read = $Stm.Read($Buf, 0, $Buf.Length)
                if ($Read -gt 0) { $Fs.Write($Buf, 0, $Read); $Done += $Read; if ($Total -gt 0) {$D.TienTrinh=[math]::Round(($Done/$Total)*100)}; $D.TrangThai = "Tải trực tiếp: $($D.TienTrinh)%"; [System.Windows.Forms.Application]::DoEvents() }
            } while ($Read -gt 0)
            $Fs.Close(); $Stm.Close(); $Res.Close(); $Success = $true
        } catch { if ($Fs) {$Fs.Close()} }
    }

    if ($Success -and $Global:TrangThaiHeThong -ne "DungLai") {
        $D.TrangThai = "Đang cài đặt..."; $D.TienTrinh = 100; [System.Windows.Forms.Application]::DoEvents()
        $Arg = if ($D.Args) {$D.Args} else {Do-LenhSilent $Path}
        if ($Path -match "\.zip") {
            $Dest = Join-Path "C:\" ($D.Ten -replace ' ', '')
            Expand-Archive -Path $Path -DestinationPath $Dest -Force -ErrorAction SilentlyContinue
            $Exe = Get-ChildItem -Path $Dest -Filter "*.exe" -Recurse | Sort Length -Descending | Select -First 1
            if ($Exe) { Tao-BieuTuongDesktop $D.Ten $Exe.FullName }
        } else {
            if ($Path -match "\.msi") { Start-Process "msiexec.exe" -ArgumentList "/i `"$Path`" /quiet /norestart" -Wait }
            else { Start-Process $Path -ArgumentList $Arg -Wait }
            # Săn Shortcut
            $K = $D.Ten.Split(' ')[0]; $Scan = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs")
            $Best = $null; foreach ($Khu in $Scan) {
                $Dir = Get-ChildItem $Khu -Directory -Filter "*$K*" -ErrorAction SilentlyContinue | Select -First 1
                if ($Dir) { $Best = Get-ChildItem $Dir.FullName -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Where {$_.Name -notmatch "unins|setup|update|agent|sender"} | Sort Length -Descending | Select -First 1 }
                if ($Best) {break}
            }
            if ($Best) { Tao-BieuTuongDesktop $D.Ten $Best.FullName }
        }
        $D.TrangThai = "Hoàn tất ✔️"
    }
}

# --- NÚT ĐIỀU KHIỂN ---
$W.FindName("btnAll").Add_Click({ foreach ($p in $S) {$p.Chon=$true} })
$W.FindName("btnNone").Add_Click({ foreach ($p in $S) {$p.Chon=$false} })
$W.FindName("btnRun").Add_Click({
    $Global:TrangThaiHeThong = "DangChay"; $W.FindName("btnRun").IsEnabled=$false; $W.FindName("btnPause").IsEnabled=$true; $W.FindName("btnStop").IsEnabled=$true
    foreach ($p in $S) { if ($p.Chon -and $Global:TrangThaiHeThong -ne "DungLai") { Tai-File $p } }
    $Global:TrangThaiHeThong = "NhanhRoi"; $W.FindName("btnRun").IsEnabled=$true; $W.FindName("btnPause").IsEnabled=$false; $W.FindName("btnStop").IsEnabled=$false
})
$W.FindName("btnPause").Add_Click({ $Global:TrangThaiHeThong="TamDung"; $W.FindName("btnPause").IsEnabled=$false; $W.FindName("btnResume").IsEnabled=$true })
$W.FindName("btnResume").Add_Click({ $Global:TrangThaiHeThong="DangChay"; $W.FindName("btnPause").IsEnabled=$true; $W.FindName("btnResume").IsEnabled=$false })
$W.FindName("btnStop").Add_Click({ $Global:TrangThaiHeThong="DungLai" })

# --- NẠP DỮ LIỆU ---
try {
    $CSV = (Invoke-RestMethod $Global:DuongDanCsv -UseBasicParsing) | ConvertFrom-Csv
    foreach ($d in $CSV) { if ($d.DownloadUrl) { $S.Add([PhanMem]@{Chon=($d.Check -match "True"); Ten=$d.Name; IconURL=$d.IconURL; Url=$d.DownloadUrl; Args=$d.SilentArgs; TrangThai="Sẵn sàng"; TienTrinh=0}) } }
} catch {}

$W.ShowDialog() | Out-Null