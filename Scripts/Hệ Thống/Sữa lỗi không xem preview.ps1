# ==============================================================================
# Tên công cụ: GIAO DIỆN GỠ PHONG ẤN TẬP TIN (BẢN WINFORMS ĐÃ FIX LỖI SCOPE)
# Đặc tính: Fix triệt để lỗi nổ biến Null, Chống tràn RAM, Bảo vệ phần mềm mẹ
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

try {
    # 1. KIỂM TRA QUYỀN QUẢN TRỊ (Dùng return để bảo vệ app mẹ không bị văng)
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        [System.Windows.Forms.MessageBox]::Show("Vui lòng chạy ứng dụng chính bằng quyền Administrator để có thể can thiệp hệ thống!", "Thiếu quyền", 0, 48)
        return 
    }

    # HÀM TẠO MÀU SẮC TỪ MÃ HEX
    function Tao-Mau($MaHex) { return [System.Drawing.ColorTranslator]::FromHtml($MaHex) }

    # KHAI BÁO BIẾN TOÀN CỤC (Đây là mấu chốt để fix lỗi nổ Null)
    $Script:BoDem = $null
    $Script:TienTrinhPS = $null
    $Script:KhongGianChay = $null
    $Script:HangDoiLog = $null
    $Script:KqChayNgam = $null

    # 2. XÂY DỰNG GIAO DIỆN
    $CuaSo = New-Object System.Windows.Forms.Form
    $CuaSo.Text = "🔓 TRÌNH GỠ PHONG ẤN TẬP TIN"
    $CuaSo.Size = New-Object System.Drawing.Size(650, 520)
    $CuaSo.StartPosition = "CenterScreen"
    $CuaSo.BackColor = Tao-Mau "#1E1E2E"
    $CuaSo.ForeColor = Tao-Mau "#F8F8F2"
    $CuaSo.FormBorderStyle = "FixedSingle"
    $CuaSo.MaximizeBox = $false
    $CuaSo.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $NhanDuongDan = New-Object System.Windows.Forms.Label
    $NhanDuongDan.Text = "Nhập đường dẫn (Hỗ trợ: Cục bộ, Mạng UNC, Ổ đĩa ánh xạ):"
    $NhanDuongDan.Location = New-Object System.Drawing.Point(20, 20)
    $NhanDuongDan.AutoSize = $true
    $CuaSo.Controls.Add($NhanDuongDan)

    $OTimKiem = New-Object System.Windows.Forms.TextBox
    $OTimKiem.Location = New-Object System.Drawing.Point(20, 45)
    $OTimKiem.Size = New-Object System.Drawing.Size(480, 30)
    $OTimKiem.BackColor = Tao-Mau "#282A36"
    $OTimKiem.ForeColor = Tao-Mau "#F8F8F2"
    $OTimKiem.BorderStyle = "FixedSingle"
    $OTimKiem.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $CuaSo.Controls.Add($OTimKiem)

    $NutChon = New-Object System.Windows.Forms.Button
    $NutChon.Text = "📁 Duyệt..."
    $NutChon.Location = New-Object System.Drawing.Point(510, 44)
    $NutChon.Size = New-Object System.Drawing.Size(100, 29)
    $NutChon.FlatStyle = "Flat"
    $NutChon.BackColor = Tao-Mau "#8BE9FD"
    $NutChon.ForeColor = Tao-Mau "#282A36"
    $NutChon.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $NutChon.Cursor = [System.Windows.Forms.Cursors]::Hand
    $CuaSo.Controls.Add($NutChon)

    $HopKiemAnToan = New-Object System.Windows.Forms.CheckBox
    $HopKiemAnToan.Text = "Tự động thêm IP máy chủ mạng vào danh sách tin cậy (Sửa lỗi Harmful)"
    $HopKiemAnToan.Location = New-Object System.Drawing.Point(20, 85)
    $HopKiemAnToan.Size = New-Object System.Drawing.Size(600, 25)
    $HopKiemAnToan.Checked = $true
    $HopKiemAnToan.ForeColor = Tao-Mau "#6272A4"
    $CuaSo.Controls.Add($HopKiemAnToan)

    $NutThucThi = New-Object System.Windows.Forms.Button
    $NutThucThi.Text = "⚡ THỰC THI MỞ KHÓA TẬP TIN"
    $NutThucThi.Location = New-Object System.Drawing.Point(20, 125)
    $NutThucThi.Size = New-Object System.Drawing.Size(590, 45)
    $NutThucThi.FlatStyle = "Flat"
    $NutThucThi.BackColor = Tao-Mau "#50FA7B"
    $NutThucThi.ForeColor = Tao-Mau "#282A36"
    $NutThucThi.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $NutThucThi.Cursor = [System.Windows.Forms.Cursors]::Hand
    $CuaSo.Controls.Add($NutThucThi)

    $NhanNhatKy = New-Object System.Windows.Forms.Label
    $NhanNhatKy.Text = "NHẬT KÝ HỆ THỐNG:"
    $NhanNhatKy.Location = New-Object System.Drawing.Point(20, 185)
    $NhanNhatKy.AutoSize = $true
    $NhanNhatKy.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $CuaSo.Controls.Add($NhanNhatKy)

    $KhungNhatKy = New-Object System.Windows.Forms.ListBox
    $KhungNhatKy.Location = New-Object System.Drawing.Point(20, 210)
    $KhungNhatKy.Size = New-Object System.Drawing.Size(590, 150)
    $KhungNhatKy.BackColor = Tao-Mau "#282A36"
    $KhungNhatKy.ForeColor = Tao-Mau "#50FA7B"
    $KhungNhatKy.BorderStyle = "FixedSingle"
    $KhungNhatKy.Font = New-Object System.Drawing.Font("Consolas", 10)
    $CuaSo.Controls.Add($KhungNhatKy)

    $NhanTrangThai = New-Object System.Windows.Forms.Label
    $NhanTrangThai.Text = "Trạng thái: Đang chờ lệnh..."
    $NhanTrangThai.Location = New-Object System.Drawing.Point(20, 380)
    $NhanTrangThai.Size = New-Object System.Drawing.Size(590, 60)
    $NhanTrangThai.ForeColor = Tao-Mau "#FFB86C"
    $NhanTrangThai.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $CuaSo.Controls.Add($NhanTrangThai)

    # 3. KẾT NỐI SỰ KIỆN GIAO DIỆN
    $NutChon.Add_Click({
        $HopThoai = New-Object System.Windows.Forms.OpenFileDialog
        $HopThoai.Title = "Chọn thư mục"
        $HopThoai.ValidateNames = $false
        $HopThoai.CheckFileExists = $false
        $HopThoai.FileName = "Chọn_Thư_Mục_Này" 
        if ($HopThoai.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $OTimKiem.Text = [System.IO.Path]::GetDirectoryName($HopThoai.FileName)
        }
    })

    # Dọn dẹp rác bộ nhớ an toàn
    $CuaSo.Add_FormClosing({
        if ($null -ne $Script:BoDem) { $Script:BoDem.Stop(); $Script:BoDem.Dispose() }
        if ($null -ne $Script:TienTrinhPS) { $Script:TienTrinhPS.Stop() | Out-Null; $Script:TienTrinhPS.Dispose() }
        if ($null -ne $Script:KhongGianChay) { $Script:KhongGianChay.Close(); $Script:KhongGianChay.Dispose() }
    })

    $NutThucThi.Add_Click({
        $DuongDan = $OTimKiem.Text.Trim('"').Trim()
        if ([string]::IsNullOrWhiteSpace($DuongDan)) {
            $NhanTrangThai.Text = "Cảnh báo: Bạn chưa nhập đường dẫn!"
            $NhanTrangThai.ForeColor = Tao-Mau "#FF5555"
            return
        }

        # Xử lý ổ đĩa ánh xạ
        $DuongDanThuc = $DuongDan
        if ($DuongDan -match "^([A-Za-z]):") {
            $KyTuO = $matches[1]
            $ThongTinMang = Get-ItemProperty -Path "HKCU:\Network\$KyTuO" -ErrorAction SilentlyContinue
            if ($null -ne $ThongTinMang -and -not [string]::IsNullOrEmpty($ThongTinMang.RemotePath)) {
                $DuongDanThuc = $DuongDan -replace "^[A-Za-z]:", $ThongTinMang.RemotePath
            }
        }

        if (-not (Test-Path -LiteralPath $DuongDanThuc)) {
            $NhanTrangThai.Text = "Lỗi: Không tìm thấy đường dẫn '$DuongDanThuc'."
            $NhanTrangThai.ForeColor = Tao-Mau "#FF5555"
            return
        }

        $NutThucThi.Enabled = $false
        $KhungNhatKy.Items.Clear()
        $KhungNhatKy.Items.Add("> Bắt đầu quy trình quét...") | Out-Null
        $NhanTrangThai.Text = "Đang trích xuất dữ liệu ngầm, vui lòng không tắt công cụ..."
        $NhanTrangThai.ForeColor = Tao-Mau "#FFB86C"

        $CapQuyenMang = $HopKiemAnToan.Checked
        $TenMayChu = $null
        if ($CapQuyenMang -and $DuongDanThuc -match "^\\\\\\*([^\\]+)") { $TenMayChu = $matches[1] }

        # LƯU VÀO BIẾN TOÀN CỤC THAY VÌ BIẾN CỤC BỘ
        $Script:HangDoiLog = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

        $Script:KhongGianChay = [runspacefactory]::CreateRunspace()
        $Script:KhongGianChay.ThreadOptions = "ReuseThread"
        $Script:KhongGianChay.Open()
        $Script:TienTrinhPS = [powershell]::Create()
        $Script:TienTrinhPS.Runspace = $Script:KhongGianChay

        [void]$Script:TienTrinhPS.AddScript({
            param($DuongDanQuet, $MayChu, $HangDoi)
            try {
                $TinNhan = ""
                if ($MayChu) {
                    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
                    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
                    Set-ItemProperty -Path $RegPath -Name $MayChu -Value "1" -Type String -Force
                    $TinNhan = " (Đã cấp quyền mạng)"
                }
                
                $DaXuLy = 0
                Get-ChildItem -LiteralPath $DuongDanQuet -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    $_ | Unblock-File -ErrorAction SilentlyContinue
                    $DaXuLy++
                    
                    $TenHienThi = $_.FullName
                    if ($TenHienThi.Length -gt 60) { $TenHienThi = "..." + $TenHienThi.Substring($TenHienThi.Length - 57) }
                    $HangDoi.Enqueue("[$DaXuLy] $TenHienThi")
                }
                
                if ($DaXuLy -eq 0) {
                    return "THANHCONG|Không có tập tin nào cần xử lý hoặc thư mục trống.$TinNhan"
                }
                return "THANHCONG|Đã mở khóa $DaXuLy tập tin thành công.$TinNhan"
            } catch {
                return "LOI|$_"
            }
        }).AddArgument($DuongDanThuc).AddArgument($TenMayChu).AddArgument($Script:HangDoiLog)

        $Script:KqChayNgam = $Script:TienTrinhPS.BeginInvoke()

        $Script:BoDem = New-Object System.Windows.Forms.Timer
        $Script:BoDem.Interval = 80

        # TRONG TIMER NÀY HIỆN TẠI ĐÃ SỬ DỤNG $SCRIPT: ĐỂ LUÔN TÌM THẤY BIẾN
        $Script:BoDem.Add_Tick({
            $DongLogMoi = ""
            while ($Script:HangDoiLog.TryDequeue([ref]$DongLogMoi)) {
                $KhungNhatKy.Items.Add($DongLogMoi) | Out-Null
                if ($KhungNhatKy.Items.Count -gt 60) { $KhungNhatKy.Items.RemoveAt(0) }
                $KhungNhatKy.TopIndex = $KhungNhatKy.Items.Count - 1 
            }

            if ($Script:KqChayNgam.IsCompleted) {
                $Script:BoDem.Stop()
                
                try {
                    $KetQuaTraVe = $Script:TienTrinhPS.EndInvoke($Script:KqChayNgam)
                } catch {
                    $KetQuaTraVe = "LOI|Đứt kết nối với luồng ngầm: $_"
                }
                
                $Script:TienTrinhPS.Dispose()
                $Script:KhongGianChay.Close()
                $Script:KhongGianChay.Dispose()

                $TachKQ = $KetQuaTraVe -split "\|", 2
                if ($TachKQ[0] -eq "THANHCONG") {
                    $KhungNhatKy.Items.Add("> " + $TachKQ[1]) | Out-Null
                    $KhungNhatKy.TopIndex = $KhungNhatKy.Items.Count - 1
                    $NhanTrangThai.Text = $TachKQ[1]
                    $NhanTrangThai.ForeColor = Tao-Mau "#50FA7B"
                } else {
                    $NhanTrangThai.Text = "Lỗi hệ thống: " + $TachKQ[1]
                    $NhanTrangThai.ForeColor = Tao-Mau "#FF5555"
                }
                $NutThucThi.Enabled = $true
            }
        })
        
        $Script:BoDem.Start()
    })

    $CuaSo.ShowDialog() | Out-Null

} catch {
    [System.Windows.Forms.MessageBox]::Show("Lỗi trong quá trình khởi tạo công cụ: $_", "Lỗi Hệ Thống", 0, 16)
}