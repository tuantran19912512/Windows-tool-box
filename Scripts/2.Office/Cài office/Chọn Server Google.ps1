# ==============================================================================
# BỘ CÀI OFFICE - BẢN GOOGLE DRIVE (TIẾNG VIỆT 100%)
# Đặc tính: Chỉ hiển thị file từ Google, mạng ép xung chống treo, dọn rác 5s
# ==============================================================================

[System.Net.WebRequest]::DefaultWebProxy = $null
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try { if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit } } catch { exit }
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
# ==============================================================================
# BỘ CÀI OFFICE - BẢN GOOGLE DRIVE V320 (TIẾNG VIỆT 100%)
# Đặc tính: Chỉ load ID Google, Ép xung mạng 15s, Dọn rác 3s không treo giao diện
# ==============================================================================

[System.Net.WebRequest]::DefaultWebProxy = $null
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try { if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit } } catch { exit }
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- ĐỘNG CƠ C# V320 (CHUYÊN GOOGLE - ÉP XUNG 15S) ---
$MaCSharp = @"
using System; using System.Net; using System.IO; using System.Threading;
public class EngineGG {
    public static int Progress = 0; public static string Speed = "0 MB/s"; public static string Info = "0/0 MB";
    public static string LastError = ""; public static bool IsCanceled = false;
    public static HttpWebRequest ActiveRequest = null; public static HttpWebResponse ActiveResponse = null; 
    public static Stream ActiveStream = null;

    public static void Reset() { Progress = 0; Speed = "0 MB/s"; Info = "0/0 MB"; LastError = ""; IsCanceled = false; }
    
    public static void Cancel() {
        IsCanceled = true;
        if (ActiveRequest != null) { try { ActiveRequest.Abort(); } catch { } }
    }

    public static int DownloadFile(string url, string path) {
        LastError = ""; int maxRetries = 10; WebRequest.DefaultWebProxy = null;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            if (IsCanceled) return -1;
            try {
                long totalRead = 0; long existingSize = 0;
                if (File.Exists(path)) { existingSize = new FileInfo(path).Length; totalRead = existingSize; }

                ActiveRequest = (HttpWebRequest)WebRequest.Create(url);
                ActiveRequest.Proxy = null;
                ActiveRequest.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36";
                ActiveRequest.Accept = "*/*";
                
                // ĐẶC TÍNH GOOGLE: ÉP XUNG 15 GIÂY (Nhanh hơn MS để chống treo luồng Google)
                ActiveRequest.KeepAlive = false; 
                ActiveRequest.Timeout = 15000; 
                ActiveRequest.ReadWriteTimeout = 15000; 
                
                if (existingSize > 0) { ActiveRequest.AddRange(existingSize); }

                ActiveResponse = (HttpWebResponse)ActiveRequest.GetResponse();
                long totalSize = ActiveResponse.ContentLength;
                if (totalSize > 0 && existingSize > 0) { totalSize += existingSize; } else if (totalSize <= 0) { totalSize = -1; }

                FileMode fm = FileMode.Append;
                if (ActiveResponse.StatusCode != HttpStatusCode.PartialContent && existingSize > 0) { fm = FileMode.Create; totalRead = 0; } else if (existingSize == 0) { fm = FileMode.Create; }

                ActiveStream = ActiveResponse.GetResponseStream();
                
                using (FileStream fs = new FileStream(path, fm, FileAccess.Write, FileShare.ReadWrite)) {
                    byte[] buffer = new byte[1048576]; int read; DateTime startTime = DateTime.Now;
                    while ((read = ActiveStream.Read(buffer, 0, buffer.Length)) > 0) {
                        if (IsCanceled) { break; }
                        fs.Write(buffer, 0, read); totalRead += read;
                        if (totalSize > 0) {
                            Progress = (int)((totalRead * 100) / totalSize);
                            double elapsed = (DateTime.Now - startTime).TotalSeconds;
                            if (elapsed > 0) { Speed = string.Format("{0:F2} MB/s", (totalRead / 1024.0 / 1024.0) / elapsed); Info = string.Format("{0:F1} / {1:F1} MB", totalRead / 1024.0 / 1024.0, totalSize / 1024.0 / 1024.0); }
                        }
                    }
                }
                
                if (IsCanceled) return -1;
                if (totalSize > 0 && totalRead < totalSize) { throw new Exception("Google ngắt mạng."); }
                return 200; 
            } 
            catch (WebException wex) {
                if (IsCanceled || wex.Status == WebExceptionStatus.RequestCanceled) return -1;
                if (wex.Response != null) {
                    using (var errRes = (HttpWebResponse)wex.Response) {
                        if (errRes.StatusCode == HttpStatusCode.RequestedRangeNotSatisfiable) { if (File.Exists(path)) { try { File.Delete(path); } catch {} } continue; }
                        LastError = "HTTP " + (int)errRes.StatusCode; if ((int)errRes.StatusCode == 403) return 403; 
                    }
                } else { LastError = wex.Message; }
            }
            catch (ThreadAbortException) { return -1; } catch (Exception ex) { LastError = ex.Message; }
            finally {
                try { if (ActiveStream != null) { ActiveStream.Dispose(); ActiveStream = null; } } catch {}
                try { if (ActiveResponse != null) { ActiveResponse.Dispose(); ActiveResponse = null; } } catch {}
                try { if (ActiveRequest != null) { ActiveRequest.Abort(); ActiveRequest = null; } } catch {}
            }
            if (attempt < maxRetries && !IsCanceled) { Info = "Kích sóng Google (" + attempt + "/" + maxRetries + ")..."; Thread.Sleep(2000); }
        }
        return 500;
    }
}
"@
if (-not ("EngineGG" -as [type])) { Add-Type -TypeDefinition $MaCSharp -ReferencedAssemblies "System" -ErrorAction Stop }

