Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Hàm tự thích nghi cho VietToolbox
function GhiLog-AnToan ($VanBan) {
    if (Get-Command GhiLog -ErrorAction SilentlyContinue) { GhiLog $VanBan }
    else { Write-Host $VanBan }
}

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    GhiLog-AnToan "=========================================================="
    GhiLog-AnToan ">>> CÔNG CỤ XÓA MẬT KHẨU BẢO VỆ SHEET EXCEL (BẢN V3) <<<"
    GhiLog-AnToan "=========================================================="
    
    $HopThoaiChonFile = New-Object System.Windows.Forms.OpenFileDialog
    $HopThoaiChonFile.Filter = "File Excel (*.xlsx;*.xlsm)|*.xlsx;*.xlsm"
    $HopThoaiChonFile.Title = "Chọn file Excel đang bị khóa Sheet (Không dùng cho file có Pass mở file)..."
    
    if ($HopThoaiChonFile.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $FileGoc = $HopThoaiChonFile.FileName
        $ThuMucChua = Split-Path $FileGoc
        $TenFileCuaKhach = [System.IO.Path]::GetFileNameWithoutExtension($FileGoc)
        $DuoiFile = [System.IO.Path]::GetExtension($FileGoc)
        
        $FileDaMoKhoa = Join-Path $ThuMucChua "$TenFileCuaKhach`_DaMoKhoa$DuoiFile"
        $ThuMucTam = Join-Path $env:TEMP "MoKhoaExcel_$TenFileCuaKhach"
        
        GhiLog-AnToan "-> Đã chọn file: $TenFileCuaKhach$DuoiFile"
        
        try {
            if (Test-Path $ThuMucTam) { Remove-Item $ThuMucTam -Recurse -Force -ErrorAction SilentlyContinue }
            if (Test-Path $FileDaMoKhoa) { Remove-Item $FileDaMoKhoa -Force -ErrorAction SilentlyContinue }
            
            GhiLog-AnToan "-> Đang kiểm tra cấu trúc mã hóa của file..."
            
            # ĐỌC THỬ MAGIC BYTES: Nếu file bị mã hóa "Pass mở file", nó không còn là file nén (ZIP) nữa
            try {
                [System.IO.Compression.ZipFile]::ExtractToDirectory($FileGoc, $ThuMucTam)
            } catch {
                # Nếu không thể bung nén, 99% là file đã bị mã hóa cứng (Password to Open)
                GhiLog-AnToan "!!! TỪ CHỐI BẺ KHÓA: File bị mã hóa toàn bộ (Có Pass mở file)."
                [System.Windows.Forms.MessageBox]::Show("KHÔNG THỂ PHÁ PASS!`n`nFile này đang được bảo vệ bằng 'Mật khẩu mở file' (Mã hóa AES cấp cao) chứ không phải khóa Sheet thông thường.`nTool chỉ hỗ trợ bẻ khóa các file bạn có thể mở lên xem nhưng không được phép chỉnh sửa.", "Giới hạn bảo mật", 0, 48)
                return
            }
            
            $DaPhaPass = $false
            $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
            
            $DanhSachXML = Get-ChildItem -Path $ThuMucTam -Recurse -Filter "*.xml" | Where-Object { $_.FullName -match "xl\\worksheets\\sheet" -or $_.Name -eq "workbook.xml" }
            
            GhiLog-AnToan "-> Đang rà quét và cắt ổ khóa bên trong mã nguồn..."
            foreach ($FileXML in $DanhSachXML) {
                $NoiDungXML = [System.IO.File]::ReadAllText($FileXML.FullName)
                
                if ($NoiDungXML -match "<sheetProtection.*?>|<workbookProtection.*?>") {
                    GhiLog-AnToan "   + Đã bẻ gãy khóa tại: $($FileXML.Name)"
                    
                    $NoiDungXML = $NoiDungXML -replace "<sheetProtection.*?>", ""
                    $NoiDungXML = $NoiDungXML -replace "</sheetProtection>", ""
                    $NoiDungXML = $NoiDungXML -replace "<workbookProtection.*?>", ""
                    $NoiDungXML = $NoiDungXML -replace "</workbookProtection>", ""
                    
                    [System.IO.File]::WriteAllText($FileXML.FullName, $NoiDungXML, $Utf8NoBom)
                    $DaPhaPass = $true
                }
            }
            
            if ($DaPhaPass) {
                GhiLog-AnToan "-> Đang đóng gói lại thành file Excel hoàn chỉnh..."
                [System.IO.Compression.ZipFile]::CreateFromDirectory($ThuMucTam, $FileDaMoKhoa)
                
                GhiLog-AnToan ">>> HOÀN TẤT: ĐÃ XÓA SẠCH MẬT KHẨU SHEET!"
                [System.Windows.Forms.MessageBox]::Show("Đã bẻ khóa Sheet thành công!`nTool đã tạo ra file mới có chữ '_DaMoKhoa'. Mở lên gõ thoải mái nhé!", "Thành công", 0, 64)
            } else {
                GhiLog-AnToan ">>> BỎ QUA: Không tìm thấy khóa Sheet trong file này."
                [System.Windows.Forms.MessageBox]::Show("File này không bị khóa Sheet.", "Thông báo", 0, 48)
            }
            
        } catch {
            GhiLog-AnToan "!!! LỖI: Không thể can thiệp vào file."
            [System.Windows.Forms.MessageBox]::Show("Lỗi bẻ khóa! Đảm bảo file Excel đang đóng hoàn toàn trước khi chạy Tool nhé.", "Lỗi", 0, 16)
        } finally {
            if (Test-Path $ThuMucTam) { Remove-Item $ThuMucTam -Recurse -Force -ErrorAction SilentlyContinue }
        }
    } else {
        GhiLog-AnToan "-> Đã hủy thao tác."
    }
}

# Chạy vào hệ thống động của VietToolbox
if (Get-Command ChayTacVu -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang phá pass file Excel..." $LogicThucThi
} else {
    &$LogicThucThi
}