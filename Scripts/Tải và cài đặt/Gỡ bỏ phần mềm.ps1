# ==========================================================
# TOOL GỠ PHẦN MỀM TẬN GỐC - BẢN FIX CÚ PHÁP (ULTRAVIEWER + REVO)
# ==========================================================
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$CSharpCode = @"
using System;
using System.Collections;
using System.Windows.Forms;

public class ListViewSorter : IComparer {
    public int Column = 0;
    public SortOrder Order = SortOrder.Ascending;
    public int Compare(object x, object y) {
        if (!(x is ListViewItem) || !(y is ListViewItem)) return 0;
        ListViewItem itemX = (ListViewItem)x;
        ListViewItem itemY = (ListViewItem)y;
        string strX = itemX.SubItems.Count > Column ? itemX.SubItems[Column].Text : "";
        string strY = itemY.SubItems.Count > Column ? itemY.SubItems[Column].Text : "";
        int result = String.Compare(strX, strY);
        if (Order == SortOrder.Descending) return -result;
        return result;
    }
}
"@
if (-not ("ListViewSorter" -as [type])) { Add-Type -TypeDefinition $CSharpCode -ReferencedAssemblies "System.Windows.Forms", "System" }

$fBold = New-Object System.Drawing.Font("Segoe UI Bold", 9)
$fStd = New-Object System.Drawing.Font("Segoe UI", 9)

$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX - GỠ PHẦN MỀM TẬN GỐC (BẢN HOÀN HẢO)"; $form.Size = "820,620"; $form.StartPosition = "CenterScreen"; $form.BackColor = "White"

$imgList = New-Object System.Windows.Forms.ImageList
$imgList.ImageSize = New-Object System.Drawing.Size(20, 20)
$imgList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

try {
    $defaultIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:windir\explorer.exe")
    $imgList.Images.Add("default", $defaultIcon)
} catch {}

$lv = New-Object System.Windows.Forms.ListView; $lv.Size = "760,350"; $lv.Location = "20,20"; $lv.View = "Details"; $lv.FullRowSelect = $true; $lv.GridLines = $true; $lv.Font = $fStd
$lv.SmallImageList = $imgList
[void]$lv.Columns.Add("TÊN PHẦN MỀM", 350)
[void]$lv.Columns.Add("PHIÊN BẢN", 100)
[void]$lv.Columns.Add("NHÀ PHÁT HÀNH", 170)
[void]$lv.Columns.Add("DUNG LƯỢNG", 90)
$form.Controls.Add($lv)

$lv.ListViewItemSorter = New-Object ListViewSorter
$lv.Add_ColumnClick({
    param($sender, $e)
    if ($sender.ListViewItemSorter.Column -eq $e.Column) {
        $sender.ListViewItemSorter.Order = if ($sender.ListViewItemSorter.Order -eq 'Ascending') { 'Descending' } else { 'Ascending' }
    } else {
        $sender.ListViewItemSorter.Column = $e.Column; $sender.ListViewItemSorter.Order = 'Ascending'
    }
    $sender.Sort()
})

$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Đang quét phần mềm..."; $lblStatus.Location = "20,385"; $lblStatus.Size = "760,20"; $lblStatus.ForeColor = "DarkBlue"
$form.Controls.Add($lblStatus)

$btnReload = New-Object System.Windows.Forms.Button; $btnReload.Text = "LÀM MỚI"; $btnReload.Location = "20,420"; $btnReload.Size = "150,45"; $btnReload.FlatStyle = "Flat"
$btnUninstall = New-Object System.Windows.Forms.Button; $btnUninstall.Text = "GỠ BỎ TẬN GỐC"; $btnUninstall.Location = "180,420"; $btnUninstall.Size = "600,45"; $btnUninstall.BackColor = "#C62828"; $btnUninstall.ForeColor = "White"; $btnUninstall.Font = $fBold; $btnUninstall.FlatStyle = "Flat"
$form.Controls.AddRange(@($btnReload, $btnUninstall))

