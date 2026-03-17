Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# ==============================================================================
# SCRIPT: TỐI ƯU OFFICE 1-CLICK (FIX LỖI BẢN MỚI + ẨN BẢN CŨ + DIỆT WPS)
# ==============================================================================

$LogicFixOffice_Ultimate = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG TỐI ƯU MENU OFFICE (FIX BẢN MỚI, ẨN BẢN CŨ) <<<"
    Ghi-Log "=========================================================="

    # 1. Danh sách bản MỚI (Cần Fix lỗi và Phục hồi Template)
    $newTypes = @(
        @{ Ext = ".docx"; ProgId = "Word.Document.12"; Template = "word12.docx" },
        @{ Ext = ".xlsx"; ProgId = "Excel.Sheet.12"; Template = "excel12.xlsx" },
        @{ Ext = ".pptx"; ProgId = "PowerPoint.Show.12"; Template = "pwrpnt12.pptx" }
    )

    # 2. Danh sách bản CŨ (Cần Ẩn khỏi Menu chuột phải)
    $oldTypes = @(
        @{ Ext = ".doc";  ProgId = "Word.Document.8" },
        @{ Ext = ".xls";  ProgId = "Excel.Sheet.8" },
        @{ Ext = ".ppt";  ProgId = "PowerPoint.Show.8" }
    )

    # --- PHẦN 1: DỌN RÁC WPS VÀ FIX LỖI BẢN MỚI ---
    Ghi-Log "-> [1/3] Đang làm sạch Registry và ép quyền cho bản MỚI..."
    foreach ($type in $newTypes) {
        $ext = $type.Ext
        # Xoá rác UserChoice của WPS chiếm quyền
        $regPathsToNuke = @("HKCU:\Software\Classes\$ext", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext")
        foreach ($path in $regPathsToNuke) {
            if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue }
        }

        # Trả quyền mở file về Office chính chủ
        $hkcrExt = "Registry::HKEY_CLASSES_ROOT\$ext"
        if (Test-Path $hkcrExt) { Set-ItemProperty -Path $hkcrExt -Name "(default)" -Value $type.ProgId -Force -ErrorAction SilentlyContinue }

        # Dọn dẹp NullFile và gán lại Template chuẩn
        $shellNewPath = "Registry::HKEY_CLASSES_ROOT\$ext\$($type.ProgId)\ShellNew"
        if (-not (Test-Path $shellNewPath)) { New-Item -Path $shellNewPath -Force -ErrorAction SilentlyContinue | Out-Null }
        if (Get-ItemProperty -Path $shellNewPath -Name "NullFile" -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $shellNewPath -Name "NullFile" -Force -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path $shellNewPath -Name "FileName" -Value $type.Template -Force -ErrorAction SilentlyContinue
    }
    Ghi-Log "   [OK] Đã dọn khóa Registry cho các định dạng mới."

    # --- PHẦN 2: PHỤC HỒI FILE TEMPLATE (CHỈ TÌM BẢN MỚI) ---
    Ghi-Log "-> [2/3] Đang kiểm tra và phục hồi file mẫu vật lý..."
    $shellNewDir = "C:\Windows\ShellNew"
    if (-not (Test-Path $shellNewDir)) { New-Item -ItemType Directory -Path $shellNewDir | Out-Null }

    $officePaths = @("C:\Program Files\Microsoft Office", "C:\Program Files (x86)\Microsoft Office", "C:\Program Files\Common Files\microsoft shared", "C:\Program Files (x86)\Common Files\microsoft shared")

    foreach ($type in $newTypes) {
        $file = $type.Template
        $destPath = Join-Path $shellNewDir $file
        
        if (-not (Test-Path $destPath) -or (Get-Item $destPath).Length -lt 100) {
            Ghi-Log "   [-] Phát hiện $file bị lỗi. Đang lùng sục ổ C để khôi phục..."
            $found = $false
            foreach ($path in $officePaths) {
                if (Test-Path $path) {
                    $sourceFile = Get-ChildItem -Path $path -Filter $file -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($sourceFile) {
                        Copy-Item -Path $sourceFile.FullName -Destination $destPath -Force
                        Ghi-Log "   [+] Đã copy phục hồi thành công: $file"
                        $found = $true
                        break
                    }
                }
            }
            if (-not $found) { Ghi-Log "   [X] Thất bại: Không tìm thấy file $file trong máy." }
        } else {
            Ghi-Log "   [OK] File mẫu $file vẫn bình thường."
        }
    }

    # --- PHẦN 3: ẨN CÁC ĐUÔI ĐỜI CŨ KHỎI MENU ---
    Ghi-Log "-> [3/3] Đang dọn dẹp, ẩn các đuôi đồ cổ khỏi Menu New..."
    foreach ($type in $oldTypes) {
        $ext = $type.Ext
        $pathsToNuke = @(
            "Registry::HKEY_CLASSES_ROOT\$ext\$($type.ProgId)\ShellNew",
            "Registry::HKEY_CLASSES_ROOT\$ext\ShellNew"
        )
        foreach ($path in $pathsToNuke) {
            if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue }
        }
        Ghi-Log "   [X] Đã tiễn $ext bay màu khỏi Menu."
    }

    Ghi-Log "-> Đang khởi động lại Explorer..."
    Stop-Process -ProcessName explorer -Force

    Ghi-Log ">>> HOÀN TẤT QUÁ TRÌNH TỐI ƯU <<<"
    [System.Windows.Forms.MessageBox]::Show("Tối ưu Menu Office thành công rực rỡ!`n`n- Đã sửa lỗi tạo file bản MỚI (.xlsx, .docx).`n", "VietToolbox", 0, 64)
}

# Tích hợp vào hệ thống VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Đang Tối ưu Menu Office..." $LogicFixOffice_Ultimate
} else {
    &$LogicFixOffice_Ultimate
}