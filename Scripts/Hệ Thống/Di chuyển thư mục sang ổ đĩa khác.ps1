# ==============================================================================
# Tên công cụ: VIETTOOLBOX - USER DATA MANAGER (V24.15 - REAL PROGRESS)
# Tác giả: Kỹ Thuật Viên
# Nâng cấp: Thanh Progress nhảy theo % số lượng thư mục hoàn thành.
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 
    [System.Windows.MessageBox]::Show("Chuột phải chọn 'Run as Administrator' nhé sếp!", "Lỗi", 0, 48); exit 
}

$global:dangXuLy = $false

# --- GIAO DIỆN XAML ---
$maXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - User Data Manager" Width="550" Height="650" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border CornerRadius="15" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Border Height="50" VerticalAlignment="Top" Background="#1E293B" CornerRadius="15,15,0,0">
                <Grid>
                    <TextBlock Text="📂 QUẢN LÝ DỮ LIỆU USER (V24.15 PRO)" Foreground="#38BDF8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Margin="20,0,0,0"/>
                    <Button Name="NutDong" Content="✕" Width="45" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="16" Cursor="Hand" FontWeight="Bold"/>
                </Grid>
            </Border>

            <StackPanel Margin="30,70,30,20">
                <Button Name="NutQuet" Content="🔍 QUÉT TÌM DỮ LIỆU CŨ" Height="40" Background="#6366F1" Foreground="White" FontWeight="Bold" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>

                <TextBlock Text="Ổ ĐĨA DỮ LIỆU (D:\, E:\...):" Foreground="#94A3B8" FontSize="11" Margin="0,15,0,5"/>
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtO_Dich" Grid.Column="0" Height="30" VerticalContentAlignment="Center" Text="D:\" Background="#1E293B" Foreground="White" BorderBrush="#334155" Padding="8,0"/>
                    <Button Name="NutChonO" Grid.Column="1" Content="📁 Chọn" Width="60" Margin="5,0,0,0" Background="#334155" Foreground="White" Cursor="Hand"/>
                </Grid>

                <CheckBox Name="ChkDesktop" Content="Bao gồm cả màn hình DESKTOP" Foreground="#F87171" IsChecked="False" Margin="0,0,0,10"/>

                <Grid Margin="0,5,0,10">
                    <ProgressBar Name="ThanhChay" Height="15" Minimum="0" Maximum="100" Value="0" Foreground="#10B981" Background="#334155" BorderThickness="0">
                        <ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="7"/></Style></ProgressBar.Resources>
                    </ProgressBar>
                    <TextBlock Name="TxtPhanTram" Text="0%" Foreground="White" FontSize="10" HorizontalAlignment="Center" VerticalAlignment="Center" FontWeight="Bold"/>
                </Grid>

                <Button Name="NutTo_D" Content="🚀 CHUYỂN SANG Ổ MỚI (C ➔ D/E)" Height="55" Background="#10B981" Foreground="White" FontWeight="Bold" FontSize="15" Cursor="Hand">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                </Button>

                <Grid Margin="0,15,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button Name="NutRevertOnly" Grid.Column="0" Content="🔄 Về lại C (Chỉ đường dẫn gốc)" Height="50" Background="#334155" Foreground="White" FontSize="11" Margin="0,0,5,0" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                    <Button Name="NutRevertFull" Grid.Column="1" Content="⏪ Về lại C + FILE cũ" Height="50" Background="#F59E0B" Foreground="White" FontWeight="Bold" FontSize="11" Margin="5,0,0,0" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <Button Name="NutDung" Content="⏹ DỪNG LẠI" Height="35" Background="#EF4444" Foreground="White" FontWeight="Bold" Visibility="Hidden" Margin="0,15,0,0">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                </Button>
                
                <Border Background="#1E293B" CornerRadius="8" Padding="10" Height="100" Margin="0,15,0,0">
                    <ScrollViewer Name="Scroller"><TextBlock Name="TxtLog" Text="Sẵn sàng." Foreground="#38BDF8" FontSize="11" TextWrapping="Wrap" TextAlignment="Left"/></ScrollViewer>
                </Border>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($maXAML)))
$CuaSo = [Windows.Markup.XamlReader]::Load($reader)

$txtO_Dich = $CuaSo.FindName("TxtO_Dich"); $txtLog = $CuaSo.FindName("TxtLog"); $scroller = $CuaSo.FindName("Scroller")
$nutChonO = $CuaSo.FindName("NutChonO"); $nutTo_D = $CuaSo.FindName("NutTo_D")
$nutRevertOnly = $CuaSo.FindName("NutRevertOnly"); $nutRevertFull = $CuaSo.FindName("NutRevertFull")
$nutQuet = $CuaSo.FindName("NutQuet"); $chkDesktop = $CuaSo.FindName("ChkDesktop")
$thanhChay = $CuaSo.FindName("ThanhChay"); $txtPhanTram = $CuaSo.FindName("TxtPhanTram")
$nutDung = $CuaSo.FindName("NutDung"); $nutDong = $CuaSo.FindName("NutDong")

