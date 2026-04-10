<#
.SYNOPSIS
    CÔNG CỤ TRIỂN KHAI WINDOWS TỰ ĐỘNG - PHIÊN BẢN ZERO-TOUCH (SIÊU NHẸ)
    Tác giả: Tuấn & AI Assistant
#>

# ==========================================
# 1. YÊU CẦU QUYỀN ADMIN & ÉP LUỒNG STA
# ==========================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ==========================================
# 2. HÀM GIAO DIỆN PHỤ & LÀM MƯỢT UI
# ==========================================
function CapNhat-GiaoDien {
    $KhungChayDoi = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [System.Action]{ $KhungChayDoi.Continue = $false }) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($KhungChayDoi)
}

function Chon-ThuMucHienDai($TieuDe) {
    $HopThoai = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoai.Title = $TieuDe
    $HopThoai.ValidateNames = $false
    $HopThoai.CheckFileExists = $false
    $HopThoai.CheckPathExists = $true
    $HopThoai.FileName = "[Vào_thư_mục_và_bấm_Open]" 
    if ($HopThoai.ShowDialog() -eq 'OK') { return [System.IO.Path]::GetDirectoryName($HopThoai.FileName) }
    return $null
}

# ==========================================
# 3. XÂY DỰNG GIAO DIỆN WPF (XAML)
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Hệ Thống Triển Khai Windows Tự Động (Zero-Touch)" 
        Width="700" Height="650" WindowStartupLocation="CenterScreen" Background="#F0F4F8">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="HỆ THỐNG CÀI ĐẶT WINDOWS TỰ ĐỘNG" FontSize="22" FontWeight="Bold" Foreground="#1E293B" HorizontalAlignment="Center" Margin="0,0,0,20"/>

        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="1. Chọn file bộ cài (WIM / ESD / ISO) và Phiên bản:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="HopThoaiFileBoCai" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0"/>
                    <Button Name="NutChonFileBoCai" Grid.Column="1" Content="Duyệt File" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                </Grid>
                <ComboBox Name="DanhSachPhienBanWin" Height="32" Margin="0,10,0,0" VerticalContentAlignment="Center">
                    <ComboBoxItem Content="Chưa có bộ cài nào được nạp..." IsSelected="True"/>
                </ComboBox>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="2. Thư mục chứa Driver (Tự động xả sau khi cài):" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="HopThoaiThuMucDriver" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0"/>
                    <Button Name="NutChonThuMucDriver" Grid.Column="1" Content="Chọn Thư Mục" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                </Grid>
            </StackPanel>
        </Border>

        <Border Grid.Row="3" Background="#0F172A" CornerRadius="4" Margin="0,0,0,15" Padding="5">
            <TextBox Name="HopThoaiNhatKy" Background="Transparent" Foreground="#38BDF8" FontFamily="Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
        </Border>

        <Button Name="NutBatDauCaiDat" Grid.Row="4" Content="BẮT ĐẦU TỰ ĐỘNG HÓA HỆ THỐNG" Height="50" Background="#E11D48" Foreground="White" FontSize="16" FontWeight="Bold" BorderThickness="0"/>
    </Grid>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML)
$GiaoDien = [Windows.Markup.XamlReader]::Load($TrinhDoc)

# Đã khớp nối 100% tên biến với XAML
$HopThoaiFileBoCai = $GiaoDien.FindName("HopThoaiFileBoCai")
$NutChonFileBoCai = $GiaoDien.FindName("NutChonFileBoCai")
$DanhSachPhienBanWin = $GiaoDien.FindName("DanhSachPhienBanWin")
$HopThoaiThuMucDriver = $GiaoDien.FindName("HopThoaiThuMucDriver")
$NutChonThuMucDriver = $GiaoDien.FindName("NutChonThuMucDriver")
$HopThoaiNhatKy = $GiaoDien.FindName("HopThoaiNhatKy")
$NutBatDauCaiDat = $GiaoDien.FindName("NutBatDauCaiDat")

# ==========================================
# 4. HÀM XỬ LÝ LÕI VÀ SỰ KIỆN UI
# ==========================================

function Ghi-NhatKy($NoiDung) {
    $ThoiGian = Get-Date -Format "HH:mm:ss"
    $HopThoaiNhatKy.AppendText("[$ThoiGian] $NoiDung`n")
    $HopThoaiNhatKy.ScrollToEnd()
    CapNhat-GiaoDien
}

