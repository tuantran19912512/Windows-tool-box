# ==========================================================
# VIETTOOLBOX - OFFICE V182 (BẢN TRÙM CUỐI - TỰ ĐỘNG SHORTCUT & KÍCH HOẠT OHOOK GIST)
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

# --- CẤU HÌNH API DRIVE ---
$B64_Key = "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))
$Global:LogPath = Join-Path $env:TEMP "VietToolbox_Office_Log.txt"

function Ghi-NhatKy ($NoiDung) {
    $ThoiGian = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    "[$ThoiGian] $NoiDung" | Out-File -FilePath $Global:LogPath -Append -Encoding UTF8
}

$LogicCaiOfficeV182 = {
    $LinkDuLieuGoc = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv"
    $FileDuLieuMay = Join-Path $env:LOCALAPPDATA "VietToolbox_Office_Local.csv"
    $script:HuyTai = $false; $script:TamDung = $false

    # --- 1. GIAO DIỆN XAML WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - OFFICE V182" Width="850" Height="860" 
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
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="TRUNG TÂM TRIỂN KHAI MICROSOFT OFFICE" FontSize="24" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Tự động tải file, cài đặt ngầm, đưa Shortcut ra Desktop và Kích hoạt" Foreground="#666666"/>
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

        <Border Grid.Row="4" Background="#E3F2FD" CornerRadius="8" Padding="12" Margin="0,0,0,15" BorderBrush="#BBDEFB" BorderThickness="1">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <TextBlock Text="CẤU HÌNH BẢN QUYỀN:" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,20,0" Foreground="#1565C0"/>
                <RadioButton Name="RadKhongKichHoat" Content="Không kích hoạt" IsChecked="True" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,30,0" Cursor="Hand"/>
                <RadioButton Name="RadKichHoatLuon" Content="Kích hoạt luôn (Tải Ohook từ Gist - Chạy ngầm)" FontWeight="Bold" VerticalAlignment="Center" Foreground="#D32F2F" Cursor="Hand"/>
            </StackPanel>
        </Border>

        <Grid Grid.Row="5" Margin="0,0,0,5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <TextBlock Name="NhanTrangThai" Grid.Column="0" Text="Sẵn sàng..." FontWeight="SemiBold" Foreground="#1565C0" FontSize="14"/>
            <TextBlock Name="NhanTocDo" Grid.Column="1" Text="-- MB/s | -- / -- MB" FontWeight="Bold" FontFamily="Consolas" Foreground="#D84315" TextAlignment="Right" FontSize="14"/>
        </Grid>

        <ProgressBar Name="ThanhChay" Grid.Row="6" Height="25" Margin="0,0,0,20" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>

        <Grid Grid.Row="7" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button Name="NutTamDung" Grid.Column="0" Content="TẠM DỪNG" Height="45" Background="#FFF59D" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
            <Button Name="NutTiepTuc" Grid.Column="2" Content="TIẾP TỤC" Height="45" Background="#A5D6A7" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
            <Button Name="NutHuy" Grid.Column="4" Content="HỦY LỆNH" Height="45" Background="#EF9A9A" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
        </Grid>

        <Grid Grid.Row="8">
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
    $RadKhongKichHoat = $CuaSo.FindName("RadKhongKichHoat")
    $RadKichHoatLuon = $CuaSo.FindName("RadKichHoatLuon")

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

    function Tai-FileCốtLõi ($IdNguon, $DichDen) {
        $MayKhachHttp = New-Object System.Net.Http.HttpClient
        $MaDrive = if ($IdNguon -match "id=([a-zA-Z0-9\-_]+)") { $matches[1] } else { $IdNguon }
        $LienKet = "https://www.googleapis.com/drive/v3/files/$($MaDrive)?alt=media&key=$($Global:DriveApiKey)"
        try {
            $PhanHoi = $MayKhachHttp.GetAsync($LienKet, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            if (-not $PhanHoi.IsSuccessStatusCode) { return "LỖI" }
            
            $TongDungLuong = $PhanHoi.Content.Headers.ContentLength
            $DongDuLieu = $PhanHoi.Content.ReadAsStreamAsync().Result
            $FileLuu = [System.IO.File]::Create($DichDen)
            $BoNhoDem = New-Object byte[] 4194304
            $DaTaiDuoc = 0; $DongHo = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (($SoByte = $DongDuLieu.Read($BoNhoDem, 0, $BoNhoDem.Length)) -gt 0) {
                if ($script:HuyTai) { 
                    $FileLuu.Dispose(); $DongDuLieu.Dispose(); $MayKhachHttp.Dispose()
                    if (Test-Path $DichDen) { Remove-Item $DichDen -Force -ErrorAction SilentlyContinue }
                    return "ĐÃ_HỦY" 
                }
                while ($script:TamDung) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200 }
                
                $FileLuu.Write($BoNhoDem, 0, $SoByte)
                $DaTaiDuoc += $SoByte
                
                if ($DongHo.ElapsedMilliseconds -ge 1000) {
                    $TocDoMB = [Math]::Round(($DaTaiDuoc / $DongHo.Elapsed.TotalSeconds) / 1MB, 2)
                    $PhanTram = if ($TongDungLuong -gt 0) { [int](($DaTaiDuoc / $TongDungLuong) * 100) } else { 0 }
                    $CuaSo.Dispatcher.Invoke([action]{ $ThanhChay.Value = $PhanTram; $NhanTocDo.Text = "$TocDoMB MB/s | $([Math]::Round($DaTaiDuoc/1MB,1)) MB" })
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            $FileLuu.Dispose(); $DongDuLieu.Dispose(); return "THÀNH_CÔNG"
        } catch { return "LỖI" }
    }

    # --- 4. SỰ KIỆN NÚT BẤM ---
    $NutNhatKy.Add_Click({ if (Test-Path $Global:LogPath) { Start-Process "notepad.exe" $Global:LogPath } })
    
    $NutLamMoi.Add_Click({ 
        try {
            Invoke-WebRequest ($LinkDuLieuGoc + "?t=" + (Get-Date).Ticks) -OutFile $FileDuLieuMay
            Tai-DuLieuLocal
            $NhanTrangThai.Text = "Đã cập nhật danh sách mới nhất!"; $NhanTrangThai.Foreground = "#2E7D32"
        } catch { $NhanTrangThai.Text = "Lỗi kết nối khi cập nhật danh sách!"; $NhanTrangThai.Foreground = "#D32F2F" }
    })
    
    $NutChonThuMuc.Add_Click({ 
        $HopThoai = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($HopThoai.ShowDialog() -eq "OK") { $OTimDuongDan.Text = $HopThoai.SelectedPath } 
    })
    
    $NutHuy.Add_Click({ $script:HuyTai = $true; $NhanTrangThai.Text = "Đang hủy lệnh..."; $NhanTrangThai.Foreground = "#D32F2F" })
    $NutTamDung.Add_Click({ $script:TamDung = $true; $NutTamDung.IsEnabled = $false; $NutTiepTuc.IsEnabled = $true; $NhanTrangThai.Text = "Đang tạm dừng"; $NhanTrangThai.Foreground = "#FF9800" })
    $NutTiepTuc.Add_Click({ $script:TamDung = $false; $NutTiepTuc.IsEnabled = $false; $NutTamDung.IsEnabled = $true; $NhanTrangThai.Text = "Đang tải tiếp..."; $NhanTrangThai.Foreground = "#1565C0" })

    # TRÁI TIM: CÀI ĐẶT
    $NutCaiDat.Add_Click({
        $DaChon = @($Global:DanhSachDuLieu | Where-Object { $_.Check -eq $true })
        if ($DaChon.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Tuấn chưa chọn bản Office nào!", "Nhắc nhở"); return }

        $NutCaiDat.IsEnabled = $false; $NutHuy.IsEnabled = $true; $NutTamDung.IsEnabled = $true
        $NhanTrangThai.Foreground = "#1565C0"

        foreach ($UngDung in $DaChon) {
            $script:HuyTai = $false; $script:TamDung = $false
            $TenAnToan = ($UngDung.Name -replace '[\\/:*?"<>|()[\]\s]', '_') + ".iso"
            $FileLuuToanBo = Join-Path $OTimDuongDan.Text $TenAnToan
            if (-not (Test-Path $OTimDuongDan.Text)) { New-Item $OTimDuongDan.Text -ItemType Directory | Out-Null }

            $UngDung.Status = "⏳ Đang tải file ISO..."; $UngDung.StatusColor = "#FF9800"
            $NhanTrangThai.Text = "Đang tải: $($UngDung.Name)"
            $CuaSo.Dispatcher.Invoke([action]{ $BangOffice.Items.Refresh() }); [System.Windows.Forms.Application]::DoEvents()
            
            Ghi-NhatKy "Bắt đầu tải $($UngDung.Name) vào $FileLuuToanBo"
            $KetQua = Tai-FileCốtLõi $UngDung.ID $FileLuuToanBo

            if ($KetQua -eq "THÀNH_CÔNG") {
                $UngDung.Status = "📦 Đang bung nén ISO..."; $UngDung.StatusColor = "#1565C0"
                $NhanTrangThai.Text = "Đang bung nén dữ liệu cài đặt..."
                $CuaSo.Dispatcher.Invoke([action]{ $BangOffice.Items.Refresh() }); [System.Windows.Forms.Application]::DoEvents()

                $DuongDan7z = "$env:ProgramFiles\7-Zip\7z.exe"
                if (-not (Test-Path $DuongDan7z)) { $DuongDan7z = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
                
                if (Test-Path $DuongDan7z) {
                    $ThuMucGiaiNen = $FileLuuToanBo + "_Ext"
                    $LenhGiaiNen = New-Object System.Diagnostics.ProcessStartInfo -Property @{FileName=$DuongDan7z; Arguments="x `"$FileLuuToanBo`" -o`"$ThuMucGiaiNen`" -y"; WindowStyle="Hidden"}
                    [System.Diagnostics.Process]::Start($LenhGiaiNen).WaitForExit()

                    $FileCaiDat = Get-ChildItem -Path $ThuMucGiaiNen -Filter "*.bat" -Recurse | Select-Object -First 1
                    if (-not $FileCaiDat) { $FileCaiDat = Get-ChildItem -Path $ThuMucGiaiNen -Filter "setup.exe" -Recurse | Select-Object -First 1 }

                    if ($FileCaiDat) {
                        $UngDung.Status = "⚙️ Đang chạy cài đặt..."; $UngDung.StatusColor = "#FF9800"
                        $NhanTrangThai.Text = "Đang chạy bộ cài ngầm..."
                        $CuaSo.Dispatcher.Invoke([action]{ $BangOffice.Items.Refresh() }); [System.Windows.Forms.Application]::DoEvents()

                        Start-Process $FileCaiDat.FullName -WorkingDirectory $FileCaiDat.DirectoryName -Wait

                        $UngDung.Status = "🔗 Đang tạo lối tắt..."; $UngDung.StatusColor = "#1565C0"
                        $NhanTrangThai.Text = "Đang đưa biểu tượng ra Desktop..."
                        $CuaSo.Dispatcher.Invoke([action]{ $BangOffice.Items.Refresh() }); [System.Windows.Forms.Application]::DoEvents()
                        
                        Tao-LoiTatOffice

                        # ==========================================================
                        # KHU VỰC THỰC THI OHOOK TỪ GIST
                        # ==========================================================
                        if ($RadKichHoatLuon.IsChecked) {
                            $UngDung.Status = "🔑 Đang tải thuốc từ Gist..."; $UngDung.StatusColor = "#FF9800"
                            $NhanTrangThai.Text = "Đang lấy thuốc bản quyền Ohook..."
                            $CuaSo.Dispatcher.Invoke([action]{ $BangOffice.Items.Refresh() }); [System.Windows.Forms.Application]::DoEvents()
                            
                            try {
                                $Url = "https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd"
                                $TempFile = Join-Path $env:TEMP "Ohook_Activation.cmd"

                                Ghi-NhatKy "=========================================="
                                Ghi-NhatKy ">>> KÍCH HOẠT OFFICE OHOOK (CHẠY NGẦM) <<<"
                                Ghi-NhatKy "=========================================="

                                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                                $FinalUrl = "$Url`?t=$((Get-Date).Ticks)"

                                Ghi-NhatKy "-> Đang kiểm tra kết nối Internet..."
                                if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                                    Ghi-NhatKy "   + Internet: OK"
                                    
                                    Ghi-NhatKy "-> Đang tải file Ohook từ Gist của Bạn..."
                                    $RawContent = Invoke-RestMethod -Uri $FinalUrl -UseBasicParsing
                                    $RawContent = $RawContent -replace "`r`n", "`n" -replace "`n", "`r`n"
                                    $RawContent += "`r`n`r`n"

                                    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
                                    [System.IO.File]::WriteAllText($TempFile, $RawContent, $Utf8NoBom)
                                    Ghi-NhatKy "   + Tải và xử lý định dạng file thành công."
                                    
                                    if (Test-Path $TempFile) {
                                        $UngDung.Status = "🔑 Đang tiêm thuốc..."; $UngDung.StatusColor = "#1565C0"
                                        $NhanTrangThai.Text = "Đang thực thi Ohook ngầm..."
                                        $CuaSo.Dispatcher.Invoke([action]{ $BangOffice.Items.Refresh() }); [System.Windows.Forms.Application]::DoEvents()
                                        
                                        Ghi-NhatKy "-> Đang khởi chạy Ohook ở chế độ ngầm (Silent Mode)..."
                                        Start-Process cmd.exe -ArgumentList "/c `"$TempFile`" /Ohook" -WindowStyle Hidden -Wait
                                        Ghi-NhatKy "   + Đã thực hiện xong quy trình Ohook."
                                    }
                                } else {
                                    $UngDung.Status = "⚠️ Lỗi mạng Ohook"; $UngDung.StatusColor = "#D32F2F"
                                    Ghi-NhatKy "!!! LỖI: Không có kết nối mạng để tải Ohook."
                                }
                            } catch {
                                $UngDung.Status = "⚠️ Lỗi tải thuốc"; $UngDung.StatusColor = "#D32F2F"
                                Ghi-NhatKy "!!! LỖI OHOOK: Không thể tải hoặc chạy file từ Gist."
                            } finally {
                                if (Test-Path $TempFile) { Remove-Item $TempFile -Force -ErrorAction SilentlyContinue }
                            }
                        }

                        # Chỉ set Hoàn tất nếu trước đó chưa bị lỗi trạng thái Ohook
                        if ($UngDung.Status -notmatch "Lỗi") {
                            $UngDung.Status = "✅ Hoàn tất"; $UngDung.StatusColor = "#2E7D32"
                        }
                        
                        Ghi-NhatKy "Hoàn tất xử lý $($UngDung.Name). Đang dọn rác..."
                        
                        # Dọn rác
                        Remove-Item $FileLuuToanBo -Force -ErrorAction SilentlyContinue
                        Remove-Item $ThuMucGiaiNen -Recurse -Force -ErrorAction SilentlyContinue
                    } else { 
                        $UngDung.Status = "❌ Không tìm thấy file Setup"; $UngDung.StatusColor = "#D32F2F"
                    }
                } else { 
                    $UngDung.Status = "❌ Lỗi: Máy thiếu 7-Zip"; $UngDung.StatusColor = "#D32F2F" 
                }
            } elseif ($KetQua -eq "ĐÃ_HỦY") { 
                $UngDung.Status = "🛑 Đã hủy tải xuống"; $UngDung.StatusColor = "#D32F2F"
                $NhanTrangThai.Text = "Đã hủy lệnh tải!"; $NhanTocDo.Text = "-- MB/s | -- / -- MB"
                $ThanhChay.Value = 0
                break 
            } else {
                $UngDung.Status = "❌ Lỗi kết nối máy chủ"; $UngDung.StatusColor = "#D32F2F"
                $NhanTrangThai.Text = "Tải xuống thất bại!"
            }
            $CuaSo.Dispatcher.Invoke([action]{ $BangOffice.Items.Refresh() })
        }
        
        $NutCaiDat.IsEnabled = $true; $NutHuy.IsEnabled = $false; $NutTamDung.IsEnabled = $false
        if ($script:HuyTai -eq $false) { $NhanTrangThai.Text = "Chu trình xử lý hoàn tất!" }
        [System.Windows.Forms.MessageBox]::Show("Toàn bộ tiến trình đã hoàn tất!", "Thông báo", 0, 64)
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$LogicCaiOfficeV182