# --- BIẾN ĐỒNG BỘ ---
$Global:DongBo = [hashtable]::Synchronized(@{ TrangThai = "Sẵn sàng"; NhatKy = ""; Lenh = "CHỜ" })
$Global:TrangThaiApp = [hashtable]::Synchronized(@{})
$Global:DuLieuOffice = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Global:TuKhoaAPI = @("QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v", "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv", "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR")
$Global:TienTrinhNgam = $null
$Global:DongHoHuy = New-Object System.Windows.Threading.DispatcherTimer; $Global:DongHoHuy.Interval = [TimeSpan]::FromSeconds(1)
$Global:DemNguoc = 3; $Global:CacBanDangTai = @()

# --- GIAO DIỆN (MÀU XANH DƯƠNG GOOGLE) ---
$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="OFFICE DEPLOY - GOOGLE DRIVE V320" Width="820" Height="700" WindowStartupLocation="CenterScreen" Background="#E3F2FD">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="120"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,10"><TextBlock Text="MÁY CHỦ GOOGLE DRIVE" FontSize="22" FontWeight="Bold" Foreground="#1565C0"/><TextBlock Text="☁ Chế độ tải Google ép xung 15s - Dọn rác tức thì" Foreground="#0277BD" FontWeight="Bold"/></StackPanel>
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

# --- LUỒNG XỬ LÝ ---
$KichBanXuLy = {
    param($GiaoTiep, $TrangThaiTungUngDung, $DanhSachChon, $TuKhoa, $CoThuoc, $CoGiuFile)
    function Them-NhatKy($tinNhan) { $GiaoTiep.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] $tinNhan`r`n" }
    function Lay-TuKhoa($mang, $chiSo) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($mang[$chiSo])) }
    
    try {
        $MayGiaiNen = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $MayGiaiNen) {
            $7zLuu = Join-Path $env:TEMP "7z_setup.exe"
            if ([EngineGG]::DownloadFile("https://www.7-zip.org/a/7z2408-x64.exe", $7zLuu) -eq 200) {
                $Cai7z = Start-Process $7zLuu -ArgumentList "/S" -WindowStyle Hidden -PassThru; while (-not $Cai7z.HasExited) { Start-Sleep -Milliseconds 500 }
                $MayGiaiNen = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
            }
        }

        $ChiSoTuKhoa = 0 
        foreach ($phanTu in $DanhSachChon) {
            $DuoiFile = if ($phanTu.ID -match "\.img$|\.iso$") { [System.IO.Path]::GetExtension($phanTu.ID) } else { ".zip" }
            $DuongDanMang = "https://www.googleapis.com/drive/v3/files/$($phanTu.ID)?alt=media&key=$(Lay-TuKhoa $TuKhoa $ChiSoTuKhoa)&acknowledgeAbuse=true" 
            $DuongDanLuuMay = Join-Path $GiaoTiep.ThuMucLuu (($phanTu.Ten -replace '\W','_') + $DuoiFile)

            $TrangThaiTungUngDung[$phanTu.ID] = "🚀 Đang tải..."
            Them-NhatKy "📡 [GOOGLE DRIVE]: $($phanTu.Ten)"
            $KetQua = [EngineGG]::DownloadFile($DuongDanMang, $DuongDanLuuMay)

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
            } elseif ($KetQua -eq -1) { $TrangThaiTungUngDung[$phanTu.ID] = "Sẵn sàng"
            } else { Them-NhatKy "❌ LỖI: $([EngineGG]::LastError)"; $TrangThaiTungUngDung[$phanTu.ID] = "❌ Lỗi" }
        }
    } catch { }
    $GiaoTiep.TrangThai = "✅ HOÀN TẤT"
}

