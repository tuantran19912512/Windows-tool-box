Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

Ghi-Log "=========================================================="
Ghi-Log ">>> CẤU HÌNH CHUẨN VĂN BẢN HÀNH CHÍNH (NGHỊ ĐỊNH 30) <<<"
Ghi-Log "=========================================================="

# --- PHẦN 1: CẤU HÌNH WINDOWS (DẤU CHẤM, PHẨY, NGÀY THÁNG) ---
Ghi-Log "[1/2] Đang thiết lập Windows Regional (Dấu . , và dd/mm/yyyy)..."
try {
    $RegInt = "HKCU:\Control Panel\International"
    
    # Dấu phẩy ngăn cách thập phân (10,5)
    Set-ItemProperty -Path $RegInt -Name "sDecimal" -Value "," -Force
    # Dấu chấm ngăn cách hàng nghìn (1.000)
    Set-ItemProperty -Path $RegInt -Name "sThousand" -Value "." -Force
    # Định dạng ngày Việt Nam
    Set-ItemProperty -Path $RegInt -Name "sShortDate" -Value "dd/MM/yyyy" -Force
    
    Ghi-Log "   + Đã chỉnh: Thập phân [,], Hàng nghìn [.], Ngày [dd/MM/yyyy]"
} catch {
    Ghi-Log "   ! Lỗi chỉnh Windows: $($_.Exception.Message)"
}

# --- PHẦN 2: CẤU HÌNH MICROSOFT WORD (FONT, LỀ, KHỔ GIẤY A4) ---
Ghi-Log "[2/2] Đang can thiệp Microsoft Word (Normal Template)..."

try {
    # Khởi tạo Word ngầm
    $Word = New-Object -ComObject Word.Application
    $Word.Visible = $false
    
    # Mở file mẫu Normal.dotm
    $NormalTemplate = $Word.NormalTemplate
    $Doc = $NormalTemplate.OpenAsDocument()
    
    Ghi-Log "   + Đang đặt Font: Times New Roman, Cỡ: 14..."
    $Style = $Doc.Styles.Item("Normal")
    $Style.Font.Name = "Times New Roman"
    $Style.Font.Size = 14
    $Style.ParagraphFormat.Alignment = 3 # wdAlignParagraphJustify (Căn đều 2 bên)

    Ghi-Log "   + Đang chỉnh Khổ giấy A4 và Căn lề chuẩn (2-2-3-1.5)..."
    $Doc.PageSetup.PaperSize = 7 # wdPaperA4
    
    # Đổi đơn vị Centimeters sang Points (Chuẩn Nghị định 30)
    $Doc.PageSetup.TopMargin    = $Word.CentimetersToPoints(2.0)  # Lề trên 2cm
    $Doc.PageSetup.BottomMargin = $Word.CentimetersToPoints(2.0)  # Lề dưới 2cm
    $Doc.PageSetup.LeftMargin   = $Word.CentimetersToPoints(3.0)  # Lề trái 3cm (để đóng tập)
    $Doc.PageSetup.RightMargin  = $Word.CentimetersToPoints(1.5)  # Lề phải 1.5cm

    # Lưu và thoát
    $Doc.Close($true)
    $Word.Quit()
    
    Ghi-Log "   + Đã cập nhật Normal.dotm thành công."
} catch {
    Ghi-Log "   ! Lỗi can thiệp Word: $($_.Exception.Message)"
    if ($Word) { $Word.Quit() }
}

Ghi-Log "----------------------------------------------------------"
Ghi-Log ">>> HOÀN TẤT: MÁY TÍNH ĐÃ CHUẨN HOÁ THEO PHÁP LUẬT."
Ghi-Log "----------------------------------------------------------"

[System.Windows.Forms.MessageBox]::Show("Đã cấu hình chuẩn Nghị định 30/2020/NĐ-CP:`n1. Dấu chấm phẩy kiểu Việt Nam.`n2. Word: Times New Roman 14, Khổ A4, Căn lề chuẩn.", "VietToolbox Pro")