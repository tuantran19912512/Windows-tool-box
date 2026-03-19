# ==========================================================
# ADMIN TOOL V114 - FULL CHỨC NĂNG + NÚT XOÁ SẠCH BẢNG
# ==========================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -AssemblyName System.Net.Http

# 1. KIỂM TRA TOKEN GITHUB
if (-not $Global:GH_TOKEN) {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $Global:GH_TOKEN = [Microsoft.VisualBasic.Interaction]::InputBox("Vui lòng nhập GitHub Token:", "Xác thực Cloud", "")
}
if (-not $Global:GH_TOKEN) { exit }

# 2. KHỞI TẠO FORM & FONT
$fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 12)
$fBtn = New-Object System.Drawing.Font("Segoe UI Bold", 9)
$fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 10)

$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX - QUẢN LÝ ISO CLOUD (V114)"; $form.Size = "850,700"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"

# --- LISTVIEW ---
$lvISO = New-Object System.Windows.Forms.ListView
$lvISO.Size = "790,300"; $lvISO.Location = "20,20"; $lvISO.View = "Details"; $lvISO.FullRowSelect = $true; $lvISO.GridLines = $true; $lvISO.Font = $fStd
[void]$lvISO.Columns.Add("TÊN PHIÊN BẢN WINDOWS", 400); [void]$lvISO.Columns.Add("LINK TẢI (DRIVE/ONEDRIVE/GITHUB)", 370)
$form.Controls.Add($lvISO)

# --- KHU VỰC NHẬP LIỆU ---
$lblWin = New-Object System.Windows.Forms.Label
$lblWin.Text = "Tên bản Win:"; $lblWin.Location = "20,345"; $lblWin.Size = "120,25"; $lblWin.Font = $fBtn
$txtWin = New-Object System.Windows.Forms.TextBox; $txtWin.Location = "140,343"; $txtWin.Size = "300,30"; $txtWin.Font = $fStd

$lblID = New-Object System.Windows.Forms.Label
$lblID.Text = "Link Tải:"; $lblID.Location = "20,385"; $lblID.Size = "120,25"; $lblID.Font = $fBtn
$txtID = New-Object System.Windows.Forms.TextBox; $txtID.Location = "140,383"; $txtID.Size = "300,30"; $txtID.Font = $fStd

$form.Controls.AddRange(@($lblWin, $txtWin, $lblID, $txtID))

# --- CÁC NÚT BẤM (CHIA LẠI CHO 4 NÚT THÀNH 1 HÀNG) ---
$btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM MỚI"; $btnAdd.Location = "460,340"; $btnAdd.Size = "80,75"; $btnAdd.BackColor = "#E8F5E9"; $btnAdd.FlatStyle = "Flat"; $btnAdd.Font = $fBtn
$btnEdit = New-Object System.Windows.Forms.Button; $btnEdit.Text = "CẬP NHẬT"; $btnEdit.Location = "550,340"; $btnEdit.Size = "80,75"; $btnEdit.BackColor = "#FFF9C4"; $btnEdit.FlatStyle = "Flat"; $btnEdit.Font = $fBtn
$btnDelete = New-Object System.Windows.Forms.Button; $btnDelete.Text = "XÓA DÒNG"; $btnDelete.Location = "640,340"; $btnDelete.Size = "80,75"; $btnDelete.BackColor = "#FFEBEE"; $btnDelete.FlatStyle = "Flat"; $btnDelete.Font = $fBtn
$btnClearAll = New-Object System.Windows.Forms.Button; $btnClearAll.Text = "XOÁ SẠCH"; $btnClearAll.Location = "730,340"; $btnClearAll.Size = "80,75"; $btnClearAll.BackColor = "#B71C1C"; $btnClearAll.ForeColor = "White"; $btnClearAll.FlatStyle = "Flat"; $btnClearAll.Font = $fBtn

$btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "ĐẨY DANH SÁCH LÊN GITHUB (CLOUD)"; $btnPush.Location = "20,530"; $btnPush.Size = "790,80"; $btnPush.BackColor = "#007ACC"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fTitle

$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,620"; $lblStatus.Size = "790,25"; $lblStatus.Font = $fStd

$form.Controls.AddRange(@($btnAdd, $btnEdit, $btnDelete, $btnClearAll, $btnPush, $lblStatus))

# ==========================================================
# LOGIC XỬ LÝ
# ==========================================================