# --- SỰ KIỆN ---
$Global:DongHoUI = New-Object System.Windows.Threading.DispatcherTimer; $Global:DongHoUI.Interval = [TimeSpan]::FromMilliseconds(300)
$Global:DongHoUI.Add_Tick({
    if ($null -ne $CuaSo -and $CuaSo.IsVisible -and $Global:DongBo.Lenh -ne "DUNG") {
        $ThanhTienDo.Value = [EngineGG]::Progress; $TxtPhanTram.Text = "$([EngineGG]::Progress)%"; $TxtTocDo.Text = [EngineGG]::Speed; $TxtThongTin.Text = [EngineGG]::Info; $TxtTrangThai.Text = $Global:DongBo.TrangThai
        if ($HopNhatKy.Text -ne $Global:DongBo.NhatKy) { $HopNhatKy.Text = $Global:DongBo.NhatKy; $HopNhatKy.ScrollToEnd() }
        foreach ($muc in $Global:DuLieuOffice) { if ($Global:TrangThaiApp.ContainsKey($muc.ID)) { $muc.TrangThai = $Global:TrangThaiApp[$muc.ID] } }
        $DanhSach.Items.Refresh()
        if ($Global:DongBo.TrangThai -match "✅|🛑|❌ LỖI") { $NutBatDau.IsEnabled = $true; $NutHuy.IsEnabled = $false; $Global:DongHoUI.Stop() }
    }
})

$Global:DongHoHuy.Add_Tick({
    if ($Global:DemNguoc -gt 0) { $TxtTrangThai.Text = "🛑 Đang nhả bộ nhớ Google... $($Global:DemNguoc)s"; $Global:DemNguoc-- } else {
        $Global:DongHoHuy.Stop()
        foreach ($muc in $Global:CacBanDangTai) {
            $DuoiFile = if ($muc.ID -match "\.img$|\.iso$") { [System.IO.Path]::GetExtension($muc.ID) } else { ".zip" }
            $FileRac = Join-Path $HopThuMuc.Text (($muc.Ten -replace '\W','_') + $DuoiFile)
            $ThuMucRac = $FileRac + "_GiaiNen"
            if (Test-Path $FileRac) { try { Remove-Item $FileRac -Force -ErrorAction SilentlyContinue } catch {} }
            if (Test-Path $ThuMucRac) { try { Remove-Item $ThuMucRac -Recurse -Force -ErrorAction SilentlyContinue } catch {} }
            $Global:TrangThaiApp[$muc.ID] = "Sẵn sàng"
        }
        $ThanhTienDo.Value = 0; $TxtPhanTram.Text = "0%"; $TxtTocDo.Text = "0 MB/s"; $TxtThongTin.Text = "0/0 MB"; $TxtTrangThai.Text = "🛑 ĐÃ HỦY VÀ DỌN SẠCH"
        $Global:DongBo.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] 🛑 Đã dọn sạch rác Google Drive.`r`n"
        $HopNhatKy.Text = $Global:DongBo.NhatKy; $HopNhatKy.ScrollToEnd(); $DanhSach.Items.Refresh(); $NutBatDau.IsEnabled = $true; $NutHuy.IsEnabled = $false
    }
})

