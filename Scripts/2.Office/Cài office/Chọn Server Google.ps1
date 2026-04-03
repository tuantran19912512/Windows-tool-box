# ==============================================================================
# BỘ CÀI OFFICE - GOOGLE DRIVE V320 (ĐỘNG CƠ ISO - HTTPCLIENT)
# Đặc tính: Dùng HttpClient từ bản ISO, Fix lỗi 3KB, Ép xung 15s, Full tính năng
# ==============================================================================

[System.Net.WebRequest]::DefaultWebProxy = $null
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

try { if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit } } catch { exit }
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- ĐỘNG CƠ C# V320 (BÊ NGUYÊN TỪ BẢN ISO SANG) ---
$MaCSharp = @"
using System;
using System.Net.Http;
using System.IO;
using System.Threading.Tasks;

public class EngineGG {
    public static int Progress = 0;
    public static string Speed = "0 MB/s";
    public static string Info = "0/0 MB";
    public static bool IsCanceled = false;

    public static void Reset() { Progress = 0; Speed = "0 MB/s"; Info = "0/0 MB"; IsCanceled = false; }
    
    public static void Cancel() { IsCanceled = true; }

    public static async Task<int> DownloadFile(string url, string path) {
        IsCanceled = false;
        try {
            using (HttpClient client = new HttpClient()) {
                client.Timeout = TimeSpan.FromHours(5);
                using (var response = await client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead)) {
                    if (!response.IsSuccessStatusCode) return (int)response.StatusCode;
                    
                    // Kiểm tra nếu là trang HTML (Virus warning của Google)
                    if (response.Content.Headers.ContentType.MediaType == "text/html") return 403;

                    var totalSize = response.Content.Headers.ContentLength ?? -1L;
                    using (var stream = await response.Content.ReadAsStreamAsync())
                    using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None)) {
                        var buffer = new byte[1048576];
                        var totalRead = 0L;
                        var startTime = DateTime.Now;
                        int read;
                        while ((read = await stream.ReadAsync(buffer, 0, buffer.Length)) > 0) {
                            if (IsCanceled) { fs.Close(); if(File.Exists(path)) File.Delete(path); return -1; }
                            await fs.WriteAsync(buffer, 0, read);
                            totalRead += read;
                            if (totalSize != -1) {
                                Progress = (int)((totalRead * 100) / totalSize);
                                double elapsed = (DateTime.Now - startTime).TotalSeconds;
                                if (elapsed > 0) {
                                    Speed = string.Format("{0:F2} MB/s", (totalRead / 1024.0 / 1024.0) / elapsed);
                                    Info = string.Format("{0:F1} / {1:F1} MB", totalRead / 1024.0 / 1024.0, totalSize / 1024.0 / 1024.0);
                                }
                            }
                        }
                    }
                }
                return 200;
            }
        } catch { return 500; }
    }
}
"@
if (-not ("EngineGG" -as [type])) { Add-Type -TypeDefinition $MaCSharp -ReferencedAssemblies "System.Net.Http", "System.Runtime" }

# --- BIẾN ĐỒNG BỘ ---
$Global:DongBo = [hashtable]::Synchronized(@{ TrangThai = "Sẵn sàng"; NhatKy = ""; Lenh = "CHỜ"; ThuMucLuu = "" })
$Global:TrangThaiApp = [hashtable]::Synchronized(@{})
$Global:DuLieuOffice = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Global:TuKhoaAPI = @("QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0","QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v")
$Global:TienTrinhNgam = $null
$Global:DongHoHuy = New-Object System.Windows.Threading.DispatcherTimer; $Global:DongHoHuy.Interval = [TimeSpan]::FromSeconds(1)
$Global:DemNguoc = 3; $Global:CacBanDangTai = @()

