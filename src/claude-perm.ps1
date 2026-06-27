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
        [System.Windows.MessageBox]::Show("Settings backed up successfully!", "Backup", "OK", "Information")
    } else {
        [System.Windows.MessageBox]::Show("No settings file found to backup.", "Backup", "OK", "Warning")
    }
}

function Restore-Settings {
    if (Test-Path $BACKUP_PATH) {
        Copy-Item -Path $BACKUP_PATH -Destination $SETTINGS_PATH -Force
        Update-UI
        [System.Windows.MessageBox]::Show("Settings restored successfully!", "Restore", "OK", "Information")
    } else {
        [System.Windows.MessageBox]::Show("No backup file found.", "Restore", "OK", "Warning")
    }
}

function Clean-ProjectSettings {
    $localSettingsPath = Join-Path (Get-Location) ".claude\settings.local.json"
    if (Test-Path $localSettingsPath) {
        Remove-Item -Path $localSettingsPath -Force
        [System.Windows.MessageBox]::Show("Project settings cleaned!", "Clean", "OK", "Information")
    } else {
        [System.Windows.MessageBox]::Show("No project settings found.", "Clean", "OK", "Warning")
    }
}

# ── XAML ─────────────────────────────────────────────────────────────────────

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="claude-perm"
        Width="440" Height="620"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#11111B"
        Foreground="#CDD6F4">
    <Window.Resources>
        <!-- Button Style -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#89B4FA"/>
            <Setter Property="Foreground" Value="#11111B"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="20,10"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#B4D0FB"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#7BA8E8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="6"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#45475A"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#585B70"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Card Style -->
        <Style x:Key="Card" TargetType="Border">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="20"/>
        </Style>
    </Window.Resources>

    <Grid Margin="25">
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

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="claude-perm"
                       FontSize="32" FontWeight="Bold"
                       Foreground="#CDD6F4"
                       HorizontalAlignment="Center"/>
            <TextBlock Text="v1.4.0"
                       FontSize="12" Foreground="#585B70"
                       HorizontalAlignment="Center"
                       Margin="0,5,0,0"/>
        </StackPanel>

        <!-- Toggle Card -->
        <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="Permission Toggle"
                           FontSize="11" Foreground="#585B70"
                           Margin="0,0,0,15"
                           HorizontalAlignment="Center"/>

                <!-- Toggle Switch -->
                <Border Width="120" Height="52"
                        CornerRadius="26" Cursor="Hand"
                        x:Name="Track" Background="#45475A"
                        HorizontalAlignment="Center"
                        Margin="0,0,0,12">
                    <Ellipse x:Name="Thumb" Width="44" Height="44"
                             Fill="#CDD6F4"
                             HorizontalAlignment="Left"
                             Margin="4,0,0,0"/>
                </Border>

                <!-- Status Text -->
                <TextBlock x:Name="StatusText"
                           FontSize="18" FontWeight="Bold"
                           HorizontalAlignment="Center"/>
            </StackPanel>
        </Border>

        <!-- Action Buttons -->
        <StackPanel Grid.Row="2" Orientation="Horizontal"
                    HorizontalAlignment="Center" Margin="0,0,0,15">
            <Button x:Name="BtnOn" Content="Enable"
                    Style="{StaticResource PrimaryButton}"
                    Width="100" Margin="0,0,10,0"/>
            <Button x:Name="BtnOff" Content="Disable"
                    Style="{StaticResource SecondaryButton}"
                    Width="100" Margin="10,0,0,0"/>
        </StackPanel>

        <!-- Backup/Restore/Clean Buttons -->
        <WrapPanel Grid.Row="3" HorizontalAlignment="Center" Margin="0,0,0,20">
            <Button x:Name="BtnBackup" Content="Backup"
                    Style="{StaticResource SecondaryButton}"
                    Margin="0,0,10,0"/>
            <Button x:Name="BtnRestore" Content="Restore"
                    Style="{StaticResource SecondaryButton}"
                    Margin="0,0,10,0"/>
            <Button x:Name="BtnClean" Content="Clean"
                    Style="{StaticResource SecondaryButton}"/>
        </WrapPanel>

        <!-- Tools Section -->
        <Border Grid.Row="4" Style="{StaticResource Card}" Margin="0,0,0,15">
            <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                    <TextBlock Text="Tools"
                               FontSize="13" FontWeight="SemiBold"
                               Foreground="#CDD6F4"/>
                    <TextBlock x:Name="ToolCount"
                               FontSize="11" Foreground="#585B70"
                               Margin="8,2,0,0"/>
                </StackPanel>
                <ItemsControl x:Name="ToolList">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Border Background="#1E1E2E"
                                    CornerRadius="4"
                                    Padding="8,4"
                                    Margin="0,2">
                                <TextBlock Text="{Binding}"
                                           FontFamily="Cascadia Code, Consolas"
                                           FontSize="11"
                                           Foreground="#A6ADC8"/>
                            </Border>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>
            </StackPanel>
        </Border>

        <!-- Info Section -->
        <Border Grid.Row="5" Style="{StaticResource Card}" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="Configuration"
                           FontSize="13" FontWeight="SemiBold"
                           Foreground="#CDD6F4"
                           Margin="0,0,0,8"/>
                <TextBlock x:Name="PathText" FontSize="11" Foreground="#585B70"
                           TextWrapping="Wrap"/>
            </StackPanel>
        </Border>

        <!-- Footer -->
        <StackPanel Grid.Row="7" HorizontalAlignment="Center" Margin="0,5,0,0">
            <TextBlock x:Name="HintText" FontSize="12" Foreground="#6C7086"
                       HorizontalAlignment="Center"/>
        </StackPanel>
    </Grid>
