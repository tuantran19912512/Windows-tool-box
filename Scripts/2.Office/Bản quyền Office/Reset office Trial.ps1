# Nạp thư viện giao diện (Đảm bảo hộp thoại MessageBox luôn chạy được)
Add-Type -AssemblyName System.Windows.Forms

# ==============================================================================
# LOGIC GIA HẠN OFFICE 30 NGÀY (BẢN TỰ THÍCH NGHI, CHỐNG LỖI HÀM)
# ==============================================================================

# 1. Hàm phụ trợ tìm file cấu hình Office
function Tim-OSPP {
    return (Get-ChildItem "C:\Program Files\Microsoft Office", "C:\Program Files (x86)\Microsoft Office" -Filter OSPP.VBS -Recurse -ErrorAction SilentlyContinue | Select -First 1).FullName
}

# 2. Hàm Ghi log an toàn (Tự nhận diện tool chính)
function GhiLog-AnToan ($text) {
    if (Get-Command GhiLog -ErrorAction SilentlyContinue) { GhiLog $text }
    else { Write-Host $text }
}

# 3. Đóng gói toàn bộ Logic vào một biến
$LogicThucThi = {
    # Nhảy sang tab Log nếu có hàm ChuyenTab
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    GhiLog-AnToan ">>> BẮT ĐẦU LÀM MỚI THỜI GIAN DÙNG THỬ OFFICE (REARM)..."
    GhiLog-AnToan "-> Đang tìm kiếm file hệ thống (OSPP.VBS)..."
    
    $osppPath = Tim-OSPP
    
    if ($osppPath) {
        GhiLog-AnToan "   + Đã tìm thấy tại: $osppPath"
        GhiLog-AnToan "-> Đang gửi lệnh gia hạn..."
        
        # Thực thi lệnh rearm và hứng kết quả
        $ketQua = cscript //nologo "$osppPath" /rearm | Out-String
        
        # In kết quả trả về
        $ketQua -split "`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
            GhiLog-AnToan "   $($_.Trim())"
        }
        
        # Phân tích kết quả
        if ($ketQua -match "successful" -or $ketQua -match "Thành công") {
            GhiLog-AnToan ">>> HOÀN TẤT: Đã gia hạn thành công!"
            [System.Windows.Forms.MessageBox]::Show("Office đã được gia hạn thêm 30 ngày dùng thử!", "Thành công", 0, 64)
        } else {
            GhiLog-AnToan "!!! LƯU Ý: Lệnh chạy xong nhưng có thể đã hết số lần gia hạn (Tối đa 5 lần)."
            [System.Windows.Forms.MessageBox]::Show("Có thể Office này đã hết số lần cho phép Reset (tối đa 5 lần).", "Lưu ý", 0, 48)
        }
    } else {
        GhiLog-AnToan "!!! LỖI: Không tìm thấy file OSPP.VBS."
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy bộ cài Office tiêu chuẩn trên máy khách!", "Lỗi hệ thống", 0, 16)
    }
}

# 4. THỰC THI AN TOÀN BẤT CHẤP MÔI TRƯỜNG
if (Get-Command ChayTacVu -ErrorAction SilentlyContinue) {
    # Nếu VietToolbox truyền được hàm ChayTacVu vào thì dùng
    ChayTacVu "Đang Reset Trial 30 ngày..." $LogicThucThi
} else {
    # Nếu không nhận diện được hàm, tự động chạy trực tiếp đoạn code luôn
    &$LogicThucThi
}