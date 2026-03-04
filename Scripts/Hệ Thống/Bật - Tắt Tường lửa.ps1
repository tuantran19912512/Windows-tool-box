Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic
$LuaChon = [Microsoft.VisualBasic.Interaction]::MsgBox(
    "Bạn muốn thực hiện thao tác nào với Tường lửa?`n`n" +
    "[YES]: BẬT Tường lửa (Khuyên dùng)`n" +
    "[NO]: TẮT Tường lửa (Để chia sẻ file/máy in)`n" +
    "[CANCEL]: Thoát", 
    "YesNoCancel,Question", "QUẢN LÝ FIREWALL"
)

if ($LuaChon -eq "Yes") {
    Ghi-Log ">>> ĐANG KÍCH HOẠT TƯỜNG LỬA..."
    $kq = netsh advfirewall set allprofiles state on 2>&1 | Out-String
    Ghi-Log "   [Kết quả]: $($kq.Trim())"
    Ghi-Log ">>> TƯỜNG LỬA ĐÃ BẬT."
    [System.Windows.Forms.MessageBox]::Show("Tường lửa đã được BẬT!", "Thông báo")
} 
elseif ($LuaChon -eq "No") {
    Ghi-Log ">>> ĐANG TẮT TƯỜNG LỬA..."
    $kq = netsh advfirewall set allprofiles state off 2>&1 | Out-String
    Ghi-Log "   [Kết quả]: $($kq.Trim())"
    Ghi-Log ">>> TƯỜNG LỬA ĐÃ TẮT (CẢNH BÁO BẢO MẬT)."
    [System.Windows.Forms.MessageBox]::Show("Tường lửa đã được TẮT!", "Cảnh báo", 0, 48)
}