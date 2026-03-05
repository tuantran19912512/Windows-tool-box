# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicCaiPhanMemFull = {
    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
    $tokenPath = Join-Path $env:TEMP "vt_cloud_token.txt"

    # --- FONT CHUẨN ---
    $fontTieuDe = New-Object System.Drawing.Font("Segoe UI Semibold", 14)
    $fontNut    = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho    = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    # --- HÀM HỎI TOKEN ---
    function Get-StoredToken {
        if (Test-Path $tokenPath) { 
            $tk = Get-Content $tokenPath -Raw
            if ($tk) { return $tk.Trim() }
        }
        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = "Kich hoat VietToolbox Cloud"; $inputForm.Size = "450,200"; $inputForm.StartPosition = "CenterScreen"; $inputForm.TopMost = $true
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Nhap ma GitHub Token de lam viec:"; $lbl.Location = "20,20"; $lbl.Size = "400,20"; $lbl.Font = $fontNoiDung
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20,50"; $txt.Size = "390,25"
        $btn = New-Object System.Windows.Forms.Button; $btn.Text = "KICH HOAT"; $btn.Location = "160,100"; $btn.Size = "120,35"; $btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $inputForm.Controls.AddRange(@($lbl, $txt, $btn))
        if ($inputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and $txt.Text) {
            $val = $txt.Text.Trim(); $val | Out-File $tokenPath -Encoding UTF8; return $val
        }
        return $null
    }

    $global:GH_TOKEN = Get-StoredToken
    if (!$global:GH_TOKEN) { return }

    # --- KHOI TAO FORM ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - QUAN LY PHAN MEM"; $form.Size = "1000,850"; $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"
    
    $tabControl = New-Object System.Windows.Forms.TabControl; $tabControl.Size = "960,750"; $tabControl.Location = "20,20"
    $tabInstall = New-Object System.Windows.Forms.TabPage; $tabInstall.Text = "CAI DAT"; $tabInstall.BackColor = "White"
    $tabAdmin = New-Object System.Windows.Forms.TabPage; $tabAdmin.Text = "QUAN TRI"; $tabAdmin.BackColor = "White"
    $tabControl.Controls.AddRange(@($tabInstall, $tabAdmin))
    $form.Controls.Add($tabControl)

    # --- [TAB 1: CAI DAT] ---
    $lvStore = New-Object System.Windows.Forms.ListView; $lvStore.Size = "910,450"; $lvStore.Location = "20,20"; $lvStore.View = "Details"; $lvStore.CheckBoxes = $true; $lvStore.FullRowSelect = $true; $lvStore.Font = $fontNoiDung; $lvStore.BorderStyle = "FixedSingle"
    [void]$lvStore.Columns.Add("TEN UNG DUNG", 480); [void]$lvStore.Columns.Add("TRANG THAI", 280); [void]$lvStore.Columns.Add("ID", 0)
    
    $lblProgress = New-Object System.Windows.Forms.Label; $lblProgress.Text = "San sang..."; $lblProgress.Location = "20,480"; $lblProgress.Size = "500,20"; $lblProgress.Font = $fontNho; $lblProgress.ForeColor = "Gray"
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,505"; $pgBar.Size = "910,20"; $pgBar.Style = "Continuous"
    
    $btnRelInst = New-Object System.Windows.Forms.Button; $btnRelInst.Text = "LAM MOI DANH SACH"; $btnRelInst.Size = "220,55"; $btnRelInst.Location = "340,560"; $btnRelInst.BackColor = "#455A64"; $btnRelInst.ForeColor = "White"; $btnRelInst.FlatStyle = "Flat"; $btnRelInst.Font = $fontNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "BAT DAU CAI DAT"; $btnInstall.Size = "350,55"; $btnInstall.Location = "580,560"; $btnInstall.BackColor = "#2196F3"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fontNut
    $tabInstall.Controls.AddRange(@($lvStore, $lblProgress, $pgBar, $btnRelInst, $btnInstall))

    # --- [TAB 2: QUAN TRI] ---
    $gridAdmin = New-Object System.Windows.Forms.DataGridView; $gridAdmin.Size = "920,300"; $gridAdmin.Location = "10,20"; $gridAdmin.AutoSizeColumnsMode = "Fill"; $gridAdmin.RowHeadersVisible = $false; $gridAdmin.BackgroundColor = "White"; $gridAdmin.BorderStyle = "None"
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="Mac dinh"}))
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="Ten Ung Dung"}))
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="ID";HeaderText="Winget ID"}))
    
    $lblLName = New-Object System.Windows.Forms.Label; $lblLName.Text = "Ten hien thi:"; $lblLName.Location = "10,335"; $lblLName.Size = "280,20"; $lblLName.Font = $fontNho; $lblLName.ForeColor = "Gray"
    $txtNewName = New-Object System.Windows.Forms.TextBox; $txtNewName.Location = "10,355"; $txtNewName.Size = "280,30"
    $lblLID = New-Object System.Windows.Forms.Label; $lblLID.Text = "Winget ID:"; $lblLID.Location = "300,335"; $lblLID.Size = "280,20"; $lblLID.Font = $fontNho; $lblLID.ForeColor = "Gray"
    $txtNewID = New-Object System.Windows.Forms.TextBox; $txtNewID.Location = "300,355"; $txtNewID.Size = "280,30"
    
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "THEM MOI"; $btnAdd.Location = "600,354"; $btnAdd.Size = "150,32"; $btnAdd.BackColor = "#4CAF50"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"; $btnAdd.Font = $fontNut
    $btnRelAdmin = New-Object System.Windows.Forms.Button; $btnRelAdmin.Text = "TAI LAI"; $btnRelAdmin.Location = "760,354"; $btnRelAdmin.Size = "150,32"; $btnRelAdmin.BackColor = "#455A64"; $btnRelAdmin.ForeColor = "White"; $btnRelAdmin.FlatStyle = "Flat"; $btnRelAdmin.Font = $fontNut
    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "CAP NHẬT DU LIEU LEN CLOUD"; $btnPush.Size = "920,60"; $btnPush.Location = "10,450"; $btnPush.BackColor = "#0D47A1"; $btnPush.ForeColor = "White"; $btnPush.Font = $fontNut; $btnPush.FlatStyle = "Flat"
    $tabAdmin.Controls.AddRange(@($gridAdmin, $lblLName, $txtNewName, $lblLID, $txtNewID, $btnAdd, $btnRelAdmin, $btnPush))

    # --- HAM TAI DU LIEU ---
    function Reload-Data {
        $lvStore.Items.Clear(); $gridAdmin.Rows.Clear()
        try {
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            if ($null -ne $response -and $null -ne $response.content) {
                $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($response.content -replace "\s", "")))
                $lines = $csvText.Trim().Trim([char]65279) -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
                $csvData = $lines | ConvertFrom-Csv
                foreach ($a in $csvData) {
                    if ($a.Name) {
                        $li = New-Object System.Windows.Forms.ListViewItem($a.Name); $li.Checked = ($a.Check -match "True")
                        [void]$li.SubItems.Add("San sang"); [void]$li.SubItems.Add($a.ID)
                        $lvStore.Items.Add($li); [void]$gridAdmin.Rows.Add($li.Checked, $a.Name, $a.ID)
                    }
                }
            }
        } catch {
            if ($_.Exception.Message -match "401") {
                if (Test-Path $tokenPath) { Remove-Item $tokenPath -Force }
                $global:GH_TOKEN = Get-StoredToken
                if ($global:GH_TOKEN) { Reload-Data }
            }
        }
    }

    # --- SU KIEN ---
    $btnRelInst.Add_Click({ Reload-Data })
    $btnRelAdmin.Add_Click({ Reload-Data })
    $btnAdd.Add_Click({ if ($txtNewName.Text) { [void]$gridAdmin.Rows.Add($true, $txtNewName.Text, $txtNewID.Text); $txtNewName.Text=""; $txtNewID.Text="" } })
    $btnPush.Add_Click({
        try {
            $csv = "Check,Name,ID`n" + (($gridAdmin.Rows | ForEach-Object { if ($_.Cells['Name'].Value) { "$($_.Cells['Check'].Value),$($_.Cells['Name'].Value),$($_.Cells['ID'].Value)" } }) -join "`n")
            $headers = @{"Authorization" = "token $global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $body = @{ message="Admin Update"; content=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csv.Trim())); sha=$info.sha } | ConvertTo-Json
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            [System.Windows.Forms.MessageBox]::Show("Da cap nhat thanh cong!"); Reload-Data
        } catch { if ($_.Exception.Message -match "401") { Reload-Data } }
    })

    $btnInstall.Add_Click({
        $items = @($lvStore.CheckedItems); if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false; $pgBar.Maximum = $items.Count; $pgBar.Value = 0
        for ($i=0; $i -lt $items.Count; $i++) {
            $item = $items[$i]; $lblProgress.Text = "Dang cai dat ($($i+1)/$($items.Count)): $($item.Text)..."
            $item.SubItems[1].Text = "Dang cai..."; [System.Windows.Forms.Application]::DoEvents()
            $p = Start-Process "winget" -ArgumentList "install --id `"$($item.SubItems[2].Text)`" --silent --accept-package-agreements" -PassThru -NoNewWindow
            while (-not $p.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 100 }
            $item.SubItems[1].Text = if ($p.ExitCode -eq 0) { "Hoan tat" } else { "Loi" }
            $pgBar.Value = $i + 1
        }
        $btnInstall.Enabled = $true; $lblProgress.Text = "Tat ca da hoan tat!"
    })

    Reload-Data
    $form.ShowDialog() | Out-Null
}

&$LogicCaiPhanMemFull