$NutBatDau.Add_Click({
    $DanhSachChon = @($DanhSach.SelectedItems); if ($DanhSachChon.Count -eq 0) { return }
    $Global:CacBanDangTai = $DanhSachChon; [EngineGG]::Reset(); $Global:DongBo.Lenh = "CHAY"
    $NutBatDau.IsEnabled = $false; $NutHuy.IsEnabled = $true; $Global:DongBo.ThuMucLuu = $HopThuMuc.Text
    $DanhSachTam = @(); foreach ($muc in $DanhSachChon) { $DanhSachTam += @{ ID = $muc.ID; Ten = $muc.Ten }; $Global:TrangThaiApp[$muc.ID] = "⏳ Chờ..." }
    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $Global:TienTrinhNgam = [powershell]::Create().AddScript($KichBanXuLy).AddArgument($Global:DongBo).AddArgument($Global:TrangThaiApp).AddArgument($DanhSachTam).AddArgument($Global:TuKhoaAPI).AddArgument($HopThuoc.IsChecked).AddArgument($HopGiuFile.IsChecked)
    $Global:TienTrinhNgam.Runspace = $MoiTruong; $Global:TienTrinhNgam.BeginInvoke(); $Global:DongHoUI.Start()
})

$NutHuy.Add_Click({ 
    $Global:DongBo.Lenh = "DUNG"; $Global:DongHoUI.Stop(); $NutBatDau.IsEnabled = $false; $NutHuy.IsEnabled = $false
    [EngineGG]::Cancel(); Get-Process | Where-Object { $_.ProcessName -match "7z|setup|inst" } | Stop-Process -Force -ErrorAction SilentlyContinue
    $Global:DemNguoc = 3; $TxtTrangThai.Text = "🛑 Đang nhả bộ nhớ Google... 3s"; $Global:DongHoHuy.Start()
})

$NutWeb.Add_Click({ $DanhSachChon = @($DanhSach.SelectedItems); foreach ($muc in $DanhSachChon) { Start-Process "https://drive.google.com/uc?export=download&id=$($muc.ID)" } })
$NutMo.Add_Click({ if(Test-Path $HopThuMuc.Text) { Start-Process explorer.exe $HopThuMuc.Text } })
$NutChon.Add_Click({ $CuaSoChon = New-Object System.Windows.Forms.FolderBrowserDialog; if ($CuaSoChon.ShowDialog() -eq "OK") { $HopThuMuc.Text = $CuaSoChon.SelectedPath } })

