# ==========================================================
# CÔNG CỤ TRIỂN KHAI MICROSOFT OFFICE (BẢN V219)
# Sửa lỗi: Cấu trúc Try/Catch chống bóp băng thông Google Drive
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# Tối ưu giới hạn kết nối mạng của Windows để tải mượt hơn
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms, System.Net.Http

# 1. BIẾN TOÀN CỤC CHỐNG LỖI
$Global:DuLieuDongBo = [hashtable]::Synchronized(@{
    LenhHienTai = "CHO_DOI"
    ChiSoKhoaApi = 0
    TienDo = 0
    TocDoTai = "-- MB/s"
    TrangThaiHeThong = "Hệ thống sẵn sàng..."
    DuongDanLuuKieuFile = ""
    DuongDanPhanMemGiaiNen = ""
})

$Global:TrangThaiTungUngDung = [hashtable]::Synchronized(@{})

$Global:DanhSachKhoaApi = @(
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0",
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR",
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v",
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv"
)

$Global:MayChuChayNgam = $null
$Global:KhongGianChayNgam = $null

# 2. GIAO DIỆN XAML
$MaGiaoDienXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="CÔNG CỤ TRIỂN KHAI MICROSOFT OFFICE V219 (TĂNG TỐC MẠNG)" Width="820" Height="650" 
        WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI" ResizeMode="NoResize">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,10">
            <StackPanel VerticalAlignment="Center">
                <TextBlock Text="TRUNG TÂM TRIỂN KHAI MICROSOFT OFFICE V219" FontSize="20" FontWeight="Bold" Foreground="#1A237E"/>
                <TextBlock Name="NhanKiemTraGiaiNen" Text="🔍 Đang kiểm tra hệ thống..." Foreground="#FF9800" FontWeight="SemiBold"/>
            </StackPanel>
            <Button Name="NutTaiLaiDanhSach" Content="🔄 TẢI LẠI DANH SÁCH" HorizontalAlignment="Right" Padding="10,5" Background="#CFD8DC" FontWeight="SemiBold" BorderThickness="0" Cursor="Hand"/>
        </Grid>

        <ListView Name="BangDanhSachOffice" Grid.Row="1" Background="White" Margin="0,0,0,10" BorderBrush="#B0BEC5" SelectionMode="Multiple">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="45">
                        <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Path=IsSelected, RelativeSource={RelativeSource AncestorType=ListViewItem}}"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="PHIÊN BẢN OFFICE" DisplayMemberBinding="{Binding Name}" Width="450"/>
                    <GridViewColumn Header="TRẠNG THÁI" Width="200" DisplayMemberBinding="{Binding Status}"/>
                </GridView>
            </ListView.View>
        </ListView>

        <Border Grid.Row="2" Background="White" CornerRadius="5" Padding="10" Margin="0,0,0,10" BorderBrush="#CFD8DC" BorderThickness="1">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="90"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                <TextBlock Text="LƯU ISO TẠI:" FontWeight="Bold" VerticalAlignment="Center"/><TextBox Name="OHienThiDuongDan" Grid.Column="1" Height="25" IsReadOnly="True" Background="#ECEFF1" Margin="5,0" VerticalContentAlignment="Center"/><Button Name="NutChonDuongDan" Grid.Column="2" Content="CHỌN" Height="25" FontWeight="Bold" Background="#90A4AE" Foreground="White" BorderThickness="0"/></Grid>
        </Border>

        <UniformGrid Grid.Row="3" Rows="1" Columns="2" Margin="0,0,0,10">
            <Border Background="#E3F2FD" CornerRadius="5" Padding="8" Margin="0,0,5,0" BorderBrush="#BBDEFB" BorderThickness="1">
                <StackPanel Orientation="Horizontal"><TextBlock Text="KÍCH HOẠT BẢN QUYỀN:" FontWeight="Bold" Margin="0,0,10,0" VerticalAlignment="Center"/><RadioButton Name="TuyChonKichHoatCo" Content="Có" IsChecked="True" FontWeight="Bold" Foreground="#D32F2F" VerticalAlignment="Center" Margin="0,0,10,0"/><RadioButton Name="TuyChonKichHoatKhong" Content="Không" VerticalAlignment="Center"/></StackPanel>
            </Border>
            <Border Background="#FFF3E0" CornerRadius="5" Padding="8" Margin="5,0,0,0" BorderBrush="#FFE0B2" BorderThickness="1">
                <StackPanel Orientation="Horizontal"><TextBlock Text="QUẢN LÝ ISO:" FontWeight="Bold" Margin="0,0,10,0" VerticalAlignment="Center"/><RadioButton Name="TuyChonGiuISO" Content="Giữ lại" IsChecked="True" FontWeight="Bold" Foreground="#E65100" VerticalAlignment="Center" Margin="0,0,10,0"/><RadioButton Name="TuyChonXoaISO" Content="Xóa bỏ" VerticalAlignment="Center"/></StackPanel>
            </Border>
        </UniformGrid>

        <StackPanel Grid.Row="5" Margin="0,0,0,10">
            <Grid><TextBlock Name="NhanTrangThaiHeThong" Text="Hệ thống sẵn sàng..." FontWeight="SemiBold" Foreground="#1565C0"/><TextBlock Name="NhanHienThiTocDo" Text="-- MB/s" FontWeight="Bold" Foreground="#D84315" TextAlignment="Right"/></Grid>
            <ProgressBar Name="ThanhChayTienDo" Height="15" Margin="0,5,0,0" Foreground="#2E7D32" BorderThickness="0"/>
        </StackPanel>

        <Grid Grid.Row="6">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="2*"/></Grid.ColumnDefinitions>
            <Button Name="NutHuyBoThaoTac" Grid.Column="0" Content="🛑 HỦY LỆNH" Height="45" Background="#EF9A9A" FontWeight="Bold" IsEnabled="False" BorderThickness="0"/>
            <Button Name="NutMoThuMucLuu" Grid.Column="2" Content="📁 MỞ THƯ MỤC" Height="45" Background="#FFF59D" FontWeight="Bold" BorderThickness="0"/>
            <Button Name="NutBatDauCaiDat" Grid.Column="4" Content="🚀 BẮT ĐẦU CÀI ĐẶT NGAY" Height="45" Background="#D32F2F" Foreground="White" FontWeight="Bold" FontSize="15" BorderThickness="0"/>
        </Grid>
    </Grid>
