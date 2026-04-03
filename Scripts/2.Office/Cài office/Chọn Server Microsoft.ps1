# ==============================================================================
# BỘ CÀI OFFICE - MICROSOFT V600 (MASTER EDITION - FULL OPTION)
# Đặc tính: Động cơ Auto Resume, UI Download Manager, Gist Ohook Silent, Cắt cáp
# ==============================================================================

# [MODULE 1] CẤU HÌNH MẠNG & BĂNG THÔNG
[System.Net.ServicePointManager]::DefaultConnectionLimit = 1024
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::UseNagleAlgorithm = $false
[System.Net.WebRequest]::DefaultWebProxy = $null
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "SilentlyContinue"

# [MODULE 2] QUYỀN ADMIN & LUỒNG STA
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit
}
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# [MODULE 3] ĐỘNG CƠ C# (AUTO RESUME & BUFFER MAX SPEED)
$MaCSharp = @"
using System; using System.Net.Http; using System.Net.Http.Headers; using System.IO; using System.Threading.Tasks; using System.Threading;
public class DongCoTai {
    public static int PhanTram = 0; public static string TocDo = "0 MB/s"; public static string ThongTin = "0/0 MB"; public static string ThoiGian = "--:--";
    public static CancellationTokenSource CTS;
    
    public static void Reset() { PhanTram = 0; TocDo = "0 MB/s"; ThongTin = "0/0 MB"; ThoiGian = "--:--"; CTS = new CancellationTokenSource(); }
    public static void HuyTai() { if (CTS != null) { CTS.Cancel(); } }
    