$CuaSo.Add_Loaded({
    $HopThuMuc.Text = if(Test-Path "D:\") {"D:\BoCaiOffice"} else {"C:\BoCaiOffice"}
    try {
        $LinkCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv?t=$(Get-Date).Ticks"
        $DuLieuCsv = (Invoke-WebRequest $LinkCsv -UseBasicParsing).Content | ConvertFrom-Csv
        foreach ($dong in $DuLieuCsv) {
            # LỌC: CHỈ HIỂN THỊ GOOGLE DRIVE
            if ($dong.ID -notmatch "^http" -or $dong.ID -match "googleapis\.com|drive\.google\.com") {
                $Global:DuLieuOffice.Add([PSCustomObject]@{ Ten=$dong.Name; TrangThai="Sẵn sàng"; ID=$dong.ID })
            }
        }
    } catch {}
})

if ($null -ne $CuaSo) { try { $CuaSo.ShowDialog() | Out-Null } finally { $Global:DongHoUI.Stop(); $Global:DongHoHuy.Stop(); [EngineGG]::Cancel() } }
# --- ĐỘNG CƠ C# ---
$MaCSharp = @"
using System; using System.Net; using System.IO; using System.Threading;
public class EngineGG {
    public static int Progress = 0; public static string Speed = "0 MB/s"; public static string Info = "0/0 MB";
    public static string LastError = ""; public static bool IsCanceled = false;
    public static HttpWebRequest ActiveRequest = null; public static HttpWebResponse ActiveResponse = null; public static Stream ActiveStream = null;

    public static void Reset() { Progress = 0; Speed = "0 MB/s"; Info = "0/0 MB"; LastError = ""; IsCanceled = false; }
    public static void Cancel() {
        IsCanceled = true;
        try { if (ActiveStream != null) { ActiveStream.Close(); ActiveStream.Dispose(); } } catch { }
        try { if (ActiveResponse != null) { ActiveResponse.Close(); ActiveResponse.Dispose(); } } catch { }
        try { if (ActiveRequest != null) { ActiveRequest.Abort(); } } catch { }
    }

    public static int DownloadFile(string url, string path, bool isDirect) {
        LastError = ""; int maxRetries = 5; WebRequest.DefaultWebProxy = null;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            if (IsCanceled) return -1;
            try {
                long totalRead = 0; long existingSize = 0;
                if (File.Exists(path)) { existingSize = new FileInfo(path).Length; totalRead = existingSize; }

                ActiveRequest = (HttpWebRequest)WebRequest.Create(url);
                ActiveRequest.Proxy = null;
                ActiveRequest.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36";
                ActiveRequest.Accept = "*/*";
                
                if (isDirect) { ActiveRequest.KeepAlive = true; ActiveRequest.Timeout = Timeout.Infinite; ActiveRequest.ReadWriteTimeout = 300000; }
                else { ActiveRequest.KeepAlive = false; ActiveRequest.Timeout = 15000; ActiveRequest.ReadWriteTimeout = 15000; }
                
                if (existingSize > 0) { ActiveRequest.AddRange(existingSize); }

                ActiveResponse = (HttpWebResponse)ActiveRequest.GetResponse();
                long totalSize = ActiveResponse.ContentLength;
                if (totalSize > 0 && existingSize > 0) { totalSize += existingSize; } else if (totalSize <= 0) { totalSize = -1; }

                FileMode fm = FileMode.Append;
                if (ActiveResponse.StatusCode != HttpStatusCode.PartialContent && existingSize > 0) { fm = FileMode.Create; totalRead = 0; } else if (existingSize == 0) { fm = FileMode.Create; }

                ActiveStream = ActiveResponse.GetResponseStream();
                using (FileStream fs = new FileStream(path, fm, FileAccess.Write, FileShare.None)) {
                    byte[] buffer = new byte[1048576]; int read; DateTime startTime = DateTime.Now;
                    while ((read = ActiveStream.Read(buffer, 0, buffer.Length)) > 0) {
                        if (IsCanceled) { fs.Close(); return -1; }
                        fs.Write(buffer, 0, read); totalRead += read;
                        if (totalSize > 0) {
                            Progress = (int)((totalRead * 100) / totalSize);
                            double elapsed = (DateTime.Now - startTime).TotalSeconds;
                            if (elapsed > 0) { Speed = string.Format("{0:F2} MB/s", (totalRead / 1024.0 / 1024.0) / elapsed); Info = string.Format("{0:F1} / {1:F1} MB", totalRead / 1024.0 / 1024.0, totalSize / 1024.0 / 1024.0); }
                        }
                    }
                }
                if (totalSize > 0 && totalRead < totalSize) { throw new Exception("Ngắt mạng."); }
                return 200; 
            } 
            catch (WebException wex) {
                if (IsCanceled || wex.Status == WebExceptionStatus.RequestCanceled) return -1;
                if (wex.Response != null) {
                    using (var errRes = (HttpWebResponse)wex.Response) {
                        if (errRes.StatusCode == HttpStatusCode.RequestedRangeNotSatisfiable) { if (File.Exists(path)) { try { File.Delete(path); } catch {} } continue; }
                        LastError = "HTTP " + (int)errRes.StatusCode; if ((int)errRes.StatusCode == 403) return 403; 
                    }
                } else { LastError = wex.Message; }
            }
            catch (ThreadAbortException) { return -1; } catch (Exception ex) { LastError = ex.Message; }
            finally {
                try { if (ActiveStream != null) { ActiveStream.Dispose(); ActiveStream = null; } } catch {}
                try { if (ActiveResponse != null) { ActiveResponse.Dispose(); ActiveResponse = null; } } catch {}
                try { if (ActiveRequest != null) { ActiveRequest.Abort(); ActiveRequest = null; } } catch {}
            }
            if (attempt < maxRetries && !IsCanceled) { Info = "Kết nối lại (" + attempt + "/" + maxRetries + ")..."; Thread.Sleep(3000); }
        }
        return 500;
    }
}
"@
if (-not ("EngineGG" -as [type])) { Add-Type -TypeDefinition $MaCSharp -ReferencedAssemblies "System" -ErrorAction Stop }

# --- BIẾN ĐỒNG BỘ ---
$Global:DongBo = [hashtable]::Synchronized(@{ TrangThai = "Sẵn sàng"; NhatKy = ""; Lenh = "CHỜ" })
$Global:TrangThaiApp = [hashtable]::Synchronized(@{})
$Global:DuLieuOffice = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Global:TuKhoaAPI = @("QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v", "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv", "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR")
$Global:TienTrinhNgam = $null
$Global:DongHoHuy = New-Object System.Windows.Threading.DispatcherTimer; $Global:DongHoHuy.Interval = [TimeSpan]::FromSeconds(1)
$Global:DemNguoc = 5; $Global:DanhSachFileRac = @()