</Window>
"@

try {
    $BoDocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGiaoDienXaml)))
    $GiaoDienChinh = [Windows.Markup.XamlReader]::Load($BoDocXml)
} catch { Write-Host "Lỗi tải giao diện."; exit }

# LIÊN KẾT BIẾN GIAO DIỆN
$Global:BangDanhSachOffice = $GiaoDienChinh.FindName("BangDanhSachOffice")
$Global:NhanKiemTraGiaiNen = $GiaoDienChinh.FindName("NhanKiemTraGiaiNen")
$Global:OHienThiDuongDan = $GiaoDienChinh.FindName("OHienThiDuongDan")
$Global:NutChonDuongDan = $GiaoDienChinh.FindName("NutChonDuongDan")
$Global:NhanTrangThaiHeThong = $GiaoDienChinh.FindName("NhanTrangThaiHeThong")
$Global:NhanHienThiTocDo = $GiaoDienChinh.FindName("NhanHienThiTocDo")
$Global:ThanhChayTienDo = $GiaoDienChinh.FindName("ThanhChayTienDo")
$Global:NutHuyBoThaoTac = $GiaoDienChinh.FindName("NutHuyBoThaoTac")
$Global:NutBatDauCaiDat = $GiaoDienChinh.FindName("NutBatDauCaiDat")
$Global:NutTaiLaiDanhSach = $GiaoDienChinh.FindName("NutTaiLaiDanhSach")
$Global:TuyChonKichHoatCo = $GiaoDienChinh.FindName("TuyChonKichHoatCo")
$Global:TuyChonGiuISO = $GiaoDienChinh.FindName("TuyChonGiuISO")

