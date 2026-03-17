[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- KIỂM TRA QUYỀN ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Phải dùng Admin mới 'ép' được menu khởi động ông Tuấn nhé!", "VietToolbox")
    return
}

$F7Manager = {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DRIVER SIGNATURE FIX - VIETTOOLBOX"; $form.Size = "500,350"; $form.BackColor = "#1E1E1E"; $form.StartPosition = "CenterScreen"
    
    $fNut = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fChu = New-Object System.Drawing.Font("Segoe UI", 9)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "ÉP HIỆN MENU KHỞI ĐỘNG (F7)"; $lbl.ForeColor = "#F1C40F"; $lbl.Font = $fNut
    $lbl.Size = "450,30"; $lbl.Location = "20,20"; $lbl.TextAlign = "MiddleCenter"

    # --- NÚT 1: ÉP HIỆN MENU F1-F9 KHI RESTART ---
    $btnForce = New-Object System.Windows.Forms.Button
    $btnForce.Text = "❌ ÉP HIỆN MENU F7 KHI RESTART"; $btnForce.Location = "50,70"; $btnForce.Size = "380,70"
    $btnForce.BackColor = "#C0392B"; $btnForce.ForeColor = "White"; $btnForce.FlatStyle = "Flat"; $btnForce.Font = $fNut
    $btnForce.Add_Click({
        try {
            # Lệnh này ép Windows hiện bảng Advanced Options (F1-F9) mỗi khi boot
            bcdedit /set "{globalsettings}" advancedoptions true
            $cf = [System.Windows.Forms.MessageBox]::Show("Đã thiết lập! Máy sẽ Restart. Khi hiện bảng xanh, ông hãy nhấn phím 7 hoặc F7. Restart ngay?", "Xác nhận", 4, 32)
            if ($cf -eq "Yes") { shutdown /r /t 0 /f }
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: $($_.Exception.Message)") }
    })

    # --- NÚT 2: TRẢ VỀ BÌNH THƯỜNG ---
    $btnNormal = New-Object System.Windows.Forms.Button
    $btnNormal.Text = "✅ TẮT MENU (TRẢ VỀ MẶC ĐỊNH)"; $btnNormal.Location = "50,160"; $btnNormal.Size = "380,60"
    $btnNormal.BackColor = "#27AE60"; $btnNormal.ForeColor = "White"; $btnNormal.FlatStyle = "Flat"; $btnNormal.Font = $fNut
    $btnNormal.Add_Click({
        try {
            # Xóa lệnh ép hiện bảng Advanced Options
            bcdedit /deletevalue "{globalsettings}" advancedoptions
            [System.Windows.Forms.MessageBox]::Show("Đã trả về chế độ khởi động bình thường!", "VietToolbox")
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: $($_.Exception.Message)") }
    })

    $lblNote = New-Object System.Windows.Forms.Label
    $lblNote.Text = "Lưu ý: Sau khi cài xong Driver, ông nhớ bấm 'TẮT MENU' để máy khách không hiện cái bảng xanh đó nữa nhé."; $lblNote.ForeColor = "#888"
    $lblNote.Size = "450,60"; $lblNote.Location = "20,240"; $lblNote.TextAlign = "MiddleCenter"; $lblNote.Font = $fChu

    $form.Controls.AddRange(@($lbl, $btnForce, $btnNormal, $lblNote))
    $form.ShowDialog() | Out-Null
}

&$F7Manager