# Yêu cầu quyền Quản trị viên
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. KHỐI C# NHÚNG: TỐI ƯU RAM & HỘP THOẠI HIỆN ĐẠI (Đổi tên Class thành V13)
if (-not ("APIHeThongV13" -as [type])) {
    $MaCSharp = @"
    using System;
    using System.Runtime.InteropServices;

    public class APIHeThongV13 {
        [DllImport("kernel32.dll")]
        public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, int dwMinimumWorkingSetSize, int dwMaximumWorkingSetSize);
        public static void ToiUuBoNho() { 
            try { SetProcessWorkingSetSize(System.Diagnostics.Process.GetCurrentProcess().Handle, -1, -1); } catch {}
        }

        [ComImport, Guid("DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7")]
        private class FileOpenDialog {}

        [ComImport, Guid("42f85136-db7e-439c-85f1-e4075d135fc8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface IFileOpenDialog {
            [PreserveSig] uint Show([In] IntPtr hwndParent);
            void SetFileTypes([In] uint cFileTypes, [In] IntPtr rgFilterSpec);
            void SetFileTypeIndex([In] uint iFileType);
            void GetFileTypeIndex(out uint piFileType);
            void Advise([In] IntPtr pfde, out uint pdwCookie);
            void Unadvise([In] uint dwCookie);
            void SetOptions([In] uint fos);
            void GetOptions(out uint pfos);
            void SetDefaultFolder([In] IShellItem psi);
            void SetFolder([In] IShellItem psi);
            void GetFolder(out IShellItem ppsi);
            void GetCurrentSelection(out IShellItem ppsi);
            void SetFileName([In, MarshalAs(UnmanagedType.LPWStr)] string pszName);
            void GetFileName([MarshalAs(UnmanagedType.LPWStr)] out string pszName);
            void SetTitle([In, MarshalAs(UnmanagedType.LPWStr)] string pszTitle);
            void SetOkButtonLabel([In, MarshalAs(UnmanagedType.LPWStr)] string pszText);
            void SetFileNameLabel([In, MarshalAs(UnmanagedType.LPWStr)] string pszLabel);
            void GetResult(out IShellItem ppsi);
            void AddPlace([In] IShellItem psi, int fdap);
            void SetDefaultExtension([In, MarshalAs(UnmanagedType.LPWStr)] string pszDefaultExtension);
            void Close([MarshalAs(UnmanagedType.Error)] int hr);
            void SetClientGuid([In] ref Guid guid);
            void ClearClientData();
            void SetFilter([In] IntPtr pFilter);
            void GetResults([In] IntPtr ppenum);
            void GetSelectedItems([In] IntPtr ppsai);
        }

        [ComImport, Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface IShellItem {
            void BindToHandler([In] IntPtr pbc, [In] ref Guid bhid, [In] ref Guid riid, out IntPtr ppv);
            void GetParent(out IShellItem ppsi);
            void GetDisplayName([In] uint sigdnName, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
            void GetAttributes([In] uint sfgaoMask, out uint psfgaoAttribs);
            void Compare([In] IShellItem psi, [In] uint hint, out int piOrder);
        }

        public static string ChonThuMucHienDai() {
            try {
                IFileOpenDialog dialog = (IFileOpenDialog)new FileOpenDialog();
                dialog.SetOptions(0x00000020 | 0x10000000); 
                dialog.SetTitle("Vui lòng chọn thư mục lưu trữ an toàn");
                uint hr = dialog.Show(IntPtr.Zero);
                if (hr == 0) { 
                    IShellItem item;
                    dialog.GetResult(out item);
                    string path;
                    item.GetDisplayName(0x80058000, out path); 
                    return path;
                }
            } catch {}
            return "";
        }
    }
"@
    Add-Type -TypeDefinition $MaCSharp
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# 2. GIAO DIỆN XAML: DASHBOARD KÈM TÍNH NĂNG KHÓA Ổ C
[xml]$GiaoDienXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Flat Backup System" Height="560" Width="760" 
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" 
        WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    
    <Border Background="#1A1A1A" CornerRadius="6" BorderBrush="#333" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid Name="TitleBar" Background="#252526">
                <TextBlock Text="HỆ THỐNG SAO LƯU DỮ LIỆU - DASHBOARD" Foreground="#3498DB" FontWeight="Bold" FontSize="11" VerticalAlignment="Center" Margin="20,0,0,0"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="btnMin" Content="0" FontFamily="Marlett" Width="45" Background="Transparent" Foreground="#888" BorderThickness="0" Cursor="Hand"/>
                    <Button Name="btnClose" Content="r" FontFamily="Marlett" Width="45" Background="Transparent" Foreground="#888" BorderThickness="0" Cursor="Hand"/>
                </StackPanel>
            </Grid>

            <Grid Grid.Row="1" Margin="25,20,25,25">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="280"/>
                    <ColumnDefinition Width="25"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Grid Grid.Column="0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/> 
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <TextBlock Grid.Row="0" Text="THIẾT BỊ LƯU TRỮ" Foreground="#777" FontSize="11" FontWeight="Bold" Margin="0,0,0,8"/>
                    
                    <ListBox Name="lstDrives" Grid.Row="1" Background="Transparent" BorderThickness="0" Margin="0,0,0,15" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemContainerStyle>
                            <Style TargetType="ListBoxItem">
                                <Setter Property="Margin" Value="0,0,0,8"/>
                                <Setter Property="Cursor" Value="Hand"/>
                                <Setter Property="IsEnabled" Value="{Binding IsEnabled}"/>
                                <Setter Property="Opacity" Value="{Binding Opacity}"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="ListBoxItem">
                                            <Border Name="Bd" Background="#252526" BorderBrush="Transparent" BorderThickness="2" CornerRadius="5" Padding="12,10">
                                                <ContentPresenter />
                                            </Border>
                                            <ControlTemplate.Triggers>
                                                <Trigger Property="IsSelected" Value="True">
                                                    <Setter TargetName="Bd" Property="BorderBrush" Value="#3498DB"/>
                                                    <Setter TargetName="Bd" Property="Background" Value="#1A2A3A"/>
                                                </Trigger>
                                                <Trigger Property="IsMouseOver" Value="True">
                                                    <Setter TargetName="Bd" Property="Background" Value="#2D2D30"/>
                                                </Trigger>
                                                <Trigger Property="IsEnabled" Value="False">
                                                    <Setter Property="Cursor" Value="Arrow"/>
                                                </Trigger>
                                            </ControlTemplate.Triggers>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </ListBox.ItemContainerStyle>
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <StackPanel>
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                        <TextBlock Text="{Binding Label}" Foreground="White" FontWeight="Bold" FontSize="12" VerticalAlignment="Center"/>
                                        <TextBlock Text="{Binding Warning}" Foreground="#E74C3C" FontSize="10" FontStyle="Italic" Margin="8,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                    <ProgressBar Value="{Binding PercentUsed}" Height="8" Background="#111" Foreground="#0078D4" BorderThickness="0"/>
                                    <TextBlock Text="{Binding Detail}" Foreground="#999" FontSize="10" Margin="0,5,0,0"/>
                                </StackPanel>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>

                    <StackPanel Grid.Row="2" Margin="0,0,0,20">
                        <TextBlock Text="ĐƯỜNG DẪN SAO LƯU" Foreground="#777" FontSize="11" FontWeight="Bold" Margin="0,0,0,8"/>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="45"/></Grid.ColumnDefinitions>
                            <TextBox Name="txtPath" Height="34" Background="#252526" Foreground="White" BorderBrush="#444" BorderThickness="1" VerticalContentAlignment="Center" Padding="10,0"/>
                            <Button Name="btnBrowse" Grid.Column="1" Content="..." Background="#444" Foreground="White" BorderThickness="0" Margin="5,0,0,0" Cursor="Hand"/>
                        </Grid>
                    </StackPanel>

                    <Button Name="btnBackup" Grid.Row="3" Content="BẮT ĐẦU SAO LƯU" Height="45" Background="#2980B9" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand" Margin="0,0,0,10"/>
                    <Button Name="btnRestore" Grid.Row="4" Content="PHỤC HỒI GỐC" Height="45" Background="#C0392B" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                </Grid>

                <Grid Grid.Column="2">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="#202020" CornerRadius="5" Padding="20" Margin="0,0,0,20" VerticalAlignment="Top">
                        <StackPanel>
                            <TextBlock Text="THƯ MỤC CÁ NHÂN" Foreground="#3498DB" FontSize="11" FontWeight="Bold" Margin="0,0,0,12"/>
                            <UniformGrid Columns="2">
                                <CheckBox Name="chkDesktop" Content="Desktop" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                                <CheckBox Name="chkDownloads" Content="Downloads" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                                <CheckBox Name="chkDocuments" Content="Documents" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                                <CheckBox Name="chkPictures" Content="Pictures" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                                <CheckBox Name="chkMusic" Content="Musics" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                            </UniformGrid>
                            
                            <Rectangle Height="1" Fill="#333" Margin="0,15,0,15"/>
                            
                            <TextBlock Text="DỮ LIỆU TRÌNH DUYỆT WEB" Foreground="#3498DB" FontSize="11" FontWeight="Bold" Margin="0,0,0,12"/>
                            <UniformGrid Columns="2">
                                <CheckBox Name="chkChrome" Content="Google Chrome" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                                <CheckBox Name="chkCocCoc" Content="Cốc Cốc" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                                <CheckBox Name="chkEdge" Content="Microsoft Edge" IsChecked="True" Foreground="#CCC" Margin="0,8"/>
                            </UniformGrid>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="1" Background="#252526" CornerRadius="5" Padding="15">
                        <StackPanel>
                            <Grid Margin="0,0,0,8">
                                <TextBlock Name="txtFileName" Text="Sẵn sàng..." Foreground="#888" FontSize="11" TextTrimming="CharacterEllipsis" Width="320" HorizontalAlignment="Left"/>
                                <TextBlock Name="txtPercent" Text="0%" Foreground="#3498DB" FontWeight="Bold" FontSize="14" HorizontalAlignment="Right"/>
                            </Grid>
                            <ProgressBar Name="pbMain" Height="6" Background="#1A1A1A" Foreground="#3498DB" BorderThickness="0"/>
                        </StackPanel>
                    </Border>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$DocXml = (New-Object System.Xml.XmlNodeReader $GiaoDienXAML)
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

$CuaSo.FindName("TitleBar").Add_MouseLeftButtonDown({ $CuaSo.DragMove() })
$CuaSo.FindName("btnClose").Add_Click({ $CuaSo.Close() })
$CuaSo.FindName("btnMin").Add_Click({ $CuaSo.WindowState = 'Minimized' })

$lstDrives = $CuaSo.FindName("lstDrives")
$txtPath = $CuaSo.FindName("txtPath")
$txtFileName = $CuaSo.FindName("txtFileName")
$txtPercent = $CuaSo.FindName("txtPercent")
$pbMain = $CuaSo.FindName("pbMain")
$btnBackup = $CuaSo.FindName("btnBackup")
$btnRestore = $CuaSo.FindName("btnRestore")

# THUẬT TOÁN TẠO THẺ Ổ ĐĨA & KHÓA Ổ C
function CapNhatODia {
    $DanhSachOdia = @()
    $Drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady -and ($_.DriveType -eq 'Fixed' -or $_.DriveType -eq 'Removable') }
    
    foreach ($Drive in $Drives) {
        $FreeGB = [math]::Round($Drive.AvailableFreeSpace / 1GB, 1)
        $TotalGB = [math]::Round($Drive.TotalSize / 1GB, 1)
        $UsedGB = $TotalGB - $FreeGB
        
        $PercentUsed = 0
        if ($TotalGB -gt 0) { $PercentUsed = [math]::Round(($UsedGB / $TotalGB) * 100) }

        $volLabel = $Drive.VolumeLabel
        if ([string]::IsNullOrWhiteSpace($volLabel)) { $volLabel = "Local Disk" }
        
        # Kiểm tra xem có phải ổ C (Ổ hệ điều hành) không
        $isDriveC = ($Drive.Name -match "^C:")
        
        $DanhSachOdia += [PSCustomObject]@{
            Letter = $Drive.Name.Substring(0,3)
            Label = "$volLabel ($($Drive.Name.Substring(0,2)))"
            Detail = "$FreeGB GB free of $TotalGB GB"
            PercentUsed = $PercentUsed
            # Gắn biến kiểm soát vô hiệu hóa
            IsEnabled = (-not $isDriveC)
            Opacity = if ($isDriveC) { 0.4 } else { 1.0 }
            Warning = if ($isDriveC) { "(Không hỗ trợ lưu trữ)" } else { "" }
        }
    }
    
    $lstDrives.ItemsSource = $DanhSachOdia
    
    # Tự động tìm và chọn ổ đĩa HỢP LỆ đầu tiên (bỏ qua ổ C)
    $firstValid = $DanhSachOdia | Where-Object { $_.IsEnabled -eq $true } | Select-Object -First 1
    if ($firstValid) {
        $lstDrives.SelectedItem = $firstValid
    }
}
CapNhatODia

$lstDrives.Add_SelectionChanged({
    if ($lstDrives.SelectedItem) {
        # Kéo đường dẫn thư mục backup vào TextBox
        $DriveLetter = $lstDrives.SelectedItem.Letter
        $txtPath.Text = Join-Path $DriveLetter "Backup_System"
    }
})

$CuaSo.FindName("btnBrowse").Add_Click({
    $ThuMucMoi = [APIHeThongV13]::ChonThuMucHienDai()
    if (-not [string]::IsNullOrEmpty($ThuMucMoi)) { 
        # Cảnh báo phụ nếu khách cố tình duyệt thư mục vào ổ C bằng tay
        if ($ThuMucMoi -match "^C:") {
            $txtFileName.Text = "CẢNH BÁO: Bạn không nên lưu vào ổ C!"
            $txtFileName.Foreground = "#E74C3C"
        } else {
            $txtFileName.Text = "Sẵn sàng..."
            $txtFileName.Foreground = "#888"
        }
        $txtPath.Text = $ThuMucMoi 
    }
})

function ThucHienCopy {
    param($IsRestore)
    
    # Chặn đứng nếu người dùng gõ tay ổ C vào ô đường dẫn
    if ($txtPath.Text -match "^C:" -and -not $IsRestore) {
        $txtFileName.Text = "LỖI: Tránh mất dữ liệu, không sao lưu vào ổ C!"
        $txtFileName.Foreground = "#E74C3C"
        return
    }

    $Mucs = @()
    if ($CuaSo.FindName("chkDesktop").IsChecked) { $Mucs += @{T="Desktop"; P="$env:USERPROFILE\Desktop"} }
    if ($CuaSo.FindName("chkDownloads").IsChecked) { $Mucs += @{T="Downloads"; P="$env:USERPROFILE\Downloads"} }
    if ($CuaSo.FindName("chkDocuments").IsChecked) { $Mucs += @{T="Documents"; P="$env:USERPROFILE\Documents"} }
    if ($CuaSo.FindName("chkPictures").IsChecked) { $Mucs += @{T="Pictures"; P="$env:USERPROFILE\Pictures"} }
    if ($CuaSo.FindName("chkMusic").IsChecked) { $Mucs += @{T="Music"; P="$env:USERPROFILE\Music"} }
    if ($CuaSo.FindName("chkChrome").IsChecked) { $Mucs += @{T="Chrome"; P="$env:LOCALAPPDATA\Google\Chrome\User Data"} }
    if ($CuaSo.FindName("chkCocCoc").IsChecked) { $Mucs += @{T="CocCoc"; P="$env:LOCALAPPDATA\CocCoc\Browser\User Data"} }
    if ($CuaSo.FindName("chkEdge").IsChecked) { $Mucs += @{T="Edge"; P="$env:LOCALAPPDATA\Microsoft\Edge\User Data"} }

    if ($Mucs.Count -eq 0) { return }

    $btnBackup.IsEnabled = $false; $btnRestore.IsEnabled = $false
    $txtFileName.Text = "Đang đếm tổng số tệp..."
    $txtFileName.Foreground = "#3498DB"
    [System.Windows.Forms.Application]::DoEvents()
    
    $Total = 0
    foreach ($M in $Mucs) {
        $S = if ($IsRestore) { Join-Path $txtPath.Text $M.T } else { $M.P }
        if (Test-Path $S) { $Total += (Get-ChildItem $S -Recurse -File -ErrorAction SilentlyContinue).Count }
    }
    if ($Total -eq 0) { $Total = 1 }

    $Current = 0
    foreach ($M in $Mucs) {
        $S = if ($IsRestore) { Join-Path $txtPath.Text $M.T } else { $M.P }
        $D = if ($IsRestore) { $M.P } else { Join-Path $txtPath.Text $M.T }
        
        if (Test-Path $S) {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "xcopy.exe"
            $psi.Arguments = "`"$S`" `"$D`" /E /I /H /Y /C"
            $psi.RedirectStandardOutput = $true; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
            $p = [System.Diagnostics.Process]::Start($psi)

            while (-not $p.StandardOutput.EndOfStream) {
                $line = $p.StandardOutput.ReadLine()
                if ($line -and $line -notmatch "File\(s\) copied") {
                    $Current++
                    $pct = [math]::Min(100, [math]::Floor(($Current / $Total) * 100))
                    $txtFileName.Text = "Đang xử lý: $line"
                    $txtPercent.Text = "$pct%"
                    $pbMain.Value = $pct
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            $p.WaitForExit()
        }
    }
    
    [APIHeThongV13]::ToiUuBoNho(); CapNhatODia
    $txtFileName.Text = "HOÀN TẤT!"; $txtPercent.Text = "100%"; $pbMain.Value = 100
    $btnBackup.IsEnabled = $true; $btnRestore.IsEnabled = $true
}

$btnBackup.Add_Click({ ThucHienCopy -IsRestore $false })
$btnRestore.Add_Click({ ThucHienCopy -IsRestore $true })

$CuaSo.ShowDialog() | Out-Null