# --- HÀM QUÉT INDEX TỪ FILE BỘ CÀI ---
function Quet-VaCapNhatPhienBanWin {
    $DuongDanFile = $HopThoaiFileBoCai.Text
    if (-not (Test-Path $DuongDanFile)) { return }

    Ghi-NhatKy "Đang dùng DISM quét lõi bộ cài..."
    $DanhSachPhienBanWin.Items.Clear()
    $DanhSachPhienBanWin.IsEnabled = $false
    $DanhSachPhienBanWin.Items.Add("⏳ Đang phân tích file...") | Out-Null
    $DanhSachPhienBanWin.SelectedIndex = 0
    CapNhat-GiaoDien

    $FileWimCanQuet = $DuongDanFile
    $DaMountIso = $false
    $KyTuODiaAo = $null

    try {
        if ($DuongDanFile -match '(?i)\.iso$') {
            $ThongTinMount = Mount-DiskImage -ImagePath $DuongDanFile -PassThru
            Start-Sleep -Seconds 1 
            $KyTuODiaAo = (Get-DiskImage -ImagePath $DuongDanFile | Get-Volume).DriveLetter
            if ($KyTuODiaAo -is [array]) { $KyTuODiaAo = $KyTuODiaAo[0] }
            if (-not $KyTuODiaAo) { throw "Không tạo được ổ ảo từ ISO." }
            
            $FileWimCanQuet = "$($KyTuODiaAo):\sources\install.wim"
            if (-not (Test-Path $FileWimCanQuet)) { $FileWimCanQuet = "$($KyTuODiaAo):\sources\install.esd" }
            $DaMountIso = $true
        }

        if (Test-Path $FileWimCanQuet) {
            $ThongTinWim = dism.exe /Get-WimInfo /WimFile:$FileWimCanQuet /English
            $CacPhienBan = @()
            $ChiSoHienTai = $null
            
            foreach ($Dong in $ThongTinWim) {
                if ($Dong -match 'Index : (\d+)') { $ChiSoHienTai = $matches[1] }
                if ($Dong -match 'Name : (.*)') {
                    if ($ChiSoHienTai) {
                        $CacPhienBan += [PSCustomObject]@{ Index = $ChiSoHienTai; Ten = $matches[1] }
                        $ChiSoHienTai = $null
                    }
                }
            }

            $DanhSachPhienBanWin.Items.Clear()
            if ($CacPhienBan.Count -gt 0) {
                foreach ($BanWin in $CacPhienBan) {
                    $DanhSachPhienBanWin.Items.Add("Index $($BanWin.Index): $($BanWin.Ten)") | Out-Null
                }
                $DanhSachPhienBanWin.IsEnabled = $true
                $DanhSachPhienBanWin.SelectedIndex = 0
                Ghi-NhatKy "✅ Tìm thấy $($CacPhienBan.Count) phiên bản hệ điều hành!"
            } else {
                $DanhSachPhienBanWin.Items.Add("❌ Không đọc được danh sách") | Out-Null
            }
        } else {
            $DanhSachPhienBanWin.Items.Clear()
            $DanhSachPhienBanWin.Items.Add("❌ Lỗi: ISO không chứa file WIM/ESD") | Out-Null
        }
    } catch {
        Ghi-NhatKy "Lỗi khi quét file: $_"
        $DanhSachPhienBanWin.Items.Clear()
        $DanhSachPhienBanWin.Items.Add("❌ Xảy ra lỗi khi đọc bộ cài") | Out-Null
    } finally {
        if ($DaMountIso) { Dismount-DiskImage -ImagePath $DuongDanFile | Out-Null }
    }
}

# --- CÁC NÚT DUYỆT THƯ MỤC/FILE ---
$NutChonFileBoCai.Add_Click({
    $HopThoaiFile = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoaiFile.Title = "Chọn file bộ cài (WIM, ESD, ISO)"
    $HopThoaiFile.Filter = "Windows Setup Files (*.wim;*.esd;*.iso)|*.wim;*.esd;*.iso|All Files (*.*)|*.*"
    if ($HopThoaiFile.ShowDialog() -eq 'OK') { 
        $HopThoaiFileBoCai.Text = $HopThoaiFile.FileName 
        Quet-VaCapNhatPhienBanWin
    }
})

$NutChonThuMucDriver.Add_Click({
    $KetQua = Chon-ThuMucHienDai "Chọn thư mục chứa Driver cho máy này"
    if ($KetQua) { $HopThoaiThuMucDriver.Text = $KetQua }
})


