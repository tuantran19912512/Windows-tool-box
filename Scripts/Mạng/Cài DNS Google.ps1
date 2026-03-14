Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# ==============================================================================
# SCRIPT: CẤU HÌNH DNS TÙY CHỌN (GIAO DIỆN NÚT BẤM)
# ==============================================================================

$LogicThucThi = {
    # --- 1. KHỞI TẠO POPUP CHỌN DNS ---
    $pop = New-Object System.Windows.Forms.Form
    $pop.Text = "VietToolbox - Lựa chọn DNS"; $pop.Size = "400,280"; $pop.BackColor = "#1E1E1E"
    $pop.StartPosition = "CenterScreen"; $pop.FormBorderStyle = "FixedDialog"
    $pop.MaximizeBox = $false; $pop.MinimizeBox = $false

    $fNut = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fChu = New-Object System.Drawing.Font("Segoe UI", 10)
    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "CHỌN HỆ THỐNG DNS MUỐN CẤU HÌNH:"; $lbl.ForeColor = "#00D4FF"
    $lbl.Size = "350,30"; $lbl.Location = "20,20"; $lbl.Font = $fNut; $lbl.TextAlign = "MiddleCenter"

    $Global:DNS_Selected = $null
    $Global:DNS_Name = ""

    # Nút Google
    $btnG = New-Object System.Windows.Forms.Button; $btnG.Text = "GOOGLE DNS (8.8.8.8)"; $btnG.Size = "340,40"; $btnG.Location = "25,60"
    $btnG.BackColor = "#2D2D2D"; $btnG.ForeColor = "White"; $btnG.FlatStyle = "Flat"; $btnG.Font = $fNut
    $btnG.Add_Click({ $Global:DNS_Selected = @("8.8.8.8", "8.8.4.4"); $Global:DNS_Name = "GOOGLE DNS"; $pop.Close() })

    # Nút Cloudflare
    $btnC = New-Object System.Windows.Forms.Button; $btnC.Text = "CLOUDFLARE DNS (1.1.1.1)"; $btnC.Size = "340,40"; $btnC.Location = "25,110"
    $btnC.BackColor = "#2D2D2D"; $btnC.ForeColor = "White"; $btnC.FlatStyle = "Flat"; $btnC.Font = $fNut
    $btnC.Add_Click({ $Global:DNS_Selected = @("1.1.1.1", "1.0.0.1"); $Global:DNS_Name = "CLOUDFLARE DNS"; $pop.Close() })

    # Nút Reset (DHCP)
    $btnR = New-Object System.Windows.Forms.Button; $btnR.Text = "MẶC ĐỊNH (NHÀ MẠNG / DHCP)"; $btnR.Size = "340,40"; $btnR.Location = "25,160"
    $btnR.BackColor = "#333333"; $btnR.ForeColor = "#AAAAAA"; $btnR.FlatStyle = "Flat"; $btnR.Font = $fNut
    $btnR.Add_Click({ $Global:DNS_Selected = "RESET"; $Global:DNS_Name = "MẶC ĐỊNH (DHCP)"; $pop.Close() })

    $pop.Controls.AddRange(@($lbl, $btnG, $btnC, $btnR))
    [void]$pop.ShowDialog()

    # --- 2. XỬ LÝ LOGIC SAU KHI CHỌN ---
    if ($null -eq $Global:DNS_Selected) { return } # Khách tắt bảng mà không chọn

    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG THIẾT LẬP: $Global:DNS_Name <<<"
    Ghi-Log "=========================================================="

    try {
        $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        if (-not $Adapters) { Ghi-Log "!!! LỖI: Không tìm thấy Card mạng đang hoạt động."; return }

        foreach ($Adapter in $Adapters) {
            Ghi-Log "-> Đang xử lý: $($Adapter.Name)"
            if ($Global:DNS_Selected -eq "RESET") {
                # Trả về DHCP (Nhà mạng)
                Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ResetServerAddresses -ErrorAction Stop
            } else {
                # Gán DNS cụ thể
                Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ServerAddresses $Global:DNS_Selected -ErrorAction Stop
            }
            Ghi-Log "   [OK] Thành công."
        }

        Ghi-Log "-> Làm mới DNS (FlushDNS)..."
        ipconfig /flushdns | Out-Null
        Ghi-Log ">>> HOÀN TẤT CẬP NHẬT DNS <<<"

        [System.Windows.Forms.MessageBox]::Show("Đã thiết lập $Global:DNS_Name thành công!", "VietToolbox", 0, 64)

    } catch {
        Ghi-Log "!!! LỖI: $($_.Exception.Message)"
    }
    Ghi-Log "=========================================================="
}

# Tích hợp vào hệ thống VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang mở bảng chọn DNS..." $LogicThucThi
} else {
    &$LogicThucThi
}