# ==========================================================
# ADMIN TOOL V113 - FULL CHỨC NĂNG (LOAD, THÊM, SỬA, XÓA, PUSH)
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
$fBtn = New-Object System.Drawing.Font("Segoe UI Bold", 10)
$fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 10)

$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX - QUẢN LÝ ISO CLOUD (V113)"; $form.Size = "850,700"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"

# --- LISTVIEW ---
$lvISO = New-Object System.Windows.Forms.ListView
$lvISO.Size = "790,300"; $lvISO.Location = "20,20"; $lvISO.View = "Details"; $lvISO.FullRowSelect = $true; $lvISO.GridLines = $true; $lvISO.Font = $fStd
[void]$lvISO.Columns.Add("TÊN PHIÊN BẢN WINDOWS", 450); [void]$lvISO.Columns.Add("FILE ID GOOGLE DRIVE", 320)
$form.Controls.Add($lvISO)

# --- KHU VỰC NHẬP LIỆU ---
$lblWin = New-Object System.Windows.Forms.Label
$lblWin.Text = "Tên bản Win:"; $lblWin.Location = "20,345"; $lblWin.Size = "120,25"; $lblWin.Font = $fBtn
$txtWin = New-Object System.Windows.Forms.TextBox; $txtWin.Location = "140,343"; $txtWin.Size = "300,30"; $txtWin.Font = $fStd

$lblID = New-Object System.Windows.Forms.Label
$lblID.Text = "File ID Drive:"; $lblID.Location = "20,385"; $lblID.Size = "120,25"; $lblID.Font = $fBtn
$txtID = New-Object System.Windows.Forms.TextBox; $txtID.Location = "140,383"; $txtID.Size = "300,30"; $txtID.Font = $fStd

$form.Controls.AddRange(@($lblWin, $txtWin, $lblID, $txtID))

# --- CÁC NÚT BẤM (ĐÃ CHIA LẠI SIZE CHO 3 NÚT) ---
$btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM MỚI"; $btnAdd.Location = "460,340"; $btnAdd.Size = "110,75"; $btnAdd.BackColor = "#E8F5E9"; $btnAdd.FlatStyle = "Flat"; $btnAdd.Font = $fBtn
$btnEdit = New-Object System.Windows.Forms.Button; $btnEdit.Text = "CẬP NHẬT"; $btnEdit.Location = "580,340"; $btnEdit.Size = "110,75"; $btnEdit.BackColor = "#FFF9C4"; $btnEdit.FlatStyle = "Flat"; $btnEdit.Font = $fBtn
$btnDelete = New-Object System.Windows.Forms.Button; $btnDelete.Text = "XÓA DÒNG"; $btnDelete.Location = "700,340"; $btnDelete.Size = "110,75"; $btnDelete.BackColor = "#FFEBEE"; $btnDelete.FlatStyle = "Flat"; $btnDelete.Font = $fBtn

$btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "ĐẨY DANH SÁCH LÊN GITHUB (CLOUD)"; $btnPush.Location = "20,530"; $btnPush.Size = "790,80"; $btnPush.BackColor = "#007ACC"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fTitle

$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,620"; $lblStatus.Size = "790,25"; $lblStatus.Font = $fStd

$form.Controls.AddRange(@($btnAdd, $btnEdit, $btnDelete, $btnPush, $lblStatus))

# ==========================================================
# 3. LOGIC XỬ LÝ
# ==========================================================

# --- [A] TẢI DỮ LIỆU KHI VỪA MỞ TOOL ---
$form.Add_Shown({
    $lblStatus.Text = "Đang tải danh sách hiện tại từ GitHub..."
    $lblStatus.ForeColor = "Blue"
    [System.Windows.Forms.Application]::DoEvents()

    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    try {
        # Dùng t=thời_gian để chống cache của GitHub
        $csvData = Invoke-RestMethod -Uri ($RawUrl + "?t=" + (Get-Date -UFormat %s)) -Method Get -UseBasicParsing
        $csv = $csvData | ConvertFrom-Csv
        
        $lvISO.Items.Clear()
        foreach ($row in $csv) {
            if ($row.Name -and $row.FileID) {
                $item = New-Object System.Windows.Forms.ListViewItem($row.Name)
                [void]$item.SubItems.Add($row.FileID)
                $lvISO.Items.Add($item)
            }
        }
        $lblStatus.Text = "✅ Đã tải xong $($lvISO.Items.Count) bản Windows từ Cloud!"
        $lblStatus.ForeColor = "DarkGreen"
    } catch {
        $lblStatus.Text = "⚠️ Chưa có dữ liệu trên Cloud hoặc lỗi mạng. Vui lòng thêm mới!"
        $lblStatus.ForeColor = "DarkOrange"
    }
})

