# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicQuanTriOffice = {
    # --- CẤU HÌNH GITHUB MẶC ĐỊNH ---
    $GH_USER = "tuantran19912512"
    $GH_REPO = "Windows-tool-box"
    $GH_FILE = "DanhSachOffice.csv"

    # LẤY TOKEN TỪ MENU CHÍNH (BIẾN TOÀN CỤC)
    $CurrentToken = $Global:GH_TOKEN

    if (-not $CurrentToken) {
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy mã xác thực! Vui lòng truy cập lại nhóm Admin từ Menu chính.", "Lỗi Xác Thực")
        return
    }

    # --- FONT UI CHUẨN ---
    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 9)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 9)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)

    # --- KHỞI TẠO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX ADMIN - QUẢN LÝ BỘ CÀI OFFICE"; $form.Size = "650,580"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    # 1. DANH SÁCH OFFICE HIỆN TẠI (Đổi tên cột cho chuẩn)
    $lv = New-Object System.Windows.Forms.ListView; $lv.Size = "590,250"; $lv.Location = "20,20"; $lv.View = "Details"; $lv.FullRowSelect = $true; $lv.GridLines = $true; $lv.Font = $fontNoiDung
    [void]$lv.Columns.Add("TÊN PHIÊN BẢN OFFICE", 280); [void]$lv.Columns.Add("ID GOOGLE DRIVE / LINK TẢI TRỰC TIẾP", 280)

    # 2. KHU VỰC THÊM MỚI (Đổi nhãn dán cho phù hợp)
    $gbAdd = New-Object System.Windows.Forms.GroupBox; $gbAdd.Text = " THÊM PHIÊN BẢN MỚI "; $gbAdd.Size = "590,130"; $gbAdd.Location = "20,285"
    $lblName = New-Object System.Windows.Forms.Label; $lblName.Text = "Tên phiên bản:"; $lblName.Location = "15,30"; $lblName.Size = "100,20"
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.Location = "120,27"; $txtName.Size = "450,25"
    
    $lblID = New-Object System.Windows.Forms.Label; $lblID.Text = "ID / Link tải:"; $lblID.Location = "15,65"; $lblID.Size = "100,20"
    $txtID = New-Object System.Windows.Forms.TextBox; $txtID.Location = "120,62"; $txtID.Size = "450,25"
    
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM TẠM VÀO BẢNG"; $btnAdd.Location = "350,95"; $btnAdd.Size = "220,25"; $btnAdd.BackColor = "#607D8B"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"
    $gbAdd.Controls.AddRange(@($lblName, $txtName, $lblID, $txtID, $btnAdd))

    # 3. CÁC NÚT ĐIỀU KHIỂN CHÍNH
    $btnDelete = New-Object System.Windows.Forms.Button; $btnDelete.Text = "XÓA DÒNG ĐÃ CHỌN"; $btnDelete.Location = "20,430"; $btnDelete.Size = "180,45"; $btnDelete.BackColor = "#E57373"; $btnDelete.ForeColor = "White"; $btnDelete.FlatStyle = "Flat"; $btnDelete.Font = $fontNut
    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "CẬP NHẬT LÊN CLOUD (GITHUB)"; $btnPush.Location = "210,430"; $btnPush.Size = "400,45"; $btnPush.BackColor = "#1E88E5"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fontNut

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Trạng thái: Đang kết nối bằng Token Admin..."; $lblStatus.Location = "20,490"; $lblStatus.Size = "590,20"; $lblStatus.ForeColor = "DarkGreen"; $lblStatus.Font = $fontNho

    $form.Controls.AddRange(@($lv, $gbAdd, $btnDelete, $btnPush, $lblStatus))

    # --- LOGIC XỬ LÝ ---
    $global_sha = ""

    # Hàm lấy dữ liệu (Tự động gọi khi mở)
    function Get-OfficeData {
        $lv.Items.Clear()
        try {
            $url = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
            $res = Invoke-RestMethod -Uri $url -Headers @{"Authorization"="token $CurrentToken"}
            $script:global_sha = $res.sha
            $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($res.content))
            $csvData = $csvText | ConvertFrom-Csv
            foreach ($row in $csvData) {
                $li = New-Object System.Windows.Forms.ListViewItem($row.Name); [void]$li.SubItems.Add($row.ID); $lv.Items.Add($li)
            }
            $lblStatus.Text = "Trạng thái: Đã đồng bộ dữ liệu Office từ Cloud."
        } catch {
            $lblStatus.Text = "Trạng thái: Lỗi kết nối Cloud hoặc file chưa tồn tại."
        }
    }

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
        if (!$script:global_sha) { [System.Windows.Forms.MessageBox]::Show("Dữ liệu chưa được tải về, không thể cập nhật!"); return }
        
        # Mặc dù giao diện hiển thị là "ID / Link", Cấu trúc file CSV vẫn giữ nguyên "Name,ID" để các tool tự động tương thích tốt
        $csvContent = "Name,ID`n"
        foreach ($item in $lv.Items) {
            $csvContent += "$($item.Text),$($item.SubItems[1].Text)`n"
        }
        
        try {
            $url = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
            $body = @{
                message = "Admin Update Office List via VietToolbox Pro"
                content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($csvContent))
                sha = $script:global_sha
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $url -Method Put -Headers @{"Authorization"="token $CurrentToken"} -Body $body
            $lblStatus.Text = "Trạng thái: Cập nhật Cloud thành công!"
            [System.Windows.Forms.MessageBox]::Show("Danh sách Office đã được đồng bộ lên Cloud!", "Thành Công")
            Get-OfficeData # Load lại để lấy SHA mới
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi khi đẩy dữ liệu lên GitHub!", "Lỗi")
        }
    })

    # TỰ ĐỘNG CHẠY KHI MỞ
    Get-OfficeData
    $form.ShowDialog() | Out-Null
}

&$LogicQuanTriOffice