$CuaSo.Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$nutDong.Add_Click({ $CuaSo.Close() })

function Get-FolderSize($path) {
    if (!(Test-Path $path)) { return "0 MB" }
    $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($size -ge 1GB) { return "{0:N2} GB" -f ($size / 1GB) }
    if ($size -ge 1MB) { return "{0:N2} MB" -f ($size / 1MB) }
    return " < 1 MB"
}

function Write-Log($message) {
    $txtLog.Text += "`n> $message"
    $scroller.ScrollToEnd()
    $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
}

$nutChonO.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") { $txtO_Dich.Text = $dialog.SelectedPath }
})

# --- HÀM THỰC THI CHÍNH ---
function Execute-Action($TargetBase, $Mode) {
    $global:dangXuLy = $true
    $nutDung.Visibility = "Visible"
    $nutTo_D.IsEnabled = $false; $nutRevertOnly.IsEnabled = $false; $nutRevertFull.IsEnabled = $false
    
    $folders = @(
        @{ ID="{374DE290-123F-4565-9164-39C4925E467B}"; Name="Downloads" },
        @{ ID="Personal"; Name="Documents" },
        @{ ID="My Pictures"; Name="Pictures" },
        @{ ID="My Music"; Name="Music" },
        @{ ID="My Video"; Name="Videos" }
    )
    if ($chkDesktop.IsChecked) { $folders += @{ ID="Desktop"; Name="Desktop" } }

    $totalFolders = $folders.Count
    $thanhChay.Value = 0
    $txtPhanTram.Text = "0%"

    try {
        $RegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $currentIdx = 0
        
        foreach ($f in $folders) {
            if ($global:dangXuLy -eq $false) { break }
            
            $OldRegPath = (Get-ItemProperty -Path $RegKey -Name $f.ID -ErrorAction SilentlyContinue).$($f.ID)
            
            if ($Mode -eq 0) { 
                $Source = $OldRegPath; $Dest = Join-Path $TargetBase $f.Name
            } else { 
                $Source = Join-Path $TargetBase $f.Name; $Dest = Join-Path $env:USERPROFILE $f.Name
            }

            if (!(Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }

            if (($Mode -eq 0 -or $Mode -eq 2) -and $Source -and (Test-Path $Source) -and ($Source.ToLower() -ne $Dest.ToLower())) {
                $size = Get-FolderSize $Source
                Write-Log "[$($currentIdx + 1)/$totalFolders] Đang chuyển $($f.Name) ($size)..."
                
                $arg = "`"$Source`" `"$Dest`" /E /MOVE /R:1 /W:1 /MT:32 /NDL /NFL /NJH /NJS /XJ /XF desktop.ini Thumbs.db"
                $proc = Start-Process robocopy -ArgumentList $arg -WindowStyle Hidden -PassThru
                while (-not $proc.HasExited) {
                    if ($global:dangXuLy -eq $false) { Stop-Process -Id $proc.Id -Force; break }
                    Start-Sleep -Milliseconds 200
                }
            } else {
                Write-Log "ℹ️ Bỏ qua/Chỉ đổi Registry: $($f.Name)"
            }
            Set-ItemProperty -Path $RegKey -Name $f.ID -Value $Dest -Force
            
            # CẬP NHẬT THANH PROGRESS THEO MỤC
            $currentIdx++
            $percent = [math]::Round(($currentIdx / $totalFolders) * 100)
            $thanhChay.Value = $percent
            $txtPhanTram.Text = "$percent%"
            $CuaSo.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
        }

        if ($global:dangXuLy) { 
            Write-Log "🎉 HOÀN TẤT 100%!"
            [System.Windows.MessageBox]::Show("Xong rồi sếp! Explorer sẽ khởi động lại.", "Hoàn tất", 0, 64)
            Stop-Process -Name explorer -Force
        }
    } catch { Write-Log "❌ LỖI: $_" } finally {
        $global:dangXuLy = $false; $nutDung.Visibility = "Hidden"
        $nutTo_D.IsEnabled = $true; $nutRevertOnly.IsEnabled = $true; $nutRevertFull.IsEnabled = $true
    }
}

$nutQuet.Add_Click({
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" }
    foreach ($d in $drives) {
        $path = Join-Path ($d.Name + ":\") "User_Files"
        if (Test-Path $path) { $txtO_Dich.Text = $d.Name + ":\"; $txtLog.Text = "✨ Thấy dữ liệu cũ!"; break }
    }
})

$nutTo_D.Add_Click({ Execute-Action (Join-Path $txtO_Dich.Text "User_Files") 0 })
$nutRevertOnly.Add_Click({ Execute-Action (Join-Path $txtO_Dich.Text "User_Files") 1 })
$nutRevertFull.Add_Click({ Execute-Action (Join-Path $txtO_Dich.Text "User_Files") 2 })
$nutDung.Add_Click({ $global:dangXuLy = $false })

$CuaSo.ShowDialog() | Out-Null