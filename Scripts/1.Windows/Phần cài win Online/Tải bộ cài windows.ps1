# ==============================================================================
# VIETTOOLBOX ISO CLIENT V301 - KIẾN TRÚC LÕI MỚI
# Đặc tính: Fix UI cắt chữ, Chống văng tuyệt đối, Auto-Resume, Reset UI an toàn
# ==============================================================================

# [PHẦN 1] THIẾT LẬP MẠNG & QUYỀN TRUY CẬP
[System.Net.ServicePointManager]::DefaultConnectionLimit = 1024
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::UseNagleAlgorithm = $false
[System.Net.WebRequest]::DefaultWebProxy = $null
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "SilentlyContinue"

try {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop; exit
    }
} catch { exit }

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# [PHẦN 2] ĐỘNG CƠ TẢI C# V8 (TỰ ĐÓNG LUỒNG & NHẢ FILE KHI BỊ HỦY)
$MaCSharp = @"
using System; using System.Net.Http; using System.Net.Http.Headers; using System.IO; using System.Threading.Tasks; using System.Threading;
public class DongCoTai {
    public static int PhanTram = 0; public static string TocDo = "0 MB/s"; public static string ThongTin = "0/0 MB"; public static string ThoiGian = "--:--";
    public static CancellationTokenSource CTS;
    
    public static void KhoiTao() { PhanTram = 0; TocDo = "0 MB/s"; ThongTin = "0/0 MB"; ThoiGian = "--:--"; CTS = new CancellationTokenSource(); }
    public static void NgatTai() { if (CTS != null) { CTS.Cancel(); } }
    
    public static async Task<int> TaiFile(string link, string duongDan) {
        int soLanThu = 5; 
        for (int lan = 1; lan <= soLanThu; lan++) {
            try {
                if (CTS != null && CTS.Token.IsCancellationRequested) return -1;
                long dungLuongCu = 0;
                if (File.Exists(duongDan)) { dungLuongCu = new FileInfo(duongDan).Length; }

                using (HttpClient trinhDuyet = new HttpClient()) {
                    trinhDuyet.Timeout = TimeSpan.FromHours(10); 
                    trinhDuyet.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    HttpRequestMessage yeuCau = new HttpRequestMessage(HttpMethod.Get, link);
                    if (dungLuongCu > 0) { yeuCau.Headers.Range = new RangeHeaderValue(dungLuongCu, null); }

                    using (var phanHoi = await trinhDuyet.SendAsync(yeuCau, HttpCompletionOption.ResponseHeadersRead, CTS.Token)) {
                        if (phanHoi.StatusCode == System.Net.HttpStatusCode.Forbidden || (phanHoi.Content.Headers.ContentType != null && phanHoi.Content.Headers.ContentType.MediaType == "text/html")) return 403;
                        if (phanHoi.StatusCode == System.Net.HttpStatusCode.RequestedRangeNotSatisfiable) { File.Delete(duongDan); continue; }
                        
                        phanHoi.EnsureSuccessStatusCode();
                        long tongDungLuong = phanHoi.Content.Headers.ContentLength ?? -1L;
                        if (tongDungLuong > 0 && dungLuongCu > 0) { tongDungLuong += dungLuongCu; }

                        FileMode cheDo = (dungLuongCu > 0 && phanHoi.StatusCode == System.Net.HttpStatusCode.PartialContent) ? FileMode.Append : FileMode.Create;

                        using (var luongMang = await phanHoi.Content.ReadAsStreamAsync())
                        using (var luongFile = new FileStream(duongDan, cheDo, FileAccess.Write, FileShare.ReadWrite)) {
                            byte[] boNhoDem = new byte[4194304]; 
                            int docDuoc; DateTime thoiGianBatDau = DateTime.Now;
                            
                            while ((docDuoc = await luongMang.ReadAsync(boNhoDem, 0, boNhoDem.Length, CTS.Token)) > 0) {
                                await luongFile.WriteAsync(boNhoDem, 0, docDuoc, CTS.Token);
                                long daTai = luongFile.Length;
                                if (tongDungLuong > 0) {
                                    PhanTram = (int)((daTai * 100) / tongDungLuong);
                                    double thoiGianQua = (DateTime.Now - thoiGianBatDau).TotalSeconds;
                                    if (thoiGianQua > 0) {
                                        double byteTrenGiay = (daTai - dungLuongCu) / thoiGianQua;
                                        if (byteTrenGiay > 0) {
                                            TocDo = string.Format("{0:F2} MB/s", byteTrenGiay / 1048576.0);
                                            ThongTin = string.Format("{0:F2} / {1:F2} MB", daTai / 1048576.0, tongDungLuong / 1048576.0);
                                            double giayConLai = (tongDungLuong - daTai) / byteTrenGiay;
                                            TimeSpan ts = TimeSpan.FromSeconds(giayConLai);
                                            ThoiGian = string.Format("{0:D2}:{1:D2}", ts.Minutes, ts.Seconds);
                                        }
                                    }
                                }
                            }
                        }
                    } return 200; 
                }
            } 
            catch (OperationCanceledException) { return -1; }
            catch (Exception) {
                if (CTS != null && CTS.Token.IsCancellationRequested) return -1;
                Thread.Sleep(3000); 
            }
        } return 500; 
    }
}
"@
if (-not ("DongCoTai" -as [type])) { Add-Type -TypeDefinition $MaCSharp -ReferencedAssemblies "System.Net.Http", "System.Runtime" }

