Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [1] CẤU HÌNH API & GITHUB
$DanhSachKeyMaHoa = @("QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v", "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv", "QUl6YVN5Q2IzaE1LUVNOamt2bFNKbUlhTGtYcVNybFpWaFNSTThR", "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0")
$Global:DanhSachAPI = $DanhSachKeyMaHoa | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
$LinkCSV = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv"

try {
    $PhanHoi = Invoke-WebRequest -Uri $LinkCSV -UseBasicParsing -ErrorAction Stop
    $NoiDung = if ($PhanHoi.Content -is [string]) { $PhanHoi.Content } else { [System.Text.Encoding]::UTF8.GetString($PhanHoi.Content) }
    $DanhSachWin = $NoiDung | ConvertFrom-Csv | Where-Object { $_.Name -match "\.wim" }
    if (!$DanhSachWin) { throw "Danh sách trống" }
} catch { [System.Windows.MessageBox]::Show("Lỗi tải danh sách bộ cài từ GitHub!"); exit }

$Global:DongBo = [hashtable]::Synchronized(@{ TrangThai = "Vui lòng chọn cấu hình và bản cài đặt..."; TienTrinh = "SAN_SANG"; Buoc1 = ""; Buoc2 = ""; Buoc3 = ""; Buoc4 = "" })

# [2] ĐỘNG CƠ C# TẢI FILE
$MaCSharp = @"
using System; using System.Net.Http; using System.Net.Http.Headers; using System.IO; using System.Threading.Tasks; using System.Threading;
public class DongCoTai {
    public static int PhanTram = 0; public static string TocDo = "0 MB/s"; public static string ThongTin = "0/0 MB"; public static string ThoiGian = "--:--";
    public static CancellationTokenSource CTS;
    
    public static void Reset() { PhanTram = 0; TocDo = "0 MB/s"; ThongTin = "0/0 MB"; ThoiGian = "--:--"; CTS = new CancellationTokenSource(); }
    public static void HuyTai() { if (CTS != null) { CTS.Cancel(); } }
    
