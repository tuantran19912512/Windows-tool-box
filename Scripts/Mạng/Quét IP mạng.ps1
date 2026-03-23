# ==========================================================
# VIETTOOLBOX IP SCANNER V12 - WPF EDITION (FIX GIAO DIỆN HOVER)
# ==========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if ($Host.Name -eq "ConsoleHost") { $Size = $Host.UI.RawUI.BufferSize; $Size.Height = 5000; $Host.UI.RawUI.BufferSize = $Size }

# KHỞI TẠO MÔI TRƯỜNG WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# --- LÕI SENDARP TẦNG VẬT LÝ ---
$Signature = '[DllImport("iphlpapi.dll", ExactSpelling=true)] public static extern int SendARP(uint DestIP, uint SrcIP, byte[] pMacAddr, ref uint PhyAddrLen);'
try { Add-Type -MemberDefinition $Signature -Name "Win32" -Namespace "Net" -ErrorAction SilentlyContinue } catch {}

$LogicIPScannerV12 = {
    $Global:TokenL = "01kknht6atwchhnagzkaq9z4qc01kknhtqtw0pzkwm2nm5dp5dshkvux5avpst6e"
    $Global:TokenV = "EyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiIsImp0aSI6ImI0NmYyN2FlLWY4N2EtNGQwNi1iYmM3LTA5MjJlZWRmMGEzZSJ9.eyJpc3MiOiJtYWN2ZW5kb3JzIiwiYXVkIjoibWFjdmVuZG9ycyIsImp0aSI6ImI0NmYyN2FlLWY4N2EtNGQwNi1iYmM3LTA5MjJlZWRmMGEzZSIsImlhdCI6MTc3MzQyMjMyMywiZXhwIjoyMDg3OTE4MzIzLCJzdWIiOiIxNzMwNiIsInR5cCI6ImFjY2VzcyJ9.dG7S9_1o8fOnH5EnZjZUrc332dAHn-kGbqbRAaeutjTcVrwfQ-X7Zl1SaMkN4zIjtZ26jjQG2lCnzZWtzO8oNQ"
    $Global:MacOfflineDB = @{}

    # --- 1. GIAO DIỆN XAML WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX IP SCANNER V12 - VENDOR HUNTER (WPF EDITION)" Width="1050" Height="750"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="GridViewColumnHeader">
            <Setter Property="Background" Value="#333337"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="5"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,5">
            <TextBlock Text="Nhập IP quét:" Foreground="#00D4FF" FontSize="16" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,15,0"/>
            <TextBox Name="txtSub" Width="400" Height="35" Background="#2D2D2D" Foreground="White" FontSize="16" FontWeight="Bold" VerticalContentAlignment="Center" Padding="10,0" BorderBrush="#3F3F46" BorderThickness="1"/>
            <Button Name="btnScan" Content="QUÉT NGAY" Width="140" Height="35" Background="#D35400" Foreground="White" FontWeight="Bold" FontSize="14" Margin="25,0,10,0" IsEnabled="False" Cursor="Hand">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></Button.Resources>
            </Button>
            <Button Name="btnStop" Content="DỪNG" Width="120" Height="35" Background="#C0392B" Foreground="White" FontWeight="Bold" FontSize="14" IsEnabled="False" Cursor="Hand">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style></Button.Resources>
            </Button>
        </StackPanel>

        <TextBlock Text="VD: 192.168.1 (Dải) | 192.168.1.10-50 (Đoạn) | 192.168.1.5 (Lẻ)" Grid.Row="1" Foreground="#888888" FontStyle="Italic" FontSize="13" Margin="115,0,0,20"/>

        <ListView Name="BangIP" Grid.Row="2" Background="#252526" Foreground="#E0E0E0" BorderBrush="#3F3F46" BorderThickness="1" Margin="0,0,0,15" FontSize="14">
            
            <ListView.ItemContainerStyle>
                <Style TargetType="ListViewItem">
                    <Setter Property="Foreground" Value="#E0E0E0"/>
                    <Setter Property="Background" Value="Transparent"/>
                    <Setter Property="Margin" Value="0,1"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ListViewItem">
                                <Border Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}" SnapsToDevicePixels="true">
                                    <GridViewRowPresenter VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="Bd" Property="Background" Value="#3E3E42"/>
                                    </Trigger>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter TargetName="Bd" Property="Background" Value="#007ACC"/>
                                        <Setter Property="Foreground" Value="White"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </ListView.ItemContainerStyle>

            <ListView.View>
                <GridView>
                    <GridViewColumn Header="TRẠNG THÁI" Width="100">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <TextBlock Text="{Binding Status}" Foreground="LimeGreen" FontWeight="Bold"/>
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="ĐỊA CHỈ IP" DisplayMemberBinding="{Binding IP}" Width="150"/>
                    <GridViewColumn Header="TÊN THIẾT BỊ" DisplayMemberBinding="{Binding Name}" Width="220"/>
                    <GridViewColumn Header="HÃNG SẢN XUẤT" DisplayMemberBinding="{Binding Vendor}" Width="330"/>
                    <GridViewColumn Header="MAC ADDRESS" DisplayMemberBinding="{Binding MAC}" Width="170"/>
                </GridView>
            </ListView.View>
        </ListView>

        <TextBlock Name="lblStatus" Grid.Row="3" Text="Đang tải dữ liệu cấu hình..." Foreground="Cyan" FontSize="14" FontWeight="SemiBold" Margin="0,0,0,8"/>
        <ProgressBar Name="pgBar" Grid.Row="4" Height="20" Background="#2D2D2D" Foreground="#00D4FF" BorderThickness="0"/>
    </Grid>