# [PHẦN 3] BIẾN ĐỒNG BỘ TOÀN CỤC (TRẠM TRUNG CHUYỂN)
$Global:HeThong = [hashtable]::Synchronized(@{ 
    TrangThai = "Sẵn sàng"; 
    NhatKy = ""; 
    TinHieu = "DUNG"; 
    ThuMucLuu = "";
    FileDangTai = ""
})
$Global:ChiTietTungFile = [hashtable]::Synchronized(@{})
$Global:DanhSachHienThi = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Global:KhoaAPI = @("QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0", "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v", "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFRnc3M5MDc4QThv")

# [PHẦN 4] GIAO DIỆN (UI) MỚI SẠCH SẼ (ĐÃ FIX LAYOUT HÀNG CUỐI)
$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VIETTOOLBOX ISO - V301 (LAYOUT FIXED)" Width="950" Height="750" WindowStartupLocation="CenterScreen" Background="#F8FAFC">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="130"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="VIETTOOLBOX ISO CLIENT V301" FontSize="26" FontWeight="Bold" Foreground="#0F172A"/>
            <TextBlock Name="TxtTrangThaiChung" Text="🔄 Đang khởi tạo hệ thống..." Foreground="#D97706" FontWeight="Bold"/>
        </StackPanel>

        <ListView Name="BangDanhSach" Grid.Row="1" Background="White" BorderBrush="#CBD5E1" BorderThickness="1">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="45"><GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check, Mode=TwoWay}"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                    <GridViewColumn Header="TÊN FILE (GOOGLE DRIVE)" DisplayMemberBinding="{Binding Name}" Width="450"/>
                    <GridViewColumn Header="TRẠNG THÁI" DisplayMemberBinding="{Binding Status}" Width="130"/>
                    <GridViewColumn Header="TIẾN ĐỘ" DisplayMemberBinding="{Binding Percent}" Width="70"/>
                    <GridViewColumn Header="TỐC ĐỘ" DisplayMemberBinding="{Binding Speed}" Width="80"/>
                    <GridViewColumn Header="DUNG LƯỢNG" DisplayMemberBinding="{Binding Size}" Width="110"/>
                </GridView>
            </ListView.View>
        </ListView>

        <GroupBox Grid.Row="2" Header="NHẬT KÝ HOẠT ĐỘNG" Margin="0,15,0,10" FontWeight="Bold" Foreground="#334155">
            <TextBox Name="HopNhatKy" IsReadOnly="True" Background="#0F172A" Foreground="#10B981" FontFamily="Consolas" VerticalScrollBarVisibility="Auto" FontSize="12" TextWrapping="Wrap" FontWeight="Normal" BorderThickness="0"/>
        </GroupBox>

        <Grid Grid.Row="3" Margin="0,5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="70"/><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
            <TextBlock Text="LƯU TẠI:" VerticalAlignment="Center" FontWeight="Bold" Foreground="#475569"/>
            <TextBox Name="HopDuongDan" Grid.Column="1" Height="32" IsReadOnly="True" VerticalContentAlignment="Center" Background="#FFFFFF" FontSize="13" BorderBrush="#CBD5E1"/>
            <Button Name="NutChon" Grid.Column="2" Content="📂 CHỌN" Margin="8,0,0,0" FontWeight="Bold" Background="#E2E8F0" BorderThickness="0"/>
            <Button Name="NutMo" Grid.Column="3" Content="MỞ FOLDER" Margin="8,0,0,0" Background="#BAE6FD" FontWeight="Bold" BorderThickness="0"/>
        </Grid>

        <Grid Grid.Row="4" Margin="0,15,0,0">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="240"/><ColumnDefinition Width="110"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
            
            <StackPanel Margin="0,0,15,0" VerticalAlignment="Center">
                <Grid Margin="0,0,0,5"><TextBlock Name="TxtTrangThaiNho" Text="Sẵn sàng..." FontWeight="Bold" Foreground="#0F172A"/><TextBlock Name="TxtPhanTram" Text="0%" HorizontalAlignment="Right" FontWeight="Bold" Foreground="#047857"/></Grid>
                <ProgressBar Name="ThanhTienDo" Height="14" Foreground="#0EA5E9" Background="#E2E8F0" BorderThickness="0"/>
            </StackPanel>
            
            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="5,0" Orientation="Horizontal" HorizontalAlignment="Center">
                <TextBlock Text="Tốc độ: " Foreground="#64748B" FontSize="13" Padding="0,2,0,0"/>
                <TextBlock Name="TxtTocDo" Text="0 MB/s" FontWeight="Bold" Foreground="#EA580C" Width="80" FontSize="13" Padding="0,2,0,0"/>
                <TextBlock Text="ETA: " Foreground="#64748B" FontSize="13" Padding="0,2,0,0"/>
                <TextBlock Name="TxtThoiGian" Text="--:--" FontWeight="Bold" Foreground="#047857" FontSize="13" Padding="0,2,0,0" MinWidth="45"/>
            </StackPanel>
            
            <Button Name="NutHuy" Grid.Column="2" Content="🛑 HỦY" Margin="8,0" IsEnabled="False" Background="#FECDD3" FontWeight="Bold" Foreground="#BE123C" FontSize="14" BorderThickness="0"/>
            <Button Name="NutTai" Grid.Column="3" Content="🚀 BẮT ĐẦU" Height="48" Background="#0284C7" Foreground="White" FontWeight="Bold" FontSize="16" BorderThickness="0"/>
        </Grid>
    </Grid>