# --- GIAO DIỆN (GIỮ NGUYÊN) ---
$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="OFFICE DEPLOY - ISO ENGINE V320" Width="820" Height="700" WindowStartupLocation="CenterScreen" Background="#E3F2FD">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="120"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,10"><TextBlock Text="MÁY CHỦ GOOGLE DRIVE" FontSize="22" FontWeight="Bold" Foreground="#1565C0"/><TextBlock Text="☁ Động cơ ISO (HttpClient) - Ép xung 15s - Dọn rác tức thì" Foreground="#0277BD" FontWeight="Bold"/></StackPanel>
        <ListView Name="DanhSach" Grid.Row="1" SelectionMode="Extended" Background="White"><ListView.View><GridView><GridViewColumn Header="DANH SÁCH OFFICE" DisplayMemberBinding="{Binding Ten}" Width="480"/><GridViewColumn Header="TRẠNG THÁI" DisplayMemberBinding="{Binding TrangThai}" Width="180"/></GridView></ListView.View></ListView>
        <GroupBox Grid.Row="2" Header="NHẬT KÝ HOẠT ĐỘNG" Margin="0,5"><TextBox Name="HopNhatKy" IsReadOnly="True" Background="#1E1E1E" Foreground="#00E676" FontFamily="Consolas" VerticalScrollBarVisibility="Auto" FontSize="11" TextWrapping="Wrap"/></GroupBox>
        <Grid Grid.Row="3" Margin="0,5"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
            <TextBlock Text="LƯU TẠI: " VerticalAlignment="Center" FontWeight="Bold"/><TextBox Name="HopThuMuc" Grid.Column="1" IsReadOnly="True" VerticalContentAlignment="Center"/><Button Name="NutChon" Grid.Column="2" Content="CHỌN" Margin="5,0"/><Button Name="NutMo" Grid.Column="3" Content="MỞ" Background="#FFF59D"/></Grid>
        <UniformGrid Grid.Row="4" Rows="1" Columns="2" Margin="0,5"><CheckBox Name="HopThuoc" Content="+ Bẻ Khóa" IsChecked="True"/><CheckBox Name="HopGiuFile" Content="Giữ file nguồn" IsChecked="True"/></UniformGrid>
        <Grid Grid.Row="5" Margin="0,5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="95"/><ColumnDefinition Width="65"/><ColumnDefinition Width="85"/><ColumnDefinition Width="140"/></Grid.ColumnDefinitions>
            <StackPanel><Grid><TextBlock Name="TxtTrangThai" Text="Đang chờ..." FontWeight="Bold"/><TextBlock Name="TxtPhanTram" Text="0%" HorizontalAlignment="Right" FontWeight="Bold" Foreground="#2E7D32"/></Grid><ProgressBar Name="ThanhTienDo" Height="15" Margin="0,5" Foreground="#1565C0"/></StackPanel>
            <StackPanel Grid.Column="1" VerticalAlignment="Center"><TextBlock Name="TxtTocDo" Text="-- MB/s" HorizontalAlignment="Center" FontWeight="Bold" Foreground="#D84315"/><TextBlock Name="TxtThongTin" Text="0/0 MB" HorizontalAlignment="Center" FontSize="10" Foreground="#666666"/></StackPanel>
            <Button Name="NutHuy" Grid.Column="2" Content="🛑 HỦY" Margin="3,0" IsEnabled="False" Background="#EF9A9A"/>
            <Button Name="NutWeb" Grid.Column="3" Content="🌐 WEB" Margin="3,0" Background="#90CAF9" FontWeight="Bold"/>
            <Button Name="NutBatDau" Grid.Column="4" Content="🚀 BẮT ĐẦU" Background="#1565C0" Foreground="White" FontWeight="Bold" FontSize="14" Margin="3,0"/>
        </Grid>
    </Grid>
</Window>
"@
$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGiaoDien))))
$DanhSach = $CuaSo.FindName("DanhSach"); $HopNhatKy = $CuaSo.FindName("HopNhatKy"); $HopThuMuc = $CuaSo.FindName("HopThuMuc")
$TxtTrangThai = $CuaSo.FindName("TxtTrangThai"); $ThanhTienDo = $CuaSo.FindName("ThanhTienDo"); $TxtTocDo = $CuaSo.FindName("TxtTocDo"); $TxtPhanTram = $CuaSo.FindName("TxtPhanTram"); $TxtThongTin = $CuaSo.FindName("TxtThongTin")
$NutHuy = $CuaSo.FindName("NutHuy"); $NutMo = $CuaSo.FindName("NutMo"); $NutChon = $CuaSo.FindName("NutChon"); $NutWeb = $CuaSo.FindName("NutWeb"); $HopThuoc = $CuaSo.FindName("HopThuoc"); $HopGiuFile = $CuaSo.FindName("HopGiuFile"); $NutBatDau = $CuaSo.FindName("NutBatDau")
$DanhSach.ItemsSource = $Global:DuLieuOffice

