# ==========================================================
# VIETTOOLBOX - PRINTER FIX PRO V4.7 (ULTIMATE AUTH)
# Đặc trị: Lỗi 709 & Quản lý Credential/User chuyên nghiệp
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - PRINTER FIX PRO V4.7" Width="600" Height="850" 
        WindowStartupLocation="CenterScreen" Background="#F1F5F9" FontFamily="Segoe UI">
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>    <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <StackPanel Grid.Row="0" Margin="0,0,0,15">
                <TextBlock Text="CÔNG CỤ ĐẶC TRỊ MÁY IN 709" FontSize="22" FontWeight="Bold" Foreground="#1E3A8A" HorizontalAlignment="Center"/>
                <TextBlock Text="Bản Ultimate Auth - Master Edition" Foreground="#64748B" HorizontalAlignment="Center"/>
            </StackPanel>

            <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="15" BorderBrush="#CBD5E1" BorderThickness="1" Margin="0,0,0,15">
                <StackPanel>
                    <TextBlock Text="DÀNH CHO MÁY CHỦ (SERVER - WIN 11):" FontWeight="Bold" Foreground="#1E293B" Margin="0,0,0,10"/>
                    <Button Name="btnCreateUser" Content="TẠO USER 'print' (PASS: 12345678)" Height="40" Background="#0F172A" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                    <TextBlock Text="* Chạy nút này trên Win 11 để tạo tài khoản share máy in." FontSize="11" Foreground="#64748B" Margin="0,5,0,0"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="2" Background="White" CornerRadius="8" Padding="15" BorderBrush="#CBD5E1" BorderThickness="1" Margin="0,0,0,15">
                <StackPanel>
                    <TextBlock Text="DÀNH CHO MÁY CON (CLIENT - WIN 10):" FontWeight="Bold" Foreground="#1E293B" Margin="0,0,0,10"/>
                    <Grid Margin="0,5">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <TextBlock Text="IP/Tên Máy chủ:" FontSize="12" Margin="0,0,0,3"/>
                            <TextBox Name="txtIP" Height="30" VerticalContentAlignment="Center" Padding="5,0"/>
                        </StackPanel>
                        <StackPanel Grid.Column="2">
                            <TextBlock Text="Tên Máy in Share:" FontSize="12" Margin="0,0,0,3"/>
                            <TextBox Name="txtName" Height="30" VerticalContentAlignment="Center" Padding="5,0"/>
                        </StackPanel>
                    </Grid>
                    
                    <StackPanel Orientation="Horizontal" Margin="0,10">
                        <RadioButton Name="rbPrint" Content="Dùng User 'print'" IsChecked="True" Margin="0,0,20,0" FontWeight="SemiBold"/>
                        <RadioButton Name="rbGuest" Content="Dùng User 'Guest' (Pass trống)" FontWeight="SemiBold"/>
                    </StackPanel>
                    
                    <Button Name="btnAddCred" Content="LƯU CREDENTIALS VÀO MÁY CON" Height="40" Background="#0369A1" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </StackPanel>
            </Border>

            <TextBox Name="txtLog" Grid.Row="4" Margin="0,0,0,15" IsReadOnly="True" MinHeight="150"
                     Background="#0F172A" Foreground="#38BDF8" FontFamily="Consolas" 
                     FontSize="12" Padding="10" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>

            <StackPanel Grid.Row="5">
                <ProgressBar Name="pgBar" Height="15" Margin="0,0,0,15" Foreground="#22C55E" Background="#F1F5F9"/>
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="btnFixServer" Grid.Column="0" Content="FIX REGISTRY MÁY CHỦ" Height="55" Background="#475569" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                    <Button Name="btnFixClient" Grid.Column="2" Content="FIX TẤT CẢ MÁY CON" Height="55" Background="#2563EB" Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </Grid>
            </StackPanel>
        </Grid>
    </ScrollViewer>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGiaoDien)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

