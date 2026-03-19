# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicVietToolboxCloudV118 = {
    # --- CẤU HÌNH GITHUB ---
    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
    $tokenPath = Join-Path $env:TEMP "vt_cloud_token.txt"

    # --- ĐỊNH NGHĨA FONT ---
    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 9)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)

    # --- HÀM HỎI TOKEN ---
    function Get-StoredToken {
        if (Test-Path $tokenPath) { $tk = Get-Content $tokenPath -Raw; if ($tk) { return $tk.Trim() } }
        $inputForm = New-Object System.Windows.Forms.Form; $inputForm.Text = "Kích hoạt VietToolbox Cloud"; $inputForm.Size = "450,220"; $inputForm.StartPosition = "CenterScreen"; $inputForm.Topmost = $true
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Nhập mã GitHub Token để quản trị:"; $lbl.Location = "20,20"; $lbl.Size = "400,20"; $lbl.Font = $fontNoiDung
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20,50"; $txt.Size = "390,25"
        $btn = New-Object System.Windows.Forms.Button; $btn.Text = "KÍCH HOẠT"; $btn.Location = "160,110"; $btn.Size = "120,35"; $btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $inputForm.Controls.AddRange(@($lbl, $txt, $btn))
        if ($inputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and $txt.Text) { $val = $txt.Text.Trim(); $val | Out-File $tokenPath -Encoding UTF8; return $val }
        return $null
    }

    $global:GH_TOKEN = Get-StoredToken
    if (!$global:GH_TOKEN) { return }

    # --- KHỞI TẠO FORM CHÍNH ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX ADMIN V118 - QUẢN TRỊ ĐA KÊNH & DÒ CHOCO ID"; $form.Size = "1000,750"; $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"

    # --- BẢNG DỮ LIỆU ---
    $grid = New-Object System.Windows.Forms.DataGridView; $grid.Size = "940,300"; $grid.Location = "20,20"; $grid.AutoSizeColumnsMode = "Fill"; $grid.RowHeadersVisible = $false; $grid.BackgroundColor = "White"; $grid.BorderStyle = "FixedSingle"; $grid.SelectionMode = "FullRowSelect"; $grid.MultiSelect = $false
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="Mặc định";Width=60}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="Tên Phần Mềm"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="WingetID";HeaderText="Winget ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="ChocoID";HeaderText="Choco ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="GDriveID";HeaderText="GDrive ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="SilentArgs";HeaderText="Silent Args"}))
    
    # --- CÁC Ô NHẬP LIỆU ---
    $yPos = 360
    # Dòng 1: Tên + Winget
    $lblN = New-Object System.Windows.Forms.Label; $lblN.Text = "Tên hiển thị:"; $lblN.Location = "20,$($yPos-20)"; $lblN.Font = $fontNho; $lblN.ForeColor = "Gray"
    $txtN = New-Object System.Windows.Forms.TextBox; $txtN.Location = "20,$yPos"; $txtN.Size = "220,25"

    $lblW = New-Object System.Windows.Forms.Label; $lblW.Text = "Winget ID:"; $lblW.Location = "250,$($yPos-20)"; $lblW.Font = $fontNho; $lblW.ForeColor = "Gray"
    $txtW = New-Object System.Windows.Forms.TextBox; $txtW.Location = "250,$yPos"; $txtW.Size = "220,25"
    
    # Dòng 2: Choco + Drive + Silent
    $yPos += 60
    $lblC = New-Object System.Windows.Forms.Label; $lblC.Text = "Choco ID:"; $lblC.Location = "20,$($yPos-20)"; $lblC.Font = $fontNho; $lblC.ForeColor = "Gray"
    $txtC = New-Object System.Windows.Forms.TextBox; $txtC.Location = "20,$yPos"; $txtC.Size = "220,25"

    $lblG = New-Object System.Windows.Forms.Label; $lblG.Text = "GDrive File ID:"; $lblG.Location = "250,$($yPos-20)"; $lblG.Font = $fontNho; $lblG.ForeColor = "Gray"
    $txtG = New-Object System.Windows.Forms.TextBox; $txtG.Location = "250,$yPos"; $txtG.Size = "220,25"

    $lblS = New-Object System.Windows.Forms.Label; $lblS.Text = "Silent Args (vd: /S):"; $lblS.Location = "480,$($yPos-20)"; $lblS.Font = $fontNho; $lblS.ForeColor = "Gray"
    $txtS = New-Object System.Windows.Forms.TextBox; $txtS.Location = "480,$yPos"; $txtS.Size = "200,25"
    
    # --- NÚT BẤM CƠ BẢN ---
    $yPos += 60
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM MỚI"; $btnAdd.Location = "20,$yPos"; $btnAdd.Size = "120,40"; $btnAdd.BackColor = "#4CAF50"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"; $btnAdd.Font = $fontNut
    $btnEdit = New-Object System.Windows.Forms.Button; $btnEdit.Text = "LƯU SỬA"; $btnEdit.Location = "150,$yPos"; $btnEdit.Size = "120,40"; $btnEdit.BackColor = "#FF9800"; $btnEdit.ForeColor = "White"; $btnEdit.FlatStyle = "Flat"; $btnEdit.Font = $fontNut
    $btnDel = New-Object System.Windows.Forms.Button; $btnDel.Text = "XOÁ DÒNG"; $btnDel.Location = "280,$yPos"; $btnDel.Size = "120,40"; $btnDel.BackColor = "#E57373"; $btnDel.ForeColor = "White"; $btnDel.FlatStyle = "Flat"; $btnDel.Font = $fontNut

    # --- NÚT DÒ GỢI Ý (CHOCO PICKER) ---
    $btnSearchPick = New-Object System.Windows.Forms.Button; $btnSearchPick.Text = "🪄 DÒ & CHỌN CHOCO ID"; $btnSearchPick.Location = "410,$yPos"; $btnSearchPick.Size = "220,40"; $btnSearchPick.BackColor = "#9C27B0"; $btnSearchPick.ForeColor = "White"; $btnSearchPick.FlatStyle = "Flat"; $btnSearchPick.Font = $fontNut

    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "CẬP NHẬT DỮ LIỆU LÊN GITHUB CLOUD"; $btnPush.Size = "940,60"; $btnPush.Location = "20,620"; $btnPush.BackColor = "#0D47A1"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fontNut
    
    $form.Controls.AddRange(@($grid, $txtN, $lblN, $txtW, $lblW, $txtC, $lblC, $txtG, $lblG, $txtS, $lblS, $btnAdd, $btnEdit, $btnDel, $btnSearchPick, $btnPush))

    # --- HÀM CHOCO PICKER (BẢN FIX TÌM KIẾM THÔNG MINH 100%) ---
    function Show-ChocoPicker($appName) {
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show("Máy ông phải cài sẵn Chocolatey thì tui mới dò được!", "Lỗi thiếu Choco")
            return $null
        }

        # 1. BỘ LỌC TỪ ĐIỂN (Bao trúng 100% các app phổ thông)
        $searchTerm = $appName.ToLower().Trim()
        $dict = @{
            "notepad++" = "notepadplusplus"
            "google chrome" = "googlechrome"
            "chrome" = "googlechrome"
            "cốc cốc" = "coccoc"
            "coccoc" = "coccoc"
            "winrar" = "winrar"
            "7-zip" = "7zip"
            "7zip" = "7zip"
            "unikey" = "unikey"
            "foxit" = "foxitreader"
            "ultraviewer" = "ultraviewer"
            "teamviewer" = "teamviewer"
            "anydesk" = "anydesk"
            "zalo" = "zalo"
            "vlc" = "vlc"
            "k-lite" = "k-litecodecpackfull"
        }

        $isVip = $false
        foreach ($key in $dict.Keys) {
            # CHỖ NÀY ĐÃ SỬA: Dùng .Contains thay cho -match để không bị lỗi dấu +
            if ($searchTerm.Contains($key)) {
                $searchTerm = $dict[$key]
                $isVip = $true
                break
            }
        }

        # 2. NẾU APP LẠ -> ÉP KIỂU TÊN THÀNH ID
        if (!$isVip) {
            # Xóa dấu cách, đổi ++ thành plusplus để Choco dễ dò ID hơn
            $searchTerm = $searchTerm -replace '\s+', '' -replace '\+\+', 'plusplus' -replace '[^a-zA-Z0-9\-]', ''
        }

        # Bắt đầu gọi Choco đi tìm (Tìm ID viết liền sẽ chuẩn hơn rất nhiều)
        $results = choco search "$searchTerm" --limit-output | Select-Object -First 15
        
        # Nếu vẫn không ra, thử tìm lại bằng tên gốc của ông
        if (!$results) {
            $results = choco search "$appName" --limit-output | Select-Object -First 15
        }

        if (!$results) { 
            [System.Windows.Forms.MessageBox]::Show("Chịu thua! Không tìm thấy thằng nào giống '$appName' trên kho Choco.", "Trắng tay")
            return $null 
        }

        # Kéo Form
        $picker = New-Object System.Windows.Forms.Form
        $picker.Text = "Chọn ID chuẩn cho: $appName"; $picker.Size = "400,320"; $picker.StartPosition = "CenterParent"; $picker.FormBorderStyle = "FixedDialog"; $picker.MinimizeBox = $false; $picker.MaximizeBox = $false
        
        $lb = New-Object System.Windows.Forms.ListBox; $lb.Location = "10,10"; $lb.Size = "360,200"; $lb.Font = $fontNoiDung
        
        # Đổ kết quả vào bảng, ưu tiên thằng nào có ID giống hệt tên tìm kiếm nhảy lên đầu (Màu mè xíu cho pro)
        $exactMatchIndex = 0
        $i = 0
        foreach ($res in $results) { 
            if ($res -match "\|") {
                $id = $res.Split("|")[0]
                $ver = $res.Split("|")[1]
                [void]$lb.Items.Add("$id (v$ver)") 
                
                # Bắt thằng chính xác nhất
                if ($id.ToLower() -eq $searchTerm.ToLower()) { $exactMatchIndex = $i }
                $i++
            }
        }
        
        if ($lb.Items.Count -gt 0) { $lb.SelectedIndex = $exactMatchIndex }

        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "✔️ CHỐT CÁI NÀY"; $btnOk.Location = "130,230"; $btnOk.Size = "130,35"; $btnOk.BackColor = "#4CAF50"; $btnOk.ForeColor = "White"; $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $picker.Controls.AddRange(@($lb, $btnOk))

        if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and $lb.SelectedItem) {
            return $lb.SelectedItem.ToString().Split(" ")[0]
        }
        return $null
    }

    # --- SỰ KIỆN NÚT DÒ & CHỌN ---
    $btnSearchPick.Add_Click({
        if ($grid.SelectedRows.Count -eq 0) { 
            [System.Windows.Forms.MessageBox]::Show("Ông phải click chọn 1 dòng trong bảng dưới trước đã!"); return 
        }
        
        $row = $grid.SelectedRows[0]
        $name = $row.Cells['Name'].Value
        if (!$name) { return }

        $btnSearchPick.Text = "⏳ Đang tìm..."; $btnSearchPick.Enabled = $false; $form.Refresh()
        
        $pickedID = Show-ChocoPicker $name
        
        if ($pickedID) {
            $row.Cells['ChocoID'].Value = $pickedID
            $txtC.Text = $pickedID # Hiện lên ô nhập luôn cho tiện
        }
        
        $btnSearchPick.Text = "🪄 DÒ & CHỌN CHOCO ID"
        $btnSearchPick.Enabled = $true
    })

    # --- HÀM TẢI DỮ LIỆU TỪ GITHUB ---
    function Reload-Admin {
        $grid.Rows.Clear()
        try {
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            if ($null -ne $response -and $null -ne $response.content) {
                $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($response.content -replace "\s", "")))
                $csvData = $csvText.Trim().Trim([char]65279) | ConvertFrom-Csv
                foreach ($a in $csvData) { 
                    $wID = if ($a.WingetID) { $a.WingetID } else { $a.ID }
                    $cID = if ($a.ChocoID)  { $a.ChocoID }  else { "" }
                    $gID = if ($a.GDriveID) { $a.GDriveID } else { "" }
                    $sA  = if ($a.SilentArgs) { $a.SilentArgs } else { "" }
                    [void]$grid.Rows.Add(($a.Check -match "True"), $a.Name, $wID, $cID, $gID, $sA) 
                }
            }
        } catch { }
    }

    # --- CÁC SỰ KIỆN KHÁC ---
    $grid.Add_SelectionChanged({
        if ($grid.SelectedRows.Count -gt 0) {
            $row = $grid.SelectedRows[0]
            if (!$row.IsNewRow) {
                $txtN.Text = $row.Cells['Name'].Value; $txtW.Text = $row.Cells['WingetID'].Value
                $txtC.Text = $row.Cells['ChocoID'].Value; $txtG.Text = $row.Cells['GDriveID'].Value; $txtS.Text = $row.Cells['SilentArgs'].Value
            }
        }
    })
    
    $btnAdd.Add_Click({ 
        if ($txtN.Text) { 
            [void]$grid.Rows.Add($true, $txtN.Text, $txtW.Text, $txtC.Text, $txtG.Text, $txtS.Text)
            $txtN.Text=$txtW.Text=$txtC.Text=$txtG.Text=$txtS.Text="" 
        } 
    })
    
    $btnEdit.Add_Click({
        if ($grid.SelectedRows.Count -gt 0) {
            $row = $grid.SelectedRows[0]
            $row.Cells['Name'].Value = $txtN.Text; $row.Cells['WingetID'].Value = $txtW.Text
            $row.Cells['ChocoID'].Value = $txtC.Text; $row.Cells['GDriveID'].Value = $txtG.Text; $row.Cells['SilentArgs'].Value = $txtS.Text
        }
    })

    $btnDel.Add_Click({ foreach ($row in $grid.SelectedRows) { if (!$row.IsNewRow) { $grid.Rows.Remove($row) } } })

    $btnPush.Add_Click({
        try {
            $header = "Check,Name,WingetID,ChocoID,GDriveID,SilentArgs"
            $rows = foreach ($r in $grid.Rows) {
                if ($r.Cells['Name'].Value) {
                    "$($r.Cells['Check'].Value),$($r.Cells['Name'].Value),$($r.Cells['WingetID'].Value),$($r.Cells['ChocoID'].Value),$($r.Cells['GDriveID'].Value),$($r.Cells['SilentArgs'].Value)"
                }
            }
            $csv = ($header, ($rows -join "`n")) -join "`n"
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $body = @{ 
                message = "VietToolbox Update V118 (Added Choco Picker)"; 
                content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csv.Trim())); 
                sha     = $info.sha 
            } | ConvertTo-Json
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật Cloud thành công!")
            Reload-Admin
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi cập nhật Cloud! Kiểm tra Token hoặc kết nối mạng.") }
    })

    Reload-Admin; $form.ShowDialog() | Out-Null
}

&$LogicVietToolboxCloudV118