# ==========================================
# 5. KHỐI LÕI: CAN THIỆP PHÂN VÙNG VÀ WINRE
# ==========================================

function ChuanBi-PhanVungHeThong {
    Ghi-NhatKy "Đang kiểm tra cấu trúc EFI & Recovery..."
    
    try {
        $ChuCaiO_Win = [System.IO.Path]::GetPathRoot($env:windir).Substring(0,1)
        
        $PhanVungOS = Get-Partition -DriveLetter $ChuCaiO_Win -ErrorAction Stop
        $global:OsDiskNum = $PhanVungOS.DiskNumber
        $global:OsPartNum = $PhanVungOS.PartitionNumber 

        Ghi-NhatKy "Xác nhận OS nằm trên Disk: $global:OsDiskNum, Partition: $global:OsPartNum"

        $CacPhanVung = Get-Partition -DiskNumber $global:OsDiskNum
        $CoEFI = $CacPhanVung | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -or $_.Type -eq 'System' }
        $CoRec = $CacPhanVung | Where-Object { $_.GptType -eq '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -or $_.Type -eq 'Recovery' }

        if (-not $CoEFI -or -not $CoRec) {
            Ghi-NhatKy "⚠️ Thiếu phân vùng hệ thống. Đang tách 1GB từ ổ $ChuCaiO_Win để tạo..."
            
            $KichThuocHienTai = $PhanVungOS.Size
            $KichThuocMoi = $KichThuocHienTai - 1GB
            
            Resize-Partition -DriveLetter $ChuCaiO_Win -Size $KichThuocMoi -ErrorAction Stop
            
            $ScriptDiskpart = @"
select disk $global:OsDiskNum
create partition efi size=260
format quick fs=fat32 label="System"
assign letter=S
create partition primary size=740
format quick fs=ntfs label="Recovery"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
assign letter=R
"@
            $PathDiskpart = "$env:TEMP\diskpart_auto.txt"
            $ScriptDiskpart | Out-File $PathDiskpart -Encoding ascii
            Start-Process "diskpart.exe" "/s $PathDiskpart" -Wait -WindowStyle Hidden
            
            Ghi-NhatKy "✅ Đã cấu trúc lại phân vùng EFI & Recovery thành công."
        } else {
            Ghi-NhatKy "✅ Hệ thống đã có đủ phân vùng cần thiết."
        }
    } catch {
        $Loi = $_.Exception.Message
        Ghi-NhatKy "❌ LỖI PHÂN VÙNG: $Loi"
        throw "Không thể chuẩn bị phân vùng: $Loi"
    }
}

function Do-WinRE_Va_KichNo {
    param($WimPath, $Index, $DriverPath)
    
    Ghi-NhatKy "Đang trích xuất thông tin định tuyến ổ đĩa..."
    $PhanVungOS = Get-Partition -DriveLetter "C"
    $OsDiskNum = $PhanVungOS.DiskNumber
    $OsPartNum = $PhanVungOS.PartitionNumber

    $DuongDanTuongDoi = $WimPath.Substring(3)

    Ghi-NhatKy "Đang Reset và mở khóa WinRE..."
    reagentc.exe /enable | Out-Null; Start-Sleep 2
    reagentc.exe /disable | Out-Null; Start-Sleep 2

    $WinRE_Goc = "C:\Windows\System32\Recovery\winre.wim"
    if (-not (Test-Path $WinRE_Goc)) { throw "Lỗi Chí Mạng: Mất file winre.wim gốc!" }

    Ghi-NhatKy "Đang dọn dẹp các tiến trình DISM bị kẹt..."
    dism.exe /Cleanup-Wim | Out-Null
    CapNhat-GiaoDien

    $ThuMucMount = "C:\MountRE"
    if (Test-Path $ThuMucMount) { 
        dism.exe /Unmount-Image /MountDir:$ThuMucMount /Discard | Out-Null
        Remove-Item -Path $ThuMucMount -Recurse -Force 
    }
    New-Item -ItemType Directory -Path $ThuMucMount | Out-Null

    $ThuMucXuLy = "C:\WinRE_XuLy"
    if (-not (Test-Path $ThuMucXuLy)) { New-Item -ItemType Directory -Path $ThuMucXuLy | Out-Null }
    
    $WinRE_Copy = "$ThuMucXuLy\winre.wim"
    Copy-Item -Path $WinRE_Goc -Destination $WinRE_Copy -Force
    Set-ItemProperty -Path $WinRE_Copy -Name IsReadOnly -Value $false

    Ghi-NhatKy "Đang Mount WinRE an toàn (Xin đợi 30s-1p)..."
    CapNhat-GiaoDien
    $MntRes = dism.exe /Mount-Image /ImageFile:$WinRE_Copy /Index:1 /MountDir:$ThuMucMount | Out-String
    if ($MntRes -notmatch "completed successfully") { throw "DISM không thể Mount: $MntRes" }

    Ghi-NhatKy "Đang cấy kịch bản tự động hóa MỚI vào não WinRE..."
    
    @"
@echo off
echo Xa Driver vao he thong...
pnputil /add-driver "$DriverPath\*.inf" /subdirs /install
echo Phat hanh Anydesk...
powershell -Command "Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'"
start "" "C:\Users\Public\Desktop\AnyDesk.exe"
del %0
"@ | Out-File "$ThuMucMount\Windows\System32\LenhCaiXong_TamThoi.cmd" -Encoding oem

    @"
@echo off
echo ==============================================
echo KHOI DONG HE THONG ZERO-TOUCH DEPLOYMENT
echo ==============================================

echo 1. Quet tim file bo cai tren tat ca cac o dia...
set "WIM_THUC_TE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\$DuongDanTuongDoi" (
        set "WIM_THUC_TE=%%D:\$DuongDanTuongDoi"
        goto :TimThayWim
    )
)