# 3. KỊCH BẢN CHẠY NGẦM HOÀN TOÀN ĐỘC LẬP (ĐÃ CẤU TRÚC LẠI TRY/CATCH)
$KichBanXuLyNgam = {
    param($DuLieuDauVao)
    Add-Type -AssemblyName System.Net.Http
    $DongBo = $DuLieuDauVao.DongBo
    $DanhSachCaiDat = $DuLieuDauVao.DanhSach
    $KhoaApi = $DuLieuDauVao.KhoaApi
    $TrangThaiNho = $DuLieuDauVao.TrangThaiNho

    try {
        foreach ($PhanMem in $DanhSachCaiDat) {
            if ($DongBo.LenhHienTai -eq "HUY") { break }
            
            $TenTapTin = ($PhanMem.Name -replace '[\\/:*?"<>|()\s]', '_') + ".iso"
            $DuongDanIsoHoanChinh = Join-Path $DongBo.DuongDanLuuKieuFile $TenTapTin
            $DongBo.TrangThaiHeThong = "🚀 Đang tải: $($PhanMem.Name)..."
            $TrangThaiNho[$PhanMem.ID] = "⏳ Đang tải dữ liệu..."
            
            $KiemTraHoanTatTai = $false
            while (-not $KiemTraHoanTatTai -and $DongBo.LenhHienTai -ne "HUY") {
                $KhoaSuDung = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($KhoaApi[$DongBo.ChiSoKhoaApi]))
                $DuongDanTaiVe = "https://www.googleapis.com/drive/v3/files/$($PhanMem.ID)?alt=media&key=$KhoaSuDung"
                
                try {
                    $MayKhachHttp = New-Object System.Net.Http.HttpClient; $MayKhachHttp.Timeout = [System.TimeSpan]::FromSeconds(30)
                    $DungLuongDaTai = 0; if (Test-Path $DuongDanIsoHoanChinh) { $DungLuongDaTai = (Get-Item $DuongDanIsoHoanChinh).Length }
                    
                    $YeuCauHttp = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $DuongDanTaiVe)
                    if ($DungLuongDaTai -gt 0) { $YeuCauHttp.Headers.Add("Range", "bytes=$DungLuongDaTai-") }
                    
                    $KetQuaPhanHoi = $MayKhachHttp.SendAsync($YeuCauHttp, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                    if (-not $KetQuaPhanHoi.IsSuccessStatusCode) {
                        $MaLoiMang = [int]$KetQuaPhanHoi.StatusCode
                        if ($MaLoiMang -eq 403 -or $MaLoiMang -eq 429) { $DongBo.ChiSoKhoaApi = ($DongBo.ChiSoKhoaApi + 1) % $KhoaApi.Count; continue }
                        if ($MaLoiMang -eq 416) { $KiemTraHoanTatTai = $true; continue } # File đã tải xong 100%
                        throw "Gặp sự cố mạng với mã lỗi $MaLoiMang"
                    }
                    
                    $TongDungLuongFile = if ($KetQuaPhanHoi.Content.Headers.ContentLength) { $KetQuaPhanHoi.Content.Headers.ContentLength + $DungLuongDaTai } else { 0 }
                    $TienTrinhNhanDuLieu = $KetQuaPhanHoi.Content.ReadAsStreamAsync().Result
                    $TienTrinhGhiDuLieu = New-Object System.IO.FileStream($DuongDanIsoHoanChinh, [System.IO.FileMode]::Append)
                    
                    $BoNhoDemTrungGian = New-Object byte[] 1048576 # 1MB Buffer
                    $DongHoBamGio = [System.Diagnostics.Stopwatch]::StartNew()
                    $DongHoKiemTraBopBangThong = [System.Diagnostics.Stopwatch]::StartNew()
                    $LuuLuongVuaTai = 0
                    
                    # BLOCK ĐỌC GHI DỮ LIỆU ĐƯỢC BỌC KỸ TRONG TRY/FINALLY 
                    try {
                        while ($true) {
                            if ($DongBo.LenhHienTai -eq "HUY") { throw "HUY_LENH" }
                            $TacVuDocBoNho = $TienTrinhNhanDuLieu.ReadAsync($BoNhoDemTrungGian, 0, $BoNhoDemTrungGian.Length)
                            
                            while (-not $TacVuDocBoNho.IsCompleted) {
                                if ($DongBo.LenhHienTai -eq "HUY") { throw "HUY_LENH" }
                                [System.Threading.Thread]::Sleep(100)
                            }
                            if ($DongBo.LenhHienTai -eq "HUY") { throw "HUY_LENH" }
                            
                            $SoLuongByteDocThanhCong = $TacVuDocBoNho.Result
                            if ($SoLuongByteDocThanhCong -le 0) { $KiemTraHoanTatTai = $true; break }
                            
                            $TienTrinhGhiDuLieu.Write($BoNhoDemTrungGian, 0, $SoLuongByteDocThanhCong)
                            $DungLuongDaTai += $SoLuongByteDocThanhCong; $LuuLuongVuaTai += $SoLuongByteDocThanhCong
                            
                            if ($DongHoBamGio.ElapsedMilliseconds -ge 1000) {
                                $TocDoHienTai = ($LuuLuongVuaTai / $DongHoBamGio.Elapsed.TotalSeconds) / 1MB
                                $DongBo.TienDo = if ($TongDungLuongFile -gt 0) { [int](($DungLuongDaTai / $TongDungLuongFile) * 100) } else { 0 }
                                $DongBo.TocDoTai = "Khóa $($DongBo.ChiSoKhoaApi+1) | $([Math]::Round($TocDoHienTai, 2)) MB/s"
                                
                                # TÍNH NĂNG CHỐNG BÓP BĂNG THÔNG: Rớt dưới 0.3 MB/s trong 5 giây thì ném tín hiệu đổi Key
                                if ($TocDoHienTai -lt 0.3 -and $DongHoKiemTraBopBangThong.ElapsedMilliseconds -gt 5000) {
                                    throw "BOP_BANG_THONG"
                                }
                                
                                $LuuLuongVuaTai = 0; $DongHoBamGio.Restart()
                            }
                        }
                    } finally {
                        # Đảm bảo tắt mọi luồng mạng dù có gặp lỗi hay không
                        if ($null -ne $TienTrinhGhiDuLieu) { $TienTrinhGhiDuLieu.Dispose() }
                        if ($null -ne $TienTrinhNhanDuLieu) { $TienTrinhNhanDuLieu.Dispose() }
                        if ($null -ne $MayKhachHttp) { $MayKhachHttp.Dispose() }
                    }
                } catch {
                    # ĐÂY LÀ NƠI HỨNG TÍN HIỆU ĐỔI KEY HOẶC HỦY LỆNH
                    if ($_.Exception.Message -match "HUY_LENH" -or $DongBo.LenhHienTai -eq "HUY") { break }
                    
                    if ($_.Exception.Message -match "BOP_BANG_THONG") {
                        $DongBo.TocDoTai = "Tăng tốc mạng..."
                        $DongBo.ChiSoKhoaApi = ($DongBo.ChiSoKhoaApi + 1) % $KhoaApi.Count
                    } else {
                        $DongBo.TocDoTai = "Đang kết nối lại..."
                        Start-Sleep -Seconds 2
                    }
                }
            }
            
            # Quá trình bung nén và cài đặt
            if ($KiemTraHoanTatTai -and $DongBo.LenhHienTai -ne "HUY") {
                $DongBo.TrangThaiHeThong = "📦 Đang bung nén và cài đặt: $($PhanMem.Name)..."; $DongBo.TienDo = 100; $DongBo.TocDoTai = "Đang xử lý hệ thống..."
                $TrangThaiNho[$PhanMem.ID] = "📦 Đang thực thi cài đặt..."
                
                $ThuMucSauGiaiNen = $DuongDanIsoHoanChinh + "_DaGiaiNen"
                & $DongBo.DuongDanPhanMemGiaiNen x "`"$DuongDanIsoHoanChinh`"" -o"`"$ThuMucSauGiaiNen`"" -y | Out-Null
                
                $TapTinChayCaiDat = Get-ChildItem $ThuMucSauGiaiNen -Filter "*.bat" -Recurse | Select-Object -First 1
                if (-not $TapTinChayCaiDat) { $TapTinChayCaiDat = Get-ChildItem $ThuMucSauGiaiNen -Filter "setup.exe" -Recurse | Select-Object -First 1 }
                if ($TapTinChayCaiDat) { Start-Process $TapTinChayCaiDat.FullName -WorkingDirectory $TapTinChayCaiDat.DirectoryName -Wait }
                
                if ($DuLieuDauVao.ChoPhepKichHoat) { 
                    try {
                        $DongBo.TrangThaiHeThong = "🔑 Đang thực thi mã kích hoạt bản quyền..."
                        (New-Object System.Net.WebClient).DownloadFile("https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd", "$env:TEMP\LenhKichHoat.cmd")
                        Start-Process cmd "/c $env:TEMP\LenhKichHoat.cmd /Ohook" -WindowStyle Hidden -Wait 
                    } catch {}
                }
                
                $DongBo.TrangThaiHeThong = "🧹 Đang dọn dẹp tập tin rác..."
                if (-not $DuLieuDauVao.ChoPhepGiuISO) { Remove-Item $DuongDanIsoHoanChinh -Force -ErrorAction SilentlyContinue }
                Remove-Item $ThuMucSauGiaiNen -Recurse -Force -ErrorAction SilentlyContinue
                $TrangThaiNho[$PhanMem.ID] = "✅ Đã cài đặt xong"
            }
        }
        $DongBo.TrangThaiHeThong = if ($DongBo.LenhHienTai -eq "HUY") { "🛑 Đã hủy toàn bộ lệnh thành công!" } else { "✅ HOÀN TẤT TRIỂN KHAI TOÀN BỘ!" }
        $DongBo.TienDo = 100; $DongBo.TocDoTai = "-- MB/s"
    } catch {
        $DongBo.TrangThaiHeThong = "❌ Lỗi hệ thống: $($_.Exception.Message)"
    }
}