    public static async Task<int> TaiFile(string link, string duongDan) {
        int soLanThu = 3; 
        for (int lan = 1; lan <= soLanThu; lan++) {
            try {
                if (CTS != null && CTS.Token.IsCancellationRequested) return -1;
                long dungLuongCu = 0;
                if (File.Exists(duongDan)) { dungLuongCu = new FileInfo(duongDan).Length; }

                using (HttpClient trinhDuyet = new HttpClient()) {
                    trinhDuyet.Timeout = TimeSpan.FromHours(5);
                    trinhDuyet.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    HttpRequestMessage yeuCau = new HttpRequestMessage(HttpMethod.Get, link);
                    if (dungLuongCu > 0) { yeuCau.Headers.Range = new RangeHeaderValue(dungLuongCu, null); }

                    using (var phanHoi = await trinhDuyet.SendAsync(yeuCau, HttpCompletionOption.ResponseHeadersRead, CTS.Token)) {
                        if (phanHoi.StatusCode == System.Net.HttpStatusCode.Forbidden || (phanHoi.Content.Headers.ContentType != null && phanHoi.Content.Headers.ContentType.MediaType == "text/html")) return 403;
                        if (phanHoi.StatusCode == System.Net.HttpStatusCode.RequestedRangeNotSatisfiable) {
                            PhanTram = 100; TocDo = "XONG"; ThoiGian = "00:00";
                            return 200; 
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
            catch (OperationCanceledException) { return -1; }
            catch (Exception) { if (CTS != null && CTS.Token.IsCancellationRequested) return -1; Thread.Sleep(2000); }
        } return 500; 
    }
}
"@
if (-not ("DongCoTai" -as [type])) { Add-Type -TypeDefinition $MaCSharp -ReferencedAssemblies "System.Net.Http", "System.Runtime" }

# [3] GIAO DIỆN XAML
$GiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="WinDeploy Master (Trực Tiếp)" SizeToContent="Height" Width="480" Background="#121212" WindowStyle="None" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#1E1E1E"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="0,4"/>
            <Setter Property="MinHeight" Value="45"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" BorderBrush="#333333" BorderThickness="1" Padding="10,5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#252525"/><Setter Property="BorderBrush" Value="#00FF7F"/></Trigger></Style.Triggers>
        </Style>
    </Window.Resources>
    <Border CornerRadius="10" BorderBrush="#00FF7F" BorderThickness="1.5">
        <Grid Margin="20,20,20,20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <TextBlock Grid.Row="0" Text="WINDOWS CLOUD DEPLOY (TRỰC TIẾP)" Foreground="#00FF7F" FontSize="18" FontWeight="Black" HorizontalAlignment="Center" Margin="0,0,0,15"/>
            
            <Border Grid.Row="1" Background="#1A1A1A" CornerRadius="5" Padding="10" Margin="0,0,0,10">
                <StackPanel>
                    <TextBlock Text="CẤU HÌNH TỰ ĐỘNG HÓA:" Foreground="#00FF7F" FontSize="11" FontWeight="Bold" Margin="0,0,0,8"/>
                    
                    <Grid Margin="0,0,0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Text="Nạp Driver (.inf):" Foreground="#AAA" VerticalAlignment="Center" FontSize="11" Margin="0,0,8,0"/>
                        <TextBox Name="DuongDanDriver" Grid.Column="1" Background="#222" Foreground="#00FF7F" BorderBrush="#444" IsReadOnly="True" VerticalContentAlignment="Center" FontSize="11" Height="25"/>
                        <Button Name="NutChonDriver" Grid.Column="2" Content="..." Width="35" MinHeight="25" Margin="5,0,0,0" Padding="0" Cursor="Hand"/>
                    </Grid>
                    
                    <StackPanel Orientation="Horizontal">
                        <CheckBox Name="CheckAnyDesk" Content="Cài đặt AnyDesk" Foreground="#AAA" IsChecked="True" Margin="0,0,20,0"/>
                        <CheckBox Name="CheckUltraViewer" Content="Cài đặt UltraViewer" Foreground="#AAA" IsChecked="False"/>
                    </StackPanel>
                </StackPanel>
            </Border>

            <ScrollViewer Grid.Row="2" MaxHeight="180" VerticalScrollBarVisibility="Auto" Margin="0,5">
                <StackPanel Name="KhungChuaNut"/>
            </ScrollViewer>

            <Border Grid.Row="3" Margin="0,15,0,10" Background="#1A1A1A" Name="KhungTienTrinh" Visibility="Collapsed" CornerRadius="5" Padding="5">
                <StackPanel>
                    <TextBlock Name="buoc1" Text="○ 1. Chuẩn bị tài nguyên (Bao gồm chép Driver)" Foreground="#888888" Margin="5,3" FontSize="11"/>
                    <TextBlock Name="buoc2" Text="○ 2. Tải WIM (Tự động bỏ qua nếu đã tải xong)" Foreground="#888888" Margin="5,3" FontSize="11"/>
                    <TextBlock Name="buoc3" Text="○ 3. Tiêm kịch bản vào Lõi Boot (Chống Treo)" Foreground="#888888" Margin="5,3" FontSize="11"/>
                    <TextBlock Name="buoc4" Text="○ 4. Khởi động môi trường tự động hóa" Foreground="#888888" Margin="5,3" FontSize="11"/>
                </StackPanel>
            </Border>

            <StackPanel Grid.Row="4" Margin="0,5,0,0">
                <Grid Margin="0,0,0,5">
                    <TextBlock Name="TrangThai" Text="Sẵn sàng..." Foreground="#00FF7F" FontSize="12" FontWeight="Bold"/>
                    <TextBlock Name="PhanTram" Text="0%" Foreground="#00FF7F" FontSize="12" HorizontalAlignment="Right" FontWeight="Bold"/>
                </Grid>
                <ProgressBar Name="ThanhTienDo" Height="10" Minimum="0" Maximum="100" Value="0" Foreground="#00FF7F" Background="#222222" BorderThickness="0"/>
                
                <UniformGrid Rows="1" Columns="3" Margin="0,8,0,0">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Left"><TextBlock Text="Tốc độ: " Foreground="#777" FontSize="11"/><TextBlock Name="TocDo" Text="0 MB/s" Foreground="#00FF7F" FontSize="11"/></StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center"><TextBlock Text="Dữ liệu: " Foreground="#777" FontSize="11"/><TextBlock Name="ThongTin" Text="0/0 MB" Foreground="#00FF7F" FontSize="11"/></StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right"><TextBlock Text="Cần: " Foreground="#777" FontSize="11"/><TextBlock Name="ThoiGian" Text="--:--" Foreground="#00FF7F" FontSize="11"/></StackPanel>
                </UniformGrid>

                <Button Name="NutThoat" Content="THOÁT CHƯƠNG TRÌNH" Margin="0,15,0,0" MinHeight="35" Width="150" BorderBrush="#FF4D4D" Foreground="#FF4D4D"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$CuaSo = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader] $GiaoDien))
$KhungChuaNut = $CuaSo.FindName("KhungChuaNut"); $KhungTienTrinh = $CuaSo.FindName("KhungTienTrinh")
$TrangThai = $CuaSo.FindName("TrangThai"); $PhanTram = $CuaSo.FindName("PhanTram"); $ThanhTienDo = $CuaSo.FindName("ThanhTienDo")
$TocDo = $CuaSo.FindName("TocDo"); $ThongTin = $CuaSo.FindName("ThongTin"); $ThoiGian = $CuaSo.FindName("ThoiGian")

# SỰ KIỆN CHỌN FOLDER DRIVER
$CuaSo.FindName("NutChonDriver").Add_Click({
    $HopThoai = New-Object System.Windows.Forms.FolderBrowserDialog
    $HopThoai.Description = "CHỌN THƯ MỤC CHỨA DRIVER BUNG WIN (Sẽ tự động quét thư mục con)"
    if ($HopThoai.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $CuaSo.FindName("DuongDanDriver").Text = $HopThoai.SelectedPath
    }
})

# [4] LUỒNG XỬ LÝ 
$KichBanXuLy = {
    param($DongBo, $DanhSachKhoa, $Win, $MaCSharp, $ThuMucDriverVao, $CaiAnyDesk, $CaiUltraViewer)
    if (-not ("DongCoTai" -as [type])) { Add-Type -TypeDefinition $MaCSharp -ReferencedAssemblies "System.Net.Http", "System.Runtime" }
    
    $PhanVungC = Get-Partition -DriveLetter C
    $SoODia = $PhanVungC.DiskNumber; $SoPhanVung = $PhanVungC.PartitionNumber

    # BƯỚC 1: TÌM Ổ CHỨA & SAO CHÉP DRIVER
    $DongBo.Buoc1 = "DangChay"; $DongBo.TrangThai = "Đang kiểm tra không gian đĩa cứng..."
    
    $ODiaWinSetup = Get-Volume | Where-Object { $_.FileSystemLabel -eq "WinSetup" } | Select-Object -First 1
    if ($ODiaWinSetup -and $ODiaWinSetup.DriveLetter) {
        $KyTuODiaDuLieu = $ODiaWinSetup.DriveLetter
    } else {
        $ODiaTrong = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" -and $_.Name -ne "X" -and $_.Free -gt 6GB } | Select-Object -First 1
        if (!$ODiaTrong) {
            $DongBo.TrangThai = "Đang tạo ổ lưu trữ 6GB từ ổ C..."
            "select disk $SoODia`nselect partition $SoPhanVung`nshrink minimum=6144`ncreate partition primary`nformat quick fs=ntfs label='WinSetup'`nassign letter=T" | diskpart | Out-Null
            Start-Sleep -Seconds 3
            $ODiaWinSetupMoi = Get-Volume | Where-Object { $_.FileSystemLabel -eq "WinSetup" } | Select-Object -First 1
            $KyTuODiaDuLieu = if ($ODiaWinSetupMoi -and $ODiaWinSetupMoi.DriveLetter) { $ODiaWinSetupMoi.DriveLetter } else { "T" }
        } else { $KyTuODiaDuLieu = $ODiaTrong.Name }
    }

    # Nếu người dùng có chọn Driver, copy sang ổ tạm trước khi khởi động lại
    if (![string]::IsNullOrWhiteSpace($ThuMucDriverVao) -and (Test-Path $ThuMucDriverVao)) {
        $DongBo.TrangThai = "Đang trích xuất Driver sang phân vùng bảo vệ..."
        $DuongDanLuuDriver = "$($KyTuODiaDuLieu):\Drivers_Ngoai"
        if (-not (Test-Path $DuongDanLuuDriver)) { New-Item -ItemType Directory -Path $DuongDanLuuDriver -Force | Out-Null }
        Copy-Item -Path "$ThuMucDriverVao\*" -Destination $DuongDanLuuDriver -Recurse -Force
    }

    $DongBo.Buoc1 = "HoanTat"

    # BƯỚC 2: TẢI FILE WIM
    $DongBo.Buoc2 = "DangChay"; $DongBo.TrangThai = "Đang kiểm tra dữ liệu bộ cài..."
    $DuongDanWim = "$($KyTuODiaDuLieu):\install.wim"
    [DongCoTai]::Reset()
    
    $ThanhCong = $false
    if ((Test-Path $DuongDanWim) -and ((Get-Item $DuongDanWim).Length -gt 3GB)) {
        $DongBo.TrangThai = "Đã có sẵn bộ cài. Bỏ qua tải xuống!"
        [DongCoTai]::PhanTram = 100; [DongCoTai]::TocDo = "XONG"; [DongCoTai]::ThoiGian = "00:00"
        $ThanhCong = $true; Start-Sleep -Seconds 2
    } else {
        foreach ($Khoa in $DanhSachKhoa) {
            if ($DongBo.TienTrinh -eq "DUNG") { break }
            $LienKet = "https://www.googleapis.com/drive/v3/files/$($Win.FileID)?alt=media&key=$Khoa"
            $kq = [DongCoTai]::TaiFile($LienKet, $DuongDanWim).GetAwaiter().GetResult()
            if ($kq -eq 200) { $ThanhCong = $true; break }
            if ($kq -eq 403) { $DongBo.TrangThai = "Đổi API Key dự phòng..."; continue }
        }
    }

    if ($DongBo.TienTrinh -eq "DUNG") { $DongBo.Buoc2 = "Loi"; $DongBo.TrangThai = "ĐÃ HỦY!"; return }
    if (!$ThanhCong -or !(Test-Path $DuongDanWim) -or (Get-Item $DuongDanWim).Length -lt 100MB) { $DongBo.Buoc2 = "Loi"; $DongBo.TrangThai = "LỖI: Rớt mạng hoặc Quota chết toàn tập!"; return }
    $DongBo.Buoc2 = "HoanTat"

    # BƯỚC 3: TIÊM MÃ VÀO LÕI BOOT
    $DongBo.Buoc3 = "DangChay"; $DongBo.TrangThai = "Đang dọn dẹp hệ thống chuẩn bị bẻ khóa..."
    Get-Process dism -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process dism.exe -ArgumentList "/Cleanup-Wim" -Wait -WindowStyle Hidden | Out-Null
    reagentc /disable | Out-Null; Start-Sleep -Seconds 2
    
    $WinREPath = "C:\Windows\System32\Recovery\winre.wim"
    if (-not (Test-Path $WinREPath)) { $WinREPath = (Get-ChildItem -Path C:\Windows -Filter "winre.wim" -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1).FullName }
    
    if ($WinREPath -and (Test-Path $WinREPath)) {
        $ThuMucMount = "$($KyTuODiaDuLieu):\MountRE"
        $FileWimCopy = "$($KyTuODiaDuLieu):\winre_copy.wim"
        
        if (Test-Path $ThuMucMount) { Remove-Item $ThuMucMount -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $ThuMucMount -Force | Out-Null
        
        $DongBo.TrangThai = "Đang trích xuất Lõi Boot ra ổ an toàn..."
        attrib -R -S -H $WinREPath -ErrorAction SilentlyContinue
        Copy-Item -Path $WinREPath -Destination $FileWimCopy -Force
        attrib -R -S -H $FileWimCopy -ErrorAction SilentlyContinue
        
        $DongBo.TrangThai = "Đang Mount Lõi Boot..."
        $TrinhMount = Start-Process dism.exe -ArgumentList "/Mount-Image /ImageFile:`"$FileWimCopy`" /Index:1 /MountDir:`"$ThuMucMount`"" -Wait -WindowStyle Hidden -PassThru
        
        if ($TrinhMount.ExitCode -eq 0) {
            $DongBo.TrangThai = "Đang tiêm kịch bản..."
            $StartNet = "$ThuMucMount\Windows\System32\startnet.cmd"
            $MaTiem = "`r`nfor %%I in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist `"%%I:\auto_install.bat`" (call `"%%I:\auto_install.bat`" & exit))"
            Add-Content -Path $StartNet -Value $MaTiem -Encoding ASCII
            
            $DongBo.TrangThai = "Đang ĐÓNG GÓI Lõi Boot (Cam kết không treo)..."
            $TrinhUnmount = Start-Process dism.exe -ArgumentList "/Unmount-Image /MountDir:`"$ThuMucMount`" /Commit" -Wait -WindowStyle Hidden -PassThru
            
            if ($TrinhUnmount.ExitCode -eq 0) {
                Copy-Item -Path $FileWimCopy -Destination $WinREPath -Force
                reagentc /enable | Out-Null
                Remove-Item $FileWimCopy -Force -ErrorAction SilentlyContinue
            } else {
                Start-Process dism.exe -ArgumentList "/Unmount-Image /MountDir:`"$ThuMucMount`" /Discard" -Wait -WindowStyle Hidden | Out-Null
                $DongBo.Buoc3 = "Loi"; $DongBo.TrangThai = "LỖI: Windows Defender chặn đóng gói!"; return
            }
        } else {
            $DongBo.Buoc3 = "Loi"; $DongBo.TrangThai = "LỖI: Không thể mở file Lõi Boot!"; return
        }
    } else {
        $DongBo.Buoc3 = "Loi"; $DongBo.TrangThai = "LỖI: Không tìm thấy file winre.wim trong máy!"; return
    }
    $DongBo.Buoc3 = "HoanTat"

    # BƯỚC 4: TẠO FILE KỊCH BẢN CHỜ (TRONG MÔI TRƯỜNG WINRE)
    $DongBo.Buoc4 = "DangChay"; $DongBo.TrangThai = "Đang tạo kịch bản định dạng & bung Win..."
    
    # Tạo mã cài phần mềm động dựa vào CheckBox
    $LenhCaiPhanMem = ""
    if ($CaiAnyDesk) {
        $LenhCaiPhanMem += "echo curl.exe -L -o C:\AnyDesk.exe https://download.anydesk.com/AnyDesk.exe`r`necho C:\AnyDesk.exe --install `"C:\Program Files\AnyDesk`" --start-with-win --create-shortcuts --create-desktop-icon --silent`r`n"
    }
    if ($CaiUltraViewer) {
        # Dùng link gốc của Ultraviewer bản 6.6
        $LenhCaiPhanMem += "echo curl.exe -L -o C:\UltraViewer_Setup.exe https://dl2.ultraviewer.net/UltraViewer_Setup_6.6_vi.exe`r`necho C:\UltraViewer_Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART`r`necho del C:\UltraViewer_Setup.exe`r`n"
    }

    $KichBanBat = @"
@echo off
title TIEN TRINH TU DONG CAI DAT WINDOWS - KHONG DUOC TAT MAY!
color 0A

echo [1/4] Dang xac dinh vi tri o đia chua bo cai...
for %%I in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist "%%I:\install.wim" set SETUP_DRIVE=%%I:)

echo [2/4] Dang xoa va đinh dang lai o C cu...
(echo select disk $SoODia & echo select partition $SoPhanVung & echo format quick fs=ntfs label='Windows' & echo assign letter=W & echo exit) | diskpart

echo [3/4] Dang bung he đieu hanh moi... Vui long cho đoi!
dism /Apply-Image /ImageFile:%SETUP_DRIVE%\install.wim /Index:1 /ApplyDir:W:\

if exist "%SETUP_DRIVE%\Drivers_Ngoai" (
    echo [+++] Dang nop them DRIVER vao Windows...
    dism /Image:W:\ /Add-Driver /Driver:%SETUP_DRIVE%\Drivers_Ngoai /Recurse
)

echo [4/4] Dang nap thiet lap tu đong hoa (Bypass, Phan mem)...
md W:\Windows\Setup\Scripts
(
echo @echo off
echo manage-bde -off C:
echo reg add "HKLM\System\CurrentControlSet\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d "1" /f
echo net accounts /maxpwage:unlimited
$LenhCaiPhanMem
echo del "%%~f0"
) > W:\Windows\Setup\Scripts\SetupComplete.cmd

reg load HKLM\zSOFTWARE W:\Windows\System32\config\SOFTWARE
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f
reg unload HKLM\zSOFTWARE

(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo   ^<settings pass="oobeSystem"^>
echo     ^<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"^>
echo       ^<OOBE^>
echo         ^<HideEULAPage^>true^</HideEULAPage^>
echo         ^<HideOEMRegistrationScreen^>true^</HideOEMRegistrationScreen^>
echo         ^<HideOnlineAccountScreens^>true^</HideOnlineAccountScreens^>
echo         ^<HideWirelessSetupInOOBE^>true^</HideWirelessSetupInOOBE^>
echo         ^<ProtectYourPC^>3^</ProtectYourPC^>
echo       ^</OOBE^>
echo     ^</component^>
echo   ^</settings^>
echo ^</unattend^>
) > W:\Windows\System32\Sysprep\unattend.xml

bcdboot W:\Windows

echo HOAN TAT! He thong se khoi đong vao Win moi.
wpeutil reboot
"@
    
    $KichBanBat | Out-File -FilePath "$($KyTuODiaDuLieu):\auto_install.bat" -Encoding ASCII
    $DongBo.Buoc4 = "HoanTat"
    
    $DongBo.TrangThai = "THÀNH CÔNG! Sẽ khởi động lại vào tự động hóa sau 5 giây..."
    Start-Sleep -Seconds 2
    
    Manage-bde -protectors -disable C: -RebootCount 1 -ErrorAction SilentlyContinue | Out-Null
    reagentc /boottore | Out-Null
    shutdown /r /t 3
    $DongBo.TienTrinh = "HOAN_TAT"
}

# [5] ĐỒNG BỘ GIAO DIỆN (TIMER)
$DongHoUI = New-Object System.Windows.Threading.DispatcherTimer; $DongHoUI.Interval = "0:0:0.5"
$DongHoUI.Add_Tick({
    $TrangThai.Text = $Global:DongBo.TrangThai
    $ThanhTienDo.Value = [DongCoTai]::PhanTram; $PhanTram.Text = "$([DongCoTai]::PhanTram)%"
    $TocDo.Text = [DongCoTai]::TocDo; $ThongTin.Text = [DongCoTai]::ThongTin; $ThoiGian.Text = [DongCoTai]::ThoiGian

    foreach ($i in 1..4) {
        $Chu = $CuaSo.FindName("buoc$i")
        $tt = $Global:DongBo["Buoc$i"]
        if ($tt -eq "DangChay") { $Chu.Foreground = "#00FF7F"; $Chu.Text = $Chu.Text.Replace("○", "▶").Replace("❌", "▶") }
        if ($tt -eq "HoanTat") { $Chu.Foreground = "#AAAAAA"; $Chu.Text = $Chu.Text.Replace("▶", "✅") }
        if ($tt -eq "Loi") { $Chu.Foreground = "#FF4D4D"; $Chu.Text = $Chu.Text.Replace("▶", "❌") }
    }

    if ($Global:DongBo.TienTrinh -match "HOAN_TAT|DUNG") {
        if ($Global:DongBo.TienTrinh -eq "DUNG") { 
            $KhungChuaNut.Children | ForEach-Object { $_.IsEnabled = $true }
            $CuaSo.FindName("NutChonDriver").IsEnabled = $true
            $CuaSo.FindName("CheckAnyDesk").IsEnabled = $true
            $CuaSo.FindName("CheckUltraViewer").IsEnabled = $true
        }
        $DongHoUI.Stop()
    }
})

# [6] KHỞI CHẠY BẰNG RUNSPACE
function BatDau-TrienKhai ($Win) {
    # Lấy giá trị từ giao diện
    $DuongDanDriverChon = $CuaSo.FindName("DuongDanDriver").Text
    $ChonAnyDesk = [bool]$CuaSo.FindName("CheckAnyDesk").IsChecked
    $ChonUltraViewer = [bool]$CuaSo.FindName("CheckUltraViewer").IsChecked

    $KhungTienTrinh.Visibility = "Visible"
    $KhungChuaNut.Children | ForEach-Object { $_.IsEnabled = $false }
    $CuaSo.FindName("NutChonDriver").IsEnabled = $false
    $CuaSo.FindName("CheckAnyDesk").IsEnabled = $false
    $CuaSo.FindName("CheckUltraViewer").IsEnabled = $false
    
    $Global:DongBo.TienTrinh = "CHAY"
    
    $rs = [runspacefactory]::CreateRunspace(); $rs.ApartmentState = "STA"; $rs.Open()
    $ps = [powershell]::Create().AddScript($KichBanXuLy).AddArgument($Global:DongBo).AddArgument($Global:DanhSachAPI).AddArgument($Win).AddArgument($MaCSharp).AddArgument($DuongDanDriverChon).AddArgument($ChonAnyDesk).AddArgument($ChonUltraViewer)
    $ps.Runspace = $rs; $ps.BeginInvoke(); $DongHoUI.Start()
}

foreach ($Win in $DanhSachWin) {
    $Nut = New-Object System.Windows.Controls.Button
    $Nut.Content = "💾  $($Win.Name)"
    $Nut.Add_Click({ BatDau-TrienKhai $Win })
    $KhungChuaNut.Children.Add($Nut)
}

$CuaSo.FindName("NutThoat").Add_Click({ 
    if ($Global:DongBo.TienTrinh -eq "CHAY") { [DongCoTai]::HuyTai(); $Global:DongBo.TienTrinh = "DUNG" }
    else { $CuaSo.Close() }
})
$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$CuaSo.ShowDialog() | Out-Null