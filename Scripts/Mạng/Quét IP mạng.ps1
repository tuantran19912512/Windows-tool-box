[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicIPScannerV4_3 = {
    # --- KHỞI TẠO GIAO DIỆN ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX IP SCANNER V4.3 - SOI ĐƯỢC CẢ MAC MÁY MÌNH"; $form.Size = "980,620"; $form.BackColor = "#1E1E1E"; $form.StartPosition = "CenterScreen"
    $fontNut = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fontChu = New-Object System.Drawing.Font("Segoe UI", 10)

    $lblSubnet = New-Object System.Windows.Forms.Label; $lblSubnet.Text = "Các dải mạng (cách nhau bằng dấu phẩy):"; $lblSubnet.Location = "20,22"; $lblSubnet.ForeColor = "#00D4FF"; $lblSubnet.Size = "280,20"; $lblSubnet.Font = $fontChu
    $txtSubnet = New-Object System.Windows.Forms.TextBox; $txtSubnet.Location = "300,20"; $txtSubnet.Size = "270,25"; $txtSubnet.BackColor = "#2D2D2D"; $txtSubnet.ForeColor = "White"; $txtSubnet.Font = $fontNut

    $myIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi, Ethernet -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -match "^(192\.168|10\.|172\.)" } | Select-Object -First 1).IPAddress
    if ($myIp) { $txtSubnet.Text = $myIp.Substring(0, $myIp.LastIndexOf('.')) } else { $txtSubnet.Text = "192.168.1" }

    $btnScan = New-Object System.Windows.Forms.Button; $btnScan.Text = "🚀 BẮT ĐẦU QUÉT"; $btnScan.Location = "580,15"; $btnScan.Size = "170,35"; $btnScan.BackColor = "#D35400"; $btnScan.ForeColor = "White"; $btnScan.FlatStyle = "Flat"; $btnScan.Font = $fontNut
    $btnStop = New-Object System.Windows.Forms.Button; $btnStop.Text = "🛑 DỪNG LẠI"; $btnStop.Location = "760,15"; $btnStop.Size = "180,35"; $btnStop.BackColor = "#C0392B"; $btnStop.ForeColor = "White"; $btnStop.FlatStyle = "Flat"; $btnStop.Font = $fontNut; $btnStop.Enabled = $false

    $btnScan.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnStop.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnScan.Add_MouseEnter({ if ($this.Enabled) { $this.BackColor = "#E67E22" } })
    $btnScan.Add_MouseLeave({ if ($this.Enabled) { $this.BackColor = "#D35400" } })
    $btnStop.Add_MouseEnter({ if ($this.Enabled) { $this.BackColor = "#E74C3C" } })
    $btnStop.Add_MouseLeave({ if ($this.Enabled) { $this.BackColor = "#C0392B" } })

    $lv = New-Object System.Windows.Forms.ListView; $lv.Size = "920,400"; $lv.Location = "20,70"; $lv.View = "Details"; $lv.FullRowSelect = $true; $lv.Font = $fontChu; $lv.BackColor = "#252526"; $lv.ForeColor = "#E0E0E0"; $lv.BorderStyle = "FixedSingle"
    [void]$lv.Columns.Add("TRẠNG THÁI", 90); [void]$lv.Columns.Add("ĐỊA CHỈ IP", 130); [void]$lv.Columns.Add("TÊN MÁY (HOSTNAME)", 220); [void]$lv.Columns.Add("MAC ADDRESS", 160); [void]$lv.Columns.Add("NHÀ CUNG CẤP", 280)

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Mẹo: Nhấp đúp vào 1 dòng để mở trang cấu hình Web."; $lblStatus.Location = "20,480"; $lblStatus.Size = "920,20"; $lblStatus.ForeColor = "#AAAAAA"; $lblStatus.Font = $fontChu
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,510"; $pgBar.Size = "920,20"; $pgBar.Style = "Continuous"

    $form.Controls.AddRange(@($lblSubnet, $txtSubnet, $btnScan, $btnStop, $lv, $lblStatus, $pgBar))

    $lv.Add_DoubleClick({
        if ($lv.SelectedItems.Count -gt 0) {
            $selectedIp = $lv.SelectedItems[0].SubItems[1].Text
            try { Start-Process "http://$selectedIp" } catch { }
        }
    })

    $global:DungQuet = $false

    $btnStop.Add_Click({
        $global:DungQuet = $true
        $btnStop.Enabled = $false; $btnStop.BackColor = "#C0392B"
        $lblStatus.Text = "🛑 Đã nhận lệnh phanh khẩn cấp! Đang dừng lại..."
        $lblStatus.ForeColor = "Red"
    })

    $btnScan.Add_Click({
        $btnScan.Enabled = $false; $btnStop.Enabled = $true; $global:DungQuet = $false; $btnScan.BackColor = "#D35400"
        $lv.Items.Clear(); $pgBar.Value = 0
        
        function Wait-Smart($ms) {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            while ($timer.ElapsedMilliseconds -lt $ms) {
                if ($global:DungQuet) { break } 
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 10
            }
            $timer.Stop()
        }

        $rawSubnets = $txtSubnet.Text -split ","
        $cleanSubnets = @()
        foreach ($s in $rawSubnets) { if ($s.Trim() -ne "") { $cleanSubnets += $s.Trim() } }
        
        if ($cleanSubnets.Count -eq 0) {
            $lblStatus.Text = "Chưa nhập dải mạng!"; $lblStatus.ForeColor = "Red"; $btnScan.Enabled = $true; $btnStop.Enabled = $false; return
        }

        $lblStatus.Text = "Đang rải thảm Ping... Giao diện giờ đã mượt mà, bấm Dừng thoải mái!"
        $lblStatus.ForeColor = "#00D4FF"; $form.Refresh()

        $Tasks = New-Object System.Collections.ArrayList
        foreach ($subnet in $cleanSubnets) {
            if ($global:DungQuet) { break }
            1..254 | ForEach-Object {
                if ($global:DungQuet) { break }
                $ip = "$subnet.$_"
                $ping = New-Object System.Net.NetworkInformation.Ping
                [void]$Tasks.Add([PSCustomObject]@{ IP = $ip; Task = $ping.SendPingAsync($ip, 1000) })
                if ($_ % 20 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
            }
        }

        while (-not $global:DungQuet) {
            $isDone = $true
            foreach ($t in $Tasks) { if (-not $t.Task.IsCompleted) { $isDone = $false; break } }
            if ($isDone) { break }
            [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50
        }

        $Alive = $Tasks | Where-Object { $_.Task.Status -eq 'RanToCompletion' -and $_.Task.Result.Status -eq 'Success' }
        
        if ($Alive.Count -eq 0 -and -not $global:DungQuet) {
            $lblStatus.Text = "Không tìm thấy thiết bị nào đang bật!"; $lblStatus.ForeColor = "Red"; $btnScan.Enabled = $true; $btnStop.Enabled = $false; return
        }

        if (-not $global:DungQuet) {
            $lblStatus.Text = "Tìm thấy $($Alive.Count) thiết bị! Đang soi MAC và API..."
            $pgBar.Maximum = $Alive.Count; $pgBar.Value = 0
        }

        $webAPI = New-Object System.Net.WebClient; $webAPI.Headers.Add("User-Agent", "VietToolbox")

        foreach ($item in $Alive) {
            if ($global:DungQuet) { break }

            $ip = $item.IP
            $li = New-Object System.Windows.Forms.ListViewItem("🟢 Online")
            $li.ForeColor = [System.Drawing.Color]::LimeGreen
            [void]$li.SubItems.Add($ip); [void]$li.SubItems.Add("..."); [void]$li.SubItems.Add("..."); [void]$li.SubItems.Add("Đang tra API...")
            $lv.Items.Add($li); $lv.Refresh(); [System.Windows.Forms.Application]::DoEvents()

            try { $li.SubItems[2].Text = [System.Net.Dns]::GetHostEntry($ip).HostName } catch { $li.SubItems[2].Text = "Không xác định" }

            $mac = ""
            
            # --- TỰ SOI GƯƠNG LẤY MAC MÁY MÌNH ---
            $isLocal = Get-NetIPAddress -IPAddress $ip -ErrorAction SilentlyContinue
            if ($isLocal) {
                $localMac = (Get-NetAdapter -InterfaceIndex $isLocal.InterfaceIndex -ErrorAction SilentlyContinue).MacAddress
                if ($localMac) { $mac = $localMac -replace '-',':' }
            } else {
                # Nếu không phải máy mình thì đi hỏi hàng xóm
                $arp = arp -a $ip | Select-String -Pattern "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})"
                if ($arp) { $mac = $arp.Matches.Value.ToUpper() -replace '-',':' }
            }
            # ------------------------------------

            if ($mac) { $li.SubItems[3].Text = $mac } else { $li.SubItems[3].Text = "Không có" }

            if ($mac) {
                try {
                    $li.SubItems[4].Text = $webAPI.DownloadString("https://api.macvendors.com/$mac")
                    Wait-Smart 500 
                } catch { $li.SubItems[4].Text = "Không có thông tin" }
            } else { $li.SubItems[4].Text = "Bỏ qua" }

            $li.ForeColor = [System.Drawing.Color]::White; $lv.Refresh(); [System.Windows.Forms.Application]::DoEvents()
            $pgBar.Value++
        }

        if ($global:DungQuet) {
            $lblStatus.Text = "🛑 ĐÃ DỪNG LẠI!"
            $lblStatus.ForeColor = "#C0392B"
        } else {
            $lblStatus.Text = "✅ XONG! Tìm thấy $($Alive.Count) thiết bị."
            $lblStatus.ForeColor = "#00FF00"
        }
        $btnScan.Enabled = $true; $btnStop.Enabled = $false
    })

    $form.ShowDialog() | Out-Null
}

&$LogicIPScannerV4_3