# ==============================================================================
# TRÌNH GỠ PHONG ẤN TẬP TIN — Bản cải tiến (Flat UI + Chống treo)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

try {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        [System.Windows.Forms.MessageBox]::Show("Vui lòng chạy bằng quyền Administrator!", "Thiếu quyền", 0, 48)
        return
    }

    function Mau($Hex) { [System.Drawing.ColorTranslator]::FromHtml($Hex) }

    # ── BIẾN TOÀN CỤC ──────────────────────────────────────────────────────────
    $Script:BoDem       = $null
    $Script:TienTrinhPS = $null
    $Script:KgChay      = $null
    $Script:HangDoiLog  = $null
    $Script:KqAsync     = $null

    # ── MÀU PALETTE PHẲNG (không dùng màu neon) ────────────────────────────────
    $Bg      = Mau "#F5F5F4"   # nền tổng
    $Surface = Mau "#FFFFFF"   # bề mặt card
    $Border  = Mau "#E2E0DC"   # viền nhẹ
    $Txt     = Mau "#1C1917"   # chữ chính
    $TxtSub  = Mau "#78716C"   # chữ phụ
    $Accent  = Mau "#2563EB"   # xanh dương trung tính
    $Success = Mau "#16A34A"   # xanh lá khi thành công
    $Danger  = Mau "#DC2626"   # đỏ khi lỗi
    $LogBg   = Mau "#1C1917"   # nền log (dark)
    $LogTxt  = Mau "#A8A29E"   # chữ log

    # ── XÂY DỰNG FORM ──────────────────────────────────────────────────────────
    $Form               = New-Object System.Windows.Forms.Form
    $Form.Text          = "Trình gỡ phong ấn tập tin"
    $Form.Size          = New-Object System.Drawing.Size(660, 530)
    $Form.StartPosition = "CenterScreen"
    $Form.BackColor     = $Bg
    $Form.ForeColor     = $Txt
    $Form.FormBorderStyle = "FixedSingle"
    $Form.MaximizeBox   = $false
    $Form.Font          = New-Object System.Drawing.Font("Segoe UI", 9)

    # Panel chứa nội dung chính (padding giả)
    $Panel              = New-Object System.Windows.Forms.Panel
    $Panel.Location     = New-Object System.Drawing.Point(20, 16)
    $Panel.Size         = New-Object System.Drawing.Size(608, 460)
    $Panel.BackColor    = $Bg
    $Form.Controls.Add($Panel)

    # Label đường dẫn
    $LblPath            = New-Object System.Windows.Forms.Label
    $LblPath.Text       = "Đường dẫn thư mục (cục bộ, UNC, ổ đĩa ánh xạ):"
    $LblPath.Location   = New-Object System.Drawing.Point(0, 0)
    $LblPath.AutoSize   = $true
    $LblPath.ForeColor  = $TxtSub
    $Panel.Controls.Add($LblPath)

    # TextBox nhập đường dẫn
    $TxtPath            = New-Object System.Windows.Forms.TextBox
    $TxtPath.Location   = New-Object System.Drawing.Point(0, 22)
    $TxtPath.Size       = New-Object System.Drawing.Size(490, 30)
    $TxtPath.BackColor  = $Surface
    $TxtPath.ForeColor  = $Txt
    $TxtPath.BorderStyle = "FixedSingle"
    $TxtPath.Font       = New-Object System.Drawing.Font("Segoe UI", 10)
    $Panel.Controls.Add($TxtPath)

    # Nút Duyệt
    $BtnBrowse          = New-Object System.Windows.Forms.Button
    $BtnBrowse.Text     = "Duyệt..."
    $BtnBrowse.Location = New-Object System.Drawing.Point(500, 21)
    $BtnBrowse.Size     = New-Object System.Drawing.Size(108, 30)
    $BtnBrowse.FlatStyle = "Flat"
    $BtnBrowse.FlatAppearance.BorderColor = $Border
    $BtnBrowse.FlatAppearance.BorderSize  = 1
    $BtnBrowse.BackColor = $Surface
    $BtnBrowse.ForeColor = $Txt
    $BtnBrowse.Cursor   = [System.Windows.Forms.Cursors]::Hand
    $Panel.Controls.Add($BtnBrowse)

    # Checkbox tin cậy mạng
    $ChkTrust           = New-Object System.Windows.Forms.CheckBox
    $ChkTrust.Text      = "Tự động thêm IP máy chủ vào danh sách tin cậy (sửa lỗi Harmful)"
    $ChkTrust.Location  = New-Object System.Drawing.Point(0, 62)
    $ChkTrust.Size      = New-Object System.Drawing.Size(608, 22)
    $ChkTrust.Checked   = $true
    $ChkTrust.ForeColor = $TxtSub
    $Panel.Controls.Add($ChkTrust)

    # Nút Thực thi — flat, viền nhạt
    $BtnRun             = New-Object System.Windows.Forms.Button
    $BtnRun.Text        = "Thực thi mở khóa tập tin"
    $BtnRun.Location    = New-Object System.Drawing.Point(0, 96)
    $BtnRun.Size        = New-Object System.Drawing.Size(608, 40)
    $BtnRun.FlatStyle   = "Flat"
    $BtnRun.FlatAppearance.BorderColor = $Border
    $BtnRun.FlatAppearance.BorderSize  = 1
    $BtnRun.BackColor   = $Surface
    $BtnRun.ForeColor   = $Txt
    $BtnRun.Font        = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $BtnRun.Cursor      = [System.Windows.Forms.Cursors]::Hand
    $Panel.Controls.Add($BtnRun)

    # ProgressBar (ẩn khi chờ)
    $ProgBar            = New-Object System.Windows.Forms.ProgressBar
    $ProgBar.Location   = New-Object System.Drawing.Point(0, 144)
    $ProgBar.Size       = New-Object System.Drawing.Size(608, 4)
    $ProgBar.Style      = "Marquee"
    $ProgBar.MarqueeAnimationSpeed = 40
    $ProgBar.Visible    = $false
    $Panel.Controls.Add($ProgBar)

    # Label nhật ký
    $LblLog             = New-Object System.Windows.Forms.Label
    $LblLog.Text        = "NHẬT KÝ HỆ THỐNG"
    $LblLog.Location    = New-Object System.Drawing.Point(0, 158)
    $LblLog.AutoSize    = $true
    $LblLog.ForeColor   = $TxtSub
    $LblLog.Font        = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)
    $Panel.Controls.Add($LblLog)

    # ListBox log — dark surface
    $ListLog            = New-Object System.Windows.Forms.ListBox
    $ListLog.Location   = New-Object System.Drawing.Point(0, 178)
    $ListLog.Size       = New-Object System.Drawing.Size(608, 180)
    $ListLog.BackColor  = $LogBg
    $ListLog.ForeColor  = $LogTxt
    $ListLog.BorderStyle = "FixedSingle"
    $ListLog.Font       = New-Object System.Drawing.Font("Consolas", 9)
    $Panel.Controls.Add($ListLog)

    # Label trạng thái
    $LblStatus          = New-Object System.Windows.Forms.Label
    $LblStatus.Text     = "Đang chờ lệnh..."
    $LblStatus.Location = New-Object System.Drawing.Point(0, 368)
    $LblStatus.Size     = New-Object System.Drawing.Size(608, 50)
    $LblStatus.ForeColor = $TxtSub
    $LblStatus.Font     = New-Object System.Drawing.Font("Segoe UI", 9)
    $Panel.Controls.Add($LblStatus)

    # ── SỰ KIỆN: DUYỆT THƯ MỤC ────────────────────────────────────────────────
    $BtnBrowse.Add_Click({
        $Dlg = New-Object System.Windows.Forms.OpenFileDialog
        $Dlg.Title           = "Chọn thư mục"
        $Dlg.ValidateNames   = $false
        $Dlg.CheckFileExists = $false
        $Dlg.FileName        = "Chọn_Thư_Mục_Này"
        if ($Dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $TxtPath.Text = [System.IO.Path]::GetDirectoryName($Dlg.FileName)
        }
    })

    # ── DỌN DẸP KHI ĐÓNG FORM ─────────────────────────────────────────────────
    $Form.Add_FormClosing({
        if ($null -ne $Script:BoDem)       { $Script:BoDem.Stop(); $Script:BoDem.Dispose() }
        if ($null -ne $Script:TienTrinhPS) {
            try { $Script:TienTrinhPS.Stop() | Out-Null } catch {}
            $Script:TienTrinhPS.Dispose()
        }
        if ($null -ne $Script:KgChay)      { $Script:KgChay.Close(); $Script:KgChay.Dispose() }
    })

    # ── SỰ KIỆN: THỰC THI ─────────────────────────────────────────────────────
    $BtnRun.Add_Click({
        $DuongDan = $TxtPath.Text.Trim('"').Trim()
        if ([string]::IsNullOrWhiteSpace($DuongDan)) {
            $LblStatus.Text     = "Cảnh báo: Bạn chưa nhập đường dẫn!"
            $LblStatus.ForeColor = $Danger
            return
        }

        # Xử lý ổ đĩa ánh xạ → đường dẫn UNC thực
        $DuongDanThuc = $DuongDan
        if ($DuongDan -match "^([A-Za-z]):") {
            $KyTuO = $matches[1]
            $RegMang = Get-ItemProperty -Path "HKCU:\Network\$KyTuO" -ErrorAction SilentlyContinue
            if ($null -ne $RegMang -and -not [string]::IsNullOrEmpty($RegMang.RemotePath)) {
                $DuongDanThuc = $DuongDan -replace "^[A-Za-z]:", $RegMang.RemotePath
            }
        }

        if (-not (Test-Path -LiteralPath $DuongDanThuc)) {
            $LblStatus.Text      = "Lỗi: Không tìm thấy đường dẫn '$DuongDanThuc'."
            $LblStatus.ForeColor = $Danger
            return
        }

        # Khóa UI, khởi động thanh tiến trình
        $BtnRun.Enabled      = $false
        $BtnRun.ForeColor    = $TxtSub
        $ProgBar.Visible     = $true
        $ListLog.Items.Clear()
        $ListLog.Items.Add("> Bắt đầu quét...") | Out-Null
        $LblStatus.Text      = "Đang xử lý, vui lòng không tắt công cụ..."
        $LblStatus.ForeColor = $TxtSub

        $CapQuyenMang = $ChkTrust.Checked
        $TenMayChu    = $null
        if ($CapQuyenMang -and $DuongDanThuc -match "^\\\\([^\\]+)") {
            $TenMayChu = $matches[1]
        }

        # Khởi tạo hàng đợi log + runspace
        $Script:HangDoiLog  = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
        $Script:KgChay      = [runspacefactory]::CreateRunspace()
        $Script:KgChay.ThreadOptions = "ReuseThread"
        $Script:KgChay.Open()
        $Script:TienTrinhPS = [powershell]::Create()
        $Script:TienTrinhPS.Runspace = $Script:KgChay

        # ✅ ĐÃ FIX — đổi $Host → $MayChu
		[void]$Script:TienTrinhPS.AddScript({
			param($Path, $MayChu, $Queue)
			try {
				$Note = ""
				if ($MayChu) {
					$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey"
					if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
					Set-ItemProperty -Path $RegPath -Name $MayChu -Value "1" -Type String -Force
					$Note = " (Đã cấp quyền mạng cho: $MayChu)"
				}
				$Count = 0
				Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
					$_ | Unblock-File -ErrorAction SilentlyContinue
					$Count++
					$Display = $_.FullName
					if ($Display.Length -gt 70) { $Display = "..." + $Display.Substring($Display.Length - 67) }
					$Queue.Enqueue("[$Count] $Display")
				}
				if ($Count -eq 0) { return "OK|Không tìm thấy tập tin nào cần xử lý.$Note" }
				return "OK|Đã mở khóa $Count tập tin thành công.$Note"
			} catch {
				return "ERR|$_"
			}
		}).AddArgument($DuongDanThuc).AddArgument($TenMayChu).AddArgument($Script:HangDoiLog)

        $Script:KqAsync = $Script:TienTrinhPS.BeginInvoke()

        # Timer poll 100ms — không block UI thread
        $Script:BoDem          = New-Object System.Windows.Forms.Timer
        $Script:BoDem.Interval = 100

        $Script:BoDem.Add_Tick({
            # Đọc log từ hàng đợi concurrent, dùng BeginUpdate để chống flicker
            $Dong = ""
            $CoBanCap = $false
            $ListLog.BeginUpdate()
            while ($Script:HangDoiLog.TryDequeue([ref]$Dong)) {
                $ListLog.Items.Add($Dong) | Out-Null
                if ($ListLog.Items.Count -gt 200) { $ListLog.Items.RemoveAt(0) }
                $CoBanCap = $true
            }
            if ($CoBanCap) { $ListLog.TopIndex = $ListLog.Items.Count - 1 }
            $ListLog.EndUpdate()

            if (-not $Script:KqAsync.IsCompleted) { return }

            # Job xong — dọn dẹp
            $Script:BoDem.Stop()
            $Script:BoDem.Dispose()
            $Script:BoDem = $null

            $KQ = $null
            try   { $KQ = $Script:TienTrinhPS.EndInvoke($Script:KqAsync) }
            catch { $KQ = "ERR|Đứt kết nối luồng ngầm: $_" }
            finally {
                $Script:TienTrinhPS.Dispose(); $Script:TienTrinhPS = $null
                $Script:KgChay.Close(); $Script:KgChay.Dispose(); $Script:KgChay = $null
            }

            $Parts = ($KQ -as [string]) -split "\|", 2
            if ($Parts[0] -eq "OK") {
                $ListLog.Items.Add("> $($Parts[1])") | Out-Null
                $ListLog.TopIndex    = $ListLog.Items.Count - 1
                $LblStatus.Text      = $Parts[1]
                $LblStatus.ForeColor = $Success
            } else {
                $LblStatus.Text      = "Lỗi hệ thống: $($Parts[1])"
                $LblStatus.ForeColor = $Danger
            }

            $ProgBar.Visible  = $false
            $BtnRun.Enabled   = $true
            $BtnRun.ForeColor = $Txt
        })

        $Script:BoDem.Start()
    })

    [void]$Form.ShowDialog()

} catch {
    [System.Windows.Forms.MessageBox]::Show("Lỗi khởi tạo: $_", "Lỗi Hệ Thống", 0, 16)
}