:TimThayWim
if "%WIM_THUC_TE%"=="" (
    echo [LOI] Khong tim thay file $DuongDanTuongDoi tren bat ky o dia nao!
    goto :DungHienTruong
)
echo [OK] Phat hien bo cai tai: %WIM_THUC_TE%

echo.
echo 2. Format dung phan vung he dieu hanh (Disk $OsDiskNum - Part $OsPartNum)...
echo select disk $OsDiskNum > X:\dinhdang.txt
echo select partition $OsPartNum >> X:\dinhdang.txt
echo assign letter=W >> X:\dinhdang.txt
echo format quick fs=ntfs label="Windows" >> X:\dinhdang.txt
diskpart /s X:\dinhdang.txt

echo.
echo 3. Dang trien khai Windows (DISM) - Vui long doi...
dism /apply-image /imagefile:"%WIM_THUC_TE%" /index:$Index /applydir:W:\
if %errorlevel% neq 0 (
    echo [LOI] DISM ap dung Image that bai. Ma loi: %errorlevel%
    goto :DungHienTruong
)

echo.
echo 4. Tao boot cho Windows...
bcdboot W:\Windows

echo.
echo 5. Dua lenh hau cai dat vao he thong moi...
mkdir W:\Windows\Setup\Scripts
copy /Y X:\Windows\System32\LenhCaiXong_TamThoi.cmd W:\Windows\Setup\Scripts\SetupComplete.cmd

echo.
echo 6. XOA CONFIG WINRE DE PHA VONG LAP KHOI DONG...
if exist X:\Windows\System32\winpeshl.ini del X:\Windows\System32\winpeshl.ini /F /Q

echo Thanh cong! Khoi dong lai trong 5 giay...
timeout /t 5
wpeutil reboot
exit

:DungHienTruong
echo ==============================================
echo [CANH BAO] XAY RA LOI! TIEN TRINH BI DUNG LAI.
echo Huy bo tu dong reboot de tranh vong lap vo tan.
if exist X:\Windows\System32\winpeshl.ini del X:\Windows\System32\winpeshl.ini /F /Q
echo Nhan phim bat ky de mo CMD...
pause >nul
cmd.exe
"@ | Out-File "$ThuMucMount\Windows\System32\LenhChayTrongRE.cmd" -Encoding oem

    "[LaunchApps]`r`nX:\Windows\System32\LenhChayTrongRE.cmd" | Out-File "$ThuMucMount\Windows\System32\winpeshl.ini" -Encoding ascii

    Ghi-NhatKy "Đang khâu vết mổ và lưu lại WinRE..."
    CapNhat-GiaoDien
    $UnmntRes = dism.exe /Unmount-Image /MountDir:$ThuMucMount /Commit | Out-String
    if ($UnmntRes -notmatch "completed successfully") {
        dism.exe /Unmount-Image /MountDir:$ThuMucMount /Discard | Out-Null
        throw "Lỗi lưu WinRE: $UnmntRes"
    }
    Remove-Item -Path $ThuMucMount -Force

    Ghi-NhatKy "Đang nạp WinRE siêu cấp vào lại hệ thống..."
    Set-ItemProperty -Path $WinRE_Goc -Name IsReadOnly -Value $false
    Copy-Item -Path $WinRE_Copy -Destination $WinRE_Goc -Force
    Remove-Item -Path $ThuMucXuLy -Recurse -Force

    reagentc.exe /enable | Out-Null
    Ghi-NhatKy "Ra lệnh chốt hạ: Ép khởi động vào Recovery!"
    reagentc.exe /boottore | Out-Null
}

