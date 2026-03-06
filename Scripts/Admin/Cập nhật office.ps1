# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicQuanTriOffice = {
    # --- CẤU HÌNH GITHUB MẶC ĐỊNH ---
    $GH_USER = "tuantran19912512"
    $GH_REPO = "Windows-tool-box"
    $GH_FILE = "DanhSachOffice.csv"

    # --- FONT UI CHUẨN ---
    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 9)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 9)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)

    # --- KHỞI TẠO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX ADMIN - QUẢN LÝ BỘ CÀI OFFICE"; $form.Size = "650,650"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    # 1. KHU VỰC NHẬP TOKEN (GIỐNG FILE ADMIN TRƯỚC)
    $gbToken = New-Object System.Windows.Forms.GroupBox; $gbToken.Text = " CẤU HÌNH GITHUB TOKEN "; $gbToken.Size = "590,70"; $gbToken.Location = "20,10"
    $txtToken = New-Object System.Windows.Forms.TextBox; $txtToken.PasswordChar = "*"; $txtToken.Location = "15,25"; $txtToken.Size = "430,25"
    $btnCheck = New-Object System.Windows.Forms.Button; $btnCheck.Text = "KẾT NỐI"; $btnCheck.Location = "460,23"; $btnCheck.Size = "110,30"; $btnCheck.BackColor = "#455A64"; $btnCheck.ForeColor = "White"; $btnCheck.FlatStyle = "Flat"
    $gbToken.Controls.AddRange(@($txtToken, $btnCheck))

    # 2. DANH SÁCH OFFICE HIỆN TẠI
    $lv = New-Object System.Windows.Forms.ListView; $lv.Size = "590,250"; $lv.Location = "20,90"; $lv.View = "Details"; $lv.FullRowSelect = $true; $lv.GridLines = $true; $lv.Font = $fontNoiDung
    [void]$lv.Columns.Add("TÊN PHIÊN BẢN OFFICE", 280); [void]$lv.Columns.Add("GOOGLE DRIVE ID", 280)

    # 3. KHU VỰC THÊM MỚI
    $gbAdd = New-Object System.Windows.Forms.GroupBox; $gbAdd.Text = " THÊM PHIÊN BẢN MỚI "; $gbAdd.Size = "590,130"; $gbAdd.Location = "20,350"
    $lblName = New-Object System.Windows.Forms.Label; $lblName.Text = "Tên phiên bản:"; $lblName.Location = "15,30"; $lblName.Size = "100,20"
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.Location = "120,27"; $txtName.Size = "450,25"
    $lblID = New-Object System.Windows.Forms.Label; $lblID.Text = "Google Drive ID:"; $lblID.Location = "15,65"; $lblID.Size = "100,20"
    $txtID = New-Object System.Windows.Forms.TextBox; $txtID.Location = "120,62"; $txtID.Size = "450,25"
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM VÀO DANH SÁCH TẠM"; $btnAdd.Location = "350,95"; $btnAdd.Size = "220,25"; $btnAdd.BackColor = "#607D8B"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"
    $gbAdd.Controls.AddRange(@($lblName, $txtName, $lblID, $txtID, $btnAdd))

    # 4. CÁC NÚT ĐIỀU KHIỂN CHÍNH
    $btnDelete = New-Object System.Windows.Forms.Button; $btnDelete.Text = "XÓA DÒNG ĐÃ CHỌN"; $btnDelete.Location = "20,490"; $btnDelete.Size = "180,45"; $btnDelete.BackColor = "#E57373"; $btnDelete.ForeColor = "White"; $btnDelete.FlatStyle = "Flat"; $btnDelete.Font = $fontNut
    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "CẬP NHẬT LÊN CLOUD (GITHUB)"; $btnPush.Location = "210,490"; $btnPush.Size = "400,45"; $btnPush.BackColor = "#1E88E5"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fontNut

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Trạng thái: Vui lòng nhập Token..."; $lblStatus.Location = "20,550"; $lblStatus.Size = "590,20"; $lblStatus.ForeColor = "Gray"; $lblStatus.Font = $fontNho

    $form.Controls.AddRange(@($gbToken, $lv, $gbAdd, $btnDelete, $btnPush, $lblStatus))

    # --- LOGIC XỬ LÝ (GIỐNG FILE ADMIN CŨ) ---
    $global_sha = ""

    # Hàm lấy dữ liệu từ GitHub
    function Get-OfficeData {
        if (!$txtToken.Text) { [System.Windows.Forms.MessageBox]::Show("Nhập Token đã Toàn ơi!"); return }
        $lv.Items.Clear()
        try {
            $url = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
            $res = Invoke-RestMethod -Uri $url -Headers @{"Authorization"="token $($txtToken.Text)"}
            $script:global_sha = $res.sha
            $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($res.content))
            $csvData = $csvText | ConvertFrom-Csv
            foreach ($row in $csvData) {
                $li = New-Object System.Windows.Forms.ListViewItem($row.Name); [void]$li.SubItems.Add($row.ID); $lv.Items.Add($li)
            }
            $lblStatus.Text = "Trạng thái: Kết nối thành công. Đã tải danh sách."
        } catch {
            $lblStatus.Text = "Trạng thái: Lỗi kết nối hoặc file chưa tồn tại."
        }
    }

    # Nút kết nối
    $btnCheck.Add_Click({ Get-OfficeData })

    # Nút thêm tạm
    $btnAdd.Add_Click({
        if ($txtName.Text -and $txtID.Text) {
            $li = New-Object System.Windows.Forms.ListViewItem($txtName.Text); [void]$li.SubItems.Add($txtID.Text); $lv.Items.Add($li)
            $txtName.Clear(); $txtID.Clear(); $lblStatus.Text = "Trạng thái: Đã thêm tạm vào bảng."
        }
    })

    # Nút xóa
    $btnDelete.Add_Click({ 
        foreach ($i in $lv.SelectedItems) { $lv.Items.Remove($i) } 
        $lblStatus.Text = "Trạng thái: Đã xóa dòng chọn."
    })

    # Nút đẩy lên GitHub
    $btnPush.Add_Click({
        if (!$script:global_sha) { [System.Windows.Forms.MessageBox]::Show("Bấm 'KẾT NỐI' trước khi cập nhật ông nhé!"); return }
        
        $csvContent = "Name,ID`n"
        foreach ($item in $lv.Items) {
            $csvContent += "$($item.Text),$($item.SubItems[1].Text)`n"
        }
        
        try {
            $url = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
            $body = @{
                message = "Update Office List from VietToolbox Admin"
                content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($csvContent))
                sha = $script:global_sha
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $url -Method Put -Headers @{"Authorization"="token $($txtToken.Text)"} -Body $body
            $lblStatus.Text = "Trạng thái: Cập nhật thành công lên GitHub!"
            [System.Windows.Forms.MessageBox]::Show("Dữ liệu Office đã được đồng bộ lên Cloud!")
            Get-OfficeData # Load lại để cập nhật SHA mới
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi khi đẩy dữ liệu lên GitHub!")
        }
    })

    $form.ShowDialog() | Out-Null
}

&$LogicQuanTriOffice