</Window>
"@
$XAMLReader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGiaoDien)))
$CuaSoChinh = [Windows.Markup.XamlReader]::Load($XAMLReader)

# Gắn biến UI
$BangDanhSach = $CuaSoChinh.FindName("BangDanhSach"); $HopNhatKy = $CuaSoChinh.FindName("HopNhatKy"); $HopDuongDan = $CuaSoChinh.FindName("HopDuongDan")
$NutChon = $CuaSoChinh.FindName("NutChon"); $NutMo = $CuaSoChinh.FindName("NutMo"); $TxtTrangThaiChung = $CuaSoChinh.FindName("TxtTrangThaiChung")
$TxtPhanTram = $CuaSoChinh.FindName("TxtPhanTram"); $ThanhTienDo = $CuaSoChinh.FindName("ThanhTienDo"); $TxtTocDo = $CuaSoChinh.FindName("TxtTocDo")
$TxtThoiGian = $CuaSoChinh.FindName("TxtThoiGian"); $TxtTrangThaiNho = $CuaSoChinh.FindName("TxtTrangThaiNho"); $NutTai = $CuaSoChinh.FindName("NutTai"); $NutHuy = $CuaSoChinh.FindName("NutHuy")
$BangDanhSach.ItemsSource = $Global:DanhSachHienThi