    public static async Task<int> TaiFile(string link, string duongDan) {
        int soLanThu = 50; 
        for (int lan = 1; lan <= soLanThu; lan++) {
            try {
                if (CTS != null && CTS.Token.IsCancellationRequested) return -1;
                long dungLuongCu = 0;
                if (File.Exists(duongDan)) { dungLuongCu = new FileInfo(duongDan).Length; }

                using (HttpClient trinhDuyet = new HttpClient()) {
                    trinhDuyet.Timeout = TimeSpan.FromHours(5);
                    HttpRequestMessage yeuCau = new HttpRequestMessage(HttpMethod.Get, link);
                    if (dungLuongCu > 0) { yeuCau.Headers.Range = new RangeHeaderValue(dungLuongCu, null); }

                    using (var phanHoi = await trinhDuyet.SendAsync(yeuCau, HttpCompletionOption.ResponseHeadersRead, CTS.Token)) {
                        if (phanHoi.StatusCode == System.Net.HttpStatusCode.RequestedRangeNotSatisfiable) {
                            File.Delete(duongDan); continue; 
                        }
                        phanHoi.EnsureSuccessStatusCode();
                        long tongDungLuong = phanHoi.Content.Headers.ContentLength ?? -1L;
                        if (tongDungLuong > 0 && dungLuongCu > 0) { tongDungLuong += dungLuongCu; }
                        else if (tongDungLuong <= 0) { tongDungLuong = -1; }

                        FileMode cheDo = (dungLuongCu > 0 && phanHoi.StatusCode == System.Net.HttpStatusCode.PartialContent) ? FileMode.Append : FileMode.Create;
                        if (cheDo == FileMode.Create) { dungLuongCu = 0; }

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
            catch (OperationCanceledException) { 
                try { if (File.Exists(duongDan)) File.Delete(duongDan); } catch {} 
                return -1; 
            }
            catch (Exception) {
                if (CTS != null && CTS.Token.IsCancellationRequested) return -1;
                Thread.Sleep(3000); 
            }
        } return 500; 
    }
}
"@
if (-not ("DongCoTai" -as [type])) { Add-Type -TypeDefinition $MaCSharp -ReferencedAssemblies "System.Net.Http", "System.Runtime" }

# [MODULE 4] BIẾN ĐỒNG BỘ TOÀN CỤC
$Global:DongBo = [hashtable]::Synchronized(@{ NhatKy = ""; TrangThai = "Đang nạp..."; Lenh = "CHO"; FileHienTai = ""; ThuMucLuu = "" })
$Global:TrangThaiApp = [hashtable]::Synchronized(@{})
$Global:DuLieuOffice = New-Object System.Collections.ObjectModel.ObservableCollection[Object]

# [MODULE 5] GIAO DIỆN WPF
$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="OFFICE DEPLOY - V600 MASTER" Width="950" Height="750" Background="#F4F6F8" WindowStartupLocation="CenterScreen">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="130"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="MÁY CHỦ MICROSOFT - V600 MASTER" FontSize="24" FontWeight="Bold" Foreground="#1565C0"/>
            <TextBlock Text="📦 Tự Nối File | Tự Mount Setup | Gist Ohook Silent | Dọn Rác Sạch" Foreground="#555555" FontWeight="Medium" FontSize="14"/>
        </StackPanel>

        <ListView Name="DanhSach" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" BorderThickness="1">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="BẢN CÀI OFFICE (CHỈ LẤY LINK MS)" DisplayMemberBinding="{Binding Ten}" Width="450"/>
                    <GridViewColumn Header="TRẠNG THÁI" DisplayMemberBinding="{Binding TrangThai}" Width="140"/>
                    <GridViewColumn Header="TIẾN ĐỘ" DisplayMemberBinding="{Binding PhanTram}" Width="70"/>
                    <GridViewColumn Header="TỐC ĐỘ" DisplayMemberBinding="{Binding TocDo}" Width="90"/>
                    <GridViewColumn Header="DUNG LƯỢNG" DisplayMemberBinding="{Binding DungLuong}" Width="120"/>
                </GridView>
            </ListView.View>
        </ListView>

        <GroupBox Grid.Row="2" Header="NHẬT KÝ HỆ THỐNG" Margin="0,10,0,10" FontWeight="Bold">
            <TextBox Name="HopNhatKy" IsReadOnly="True" Background="#1E1E1E" Foreground="#00E676" FontFamily="Consolas" VerticalScrollBarVisibility="Auto" FontSize="12" TextWrapping="Wrap" FontWeight="Normal"/>
        </GroupBox>

        <Grid Grid.Row="3" Margin="0,5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
            <TextBox Name="HopThuMuc" IsReadOnly="True" VerticalContentAlignment="Center" Background="#FFFFFF" FontSize="14"/>
            <Button Name="NutChon" Grid.Column="1" Content="📂 CHỌN" Margin="5,0" FontWeight="Bold"/>
            <Button Name="NutMo" Grid.Column="2" Content="MỞ FOLDER" Background="#E3F2FD" FontWeight="Bold"/>
        </Grid>

        <UniformGrid Grid.Row="4" Rows="1" Columns="3" Margin="0,15">
            <CheckBox Name="HopThuoc" Content="💊 Kích hoạt Ohook (Gist Silent)" IsChecked="True" FontWeight="Bold" Foreground="#D84315" FontSize="14"/>
            <CheckBox Name="HopLoiTat" Content="📌 Đưa Shortcut ra Desktop" IsChecked="True" FontWeight="Bold" Foreground="#1565C0" FontSize="14"/>
            <CheckBox Name="HopGiuFile" Content="💾 Giữ lại file .img sau khi cài" IsChecked="False" FontWeight="Bold" FontSize="14"/>
        </UniformGrid>

        <Grid Grid.Row="5" Background="#E3F2FD" Margin="-15,0,-15,-15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="220"/><ColumnDefinition Width="120"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
            <StackPanel Margin="15,10,10,10">
                <Grid><TextBlock Name="TxtTrangThai" Text="Sẵn sàng..." FontWeight="Bold" Foreground="#1565C0"/><TextBlock Name="TxtThongTin" Text="0/0 MB" HorizontalAlignment="Right" Foreground="#666666"/></Grid>
                <ProgressBar Name="ThanhTienDo" Height="22" Margin="0,5" Foreground="#1976D2" Background="#FFFFFF"/>
            </StackPanel>
            <StackPanel Grid.Column="1" VerticalAlignment="Center" Orientation="Horizontal" HorizontalAlignment="Center">
                <TextBlock Text="Tốc độ: " Foreground="#555" FontSize="13"/>
                <TextBlock Name="TxtTocDo" Text="0 MB/s" FontWeight="Bold" Foreground="#D84315" Width="75" FontSize="13"/>
                <TextBlock Text="ETA: " Foreground="#555" FontSize="13"/>
                <TextBlock Name="TxtThoiGian" Text="--:--" FontWeight="Bold" Foreground="#2E7D32" FontSize="13"/>
            </StackPanel>
            <Button Name="NutHuy" Grid.Column="2" Content="🛑 HỦY BỎ" Margin="5,10" IsEnabled="False" Background="#FFCDD2" FontWeight="Bold" Foreground="#C62828" FontSize="14"/>
            <Button Name="NutBatDau" Grid.Column="3" Content="🚀 BẮT ĐẦU" Background="#1565C0" Foreground="White" FontWeight="Bold" FontSize="16" Margin="5,10,15,10"/>
        </Grid>
    </Grid>
</Window>
"@
$CuaSo = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]::new($MaGiaoDien)))
$DanhSach = $CuaSo.FindName("DanhSach"); $HopNhatKy = $CuaSo.FindName("HopNhatKy"); $HopThuMuc = $CuaSo.FindName("HopThuMuc"); $NutChon = $CuaSo.FindName("NutChon"); $NutMo = $CuaSo.FindName("NutMo")
$HopThuoc = $CuaSo.FindName("HopThuoc"); $HopGiuFile = $CuaSo.FindName("HopGiuFile"); $HopLoiTat = $CuaSo.FindName("HopLoiTat"); $TxtTrangThai = $CuaSo.FindName("TxtTrangThai"); $TxtThongTin = $CuaSo.FindName("TxtThongTin")
$ThanhTienDo = $CuaSo.FindName("ThanhTienDo"); $TxtTocDo = $CuaSo.FindName("TxtTocDo"); $TxtThoiGian = $CuaSo.FindName("TxtThoiGian"); $NutBatDau = $CuaSo.FindName("NutBatDau"); $NutHuy = $CuaSo.FindName("NutHuy")
$DanhSach.ItemsSource = $Global:DuLieuOffice