# --- LUỒNG XỬ LÝ (SỬ DỤNG HTTPCLIENT ASYNC) ---
$KichBanXuLy = {
    param($GiaoTiep, $TrangThaiTungUngDung, $DanhSachChon, $TuKhoa, $CoThuoc, $CoGiuFile)
    function Them-NhatKy($tinNhan) { $GiaoTiep.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] $tinNhan`r`n" }
    function Lay-TuKhoa($mang, $chiSo) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($mang[$chiSo])) }
    
    try {
        $MayGiaiNen = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
        $KIdx = 0
        foreach ($phanTu in $DanhSachChon) {
            if ($GiaoTiep.Lenh -eq "DUNG") { break }
            $DuoiFile = if ($phanTu.ID -match "\.img$|\.iso$") { [System.IO.Path]::GetExtension($phanTu.ID) } else { ".zip" }
            # Sử dụng acknowledgeAbuse để vượt virus scan
            $DuongDanMang = "https://www.googleapis.com/drive/v3/files/$($phanTu.ID)?alt=media&key=$(Lay-TuKhoa $TuKhoa $KIdx)&acknowledgeAbuse=true" 
            $DuongDanLuuMay = Join-Path $GiaoTiep.ThuMucLuu (($phanTu.Ten -replace '\W','_') + $DuoiFile)

            $TrangThaiTungUngDung[$phanTu.ID] = "🚀 Đang tải..."
            Them-NhatKy "📡 [GOOGLE DRIVE]: $($phanTu.Ten)"
            
            # Chạy Task Download và lấy kết quả (.Result)
            $KetQua = [EngineGG]::DownloadFile($DuongDanMang, $DuongDanLuuMay).Result

            if ($KetQua -eq 200) {
                $TrangThaiTungUngDung[$phanTu.ID] = "📦 Đang cài..."
                $ThuMucGiaiNen = $DuongDanLuuMay + "_GiaiNen"
                $tienTrinh = Start-Process $MayGiaiNen -ArgumentList "x `"$DuongDanLuuMay`" -o`"$ThuMucGiaiNen`" -y" -WindowStyle Hidden -PassThru; while (-not $tienTrinh.HasExited) { Start-Sleep -Milliseconds 500 }
                $FileChay = Get-ChildItem $ThuMucGiaiNen -Filter "*.bat" -Recurse | Select-Object -First 1
                if (-not $FileChay) { $FileChay = Get-ChildItem $ThuMucGiaiNen -Filter "setup.exe" -Recurse | Select-Object -First 1 }
                if ($FileChay) { Start-Process $FileChay.FullName -WorkingDirectory $FileChay.DirectoryName -Wait }
                if ($CoThuoc) { try { (New-Object System.Net.WebClient).DownloadFile("https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd", "$env:TEMP\A.cmd"); Start-Process cmd "/c $env:TEMP\A.cmd /Ohook" -WindowStyle Hidden -Wait } catch {} }
                if (-not $CoGiuFile) { Remove-Item $DuongDanLuuMay -Force -ErrorAction SilentlyContinue }
                Remove-Item $ThuMucGiaiNen -Recurse -Force -ErrorAction SilentlyContinue
                $TrangThaiTungUngDung[$phanTu.ID] = "✅ Xong"; Them-NhatKy "✅ Xong: $($phanTu.Ten)"
            } elseif ($KetQua -eq 403) {
                $KIdx = ($KIdx + 1) % $TuKhoa.Count; Them-NhatKy "⚠️ Đổi API Key..."; redo
            } else { Them-NhatKy "❌ LỖI: $KetQua"; $TrangThaiTungUngDung[$phanTu.ID] = "❌ Lỗi" }
        }
    } catch { Them-NhatKy "❌ Lỗi: $($_.Exception.Message)" }
    $GiaoTiep.TrangThai = "✅ HOÀN TẤT"
}

# --- SỰ KIỆN (GIỮ NGUYÊN) ---
$Global:DongHoUI = New-Object System.Windows.Threading.DispatcherTimer; $Global:DongHoUI.Interval = [TimeSpan]::FromMilliseconds(300)
$Global:DongHoUI.Add_Tick({
    if ($null -ne $CuaSo -and $CuaSo.IsVisible -and $Global:DongBo.Lenh -ne "DUNG") {
        $ThanhTienDo.Value = [EngineGG]::Progress; $TxtPhanTram.Text = "$([EngineGG]::Progress)%"; $TxtTocDo.Text = [EngineGG]::Speed; $TxtThongTin.Text = [EngineGG]::Info; $TxtTrangThai.Text = $Global:DongBo.TrangThai
        if ($HopNhatKy.Text -ne $Global:DongBo.NhatKy) { $HopNhatKy.Text = $Global:DongBo.NhatKy; $HopNhatKy.ScrollToEnd() }
        foreach ($muc in $Global:DuLieuOffice) { if ($Global:TrangThaiApp.ContainsKey($muc.ID)) { $muc.TrangThai = $Global:TrangThaiApp[$muc.ID] } }
        $DanhSach.Items.Refresh()
        if ($Global:DongBo.TrangThai -match "✅|🛑") { $NutBatDau.IsEnabled = $true; $NutHuy.IsEnabled = $false; $Global:DongHoUI.Stop() }
    }
})