# --- GIAO DIỆN ---
$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="OFFICE DEPLOY - BẢN GOOGLE DRIVE" Width="820" Height="700" WindowStartupLocation="CenterScreen" Background="#E3F2FD">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="120"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,10"><TextBlock Text="MÁY CHỦ GOOGLE DRIVE" FontSize="22" FontWeight="Bold" Foreground="#1565C0"/><TextBlock Text="☁ Chỉ hiển thị và tải các link từ Google Drive" Foreground="#0277BD" FontWeight="Bold"/></StackPanel>
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

# --- LUỒNG XỬ LÝ CHÍNH ---
$KichBanXuLy = {
    param($GiaoTiep, $TrangThaiTungUngDung, $DanhSachChon, $TuKhoa, $CoThuoc, $CoGiuFile)
    function Them-NhatKy($tinNhan) { $GiaoTiep.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] $tinNhan`r`n" }
    function Lay-TuKhoa($mang, $chiSo) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($mang[$chiSo])) }
    
    try {
        $MayGiaiNen = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $MayGiaiNen) {
            Them-NhatKy "⚠️ Đang tải 7-Zip..."
            $7zLuu = Join-Path $env:TEMP "7z_setup.exe"
            if ([EngineGG]::DownloadFile("https://www.7-zip.org/a/7z2408-x64.exe", $7zLuu, $true) -eq 200) {
                $Cai7z = Start-Process $7zLuu -ArgumentList "/S" -WindowStyle Hidden -PassThru; while (-not $Cai7z.HasExited) { Start-Sleep -Milliseconds 500 }
                $MayGiaiNen = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
            } else { Them-NhatKy "❌ Lỗi tải 7-Zip"; $GiaoTiep.TrangThai = "❌ LỖI 7-ZIP"; return }
        }

        $ChiSoTuKhoa = 0 
        foreach ($phanTu in $DanhSachChon) {
            $DuoiFile = if ($phanTu.ID -match "\.img$|\.iso$") { [System.IO.Path]::GetExtension($phanTu.ID) } else { ".zip" }
            $DuongDanMang = "https://www.googleapis.com/drive/v3/files/$($phanTu.ID)?alt=media&key=$(Lay-TuKhoa $TuKhoa $ChiSoTuKhoa)&acknowledgeAbuse=true" 
            $DuongDanLuuMay = Join-Path $GiaoTiep.ThuMucLuu (($phanTu.Ten -replace '\W','_') + $DuoiFile)
            if (Test-Path $DuongDanLuuMay) { try { Remove-Item $DuongDanLuuMay -Force -ErrorAction Stop } catch { Them-NhatKy "⚠️ Dọn file kẹt..."; Start-Sleep 1; try{Remove-Item $DuongDanLuuMay -Force}catch{} } }

            $TrangThaiTungUngDung[$phanTu.ID] = "🚀 Đang tải..."
            Them-NhatKy "📡 [GOOGLE DRIVE]: $($phanTu.Ten)"
            $KetQua = [EngineGG]::DownloadFile($DuongDanMang, $DuongDanLuuMay, $false)

            if ($KetQua -eq 200) {
                $TrangThaiTungUngDung[$phanTu.ID] = "📦 Đang cài..."
                $ThuMucGiaiNen = $DuongDanLuuMay + "_GiaiNen"
                $tienTrinh = Start-Process $MayGiaiNen -ArgumentList "x `"$DuongDanLuuMay`" -o`"$ThuMucGiaiNen`" -y" -WindowStyle Hidden -PassThru; while (-not $tienTrinh.HasExited) { Start-Sleep -Milliseconds 500 }
                $FileChay = Get-ChildItem $ThuMucGiaiNen -Filter "*.bat" -Recurse | Select-Object -First 1
                if (-not $FileChay) { $FileChay = Get-ChildItem $ThuMucGiaiNen -Filter "setup.exe" -Recurse | Select-Object -First 1 }
                if ($FileChay) { $tienTrinhCai = Start-Process $FileChay.FullName -WorkingDirectory $FileChay.DirectoryName -PassThru; while (-not $tienTrinhCai.HasExited) { Start-Sleep -Milliseconds 500 } }
                if ($CoThuoc) { try { (New-Object System.Net.WebClient).DownloadFile("https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd", "$env:TEMP\A.cmd"); Start-Process cmd "/c $env:TEMP\A.cmd /Ohook" -WindowStyle Hidden -Wait } catch {} }
                if (-not $CoGiuFile) { Remove-Item $DuongDanLuuMay -Force -ErrorAction SilentlyContinue }
                Remove-Item $ThuMucGiaiNen -Recurse -Force -ErrorAction SilentlyContinue
                $TrangThaiTungUngDung[$phanTu.ID] = "✅ Xong"; Them-NhatKy "✅ Xong: $($phanTu.Ten)"
            } elseif ($KetQua -eq 403) { Them-NhatKy "❌ 403 Quá giới hạn"; $TrangThaiTungUngDung[$phanTu.ID] = "❌ Quá giới hạn"
            } elseif ($KetQua -eq -1) { $TrangThaiTungUngDung[$phanTu.ID] = "Sẵn sàng"
            } else { Them-NhatKy "❌ LỖI: $([EngineGG]::LastError)"; $TrangThaiTungUngDung[$phanTu.ID] = "❌ Lỗi" }
        }
    } catch { if ($_.Exception.Message -notmatch "Pipeline stopped") { Them-NhatKy "❌ LỖI: $($_.Exception.Message)" } }
    $GiaoTiep.TrangThai = "✅ HOÀN TẤT"
}

