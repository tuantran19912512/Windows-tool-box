# 1. Gói toàn bộ lệnh tải file và lệnh chạy tool vào một chuỗi (sử dụng @" "@ để viết nhiều dòng)
$CodeThucThi = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
`$FileLocalTam = `"$env:TEMP\Config.json`"
Write-Host 'Dang tai file cau hinh tu he thong...' -ForegroundColor Cyan
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/Config.json' -OutFile `$FileLocalTam -UseBasicParsing

Write-Host 'Dang khoi dong dong co toi uu...' -ForegroundColor Green
& ([ScriptBlock]::Create((irm 'https://christitus.com/win'))) -Config `$FileLocalTam -Run
"@

# 2. Mã hóa sang Base64 để truyền đi an toàn tuyệt đối, không sợ vỡ cú pháp
$ChuoiByte = [System.Text.Encoding]::Unicode.GetBytes($CodeThucThi)
$MaHoaBase64 = [Convert]::ToBase64String($ChuoiByte)

# 3. Kích nổ tiến trình mới. Bỏ tham số Hidden đi để nó hiện cửa sổ đen lên.
# Thêm tham số -NoExit để nếu chạy xong (hoặc có lỗi) cửa sổ vẫn giữ nguyên cho anh xem chữ, không bị chớp tắt.
Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -EncodedCommand $MaHoaBase64"