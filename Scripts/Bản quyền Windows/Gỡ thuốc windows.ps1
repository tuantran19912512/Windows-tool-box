Add-Type -AssemblyName System.Windows.Forms
Ghi-Log "-> Đang gỡ bỏ bản quyền cũ và dọn Registry..."
cscript //nologo $env:windir\system32\slmgr.vbs /upk
cscript //nologo $env:windir\system32\slmgr.vbs /cpky
cscript //nologo $env:windir\system32\slmgr.vbs /rearm
Ghi-Log "   + Đã dọn sạch Key cũ."
[System.Windows.Forms.MessageBox]::Show("Đã gỡ Key thành công. Hãy nạp Key mới hoặc dùng thuốc!", "Thông báo")