# ==============================================================================
# CÔNG CỤ: KÍCH HOẠT .NET 3.5 AUTO (BẢN GUI + DUAL SERVER + AUTO ADMIN)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Ghi chú: Chạy 1 tệp EXE đa năng, dự phòng 2 Server (GDrive -> GitHub)
# ==============================================================================

# --- TỰ ĐỘNG XIN QUYỀN ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- CẤU HÌNH 2 SERVER ---
$Global:ID_GDrive = "1qwwVtfh--A9uR1JwE_UdQKRfsmWZt2hz" 
$Global:Link_GitHub = "https://github.com/abbodi1406/dotNetFx35W10/releases/download/v0.25.11/dotNetFx35_WX_10_x86_x64_u.exe"
$Global:TempExePath = Join-Path $env:TEMP "NetFx3_Auto.exe"

function LamMoi-GiaoDien { [System.Windows.Forms.Application]::DoEvents() }

# --- 1. KHỞI TẠO CỬA SỔ ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIETTOOLBOX - BƠM .NET 3.5 TỰ ĐỘNG (DUAL SERVER)"
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

# --- 2. HÀM XỬ LÝ LOGIC ---
function Ghi-Log($msg, $color = "Black") {
    $txtLog.SelectionStart = $txtLog.TextLength; $txtLog.SelectionColor = $color
    $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
    $txtLog.ScrollToCaret(); LamMoi-GiaoDien
}

# Hàm tải file dùng chung (Có bắt lỗi)
function Tai-File($url) {
    if (Test-Path $Global:TempExePath) { Remove-Item $Global:TempExePath -Force }
    $wc = New-Object System.Net.WebClient
    $Global:TaiXong = $false; $Global:TaiLoi = $false

    $wc.add_DownloadProgressChanged({
        param($sender, $e)
        $thanhTienDo.Value = $e.ProgressPercentage; LamMoi-GiaoDien
    })
    $wc.add_DownloadFileCompleted({
        param($sender, $e)
        if ($e.Error -ne $null) { $Global:TaiLoi = $true }
        $Global:TaiXong = $true
    })

    $wc.DownloadFileAsync((New-Object Uri($url)), $Global:TempExePath)
    while (-not $Global:TaiXong) { LamMoi-GiaoDien; Start-Sleep -Milliseconds 50 }
    $wc.Dispose()
    
    return (-not $Global:TaiLoi)
}

$btnAuto.Add_Click({
    $btnAuto.Enabled = $false; $txtLog.Clear(); $thanhTienDo.Style = "Blocks"; $thanhTienDo.Value = 0

    Ghi-Log "[*] Đang kiểm tra hệ thống..." "Blue"
    if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -eq 'Enabled') {
        Ghi-Log "[THÀNH CÔNG] Máy khách đã kích hoạt sẵn .NET 3.5 rồi!" "Green"
        $thanhTienDo.Value = 100; $btnAuto.Enabled = $true; return
    }

    # BƯỚC 1: TẢI TỪ SERVER 1 (GDRIVE)
    Ghi-Log "[*] Đang kết nối Server 1 (Google Drive)..." "Orange"
    $linkGDrive = "https://docs.google.com/uc?export=download&id=$Global:ID_GDrive"
    
    if (-not (Tai-File $linkGDrive)) {
        # BƯỚC 2: FALLBACK SERVER 2 (GITHUB)
        $thanhTienDo.Value = 0
        Ghi-Log "[CẢNH BÁO] Server 1 lỗi! Đang chuyển hướng sang Server 2 (GitHub)..." "Red"
        
        if (-not (Tai-File $Global:Link_GitHub)) {
            Ghi-Log "[LỖI TỔNG] Cả 2 Server đều không thể tải file. Vui lòng kiểm tra lại mạng!" "Red"
            $thanhTienDo.Value = 0; $btnAuto.Enabled = $true; return
        }
    }

    Ghi-Log "[THÀNH CÔNG] Đã tải xong tệp cài đặt gốc (41MB)!" "Green"

    # BƯỚC 3: CÀI ĐẶT
    $thanhTienDo.Style = "Marquee"; $thanhTienDo.MarqueeAnimationSpeed = 30
    Ghi-Log "[*] Đang tự động bung dữ liệu vào lõi Windows (Tầm 30s-1p)..." "Blue"
    Ghi-Log "[CHÚ Ý] Vui lòng không tắt công cụ lúc này!" "Gray"
    
    $proc = Start-Process -FilePath $Global:TempExePath -ArgumentList "/q" -WindowStyle Hidden -PassThru -Wait

    $thanhTienDo.Style = "Blocks"
    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
        $thanhTienDo.Value = 100
        Ghi-Log "[THÀNH CÔNG] KÍCH HOẠT HOÀN TẤT .NET 3.5!" "Green"
    } else {
        $thanhTienDo.Value = 0
        Ghi-Log "[LỖI] Cài đặt thất bại (Mã: $($proc.ExitCode))" "Red"
    }

    if (Test-Path $Global:TempExePath) { Remove-Item $Global:TempExePath -Force -ErrorAction SilentlyContinue }
    
    $btnAuto.Enabled = $true; Ghi-Log "[*] Xong!" "Black"
})

$form.ShowDialog() | Out-Null