# --- [1] LOGIC QUÉT PHẦN MỀM (.NET ENGINE - CHỐNG MẤT ULTRAVIEWER) ---
function Get-InstalledApps {
    $lv.Items.Clear()
    $lblStatus.Text = "Đang đồng bộ danh sách bằng .NET Engine..."
    $lblStatus.ForeColor = "Blue"; [System.Windows.Forms.Application]::DoEvents()

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", 
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall", 
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $subKeys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
            foreach ($key in $subKeys) {
                $name = $key.GetValue("DisplayName")
                if ([string]::IsNullOrWhiteSpace($name)) { continue }
                
                $sysComp = $key.GetValue("SystemComponent")
                if ($sysComp -eq 1) { continue }
                
                $parent = $key.GetValue("ParentKeyName")
                if (-not [string]::IsNullOrWhiteSpace($parent)) { continue }
                if ($name -match "(?i)KB\d{6,}") { continue }

                try {
                    $ver = $key.GetValue("DisplayVersion")
                    $pub = $key.GetValue("Publisher")
                    
                    $uninst = $key.GetValue("UninstallString")
                    if ([string]::IsNullOrWhiteSpace($uninst)) { $uninst = $key.GetValue("QuietUninstallString") }

                    $sizeStr = "N/A"
                    $estSize = $key.GetValue("EstimatedSize")
                    if ($estSize -ne $null -and $estSize -match '^\d+$') {
                        $sizeMB = [math]::Round($estSize / 1024, 2)
                        $sizeStr = if ($sizeMB -ge 1024) { "$([math]::Round($sizeMB / 1024, 2)) GB" } else { "$sizeMB MB" }
                    }

                    $iconKey = "default"
                    $targetPath = ""
                    $dispIcon = $key.GetValue("DisplayIcon")
                    if (-not [string]::IsNullOrWhiteSpace($dispIcon)) {
                        $targetPath = $dispIcon.ToString().Trim() -replace '"', '' -replace ',\s*-?\d+$', ''
                        $targetPath = [System.Environment]::ExpandEnvironmentVariables($targetPath)
                    }
                    if (-not (Test-Path -LiteralPath "$targetPath" -ErrorAction SilentlyContinue) -and -not [string]::IsNullOrWhiteSpace($uninst)) {
                        if (($uninst.ToString().Trim() -replace '"', '') -match '^(.*?\.exe)') { $targetPath = [System.Environment]::ExpandEnvironmentVariables($matches[1]) }
                    }

                    if (Test-Path -LiteralPath "$targetPath" -ErrorAction SilentlyContinue) {
                        try {
                            $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($targetPath)
                            if ($null -ne $icon) { $iconKey = [Guid]::NewGuid().ToString(); $imgList.Images.Add($iconKey, $icon) }
                        } catch {}
                    }

                    $lvItem = New-Object System.Windows.Forms.ListViewItem($name)
                    $lvItem.ImageKey = $iconKey
                    
                    # Đã fix lại cú pháp cho PowerShell dễ hiểu
                    $strVer = if ([string]::IsNullOrWhiteSpace($ver)) { "N/A" } else { [string]$ver }
                    $strPub = if ([string]::IsNullOrWhiteSpace($pub)) { "N/A" } else { [string]$pub }
                    
                    [void]$lvItem.SubItems.Add($strVer)
                    [void]$lvItem.SubItems.Add($strPub)
                    [void]$lvItem.SubItems.Add($sizeStr)
                    
                    $lvItem.Tag = @{ UninstallString = $uninst; Name = $name; IsUWP = $false }
                    $lv.Items.Add($lvItem)
                } catch {}
            }
        }
    }

    # 2. QUÉT ỨNG DỤNG UWP (STORE APPS)
    [System.Windows.Forms.Application]::DoEvents()
    $uwpApps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.IsFramework -eq $false -and $_.NonRemovable -eq $false }
    foreach ($app in $uwpApps) {
        try {
            $name = $app.Name; $ver = $app.Version; $pkgFullName = $app.PackageFullName
            $pub = if ($app.Publisher) { ($app.Publisher -split ',')[0] -replace 'CN=', '' } else { "Microsoft/Store" }
            
            $lvItem = New-Object System.Windows.Forms.ListViewItem("$name (Store App)")
            $lvItem.ImageKey = "default" 
            [void]$lvItem.SubItems.Add($ver); [void]$lvItem.SubItems.Add($pub); [void]$lvItem.SubItems.Add("N/A")
            
            $lvItem.Tag = @{ UninstallString = $pkgFullName; Name = $name; IsUWP = $true }
            $lv.Items.Add($lvItem)
        } catch {}
    }
    
    $lv.ListViewItemSorter.Column = 0
    $lv.ListViewItemSorter.Order = 'Ascending'
    $lv.Sort()

    $lblStatus.Text = "✅ Đã tải xong $($lv.Items.Count) phần mềm."
    $lblStatus.ForeColor = "DarkGreen"
}