# --- SỰ KIỆN GIAO DIỆN ---
$Global:DongHoUI = New-Object System.Windows.Threading.DispatcherTimer; $Global:DongHoUI.Interval = [TimeSpan]::FromMilliseconds(300)
$Global:DongHoUI.Add_Tick({
    if ($null -ne $CuaSo -and $CuaSo.IsVisible -and $Global:DongBo.Lenh -ne "DUNG") {
        $ThanhTienDo.Value = [EngineGG]::Progress; $TxtPhanTram.Text = "$([EngineGG]::Progress)%"; $TxtTocDo.Text = [EngineGG]::Speed; $TxtThongTin.Text = [EngineGG]::Info; $TxtTrangThai.Text = $Global:DongBo.TrangThai
        if ($HopNhatKy.Text -ne $Global:DongBo.NhatKy) { $HopNhatKy.Text = $Global:DongBo.NhatKy; $HopNhatKy.ScrollToEnd() }
        foreach ($muc in $Global:DuLieuOffice) { if ($Global:TrangThaiApp.ContainsKey($muc.ID)) { $muc.TrangThai = $Global:TrangThaiApp[$muc.ID] } }
        $DanhSach.Items.Refresh()
        if ($Global:DongBo.TrangThai -match "✅|🛑|❌ LỖI") { $NutBatDau.IsEnabled = $true; $NutHuy.IsEnabled = $false; $Global:DongHoUI.Stop() }
    }
})

$Global:DongHoHuy.Add_Tick({
    if ($Global:DemNguoc -gt 0) { $TxtTrangThai.Text = "🛑 Đang dọn rác... $($Global:DemNguoc)s"; $Global:DemNguoc-- } else {
        $Global:DongHoHuy.Stop(); [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
        if ($null -ne $Global:TienTrinhNgam) { try { $Global:TienTrinhNgam.BeginStop($null, $null) | Out-Null } catch {} }
        foreach ($muc in $Global:DanhSachFileRac) {
            $DuoiFile = if ($muc.ID -match "\.img$|\.iso$") { [System.IO.Path]::GetExtension($muc.ID) } else { ".zip" }
            $FileRac = Join-Path $HopThuMuc.Text (($muc.Ten -replace '\W','_') + $DuoiFile); $ThuMucRac = $FileRac + "_GiaiNen"
            if (Test-Path $FileRac) { try { Remove-Item $FileRac -Force -ErrorAction SilentlyContinue } catch {} }; if (Test-Path $ThuMucRac) { try { Remove-Item $ThuMucRac -Recurse -Force -ErrorAction SilentlyContinue } catch {} }
            $Global:TrangThaiApp[$muc.ID] = "Sẵn sàng"
        }
        $ThanhTienDo.Value = 0; $TxtPhanTram.Text = "0%"; $TxtTocDo.Text = "0 MB/s"; $TxtThongTin.Text = "0/0 MB"; $TxtTrangThai.Text = "🛑 ĐÃ HỦY VÀ DỌN RÁC"; $Global:DongBo.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] 🛑 Đã dọn sạch rác.`r`n"
        $HopNhatKy.Text = $Global:DongBo.NhatKy; $HopNhatKy.ScrollToEnd(); $DanhSach.Items.Refresh(); $NutBatDau.IsEnabled = $true; $NutHuy.IsEnabled = $false
    }
})