# ==========================================
# 6. KÍCH NỔ HỆ THỐNG
# ==========================================
$NutBatDauCaiDat.Add_Click({
    try {
        $FileCai = $HopThoaiFileBoCai.Text
        $FileDriver = $HopThoaiThuMucDriver.Text
        $ChonIndex = $DanhSachPhienBanWin.SelectedItem

        if (-not (Test-Path $FileCai)) { throw "CHẶN: Chưa có file bộ cài hợp lệ!" }
        if ($ChonIndex -notmatch 'Index (\d+):') { throw "CHẶN: Vui lòng chọn một phiên bản Win!" }
        $IndexLoi = $matches[1]

        if ([System.IO.Path]::GetPathRoot($FileCai) -match "(?i)^C:") {
            throw "NGUY HIỂM: File cài nằm trên ổ C:\ ! Hệ thống sẽ format ổ C, file cài sẽ bị xoá. Vui lòng dời sang ổ khác."
        }

        $XacNhan = [System.Windows.Forms.MessageBox]::Show("BẠN SẮP FORMAT Ổ C VÀ CÀI LẠI WIN.`nPhiên bản: $ChonIndex`n`nDữ liệu ổ C sẽ mất sạch. Khởi chạy?", "ĐIỂM KHÔNG QUAY ĐẦU", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Stop)
        if ($XacNhan -ne 'Yes') { return }

        $NutBatDauCaiDat.IsEnabled = $false
        $GiaoDien.Cursor = [System.Windows.Input.Cursors]::Wait

        if ($FileCai -match '(?i)\.iso$') {
            Ghi-NhatKy "Đang xả nén file ruột từ ISO..."
            $MntIso = Mount-DiskImage -ImagePath $FileCai -PassThru
            Start-Sleep 1
            $KyTuIso = (Get-DiskImage -ImagePath $FileCai | Get-Volume).DriveLetter[0]
            
            $Wim = "$($KyTuIso):\sources\install.wim"
            $Esd = "$($KyTuIso):\sources\install.esd"
            $FileTrich = if (Test-Path $Wim) { $Wim } elseif (Test-Path $Esd) { $Esd } else { $null }

            if (-not $FileTrich) { throw "ISO này không có file install.wim/esd" }

            $FileCai = Join-Path ([System.IO.Path]::GetDirectoryName($FileCai)) ("install_extracted" + [System.IO.Path]::GetExtension($FileTrich))
            Copy-Item -Path $FileTrich -Destination $FileCai -Force
            Dismount-DiskImage -ImagePath $HopThoaiFileBoCai.Text | Out-Null
            Ghi-NhatKy "✅ Trích xuất ruột ISO thành công!"
        }

        ChuanBi-PhanVungHeThong
        Do-WinRE_Va_KichNo -WimPath $FileCai -Index $IndexLoi -DriverPath $FileDriver
        
        Ghi-NhatKy "🚀 HOÀN TẤT! HỆ THỐNG SẼ TỰ RESET TRONG 5 GIÂY ĐỂ VÀO QUY TRÌNH ZERO-TOUCH."
        Start-Sleep -Seconds 5
        
        # [MỞ KHÓA KHI ĐEM ĐI SỬ DỤNG THỰC TẾ]
		Restart-Computer -Force
    } catch {
        $Loi = $_.Exception.Message
        Ghi-NhatKy "❌ LỖI HỆ THỐNG CHẶN ĐƯỢC: $Loi"
        [System.Windows.Forms.MessageBox]::Show($Loi, "Tiến Trình Bị Hủy Bỏ Tự Động", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $NutBatDauCaiDat.IsEnabled = $true
        $GiaoDien.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

$GiaoDien.ShowDialog() | Out-Null