# --- [2] LOGIC GỠ CÀI ĐẶT (CƠ CHẾ REVO UNINSTALLER) ---
$btnUninstall.Add_Click({
    if ($lv.SelectedItems.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn 1 phần mềm để gỡ!"); return }
    $app = $lv.SelectedItems[0].Tag; $appName = $app.Name
    
    if ([System.Windows.Forms.MessageBox]::Show("Khởi động trình gỡ cài đặt cho '$appName'?", "Xác nhận gỡ", "YesNo", "Question") -eq "No") { return }

    $lblStatus.Text = "Đang chờ trình gỡ cài đặt hoàn tất..."; $lblStatus.ForeColor = "DarkOrange"; [System.Windows.Forms.Application]::DoEvents()
    
    # BƯỚC 1: CHẠY TRÌNH GỠ GỐC VÀ CHỜ
    if ($app.IsUWP) {
        try { Remove-AppxPackage -Package $app.UninstallString -AllUsers -ErrorAction Stop } catch {}
    } else {
        if (-not [string]::IsNullOrWhiteSpace($app.UninstallString)) {
            $uninst = $app.UninstallString -replace "msiexec.exe /I", "msiexec.exe /X"
            try { 
                # Chờ trình gỡ chạy xong
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninst`"" -Wait -WindowStyle Hidden
            } catch {}
        }
    }

    # BƯỚC 2: HỎI Ý KIẾN CÓ DỌN RÁC KHÔNG
    $msg = "Trình gỡ cài đặt gốc đã chạy xong (hoặc đã bị bạn huỷ bỏ).`n`nBạn có muốn thực hiện QUÉT VÀ XOÁ RÁC (thư mục, registry) của phần mềm '$appName' không?`n`n👉 Chọn 'Yes' nếu phần mềm đã gỡ xong.`n👉 Chọn 'No' nếu bạn vừa huỷ việc gỡ cài đặt."
    $cleanup = [System.Windows.Forms.MessageBox]::Show($msg, "Dọn dẹp tàn dư (Revo Cleaner)", "YesNo", "Warning")

    if ($cleanup -eq "Yes") {
        $lblStatus.Text = "Đang quét và tiêu diệt rác..."; [System.Windows.Forms.Application]::DoEvents()
        
        # Xoá Thư mục
        $trashPaths = @("$env:ProgramFiles\$appName", "${env:ProgramFiles(x86)}\$appName", "$env:AppData\$appName", "$env:LocalAppData\$appName")
        foreach ($p in $trashPaths) { if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } }

        # Xoá Registry
        $regPaths = @("HKLM:\SOFTWARE", "HKCU:\Software", "HKLM:\SOFTWARE\WOW6432Node")
        foreach ($reg in $regPaths) {
            $subKey = Get-ChildItem -Path $reg -ErrorAction SilentlyContinue | Where-Object { $_.Name -match [regex]::Escape($appName) }
            if ($subKey) { $subKey | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
        }
        [System.Windows.Forms.MessageBox]::Show("Đã xoá sạch phần mềm và rác của '$appName'!", "Hoàn tất")
    } else {
        [System.Windows.Forms.MessageBox]::Show("Đã bỏ qua bước dọn rác do người dùng chọn huỷ.", "Thông báo")
    }

    Get-InstalledApps
})

$btnReload.Add_Click({ Get-InstalledApps })
$form.Add_Shown({ Get-InstalledApps })
$form.ShowDialog() | Out-Null