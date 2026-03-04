# ÉP POWERSHELL HIỂU TIẾNG VIỆT (UTF-8)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

# ==============================================================================
# SCRIPT: TẮT HOÀN TOÀN WEATHER (WIN 10) & WIDGETS (WIN 11)
# ==============================================================================

$LogicThucThi = {
    if (Get-Command ChuyenTab -ErrorAction SilentlyContinue) { ChuyenTab $pnlLog $btnMenuLog }
    
    Ghi-Log "=========================================================="
    Ghi-Log ">>> ĐANG TẮT WEATHER & WIDGETS HỆ THỐNG <<<"
    Ghi-Log "=========================================================="

    $WinVersion = [Environment]::OSVersion.Version.Build

    try {
        # --- TRƯỜNG HỢP WINDOWS 10 (News and Interests) ---
        if ($WinVersion -lt 22000) {
            Ghi-Log "-> Phát hiện: Windows 10."
            Ghi-Log "-> Đang tắt tính năng 'News and Interests' trên Taskbar..."
            
            $RegPath10 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
            if (-not (Test-Path $RegPath10)) { New-Item -Path $RegPath10 -Force | Out-Null }
            
            # Value 2 = Hidden (Tắt hoàn toàn)
            Set-ItemProperty -Path $RegPath10 -Name "ShellFeedsTaskbarViewMode" -Value 2 -Force
            Ghi-Log "   [OK] Đã cấu hình ẩn Weather Win 10."
        } 
        # --- TRƯỜNG HỢP WINDOWS 11 (Widgets) ---
        else {
            Ghi-Log "-> Phát hiện: Windows 11."
            Ghi-Log "-> Đang tắt tính năng Widgets hệ thống..."
            
            # Tắt qua Policy Registry (Triệt để nhất)
            $RegPath11 = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
            if (-not (Test-Path $RegPath11)) { New-Item -Path $RegPath11 -Force | Out-Null }
            
            Set-ItemProperty -Path $RegPath11 -Name "AllowNewsAndInterests" -Value 0 -Force
            Ghi-Log "   [OK] Đã vô hiệu hóa Widgets Win 11 qua Policy."
        }

        # --- BƯỚC QUAN TRỌNG: RESET EXPLORER ĐỂ CẬP NHẬT ---
        Ghi-Log "-> Đang làm mới giao diện Explorer..."
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 1
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer.exe
        }
        Ghi-Log "   [DONE] Tính năng Weather/Widgets đã được dẹp bỏ!"

    } catch {
        Ghi-Log "!!! LỖI: $($_.Exception.Message)"
    }

    Ghi-Log "=========================================================="
    [System.Windows.Forms.MessageBox]::Show("Đã tắt hoàn toàn Weather/Widgets và làm mới giao diện!", "VietToolbox", 0, 64)
}

# Tích hợp vào VietToolbox
if (Get-Command "ChayTacVu" -ErrorAction SilentlyContinue) {
    ChayTacVu "Tắt Weather/Widgets..." $LogicThucThi
} else {
    &$LogicThucThi
}