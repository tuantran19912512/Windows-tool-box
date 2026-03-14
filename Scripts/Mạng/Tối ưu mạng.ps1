Add-Type -AssemblyName System.Windows.Forms

# ==============================================================================
# SCRIPT: NETWORK TURBO ULTIMATE V4.0 - TỐI ƯU HOÁ TOÀN DIỆN MẠNG
# Tác giả: Tuấn Kỹ Thuật Máy Tính x VietToolbox
# ==============================================================================

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG KÍCH HOẠT CHẾ ĐỘ NETWORK ULTIMATE V4.0 <<<"
    Ghi-Log "=========================================================="

    try {
        # --- 1. TỐI ƯU HOÁ TCP/IP GLOBAL (NETSH) ---
        Ghi-Log "-> Đang tinh chỉnh bộ giao thức TCP/IP Global..."
        # Tự động điều chỉnh cửa sổ nhận (Rất quan trọng để đạt max speed)
        netsh int tcp set global autotuninglevel=normal | Out-Null
        # Giảm tải cho CPU, dồn sức mạnh cho xử lý gói tin
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=enabled | Out-Null
        netsh int tcp set global netdma=enabled | Out-Null
        netsh int tcp set global dca=enabled | Out-Null
        # Tối ưu hóa kiểm soát tắc nghẽn (Dùng CUBIC - thuật toán mới nhất)
        netsh int tcp set supplemental template=internet congestionprovider=cubic | Out-Null
        # Tắt các tính năng gây trễ gói tin
        netsh int tcp set global ecncapability=disabled | Out-Null
        netsh int tcp set global timestamps=disabled | Out-Null
        Ghi-Log "   [OK] Đã tối ưu các luồng TCP truyền tải."

        # --- 2. CAN THIỆP REGISTRY (MỞ KHOÁ BĂNG THÔNG & GIẢM PING) ---
        Ghi-Log "-> Đang can thiệp Registry để mở khóa giới hạn..."
        
        # A. Xóa bỏ 20% băng thông dự trữ QoS
        $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
        if (!(Test-Path $qosPath)) { New-Item -Path $qosPath -Force | Out-Null }
        Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0

        # B. Tối ưu Network Throttling (Chống bóp mạng khi chạy đa tác vụ)
        $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF

        # C. Tinh chỉnh Gaming (TCPNoDelay & TcpAckFrequency) - Giảm Ping cực sâu
        $interfacesPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
        Get-ChildItem $interfacesPath | ForEach-Object {
            Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
        }
        Ghi-Log "   [OK] Đã mở khóa 100% băng thông và giảm độ trễ (Ping)."

        # --- 3. ĐIỀU CHỈNH PHẦN CỨNG CARD MẠNG (NIC TWEAKS) ---
        Ghi-Log "-> Đang tắt các tính năng tiết kiệm điện gây lag trên Card mạng..."
        $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($Adapter in $Adapters) {
            Ghi-Log "   [+] Đang xử lý Card: $($Adapter.Name)"
            # Tắt tính năng tiết kiệm điện (Energy Efficient Ethernet / Green Ethernet)
            Disable-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction SilentlyContinue
            # Tắt Interrupt Moderation (Latency vs Throughput - Ưu tiên Latency cho mượt)
            Set-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            # Gán độ ưu tiên Metric (Số càng nhỏ ưu tiên càng cao)
            Set-NetIPInterface -InterfaceAlias $Adapter.Name -InterfaceMetric 10 -ErrorAction SilentlyContinue
        }

        # --- 4. LÀM SẠCH VÀ RESET HỆ THỐNG ---
        Ghi-Log "-> Đang dọn dẹp bộ đệm DNS và Reset Winsock..."
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
        ipconfig /flushdns | Out-Null

        Ghi-Log "----------------------------------------------------------"
        Ghi-Log ">>> HOÀN TẤT: MÁY TÍNH ĐÃ ĐƯỢC KÍCH BĂNG THÔNG FULL OPTION! <<<"
        
        [System.Windows.Forms.MessageBox]::Show("Đã kích hoạt Network Ultimate V4.0 thành công!`nMạng của bạn đã được tối ưu hóa ở mức cao nhất.", "VietToolbox", 0, 64)

    } catch {
        Ghi-Log "!!! LỖI: $($_.Exception.Message)"
    }
    Ghi-Log "=========================================================="
}

# Tích hợp vào hệ thống VietToolbox Pro
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang tối ưu mạng Full Option..." $LogicThucThi
} else {
    &$LogicThucThi
}