$Global:DongHoHuy.Add_Tick({
    if ($Global:DemNguoc -gt 0) { $TxtTrangThai.Text = "🛑 Đang nhả bộ nhớ Google... $($Global:DemNguoc)s"; $Global:DemNguoc-- } else {
        $Global:DongHoHuy.Stop()
        foreach ($muc in $Global:CacBanDangTai) {
            $DuoiFile = if ($muc.ID -match "\.img$|\.iso$") { [System.IO.Path]::GetExtension($muc.ID) } else { ".zip" }
            $FileRac = Join-Path $HopThuMuc.Text (($muc.Ten -replace '\W','_') + $DuoiFile); if (Test-Path $FileRac) { try { Remove-Item $FileRac -Force } catch {} }
            $Global:TrangThaiApp[$muc.ID] = "Sẵn sàng"
        }
        $ThanhTienDo.Value = 0; $TxtPhanTram.Text = "0%"; $TxtTocDo.Text = "0 MB/s"; $TxtThongTin.Text = "0/0 MB"; $TxtTrangThai.Text = "🛑 ĐÃ HỦY VÀ DỌN SẠCH"
        $HopNhatKy.Text += "[$((Get-Date).ToString('HH:mm:ss'))] 🛑 Đã dọn sạch rác.`r`n"; $NutBatDau.IsEnabled = $true; $NutHuy.IsEnabled = $false
    }
})

$NutBatDau.Add_Click({
    $DanhSachChon = @($DanhSach.SelectedItems); if ($DanhSachChon.Count -eq 0) { return }
    $Global:CacBanDangTai = $DanhSachChon; [EngineGG]::Reset(); $Global:DongBo.Lenh = "CHAY"; $Global:DongBo.TrangThai = "Đang tải..."
    $NutBatDau.IsEnabled = $false; $NutHuy.IsEnabled = $true; $Global:DongBo.ThuMucLuu = $HopThuMuc.Text
    $DanhSachTam = @(); foreach ($muc in $DanhSachChon) { $DanhSachTam += @{ ID = $muc.ID; Ten = $muc.Ten }; $Global:TrangThaiApp[$muc.ID] = "⏳ Chờ..." }
    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $Global:TienTrinhNgam = [powershell]::Create().AddScript($KichBanXuLy).AddArgument($Global:DongBo).AddArgument($Global:TrangThaiApp).AddArgument($DanhSachTam).AddArgument($Global:TuKhoaAPI).AddArgument($HopThuoc.IsChecked).AddArgument($HopGiuFile.IsChecked)
    $Global:TienTrinhNgam.Runspace = $MoiTruong; $Global:TienTrinhNgam.BeginInvoke(); $Global:DongHoUI.Start()
})

$NutHuy.Add_Click({ 
    $Global:DongBo.Lenh = "DUNG"; $Global:DongHoUI.Stop(); $NutBatDau.IsEnabled = $false; $NutHuy.IsEnabled = $false
    [EngineGG]::Cancel(); $Global:DemNguoc = 3; $Global:DongHoHuy.Start()
})

$NutMo.Add_Click({ if(Test-Path $HopThuMuc.Text) { Start-Process explorer.exe $HopThuMuc.Text } })
$NutChon.Add_Click({ $CuaSoChon = New-Object System.Windows.Forms.FolderBrowserDialog; if ($CuaSoChon.ShowDialog() -eq "OK") { $HopThuMuc.Text = $CuaSoChon.SelectedPath } })

$CuaSo.Add_Loaded({
    $HopThuMuc.Text = if(Test-Path "D:\") {"D:\BoCaiOffice"} else {"C:\BoCaiOffice"}
    if (-not (Test-Path $HopThuMuc.Text)) { New-Item $HopThuMuc.Text -ItemType Directory | Out-Null }
    try {
        $LinkCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv?t=$(Get-Date).Ticks"
        $DuLieuCsv = (Invoke-WebRequest $LinkCsv -UseBasicParsing).Content | ConvertFrom-Csv
        foreach ($dong in $DuLieuCsv) {
            if ($dong.ID -match "drive|docs" -or $dong.ID -notmatch "http") {
                $id = $dong.ID -replace '.*id=([^&]+).*','$1' -replace '.*/d/([^/]+).*','$1'
                $Global:DuLieuOffice.Add([PSCustomObject]@{ Ten=$dong.Name; TrangThai="Sẵn sàng"; ID=$id })
            }
        }
    } catch {}
})

$CuaSo.ShowDialog() | Out-Null