# --- [A] TẢI DỮ LIỆU ---
$form.Add_Shown({
    $lblStatus.Text = "Đang tải danh sách hiện tại từ GitHub..."
    $lblStatus.ForeColor = "Blue"; [System.Windows.Forms.Application]::DoEvents()
    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    try {
        $csvData = Invoke-RestMethod -Uri ($RawUrl + "?t=" + (Get-Date -UFormat %s)) -Method Get -UseBasicParsing
        $csv = $csvData | ConvertFrom-Csv
        $lvISO.Items.Clear()
        foreach ($row in $csv) {
            if ($row.Name -and $row.FileID) {
                $item = New-Object System.Windows.Forms.ListViewItem($row.Name)
                [void]$item.SubItems.Add($row.FileID); $lvISO.Items.Add($item)
            }
        }
        $lblStatus.Text = "✅ Đã tải xong $($lvISO.Items.Count) bản Windows từ Cloud!"; $lblStatus.ForeColor = "DarkGreen"
    } catch { $lblStatus.Text = "⚠️ Lỗi tải Cloud hoặc chưa có dữ liệu."; $lblStatus.ForeColor = "DarkOrange" }
})

# --- [B] CLICK CHỌN DÒNG ---
$lvISO.Add_SelectedIndexChanged({
    if ($lvISO.SelectedItems.Count -eq 1) {
        $txtWin.Text = $lvISO.SelectedItems[0].Text
        $txtID.Text = $lvISO.SelectedItems[0].SubItems[1].Text
    }
})

# --- [C] THÊM ---
$btnAdd.Add_Click({
    if ($txtWin.Text -and $txtID.Text) {
        $item = New-Object System.Windows.Forms.ListViewItem($txtWin.Text); [void]$item.SubItems.Add($txtID.Text); $lvISO.Items.Add($item)
        $txtWin.Clear(); $txtID.Clear(); $txtWin.Focus()
        $lblStatus.Text = "Đã thêm dòng mới."; $lblStatus.ForeColor = "Black"
    }
})

# --- [D] CẬP NHẬT ---
$btnEdit.Add_Click({
    if ($lvISO.SelectedItems.Count -eq 1 -and $txtWin.Text -and $txtID.Text) {
        $lvISO.SelectedItems[0].Text = $txtWin.Text
        $lvISO.SelectedItems[0].SubItems[1].Text = $txtID.Text
        $lblStatus.Text = "Đã cập nhật dòng chọn."; $lblStatus.ForeColor = "DarkGreen"
    }
})

# --- [E] XOÁ DÒNG ĐÃ CHỌN ---
$btnDelete.Add_Click({ foreach ($s in $lvISO.SelectedItems) { $lvISO.Items.Remove($s) }; $txtWin.Clear(); $txtID.Clear() })

# --- [X] NÚT XOÁ SẠCH BẢNG (MỚI THÊM) ---
$btnClearAll.Add_Click({
    $res = [System.Windows.Forms.MessageBox]::Show("Bạn có chắc chắn muốn XOÁ SẠCH tất cả danh sách không?", "Cảnh báo", "YesNo", "Warning")
    if ($res -eq "Yes") {
        $lvISO.Items.Clear()
        $txtWin.Clear(); $txtID.Clear()
        $lblStatus.Text = "Đã xoá sạch bảng! Hãy bấm Đẩy Lên Cloud để lưu thay đổi."; $lblStatus.ForeColor = "Red"
    }
})

# --- [F] ĐẨY LÊN GITHUB ---
$btnPush.Add_Click({
    $btnPush.Enabled = $false; $lblStatus.Text = "Đang đẩy dữ liệu lên GitHub..."; $lblStatus.ForeColor = "Blue"
    $csvData = "Name,FileID`r`n"
    foreach ($row in $lvISO.Items) { $csvData += "$($row.Text),$($row.SubItems[1].Text)`r`n" }
    try {
        $Client = New-Object System.Net.Http.HttpClient
        $Client.DefaultRequestHeaders.Add("Authorization", "token $($Global:GH_TOKEN)")
        $Client.DefaultRequestHeaders.Add("User-Agent", "VietToolbox")
        $Url = "https://api.github.com/repos/tuantran19912512/Windows-tool-box/contents/iso_list.csv"
        $SHA = $null; $GetRes = $Client.GetAsync($Url).Result
        if ($GetRes.IsSuccessStatusCode) { $SHA = ($GetRes.Content.ReadAsStringAsync().Result | ConvertFrom-Json).sha }
        $Base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csvData))
        $Body = @{ message = "Admin Update Cloud List"; content = $Base64; sha = $SHA } | ConvertTo-Json
        $Content = New-Object System.Net.Http.StringContent($Body, [System.Text.Encoding]::UTF8, "application/json")
        $PutRes = $Client.PutAsync($Url, $Content).Result
        if ($PutRes.IsSuccessStatusCode) {
            $lblStatus.Text = "✅ ĐÃ LƯU LÊN CLOUD THÀNH CÔNG!"; $lblStatus.ForeColor = "DarkGreen"
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật thành công lên GitHub!", "Thành công")
        } else { $lblStatus.Text = "❌ Lỗi: $($PutRes.StatusCode)"; $lblStatus.ForeColor = "Red" }
    } catch { $lblStatus.Text = "❌ Lỗi kết nối mạng!"; $lblStatus.ForeColor = "Red"
    } finally { if ($Client) { $Client.Dispose() }; $btnPush.Enabled = $true }
})

$form.ShowDialog() | Out-Null