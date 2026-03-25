# ==============================================================================
# Tên công cụ: PHÂN TÍCH DUNG LƯỢNG (BẢN CHUẨN TREESIZE CLONE)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc trị: BỎ CODE ẨN CỬA SỔ (Để không "bắt cóc" Menu chính), Giao diện siêu mượt
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- ĐÃ XÓA TẬN GỐC ĐOẠN CODE WIN32SHOWWINDOWASYNC ĐỂ BẢO VỆ MENU CHÍNH ---

# 1. NHÂN C# TÍNH DUNG LƯỢNG SIÊU TỐC (CÓ ASYNC TASK)
if (-not ([System.Management.Automation.PSTypeName]'VietToolbox.DirScanner').Type) {
    $Source = @"
    using System; using System.IO; using System.Threading.Tasks;
    namespace VietToolbox {
        public class DirScanner {
            public static bool CancelFlag = false;
            public static long GetSize(string path) {
                if (CancelFlag) return 0;
                long size = 0; 
                try {
                    DirectoryInfo d = new DirectoryInfo(path);
                    try { FileInfo[] files = d.GetFiles(); foreach (FileInfo fi in files) { if (CancelFlag) return size; size += fi.Length; } } catch { }
                    try { DirectoryInfo[] dirs = d.GetDirectories(); foreach (DirectoryInfo di in dirs) { if (CancelFlag) return size; if ((di.Attributes & FileAttributes.ReparsePoint) == 0) { size += GetSize(di.FullName); } } } catch { }
                } catch { } return size;
            }
            public static Task<long> GetSizeAsync(string path) {
                return Task.Run(() => GetSize(path));
            }
        }
    }
"@
    try { Add-Type -TypeDefinition $Source -ReferencedAssemblies "System.Windows.Forms" -ErrorAction SilentlyContinue } catch { }
}

# HÀM BƠM OXY CHO GIAO DIỆN (CHỐNG ĐƠ)
$Global:CapNhatGiaoDien = {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $delegate = [System.Windows.Threading.DispatcherOperationCallback] { param($f) $f.Continue = $false; return $null }
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, $delegate, $frame) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}
$BrushConv = New-Object System.Windows.Media.BrushConverter
$Global:CancelScan = $false