</Window>
"@

# ── Build ────────────────────────────────────────────────────────────────────

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$Track      = $window.FindName("Track")
$Thumb      = $window.FindName("Thumb")
$StatusText = $window.FindName("StatusText")
$ToolList   = $window.FindName("ToolList")
$ToolCount  = $window.FindName("ToolCount")
$PathText   = $window.FindName("PathText")
$HintText   = $window.FindName("HintText")
$BtnOn      = $window.FindName("BtnOn")
$BtnOff     = $window.FindName("BtnOff")
$BtnBackup  = $window.FindName("BtnBackup")
$BtnRestore = $window.FindName("BtnRestore")
$BtnClean   = $window.FindName("BtnClean")

$PathText.Text = $SETTINGS_PATH
$ToolList.ItemsSource = $ALLOWED_TOOLS
$ToolCount.Text = "($($ALLOWED_TOOLS.Count) tools)"

$script:IsOn = $false

$GreenBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A6E3A1")
$GrayBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#45475A")
$DarkBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#11111B")
$LightBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CDD6F4")
$RedBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F38BA8")

function Update-UI {
    $script:IsOn = Get-Status
    if ($script:IsOn) {
        $Track.Background = $GreenBrush
        $Thumb.Fill = $DarkBrush
        [System.Windows.Controls.Canvas]::SetLeft($Thumb, 72)
        $StatusText.Text = "ON"
        $StatusText.Foreground = $GreenBrush
        $HintText.Text = "Restart Claude Code to apply changes"
    } else {
        $Track.Background = $GrayBrush
        $Thumb.Fill = $LightBrush
        [System.Windows.Controls.Canvas]::SetLeft($Thumb, 4)
        $StatusText.Text = "OFF"
        $StatusText.Foreground = $RedBrush
        $HintText.Text = "Restart Claude Code to apply changes"
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
$BtnClean.Add_Click({ Clean-ProjectSettings })
$window.Add_Loaded({ Update-UI })

# ── Run ──────────────────────────────────────────────────────────────────────

$window.ShowDialog() | Out-Null
