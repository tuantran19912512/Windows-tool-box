# ==============================================================================
# CÔNG CỤ: KÍCH HOẠT .NET 3.5 AUTO (V182.15 - GITHUB ENGINE)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Tải trực tiếp từ GitHub, chống đơ giao diện, tự nhận diện lỗi.
# ==============================================================================

# --- 1. TỰ ĐỘNG XIN QUYỀN ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- 2. CẤU HÌNH LINK TẢI GITHUB (LINK TĨNH VĨNH VIỄN) ---
$Global:Link_GitHub = "https://github.com/abbodi1406/dotNetFx35W10/releases/download/v0.25.11/dotNetFx35_WX_10_x86_x64_u.exe"
$Global:TempExePath = Join-Path $env:TEMP "NetFx3_Installer.exe"

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents() }

# --- 3. KHỞI TẠO GIAO DIỆN ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX - BƠM .NET 3.5 (GITHUB ENGINE)"; $form.Size = "600,450"
$form.StartPosition = "CenterScreen"; $form.BackColor = "#F0F4F8"; $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false

$fBold = New-Object System.Drawing.Font("Segoe UI Bold", 10); $fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 16); $fStd = New-Object System.Drawing.Font("Segoe UI", 10)

$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "CÀI ĐẶT .NET 3.5 (WIN 10 & 11 CHUNG)"; $lblHeader.Location = "20,15"; $lblHeader.Size = "550,35"; $lblHeader.Font = $fTitle; $lblHeader.ForeColor = "#0277BD"; $lblHeader.TextAlign = "MiddleCenter"

$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "[>>>] BẮT ĐẦU TẢI VÀ CÀI ĐẶT [<<<]"; $btnAuto.Location = "20,70"; $btnAuto.Size = "545,50"; $btnAuto.BackColor = "#0288D1"; $btnAuto.ForeColor = "White"; $btnAuto.Font = $fBold; $btnAuto.FlatStyle = "Flat"; $btnAuto.Cursor = "Hand"

$thanhTienDo = New-Object System.Windows.Forms.ProgressBar
$thanhTienDo.Location = "20,140"; $thanhTienDo.Size = "545,25"; $thanhTienDo.Style = "Blocks"

$gbLog = New-Object System.Windows.Forms.GroupBox
$gbLog.Text = " Nhật Ký Xử Lý "; $gbLog.Location = "20,180"; $gbLog.Size = "545,210"; $gbLog.Font = $fBold

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Dock = "Fill"; $txtLog.BackColor = "White"; $txtLog.ReadOnly = $true; $txtLog.Font = $fStd; $txtLog.BorderStyle = "None"
$gbLog.Controls.Add($txtLog)

$form.Controls.AddRange(@($lblHeader, $btnAuto, $thanhTienDo, $gbLog))

# --- 4. HÀM XỬ LÝ LOGIC ---
function Ghi-Log($msg, $color = "Black") {
    $txtLog.SelectionStart = $txtLog.TextLength; $txtLog.SelectionColor = $color
    $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
    $txtLog.ScrollToCaret(); LamMoi-GiaoDien
}

$btnAuto.Add_Click({
    $btnAuto.Enabled = $false; $txtLog.Clear(); $thanhTienDo.Style = "Blocks"; $thanhTienDo.Value = 0

    # Bước 1: Khám bệnh
    Ghi-Log "[*] Đang kiểm tra hệ thống..." "Blue"
    if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -eq 'Enabled') {
        Ghi-Log "[XONG] Máy khách đã có sẵn .NET 3.5 rồi!" "Green"
        $thanhTienDo.Value = 100; $btnAuto.Enabled = $true; return
    }

    # Bước 2: Tải file từ GitHub
    try {
        Ghi-Log "[*] Đang tải bộ cài từ GitHub (Tốc độ cao)..." "Orange"
        if (Test-Path $Global:TempExePath) { Remove-Item $Global:TempExePath -Force }
        
        $wc = New-Object System.Net.WebClient
        $Global:TaiXong = $false

        $wc.add_DownloadProgressChanged({
            param($sender, $e)
            $thanhTienDo.Value = $e.ProgressPercentage; LamMoi-GiaoDien
        })
        $wc.add_DownloadFileCompleted({ $Global:TaiXong = $true })

        $wc.DownloadFileAsync((New-Object Uri($Global:Link_GitHub)), $Global:TempExePath)
        while (-not $Global:TaiXong) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 100 }
        $wc.Dispose()

        Ghi-Log "[XONG] Đã tải xong tệp cài đặt (41MB)!" "Green"

        # Bước 3: Cài đặt (Chế độ chống đơ)
        $thanhTienDo.Style = "Marquee"; $thanhTienDo.MarqueeAnimationSpeed = 30
        Ghi-Log "[*] Đang bung dữ liệu vào lõi Windows..." "Blue"
        Ghi-Log "[LƯU Ý] Quá trình này có thể mất vài phút tùy ổ cứng!" "Gray"
        
        # Chạy file EXE (dùng /y để tự động gật đầu)
        $proc = Start-Process -FilePath $Global:TempExePath -ArgumentList "/y" -WindowStyle Hidden -PassThru

        # Vòng lặp chờ cài đặt (Chống đơ giao diện)
        while (-not $proc.HasExited) {
            LamMoi-GiaoDien
            Start-Sleep -Milliseconds 300
        }

        $thanhTienDo.Style = "Blocks"
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            $thanhTienDo.Value = 100
            Ghi-Log "[THÀNH CÔNG] KÍCH HOẠT HOÀN TẤT .NET 3.5!" "Green"
        } else {
            $thanhTienDo.Value = 0
            Ghi-Log "[LỖI] Cài đặt thất bại! Mã lỗi: $($proc.ExitCode)" "Red"
        }

        if (Test-Path $Global:TempExePath) { Remove-Item $Global:TempExePath -Force -ErrorAction SilentlyContinue }

    } catch {
        Ghi-Log "[LỖI] Không thể kết nối GitHub để tải file!" "Red"
    }

    $btnAuto.Enabled = $true; Ghi-Log "[*] Đã kết thúc tiến trình." "Black"
})

$form.ShowDialog() | Out-Null