# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicCaiPhanMemFull = {
    # --- CẤU HÌNH GITHUB ---
    $GH_TOKEN = "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" 
    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"

    $apiUrl = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VietToolbox - App Store (Zero Delay Edition)"; $form.Size = "1000,820"; $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"

    $fontNhan = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $fontDam = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

    $tabControl = New-Object System.Windows.Forms.TabControl; $tabControl.Size = "960,720"; $tabControl.Location = "20,20"
    $tabInstall = New-Object System.Windows.Forms.TabPage; $tabInstall.Text = "Cài Đặt"; $tabInstall.BackColor = "White"
    $tabAdmin = New-Object System.Windows.Forms.TabPage; $tabAdmin.Text = "Quản Trị"; $tabAdmin.BackColor = "White"
    $tabControl.Controls.AddRange(@($tabInstall, $tabAdmin))
    $form.Controls.Add($tabControl)

    # --- TAB 1: STORE UI ---
    $lvStore = New-Object System.Windows.Forms.ListView
    $lvStore.Size = "910,480"; $lvStore.Location = "20,20"; $lvStore.View = [System.Windows.Forms.View]::Details
    $lvStore.FullRowSelect = $true; $lvStore.CheckBoxes = $true; $lvStore.BorderStyle = "FixedSingle"; $lvStore.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    [void]$lvStore.Columns.Add("Tên Ứng Dụng", 500); [void]$lvStore.Columns.Add("Trạng thái", 300); [void]$lvStore.Columns.Add("ID", 0) 
    $tabInstall.Controls.Add($lvStore)

    $lblProgress = New-Object System.Windows.Forms.Label; $lblProgress.Text = "Sẵn sàng..."; $lblProgress.Location = "20,510"; $lblProgress.Size = "500,20"; $lblProgress.Font = $fontNhan
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,535"; $pgBar.Size = "910,20"
    
    $btnReloadInstall = New-Object System.Windows.Forms.Button; $btnReloadInstall.Text = "🔄 LÀM MỚI DANH SÁCH"; $btnReloadInstall.Size = "220,60"; $btnReloadInstall.Location = "340,580"; $btnReloadInstall.BackColor = "#6C757D"; $btnReloadInstall.ForeColor = "White"; $btnReloadInstall.FlatStyle = "Flat"; $btnReloadInstall.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnInstallStore = New-Object System.Windows.Forms.Button; $btnInstallStore.Text = "🚀 BẮT ĐẦU CÀI ĐẶT"; $btnInstallStore.Size = "350,60"; $btnInstallStore.Location = "580,580"; $btnInstallStore.BackColor = "#0068FF"; $btnInstallStore.ForeColor = "White"; $btnInstallStore.FlatStyle = "Flat"; $btnInstallStore.Font = $fontDam
    
    $tabInstall.Controls.AddRange(@($lblProgress, $pgBar, $btnReloadInstall, $btnInstallStore))

    # --- TAB 2: ADMIN UI ---
    $gridAdmin = New-Object System.Windows.Forms.DataGridView; $gridAdmin.Size = "920,320"; $gridAdmin.Location = "10,20"; $gridAdmin.AutoSizeColumnsMode = "Fill"; $gridAdmin.RowHeadersVisible = $false; $gridAdmin.BackgroundColor = "White"
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name="Check";HeaderText="Mặc định"}))
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="Name";HeaderText="Tên Phần Mềm"}))
    [void]$gridAdmin.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{Name="ID";HeaderText="ID"}))
    $tabAdmin.Controls.Add($gridAdmin)

    $lblTen = New-Object System.Windows.Forms.Label; $lblTen.Text = "Tên hiển thị:"; $lblTen.Location = "10,355"; $lblTen.Size = "280,20"; $lblTen.Font = $fontNhan; $lblTen.ForeColor = "Gray"
    $txtNewName = New-Object System.Windows.Forms.TextBox; $txtNewName.Location = "10,380"; $txtNewName.Size = "280,30"
    $lblID = New-Object System.Windows.Forms.Label; $lblID.Text = "Winget ID:"; $lblID.Location = "300,355"; $lblID.Size = "280,20"; $lblID.Font = $fontNhan; $lblID.ForeColor = "Gray"
    $txtNewID = New-Object System.Windows.Forms.TextBox; $txtNewID.Location = "300,380"; $txtNewID.Size = "280,30"
    $btnAddRow = New-Object System.Windows.Forms.Button; $btnAddRow.Text = "➕ THÊM"; $btnAddRow.Location = "600,378"; $btnAddRow.Size = "150,32"; $btnAddRow.BackColor = "#2ECC71"; $btnAddRow.ForeColor = "White"; $btnAddRow.FlatStyle = "Flat"
    $btnReloadAdmin = New-Object System.Windows.Forms.Button; $btnReloadAdmin.Text = "🔄 LÀM MỚI"; $btnReloadAdmin.Location = "760,378"; $btnReloadAdmin.Size = "150,32"; $btnReloadAdmin.BackColor = "#6C757D"; $btnReloadAdmin.ForeColor = "White"; $btnReloadAdmin.FlatStyle = "Flat"
    $btnPushCloud = New-Object System.Windows.Forms.Button; $btnPushCloud.Text = "☁️ CẬP NHẬT LÊN CLOUD (GITHUB)"; $btnPushCloud.Size = "920,60"; $btnPushCloud.Location = "10,480"; $btnPushCloud.BackColor = "#1A2B4C"; $btnPushCloud.ForeColor = "White"; $btnPushCloud.Font = $fontDam; $btnPushCloud.FlatStyle = "Flat"
    $tabAdmin.Controls.AddRange(@($lblTen, $txtNewName, $lblID, $txtNewID, $btnAddRow, $btnReloadAdmin, $btnPushCloud))

    # --- [CẢI TIẾN QUAN TRỌNG]: HÀM TẢI DỮ LIỆU QUA API (ZERO CACHE) ---
    function Reload-Data {
        $lvStore.Items.Clear(); $gridAdmin.Rows.Clear()
        try {
            $headers = @{"Authorization" = "token $GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            # Gọi thẳng vào API thay vì link Raw để tránh cache
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            
            # Giải mã Base64 từ API trả về
            $base64Content = $response.content -replace "`n", "" -replace "`r", ""
            $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Content))
            
            if (-not [string]::IsNullOrWhiteSpace($csvText)) {
                $cleanRaw = $csvText.Trim().Trim([char]65279)
                $lines = $cleanRaw -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
                if ($lines.Count -gt 0) {
                    $delim = if ($lines[0] -match ";") { ";" } else { "," }
                    $csvData = $lines | ConvertFrom-Csv -Delimiter $delim
                    foreach ($a in $csvData) {
                        if ($a.Name) {
                            $chkValue = ($a.Check -match "True")
                            $li = New-Object System.Windows.Forms.ListViewItem($a.Name); $li.Checked = $chkValue
                            [void]$li.SubItems.Add("Sẵn sàng"); [void]$li.SubItems.Add($a.ID)
                            $lvStore.Items.Add($li)
                            [void]$gridAdmin.Rows.Add($chkValue, $a.Name, $a.ID)
                        }
                    }
                }
            }
        } catch { 
            [System.Windows.Forms.MessageBox]::Show("Lỗi: Không thể kết nối API GitHub. Kiểm tra Token!")
        }
    }

    # --- SỰ KIỆN NÚT BẤM ---
    $btnReloadInstall.Add_Click({ Reload-Data })
    $btnReloadAdmin.Add_Click({ Reload-Data })
    $btnAddRow.Add_Click({ if ($txtNewName.Text) { [void]$gridAdmin.Rows.Add($true, $txtNewName.Text, $txtNewID.Text); $txtNewName.Text=""; $txtNewID.Text="" } })

    $btnPushCloud.Add_Click({
        try {
            $csvText = "Check,Name,ID`n"
            foreach($row in $gridAdmin.Rows) { if ($row.Cells["Name"].Value) { $csvText += "$($row.Cells['Check'].Value),$($row.Cells['Name'].Value),$($row.Cells['ID'].Value)`n" } }
            $headers = @{"Authorization" = "token $GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $body = @{ message="Admin Update"; content=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csvText.Trim())); sha=$info.sha } | ConvertTo-Json
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            [System.Windows.Forms.MessageBox]::Show("Đã cập nhật Cloud! Dữ liệu sẽ được làm mới ngay lập tức.")
            Reload-Data # Tự động load lại sau khi push
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: $($_.Exception.Message)") }
    })

    $btnInstallStore.Add_Click({
        $items = @($lvStore.CheckedItems)
        if ($items.Count -eq 0) { return }
        $btnInstallStore.Enabled = $false; $pgBar.Maximum = $items.Count; $pgBar.Value = 0; $count = 0
        foreach ($item in $items) {
            $count++; $lblProgress.Text = "Đang cài ($count/$($items.Count)): $($item.Text)..."
            $item.SubItems[1].Text = "⏳ Đang cài..."; $item.BackColor = [System.Drawing.Color]::LightYellow; [System.Windows.Forms.Application]::DoEvents()
            $p = Start-Process "winget" -ArgumentList "install --id `"$($item.SubItems[2].Text)`" --silent --accept-package-agreements" -PassThru -NoNewWindow
            while (-not $p.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 100 }
            $item.SubItems[1].Text = if ($p.ExitCode -eq 0) { "✅ Xong" } else { "⚠️ Lỗi" }
            $item.BackColor = if ($p.ExitCode -eq 0) { [System.Drawing.Color]::LightGreen } else { [System.Drawing.Color]::White }
            $pgBar.Value = $count
        }
        $btnInstallStore.Enabled = $true; $lblProgress.Text = "Cài đặt hoàn tất!"
    })

    Reload-Data
    $form.ShowDialog() | Out-Null
}

&$LogicCaiPhanMemFull