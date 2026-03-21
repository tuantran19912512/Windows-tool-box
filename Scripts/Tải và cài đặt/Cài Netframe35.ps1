# ==============================================================================
# CÔNG CỤ: KÍCH HOẠT .NET 3.5 CLOUD (BẢN DÙNG EXE CỦA ABBODI1406)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Chạy 1 tệp EXE duy nhất cho cả Win 10 & Win 11, tự động hoàn toàn.
# ==============================================================================
# ==============================================================================
# TỰ ĐỘNG YÊU CẦU QUYỀN ADMIN NẾU CHƯA CÓ
# ==============================================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- CẤU HÌNH ĐÚNG 1 ID GOOGLE DRIVE DUY NHẤT ---
$Global:FileID_Net35 = "1qwwVtfh--A9uR1JwE_UdQKRfsmWZt2hz"
$Global:TempExePath = Join-Path $env:TEMP "NetFx3_Auto.exe"

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents() }

# --- 1. KHỞI TẠO CỬA SỔ ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX - BƠM .NET 3.5 TỰ ĐỘNG (ALL IN ONE)"
$form.Size = "600,450"; $form.StartPosition = "CenterScreen"
$form.BackColor = "#F0F4F8"; $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false

$fBold = New-Object System.Drawing.Font("Segoe UI Bold", 10)
$fTitle = New-Object System.Drawing.Font("Segoe UI Bold", 16)
$fStd = New-Object System.Drawing.Font("Segoe UI", 10)

$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "CÀI ĐẶT .NET 3.5 (WIN 10 & 11 CHUNG)"; $lblHeader.Location = "20,15"; $lblHeader.Size = "550,35"; $lblHeader.Font = $fTitle; $lblHeader.ForeColor = "#0277BD"; $lblHeader.TextAlign = "MiddleCenter"

$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "[>>>] BẮT ĐẦU TẢI VÀ CÀI ĐẶT [<<<]"; $btnAuto.Location = "20,70"; $btnAuto.Size = "545,50"
$btnAuto.BackColor = "#0288D1"; $btnAuto.ForeColor = "White"; $btnAuto.Font = $fBold; $btnAuto.FlatStyle = "Flat"; $btnAuto.Cursor = "Hand"

$thanhTienDo = New-Object System.Windows.Forms.ProgressBar
$thanhTienDo.Location = "20,140"; $thanhTienDo.Size = "545,25"; $thanhTienDo.Style = "Blocks"

$gbLog = New-Object System.Windows.Forms.GroupBox
$gbLog.Text = " Nhật Ký Xử Lý "; $gbLog.Location = "20,180"; $gbLog.Size = "545,210"; $gbLog.Font = $fBold

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Dock = "Fill"; $txtLog.BackColor = "White"; $txtLog.ReadOnly = $true; $txtLog.Font = $fStd; $txtLog.BorderStyle = "None"
$gbLog.Controls.Add($txtLog)

$form.Controls.AddRange(@($lblHeader, $btnAuto, $thanhTienDo, $gbLog))

# --- 2. HÀM XỬ LÝ ---
function Ghi-Log($msg, $color = "Black") {
    $txtLog.SelectionStart = $txtLog.TextLength; $txtLog.SelectionColor = $color
    $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
    $txtLog.ScrollToCaret(); LamMoi-GiaoDien
}

$btnAuto.Add_Click({
    $btnAuto.Enabled = $false; $txtLog.Clear(); $thanhTienDo.Style = "Blocks"; $thanhTienDo.Value = 0

    Ghi-Log "[*] Đang kiểm tra tính năng .NET 3.5 trên máy..." "Blue"
    if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -eq 'Enabled') {
        Ghi-Log "[THÀNH CÔNG] Hệ thống đã cài sẵn .NET 3.5 rồi!" "Green"
        $thanhTienDo.Value = 100; $btnAuto.Enabled = $true; return
    }

    try {
        Ghi-Log "[*] Đang kết nối máy chủ tải gói Cài đặt đa năng (41MB)..." "Orange"
        if (Test-Path $Global:TempExePath) { Remove-Item $Global:TempExePath -Force }
        
        $wc = New-Object System.Net.WebClient
        $Global:TaiXong = $false

        $wc.add_DownloadProgressChanged({
            param($sender, $e)
            $thanhTienDo.Value = $e.ProgressPercentage; LamMoi-GiaoDien
        })
        $wc.add_DownloadFileCompleted({ $Global:TaiXong = $true })

        $wc.DownloadFileAsync((New-Object Uri("https://docs.google.com/uc?export=download&id=$Global:FileID_Net35")), $Global:TempExePath)

        while (-not $Global:TaiXong) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 100 }
        $wc.Dispose()

        Ghi-Log "[THÀNH CÔNG] Tải tệp hoàn tất!" "Green"

        $thanhTienDo.Style = "Marquee"; $thanhTienDo.MarqueeAnimationSpeed = 30
        Ghi-Log "[*] Đang tự động kích hoạt .NET 3.5 (Tầm 30 giây)..." "Blue"
        Ghi-Log "[CHÚ Ý] Không tắt công cụ lúc này!" "Gray"
        
        # Chạy file EXE siêu tĩnh lặng (thêm /q để chắc chắn nó không hiện popup)
        $proc = Start-Process -FilePath $Global:TempExePath -ArgumentList "/q" -WindowStyle Hidden -PassThru -Wait

        $thanhTienDo.Style = "Blocks"
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            $thanhTienDo.Value = 100
            Ghi-Log "[THÀNH CÔNG] KÍCH HOẠT HOÀN TẤT .NET 3.5!" "Green"
        } else {
            $thanhTienDo.Value = 0
            Ghi-Log "[LỖI] Cài đặt thất bại (Mã lỗi: $($proc.ExitCode))" "Red"
        }

        if (Test-Path $Global:TempExePath) { Remove-Item $Global:TempExePath -Force -ErrorAction SilentlyContinue }
    } catch {
        $thanhTienDo.Style = "Blocks"; $thanhTienDo.Value = 0
        Ghi-Log "[LỖI MẠNG] Không thể kết nối hoặc tải tệp!" "Red"
    }
    $btnAuto.Enabled = $true; Ghi-Log "[*] Xong!" "Black"
})

$form.ShowDialog() | Out-Null