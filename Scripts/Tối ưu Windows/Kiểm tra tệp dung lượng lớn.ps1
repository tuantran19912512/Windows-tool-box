# ÉP POWERSHELL HIỂU TIẾNG VIỆT 100%
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- NHÂN C# QUÉT SIÊU TỐC ---
if (-not ([Ref].Assembly.GetType("VietToolbox.DirScanner"))) {
    $Source = @"
    using System;
    using System.IO;
    using System.Windows.Forms;
    namespace VietToolbox {
        public class DirScanner {
            private static int tick = 0;
            public static long GetSize(string path) {
                long size = 0;
                tick++;
                if (tick > 50) { Application.DoEvents(); tick = 0; }
                try {
                    DirectoryInfo d = new DirectoryInfo(path);
                    try {
                        FileInfo[] files = d.GetFiles();
                        foreach (FileInfo fi in files) { size += fi.Length; }
                    } catch { }
                    try {
                        DirectoryInfo[] dirs = d.GetDirectories();
                        foreach (DirectoryInfo di in dirs) {
                            if ((di.Attributes & FileAttributes.ReparsePoint) == 0) {
                                size += GetSize(di.FullName);
                            }
                        }
                    } catch { }
                } catch { }
                return size;
            }
        }
    }
"@
    try { Add-Type -TypeDefinition $Source -ReferencedAssemblies "System.Windows.Forms" -ErrorAction SilentlyContinue } catch { }
}

