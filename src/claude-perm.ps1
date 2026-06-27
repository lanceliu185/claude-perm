Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$SETTINGS_DIR = Join-Path $env:USERPROFILE ".claude"
$SETTINGS_PATH = Join-Path $SETTINGS_DIR "settings.json"
$BACKUP_PATH = Join-Path $SETTINGS_DIR "settings.backup.json"

$ALLOWED_TOOLS = @(
    "Bash(*)", "Read", "Write", "Edit", "Glob", "Grep",
    "Agent", "WebFetch", "WebSearch", "NotebookEdit", "Skill(*)",
    "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TaskOutput", "TaskStop",
    "CronCreate", "CronDelete", "CronList", "ScheduleWakeup",
    "SendMessage", "DesignSync", "Workflow"
)

function Read-Settings {
    if (Test-Path $SETTINGS_PATH) {
        try { return (Get-Content $SETTINGS_PATH -Raw | ConvertFrom-Json) } catch { return [PSCustomObject]@{} }
    }
    return [PSCustomObject]@{}
}

function Write-Settings($data) {
    $dir = Split-Path $SETTINGS_PATH -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $json = ($data | ConvertTo-Json -Depth 10) + "`n"
    [System.IO.File]::WriteAllText($SETTINGS_PATH, $json, [System.Text.UTF8Encoding]::new($false))
}

function Get-Status {
    $data = Read-Settings
    if ($data.permissions -and $data.permissions.allow) {
        return ($data.permissions.allow | Where-Object { $_ -like "*Bash(*)*" }).Count -gt 0
    }
    return $false
}