# 4. CHỨC NĂNG CÁC NÚT BẤM
function Tai-DuLieuMoiNhat {
    $Global:NhanTrangThaiHeThong.Text = "⏳ Đang kết nối máy chủ tải dữ liệu..."; [System.Windows.Forms.Application]::DoEvents()
    $DuongDanKhoLuuTru = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $DuongDanLuuMayGoc = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    try {
        Invoke-WebRequest ($DuongDanKhoLuuTru + "?t=" + (Get-Date).Ticks) -OutFile $DuongDanLuuMayGoc -TimeoutSec 10
        $Global:DanhSachPhanMemHienThi.Clear()
        Import-Csv $DuongDanLuuMayGoc -Encoding UTF8 | ForEach-Object { $Global:DanhSachPhanMemHienThi.Add([PSCustomObject]@{ Name=$_.Name; Status="Sẵn sàng"; ID=$_.ID }) }
        $Global:NhanTrangThaiHeThong.Text = "✅ Đã làm mới danh sách phần mềm!"; $Global:NhanTrangThaiHeThong.Foreground = "Green"
    } catch {
        $Global:NhanTrangThaiHeThong.Text = "❌ Mất kết nối tới kho dữ liệu GitHub!"; $Global:NhanTrangThaiHeThong.Foreground = "Red"
    }
    $Global:BangDanhSachOffice.Items.Refresh()
}