$LogicTreeSizeUltimate = {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VietToolbox - Phân Tích & Quản Lý Dung Lượng (Ultimate Edition)"
    $form.Size = "1100,750"
    $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"

    $fontTieuDe = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $fontChu = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontTree = New-Object System.Drawing.Font("Consolas", 10) 

    # --- KHU VỰC ĐIỀU KHIỂN ---
    $lblPath = New-Object System.Windows.Forms.Label
    $lblPath.Text = "Chọn đường dẫn gốc cần quét (Bấm chuột phải vào mục bất kỳ để thao tác):"
    $lblPath.Font = $fontTieuDe; $lblPath.Location = "20,20"; $lblPath.Size = "650,25"; $lblPath.ForeColor = "#394E60"

    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = "20,55"; $txtPath.Size = "640,30"; $txtPath.Font = $fontChu; $txtPath.Text = "C:\"

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "Duyệt..."
    $btnBrowse.Location = "670,54"; $btnBrowse.Size = "90,30"
    $btnBrowse.BackColor = "#E1E4E8"; $btnBrowse.FlatStyle = "Flat"; $btnBrowse.FlatAppearance.BorderSize = 0

    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Text = "🚀 BẮT ĐẦU QUÉT TỔNG"
    $btnScan.Location = "770,54"; $btnScan.Size = "290,30"
    $btnScan.BackColor = "#0068FF"; $btnScan.ForeColor = "White"; $btnScan.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnScan.FlatStyle = "Flat"; $btnScan.FlatAppearance.BorderSize = 0

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "Bấm 'Quét Tổng' để lấy dữ liệu. Bấm dấu [+] để đào sâu. CHUỘT PHẢI để Xóa/Copy/Move."
    $lblStatus.Location = "20,95"; $lblStatus.Size = "1040,20"; $lblStatus.ForeColor = "#666666"; $lblStatus.Font = New-Object System.Drawing.Font("Consolas", 9)

    $pnlDiskInfo = New-Object System.Windows.Forms.Panel
    $pnlDiskInfo.Location = "20,120"; $pnlDiskInfo.Size = "1040,35"; $pnlDiskInfo.BackColor = "#EBF5FF"
    
    $lblDiskDetails = New-Object System.Windows.Forms.Label
    $lblDiskDetails.Location = "10,8"; $lblDiskDetails.Size = "700,20"
    $lblDiskDetails.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblDiskDetails.ForeColor = "#0068FF"; $lblDiskDetails.Text = "💽 Thông tin ổ đĩa: Đang chờ quét..."

    $progDisk = New-Object System.Windows.Forms.ProgressBar
    $progDisk.Location = "720,8"; $progDisk.Size = "310,18"; $progDisk.Style = "Continuous"
    
    $pnlDiskInfo.Controls.AddRange(@($lblDiskDetails, $progDisk))

    $lblHeader = New-Object System.Windows.Forms.Label
    $lblHeader.Text = "TỶ LỆ (%)         | DUNG LƯỢNG  | THƯ MỤC / TẬP TIN"
    $lblHeader.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $lblHeader.Location = "20,165"; $lblHeader.Size = "1040,20"; $lblHeader.BackColor = "#394E60"; $lblHeader.ForeColor = "White"

    $form.Controls.AddRange(@($lblPath, $txtPath, $btnBrowse, $btnScan, $lblStatus, $pnlDiskInfo, $lblHeader))

    # --- TREEVIEW ---
    $tree = New-Object System.Windows.Forms.TreeView
    $tree.Location = "20,185"; $tree.Size = "1040,500"; $tree.BackColor = "#F4F5F7"
    $tree.Font = $fontTree; $tree.ShowLines = $true; $tree.ShowPlusMinus = $true
    $tree.BorderStyle = "None"
    $form.Controls.Add($tree)

    # ==========================================
    # KHU VỰC MENU CHUỘT PHẢI (CONTEXT MENU)
    # ==========================================
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $fontMenu = New-Object System.Drawing.Font("Segoe UI", 10)
    $contextMenu.Font = $fontMenu

    $itemOpen = $contextMenu.Items.Add("📂 Mở vị trí (Open in Explorer)")
    $itemCopy = $contextMenu.Items.Add("📋 Sao chép đến...")
    $itemMove = $contextMenu.Items.Add("✂️ Di chuyển đến...")
    $contextMenu.Items.Add("-") | Out-Null # Dòng kẻ ngang
    $itemDelete = $contextMenu.Items.Add("🗑️ Xóa vĩnh viễn (Delete)")
    $itemDelete.ForeColor = [System.Drawing.Color]::Red

    # Sự kiện chuột phải
    $tree.Add_NodeMouseClick({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            $tree.SelectedNode = $e.Node # Tự động chọn dòng đang trỏ
            $contextMenu.Show($tree, $e.Location)
        }
    })

    # Hành động: Mở vị trí
    $itemOpen.Add_Click({
        $path = $tree.SelectedNode.Tag.Path
        if (Test-Path $path) {
            # Lệnh bôi đen sẵn file/thư mục trong Windows Explorer
            Start-Process "explorer.exe" -ArgumentList "/select,`"$path`""
        } else {
            [System.Windows.Forms.MessageBox]::Show("Đường dẫn không còn tồn tại!", "Lỗi", 0, 16)
        }
    })

    # Hành động: Xóa
    $itemDelete.Add_Click({
        $node = $tree.SelectedNode
        $path = $node.Tag.Path
        $name = $node.Tag.Name
        
        $ans = [System.Windows.Forms.MessageBox]::Show("Bạn có CHẮC CHẮN muốn xóa vĩnh viễn:`n$name`n`nHành động này không thể hoàn tác!", "Cảnh báo Xóa", 4, 48)
        if ($ans -eq "Yes") {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                $node.Remove() # Xóa dòng đó khỏi bảng ngay lập tức
                [System.Windows.Forms.MessageBox]::Show("Đã xóa thành công!", "Thông báo", 0, 64)
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Không thể xóa! Có thể tệp đang được sử dụng hoặc bạn không có quyền Admin.`n`nChi tiết: $($_.Exception.Message)", "Lỗi Xóa", 0, 16)
            }
        }
    })

    # Hành động: Sao chép
    $itemCopy.Add_Click({
        $node = $tree.SelectedNode
        $path = $node.Tag.Path
        
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Chọn thư mục muốn SAO CHÉP đến:"
        if ($dialog.ShowDialog() -eq "OK") {
            try {
                Copy-Item -Path $path -Destination $dialog.SelectedPath -Recurse -Force -ErrorAction Stop
                [System.Windows.Forms.MessageBox]::Show("Đã sao chép thành công tới: $($dialog.SelectedPath)", "Thông báo", 0, 64)
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Lỗi sao chép: $($_.Exception.Message)", "Lỗi", 0, 16)
            }
        }
    })

    # Hành động: Di chuyển
    $itemMove.Add_Click({
        $node = $tree.SelectedNode
        $path = $node.Tag.Path
        
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Chọn thư mục muốn DI CHUYỂN đến:"
        if ($dialog.ShowDialog() -eq "OK") {
            try {
                Move-Item -Path $path -Destination $dialog.SelectedPath -Force -ErrorAction Stop
                $node.Remove() # Di chuyển xong thì xóa dòng trên bảng
                [System.Windows.Forms.MessageBox]::Show("Đã di chuyển thành công tới: $($dialog.SelectedPath)", "Thông báo", 0, 64)
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Lỗi di chuyển: $($_.Exception.Message)", "Lỗi", 0, 16)
            }
        }
    })

    # ==========================================
    # CÁC HÀM CŨ GIỮ NGUYÊN
    # ==========================================
    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog() -eq "OK") { $txtPath.Text = $dialog.SelectedPath }
    })

    function Update-DiskInfo($path) {
        try {
            $root = [System.IO.Path]::GetPathRoot($path)
            $drive = New-Object System.IO.DriveInfo($root)
            if ($drive.IsReady) {
                $total = $drive.TotalSize; $free = $drive.AvailableFreeSpace; $used = $total - $free
                $pct = [math]::Round(($used / $total) * 100, 1)
                $lblDiskDetails.Text = "💽 Ổ đĩa: $root  |  Tổng: $("{0:N2} GB" -f ($total/1GB))  |  Đã dùng: $("{0:N2} GB" -f ($used/1GB)) ($pct%)  |  Còn trống: $("{0:N2} GB" -f ($free/1GB))"
                $progDisk.Value = [int]$pct
            }
        } catch { }
    }

    $tree.Add_BeforeExpand({
        param($sender, $e)
        $node = $e.Node
        if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "*LOADING*") {
            $node.Nodes.Clear()
            $parentPath = $node.Tag.Path; $parentSize = $node.Tag.Size
            $lblStatus.Text = "Đang quét nhanh: $parentPath"; $lblStatus.ForeColor = "#E74C3C"
            [System.Windows.Forms.Application]::DoEvents()

            try {
                $subItems = Get-ChildItem -Path $parentPath -Force -ErrorAction SilentlyContinue
                $childList = @()

                foreach ($item in $subItems) {
                    [long]$sBytes = 0; $nType = 0
                    if ($item.PSIsContainer) {
                        if ($null -ne $item.Attributes -and $item.Attributes.ToString() -match "ReparsePoint") { $nType = 2 } 
                        else { $nType = 1; $sBytes = [VietToolbox.DirScanner]::GetSize($item.FullName) }
                    } else { try { $sBytes = (New-Object System.IO.FileInfo($item.FullName)).Length } catch { } }
                    $childList += [PSCustomObject]@{ Item=$item; Size=$sBytes; NodeType=$nType }
                }

                $childList = $childList | Sort-Object Size -Descending
                foreach ($c in $childList) {
                    $pct = 0
                    if ($parentSize -gt 0 -and $c.Size -gt 0) { $pct = [math]::Round(($c.Size / $parentSize) * 100, 1) }
                    $bc = [math]::Round($pct / 10)
                    if ($bc -lt 0) { $bc = 0 }; if ($bc -gt 10) { $bc = 10 }
                    $pStr = "[$("█" * $bc)$("░" * (10 - $bc))] $($pct)%".PadRight(17)
                    
                    $sStr = "0 KB"
                    if ($c.Size -ge 1GB) { $sStr = "{0:N2} GB" -f ($c.Size/1GB) } elseif ($c.Size -ge 1MB) { $sStr = "{0:N2} MB" -f ($c.Size/1MB) } elseif ($c.Size -ge 1KB) { $sStr = "{0:N2} KB" -f ($c.Size/1KB) } elseif ($c.Size -gt 0) { $sStr = "{0} B" -f $c.Size }
                    
                    $icon = if ($c.NodeType -eq 1) { "📁" } elseif ($c.NodeType -eq 2) { "🔗" } else { "📄" }
                    $newNode = New-Object System.Windows.Forms.TreeNode("$pStr | $($sStr.PadLeft(11)) | $icon $($c.Item.Name)")
                    $newNode.Tag = @{ Path = $c.Item.FullName; Size = $c.Size; NodeType = $c.NodeType; Name = $c.Item.Name }
                    if ($c.NodeType -ne 0) { $newNode.Nodes.Add("*LOADING*") | Out-Null }
                    $node.Nodes.Add($newNode) | Out-Null
                }
                $lblStatus.Text = "✅ Đã tải xong."; $lblStatus.ForeColor = "#2ECC71"
            } catch { $node.Nodes.Add("❌ Không có quyền truy cập") | Out-Null }
        }
    })

    $tree.Add_NodeMouseDoubleClick({
        param($sender, $e)
        if ($e.Node.Tag.NodeType -eq 0) { Start-Process $e.Node.Tag.Path -ErrorAction SilentlyContinue }
    })

    $btnScan.Add_Click({
        $targetPath = $txtPath.Text
        if (-not (Test-Path $targetPath)) { [System.Windows.Forms.MessageBox]::Show("Đường dẫn không tồn tại!", "Lỗi", 0, 16); return }

        $btnScan.Enabled = $false; $tree.Nodes.Clear(); Update-DiskInfo $targetPath
        $lblStatus.Text = "Đang tải danh sách cấp 1..."; $lblStatus.ForeColor = "#E74C3C"
        [System.Windows.Forms.Application]::DoEvents()

        $items = Get-ChildItem -Path $targetPath -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $nType = 0
            if ($item.PSIsContainer) {
                if ($null -ne $item.Attributes -and $item.Attributes.ToString() -match "ReparsePoint") { $nType = 2 } else { $nType = 1 }
            }
            $icon = if ($nType -eq 1) { "📁" } elseif ($nType -eq 2) { "🔗" } else { "📄" }
            
            $node = New-Object System.Windows.Forms.TreeNode("Đang chờ...       | Đang tính   | $icon $($item.Name)")
            $node.Tag = @{ Path = $item.FullName; Size = -1; NodeType = $nType; Name = $item.Name }
            if ($nType -ne 0) { $node.Nodes.Add("*LOADING*") | Out-Null }
            $tree.Nodes.Add($node) | Out-Null
        }

        [long]$totalBytesAll = 0
        $allNodes = @($tree.Nodes | ForEach-Object { $_ }) 

        foreach ($node in $allNodes) {
            $path = $node.Tag.Path; $nType = $node.Tag.NodeType; $name = $node.Tag.Name
            $lblStatus.Text = "Đang quét: $path"; [System.Windows.Forms.Application]::DoEvents()

            [long]$sBytes = 0
            if ($nType -eq 1) { $sBytes = [VietToolbox.DirScanner]::GetSize($path) } 
            elseif ($nType -eq 0) { try { $sBytes = (New-Object System.IO.FileInfo($path)).Length } catch { } }

            $totalBytesAll += $sBytes
            $tag = $node.Tag; $tag.Size = $sBytes; $node.Tag = $tag

            $sizeStr = "0 KB"
            if ($sBytes -ge 1GB) { $sizeStr = "{0:N2} GB" -f ($sBytes/1GB) } elseif ($sBytes -ge 1MB) { $sizeStr = "{0:N2} MB" -f ($sBytes/1MB) } elseif ($sBytes -ge 1KB) { $sizeStr = "{0:N2} KB" -f ($sBytes/1KB) } elseif ($sBytes -gt 0) { $sizeStr = "{0} B" -f $sBytes }
            
            $icon = if ($nType -eq 1) { "📁" } elseif ($nType -eq 2) { "🔗" } else { "📄" }
            $node.Text = "Đang chờ...       | $($sizeStr.PadLeft(11)) | $icon $name"

            $sorted = @($tree.Nodes | ForEach-Object { $_ }) | Sort-Object { $_.Tag.Size } -Descending
            $tree.Nodes.Clear(); $tree.Nodes.AddRange($sorted); [System.Windows.Forms.Application]::DoEvents()
        }

        $lblStatus.Text = "Đang vẽ biểu đồ..."
        foreach ($node in $tree.Nodes) {
            $sBytes = $node.Tag.Size; $nType = $node.Tag.NodeType; $name = $node.Tag.Name
            $pct = 0
            if ($totalBytesAll -gt 0 -and $sBytes -gt 0) { $pct = [math]::Round(($sBytes / $totalBytesAll) * 100, 1) }
            
            $bc = [math]::Round($pct / 10)
            if ($bc -lt 0) { $bc = 0 }; if ($bc -gt 10) { $bc = 10 }
            $pStr = "[$("█" * $bc)$("░" * (10 - $bc))] $($pct)%".PadRight(17)

            $sizeStr = "0 KB"
            if ($sBytes -ge 1GB) { $sizeStr = "{0:N2} GB" -f ($sBytes/1GB) } elseif ($sBytes -ge 1MB) { $sizeStr = "{0:N2} MB" -f ($sBytes/1MB) } elseif ($sBytes -ge 1KB) { $sizeStr = "{0:N2} KB" -f ($sBytes/1KB) } elseif ($sBytes -gt 0) { $sizeStr = "{0} B" -f $sBytes }
            
            $icon = if ($nType -eq 1) { "📁" } elseif ($nType -eq 2) { "🔗" } else { "📄" }
            $node.Text = "$pStr | $($sizeStr.PadLeft(11)) | $icon $name"
        }

        $totalStr = "{0:N2} GB" -f ($totalBytesAll / 1GB)
        $lblStatus.Text = "✅ Quét hoàn tất. CHUỘT PHẢI để thao tác. Tổng dung lượng: $totalStr"
        $lblStatus.ForeColor = "#2ECC71"
        $btnScan.Enabled = $true
        
        $form.TopMost = $true; [System.Windows.Forms.Application]::DoEvents(); $form.TopMost = $false
    })

    $form.ShowDialog() | Out-Null
}

&$LogicTreeSizeUltimate