function Set-Permissions($enabled) {
    $data = Read-Settings
    if (-not $data.permissions) {
        $data | Add-Member -NotePropertyName "permissions" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if ($enabled) {
        $data.permissions | Add-Member -NotePropertyName "allow" -NotePropertyValue $ALLOWED_TOOLS -Force
    } else {
        $data.permissions.PSObject.Properties.Remove("allow")
        if ($data.permissions.PSObject.Properties.Count -eq 0) {
            $data.PSObject.Properties.Remove("permissions")
        }
    }
    Write-Settings $data
}

function Backup-Settings {
    if (Test-Path $SETTINGS_PATH) {
        Copy-Item -Path $SETTINGS_PATH -Destination $BACKUP_PATH -Force
        [System.Windows.MessageBox]::Show("Settings backed up to:`n$BACKUP_PATH", "Backup Success", "OK", "Information")
    } else {
        [System.Windows.MessageBox]::Show("No settings file found to backup.", "Backup", "OK", "Warning")
    }
}

function Restore-Settings {
    if (Test-Path $BACKUP_PATH) {
        Copy-Item -Path $BACKUP_PATH -Destination $SETTINGS_PATH -Force
        Update-UI
        [System.Windows.MessageBox]::Show("Settings restored from backup.", "Restore Success", "OK", "Information")
    } else {
        [System.Windows.MessageBox]::Show("No backup file found.", "Restore", "OK", "Warning")
    }
}

# ── XAML ─────────────────────────────────────────────────────────────────────

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Claude Code Permission Toggle"
        Width="420" Height="560"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#1E1E2E">
    <Grid Margin="30">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0"
                   Text="claude-perm"
                   FontSize="28" FontWeight="Bold"
                   Foreground="#CDD6F4"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,5"/>
        <TextBlock Grid.Row="1"
                   Text="Claude Code Permission Toggle"
                   FontSize="13" Foreground="#6C7086"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,25"/>

        <!-- Toggle Area -->
        <Border Grid.Row="2" Width="100" Height="46"
                CornerRadius="23" Cursor="Hand"
                x:Name="Track" Background="#45475A"
                HorizontalAlignment="Center"
                Margin="0,0,0,15">
            <Ellipse x:Name="Thumb" Width="38" Height="38"
                     Fill="#CDD6F4"
                     HorizontalAlignment="Left"
                     Margin="4,0,0,0"/>
        </Border>

        <!-- Status -->
        <TextBlock Grid.Row="3"
                   x:Name="StatusText"
                   FontSize="16" FontWeight="SemiBold"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,15"/>

        <!-- Buttons -->
        <StackPanel Grid.Row="4" Orientation="Horizontal"
                    HorizontalAlignment="Center" Margin="0,0,0,10">
            <Button x:Name="BtnOn" Content="Turn ON"
                    Width="90" Height="32" Margin="0,0,8,0"
                    FontSize="13" FontWeight="SemiBold"/>
            <Button x:Name="BtnOff" Content="Turn OFF"
                    Width="90" Height="32" Margin="8,0,0,0"
                    FontSize="13" FontWeight="SemiBold"/>
        </StackPanel>

        <!-- Backup/Restore Buttons -->
        <StackPanel Grid.Row="5" Orientation="Horizontal"
                    HorizontalAlignment="Center" Margin="0,0,0,15">
            <Button x:Name="BtnBackup" Content="Backup"
                    Width="90" Height="28" Margin="0,0,8,0"
                    FontSize="12"/>
            <Button x:Name="BtnRestore" Content="Restore"
                    Width="90" Height="28" Margin="8,0,0,0"
                    FontSize="12"/>
        </StackPanel>

        <!-- Tool List -->
        <Border Grid.Row="6" Background="#181825" CornerRadius="10" Padding="15">
            <StackPanel>
                <TextBlock Text="Allowed Tools" FontSize="13"
                           Foreground="#6C7086" Margin="0,0,0,10"/>
                <ItemsControl x:Name="ToolList">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <TextBlock Text="{Binding}"
                                       FontFamily="Consolas" FontSize="12"
                                       Foreground="#A6ADC8" Margin="0,2"/>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>
            </StackPanel>
        </Border>

        <!-- Footer -->
        <StackPanel Grid.Row="7" HorizontalAlignment="Center" Margin="0,15,0,0">
            <TextBlock x:Name="PathText" FontSize="11" Foreground="#585B70"
                       HorizontalAlignment="Center" Margin="0,0,0,5"/>
            <TextBlock x:Name="HintText" FontSize="12" Foreground="#6C7086"
                       HorizontalAlignment="Center"/>
        </StackPanel>
    </Grid>
</Window>
"@

# ── Build ────────────────────────────────────────────────────────────────────

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$Track     = $window.FindName("Track")
$Thumb     = $window.FindName("Thumb")
$StatusText = $window.FindName("StatusText")
$ToolList  = $window.FindName("ToolList")
$PathText  = $window.FindName("PathText")
$HintText  = $window.FindName("HintText")
$BtnOn     = $window.FindName("BtnOn")
$BtnOff    = $window.FindName("BtnOff")
$BtnBackup = $window.FindName("BtnBackup")
$BtnRestore = $window.FindName("BtnRestore")

$PathText.Text = "Settings: $SETTINGS_PATH"
$ToolList.ItemsSource = $ALLOWED_TOOLS

$script:IsOn = $false

$GreenBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A6E3A1")
$GrayBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#45475A")
$DarkBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E1E2E")
$LightBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CDD6F4")
$RedBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F38BA8")

function Update-UI {
    $script:IsOn = Get-Status
    if ($script:IsOn) {
        $Track.Background = $GreenBrush
        $Thumb.Fill = $DarkBrush
        [System.Windows.Controls.Canvas]::SetLeft($Thumb, 58)
        $StatusText.Text = "ON  —  All tools auto-approved"
        $StatusText.Foreground = $GreenBrush
        $HintText.Text = "Restart Claude Code session to take effect"
    } else {
        $Track.Background = $GrayBrush
        $Thumb.Fill = $LightBrush
        [System.Windows.Controls.Canvas]::SetLeft($Thumb, 4)
        $StatusText.Text = "OFF  —  Tool calls require confirmation"
        $StatusText.Foreground = $RedBrush
        $HintText.Text = "Restart Claude Code session to take effect"
    }
}

function Do-Toggle {
    $newState = -not $script:IsOn
    Set-Permissions $newState
    Update-UI
}

function Do-On {
    Set-Permissions $true
    Update-UI
}

function Do-Off {
    Set-Permissions $false
    Update-UI
}

# ── Events ───────────────────────────────────────────────────────────────────

$Track.Add_MouseLeftButtonDown({ Do-Toggle })
$Thumb.Add_MouseLeftButtonDown({ Do-Toggle })
$BtnOn.Add_Click({ Do-On })
$BtnOff.Add_Click({ Do-Off })
$BtnBackup.Add_Click({ Backup-Settings })
$BtnRestore.Add_Click({ Restore-Settings })
$window.Add_Loaded({ Update-UI })

# ── Run ──────────────────────────────────────────────────────────────────────

$window.ShowDialog() | Out-Null
