# ==============================================================================
# Công cụ: VIETTOOLBOX NOTICE - CỔNG ĐẨY TIN (DÙNG KEY TỪ ADMIN)
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 🚨 KIỂM TRA KEY TỪ HỆ THỐNG ADMIN 🚨
if (-not $Global:GH_TOKEN -or $Global:GH_TOKEN -eq "") {
    [System.Windows.Forms.MessageBox]::Show("Không tìm thấy mã xác thực! Vui lòng mở từ bản Admin.", "Lỗi Truy Cập")
    exit
}

$GH_Token = $Global:GH_TOKEN
$Owner = "tuantran19912512"
$Repo = "Windows-tool-box"
$FilePath = "ThongBao.txt"

# --- GIAO DIỆN ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "ĐIỀU KHIỂN THÔNG BÁO - ADMIN MODE"; $form.Size = "600,450"; $form.BackColor = "#0A0702"; $form.StartPosition = "CenterScreen"
$fontT = New-Object System.Drawing.Font("Segoe UI Bold", 12); $fontS = New-Object System.Drawing.Font("Segoe UI", 10)

$lbl1 = New-Object System.Windows.Forms.Label; $lbl1.Text = "NỘI DUNG CHO KHÁCH:"; $lbl1.Location = "20,20"; $lbl1.Size = "540,25"; $lbl1.ForeColor = "#007ACC"; $lbl1.Font = $fontT
$txtKhach = New-Object System.Windows.Forms.TextBox; $txtKhach.Location = "20,50"; $txtKhach.Size = "540,30"; $txtKhach.Font = $fontS; $txtKhach.Text = "MỚI CẬP NHẬT V174..."

$lbl2 = New-Object System.Windows.Forms.Label; $lbl2.Text = "NỘI DUNG CHO ADMIN:"; $lbl2.Location = "20,100"; $lbl2.Size = "540,25"; $lbl2.ForeColor = "#FFB300"; $lbl2.Font = $fontT
$txtAdmin = New-Object System.Windows.Forms.TextBox; $txtAdmin.Location = "20,130"; $txtAdmin.Size = "540,30"; $txtAdmin.Font = $fontS; $txtAdmin.Text = "Chào Sếp! Hệ thống ổn định."

$btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = "🚀 CẬP NHẬT LÊN GITHUB"; $btnPush.Location = "20,200"; $btnPush.Size = "540,60"; $btnPush.BackColor = "#FFB300"; $btnPush.Font = $fontT; $btnPush.FlatStyle = "Flat"
$txtStatus = New-Object System.Windows.Forms.TextBox; $txtStatus.Location = "20,280"; $txtStatus.Size = "540,100"; $txtStatus.Multiline = $true; $txtStatus.ReadOnly = $true; $txtStatus.BackColor = "#1A1305"; $txtStatus.ForeColor = "#00FF00"; $txtStatus.Font = New-Object System.Drawing.Font("Consolas", 9)

$form.Controls.AddRange(@($lbl1, $txtKhach, $lbl2, $txtAdmin, $btnPush, $txtStatus))

$btnPush.Add_Click({
    $btnPush.Enabled = $false; $txtStatus.Text = "Đang kết nối GitHub qua Token Admin..."
    
    $FinalContent = "Khách: $($txtKhach.Text)`nAdmin: $($txtAdmin.Text)"
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($FinalContent)
    $B64_Content = [System.Convert]::ToBase64String($Bytes)
    $ApiUrl = "https://api.github.com/repos/$Owner/$Repo/contents/$FilePath"
    $Headers = @{ "Authorization" = "token $GH_Token"; "Accept" = "application/vnd.github.v3+json" }
    
    try {
        $FileRes = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Get
        $SHA = $FileRes.sha
        $Body = @{ message = "Update ThongBao.txt"; content = $B64_Content; sha = $SHA } | ConvertTo-Json
        Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Put -Body $Body | Out-Null
        $txtStatus.Text = "✅ THÀNH CÔNG!`nTin nhắn đã được đồng bộ lên máy khách."
    } catch {
        $txtStatus.Text = "❌ LỖI: " + $_.Exception.Message
    }
    $btnPush.Enabled = $true
})
$form.ShowDialog() | Out-Null