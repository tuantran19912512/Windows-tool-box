# ==========================================================
# ADMIN TOOL V112 - FIX LỖI HIỂN THỊ TIÊU ĐỀ NHÃN (LABEL)
# ==========================================================
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -AssemblyName System.Net.Http

# 1. KIỂM TRA TOKEN
if (-not $Global:GH_TOKEN) {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $Global:GH_TOKEN = [Microsoft.VisualBasic.Interaction]::InputBox("Vui lòng nhập GitHub Token:", "Xác thực Cloud", "")
}
if (-not $Global:GH_TOKEN) { exit }

# 2. KHỞI TẠO FORM
$fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 12)
$fBtn = New-Object System.Drawing.Font("Segoe UI Bold", 10)
$fStd = New-Object System.Drawing.Font("Segoe UI Semibold", 10)

$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX - QUẢN LÝ ISO CLOUD (V112)"; $form.Size = "850,700"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"

# --- LISTVIEW ---
$lvISO = New-Object System.Windows.Forms.ListView
$lvISO.Size = "790,300"; $lvISO.Location = "20,20"; $lvISO.View = "Details"; $lvISO.FullRowSelect = $true; $lvISO.GridLines = $true; $lvISO.Font = $fStd
[void]$lvISO.Columns.Add("TÊN PHIÊN BẢN WINDOWS", 450); [void]$lvISO.Columns.Add("FILE ID GOOGLE DRIVE", 320)
$form.Controls.Add($lvISO)

# --- NHẬP LIỆU (FIX LẠI ĐOẠN NÀY) ---
$lblWin = New-Object System.Windows.Forms.Label
$lblWin.Text = "Tên bản Win:"; $lblWin.Location = "20,345"; $lblWin.Size = "120,25"; $lblWin.Font = $fBtn
$txtWin = New-Object System.Windows.Forms.TextBox; $txtWin.Location = "140,343"; $txtWin.Size = "300,30"; $txtWin.Font = $fStd

$lblID = New-Object System.Windows.Forms.Label
$lblID.Text = "File ID Drive:"; $lblID.Location = "20,385"; $lblID.Size = "120,25"; $lblID.Font = $fBtn
$txtID = New-Object System.Windows.Forms.TextBox; $txtID.Location = "140,383"; $txtID.Size = "300,30"; $txtID.Font = $fStd

# Đưa tất cả nhãn và ô nhập vào Form
$form.Controls.AddRange(@($lblWin, $txtWin, $lblID, $txtID))

# --- CÁC NÚT BẤM ---
$btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM VÀO BẢNG"; $btnAdd.Location = "460,340"; $btnAdd.Size = "160,75"; $btnAdd.BackColor = "#E8F5E9"; $btnAdd.FlatStyle = "Flat"; $btnAdd.Font = $fBtn
$btnDelete = New-Object System.Windows.Forms.Button; $btnDelete.Text = "XÓA DÒNG CHỌN"; $btnDelete.Location = "640,340"; $btnDelete.Size = "160,75"; $btnDelete.BackColor = "#FFEBEE"; $btnDelete.FlatStyle = "Flat"; $btnDelete.Font = $fBtn
$btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "ĐẨY DANH SÁCH LÊN GITHUB (CLOUD)"; $btnPush.Location = "20,530"; $btnPush.Size = "790,80"; $btnPush.BackColor = "#007ACC"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fTitle
$form.Controls.AddRange(@($btnAdd, $btnDelete, $btnPush))

$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Sẵn sàng..."; $lblStatus.Location = "20,620"; $lblStatus.Size = "790,25"; $lblStatus.Font = $fStd; $form.Controls.Add($lblStatus)

# --- LOGIC ---
$btnAdd.Add_Click({
    if ($txtWin.Text -and $txtID.Text) {
        $item = New-Object System.Windows.Forms.ListViewItem($txtWin.Text); [void]$item.SubItems.Add($txtID.Text); $lvISO.Items.Add($item)
        $txtWin.Clear(); $txtID.Clear(); $txtWin.Focus()
        $lblStatus.Text = "Đã thêm tạm vào bảng."
    }
})

$btnDelete.Add_Click({ foreach ($s in $lvISO.SelectedItems) { $lvISO.Items.Remove($s) } })

$btnPush.Add_Click({
    if ($lvISO.Items.Count -eq 0) { return }
    $btnPush.Enabled = $false; $lblStatus.Text = "Đang đẩy dữ liệu..."; $lblStatus.ForeColor = "Blue"
    
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
        $Body = @{ message = "Update ISO Cloud"; content = $Base64; sha = $SHA } | ConvertTo-Json
        $Content = New-Object System.Net.Http.StringContent($Body, [System.Text.Encoding]::UTF8, "application/json")

        $PutRes = $Client.PutAsync($Url, $Content).Result
        if ($PutRes.IsSuccessStatusCode) {
            $lblStatus.Text = "✅ ĐÃ LƯU LÊN CLOUD!"; $lblStatus.ForeColor = "DarkGreen"
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật danh sách thành công!")
        } else {
            $lblStatus.Text = "❌ Lỗi GitHub: $($PutRes.StatusCode)"; $lblStatus.ForeColor = "Red"
        }
    } catch {
        $lblStatus.Text = "❌ Lỗi kết nối!"; $lblStatus.ForeColor = "Red"
    } finally {
        if ($Client) { $Client.Dispose() }
        $btnPush.Enabled = $true
    }
})
# --- HÀM TẢI DỮ LIỆU TỪ GITHUB KHI VỪA MỞ TOOL ---
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

$form.ShowDialog() | Out-Null