# --- [B] CLICK VÀO DÒNG -> ĐẨY CHỮ LÊN Ô NHẬP ---
$lvISO.Add_SelectedIndexChanged({
    if ($lvISO.SelectedItems.Count -eq 1) {
        $txtWin.Text = $lvISO.SelectedItems[0].Text
        $txtID.Text = $lvISO.SelectedItems[0].SubItems[1].Text
    }
})

# --- [C] NÚT THÊM MỚI ---
$btnAdd.Add_Click({
    if ($txtWin.Text -and $txtID.Text) {
        $item = New-Object System.Windows.Forms.ListViewItem($txtWin.Text); [void]$item.SubItems.Add($txtID.Text); $lvISO.Items.Add($item)
        $txtWin.Clear(); $txtID.Clear(); $txtWin.Focus()
        $lblStatus.Text = "Đã thêm dòng mới vào bảng (Chưa lưu lên Cloud)."
        $lblStatus.ForeColor = "Black"
    } else {
        $lblStatus.Text = "❌ Vui lòng nhập đủ Tên và ID!"
        $lblStatus.ForeColor = "Red"
    }
})

# --- [D] NÚT CẬP NHẬT ---
$btnEdit.Add_Click({
    if ($lvISO.SelectedItems.Count -eq 1) {
        if ($txtWin.Text -and $txtID.Text) {
            $lvISO.SelectedItems[0].Text = $txtWin.Text
            $lvISO.SelectedItems[0].SubItems[1].Text = $txtID.Text
            $lblStatus.Text = "Đã cập nhật dòng thành công! Nhớ bấm Đẩy Lên Cloud để lưu thật."
            $lblStatus.ForeColor = "DarkGreen"
        } else {
            $lblStatus.Text = "❌ Vui lòng nhập đủ Tên và ID để cập nhật!"
            $lblStatus.ForeColor = "Red"
        }
    } else {
        $lblStatus.Text = "⚠️ Vui lòng chọn 1 dòng trong bảng trước khi bấm Cập Nhật!"
        $lblStatus.ForeColor = "DarkOrange"
    }
})

# --- [E] NÚT XÓA ---
$btnDelete.Add_Click({ 
    foreach ($s in $lvISO.SelectedItems) { $lvISO.Items.Remove($s) } 
    $txtWin.Clear(); $txtID.Clear()
    $lblStatus.Text = "Đã xóa dòng chọn."
    $lblStatus.ForeColor = "Black"
})

# --- [F] NÚT ĐẨY LÊN GITHUB ---
$btnPush.Add_Click({
    if ($lvISO.Items.Count -eq 0) { return }
    $btnPush.Enabled = $false; $lblStatus.Text = "Đang đẩy dữ liệu lên GitHub..."; $lblStatus.ForeColor = "Blue"
    
    $csvData = "Name,FileID`r`n"
    foreach ($row in $lvISO.Items) { $csvData += "$($row.Text),$($row.SubItems[1].Text)`r`n" }

    try {
        $Client = New-Object System.Net.Http.HttpClient
        $Client.DefaultRequestHeaders.Add("Authorization", "token $($Global:GH_TOKEN)")
        $Client.DefaultRequestHeaders.Add("User-Agent", "VietToolbox")
        
        $Url = "https://api.github.com/repos/tuantran19912512/Windows-tool-box/contents/iso_list.csv"
        
        $SHA = $null
        $GetRes = $Client.GetAsync($Url).Result
        if ($GetRes.IsSuccessStatusCode) {
            $SHA = ($GetRes.Content.ReadAsStringAsync().Result | ConvertFrom-Json).sha
        }

        $Base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csvData))
        $Body = @{ message = "Update ISO Cloud List"; content = $Base64; sha = $SHA } | ConvertTo-Json
        $Content = New-Object System.Net.Http.StringContent($Body, [System.Text.Encoding]::UTF8, "application/json")

        $PutRes = $Client.PutAsync($Url, $Content).Result
        if ($PutRes.IsSuccessStatusCode) {
            $lblStatus.Text = "✅ ĐÃ LƯU LÊN CLOUD THÀNH CÔNG!"; $lblStatus.ForeColor = "DarkGreen"
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật danh sách thành công lên GitHub!", "Thành công")
        } else {
            $lblStatus.Text = "❌ Lỗi GitHub: $($PutRes.StatusCode)"; $lblStatus.ForeColor = "Red"
        }
    } catch {
        $lblStatus.Text = "❌ Lỗi kết nối mạng!"; $lblStatus.ForeColor = "Red"
    } finally {
        if ($Client) { $Client.Dispose() }
        $btnPush.Enabled = $true
    }
})

$form.ShowDialog() | Out-Null