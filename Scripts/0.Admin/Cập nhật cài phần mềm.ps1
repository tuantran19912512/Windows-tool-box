# ==============================================================================
# VIETTOOLBOX ADMIN V123 - BẢN FIX GIAO DIỆN & TIÊU ĐỀ
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicVietToolboxCloudV123 = {
    if (-not $Global:GH_TOKEN) {
        [System.Windows.Forms.MessageBox]::Show("Thiếu GitHub Token ở Main!", "Lỗi")
        return
    }

    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"

    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 9)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX ADMIN V123 - QUẢN TRỊ CLOUD"; $form.Size = "1000,750"; $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"

    # --- BẢNG DỮ LIỆU ---
    $grid = New-Object System.Windows.Forms.DataGridView; $grid.Size = "940,300"; $grid.Location = "20,20"; $grid.AutoSizeColumnsMode = "Fill"; $grid.RowHeadersVisible = $false; $grid.BackgroundColor = "White"; $grid.SelectionMode = "FullRowSelect"
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="Mặc định";Width=60}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="Tên Phần Mềm"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="WingetID";HeaderText="Winget ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="ChocoID";HeaderText="Choco ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="GDriveID";HeaderText="GDrive ID"}))
    [void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="SilentArgs";HeaderText="Silent Args"}))
    
    # --- CÁC Ô NHẬP LIỆU & TIÊU ĐỀ (ĐÃ KHÔI PHỤC) ---
    $yPos = 360
    $lblN = New-Object System.Windows.Forms.Label; $lblN.Text = "Tên hiển thị:"; $lblN.Location = "20,$($yPos-20)"; $lblN.Font = $fontNho; $lblN.ForeColor = "Gray"
    $txtN = New-Object System.Windows.Forms.TextBox; $txtN.Location = "20,$yPos"; $txtN.Size = "220,25"

    $lblW = New-Object System.Windows.Forms.Label; $lblW.Text = "Winget ID:"; $lblW.Location = "250,$($yPos-20)"; $lblW.Font = $fontNho; $lblW.ForeColor = "Gray"
    $txtW = New-Object System.Windows.Forms.TextBox; $txtW.Location = "250,$yPos"; $txtW.Size = "220,25"
    
    $yPos += 60
    $lblC = New-Object System.Windows.Forms.Label; $lblC.Text = "Choco ID:"; $lblC.Location = "20,$($yPos-20)"; $lblC.Font = $fontNho; $lblC.ForeColor = "Gray"
    $txtC = New-Object System.Windows.Forms.TextBox; $txtC.Location = "20,$yPos"; $txtC.Size = "220,25"

    $lblG = New-Object System.Windows.Forms.Label; $lblG.Text = "GDrive File ID:"; $lblG.Location = "250,$($yPos-20)"; $lblG.Font = $fontNho; $lblG.ForeColor = "Gray"
    $txtG = New-Object System.Windows.Forms.TextBox; $txtG.Location = "250,$yPos"; $txtG.Size = "220,25"

    $lblS = New-Object System.Windows.Forms.Label; $lblS.Text = "Silent Args:"; $lblS.Location = "480,$($yPos-20)"; $lblS.Font = $fontNho; $lblS.ForeColor = "Gray"
    $txtS = New-Object System.Windows.Forms.TextBox; $txtS.Location = "480,$yPos"; $txtS.Size = "200,25"
    
    # --- NÚT BẤM ---
    $yPos += 60
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THÊM MỚI"; $btnAdd.Location = "20,$yPos"; $btnAdd.Size = "110,40"; $btnAdd.BackColor = "#4CAF50"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"; $btnAdd.Font = $fontNut
    $btnEdit = New-Object System.Windows.Forms.Button; $btnEdit.Text = "LƯU SỬA"; $btnEdit.Location = "140,$yPos"; $btnEdit.Size = "110,40"; $btnEdit.BackColor = "#FF9800"; $btnEdit.ForeColor = "White"; $btnEdit.FlatStyle = "Flat"; $btnEdit.Font = $fontNut
    $btnDel = New-Object System.Windows.Forms.Button; $btnDel.Text = "XOÁ DÒNG"; $btnDel.Location = "260,$yPos"; $btnDel.Size = "110,40"; $btnDel.BackColor = "#E57373"; $btnDel.ForeColor = "White"; $btnDel.FlatStyle = "Flat"; $btnDel.Font = $fontNut
    
    $btnPickWinget = New-Object System.Windows.Forms.Button; $btnPickWinget.Text = "🔍 DÒ WINGET"; $btnPickWinget.Location = "380,$yPos"; $btnPickWinget.Size = "180,40"; $btnPickWinget.BackColor = "#0288D1"; $btnPickWinget.ForeColor = "White"; $btnPickWinget.FlatStyle = "Flat"; $btnPickWinget.Font = $fontNut
    $btnPickChoco = New-Object System.Windows.Forms.Button; $btnPickChoco.Text = "🪄 DÒ CHOCO"; $btnPickChoco.Location = "570,$yPos"; $btnPickChoco.Size = "180,40"; $btnPickChoco.BackColor = "#9C27B0"; $btnPickChoco.ForeColor = "White"; $btnPickChoco.FlatStyle = "Flat"; $btnPickChoco.Font = $fontNut

    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "🚀 CẬP NHẬT DỮ LIỆU LÊN GITHUB CLOUD"; $btnPush.Size = "940,60"; $btnPush.Location = "20,620"; $btnPush.BackColor = "#0D47A1"; $btnPush.ForeColor = "White"; $btnPush.FlatStyle = "Flat"; $btnPush.Font = $fontNut

    $form.Controls.AddRange(@($grid, $lblN, $txtN, $lblW, $txtW, $lblC, $txtC, $lblG, $txtG, $lblS, $txtS, $btnAdd, $btnEdit, $btnDel, $btnPickWinget, $btnPickChoco, $btnPush))

    # --- HÀM DÒ ID ---
    function Show-ChocoPicker($appName) {
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) { return $null }
        $searchTerm = $appName -replace '\s+', '' -replace '[^a-zA-Z0-9\-]', ''
        $results = choco search "$searchTerm" --limit-output | Select-Object -First 10
        $picker = New-Object System.Windows.Forms.Form; $picker.Text = "Chọn Choco ID"; $picker.Size = "400,320"; $picker.StartPosition = "CenterParent"
        $lb = New-Object System.Windows.Forms.ListBox; $lb.Dock = "Top"; $lb.Height = 200
        foreach ($res in $results) { if ($res -match "\|") { [void]$lb.Items.Add($res.Split("|")[0]) } }
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "OK"; $btnOk.Dock = "Bottom"; $btnOk.DialogResult = "OK"
        $picker.Controls.AddRange(@($lb, $btnOk))
        if ($picker.ShowDialog() -eq "OK") { return $lb.SelectedItem }
        return $null
    }

    function Show-WingetPicker($appName) {
        if (!(Get-Command winget -ErrorAction SilentlyContinue)) { return $null }
        $env:WINGET_DISABLE_PROGRESS = "true"
        $raw = (winget search "$appName" --accept-source-agreements 2>&1) -join "`n"
        $results = @(); $lines = $raw -split "`n"; $start = $false
        foreach ($line in $lines) {
            if ($line -match "^---") { $start = $true; continue }
            if ($start -and $line.Trim() -ne "") {
                if ($line -match '(?<Name>.+?)\s+(?<Id>[a-zA-Z0-9]+\.[a-zA-Z0-9\.]+)\s+(?<Version>\S+)') {
                    $results += [PSCustomObject]@{ Id = $matches['Id'].Trim(); Name = $matches['Name'].Trim(); Ver = $matches['Version'].Trim() }
                }
            }
        }
        if ($results.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Không tìm thấy ID phù hợp!", "Lỗi"); return $null }
        $picker = New-Object System.Windows.Forms.Form; $picker.Text = "Chọn Winget ID"; $picker.Size = "500,350"; $picker.StartPosition = "CenterParent"
        $lb = New-Object System.Windows.Forms.ListBox; $lb.Dock = "Top"; $lb.Height = 250; $lb.Font = $fontNoiDung
        foreach ($r in $results) { [void]$lb.Items.Add("$($r.Id) | $($r.Name)") }
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "CHỐT ID"; $btnOk.Dock = "Bottom"; $btnOk.DialogResult = "OK"
        $picker.Controls.AddRange(@($lb, $btnOk))
        if ($picker.ShowDialog() -eq "OK" -and $lb.SelectedItem) { return $lb.SelectedItem.ToString().Split("|")[0].Trim() }
        return $null
    }

    # --- SỰ KIỆN NÚT ---
    $btnPickChoco.Add_Click({
        if ($grid.SelectedRows.Count -eq 0) { return }
        $id = Show-ChocoPicker $grid.SelectedRows[0].Cells['Name'].Value
        if ($id) { $grid.SelectedRows[0].Cells['ChocoID'].Value = $id; $txtC.Text = $id }
    })

    $btnPickWinget.Add_Click({
        if ($grid.SelectedRows.Count -eq 0) { return }
        $btnPickWinget.Text = "⏳ Đang dò..."; $btnPickWinget.Enabled = $false
        $id = Show-WingetPicker $grid.SelectedRows[0].Cells['Name'].Value
        if ($id) { $grid.SelectedRows[0].Cells['WingetID'].Value = $id; $txtW.Text = $id }
        $btnPickWinget.Text = "🔍 DÒ WINGET"; $btnPickWinget.Enabled = $true
    })

    function Reload-Admin {
        $grid.Rows.Clear()
        try {
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($response.content -replace "\s", "")))
            $csvData = $csvText.Trim().Trim([char]65279) | ConvertFrom-Csv
            foreach ($a in $csvData) { [void]$grid.Rows.Add(($a.Check -match "True"), $a.Name, $a.WingetID, $a.ChocoID, $a.GDriveID, $a.SilentArgs) }
        } catch {}
    }

    $grid.Add_SelectionChanged({
        if ($grid.SelectedRows.Count -gt 0) {
            $r = $grid.SelectedRows[0]; $txtN.Text = $r.Cells['Name'].Value; $txtW.Text = $r.Cells['WingetID'].Value
            $txtC.Text = $r.Cells['ChocoID'].Value; $txtG.Text = $r.Cells['GDriveID'].Value; $txtS.Text = $r.Cells['SilentArgs'].Value
        }
    })

    $btnAdd.Add_Click({ if ($txtN.Text) { [void]$grid.Rows.Add($true, $txtN.Text, $txtW.Text, $txtC.Text, $txtG.Text, $txtS.Text) } })
    $btnEdit.Add_Click({ if ($grid.SelectedRows.Count -gt 0) { $r=$grid.SelectedRows[0]; $r.Cells['Name'].Value=$txtN.Text; $r.Cells['WingetID'].Value=$txtW.Text; $r.Cells['ChocoID'].Value=$txtC.Text; $r.Cells['GDriveID'].Value=$txtG.Text; $r.Cells['SilentArgs'].Value=$txtS.Text } })
    $btnDel.Add_Click({ foreach ($r in $grid.SelectedRows) { $grid.Rows.Remove($r) } })

    $btnPush.Add_Click({
        try {
            $csv = "Check,Name,WingetID,ChocoID,GDriveID,SilentArgs`n"
            foreach ($r in $grid.Rows) { if ($r.Cells['Name'].Value) { $csv += "$($r.Cells['Check'].Value),$($r.Cells['Name'].Value),$($r.Cells['WingetID'].Value),$($r.Cells['ChocoID'].Value),$($r.Cells['GDriveID'].Value),$($r.Cells['SilentArgs'].Value)`n" } }
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $body = @{ message="Update V123"; content=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csv.Trim())); sha=$info.sha } | ConvertTo-Json
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật GitHub!"); Reload-Admin
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi!") }
    })

    Reload-Admin; $form.ShowDialog() | Out-Null
}

&$LogicVietToolboxCloudV123