# [PHẦN 5] LUỒNG XỬ LÝ BACKGROUND (ĐỘC LẬP HOÀN TOÀN)
$KichBanTai = {
    param($HeThong, $ChiTiet, $DanhSachTai, $KhoaB64)
    function GhiLog($m) { $HeThong.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] $m`r`n" }
    function GiaiMa($m, $i) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($m[$i])) }
    
    try {
        $IdxKhoa = 0
        foreach ($File in $DanhSachTai) {
            if ($HeThong.TinHieu -eq "DUNG") { break }
            $DuongDanLuu = Join-Path $HeThong.ThuMucLuu ($File.Name.Replace(" ", "_") + ".iso")
            $HeThong.FileDangTai = $DuongDanLuu
            
            $ChiTiet[$File.ID] = @{ STT="🚀 Đang tải"; PCT="0%"; SPD="--"; SZ="--" }
            GhiLog "📡 Kết nối: $($File.Name)"
            
            $TaiThanhCong = $false; $SoLanThu = 0
            while (-not $TaiThanhCong -and $SoLanThu -lt $KhoaB64.Count -and $HeThong.TinHieu -ne "DUNG") {
                $Link = "https://www.googleapis.com/drive/v3/files/$($File.ID)?alt=media&key=$(GiaiMa $KhoaB64 $IdxKhoa)&acknowledgeAbuse=true"
                $KetQua = [DongCoTai]::TaiFile($Link, $DuongDanLuu).GetAwaiter().GetResult()
                
                if ($KetQua -eq 200) { $TaiThanhCong = $true }
                elseif ($KetQua -eq 403) {
                    $IdxKhoa = ($IdxKhoa + 1) % $KhoaB64.Count
                    GhiLog "⚠️ Hết băng thông! Chuyển sang API Key dự phòng..."
                    $SoLanThu++
                } else { break }
            }

            if ($TaiThanhCong) {
                $ChiTiet[$File.ID] = @{ STT="✅ Hoàn Tất"; PCT="100%"; SPD="Hoàn thành"; SZ="Xong" }
                GhiLog "🎉 Đã tải xong: $($File.Name)"
            }
        }
    } catch { GhiLog "❌ LỖI BACKGROUND: $($_.Exception.Message)" }
    
    # Luồng tải kết thúc, báo tín hiệu về cho Giao diện biết
    if ($HeThong.TinHieu -eq "DUNG") { $HeThong.TrangThai = "DA_NGAT" } else { $HeThong.TrangThai = "HOAN_TAT" }
}

# [PHẦN 6] KIỂM SOÁT GIAO DIỆN & XỬ LÝ HỦY AN TOÀN
$TimerGiaoDien = New-Object System.Windows.Threading.DispatcherTimer
$TimerGiaoDien.Interval = "0:0:0.3"
$TimerGiaoDien.Add_Tick({
    if ($null -ne $CuaSoChinh -and $CuaSoChinh.IsVisible) {
        $ThanhTienDo.Value = [DongCoTai]::PhanTram
        $TxtPhanTram.Text = "$([DongCoTai]::PhanTram)%"
        $TxtTocDo.Text = [DongCoTai]::TocDo
        $TxtThoiGian.Text = [DongCoTai]::ThoiGian
        if ($HopNhatKy.Text -ne $Global:HeThong.NhatKy) { $HopNhatKy.Text = $Global:HeThong.NhatKy; $HopNhatKy.ScrollToEnd() }
        
        foreach ($Item in $Global:DanhSachHienThi) { 
            if ($Global:ChiTietTungFile.ContainsKey($Item.ID)) { 
                $Data = $Global:ChiTietTungFile[$Item.ID]
                if ($Data -is [hashtable]) { 
                    $Item.Status = $Data.STT; $Item.Percent = $Data.PCT; $Item.Speed = $Data.SPD; $Item.Size = $Data.SZ 
                } else { $Item.Status = $Data }
            } 
        }
        $BangDanhSach.Items.Refresh()

        if ($Global:HeThong.TrangThai -eq "DA_NGAT") {
            $TxtTrangThaiNho.Text = "🛑 Đang dọn dẹp rác..."
            
            if ($Global:HeThong.FileDangTai -and (Test-Path $Global:HeThong.FileDangTai)) {
                try { Remove-Item $Global:HeThong.FileDangTai -Force -ErrorAction SilentlyContinue } catch {}
            }

            foreach ($Item in $Global:DanhSachHienThi) {
                $Item.Check = $false
                $Global:ChiTietTungFile[$Item.ID] = @{ STT="Sẵn sàng"; PCT=""; SPD=""; SZ="" }
            }
            $ThanhTienDo.Value = 0; $TxtPhanTram.Text = "0%"; $TxtTocDo.Text = "0 MB/s"; $TxtThoiGian.Text = "--:--"
            $HopNhatKy.Text += "[$((Get-Date).ToString('HH:mm:ss'))] 🛑 Đã hủy tải. Reset toàn bộ hệ thống.`r`n"
            $HopNhatKy.ScrollToEnd()
            $TxtTrangThaiNho.Text = "Sẵn sàng..."
            
            $Global:HeThong.TrangThai = "CHO" 
            $NutTai.IsEnabled = $true; $NutHuy.IsEnabled = $false
            $TimerGiaoDien.Stop()
        }
        elseif ($Global:HeThong.TrangThai -eq "HOAN_TAT") {
            $TxtTrangThaiNho.Text = "✅ Hoàn tất toàn bộ!"
            $Global:HeThong.TrangThai = "CHO"
            $NutTai.IsEnabled = $true; $NutHuy.IsEnabled = $false
            $TimerGiaoDien.Stop()
        } else {
            $TxtTrangThaiNho.Text = $Global:HeThong.TrangThai
        }
    }
})