# Ánh xạ biến UI
$txtIP = $CuaSo.FindName("txtIP"); $txtName = $CuaSo.FindName("txtName"); $txtLog = $CuaSo.FindName("txtLog")
$pgBar = $CuaSo.FindName("pgBar"); $btnCreateUser = $CuaSo.FindName("btnCreateUser"); $btnAddCred = $CuaSo.FindName("btnAddCred")
$btnFixServer = $CuaSo.FindName("btnFixServer"); $btnFixClient = $CuaSo.FindName("btnFixClient")
$rbPrint = $CuaSo.FindName("rbPrint"); $rbGuest = $CuaSo.FindName("rbGuest")

function Log ($msg) { 
    $TimeStr = (Get-Date).ToString("HH:mm:ss")
    $txtLog.AppendText("[$TimeStr] $msg`r`n")
    $txtLog.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

# --- LOGIC MÁY CHỦ: TẠO USER ---
$btnCreateUser.Add_Click({
    Log "Tiến hành tạo User 'print' trên máy chủ..."
    try {
        if (Get-LocalUser -Name "print" -ErrorAction SilentlyContinue) {
            net user print 12345678 /active:yes
            Log "⚠️ User 'print' đã tồn tại, đã reset password về 12345678."
        } else {
            net user print 12345678 /add /passwordchg:no /expires:never
            Log "✅ Đã tạo thành công User 'print' với pass 12345678."
        }
        wmic useraccount where "name='print'" set passwordexpires=false | Out-Null
        Log "[+] Đã thiết lập: Mật khẩu không bao giờ hết hạn."
    } catch { Log "❌ Lỗi tạo User! Kiểm tra quyền Admin." }
})

# --- LOGIC MÁY CON: NẠP CREDENTIAL ---
$btnAddCred.Add_Click({
    if (-not $txtIP.Text) { [System.Windows.MessageBox]::Show("Nhập IP máy chủ đã sếp ơi!"); return }
    $Target = $txtIP.Text
    $User = if ($rbPrint.IsChecked) { "print" } else { "Guest" }
    $Pass = if ($rbPrint.IsChecked) { "12345678" } else { "" }
    
    Log "Đang nạp Credential cho máy chủ: $Target..."
    cmdkey /add:$Target /user:$User /pass:$Pass | Out-Null
    Log "✅ Đã lưu thông tin đăng nhập ($User) vào Windows Vault."
})

# --- LOGIC FIX TỔNG THỂ ---
$LogicFix = {
    param($isClient)
    $pgBar.Value = 10; Log "Bắt đầu Fix hệ thống..."
    
    # Registry Fix (Chung cho cả 2)
    Log "Đang xử lý Registry (RPC & Privacy)..."
    $reg = @(
        @("HKLM:\System\CurrentControlSet\Control\Print", "RpcAuthnLevelPrivacyEnabled", 0),
        @("HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint", "RestrictDriverInstallationToAdministrators", 0),
        @("HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC", "RpcUseNamedPipeProtocol", 1),
        @("HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC", "RpcProtocols", 7)
    )
    foreach ($item in $reg) {
        if (!(Test-Path $item[0])) { New-Item $item[0] -Force | Out-Null }
        Set-ItemProperty -Path $item[0] -Name $item[1] -Value $item[2] -Type DWORD -Force
    }

    if ($isClient -and $txtIP.Text -and $txtName.Text) {
        $port = "\\$($txtIP.Text)\$($txtName.Text)"
        Log "Đang cưỡng chế nạp Local Port: $port"
        Add-PrinterPort -Name $port -ErrorAction SilentlyContinue
    }

    Log "Đang Deep Reset dịch vụ in ấn (Dọn sạch hàng đợi)..."
    Stop-Service Spooler -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS\*" -Force | Remove-Item -Force -ErrorAction SilentlyContinue
    Start-Service Spooler
    
    $pgBar.Value = 100; Log "🚀 TẤT CẢ ĐÃ XONG! Sẵn sàng in ấn."
    [System.Windows.MessageBox]::Show("Xong rồi nhé!", "VietToolbox")
}

$btnFixServer.Add_Click({ &$LogicFix $false })
$btnFixClient.Add_Click({ &$LogicFix $true })

Log "Sẵn sàng phục vụ sếp!"
$CuaSo.ShowDialog() | Out-Null