$Global:NutTaiLaiDanhSach.Add_Click({ Tai-DuLieuMoiNhat })
$Global:OHienThiDuongDan.Text = if (Test-Path "D:\") { "D:\BoCaiOffice" } else { "C:\BoCaiOffice" }
$Global:NutChonDuongDan.Add_Click({ $HopThoaiChonThuMuc = New-Object System.Windows.Forms.FolderBrowserDialog; if ($HopThoaiChonThuMuc.ShowDialog() -eq "OK") { $Global:OHienThiDuongDan.Text = $HopThoaiChonThuMuc.SelectedPath } })
$GiaoDienChinh.FindName("NutMoThuMucLuu").Add_Click({ if (Test-Path $Global:OHienThiDuongDan.Text) { Start-Process "explorer.exe" $Global:OHienThiDuongDan.Text } })

$Global:NutHuyBoThaoTac.Add_Click({ 
    $Global:DuLieuDongBo.LenhHienTai = "HUY"
    $Global:NutHuyBoThaoTac.IsEnabled = $false
    $Global:NhanTrangThaiHeThong.Text = "🛑 Đang gửi tín hiệu dừng khẩn cấp..."
    
    $DanhSachID = @($Global:TrangThaiTungUngDung.Keys)
    foreach ($MaDinhDanh in $DanhSachID) {
        if ($Global:TrangThaiTungUngDung[$MaDinhDanh] -match "Đang tải") { $Global:TrangThaiTungUngDung[$MaDinhDanh] = "🛑 Đã ngừng tải" }
    }
})

$Global:NutBatDauCaiDat.Add_Click({
    $NhungDongDaChon = @($Global:BangDanhSachOffice.SelectedItems)
    if ($NhungDongDaChon.Count -eq 0) { 
        [System.Windows.Forms.MessageBox]::Show("Vui lòng tích chọn ít nhất 1 bản Office trong bảng danh sách để bắt đầu cài đặt!", "Yêu cầu kiểm tra", 0, 48)
        return 
    }

    $DanhSachBocTach = @()
    $Global:TrangThaiTungUngDung.Clear()
    foreach ($PhanTu in $NhungDongDaChon) {
        $DanhSachBocTach += @{ ID = $PhanTu.ID; Name = $PhanTu.Name }
        $Global:TrangThaiTungUngDung[$PhanTu.ID] = "⏳ Đang trong danh sách chờ..."
    }
    
    if (-not (Test-Path $Global:OHienThiDuongDan.Text)) { New-Item $Global:OHienThiDuongDan.Text -ItemType Directory | Out-Null }
    
    $Global:DuLieuDongBo.DuongDanLuuKieuFile = $Global:OHienThiDuongDan.Text
    $Global:DuLieuDongBo.LenhHienTai = "CHAY"
    $Global:NutBatDauCaiDat.IsEnabled = $false; $Global:NutHuyBoThaoTac.IsEnabled = $true; $Global:NutTaiLaiDanhSach.IsEnabled = $false
    
    if ($Global:MayChuChayNgam) { try { $Global:MayChuChayNgam.Dispose() } catch {} }
    if ($Global:KhongGianChayNgam) { try { $Global:KhongGianChayNgam.Dispose() } catch {} }
    
    $Global:KhongGianChayNgam = [runspacefactory]::CreateRunspace()
    $Global:KhongGianChayNgam.ApartmentState = "STA"
    $Global:KhongGianChayNgam.ThreadOptions = "ReuseThread"
    $Global:KhongGianChayNgam.Open()

    $Global:MayChuChayNgam = [powershell]::Create()
    $Global:MayChuChayNgam.Runspace = $Global:KhongGianChayNgam
    $Global:MayChuChayNgam.AddScript($KichBanXuLyNgam).AddArgument(@{
        DongBo = $Global:DuLieuDongBo; DanhSach = $DanhSachBocTach; KhoaApi = $Global:DanhSachKhoaApi; 
        TrangThaiNho = $Global:TrangThaiTungUngDung;
        ChoPhepKichHoat = $Global:TuyChonKichHoatCo.IsChecked; ChoPhepGiuISO = $Global:TuyChonGiuISO.IsChecked
    }) | Out-Null
    
    $TienTrinhChayNgam = $Global:MayChuChayNgam.BeginInvoke()

    $BoBamGio = New-Object System.Windows.Threading.DispatcherTimer
    $BoBamGio.Interval = [TimeSpan]::FromMilliseconds(300)
    $BoBamGio.Add_Tick({
        $Global:ThanhChayTienDo.Value = $Global:DuLieuDongBo.TienDo
        $Global:NhanHienThiTocDo.Text = $Global:DuLieuDongBo.TocDoTai
        $Global:NhanTrangThaiHeThong.Text = $Global:DuLieuDongBo.TrangThaiHeThong
        
        foreach ($PhanTuHienThi in $Global:DanhSachPhanMemHienThi) {
            if ($Global:TrangThaiTungUngDung.ContainsKey($PhanTuHienThi.ID)) { $PhanTuHienThi.Status = $Global:TrangThaiTungUngDung[$PhanTuHienThi.ID] }
        }
        $Global:BangDanhSachOffice.Items.Refresh()
        
        if ($Global:DuLieuDongBo.TrangThaiHeThong -match "✅|🛑|❌") { 
            $Global:NutBatDauCaiDat.IsEnabled = $true; $Global:NutHuyBoThaoTac.IsEnabled = $false; $Global:NutTaiLaiDanhSach.IsEnabled = $true
            $BoBamGio.Stop() 
        }
    })
    $BoBamGio.Start()
})

# 5. LỆNH KHỞI CHẠY (BỌC TRY/CATCH ĐỂ DẬP LỖI CONSOLE KHI ĐÓNG GIAO DIỆN)
$Global:DanhSachPhanMemHienThi = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Global:BangDanhSachOffice.ItemsSource = $Global:DanhSachPhanMemHienThi

$GiaoDienChinh.Add_ContentRendered({
    $Global:DuLieuDongBo.DuongDanPhanMemGiaiNen = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $Global:DuLieuDongBo.DuongDanPhanMemGiaiNen) { $Global:NhanKiemTraGiaiNen.Text = "❌ Sự cố: Máy tính chưa cài đặt 7-Zip!"; $Global:NhanKiemTraGiaiNen.Foreground = "Red" } else { $Global:NhanKiemTraGiaiNen.Text = "✅ Đã nhận diện công cụ 7-Zip!"; $Global:NhanKiemTraGiaiNen.Foreground = "Green" }
    Tai-DuLieuMoiNhat
})

try {
    if ($null -ne $GiaoDienChinh) { $GiaoDienChinh.ShowDialog() | Out-Null }
} catch {
    Write-Host "Đã đóng giao diện công cụ Office an toàn."
}