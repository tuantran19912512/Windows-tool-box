# ==============================================================================
# SCRIPT: QUÉT MẠNG LAN & TRA CỨU HÃNG SẢN XUẤT (BẢN ULTIMATE)
# ==============================================================================

Ghi-Log "=========================================================================================="
Ghi-Log ">>> BẮT ĐẦU QUY TRÌNH QUÉT MẠNG LAN CHUYÊN SÂU <<<"

# 1. Tự động nhận diện dải IP (Subnet) của máy đang dùng
$MyIPAddressInfo = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback|Pseudo" }
$MyIPs = $MyIPAddressInfo.IPAddress

if (-not $MyIPs) { 
    Ghi-Log "!!! LỖI: Không tìm thấy kết nối mạng. Vui lòng kiểm tra lại cáp/Wifi."
    return 
}

$SubnetDefault = ($MyIPs[0].Substring(0, $MyIPs[0].LastIndexOf('.')))
Ghi-Log "-> Đã nhận diện dải mạng hiện tại: $SubnetDefault.x"

# 2. Hộp thoại yêu cầu xác nhận dải IP cần quét
Add-Type -AssemblyName Microsoft.VisualBasic
$UserInput = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập dải IP cần quét (Ví dụ: 192.168.1):", "Quét IP Mạng LAN", $SubnetDefault)

if ([string]::IsNullOrWhiteSpace($UserInput)) { 
    Ghi-Log "!!! Người dùng đã hủy quy trình quét."
    return 
}

# 3. Tải Database MAC Vendor từ GitHub (Dữ liệu lớn giúp nhận diện chính xác hãng sản xuất)
Ghi-Log "-> [1/3] Đang nạp cơ sở dữ liệu MAC Vendor từ GitHub..."
$MacVendors = @{}
$GithubRawUrl = "https://raw.githubusercontent.com/tuantran19912512/pm/refs/heads/main/mac_interval_tree.txt"

try {
    # Cấu hình bảo mật để tải từ GitHub
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ApiResult = Invoke-WebRequest -Uri $GithubRawUrl -UseBasicParsing -TimeoutSec 10
    $Lines = $ApiResult.Content -split "`n"
    foreach ($line in $Lines) {
        if ($line.Length -gt 13 -and $line -notmatch "<GAP>") {
            # Lấy 6 ký tự đầu của MAC làm khóa (OUI)
            $oui = $line.Substring(0, 6).ToUpper()
            $MacVendors[$oui] = $line.Substring(13).Trim()
        }
    }
    Ghi-Log "   + Đã nạp thành công $( "{0:N0}" -f $MacVendors.Count ) bản ghi hãng sản xuất."
} catch {
    Ghi-Log "   ! Cảnh báo: Không thể kết nối GitHub. Chế độ quét sẽ không hiển thị đầy đủ hãng sản xuất."
}

# 4. Thiết lập bảng hiển thị
Ghi-Log " "
Ghi-Log "-> [2/3] Đang dò tìm thiết bị trực tuyến (Dải IP: $UserInput.1 - $UserInput.254)..."
Ghi-Log " "
# Căn lề các cột: IP (18), MAC (20), HOSTNAME (25), VENDOR (Tự do)
$Header = "{0,-18} {1,-20} {2,-25} {3}" -f "ĐỊA CHỈ IP", "MÃ MAC", "TÊN MÁY (HOST)", "HÃNG SẢN XUẤT"
Ghi-Log $Header
Ghi-Log ("-" * 105)

$Ping = New-Object System.Net.NetworkInformation.Ping
$ActiveCount = 0

# Vòng lặp quét từ 1 đến 254
for ($i = 1; $i -le 254; $i++) {
    $ip = "$UserInput.$i"
    
    # Ping kiểm tra (Timeout ngắn 100ms để tăng tốc độ quét)
    try {
        $Reply = $Ping.Send($ip, 100)
    } catch { $Reply = $null }
    
    if ($null -ne $Reply -and $Reply.Status -eq "Success") {
        $ActiveCount++
        
        # A. Lấy địa chỉ MAC thông qua bảng ARP
        $mac = "N/A"
        $arpData = arp -a $ip | Select-String -Pattern "([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})"
        if ($arpData -match "([0-9a-fA-F]{2}-){5}([0-9a-fA-F]{2})") {
            $mac = $Matches[0].ToUpper().Replace("-",":")
        }

        # B. Lấy Hostname từ DNS (Nếu có)
        $hName = "Unknown"
        try {
            $dnsResult = [System.Net.Dns]::GetHostEntry($ip)
            $hName = $dnsResult.HostName.Split('.')[0]
        } catch { }

        # C. Tra cứu hãng sản xuất dựa trên MAC OUI
        $vendor = "Unknown Vendor"
        if ($mac -ne "N/A") {
            $pref = $mac.Replace(":","").Substring(0,6)
            if ($MacVendors.ContainsKey($pref)) { 
                $vendor = $MacVendors[$pref] 
            }
        }
        
        # Rút gọn chuỗi nếu quá dài để không làm vỡ bảng
        $hNameDisplay = if ($hName.Length -gt 22) { $hName.Substring(0,19) + "..." } else { $hName }
        $vendorDisplay = if ($vendor.Length -gt 35) { $vendor.Substring(0,32) + "..." } else { $vendor }

        # Ghi dòng kết quả vào khung Log ngay lập tức
        $Row = "{0,-18} {1,-20} {2,-25} {3}" -f $ip, $mac, $hNameDisplay, $vendorDisplay
        Ghi-Log $Row
    }

    # Cứ sau 5 IP, ép giao diện cập nhật để người dùng vẫn có thể di chuyển cửa sổ Tool
    if ($i % 5 -eq 0) { 
        [System.Windows.Forms.Application]::DoEvents() 
    }
}

Ghi-Log ("-" * 105)
Ghi-Log ">>> [3/3] HOÀN TẤT QUY TRÌNH."
Ghi-Log "-> Kết quả: Tìm thấy tổng cộng $ActiveCount thiết bị đang hoạt động trong mạng LAN."
Ghi-Log "=========================================================================================="

# Hiện thông báo tổng kết
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("Quá trình quét mạng LAN hoàn tất!`nTìm thấy $ActiveCount thiết bị trực tuyến.", "Thông báo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)