# [MODULE 6] LUỒNG XỬ LÝ (TÍCH HỢP GIST OHOOK CỦA TUẤN)
$KichBanXuLy = {
    param($GiaoTiep, $TrangThaiApp, $DanhSachChon, $CoThuoc, $CoGiuFile, $CoLoiTat)
    function ThemNhatKy($m) { $GiaoTiep.NhatKy += "[$((Get-Date).ToString('HH:mm:ss'))] $m`r`n" }
    
    function Tao-LoiTatDesktop {
        ThemNhatKy "📌 Đang tìm và đưa Shortcut ra Desktop..."
        $ManHinh = [Environment]::GetFolderPath("Desktop"); $WShell = New-Object -ComObject WScript.Shell
        $KhuVuc = @("${env:ProgramFiles}\Microsoft Office\root\Office16", "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16")
        $CacUngDung = @{ "WINWORD.EXE"="Word"; "EXCEL.EXE"="Excel"; "POWERPNT.EXE"="PowerPoint"; "MSACCESS.EXE"="Access"; "OUTLOOK.EXE"="Outlook" }
        $DaTao = 0
        foreach ($ThuMuc in $KhuVuc) {
            if (Test-Path $ThuMuc) {
                foreach ($FileExe in $CacUngDung.Keys) {
                    $MucTieu = Join-Path $ThuMuc $FileExe
                    if (Test-Path $MucTieu) { 
                        $Lnk = $WShell.CreateShortcut((Join-Path $ManHinh "$($CacUngDung[$FileExe]).lnk")); $Lnk.TargetPath = $MucTieu; $Lnk.Save()
                        $DaTao++
                    }
                } if ($DaTao -gt 0) { break }
            }
        }
        ThemNhatKy "📌 Đã đưa $DaTao biểu tượng Office ra Desktop."
    }

    foreach ($phanTu in $DanhSachChon) {
        if ($GiaoTiep.Lenh -eq "DUNG") { break }
        $DuoiFile = if ($phanTu.ID -match "\.img$") { ".img" } else { ".iso" }
        $FileLuu = Join-Path $GiaoTiep.ThuMucLuu (($phanTu.Ten -replace '\W','_') + $DuoiFile)
        $GiaoTiep.FileHienTai = $FileLuu
        
        # 1. TẢI DỮ LIỆU
        $TrangThaiApp[$phanTu.ID] = @{ STT="🚀 Đang tải"; PCT="0%"; SPD="--"; ETA="--"; DL="--" }
        ThemNhatKy "📡 Bắt đầu tải: $($phanTu.Ten)"
        $KetQuaTai = [DongCoTai]::TaiFile($phanTu.ID, $FileLuu).GetAwaiter().GetResult()

        if ($KetQuaTai -eq 200) {
            $TrangThaiApp[$phanTu.ID] = @{ STT="📦 Đang cài đặt"; PCT="100%"; SPD="Hoàn thành"; ETA="--"; DL="Hoàn thành" }
            
            # 2. MOUNT & CÀI ĐẶT
            try {
                ThemNhatKy "💿 Mount ổ đĩa ảo..."
                $O_Ao = Mount-DiskImage -ImagePath $FileLuu -PassThru
                $ChuCai = ($O_Ao | Get-Volume).DriveLetter + ":"
                $SetupExe = Get-ChildItem "$ChuCai\" -Filter "setup.exe" -Recurse | Select-Object -First 1
                if ($SetupExe) { 
                    ThemNhatKy "🛠 Đang chạy Setup ngầm..."
                    $TienTrinhCai = Start-Process $SetupExe.FullName -WorkingDirectory $SetupExe.DirectoryName -PassThru
                    while (-not $TienTrinhCai.HasExited) {
                        if ($GiaoTiep.Lenh -eq "DUNG") { $TienTrinhCai.Kill(); break }
                        Start-Sleep -Milliseconds 500
                    }
                }
                Dismount-DiskImage -ImagePath $FileLuu -ErrorAction SilentlyContinue | Out-Null
            } catch { ThemNhatKy "⚠️ Lỗi khi Mount hoặc chạy file cài đặt." }

            if ($GiaoTiep.Lenh -eq "DUNG") { break }

            # 3. KÍCH HOẠT OHOOK (THEO SCRIPT GIST CỦA BẠN)
            if ($CoThuoc) {
                ThemNhatKy "=========================================="
                ThemNhatKy ">>> KÍCH HOẠT OFFICE OHOOK (CHẠY NGẦM) <<<"
                ThemNhatKy "=========================================="
                
                $UrlGist = "https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd?t=$((Get-Date).Ticks)"
                $TempFile = Join-Path $env:TEMP "Ohook_Activation.cmd"
                
                ThemNhatKy "-> Đang kiểm tra kết nối Internet..."
                if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                    ThemNhatKy "   + Internet: OK"
                    try {
                        ThemNhatKy "-> Đang tải file Ohook từ Gist..."
                        $RawContent = Invoke-RestMethod -Uri $UrlGist -UseBasicParsing
                        
                        # Xử lý định dạng LF/CRLF và No BOM
                        $RawContent = $RawContent -replace "`r`n", "`n" -replace "`n", "`r`n"
                        $RawContent += "`r`n`r`n"
                        $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
                        [System.IO.File]::WriteAllText($TempFile, $RawContent, $Utf8NoBom)
                        ThemNhatKy "   + Tải và xử lý định dạng file thành công."
                        
                        ThemNhatKy "-> Đang khởi chạy Ohook ngầm (Silent Mode)..."
                        $TienTrinhThuoc = Start-Process cmd.exe -ArgumentList "/c `"$TempFile`" /Ohook" -WindowStyle Hidden -PassThru
                        
                        # Vòng lặp chờ an toàn, cho phép HỦY giữa chừng
                        while (-not $TienTrinhThuoc.HasExited) {
                            if ($GiaoTiep.Lenh -eq "DUNG") { $TienTrinhThuoc.Kill(); break }
                            Start-Sleep -Milliseconds 500
                        }
                        if ($GiaoTiep.Lenh -ne "DUNG") {
                            ThemNhatKy "   + Đã thực hiện xong quy trình Ohook."
                        }
                    } catch {
                        ThemNhatKy "!!! LỖI: Không thể tải file. Link Gist có thể bị chặn."
                    } finally {
                        if (Test-Path $TempFile) { Remove-Item $TempFile -Force -ErrorAction SilentlyContinue }
                    }
                } else {
                    ThemNhatKy "!!! LỖI: Không có mạng để tải file Ohook."
                }
            }

            # 4. TẠO LỐI TẮT & DỌN DẸP
            if ($CoLoiTat -and $GiaoTiep.Lenh -ne "DUNG") { Tao-LoiTatDesktop }
            if (-not $CoGiuFile -and $GiaoTiep.Lenh -ne "DUNG") { 
                Remove-Item $FileLuu -Force -ErrorAction SilentlyContinue
                ThemNhatKy "🧹 Đã xóa file .img." 
            }

            $TrangThaiApp[$phanTu.ID] = @{ STT="✅ Hoàn Tất"; PCT=""; SPD=""; ETA=""; DL="" }
            ThemNhatKy "🎉 XONG: $($phanTu.Ten)"
        } else { 
            # XỬ LÝ KHI BỊ LỖI HOẶC HỦY
            if ($GiaoTiep.Lenh -eq "DUNG") {
                try { if (Test-Path $FileLuu) { Remove-Item $FileLuu -Force } } catch {}
                $TrangThaiApp[$phanTu.ID] = @{ STT="🛑 Đã Hủy"; PCT=""; SPD=""; ETA=""; DL="" }
                ThemNhatKy "🛑 Đã hủy và dọn rác."
            } else {
                $TrangThaiApp[$phanTu.ID] = @{ STT="❌ Lỗi Tải"; PCT=""; SPD=""; ETA=""; DL="" }
                ThemNhatKy "❌ Tải thất bại sau 50 lần thử nối file."
            }
        }
    }
    if ($GiaoTiep.Lenh -eq "DUNG") { $GiaoTiep.TrangThai = "🛑 ĐÃ HỦY VÀ XÓA SẠCH RÁC" }
    else { $GiaoTiep.TrangThai = "✅ HOÀN TẤT TOÀN BỘ YÊU CẦU" }
}

# [MODULE 7] ĐỒNG BỘ GIAO DIỆN
$DongHoUI = New-Object System.Windows.Threading.DispatcherTimer; $DongHoUI.Interval = "0:0:0.3"
$DongHoUI.Add_Tick({
    $ThanhTienDo.Value = [DongCoTai]::PhanTram; $TxtTrangThai.Text = $Global:DongBo.TrangThai
    $TxtTocDo.Text = [DongCoTai]::TocDo; $TxtThongTin.Text = [DongCoTai]::ThongTin; $TxtThoiGian.Text = [DongCoTai]::ThoiGian
    if ($HopNhatKy.Text -ne $Global:DongBo.NhatKy) { $HopNhatKy.Text = $Global:DongBo.NhatKy; $HopNhatKy.ScrollToEnd() }
    
    foreach ($m in $Global:DuLieuOffice) { 
        if ($Global:TrangThaiApp.ContainsKey($m.ID)) { 
            $thongso = $Global:TrangThaiApp[$m.ID]
            $m.TrangThai = $thongso.STT; $m.PhanTram = $thongso.PCT; $m.TocDo = $thongso.SPD; $m.DungLuong = $thongso.DL
        } 
    }
    $DanhSach.Items.Refresh()
    if ($Global:DongBo.TrangThai -match "HOÀN TẤT|ĐÃ HỦY") { $NutBatDau.IsEnabled = $true; $NutHuy.IsEnabled = $false; $DongHoUI.Stop() }
})

# [MODULE 8] NÚT BẤM VÀ CẮT CÁP HỦY
$NutBatDau.Add_Click({
    $MucChon = @($DanhSach.SelectedItems); if ($MucChon.Count -eq 0) { [Windows.MessageBox]::Show("Vui lòng chọn bản cài Office!", "Cảnh báo", 0, 48); return }
    [DongCoTai]::Reset(); $NutBatDau.IsEnabled = $false; $NutHuy.IsEnabled = $true; $Global:DongBo.TrangThai = "Đang kết nối..."; $Global:DongBo.Lenh = "CHAY"; $Global:DongBo.ThuMucLuu = $HopThuMuc.Text
    $rs = [runspacefactory]::CreateRunspace(); $rs.ApartmentState = "STA"; $rs.Open()
    $ps = [powershell]::Create().AddScript($KichBanXuLy).AddArgument($Global:DongBo).AddArgument($Global:TrangThaiApp).AddArgument($MucChon).AddArgument($HopThuoc.IsChecked).AddArgument($HopGiuFile.IsChecked).AddArgument($HopLoiTat.IsChecked)
    $ps.Runspace = $rs; $ps.BeginInvoke(); $DongHoUI.Start()
})

$NutHuy.Add_Click({
    $NutHuy.IsEnabled = $false; $Global:DongBo.Lenh = "DUNG"; $Global:DongBo.TrangThai = "🛑 Đang cắt mạng & dọn rác..."
    [DongCoTai]::HuyTai() 
    Get-Process | Where-Object {$_.ProcessName -match "setup|inst|setu|cmd"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-ThreadJob -ScriptBlock { param($S) Start-Sleep -Seconds 2; try { Dismount-DiskImage -ImagePath $S.FileHienTai -ErrorAction SilentlyContinue | Out-Null; Remove-Item $S.FileHienTai -Force } catch {} } -ArgumentList $Global:DongBo
})

$NutChon.Add_Click({ $d = New-Object Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $HopThuMuc.Text = $d.SelectedPath } })
$NutMo.Add_Click({ if(Test-Path $HopThuMuc.Text) { Start-Process explorer.exe $HopThuMuc.Text } })

# [MODULE 9] NẠP DỮ LIỆU CSV (LỌC LINK CHUẨN MS)
$CuaSo.Add_Loaded({
    $p = if (Test-Path "D:\") {"D:\BoCaiOffice"} else {"C:\BoCaiOffice"}
    $HopThuMuc.Text = $p; if (-not (Test-Path $p)) { New-Item $p -Type Directory | Out-Null }
    try {
        $url = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv?t=$(Get-Date).Ticks"
        $csv = (Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Csv
        foreach ($r in $csv) { 
            if ($r.ID -match "^http" -and $r.ID -match "officecdn|microsoft|office\.net|azureedge") { 
                $Global:DuLieuOffice.Add([PSCustomObject]@{ Ten=$r.Name; ID=$r.ID; TrangThai="Sẵn sàng"; PhanTram=""; TocDo=""; DungLuong="" }) 
            } 
        }
        $TxtTrangThai.Text = "Sẵn sàng"
    } catch { $TxtTrangThai.Text = "❌ Lỗi mạng"; $HopNhatKy.Text += "❌ Lỗi nạp danh sách.`r`n" }
})

$CuaSo.ShowDialog() | Out-Null