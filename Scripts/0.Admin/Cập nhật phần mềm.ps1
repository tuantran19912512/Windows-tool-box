# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicVietToolboxCloudV117 = {
    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
    $tokenPath = Join-Path $env:TEMP "vt_cloud_token.txt"

    $fontNut = New-Object System.Drawing.Font("Segoe UI Bold", 9)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)

    function Get-StoredToken {
        if (Test-Path $tokenPath) { $tk = Get-Content $tokenPath -Raw; if ($tk) { return $tk.Trim() } }
        $inputForm = New-Object System.Windows.Forms.Form; $inputForm.Text = "Kích hoạt VietToolbox Cloud"; $inputForm.Size = "450,220"; $inputForm.StartPosition = "CenterScreen"; $inputForm.TopMost = $true
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Nhập mã GitHub Token để quản trị:"; $lbl.Location = "20,20"; $lbl.Size = "400,20"; $lbl.Font = $fontNoiDung
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20,50"; $txt.Size = "390,25"
        $btn = New-Object System.Windows.Forms.Button; $btn.Text = "KÍCH HOẠT"; $btn.Location = "160,110"; $btn.Size = "120,35"; $btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $inputForm.Controls.AddRange(@($lbl, $txt, $btn))
        if ($inputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and $txt.Text) { $val = $txt.Text.Trim(); $val | Out-File $tokenPath -Encoding UTF8; return $val }
        return $null
    }

    $global:GH_TOKEN = Get-StoredToken
    if (!$global:GH_TOKEN) { return }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX ADMIN V117 - AUTO SEARCH CHOCO ID"; $form.Size = "1050,800"; $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"

    $grid = New-Object System.Windows.Forms.DataGridView; $grid.Size = "980,300"; $grid.Location = "20,20"; $grid.AutoSizeColumnsMode = "Fill"; $grid.RowHeadersVisible = $false; $grid.BackgroundColor = "White"; $grid.BorderStyle = "FixedSingle"; $grid.SelectionMode = "FullRowSelect"; $grid.MultiSelect = $false
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="Mặc định";Width=60}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="Tên Phần Mềm"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="WingetID";HeaderText="Winget ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="ChocoID";HeaderText="Choco ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="GDriveID";HeaderText="GDrive ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="SilentArgs";HeaderText="Silent Args"}))
    
    $yPos = 360
    $lblN = New-Object System.Windows.Forms.Label; $lblN.Text = "Tên hiển thị:"; $lblN.Location = "20,$($yPos-20)"; $lblN.Font = $fontNho; $lblN.ForeColor = "Gray"
    $txtN = New-Object System.Windows.Forms.TextBox; $txtN.Location = "20,$yPos"; $txtN.Size = "220,25"
    $txtW = New-Object System.Windows.Forms.TextBox; $txtW.Location = "250,$yPos"; $txtW.Size = "220,25"
    
    $yPos += 60
    $txtC = New-Object System.Windows.Forms.TextBox; $txtC.Location = "20,$yPos"; $txtC.Size = "220,25"
    $txtG = New-Object System.Windows.Forms.TextBox; $txtG.Location = "250,$yPos"; $txtG.Size = "220,25"
    $txtS = New-Object System.Windows.Forms.TextBox; $txtS.Location = "480,$yPos"; $txtS.Size = "200,25"
    
    $yPos += 50
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM DÒNG"; $btnAdd.Location = "20,$yPos"; $btnAdd.Size = "130,40"; $btnAdd.BackColor = "#4CAF50"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"
    $btnEdit = New-Object System.Windows.Forms.Button; $btnEdit.Text = "LƯU SỬA"; $btnEdit.Location = "160,$yPos"; $btnEdit.Size = "130,40"; $btnEdit.BackColor = "#FF9800"; $btnEdit.ForeColor = "White"; $btnEdit.FlatStyle = "Flat"
    $btnDel = New-Object System.Windows.Forms.Button; $btnDel.Text = "XOÁ DÒNG"; $btnDel.Location = "300,$yPos"; $btnDel.Size = "130,40"; $btnDel.BackColor = "#E57373"; $btnDel.ForeColor = "White"; $btnDel.FlatStyle = "Flat"

    # --- NÚT DÒ HÀNG LOẠT (BÁ ĐẠO) ---
    $btnAutoAll = New-Object System.Windows.Forms.Button; $btnAutoAll.Text = "🪄 DÒ TOÀN BỘ CHOCO ID"; $btnAutoAll.Location = "440,$yPos"; $btnAutoAll.Size = "250,40"; $btnAutoAll.BackColor = "#673AB7"; $btnAutoAll.ForeColor = "White"; $btnAutoAll.FlatStyle = "Flat"; $btnAutoAll.Font = $fontNut

    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "CẬP NHẬT DỮ LIỆU LÊN GITHUB CLOUD"; $btnPush.Size = "980,60"; $btnPush.Location = "20,650"; $btnPush.BackColor = "#0D47A1"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fontNut
    
    $form.Controls.AddRange(@($grid, $txtN, $lblN, $txtW, $txtC, $txtG, $txtS, $btnAdd, $btnEdit, $btnDel, $btnAutoAll, $btnPush))

    function Reload-Admin {
        $grid.Rows.Clear()
        try {
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            if ($null -ne $response -and $null -ne $response.content) {
                $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($response.content -replace "\s", "")))
                $csvData = $csvText.Trim().Trim([char]65279) | ConvertFrom-Csv
                foreach ($a in $csvData) { 
                    [void]$grid.Rows.Add(($a.Check -match "True"), $a.Name, $a.WingetID, $a.ChocoID, $a.GDriveID, $a.SilentArgs) 
                }
            }
        } catch { }
    }

    # --- LOGIC DÒ HÀNG LOẠT ---
    $btnAutoAll.Add_Click({
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show("Máy ông phải cài Chocolatey thì tui mới dò được chứ!")
            return
        }

        $confirm = [System.Windows.Forms.MessageBox]::Show("Tui sẽ dò ID cho toàn bộ danh sách, việc này mất chút thời gian. Chơi luôn không?", "Xác nhận lười", "YesNo")
        if ($confirm -eq "No") { return }

        $btnAutoAll.Enabled = $false
        foreach ($row in $grid.Rows) {
            $appName = $row.Cells['Name'].Value
            $currentChoco = $row.Cells['ChocoID'].Value
            
            # Chỉ dò nếu có tên và ChocoID đang trống
            if ($appName -and [string]::IsNullOrEmpty($currentChoco)) {
                $btnAutoAll.Text = "⏳ Đang dò: $appName..."
                $form.Refresh()
                
                $searchResult = choco search $appName --limit-output | Select-Object -First 1
                if ($searchResult) {
                    $foundID = $searchResult.Split("|")[0]
                    $row.Cells['ChocoID'].Value = $foundID
                }
            }
        }
        $btnAutoAll.Text = "🪄 DÒ TOÀN BỘ CHOCO ID"
        $btnAutoAll.Enabled = $true
        [System.Windows.Forms.MessageBox]::Show("Xong rồi ông Tuấn ơi! Tui đã điền hết ID tìm được vào bảng.")
    })

    $grid.Add_SelectionChanged({
        if ($grid.SelectedRows.Count -gt 0) {
            $row = $grid.SelectedRows[0]
            if (!$row.IsNewRow) {
                $txtN.Text = $row.Cells['Name'].Value; $txtW.Text = $row.Cells['WingetID'].Value
                $txtC.Text = $row.Cells['ChocoID'].Value; $txtG.Text = $row.Cells['GDriveID'].Value; $txtS.Text = $row.Cells['SilentArgs'].Value
            }
        }
    })
    
    $btnAdd.Add_Click({ if ($txtN.Text) { [void]$grid.Rows.Add($true, $txtN.Text, $txtW.Text, $txtC.Text, $txtG.Text, $txtS.Text); $txtN.Text=$txtW.Text=$txtC.Text=$txtG.Text=$txtS.Text="" } })
    
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
            $rows = foreach ($r in $grid.Rows) { if ($r.Cells['Name'].Value) { "$($r.Cells['Check'].Value),$($r.Cells['Name'].Value),$($r.Cells['WingetID'].Value),$($r.Cells['ChocoID'].Value),$($r.Cells['GDriveID'].Value),$($r.Cells['SilentArgs'].Value)" } }
            $csv = ($header, ($rows -join "`n")) -join "`n"
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $body = @{ message="VietToolbox Triple Channel Update (V117)"; content=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csv.Trim())); sha=$info.sha } | ConvertTo-Json
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật Cloud thành công!")
            Reload-Admin
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi cập nhật Cloud!") }
    })

    Reload-Admin; $form.ShowDialog() | Out-Null
}
&$LogicVietToolboxCloudV117