$NutBatDau.Add_Click({
    $DanhSachChon = @($DanhSach.SelectedItems); if ($DanhSachChon.Count -eq 0) { return }
    [System.Threading.Tasks.Task]::Run([System.Action]{ [EngineGG]::Cancel() }) | Out-Null
    if ($null -ne $Global:TienTrinhNgam) { try { $Global:TienTrinhNgam.BeginStop($null, $null) | Out-Null } catch {} }
    Get-Process | Where-Object { $_.ProcessName -match "7z|setup|inst" } | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 200 
    [EngineGG]::Reset(); $Global:DongBo.Lenh = "CHAY"; $Global:DongBo.NhatKy = "🚀 Bắt đầu tải từ Google Drive...`r`n"; $NutBatDau.IsEnabled = $false; $NutHuy.IsEnabled = $true; $Global:DongBo.ThuMucLuu = $HopThuMuc.Text
    $DanhSachTam = @(); foreach ($muc in $DanhSachChon) { $DanhSachTam += @{ ID = $muc.ID; Ten = $muc.Ten }; $Global:TrangThaiApp[$muc.ID] = "⏳ Chờ..." }
    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $Global:TienTrinhNgam = [powershell]::Create().AddScript($KichBanXuLy).AddArgument($Global:DongBo).AddArgument($Global:TrangThaiApp).AddArgument($DanhSachTam).AddArgument($Global:TuKhoaAPI).AddArgument($HopThuoc.IsChecked).AddArgument($HopGiuFile.IsChecked)
    $Global:TienTrinhNgam.Runspace = $MoiTruong; $Global:TienTrinhNgam.BeginInvoke(); $Global:DongHoUI.Start()
})

$NutHuy.Add_Click({ 
    $Global:DongBo.Lenh = "DUNG"; $Global:DongHoUI.Stop(); $NutBatDau.IsEnabled = $false; $NutHuy.IsEnabled = $false; $Global:DanhSachFileRac = @($DanhSach.SelectedItems)
    [System.Threading.Tasks.Task]::Run([System.Action]{ [EngineGG]::Cancel() }) | Out-Null
    Get-Process | Where-Object { $_.ProcessName -match "7z|setup|inst" } | Stop-Process -Force -ErrorAction SilentlyContinue
    $Global:DemNguoc = 5; $TxtTrangThai.Text = "🛑 Đang dọn rác... 5s"; $Global:DongHoHuy.Start()
})

$NutWeb.Add_Click({ $DanhSachChon = @($DanhSach.SelectedItems); if ($DanhSachChon.Count -eq 0) { return }; foreach ($muc in $DanhSachChon) { Start-Process "https://drive.google.com/uc?export=download&id=$($muc.ID)" } })
$NutMo.Add_Click({ if(Test-Path $HopThuMuc.Text) { Start-Process explorer.exe $HopThuMuc.Text } })
$NutChon.Add_Click({ $CuaSoChon = New-Object System.Windows.Forms.FolderBrowserDialog; if ($CuaSoChon.ShowDialog() -eq "OK") { $HopThuMuc.Text = $CuaSoChon.SelectedPath } })

$CuaSo.Add_Loaded({
    $HopThuMuc.Text = if(Test-Path "D:\") {"D:\BoCaiOffice"} else {"C:\BoCaiOffice"}
    try {
        $LinkCsv = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv?t=$(Get-Date).Ticks"
        $DuLieuCsv = (Invoke-WebRequest $LinkCsv -UseBasicParsing).Content | ConvertFrom-Csv
        # BỘ LỌC CHỈ CHO PHÉP LOAD GOOGLE DRIVE
        foreach ($dong in $DuLieuCsv) {
            if ($dong.ID -notmatch "^http" -or $dong.ID -match "googleapis\.com|drive\.google\.com") {
                $Global:DuLieuOffice.Add([PSCustomObject]@{ Ten=$dong.Name; TrangThai="Sẵn sàng"; ID=$dong.ID })
            }
        }
    } catch {}
})

if ($null -ne $CuaSo) { try { $CuaSo.ShowDialog() | Out-Null } finally { $Global:DongHoUI.Stop(); $Global:DongHoHuy.Stop(); [EngineGG]::Cancel(); if ($null -ne $Global:TienTrinhNgam) { try { $Global:TienTrinhNgam.BeginStop($null, $null) | Out-Null } catch {} } } }