Add-Type -AssemblyName System.Windows.Forms

# ==============================================================================
# SCRIPT: CÀI IP SCANNER (BẢN FIX LỖI MỞ 2 CỬA SỔ SONG SONG)
# ==============================================================================

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> TIẾN TRÌNH TRIỂN KHAI IP SCANNER <<<"
    Ghi-Log "=========================================================="

    $InstallerPath = "$env:TEMP\Advanced_IP_Scanner_Setup.exe"

    # --- HÀM TÌM KIẾM ĐƯỜNG DẪN ---
    function Lay-Duong-Dan-App {
        $FileNames = @("advanced_ip_scanner.exe", "AdvancedIPScanner.exe")
        $Folders = @("${env:ProgramFiles(x86)}", "${env:ProgramFiles}", "C:\Program Files (x86)", "C:\Program Files")
        foreach ($folder in $Folders) {
            foreach ($file in $FileNames) {
                $FullPath = Join-Path "$folder\Advanced IP Scanner" $file
                if (Test-Path $FullPath) { return $FullPath }
            }
        }
        return $null
    }

    # --- HÀM MỞ APP THÔNG MINH (CHỈ MỞ NẾU CHƯA CHẠY) ---
    function Mo-App-Thong-Minh {
        $Path = Lay-Duong-Dan-App
        if ($Path) {
            # Kiểm tra xem có tiến trình nào đang chạy không
            $CheckProcess = Get-Process | Where-Object { $_.Name -match "advanced_ip_scanner|AdvancedIPScanner" }
            if ($CheckProcess) {
                Ghi-Log "   [!] Phần mềm đã được mở tự động trước đó."
                return $true
            } else {
                Ghi-Log "   [+] Đang khởi chạy phần mềm..."
                Start-Process "$Path"
                return $true
            }
        }
        return $false
    }

    # BƯỚC 1: KIỂM TRA SẴN CÓ
    Ghi-Log "[1/3] Kiểm tra ứng dụng trên máy..."
    if (Mo-App-Thong-Minh) { 
        Ghi-Log ">>> HOÀN TẤT: ĐÃ MỞ ỨNG DỤNG <<<"
        Ghi-Log "=========================================================="
        return 
    }

    # BƯỚC 2: THỬ QUA WINGET
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Ghi-Log "[2/3] Đang gọi Winget cài đặt ngầm..."
        $proc = Start-Process winget -ArgumentList "install --id Famatech.AdvancedIPScanner --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -PassThru
        
        $count = 0
        while (-not $proc.HasExited) {
            $count++; Ghi-Log "   ... Đang cài đặt ($count s)"; [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Seconds 1
        }
        
        Start-Sleep -Seconds 2
        if (Mo-App-Thong-Minh) { 
            Ghi-Log ">>> HOÀN TẤT: CÀI XONG QUA WINGET <<<"
            Ghi-Log "=========================================================="
            return 
        }
    }

    # BƯỚC 3: TẢI VÀ CÀI OFFLINE
    Ghi-Log "[3/3] Đang tải bộ cài Offline..."
    $DirectUrl = "https://download.advanced-ip-scanner.com/download/files/Advanced_IP_Scanner_2.5.4594.1.exe"
    try {
        if (Test-Path $InstallerPath) { Remove-Item $InstallerPath -Force }
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($DirectUrl, $InstallerPath)
        
        if (Test-Path $InstallerPath) {
            Ghi-Log "   + Đã tải xong. Đang cài đặt ngầm..."
            $installProc = Start-Process -FilePath $InstallerPath -ArgumentList "/S" -PassThru
            
            $timeout = 0
            while ($timeout -lt 60) {
                if (Mo-App-Thong-Minh) { break }
                if ($installProc.HasExited) { break }
                [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Seconds 1; $timeout++
            }
        }
    } catch { Ghi-Log "   !!! LỖI: Không tải được file." }

    # TỔNG KẾT
    if (-not (Mo-App-Thong-Minh)) {
        Ghi-Log "!!! THẤT BẠI: Vui lòng cài thủ công."
    } else {
        if (Test-Path $InstallerPath) { Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue }
    }
    Ghi-Log "=========================================================="
}

if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Triển khai IP Scanner..." $LogicThucThi
} else { &$LogicThucThi }