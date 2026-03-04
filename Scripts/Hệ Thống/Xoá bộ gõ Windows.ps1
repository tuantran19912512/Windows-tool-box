Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

Ghi-Log "=========================================="
Ghi-Log ">>> KIỂM TRA NGÔN NGỮ & BỘ GÕ HỆ THỐNG <<<"

# 1. Liệt kê danh sách đang có ra khung LOG
$CurrentList = Get-WinUserLanguageList
Ghi-Log "DANH SÁCH HIỆN TẠI:"
foreach ($lang in $CurrentList) {
    Ghi-Log "   [+] $($lang.LanguageTag) - $($lang.Autonym)"
}
Ghi-Log "------------------------------------------"

# 2. Hiển thị bảng chọn
$MenuMessage = "MÁY ĐANG CÓ $(( $CurrentList.Count )) NGÔN NGỮ.`n" +
               "Bạn muốn dọn dẹp như thế nào?`n`n" +
               "1. CHỈ GIỮ TIẾNG ANH (en-US) - Xóa hết cái khác`n" +
               "2. CHỈ GIỮ TIẾNG VIỆT (vi-VN) - Xóa hết cái khác`n" +
               "3. GIỮ CẢ TIẾNG VIỆT & ANH (Sạch nhất)`n" +
               "0. KHÔNG XÓA - Thoát ngay"

$LuaChon = [Microsoft.VisualBasic.Interaction]::InputBox($MenuMessage, "DỌN DẸP LAYOUT BÀN PHÍM", "3")

# 3. Xử lý logic
switch ($LuaChon) {
    "1" {
        Ghi-Log "-> Đang thực hiện: CHỈ GIỮ TIẾNG ANH (en-US)..."
        $NewList = New-WinUserLanguageList en-US
        Set-WinUserLanguageList $NewList -Force
    }
    
    "2" {
        Ghi-Log "-> Đang thực hiện: CHỈ GIỮ TIẾNG VIỆT (vi-VN)..."
        $NewList = New-WinUserLanguageList vi-VN
        Set-WinUserLanguageList $NewList -Force
    }

    "3" {
        Ghi-Log "-> Đang thực hiện: GIỮ TIẾNG VIỆT (Ưu tiên) + TIẾNG ANH..."
        $NewList = New-WinUserLanguageList vi-VN
        $NewList.Add("en-US")
        Set-WinUserLanguageList $NewList -Force
    }

    "0" { 
        Ghi-Log "!!! Đã hủy quy trình. Không có thay đổi nào được thực hiện."
        return 
    }

    default { return }
}

# 4. Kiểm tra lại sau khi xóa
[System.Windows.Forms.Application]::DoEvents()
$FinalList = Get-WinUserLanguageList
Ghi-Log "-> DANH SÁCH MỚI: $(($FinalList.LanguageTag) -join ' | ')"
Ghi-Log ">>> HOÀN TẤT DỌN DẸP."

[System.Windows.Forms.MessageBox]::Show("Đã cập nhật layout bàn phím thành công!", "Thông báo")