# [PHẦN 7] SỰ KIỆN NÚT BẤM (GỌN GÀNG, KHÔNG LÀM NẶNG UI)
$NutTai.Add_Click({
    $DuLieuChon = @($Global:DanhSachHienThi | Where-Object { $_.Check -eq $true })
    if ($DuLieuChon.Count -eq 0) { [Windows.MessageBox]::Show("Sếp chưa chọn bản ISO nào để tải!", "Báo Cáo", 0, 48); return }
    
    [DongCoTai]::KhoiTao()
    $NutTai.IsEnabled = $false; $NutHuy.IsEnabled = $true
    $Global:HeThong.TinHieu = "CHAY"; $Global:HeThong.TrangThai = "Đang kết nối API..."
    $Global:HeThong.ThuMucLuu = $HopDuongDan.Text
    $Global:HeThong.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] 🚀 Bắt đầu nổ máy tải...`r`n"
    
    $DanhSachTruyenDua = @()
    foreach ($Item in $DuLieuChon) { 
        $DanhSachTruyenDua += @{ ID = $Item.ID; Name = $Item.Name }
        $Global:ChiTietTungFile[$Item.ID] = @{ STT="⏳ Chờ..."; PCT=""; SPD=""; SZ="" }
    }
    
    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $TienTrinh = [powershell]::Create().AddScript($KichBanTai).AddArgument($Global:HeThong).AddArgument($Global:ChiTietTungFile).AddArgument($DanhSachTruyenDua).AddArgument($Global:KhoaAPI)
    $TienTrinh.Runspace = $MoiTruong; $TienTrinh.BeginInvoke()
    
    $TimerGiaoDien.Start()
})

$NutHuy.Add_Click({
    $NutHuy.IsEnabled = $false
    $Global:HeThong.TrangThai = "🛑 Đang gửi lệnh ngắt tải..."
    $Global:HeThong.TinHieu = "DUNG"
    [DongCoTai]::NgatTai() 
})

$NutChon.Add_Click({ 
    $HopThoai = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($HopThoai.ShowDialog() -eq "OK") { $HopDuongDan.Text = $HopThoai.SelectedPath } 
})
$NutMo.Add_Click({ if(Test-Path $HopDuongDan.Text) { Start-Process explorer.exe $HopDuongDan.Text } })

# [PHẦN 8] NẠP DỮ LIỆU & KHỞI CHẠY (BẢO VỆ SHOWDIALOG)
function TaiCSV {
    try {
        $Link = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv?t=$(Get-Date).Ticks"
        $Csv = (Invoke-WebRequest $Link -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Csv
        $Global:DanhSachHienThi.Clear()
        foreach ($Dong in $Csv) { $Global:DanhSachHienThi.Add([PSCustomObject]@{ Check=$false; Name=$Dong.Name; ID=$Dong.FileID; Status="Sẵn sàng"; Percent=""; Speed=""; Size="" }) }
        $TxtTrangThaiChung.Text = "✅ Nạp dữ liệu hoàn tất ($($Global:DanhSachHienThi.Count) ISO)."
    } catch { $TxtTrangThaiChung.Text = "❌ Không có Internet hoặc bị chặn GitHub." }
}

$CuaSoChinh.Add_Loaded({
    $HopDuongDan.Text = Join-Path ([Environment]::GetFolderPath("Desktop")) "VietToolbox_ISO"
    if (-not (Test-Path $HopDuongDan.Text)) { New-Item $HopDuongDan.Text -Type Directory | Out-Null }
    TaiCSV
})

if ($null -ne $CuaSoChinh) { 
    try { $CuaSoChinh.ShowDialog() | Out-Null } 
    finally { $TimerGiaoDien.Stop() } 
}