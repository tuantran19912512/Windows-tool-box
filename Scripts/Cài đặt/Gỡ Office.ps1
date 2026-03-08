# ==========================================================
# 1. ÉP CHẠY QUYỀN ADMINISTRATOR
# ==========================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. THIẾT LẬP MÔI TRƯỜNG
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicGoOfficeV22 = {
    # --- KHỞI TẠO GIAO DIỆN ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - GỠ OFFICE & DỌN TẬN GỐC V2.2"; $form.Size = "800,650"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lvOffice = New-Object System.Windows.Forms.ListView; $lvOffice.Size = "740,300"; $lvOffice.Location = "20,20"; $lvOffice.View = "Details"; $lvOffice.FullRowSelect = $true; $lvOffice.Font = New-Object System.Drawing.Font("Segoe UI", 10); $lvOffice.BorderStyle = "FixedSingle"; $lvOffice.CheckBoxes = $true
    [void]$lvOffice.Columns.Add("CÁC BẢN OFFICE TRÊN MÁY", 550); [void]$lvOffice.Columns.Add("TRẠNG THÁI", 180)

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,335"; $lblStatus.Size = "740,20"; $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,360"; $pgBar.Size = "740,25"

    # --- NHÓM NÚT CHỨC NĂNG ---
    $btnRefresh = New-Object System.Windows.Forms.Button; $btnRefresh.Text = "LÀM MỚI"; $btnRefresh.Size = "150,60"; $btnRefresh.Location = "20,450"; $btnRefresh.BackColor = "#455A64"; $btnRefresh.ForeColor = "White"; $btnRefresh.FlatStyle = "Flat"
    
    # NÚT DỌN SẠCH (MẶC ĐỊNH BỊ ẨN)
    $btnCleanAll = New-Object System.Windows.Forms.Button; $btnCleanAll.Text = "DỌN SẠCH TẬN GỐC"; $btnCleanAll.Size = "250,60"; $btnCleanAll.Location = "180,450"; $btnCleanAll.BackColor = "#FF8F00"; $btnCleanAll.ForeColor = "White"; $btnCleanAll.FlatStyle = "Flat"; $btnCleanAll.Font = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $btnCleanAll.Visible = $false # <<--- ẨN TỪ ĐẦU NHƯ ÔNG YÊU CẦU

    $btnUninstall = New-Object System.Windows.Forms.Button; $btnUninstall.Text = "BẮT ĐẦU GỠ"; $btnUninstall.Size = "320,60"; $btnUninstall.Location = "440,450"; $btnUninstall.BackColor = "#D32F2F"; $btnUninstall.ForeColor = "White"; $btnUninstall.FlatStyle = "Flat"; $btnUninstall.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11)

    $form.Controls.AddRange(@($lvOffice, $lblStatus, $pgBar, $btnRefresh, $btnCleanAll, $btnUninstall))

    # --- HÀM QUÉT OFFICE ---
    function Get-OfficeList {
        $lvOffice.Items.Clear(); $lblStatus.Text = "Đang quét hệ thống..."; [System.Windows.Forms.Application]::DoEvents()
        $paths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
        $officeApps = Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Microsoft Office*" -and $_.UninstallString -ne $null }
        foreach ($app in $officeApps) {
            $li = New-Object System.Windows.Forms.ListViewItem($app.DisplayName); [void]$li.SubItems.Add("Sẵn sàng gỡ"); $li.Tag = $app.UninstallString; $lvOffice.Items.Add($li)
        }
        $lblStatus.Text = "Tìm thấy $($lvOffice.Items.Count) bản Office."
    }

    # --- HÀM DỌN DẸP TẬN GỐC ---
    $btnCleanAll.Add_Click({
        $msg = "Bạn có muốn xóa sạch Registry và Folder rác của Office?`n(Thao tác này giúp máy sạch 100% để cài bản mới không bị lỗi)"
        if ([System.Windows.Forms.MessageBox]::Show($msg, "Xác nhận dọn dẹp", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning) -ne "Yes") { return }
        
        $btnCleanAll.Enabled = $false; $pgBar.Style = "Marquee"
        
        $regPaths = @("HKLM:\SOFTWARE\Microsoft\Office","HKCU:\Software\Microsoft\Office","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office","HKLM:\SOFTWARE\Microsoft\AppVISV","HKCU:\Software\Microsoft\AppVISV")
        $folderPaths = @("$env:AppData\Microsoft\Office","$env:LocalAppData\Microsoft\Office","C:\Program Files\Microsoft Office","C:\Program Files (x86)\Microsoft Office")

        foreach ($p in $regPaths) { if (Test-Path $p) { $lblStatus.Text = "Xóa Registry: $p"; [System.Windows.Forms.Application]::DoEvents(); Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } }
        foreach ($f in $folderPaths) { if (Test-Path $f) { $lblStatus.Text = "Xóa Folder: $f"; [System.Windows.Forms.Application]::DoEvents(); Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue } }

        $pgBar.Style = "Blocks"; $pgBar.Value = 100
        $lblStatus.Text = "Đã dọn sạch tuyệt đối!"; $btnCleanAll.Enabled = $true
        [System.Windows.Forms.MessageBox]::Show("Đã quét sạch dấu vết Office!")
    })

    # --- SỰ KIỆN GỠ BỎ ---
    $btnUninstall.Add_Click({
        $items = @($lvOffice.CheckedItems)
        if ($items.Count -eq 0) { return }
        $btnUninstall.Enabled = $false
        foreach ($item in $items) {
            $item.SubItems[1].Text = "⏳ Đang gỡ..."; $lblStatus.Text = "Đang gỡ: $($item.Text)"; [System.Windows.Forms.Application]::DoEvents()
            try {
                $cmd = $item.Tag
                if ($cmd -like "MsiExec.exe*") { $silent = ($cmd -replace "/I", "/X") + " /quiet /norestart"; Start-Process cmd.exe -ArgumentList "/c $silent" -Wait }
                else { Start-Process cmd.exe -ArgumentList "/c $cmd" -Wait }
                $item.SubItems[1].Text = "✅ Đã gỡ"
            } catch { $item.SubItems[1].Text = "❌ Lỗi" }
        }
        $btnUninstall.Enabled = $true; $lblStatus.Text = "Hoàn tất gỡ cài đặt!"; $pgBar.Value = 100
        
        # --- QUAN TRỌNG: HIỆN NÚT DỌN SẠCH SAU KHI GỠ XONG ---
        $btnCleanAll.Visible = $true 
        $lblStatus.Text = "Gợi ý: Hãy bấm 'DỌN SẠCH TẬN GỐC' để máy sạch 100%!"
    })

    $btnRefresh.Add_Click({ Get-OfficeList; $btnCleanAll.Visible = $false }) # Làm mới thì ẩn lại
    Get-OfficeList; $form.ShowDialog() | Out-Null
}

&$LogicGoOfficeV22