# 2. GIAO DIỆN XAML WPF
$inputXML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox - Phân Tích Dung Lượng" Width="1100" Height="750" Background="Transparent" AllowsTransparency="True" WindowStyle="None" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Border CornerRadius="12" BorderBrush="#334155" BorderThickness="1" Background="#0F172A">
        <Grid>
            <Grid Height="40" VerticalAlignment="Top" Background="#1E293B">
                <Grid.Clip><RectangleGeometry Rect="0,0,1100,40" RadiusX="12" RadiusY="12"/></Grid.Clip>
                <TextBlock Text="📂 PHÂN TÍCH DUNG LƯỢNG (PHONG CÁCH TREESIZE)" Foreground="#38BDF8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Margin="15,0,0,0"/>
                <Button Name="BtnClose" Content="✕" Width="40" HorizontalAlignment="Right" Background="Transparent" Foreground="#EF4444" BorderThickness="0" FontSize="14" Cursor="Hand" FontWeight="Bold"/>
            </Grid>
            
            <Grid Margin="20,60,20,0" VerticalAlignment="Top">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/><ColumnDefinition Width="130"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                    <Button Name="BtnBack" Grid.Column="0" Content="⬅️ Trở lại" Background="#475569" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0" Width="80" ToolTip="Lên một thư mục"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <TextBox Name="TxtPath" Grid.Column="1" Text="C:\" Height="35" Background="#1E293B" Foreground="White" BorderBrush="#334155" VerticalContentAlignment="Center" Padding="10,0" FontSize="14" Margin="0,0,10,0"><TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></TextBox.Resources></TextBox>
                    <Button Name="BtnBrowse" Grid.Column="2" Content="Duyệt..." Background="#334155" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button Name="BtnScan" Grid.Column="3" Content="🚀 BẮT ĐẦU QUÉT" Background="#3B82F6" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                    <Button Name="BtnCancel" Grid.Column="4" Content="⏹ HỦY QUÉT" Background="#EF4444" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand" IsEnabled="False" Opacity="0.5"><Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources></Button>
                </Grid>
                <Border Grid.Row="2" Background="#1E293B" CornerRadius="6" Padding="15,10" Margin="0,15,0,0">
                    <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <TextBlock Name="LblDiskDetails" Text="💽 Thông tin hệ thống: Sẵn sàng" Foreground="#10B981" FontWeight="SemiBold" FontSize="13" VerticalAlignment="Center" Margin="0,0,20,0"/>
                        <ProgressBar Name="ProgDisk" Grid.Column="1" Height="10" Value="0" Maximum="100" Background="#0F172A" Foreground="#10B981" BorderThickness="0"><ProgressBar.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></ProgressBar.Resources></ProgressBar>
                    </Grid>
                </Border>
            </Grid>

            <Border Margin="20,185,20,40" Background="#0B1120" BorderBrush="#334155" BorderThickness="1" CornerRadius="6">
                <ListView Name="ListDir" Background="Transparent" Foreground="#E2E8F0" BorderThickness="0" FontFamily="Consolas" FontSize="14" Margin="5">
                    <ListView.Resources>
                        <Style TargetType="GridViewColumnHeader"><Setter Property="Background" Value="#1E293B"/><Setter Property="Foreground" Value="#94A3B8"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Padding" Value="10,5"/><Setter Property="HorizontalContentAlignment" Value="Left"/></Style>
                        <Style TargetType="ListViewItem"><Setter Property="Margin" Value="0,2"/><Setter Property="Cursor" Value="Hand"/><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#334155"/></Trigger></Style.Triggers></Style>
                    </ListView.Resources>
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="  THƯ MỤC / TẬP TIN" DisplayMemberBinding="{Binding Name}" Width="450"/>
                            <GridViewColumn Header="DUNG LƯỢNG" DisplayMemberBinding="{Binding SizeStr}" Width="150"/>
                            <GridViewColumn Header="TỶ LỆ %" DisplayMemberBinding="{Binding PercentStr}" Width="250"/>
                            <GridViewColumn Header="LOẠI" DisplayMemberBinding="{Binding CountStr}" Width="100"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </Border>
            <TextBlock Name="LblStatus" Text="Gợi ý: Click đúp vào một thư mục để đi sâu vào bên trong." VerticalAlignment="Bottom" Margin="20,0,0,10" Foreground="#64748B" FontSize="12"/>
        </Grid>
    </Border>
</Window>
"@

try { $ToolWindow = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($inputXML)))) } catch { [System.Windows.MessageBox]::Show("Lỗi XAML: $($_.Exception.Message)"); exit }

$txtPath = $ToolWindow.FindName("TxtPath"); $btnBrowse = $ToolWindow.FindName("BtnBrowse")
$btnScan = $ToolWindow.FindName("BtnScan"); $btnCancel = $ToolWindow.FindName("BtnCancel"); $btnBack = $ToolWindow.FindName("BtnBack")
$lblDiskDetails = $ToolWindow.FindName("LblDiskDetails"); $progDisk = $ToolWindow.FindName("ProgDisk")
$listDir = $ToolWindow.FindName("ListDir"); $lblStatus = $ToolWindow.FindName("LblStatus"); $btnClose = $ToolWindow.FindName("BtnClose")

$ToolWindow.Add_MouseLeftButtonDown({ $ToolWindow.DragMove() }); $btnClose.Add_Click({ $ToolWindow.Close() })

