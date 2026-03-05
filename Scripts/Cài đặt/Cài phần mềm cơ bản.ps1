# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicCaiPhanMemFull = {
    # --- THÔNG TIN GITHUB ---
    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
    
    # File lưu Token nội bộ (Cùng thư mục với Tool)
    $tokenPath = Join-Path $PSScriptRoot "token.txt"

    # HÀM LẤY HOẶC HỎI TOKEN (CHỈ HỎI 1 LẦN TRÊN MÁY MỚI)
    function Get-StoredToken {
        if (Test-Path $tokenPath) { return Get-Content $tokenPath -Raw }
        
        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = "Kích hoạt VietToolbox Cloud"; $inputForm.Size = "450,200"; $inputForm.StartPosition = "CenterScreen"
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Vui lòng dán GitHub Token để nạp dữ liệu phần mềm:"; $lbl.Location = "20,20"; $lbl.Size = "400,20"
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20,50"; $txt.Size = "390,25"
        $btn = New-Object System.Windows.Forms.Button; $btn.Text = "KÍCH HOẠT"; $btn.Location = "160,100"; $btn.Size = "120,35"; $btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $inputForm.Controls.AddRange(@($lbl, $txt, $btn))
        
        if ($inputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and $txt.Text -ne "") {
            $txt.Text.Trim() | Out-File $tokenPath
            return $txt.Text.Trim()
        }
        return ""
    }

    $GH_TOKEN = Get-StoredToken
    if ([string]::IsNullOrEmpty($GH_TOKEN)) { return }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VietToolbox - App Store (Deployment Edition)"; $form.Size = "1000,850"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"

    $fontNhan = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $fontDam = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

    $tabControl = New-Object System.Windows.Forms.TabControl; $tabControl.Size = "960,750"; $tabControl.Location = "20,20"
    $tabInstall = New-Object System.Windows.Forms.TabPage; $tabInstall.Text = "🚀 Cài Đặt"; $tabInstall.BackColor = "White"
    $tabAdmin = New-Object System.Windows.Forms.TabPage; $tabAdmin.Text = "⚙️ Quản Trị"; $tabAdmin.BackColor = "White"
    $tabControl.Controls.AddRange(@($tabInstall, $tabAdmin))
    $form.Controls.Add($tabControl)

    # --- TAB 1: STORE UI ---
    $lvStore = New-Object System.Windows.Forms.ListView
    $lvStore.Size = "910,450"; $lvStore.Location = "20,20"; $lvStore.View = [System.Windows.Forms.View]::Details
    $lvStore.FullRowSelect = $true; $lvStore.CheckBoxes = $true; $lvStore.BorderStyle = "FixedSingle"; $lvStore.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    [void]$lvStore.Columns.Add("Tên Ứng Dụng", 500); [void]$lvStore.Columns.Add("Trạng thái", 300); [void]$lvStore.Columns.Add("ID", 0) 
    
    $lblProgress = New-Object System.Windows.Forms.Label; $lblProgress.Text = "Sẵn sàng..."; $lblProgress.Location = "20,480"; $lblProgress.Size = "500,20"; $lblProgress.Font = $fontNhan
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,505"; $pgBar.Size = "910,25"; $pgBar.Style = "Continuous"
    $btnRelInst = New-Object System.Windows.Forms.Button; $btnRelInst.Text = "🔄 CẬP NHẬT"; $btnRelInst.Size = "220,60"; $btnRelInst.Location = "340,560"; $btnRelInst.BackColor = "#6C757D"; $btnRelInst.ForeColor = "White"; $btnRelInst.FlatStyle = "Flat"
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "🚀 CÀI ĐẶT NGAY"; $btnInstall.Size = "350,60"; $btnInstall.Location = "580,560"; $btnInstall.BackColor = "#0068FF"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fontDam
    $tabInstall.Controls.AddRange(@($lvStore, $lblProgress, $pgBar, $btnRelInst, $btnInstall))

    # --- TAB 2: ADMIN UI ---
    $gridAdmin = New-Object System.Windows.Forms.DataGridView; $gridAdmin.Size = "920,300"; $gridAdmin.Location = "10,20"; $gridAdmin.AutoSizeColumnsMode = "Fill"; $gridAdmin.RowHeadersVisible = $false; $gridAdmin.BackgroundColor = "White"
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="Mặc định"}))
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="Tên Phần Mềm"}))
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="ID";HeaderText="ID"}))
    
    $lblLabelName = New-Object System.Windows.Forms.Label; $lblLabelName.Text = "Tên hiển thị:"; $lblLabelName.Location = "10,335"; $lblLabelName.Size = "280,20"; $lblLabelName.Font = $fontNhan; $lblLabelName.ForeColor = "Gray"
    $txtNewName = New-Object System.Windows.Forms.TextBox; $txtNewName.Location = "10,360"; $txtNewName.Size = "280,30"
    $lblLabelID = New-Object System.Windows.Forms.Label; $lblLabelID.Text = "Winget ID:"; $lblLabelID.Location = "300,335"; $lblLabelID.Size = "280,20"; $lblLabelID.Font = $fontNhan; $lblLabelID.ForeColor = "Gray"
    $txtNewID = New-Object System.Windows.Forms.TextBox; $txtNewID.Location = "300,360"; $txtNewID.Size = "280,30"
    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "➕ THÊM"; $btnAdd.Location = "600,358"; $btnAdd.Size = "150,32"; $btnAdd.BackColor = "#2ECC71"; $btnAdd.ForeColor = "White"; $btnAdd.FlatStyle = "Flat"
    $btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "☁️ CẬP NHẬT LÊN GITHUB CLOUD"; $btnPush.Size = "920,60"; $btnPush.Location = "10,450"; $btnPush.BackColor = "#1A2B4C"; $btnPush.ForeColor = "White"; $btnPush.Font = $fontDam; $btnPush.FlatStyle = "Flat"
    
    $tabAdmin.Controls.AddRange(@($gridAdmin, $lblLabelName, $txtNewName, $lblLabelID, $txtNewID, $btnAdd, $btnPush))

    # --- HÀM TẢI DỮ LIỆU QUA API (MỚI NHẤT) ---
    function Reload-Data {
        $lvStore.Items.Clear(); $gridAdmin.Rows.Clear()
        try {
            $headers = @{"Authorization" = "token $GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($response.content -replace "\s", "")))
            if ($csvText) {
                $lines = $csvText.Trim().Trim([char]65279) -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
                $csvData = $lines | ConvertFrom-Csv
                foreach ($a in $csvData) {
                    if ($a.Name) {
                        $chk = ($a.Check -match "True"); $li = New-Object System.Windows.Forms.ListViewItem($a.Name); $li.Checked = $chk
                        [void]$li.SubItems.Add("Sẵn sàng"); [void]$li.SubItems.Add($a.ID)
                        $lvStore.Items.Add($li); [void]$gridAdmin.Rows.Add($chk, $a.Name, $a.ID)
                    }
                }
            }
        } catch { }
    }

    # --- SỰ KIỆN ---
    $btnRelInst.Add_Click({ Reload-Data })
    $btnAdd.Add_Click({ if ($txtNewName.Text) { [void]$gridAdmin.Rows.Add($true, $txtNewName.Text, $txtNewID.Text); $txtNewName.Text=""; $txtNewID.Text="" } })
    $btnPush.Add_Click({
        try {
            $csv = "Check,Name,ID`n" + (($gridAdmin.Rows | ForEach-Object { if ($_.Cells['Name'].Value) { "$($_.Cells['Check'].Value),$($_.Cells['Name'].Value),$($_.Cells['ID'].Value)" } }) -join "`n")
            $headers = @{"Authorization" = "token $GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $body = @{ message="Deploy Sync"; content=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csv.Trim())); sha=$info.sha } | ConvertTo-Json
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật Cloud!"); Reload-Data
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi Token hoặc API!") }
    })

    $btnInstall.Add_Click({
        $items = @($lvStore.CheckedItems); if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false; $pgBar.Maximum = $items.Count; $pgBar.Value = 0
        for ($i=0; $i -lt $items.Count; $i++) {
            $item = $items[$i]; $lblProgress.Text = "Đang cài ($($i+1)/$($items.Count)): $($item.Text)..."
            $item.SubItems[1].Text = "⏳ Đang cài..."; $item.BackColor = [System.Drawing.Color]::LightYellow; [System.Windows.Forms.Application]::DoEvents()
            $p = Start-Process "winget" -ArgumentList "install --id `"$($item.SubItems[2].Text)`" --silent --accept-package-agreements" -PassThru -NoNewWindow
            while (-not $p.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 100 }
            $item.SubItems[1].Text = if ($p.ExitCode -eq 0) { "✅ Xong" } else { "⚠️ Lỗi" }; $item.BackColor = if ($p.ExitCode -eq 0) { [System.Drawing.Color]::LightGreen } else { [System.Drawing.Color]::White }
            $pgBar.Value = $i + 1
        }
        $btnInstall.Enabled = $true; $lblProgress.Text = "Hoàn tất!"
    })

    Reload-Data
    $form.ShowDialog() | Out-Null
}

&$LogicCaiPhanMemFull