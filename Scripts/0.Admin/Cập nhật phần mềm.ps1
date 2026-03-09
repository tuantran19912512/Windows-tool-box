# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicQuanTriCloud = {
    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
    $tokenPath = Join-Path $env:TEMP "vt_cloud_token.txt"

    # --- ĐỊNH NGHĨA FONT ---
    $fontNut    = New-Object System.Drawing.Font("Segoe UI Bold", 9)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho    = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    # --- HÀM HỎI TOKEN ---
    function Get-StoredToken {
        if (Test-Path $tokenPath) { 
            $tk = Get-Content $tokenPath -Raw
            if ($tk) { return $tk.Trim() }
        }
        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = "Kích hoạt VietToolbox Cloud"; $inputForm.Size = "450,200"; $inputForm.StartPosition = "CenterScreen"; $inputForm.TopMost = $true
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Nhập mã GitHub Token để quản trị:"; $lbl.Location = "20,20"; $lbl.Size = "400,20"; $lbl.Font = $fontNoiDung
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20,50"; $txt.Size = "390,25"
        $btn = New-Object System.Windows.Forms.Button; $btn.Text = "KÍCH HOẠT"; $btn.Location = "160,100"; $btn.Size = "120,35"; $btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $inputForm.Controls.AddRange(@($lbl, $txt, $btn))
        if ($inputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and $txt.Text) {
            $val = $txt.Text.Trim(); $val | Out-File $tokenPath -Encoding UTF8; return $val
        }
        return $null
    }

    $global:GH_TOKEN = Get-StoredToken
    if (!$global:GH_TOKEN) { return }

    # --- KHỞI TẠO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - QUẢN TRỊ DỮ LIỆU CLOUD (V115)"; $form.Size = "900,650"; $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"

    # Bảng dữ liệu
    $grid = New-Object System.Windows.Forms.DataGridView; $grid.Size = "840,280"; $grid.Location = "20,20"; $grid.AutoSizeColumnsMode = "Fill"; $grid.RowHeadersVisible = $false; $grid.BackgroundColor = "White"; $grid.BorderStyle = "FixedSingle"; $grid.SelectionMode = "FullRowSelect"; $grid.MultiSelect = $false
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="Mặc định"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="Tên Ứng Dụng"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="ID";HeaderText="Winget ID"}))
    
    # --- Ô NHẬP LIỆU ---
    $lblN = New-Object System.Windows.Forms.Label; $lblN.Text = "Tên hiển thị:"; $lblN.Location = "20,315"; $lblN.Size = "220,20"; $lblN.Font = $fontNho; $lblN.ForeColor = "Gray"
    $txtN = New-Object System.Windows.Forms.TextBox; $txtN.Location = "20,340"; $txtN.Size = "220,25"; $txtN.Font = $fontNoiDung
    
    $lblI = New-Object System.Windows.Forms.Label; $lblI.Text = "Winget ID:"; $lblI.Location = "250,315"; $lblI.Size = "220,20"; $lblI.Font = $fontNho; $lblI.ForeColor = "Gray"
    $txtI = New-Object System.Windows.Forms.TextBox; $txtI.Location = "250,340"; $txtI.Size = "220,25"; $txtI.Font = $fontNoiDung
    
    # --- BỘ NÚT ĐIỀU KHIỂN ---
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM MỚI"; $btnAdd.Location = "480,338"; $btnAdd.Size = "95,30"; $btnAdd.BackColor = "#4CAF50"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"; $btnAdd.Font = $fontNut
    
    $btnEdit = New-Object System.Windows.Forms.Button; $btnEdit.Text = "SỬA / LƯU"; $btnEdit.Location = "580,338"; $btnEdit.Size = "95,30"; $btnEdit.BackColor = "#FF9800"; $btnEdit.ForeColor = "White"; $btnEdit.FlatStyle = "Flat"; $btnEdit.Font = $fontNut

    $btnDel = New-Object System.Windows.Forms.Button; $btnDel.Text = "XOÁ DÒNG"; $btnDel.Location = "680,338"; $btnDel.Size = "95,30"; $btnDel.BackColor = "#E57373"; $btnDel.ForeColor = "White"; $btnDel.FlatStyle = "Flat"; $btnDel.Font = $fontNut

    $btnClear = New-Object System.Windows.Forms.Button; $btnClear.Text = "XOÁ SẠCH"; $btnClear.Location = "780,338"; $btnClear.Size = "80,30"; $btnClear.BackColor = "#B71C1C"; $btnClear.ForeColor = "White"; $btnClear.FlatStyle = "Flat"; $btnClear.Font = $fontNut

    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "CẬP NHẬT DỮ LIỆU LÊN CLOUD (GITHUB)"; $btnPush.Size = "840,60"; $btnPush.Location = "20,500"; $btnPush.BackColor = "#0D47A1"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fontNut
    
    $form.Controls.AddRange(@($grid, $lblN, $txtN, $lblI, $txtI, $btnAdd, $btnEdit, $btnDel, $btnClear, $btnPush))

    # --- HÀM TẢI DỮ LIỆU ---
    function Reload-Admin {
        $grid.Rows.Clear()
        try {
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            if ($null -ne $response -and $null -ne $response.content) {
                $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($response.content -replace "\s", "")))
                $lines = $csvText.Trim().Trim([char]65279) -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
                $csvData = $lines | ConvertFrom-Csv
                foreach ($a in $csvData) { if ($a.Name) { [void]$grid.Rows.Add(($a.Check -match "True"), $a.Name, $a.ID) } }
            }
        } catch { }
    }

    # --- SỰ KIỆN ---

    # Click vào dòng trong Grid -> Đưa lên ô nhập
    $grid.Add_SelectionChanged({
        if ($grid.SelectedRows.Count -gt 0) {
            $row = $grid.SelectedRows[0]
            if (!$row.IsNewRow) {
                $txtN.Text = $row.Cells['Name'].Value
                $txtI.Text = $row.Cells['ID'].Value
            }
        }
    })
    
    # Thêm mới
    $btnAdd.Add_Click({ 
        if ($txtN.Text) { 
            [void]$grid.Rows.Add($true, $txtN.Text, $txtI.Text)
            $txtN.Text=""; $txtI.Text="" 
        } 
    })
    
    # Sửa dòng đang chọn
    $btnEdit.Add_Click({
        if ($grid.SelectedRows.Count -gt 0) {
            $row = $grid.SelectedRows[0]
            if ($txtN.Text) {
                $row.Cells['Name'].Value = $txtN.Text
                $row.Cells['ID'].Value = $txtI.Text
                [System.Windows.Forms.MessageBox]::Show("Đã sửa dòng thành công! Nhớ bấm Cập nhật Cloud để lưu.")
            }
        }
    })

    # Xoá dòng
    $btnDel.Add_Click({
        foreach ($row in $grid.SelectedRows) { if (!$row.IsNewRow) { $grid.Rows.Remove($row) } }
    })

    # Xoá sạch
    $btnClear.Add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("Xoá sạch bảng?", "Xác nhận", "YesNo") -eq "Yes") { $grid.Rows.Clear() }
    })
    
    # Đẩy dữ liệu
    $btnPush.Add_Click({
        try {
            $csv = "Check,Name,ID`n" + (($grid.Rows | ForEach-Object { if ($_.Cells['Name'].Value) { "$($_.Cells['Check'].Value),$($_.Cells['Name'].Value),$($_.Cells['ID'].Value)" } }) -join "`n")
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $body = @{ message="Admin Update"; content=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csv.Trim())); sha=$info.sha } | ConvertTo-Json
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật dữ liệu Cloud thành công!"); Reload-Admin
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi kết nối Cloud!") }
    })

    Reload-Admin; $form.ShowDialog() | Out-Null
}
&$LogicQuanTriCloud