# ====================================================================
# 1. ĐÓNG GÓI SCRIPT CON VÀO MỘT CHUỖI VĂN BẢN (Dùng @' '@ để chống lỗi)
# ====================================================================
$CodeThucThi = @'
# --- Ép cửa sổ Console nổi lên trên cùng (Topmost) ---
$C_Sharp = 'using System; using System.Runtime.InteropServices; public class CuaSoConsole { [DllImport("user32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags); }'
Add-Type -TypeDefinition $C_Sharp -ErrorAction SilentlyContinue
$ID_CuaSo = [CuaSoConsole]::GetConsoleWindow()
[CuaSoConsole]::SetWindowPos($ID_CuaSo, -1, 0, 0, 0, 0, 3) | Out-Null
# -----------------------------------------------------

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'SilentlyContinue'

Clear-Host
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "     VIETTOOLBOX - BỘ TỐI ƯU HỆ THỐNG MẠNH MẼ    " -ForegroundColor Yellow
Write-Host "=================================================`n" -ForegroundColor Cyan

$LinkJson = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/Config.json"
Write-Host "[*] Đang kết nối máy chủ, tải cấu hình JSON mới nhất..." -ForegroundColor White

try {
    $DuLieuJson = Invoke-RestMethod -Uri $LinkJson -UseBasicParsing
    Write-Host "[+] Tải cấu hình thành công!`n" -ForegroundColor Green
} catch {
    Write-Host "[-] Không thể tải file cấu hình! Vui lòng kiểm tra lại mạng." -ForegroundColor Red
    Read-Host "Nhấn Enter để thoát"
    Exit
}

$DanhSachTweaks = $DuLieuJson.psobject.properties
$TongSo = $DanhSachTweaks.Count
$Dem = 1

foreach ($Tweak in $DanhSachTweaks) {
    $ThongTin = $Tweak.Value
    $TenTweak = if ($ThongTin.Content) { $ThongTin.Content } else { $Tweak.Name }
    
    Write-Host "[$Dem/$TongSo] Đang xử lý: $TenTweak" -ForegroundColor Yellow

    if ($null -ne $ThongTin.registry) {
        foreach ($Reg in $ThongTin.registry) {
            $LoaiDuLieu = if ($Reg.Type) { $Reg.Type } else { "DWord" }
            if (-not (Test-Path $Reg.Path)) { New-Item -Path $Reg.Path -Force | Out-Null }
            Set-ItemProperty -Path $Reg.Path -Name $Reg.Name -Value $Reg.Value -Type $LoaiDuLieu -Force
            Write-Host "    -> Đã chèn Registry: $($Reg.Name)" -ForegroundColor DarkGray
        }
    }

    if ($null -ne $ThongTin.service) {
        foreach ($Svc in $ThongTin.service) {
            Set-Service -Name $Svc.Name -StartupType $Svc.StartupType
            Write-Host "    -> Cấu hình Service $($Svc.Name) thành $($Svc.StartupType)" -ForegroundColor DarkGray
        }
    }

    if ($null -ne $ThongTin.appx) {
        foreach ($App in $ThongTin.appx) {
            Get-AppxPackage -Name "*$App*" -AllUsers | Remove-AppxPackage -AllUsers
            Write-Host "    -> Đã gỡ ứng dụng rác: $App" -ForegroundColor DarkGray
        }
    }

    if ($null -ne $ThongTin.InvokeScript) {
        Write-Host "    -> Đang thực thi tập lệnh hệ thống..." -ForegroundColor DarkGray
        foreach ($MaLenh in $ThongTin.InvokeScript) {
            Invoke-Command -ScriptBlock ([scriptblock]::Create($MaLenh))
        }
    }

    $Dem++
    Write-Host ""
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " HOÀN TẤT! HỆ THỐNG ĐÃ ĐƯỢC TỐI ƯU TOÀN DIỆN." -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Read-Host "Nhấn Enter để kết thúc..."
'@

# ====================================================================
# 2. MÃ HÓA VÀ BẮN SCRIPT CON RA MÀN HÌNH ĐEN
# ====================================================================
$ChuoiByte = [System.Text.Encoding]::Unicode.GetBytes($CodeThucThi)
$MaHoaBase64 = [Convert]::ToBase64String($ChuoiByte)

# Dùng Start-Process để mở một cửa sổ mới hoàn toàn tách biệt khỏi main.ps1
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $MaHoaBase64"