[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if ($Host.Name -eq "ConsoleHost") { $Size = $Host.UI.RawUI.BufferSize; $Size.Height = 5000; $Host.UI.RawUI.BufferSize = $Size }
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- LÕI SENDARP TẦNG VẬT LÝ ---
$Signature = '[DllImport("iphlpapi.dll", ExactSpelling=true)] public static extern int SendARP(uint DestIP, uint SrcIP, byte[] pMacAddr, ref uint PhyAddrLen);'
try { Add-Type -MemberDefinition $Signature -Name "Win32" -Namespace "Net" -ErrorAction SilentlyContinue } catch {}

$LogicIPScannerV12 = {
    $Global:TokenL = "01kknht6atwchhnagzkaq9z4qc01kknhtqtw0pzkwm2nm5dp5dshkvux5avpst6e"
    $Global:TokenV = "EyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiIsImp0aSI6ImI0NmYyN2FlLWY4N2EtNGQwNi1iYmM3LTA5MjJlZWRmMGEzZSJ9.eyJpc3MiOiJtYWN2ZW5kb3JzIiwiYXVkIjoibWFjdmVuZG9ycyIsImp0aSI6ImI0NmYyN2FlLWY4N2EtNGQwNi1iYmM3LTA5MjJlZWRmMGEzZSIsImlhdCI6MTc3MzQyMjMyMywiZXhwIjoyMDg3OTE4MzIzLCJzdWIiOiIxNzMwNiIsInR5cCI6ImFjY2VzcyJ9.dG7S9_1o8fOnH5EnZjZUrc332dAHn-kGbqbRAaeutjTcVrwfQ-X7Zl1SaMkN4zIjtZ26jjQG2lCnzZWtzO8oNQ"
    $Global:MacOfflineDB = @{}

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX IP SCANNER V12 - VENDOR HUNTER (FIX UNKNOWN)"; $form.Size = "1050,750"; $form.BackColor = "#1E1E1E"; $form.StartPosition = "CenterScreen"
    $fNut = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fChu = New-Object System.Drawing.Font("Segoe UI", 10); $fGuide = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    # UI INPUT & GUIDE
    $lblSub = New-Object System.Windows.Forms.Label; $lblSub.Text = "Nhập IP quét:"; $lblSub.Location = "20,22"; $lblSub.ForeColor = "#00D4FF"; $lblSub.Size = "100,20"; $lblSub.Font = $fChu
    $txtSub = New-Object System.Windows.Forms.TextBox; $txtSub.Location = "130,20"; $txtSub.Size = "400,25"; $txtSub.BackColor = "#2D2D2D"; $txtSub.ForeColor = "White"; $txtSub.Font = $fNut
    $lblGuide = New-Object System.Windows.Forms.Label; $lblGuide.Text = "VD: 192.168.1 (Dải) | 192.168.1.10-50 (Đoạn) | 192.168.1.5 (Lẻ)"; $lblGuide.Location = "130,50"; $lblGuide.Size = "500,20"; $lblGuide.ForeColor = "#888888"; $lblGuide.Font = $fGuide

    $myIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi, Ethernet -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -match "^(192\.168|10\.|172\.)" } | Select-Object -First 1).IPAddress
    $txtSub.Text = if ($myIp) { $myIp.Substring(0, $myIp.LastIndexOf('.')) } else { "192.168.1" }

    $btnScan = New-Object System.Windows.Forms.Button; $btnScan.Text = "QUÉT NGAY"; $btnScan.Location = "550,15"; $btnScan.Size = "140,35"; $btnScan.BackColor = "#D35400"; $btnScan.ForeColor = "White"; $btnScan.FlatStyle = "Flat"; $btnScan.Font = $fNut; $btnScan.Enabled = $false
    $btnStop = New-Object System.Windows.Forms.Button; $btnStop.Text = "DỪNG"; $btnStop.Location = "700,15"; $btnStop.Size = "120,35"; $btnStop.BackColor = "#C0392B"; $btnStop.ForeColor = "White"; $btnStop.FlatStyle = "Flat"; $btnStop.Font = $fNut; $btnStop.Enabled = $false

    $lv = New-Object System.Windows.Forms.ListView; $lv.Size = "990,450"; $lv.Location = "20,85"; $lv.View = "Details"; $lv.FullRowSelect = $true; $lv.Font = $fChu; $lv.BackColor = "#252526"; $lv.ForeColor = "#E0E0E0"; $lv.BorderStyle = "FixedSingle"
    $BindingFlags = [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Instance
    $lv.GetType().GetProperty("DoubleBuffered", $BindingFlags).SetValue($lv, $true, $null)

    [void]$lv.Columns.Add("TRẠNG THÁI", 90); [void]$lv.Columns.Add("ĐỊA CHỈ IP", 140); [void]$lv.Columns.Add("TÊN THIẾT BỊ", 210); [void]$lv.Columns.Add("HÃNG SẢN XUẤT", 320); [void]$lv.Columns.Add("MAC ADDRESS", 170)

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Đang tải dữ liệu..."; $lblStatus.Location = "20,550"; $lblStatus.Size = "990,20"; $lblStatus.ForeColor = "Cyan"; $lblStatus.Font = $fChu
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,580"; $pgBar.Size = "990,20"

    $form.Controls.AddRange(@($lblSub, $txtSub, $lblGuide, $btnScan, $btnStop, $lv, $lblStatus, $pgBar))

    # Tải Offline DB & Deep Parser
    $form.Add_Shown({
        try {
            $dbUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/Scripts/M%E1%BA%A1ng/mac_interval_tree.txt"
            $raw = (New-Object System.Net.WebClient).DownloadString($dbUrl)
            foreach ($line in ($raw -split "`n")) {
                if ($line -match "^\s*([0-9A-Fa-f]{6})\s+[`"']?(.+?)[`"']?\s*$") {
                    $Global:MacOfflineDB[$matches[1].ToUpper()] = $matches[2].Trim()
                }
            }
            $lblStatus.Text = "✅ DB Offline OK ($($Global:MacOfflineDB.Count) hãng)."; $btnScan.Enabled = $true
        } catch { $lblStatus.Text = "⚠️ Lỗi tải DB Offline!"; $btnScan.Enabled = $true }
    })

    $SyncHash = [hashtable]::Synchronized(@{ Queue = [System.Collections.Concurrent.ConcurrentQueue[psobject]]::new(); TokenL = $Global:TokenL; TokenV = $Global:TokenV; DB = $Global:MacOfflineDB; Cancel = $false; Cache = [hashtable]::Synchronized(@{}) })
    $script:Jobs = @(); $script:Pool = $null

    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 100
    $timer.Add_Tick({
        $completed = 0; foreach ($j in $script:Jobs) { if ($j.Handle.IsCompleted) { $completed++ } }
        $pgBar.Value = $completed
        $obj = $null
        while ($SyncHash.Queue.TryDequeue([ref]$obj)) {
            $li = New-Object System.Windows.Forms.ListViewItem("ONLINE")
            $li.ForeColor = [System.Drawing.Color]::LimeGreen
            [void]$li.SubItems.Add($obj.IP); [void]$li.SubItems.Add($obj.Name); [void]$li.SubItems.Add($obj.Vendor); [void]$li.SubItems.Add($obj.MAC)
            $lv.Items.Add($li)
        }
        if ($script:Jobs.Count -gt 0 -and $completed -ge $script:Jobs.Count) {
            $timer.Stop()
            $lv.BeginUpdate()
            $items = @($lv.Items); $lv.Items.Clear()
            $sorted = $items | Sort-Object { if ($_.SubItems[2].Text -eq $_.SubItems[1].Text) { 1 } else { 0 } }, @{Expression={$_.SubItems[1].Text}; Ascending=$true}
            $lv.Items.AddRange($sorted)
            $lv.EndUpdate()
            $lblStatus.Text = "XONG! Đã tìm thấy $($lv.Items.Count) thiết bị."; $btnScan.Enabled = $true; $btnStop.Enabled = $false
        }
    })

    $btnScan.Add_Click({
        $lv.Items.Clear(); $btnScan.Enabled = $false; $btnStop.Enabled = $true; $SyncHash.Cancel = $false
        $ips = New-Object System.Collections.Generic.List[string]
        foreach ($p in ($txtSub.Text -split ",")) {
            $p = $p.Trim()
            if ($p -match '^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d+)-(\d+)$') { [int]$matches[2]..[int]$matches[3] | ForEach-Object { $ips.Add("$($matches[1]).$_") } }
            elseif ($p -match '^\d{1,3}\.\d{1,3}\.\d{1,3}$') { 1..254 | ForEach-Object { $ips.Add("$p.$_") } }
            elseif ($p -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ips.Add($p) }
        }
        if ($ips.Count -eq 0) { return }
        $pgBar.Maximum = $ips.Count; $pgBar.Value = 0
        $script:Pool = [runspacefactory]::CreateRunspacePool(1, 20); $script:Pool.Open()
        $script:Jobs = @(); $timer.Start()
        foreach ($ip in $ips) {
            $ps = [powershell]::Create(); $ps.RunspacePool = $script:Pool
            $ps.AddScript({
                param($ip, $Sync)
                if ($Sync.Cancel) { return }
                try {
                    $ipAddr = [System.Net.IPAddress]::Parse($ip).Address
                    $mB = New-Object Byte[] 6; $mL = [uint32]6
                    if ([Net.Win32]::SendARP($ipAddr, 0, $mB, [ref]$mL) -eq 0) {
                        $macRaw = ($mB | ForEach-Object { $_.ToString("X2") }) -join ""
                        $macPretty = ($mB | ForEach-Object { $_.ToString("X2") }) -join ":"
                        $oui = $macRaw.Substring(0,6).ToUpper()

                        # --- DÒ TÊN (2 GIÂY) ---
                        $name = $ip
                        try {
                            $dns = [System.Net.Dns]::BeginGetHostEntry($ip, $null, $null)
                            if ($dns.AsyncWaitHandle.WaitOne(2000)) { $name = [System.Net.Dns]::EndGetHostEntry($dns).HostName }
                            if ($name -eq $ip) {
                                $socket = New-Object System.Net.Sockets.UdpClient; $socket.Client.ReceiveTimeout = 1000
                                $req = [byte[]](0x80,0x94,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x43,0x4b,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x00,0x00,0x21,0x00,0x01)
                                $socket.Send($req, $req.Length, $ip, 137) | Out-Null
                                $ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0); $res = $socket.Receive([ref]$ep)
                                if ($res.Length -gt 57) { $nb = [System.Text.Encoding]::ASCII.GetString($res, 57, 15).Trim(); if ($nb) { $name = $nb } }
                                $socket.Close()
                            }
                        } catch {}

                        # --- DÒ HÃNG TRUY QUÉT ---
                        $vendor = "Unknown"
                        if ($Sync.Cache.ContainsKey($oui)) { $vendor = $Sync.Cache[$oui] }
                        elseif ($Sync.DB.ContainsKey($oui)) { $vendor = $Sync.DB[$oui]; $Sync.Cache[$oui] = $vendor }
                        else {
                            Start-Sleep -Seconds 1 # Nghỉ 1s tránh nghẽn API
                            try {
                                $web = New-Object System.Net.WebClient; $web.Headers.Add("X-Authentication-Token", "$($Sync.TokenL)")
                                $json = $web.DownloadString("https://api.maclookup.app/v2/macs/$macRaw") | ConvertFrom-Json
                                if ($json.company -and $json.company -ne "Unknown") { $vendor = $json.company }
                            } catch {}

                            if ($vendor -eq "Unknown") {
                                try {
                                    $webV = New-Object System.Net.WebClient; $webV.Headers.Add("Authorization", "Bearer $($Sync.TokenV)")
                                    $resV = $webV.DownloadString("https://api.macvendors.com/$macPretty")
                                    if ($resV -and $resV -notmatch "not found") { $vendor = $resV }
                                } catch {}
                            }
                            if ($vendor -ne "Unknown") { $Sync.Cache[$oui] = $vendor }
                        }
                        $Sync.Queue.Enqueue([PSCustomObject]@{IP=$ip; Name=$name; Vendor=$vendor; MAC=$macPretty})
                    }
                } catch {}
            }).AddArgument($ip).AddArgument($SyncHash) | Out-Null
            $script:Jobs += [PSCustomObject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
        }
    })

    $btnStop.Add_Click({ $SyncHash.Cancel = $true; $timer.Stop(); $btnScan.Enabled = $true; $btnStop.Enabled = $false })
    $form.ShowDialog() | Out-Null
}

&$LogicIPScannerV12