# 3. HÀM QUÉT CHÍNH
function Start-ScanFolder($path) {
    if (-not (Test-Path $path)) { [System.Windows.MessageBox]::Show("Đường dẫn không tồn tại!", "Lỗi"); return }

    $txtPath.Text = $path
    $btnScan.IsEnabled = $false; $btnScan.Opacity = 0.5; $btnCancel.IsEnabled = $true; $btnCancel.Opacity = 1
    $Global:CancelScan = $false; [VietToolbox.DirScanner]::CancelFlag = $false; $listDir.Items.Clear()
    
    try { $root = [System.IO.Path]::GetPathRoot($path); $drive = New-Object System.IO.DriveInfo($root)
        if ($drive.IsReady) { $total = $drive.TotalSize; $free = $drive.AvailableFreeSpace; $used = $total - $free; $pct = [math]::Round(($used / $total) * 100, 1)
            $lblDiskDetails.Text = "💽 Ổ đĩa: $root  |  Tổng: $("{0:N2} GB" -f ($total/1GB))  |  Đã dùng: $("{0:N2} GB" -f ($used/1GB)) ($pct%)  |  Trống: $("{0:N2} GB" -f ($free/1GB))"; $progDisk.Value = $pct }
    } catch {}

    $lblStatus.Text = "Đang lấy danh sách..."; $lblStatus.Foreground = $BrushConv.ConvertFromString("#F59E0B"); &$CapNhatGiaoDien
    
    $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue
    $Global:CurrentItems = @()
    
    foreach ($item in $items) {
        $nType = 0; if ($item.PSIsContainer) { if ($null -ne $item.Attributes -and $item.Attributes.ToString() -match "ReparsePoint") { $nType = 2 } else { $nType = 1 } }
        $icon = if ($nType -eq 1) { "📁" } elseif ($nType -eq 2) { "🔗" } else { "📄" }
        
        $obj = [PSCustomObject]@{
            Name = "$icon $($item.Name)"; Path = $item.FullName; NodeType = $nType; RawSize = 0
            SizeStr = "Đang chờ..."; PercentStr = "[░░░░░░░░░░] 0%"; CountStr = if ($nType -ne 0) { "Thư mục" } else { "Tập tin" }
        }
        $listDir.Items.Add($obj) | Out-Null
        $Global:CurrentItems += $obj
    }
    &$CapNhatGiaoDien

    [long]$totalBytesAll = 0
    foreach ($item in $Global:CurrentItems) {
        if ($Global:CancelScan) { break }
        
        $item.SizeStr = "⏳ Đang tính..."
        $listDir.Items.Refresh(); &$CapNhatGiaoDien

        [long]$sBytes = 0
        if ($item.NodeType -eq 1) { 
            $task = [VietToolbox.DirScanner]::GetSizeAsync($item.Path)
            while (-not $task.IsCompleted) {
                if ($Global:CancelScan) { [VietToolbox.DirScanner]::CancelFlag = $true }
                &$CapNhatGiaoDien
                Start-Sleep -Milliseconds 20
            }
            $sBytes = $task.Result 
        } 
        elseif ($item.NodeType -eq 0) { try { $sBytes = (New-Object System.IO.FileInfo($item.Path)).Length } catch {} }

        $item.RawSize = $sBytes
        $totalBytesAll += $sBytes
        
        $sStr = "0 KB"
        if ($sBytes -ge 1GB) { $sStr = "{0:N2} GB" -f ($sBytes/1GB) } elseif ($sBytes -ge 1MB) { $sStr = "{0:N2} MB" -f ($sBytes/1MB) } elseif ($sBytes -ge 1KB) { $sStr = "{0:N2} KB" -f ($sBytes/1KB) } elseif ($sBytes -gt 0) { $sStr = "{0} B" -f $sBytes }
        $item.SizeStr = $sStr
        $listDir.Items.Refresh(); &$CapNhatGiaoDien
    }

    if ($Global:CancelScan) {
        $lblStatus.Text = "🛑 ĐÃ HỦY THEO YÊU CẦU!"
        $lblStatus.Foreground = $BrushConv.ConvertFromString("#EF4444")
    } else {
        foreach ($item in $Global:CurrentItems) {
            $pct = 0; if ($totalBytesAll -gt 0 -and $item.RawSize -gt 0) { $pct = [math]::Round(($item.RawSize / $totalBytesAll) * 100, 1) }
            $bc = [math]::Round($pct / 10); if ($bc -lt 0) { $bc = 0 }; if ($bc -gt 10) { $bc = 10 }
            $item.PercentStr = "[$("█" * $bc)$("░" * (10 - $bc))] $($pct)%"
        }
        
        $sorted = $Global:CurrentItems | Sort-Object RawSize -Descending
        $listDir.Items.Clear()
        foreach ($s in $sorted) { $listDir.Items.Add($s) | Out-Null }
        
        $totalStr = "{0:N2} GB" -f ($totalBytesAll / 1GB)
        $lblStatus.Text = "✅ Hoàn tất. Tổng dung lượng: $totalStr"
        $lblStatus.Foreground = $BrushConv.ConvertFromString("#10B981")
    }
    $btnScan.IsEnabled = $true; $btnScan.Opacity = 1; $btnCancel.IsEnabled = $false; $btnCancel.Opacity = 0.5
}

