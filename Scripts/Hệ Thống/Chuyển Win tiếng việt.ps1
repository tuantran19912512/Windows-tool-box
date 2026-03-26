# ==============================================================================
# VIETTOOLBOX V54 - BẢN THÔNG MINH (CHECK EXIST)
# Đặc trị: Tiết kiệm thời gian, không tải lại nếu đã có gói Tiếng Việt
# ==============================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# --- GIAO DIỆN DARK MODE ---
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="VietToolbox Pro v54 - Smart Check" Width="600" Height="460" Background="#0F172A" WindowStartupLocation="CenterScreen">
    <Grid Margin="20">
        <StackPanel>
            <TextBlock Text="VIETTOOLBOX - PHIÊN BẢN THÔNG MINH" Foreground="#38BDF8" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,20"/>
            
            <ProgressBar Name="pbStatus" Height="15" Foreground="#10B981" Background="#1E293B" BorderThickness="0" Value="0" Margin="0,0,0 autor10,10"/>
            <TextBlock Name="lblStatus" Text="Trạng thái: Sẵn sàng check máy..." Foreground="#F1F5F9" HorizontalAlignment="Left" Margin="0,0,0,10"/>

            <TextBox Name="txtLog" Height="180" Background="#1E293B" Foreground="#10B981" FontFamily="Consolas" FontSize="11" 
                     VerticalScrollBarVisibility="Auto" IsReadOnly="True" BorderBrush="#334155" Padding="10"/>

            <Button Name="btnStart" Content="🚀 KIỂM TRA &amp; CÀI ĐẶT" Height="50" Background="#3B82F6" Foreground="White" FontWeight="Bold" Margin="0,20,0,0">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="10"/></Style></Button.Resources>
            </Button>
        </StackPanel>
    </Grid>
</Window>
"@

$Form = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($inputXML.Replace("autor10,10","10")))))
$txtLog = $Form.FindName("txtLog"); $pbStatus = $Form.FindName("pbStatus"); $lblStatus = $Form.FindName("lblStatus"); $btnStart = $Form.FindName("btnStart")

$Sync = [hashtable]::Synchronized(@{ LogBox = $txtLog; PB = $pbStatus; Lbl = $lblStatus; Form = $Form; Running = $false })

$btnStart.Add_Click({
    $btnStart.IsEnabled = $false
    $Sync.Running = $true
    
    $PS = [powershell]::Create().AddScript({
        param($s)
        function Log { param($m,$v,$st) $s.Form.Dispatcher.Invoke([Action]{ 
            if($m){$s.LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $m`r`n"); $s.LogBox.ScrollToEnd()}
            if($v -ne $null){$s.PB.Value=$v}
            if($st){$s.Lbl.Text="Trạng thái: $st"}
        })}

        try {
            # BƯỚC 1: QUÉT HỆ THỐNG (20%)
            Log "Đang quét gói ngôn ngữ trên máy khách..." 20 "Đang kiểm tra..."
            $checkPack = Get-AppxPackage -Name "Microsoft.LanguageExperiencePackvi-VN*"
            
            if ($checkPack) {
                # TRƯỜNG HỢP 1: ĐÃ CÓ GÓI
                Log "PHÁT HIỆN: Máy đã có sẵn gói Tiếng Việt (LXP)." 80 "Đã có sẵn!"
                Log "Bỏ qua bước tải Winget để tiết kiệm thời gian." $null $null
            } else {
                # TRƯỜNG HỢP 2: CHƯA CÓ GÓI -> DÙNG WINGET
                Log "KHÔNG TÌM THẤY: Đang chuẩn bị tải gói qua Winget..." 30 "Đang kết nối Store..."
                
                if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
                    Log "LỖI: Không tìm thấy Winget! Hãy cài App Installer trước." 0 "Thất bại"
                    return
                }

                $process = Start-Process winget -ArgumentList "install --id 9P0W68X0XZPT --source msstore --accept-package-agreements --silent" -PassThru -WindowStyle Hidden
                
                $counter = 0
                while (!$process.HasExited) {
                    $counter++
                    Log $null (30 + ($counter % 40)) "Đang tải dữ liệu ($counter s)..."
                    Start-Sleep -Seconds 1
                }
                Log "Đã cài xong gói từ Store." 70 "Tải xong"
            }

            # BƯỚC 2: THIẾT LẬP MẶC ĐỊNH (90%)
            Log "Đang thiết lập Tiếng Việt làm ngôn ngữ hiển thị chính..." 90 "Đang thiết lập..."
            
            # Ép danh sách ngôn ngữ (Ưu tiên vi-VN lên đầu)
            $langs = New-Object System.Collections.Generic.List[string]
            $langs.Add("vi-VN"); $langs.Add("en-US")
            Set-WinUserLanguageList -LanguageList $langs -Force -ErrorAction SilentlyContinue

            # Ép giao diện (MUI Override)
            if (Get-Command Set-WinUILanguageOverride -ErrorAction SilentlyContinue) {
                Set-WinUILanguageOverride -Language vi-VN
            }

            Log "HOÀN TẤT 100%! ĐANG CHỜ TUẤN XÁC NHẬN..." 100 "Thành công"
            
            # THÔNG BÁO LOGOUT
            [System.Windows.MessageBox]::Show("Xong rồi Tuấn ơi! Máy sẽ Đăng xuất (Logout) ngay sau khi bấm OK.", "VietToolbox")
            
            # Dùng lệnh chuẩn để thoát User
            shutdown /l
        } catch {
            Log "LỖI: $($_.Exception.Message)" 0 "Có lỗi xảy ra"
        }
    }).AddArgument($Sync)

    $PS.BeginInvoke()
})

$Form.ShowDialog() | Out-Null