</Window>
"@

    # --- 2. KHỞI TẠO CỬA SỔ & ÁNH XẠ BIẾN ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    $txtSub = $CuaSo.FindName("txtSub")
    $btnScan = $CuaSo.FindName("btnScan")
    $btnStop = $CuaSo.FindName("btnStop")
    $BangIP = $CuaSo.FindName("BangIP")
    $lblStatus = $CuaSo.FindName("lblStatus")
    $pgBar = $CuaSo.FindName("pgBar")

    # Dữ liệu bảng
    $Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $BangIP.ItemsSource = $Global:DanhSachDuLieu

    # Tự động lấy IP mạng LAN hiện tại
    $myIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi, Ethernet -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -match "^(192\.168|10\.|172\.)" } | Select-Object -First 1).IPAddress
    $txtSub.Text = if ($myIp) { $myIp.Substring(0, $myIp.LastIndexOf('.')) } else { "192.168.1" }

    # Setup Đồng bộ luồng (Đóng gói để đưa vào Runspace)
    $SyncHash = [hashtable]::Synchronized(@{ 
        Queue = [System.Collections.Concurrent.ConcurrentQueue[psobject]]::new()
        TokenL = $Global:TokenL
        TokenV = $Global:TokenV
        DB = $Global:MacOfflineDB
        Cancel = $false
        Cache = [hashtable]::Synchronized(@{}) 
    })
    $script:Jobs = @()
    $script:Pool = $null

    # --- BỘ ĐẾM NHỊP WPF (DISPATCHER TIMER) ---
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        $completed = 0
        foreach ($j in $script:Jobs) { if ($j.Handle.IsCompleted) { $completed++ } }
        $pgBar.Value = $completed

        # Lấy dữ liệu từ luồng quét nhét vào UI
        $obj = $null
        while ($SyncHash.Queue.TryDequeue([ref]$obj)) {
            $Global:DanhSachDuLieu.Add([PSCustomObject]@{
                Status = "ONLINE"
                IP = $obj.IP
                Name = $obj.Name
                Vendor = $obj.Vendor
                MAC = $obj.MAC
            })
        }

        # Xử lý khi quét xong toàn bộ
        if ($script:Jobs.Count -gt 0 -and $completed -ge $script:Jobs.Count) {
            $timer.Stop()
            
            # Sắp xếp lại danh sách theo IP (Dùng mảng tạm để tránh lỗi chớp nháy giao diện)
            $mangTam = $Global:DanhSachDuLieu | Sort-Object { 
                try { [version]($_.IP) } catch { $_.IP } 
            }
            $Global:DanhSachDuLieu.Clear()
            foreach ($item in $mangTam) { $Global:DanhSachDuLieu.Add($item) }
            
            $lblStatus.Text = "XONG! Đã tìm thấy $($Global:DanhSachDuLieu.Count) thiết bị."
            $btnScan.IsEnabled = $true
            $btnStop.IsEnabled = $false
        }
    })

    # --- SỰ KIỆN TẢI CỬA SỔ (Lấy CSDL Offline) ---
    $CuaSo.Add_Loaded({
        try {
            $dbUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/Scripts/M%E1%BA%A1ng/mac_interval_tree.txt"
            $raw = (New-Object System.Net.WebClient).DownloadString($dbUrl)
            foreach ($line in ($raw -split "`n")) {
                if ($line -match "^\s*([0-9A-Fa-f]{6})\s+[`"']?(.+?)[`"']?\s*$") {
                    $Global:MacOfflineDB[$matches[1].ToUpper()] = $matches[2].Trim()
                }
            }
            $lblStatus.Text = "✅ Tải Database Offline thành công ($($Global:MacOfflineDB.Count) hãng sản xuất)."
            $btnScan.IsEnabled = $true
        } catch { 
            $lblStatus.Text = "⚠️ Lỗi tải DB Offline! Công cụ vẫn sẽ dùng hàm nội bộ để quét API."
            $btnScan.IsEnabled = $true 
        }
    })

    # --- SỰ KIỆN NÚT QUÉT ---
    $btnScan.Add_Click({
        $Global:DanhSachDuLieu.Clear()
        $btnScan.IsEnabled = $false
        $btnStop.IsEnabled = $true
        $SyncHash.Cancel = $false

        $ips = New-Object System.Collections.Generic.List[string]
        foreach ($p in ($txtSub.Text -split ",")) {
            $p = $p.Trim()
            if ($p -match '^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d+)-(\d+)$') { [int]$matches[2]..[int]$matches[3] | ForEach-Object { $ips.Add("$($matches[1]).$_") } }
            elseif ($p -match '^\d{1,3}\.\d{1,3}\.\d{1,3}$') { 1..254 | ForEach-Object { $ips.Add("$p.$_") } }
            elseif ($p -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ips.Add($p) }
        }
        
        if ($ips.Count -eq 0) { 
            $lblStatus.Text = "⚠️ Lỗi cú pháp IP! Vui lòng nhập đúng định dạng."; 
            $btnScan.IsEnabled = $true; $btnStop.IsEnabled = $false; return 
        }

        $pgBar.Maximum = $ips.Count; $pgBar.Value = 0
        $lblStatus.Text = "Đang rải thảm $($ips.Count) địa chỉ IP..."
        
        # Khởi tạo bể chứa luồng (Runspace Pool) tối đa 20 luồng cùng lúc
        $script:Pool = [runspacefactory]::CreateRunspacePool(1, 20)
        $script:Pool.Open()
        $script:Jobs = @()
        $timer.Start()

        foreach ($ip in $ips) {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $script:Pool
            $ps.AddScript({
                param($ip, $Sync)
                if ($Sync.Cancel) { return }
                try {
                    $ipAddr = [System.Net.IPAddress]::Parse($ip).Address
                    $mB = New-Object Byte[] 6; $mL = [uint32]6
                    
                    # Bắn gói tin ARP tầng vật lý
                    if ([Net.Win32]::SendARP($ipAddr, 0, $mB, [ref]$mL) -eq 0) {
                        $macRaw = ($mB | ForEach-Object { $_.ToString("X2") }) -join ""
                        $macPretty = ($mB | ForEach-Object { $_.ToString("X2") }) -join ":"
                        $oui = $macRaw.Substring(0,6).ToUpper()

                        # --- DÒ TÊN QUA DNS VÀ NETBIOS ---
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

                        # --- DÒ HÃNG SẢN XUẤT (VENDOR HUNTER) ---
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
                        
                        # Bơm dữ liệu tìm được vào Hàng đợi luồng an toàn
                        $Sync.Queue.Enqueue([PSCustomObject]@{IP=$ip; Name=$name; Vendor=$vendor; MAC=$macPretty})
                    }
                } catch {}
            }).AddArgument($ip).AddArgument($SyncHash) | Out-Null
            
            $script:Jobs += [PSCustomObject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
        }
    })

    # --- SỰ KIỆN NÚT DỪNG ---
    $btnStop.Add_Click({ 
        $SyncHash.Cancel = $true
        $timer.Stop()
        $lblStatus.Text = "🛑 Đã buộc dừng tiến trình quét!"
        $btnScan.IsEnabled = $true
        $btnStop.IsEnabled = $false 
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$LogicIPScannerV12