# 4. CÁC SỰ KIỆN NÚT BẤM
$btnBrowse.Add_Click({ $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; if ($dialog.ShowDialog() -eq "OK") { Start-ScanFolder $dialog.SelectedPath } })
$btnScan.Add_Click({ Start-ScanFolder $txtPath.Text })
$btnCancel.Add_Click({ 
    $Global:CancelScan = $true; [VietToolbox.DirScanner]::CancelFlag = $true 
    $lblStatus.Text = "🛑 Đang ngắt luồng..."; $lblStatus.Foreground = $BrushConv.ConvertFromString("#EF4444")
})
$btnBack.Add_Click({
    $current = $txtPath.Text; $parent = Split-Path $current -Parent
    if ([string]::IsNullOrEmpty($parent)) { [System.Windows.MessageBox]::Show("Đã ở thư mục gốc!", "Thông báo") } else { Start-ScanFolder $parent }
})

# 5. SỰ KIỆN CHUỘT PHẢI
$listDir.Add_MouseRightButtonUp({
    $item = $listDir.SelectedItem; if ($null -eq $item) { return }
    $cm = New-Object System.Windows.Controls.ContextMenu; $cm.Background = $BrushConv.ConvertFromString("#1E293B"); $cm.Foreground = $BrushConv.ConvertFromString("White"); $cm.BorderBrush = $BrushConv.ConvertFromString("#334155")
    $miOpen = New-Object System.Windows.Controls.MenuItem; $miOpen.Header = "📂 Mở thư mục này"
    $miOpen.Add_Click({ Start-Process "explorer.exe" "/select,`"$($item.Path)`"" })
    $miDel = New-Object System.Windows.Controls.MenuItem; $miDel.Header = "🗑️ Xóa vĩnh viễn"; $miDel.Foreground = $BrushConv.ConvertFromString("#EF4444")
    $miDel.Add_Click({ if ([System.Windows.MessageBox]::Show("Xóa vĩnh viễn:`n$($item.Path)?", "Cảnh báo", "YesNo", "Warning") -eq "Yes") { try { Remove-Item -Path $item.Path -Recurse -Force -ErrorAction Stop; Start-ScanFolder $txtPath.Text } catch { [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)") } } })
    $cm.Items.Add($miOpen); $cm.Items.Add($miDel) | Out-Null; $cm.IsOpen = $true
})

# 6. CLICK ĐÚP CHUI VÀO THƯ MỤC CON
$listDir.Add_MouseDoubleClick({
    $item = $listDir.SelectedItem
    if ($null -ne $item -and $item.NodeType -eq 1) { Start-ScanFolder $item.Path }
    elseif ($null -ne $item -and $item.NodeType -eq 0) { Start-Process $item.Path -ErrorAction SilentlyContinue }
})

$ToolWindow.ShowDialog() | Out-Null