# ==========================================================
# VIETTOOLBOX - OFFICE V182 (XOAY VÒNG KEY API - CHỐNG 403)
# ==========================================================

# 1. ÉP CHẠY QUYỀN QUẢN TRỊ VIÊN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. THIẾT LẬP TURBO (TỐI ƯU MẠNG & UTF8)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::UseNagleAlgorithm = $false
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms, System.Net.Http

# --- CẤU HÌNH XOAY VÒNG API KEYS (ĐÃ SỬA) ---
$Global:B64_Key_Pool = @(
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0", # Key 1
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", # Key 2
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v", # Key 3
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv"  # Key 4
)
$Global:CurrentKeyIndex = 0

function Get-NextApiKey {
    $rawKey = $Global:B64_Key_Pool[$Global:CurrentKeyIndex]
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($rawKey))
}

$Global:LogPath = Join-Path $env:TEMP "VietToolbox_Office_Log.txt"

function Ghi-NhatKy ($NoiDung) {
    $ThoiGian = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    "[$ThoiGian] $NoiDung" | Out-File -FilePath $Global:LogPath -Append -Encoding UTF8
}

$LogicCaiOfficeV182 = {
    $LinkDuLieuGoc = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $FileDuLieuMay = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    $script:HuyTai = $false; $script:TamDung = $false

    # --- 1. GIAO DIỆN XAML WPF (GIỮ NGUYÊN) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - OFFICE V182 (XOAY KEY API)" Width="850" Height="650" 
        WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="TRUNG TÂM TRIỂN KHAI MICROSOFT OFFICE" FontSize="24" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Cơ chế: Tự động xoay vòng 4 API Key khi hết hạn mức (403 Forbidden)" Foreground="#666666"/>
        </StackPanel>

        <ListView Name="BangOffice" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" BorderThickness="1" Margin="0,0,0,10">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="45">
                        <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="PHIÊN BẢN OFFICE" DisplayMemberBinding="{Binding Name}" Width="450"/>
                    <GridViewColumn Header="TRẠNG THÁI" Width="250">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="Bold"/></DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>

        <TextBlock Name="Nhan7Zip" Grid.Row="2" Text="🔍 Đang kiểm tra hệ thống..." FontWeight="SemiBold" Foreground="#FF9800" Margin="0,0,0,15"/>

        <Border Grid.Row="3" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#DDDDDD" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="80"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="150"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="LƯU TẠI:" FontWeight="Bold" VerticalAlignment="Center" Foreground="#333333"/>
                <TextBox Name="OTimDuongDan" Grid.Column="1" Height="30" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0" Background="#F0F0F0" Padding="5,0"/>
                <Button Name="NutChonThuMuc" Grid.Column="2" Content="CHỌN THƯ MỤC" Height="35" Background="#ECEFF1" FontWeight="Bold" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></Button.Resources>
                </Button>
            </Grid>
        </Border>

        <Border Grid.Row="4" Background="#E3F2FD" CornerRadius="8" Padding="12" Margin="0,0,0,10" BorderBrush="#BBDEFB" BorderThickness="1">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <TextBlock Text="CẤU HÌNH BẢN QUYỀN:" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,20,0" Foreground="#1565C0"/>
                <RadioButton Name="RadKhongKichHoat" Content="Không kích hoạt" IsChecked="True" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,30,0" Cursor="Hand"/>
                <RadioButton Name="RadKichHoatLuon" Content="Kích hoạt luôn (Tải Ohook từ Gist - Chạy ngầm)" FontWeight="Bold" VerticalAlignment="Center" Foreground="#D32F2F" Cursor="Hand"/>
            </StackPanel>
        </Border>

        <Border Grid.Row="5" Background="#FFF3E0" CornerRadius="8" Padding="12" Margin="0,0,0,15" BorderBrush="#FFE0B2" BorderThickness="1">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <TextBlock Text="CẤU HÌNH FILE GỐC:" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,20,0" Foreground="#E65100"/>
                <RadioButton Name="RadXoaSource" Content="Cài xong xóa Source luôn (Dọn rác)" IsChecked="True" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,30,0" Cursor="Hand"/>
                <RadioButton Name="RadGiuSource" Content="Cài xong giữ lại file ISO" FontWeight="Bold" VerticalAlignment="Center" Foreground="#E65100" Cursor="Hand"/>
            </StackPanel>
        </Border>

        <Grid Grid.Row="6" Margin="0,0,0,5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <TextBlock Name="NhanTrangThai" Grid.Column="0" Text="Sẵn sàng..." FontWeight="SemiBold" Foreground="#1565C0" FontSize="14"/>
            <TextBlock Name="NhanTocDo" Grid.Column="1" Text="-- MB/s | -- / -- MB (0%)" FontWeight="Bold" FontFamily="Consolas" Foreground="#D84315" TextAlignment="Right" FontSize="14"/>
        </Grid>

        <ProgressBar Name="ThanhChay" Grid.Row="7" Height="25" Margin="0,0,0,20" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>

        <Grid Grid.Row="8" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button Name="NutTamDung" Grid.Column="0" Content="TẠM DỪNG" Height="45" Background="#FFF59D" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
            <Button Name="NutTiepTuc" Grid.Column="2" Content="TIẾP TỤC" Height="45" Background="#A5D6A7" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
            <Button Name="NutHuy" Grid.Column="4" Content="HỦY LỆNH" Height="45" Background="#EF9A9A" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
        </Grid>

        <Grid Grid.Row="9">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button Name="NutNhatKy" Grid.Column="0" Content="NHẬT KÝ" Height="55" Background="#607D8B" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
            <Button Name="NutLamMoi" Grid.Column="2" Content="LÀM MỚI DANH SÁCH" Height="55" Background="#455A64" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
            <Button Name="NutCaiDat" Grid.Column="4" Content="🚀 CÀI ĐẶT NGAY" Height="55" Background="#D32F2F" Foreground="White" FontSize="16" FontWeight="Bold" Cursor="Hand"/>
        </Grid>
    </Grid>
</Window>
"@

    # --- 2. KHỞI TẠO CỬA SỔ XAML ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    # Ánh xạ biến
    $BangOffice = $CuaSo.FindName("BangOffice"); $Nhan7Zip = $CuaSo.FindName("Nhan7Zip")
    $OTimDuongDan = $CuaSo.FindName("OTimDuongDan"); $NutChonThuMuc = $CuaSo.FindName("NutChonThuMuc")
    $NhanTrangThai = $CuaSo.FindName("NhanTrangThai"); $NhanTocDo = $CuaSo.FindName("NhanTocDo")
    $ThanhChay = $CuaSo.FindName("ThanhChay")
    $NutTamDung = $CuaSo.FindName("NutTamDung"); $NutTiepTuc = $CuaSo.FindName("NutTiepTuc"); $NutHuy = $CuaSo.FindName("NutHuy")
    $NutNhatKy = $CuaSo.FindName("NutNhatKy"); $NutLamMoi = $CuaSo.FindName("NutLamMoi"); $NutCaiDat = $CuaSo.FindName("NutCaiDat")
    $RadKhongKichHoat = $CuaSo.FindName("RadKhongKichHoat"); $RadKichHoatLuon = $CuaSo.FindName("RadKichHoatLuon")
    $RadXoaSource = $CuaSo.FindName("RadXoaSource"); $RadGiuSource = $CuaSo.FindName("RadGiuSource")

    $Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $BangOffice.ItemsSource = $Global:DanhSachDuLieu
    $OTimDuongDan.Text = if (Test-Path "D:\") { "D:\VietToolbox_Office" } else { "C:\VietToolbox_Office" }

    # --- 3. HÀM XỬ LÝ LÕI ---

    function Tao-LoiTatOffice {
        $ThuMucOffice = @(
            "$env:ProgramFiles\Microsoft Office\root\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16",
            "$env:ProgramFiles\Microsoft Office\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16"
        )
        $DanhSachApp = @{ "Word"="WINWORD.EXE"; "Excel"="EXCEL.EXE"; "PowerPoint"="POWERPNT.EXE"; "Access"="MSACCESS.EXE"; "Outlook"="OUTLOOK.EXE" }
        $ManHinhChinh = [Environment]::GetFolderPath("CommonDesktopDirectory")
        $WshShell = New-Object -ComObject WScript.Shell
        foreach ($DuongDan in $ThuMucOffice) {
            if (Test-Path $DuongDan) {
                foreach ($TenApp in $DanhSachApp.Keys) {
                    $FileExe = Join-Path $DuongDan $DanhSachApp[$TenApp]
                    if (Test-Path $FileExe) {
                        $LoiTat = Join-Path $ManHinhChinh "$TenApp.lnk"
                        $BanSao = $WshShell.CreateShortcut($LoiTat)
                        $BanSao.TargetPath = $FileExe
                        $BanSao.Save()
                    }
                }
                break 
            }
        }
    }

    function Tai-DuLieuLocal {
        if (Test-Path $FileDuLieuMay) {
            $Global:DanhSachDuLieu.Clear()
            $csv = Import-Csv $FileDuLieuMay -Encoding UTF8
            foreach ($r in $csv) { 
                if ($r.Name) { $Global:DanhSachDuLieu.Add([PSCustomObject]@{ Check=$false; Name=$r.Name; Status="Sẵn sàng"; StatusColor="Black"; ID=$r.ID }) } 
            }
        }
    }

    $CuaSo.Add_ContentRendered({
        Tai-DuLieuLocal
        $DuongDan7z = "$env:ProgramFiles\7-Zip\7z.exe"
        if (-not (Test-Path $DuongDan7z)) { $DuongDan7z = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
        if (-not (Test-Path $DuongDan7z)) {
            $Nhan7Zip.Text = "⚠️ Thiếu 7-Zip! Đang tự động tải và cài đặt..."; $Nhan7Zip.Foreground = "#D32F2F"
            [System.Windows.Forms.Application]::DoEvents()
            $Link7z = "https://www.7-zip.org/a/7z2408-x64.exe"
            $FileCai7z = Join-Path $env:TEMP "7z_setup.exe"
            try {
                (New-Object System.Net.WebClient).DownloadFile($Link7z, $FileCai7z)
                Start-Process $FileCai7z -ArgumentList "/S" -Wait -PassThru | Out-Null
                $Nhan7Zip.Text = "✅ Đã tự cài 7-Zip thành công!"; $Nhan7Zip.Foreground = "#2E7D32"
            } catch { $Nhan7Zip.Text = "❌ Lỗi cài 7-Zip! Vui lòng cài thủ công."; $Nhan7Zip.Foreground = "#D32F2F" }
        } else { $Nhan7Zip.Text = "✅ Hệ thống: 7-Zip đã sẵn sàng!"; $Nhan7Zip.Foreground = "#2E7D32" }
    })

    # --- HÀM TẢI FILE CHÍNH (ĐÃ SỬA ĐỂ XOAY KEY) ---
    function Tai-FileCốtLõi ($IdNguon, $DichDen) {
        $MaDrive = if ($IdNguon -match "id=([a-zA-Z0-9\-_]+)") { $matches[1] } else { $IdNguon }
        $ThoiGianChoToiDa = 300 
        $ThoiGianDaCho = 0
        $TongDungLuong = 0
        
        while ($true) {
            if ($script:HuyTai) { 
                if (Test-Path $DichDen) { Remove-Item $DichDen -Force -ErrorAction SilentlyContinue }
                return "ĐÃ_HỦY" 
            }
            while ($script:TamDung) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }

            # Lấy Key hiện tại từ Pool
            $CurrentKey = Get-NextApiKey
            $LienKet = "https://www.googleapis.com/drive/v3/files/$($MaDrive)?alt=media&key=$CurrentKey"

            try {
                $MayKhachHttp = New-Object System.Net.Http.HttpClient
                $MayKhachHttp.Timeout = [System.TimeSpan]::FromSeconds(30)
                
                $DaTaiDuoc = 0
                if (Test-Path $DichDen) { $DaTaiDuoc = (Get-Item $DichDen).Length }

                $YeuCau = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $LienKet)
                if ($DaTaiDuoc -gt 0) { $YeuCau.Headers.Add("Range", "bytes=$DaTaiDuoc-") }

                $PhanHoi = $MayKhachHttp.SendAsync($YeuCau, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result

                # --- LOGIC XOAY KEY KHI LỖI 403 HOẶC 429 ---
                if (-not $PhanHoi.IsSuccessStatusCode) {
                    $Code = [int]$PhanHoi.StatusCode
                    if ($Code -eq 403 -or $Code -eq 429) {
                        if ($Global:CurrentKeyIndex -lt ($Global:B64_Key_Pool.Count - 1)) {
                            $Global:CurrentKeyIndex++
                            Ghi-NhatKy "⚠️ Key API lỗi ($Code). Đang chuyển sang Key dự phòng #$($Global:CurrentKeyIndex + 1)..."
                            $MayKhachHttp.Dispose(); continue 
                        } else {
                            # Nếu hết Key, thử đá ra trình duyệt làm phương án cuối
                            Ghi-NhatKy "❌ Hết sạch Key API. Đang mở trình duyệt để tải dự phòng..."
                            Start-Process "https://drive.google.com/uc?id=$MaDrive&export=download"
                            return "ĐÃ_CHUYỂN_WEB"
                        }
                    }
                }

                if ($PhanHoi.StatusCode -eq [System.Net.HttpStatusCode]::RequestedRangeNotSatisfiable) {
                    return "THÀNH_CÔNG"
                } elseif ($PhanHoi.StatusCode -eq [System.Net.HttpStatusCode]::OK) {
                    if ($DaTaiDuoc -gt 0) { $DaTaiDuoc = 0; if (Test-Path $DichDen) { Remove-Item $DichDen -Force } }
                    if ($PhanHoi.Content.Headers.ContentLength) { $TongDungLuong = $PhanHoi.Content.Headers.ContentLength }
                } elseif ($PhanHoi.StatusCode -eq [System.Net.HttpStatusCode]::PartialContent) {
                    if ($PhanHoi.Content.Headers.ContentRange -ne $null) { $TongDungLuong = $PhanHoi.Content.Headers.ContentRange.Length }
                } else { throw "Lỗi HTTP: $($PhanHoi.StatusCode)" }

                $DongDuLieu = $PhanHoi.Content.ReadAsStreamAsync().Result
                $CheDoMo = if ($DaTaiDuoc -gt 0) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }
                $FileLuu = New-Object System.IO.FileStream($DichDen, $CheDoMo, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                
                $BoNhoDem = New-Object byte[] 4194304
                $DongHo = [System.Diagnostics.Stopwatch]::StartNew()
                $SoByteTaiLuotNay = 0
                $ThoiGianDaCho = 0 
                
                while (($SoByte = $DongDuLieu.Read($BoNhoDem, 0, $BoNhoDem.Length)) -gt 0) {
                    if ($script:HuyTai) { $FileLuu.Dispose(); $DongDuLieu.Dispose(); $MayKhachHttp.Dispose(); return "ĐÃ_HỦY" }
                    $FileLuu.Write($BoNhoDem, 0, $SoByte)
                    $DaTaiDuoc += $SoByte
                    $SoByteTaiLuotNay += $SoByte
                    if ($DongHo.ElapsedMilliseconds -ge 1000) {
                        $TocDoMB = [Math]::Round(($SoByteTaiLuotNay / $DongHo.Elapsed.TotalSeconds) / 1MB, 2)
                        $PhanTram = if ($TongDungLuong -gt 0) { [int](($DaTaiDuoc / $TongDungLuong) * 100) } else { 0 }
                        $CuaSo.Dispatcher.Invoke([action]{ 
                            $ThanhChay.Value = $PhanTram
                            $NhanTocDo.Text = "API #$($Global:CurrentKeyIndex + 1) | $TocDoMB MB/s | $([Math]::Round($DaTaiDuoc/1MB,1)) MB ($PhanTram%)" 
                        })
                        $SoByteTaiLuotNay = 0; $DongHo.Restart(); [System.Windows.Forms.Application]::DoEvents()
                    }
                }
                $FileLuu.Dispose(); $DongDuLieu.Dispose(); $MayKhachHttp.Dispose()
                if ($TongDungLuong -eq 0 -or $DaTaiDuoc -ge $TongDungLuong) { return "THÀNH_CÔNG" } else { throw "Ngắt mạng..." }
            } catch {
                $ThoiGianDaCho += 5
                if ($ThoiGianDaCho -ge $ThoiGianChoToiDa) { return "LỖI" }
                Ghi-NhatKy "Đang thử nối lại ($ThoiGianDaCho s)..."; Start-Sleep -Seconds 5
            }
        }
    }

    # --- SỰ KIỆN NÚT BẤM (GIỮ NGUYÊN LOGIC) ---
    $NutNhatKy.Add_Click({ if (Test-Path $Global:LogPath) { Start-Process "notepad.exe" $Global:LogPath } })
    $NutLamMoi.Add_Click({ 
        try {
            Invoke-WebRequest ($LinkDuLieuGoc + "?t=" + (Get-Date).Ticks) -OutFile $FileDuLieuMay
            Tai-DuLieuLocal
            $NhanTrangThai.Text = "Đã cập nhật danh sách!"; $NhanTrangThai.Foreground = "#2E7D32"
        } catch { $NhanTrangThai.Text = "Lỗi GitHub!"; $NhanTrangThai.Foreground = "#D32F2F" }
    })
    $NutChonThuMuc.Add_Click({ $HopThoai = New-Object System.Windows.Forms.FolderBrowserDialog; if ($HopThoai.ShowDialog() -eq "OK") { $OTimDuongDan.Text = $HopThoai.SelectedPath } })
    $NutHuy.Add_Click({ $script:HuyTai = $true; $NhanTrangThai.Text = "🛑 Đang hủy..." })
    $NutTamDung.Add_Click({ $script:TamDung = $true; $NutTamDung.IsEnabled = $false; $NutTiepTuc.IsEnabled = $true; $NhanTrangThai.Text = "⏸️ Tạm dừng" })
    $NutTiepTuc.Add_Click({ $script:TamDung = $false; $NutTiepTuc.IsEnabled = $false; $NutTamDung.IsEnabled = $true; $NhanTrangThai.Text = "▶️ Tiếp tục" })

    $NutCaiDat.Add_Click({
        $DaChon = @($Global:DanhSachDuLieu | Where-Object { $_.Check -eq $true })
        if ($DaChon.Count -eq 0) { return }
        $NutCaiDat.IsEnabled = $false; $NutHuy.IsEnabled = $true; $NutTamDung.IsEnabled = $true
        foreach ($UngDung in $DaChon) {
            $FileLuuToanBo = Join-Path $OTimDuongDan.Text (($UngDung.Name -replace '\s', '_') + ".iso")
            if (-not (Test-Path $OTimDuongDan.Text)) { New-Item $OTimDuongDan.Text -ItemType Directory | Out-Null }
            $UngDung.Status = "⏳ Đang tải..."; $UngDung.StatusColor = "#FF9800"
            $BangOffice.Items.Refresh(); [System.Windows.Forms.Application]::DoEvents()
            
            $KetQua = Tai-FileCốtLõi $UngDung.ID $FileLuuToanBo
            if ($KetQua -eq "THÀNH_CÔNG") {
                $UngDung.Status = "📦 Đang bung nén..."; $BangOffice.Items.Refresh(); [System.Windows.Forms.Application]::DoEvents()
                $DuongDan7z = "$env:ProgramFiles\7-Zip\7z.exe"; if (-not (Test-Path $DuongDan7z)) { $DuongDan7z = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
                $ThuMucGiaiNen = $FileLuuToanBo + "_Ext"
                Start-Process $DuongDan7z -ArgumentList "x `"$FileLuuToanBo`" -o`"$ThuMucGiaiNen`" -y" -WindowStyle Hidden -Wait
                $Setup = Get-ChildItem -Path $ThuMucGiaiNen -Filter "*.bat" -Recurse | Select-Object -First 1
                if (-not $Setup) { $Setup = Get-ChildItem -Path $ThuMucGiaiNen -Filter "setup.exe" -Recurse | Select-Object -First 1 }
                if ($Setup) {
                    $UngDung.Status = "⚙️ Đang cài..."; $BangOffice.Items.Refresh(); [System.Windows.Forms.Application]::DoEvents()
                    Start-Process $Setup.FullName -WorkingDirectory $Setup.DirectoryName -Wait
                    Tao-LoiTatOffice
                    if ($RadKichHoatLuon.IsChecked) {
                        $OhookUrl = "https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd"
                        $TempOhook = Join-Path $env:TEMP "Ohook_Viet.cmd"
                        (New-Object System.Net.WebClient).DownloadFile($OhookUrl, $TempOhook)
                        Start-Process cmd.exe -ArgumentList "/c `"$TempOhook`" /Ohook" -WindowStyle Hidden -Wait
                        Remove-Item $TempOhook -Force
                    }
                    $UngDung.Status = "✅ Hoàn tất"; $UngDung.StatusColor = "Green"
                }
                if ($RadXoaSource.IsChecked) { Remove-Item $FileLuuToanBo -Force }
                if (Test-Path $ThuMucGiaiNen) { Remove-Item $ThuMucGiaiNen -Recurse -Force }
            } elseif ($KetQua -eq "ĐÃ_CHUYỂN_WEB") { $UngDung.Status = "🌐 Tải qua Web"; $UngDung.StatusColor = "Blue"
            } else { $UngDung.Status = "❌ Lỗi!"; $UngDung.StatusColor = "Red" }
            $BangOffice.Items.Refresh()
        }
        $NutCaiDat.IsEnabled = $true; [System.Windows.Forms.MessageBox]::Show("Hoàn tất!")
    })
    $CuaSo.ShowDialog() | Out-Null
}
&$LogicCaiOfficeV182