# 4 Minute Timer
# Copyright (c) 2026 Hunter Browning, licensed under the MIT License.
# For repo visit https://github.com/Hxntyr/4-Minute-Timer

# Init -------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration ----------------------------------------------------------------
$script:IntervalSeconds = 240
$script:Remaining       = $script:IntervalSeconds
$script:Running         = $false
$script:Muted           = $false

$ConfigDir  = Join-Path $env:LOCALAPPDATA "FourMinuteTimer"
$ConfigFile = Join-Path $ConfigDir "settings.json"

# ------------------------------------------------------------------------------
# Generates a simple chime.
# Plays through normal audio output and does not depend on windows notification # or system-sound settings.
# ------------------------------------------------------------------------------

function New-ToneWav {
    param(
        [int]$Frequency = 880,
        [double]$Duration = 0.22,
        [int]$SampleRate = 44100
    )

    $samples  = [int]($SampleRate * $Duration)
    $dataSize = $samples * 2

    $stream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($stream)

    $writer.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
    $writer.Write([int](36 + $dataSize))
    $writer.Write([Text.Encoding]::ASCII.GetBytes("WAVE"))
    $writer.Write([Text.Encoding]::ASCII.GetBytes("fmt "))
    $writer.Write([int]16)
    $writer.Write([int16]1)
    $writer.Write([int16]1)
    $writer.Write([int]$SampleRate)
    $writer.Write([int]($SampleRate * 2))
    $writer.Write([int16]2)
    $writer.Write([int16]16)
    $writer.Write([Text.Encoding]::ASCII.GetBytes("data"))
    $writer.Write([int]$dataSize)

    for ($i = 0; $i -lt $samples; $i++) {
        $fade = 1.0 - ($i / $samples)

        $sample = [Math]::Sin(
            2 * [Math]::PI * $Frequency * $i / $SampleRate
        )

        $value = [int16](10000 * $sample * $fade)
        $writer.Write($value)
    }

    $writer.Flush()
    $stream.Position = 0

    return $stream
}

$ChimeStream = New-ToneWav
$Player = New-Object System.Media.SoundPlayer($ChimeStream)
$Player.Load()

# Window -----------------------------------------------------------------------
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "4 Minute Timer"
$Form.ClientSize = New-Object System.Drawing.Size(270,145)
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false
$Form.MinimizeBox = $true
$Form.StartPosition = "Manual"
## Set TopMost true for always on top - - - - - - - - - - - - - - - - - - - - -
$Form.TopMost = $true

# Restore previous position if available ---------------------------------------
$positionLoaded = $false

if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

        if ($null -ne $config.X -and $null -ne $config.Y) {
            $Form.Location = New-Object System.Drawing.Point(
                [int]$config.X,
                [int]$config.Y
            )
            $positionLoaded = $true
        }
    }
    catch {
        # Ignorance is bliss.
    }
}

if (-not $positionLoaded) {
    $Form.StartPosition = "CenterScreen"
}

# Show countdown ---------------------------------------------------------------
$Display = New-Object System.Windows.Forms.Label
$Display.Location = New-Object System.Drawing.Point(20,15)
$Display.Size = New-Object System.Drawing.Size(230,70)
$Display.TextAlign = "MiddleCenter"
$Display.Font = New-Object System.Drawing.Font("Segoe UI",32)
$Display.Text = "4:00"

$Form.Controls.Add($Display)

# Buttons ----------------------------------------------------------------------
$StartStopButton = New-Object System.Windows.Forms.Button
$StartStopButton.Location = New-Object System.Drawing.Point(25,95)
$StartStopButton.Size = New-Object System.Drawing.Size(100,34)
$StartStopButton.Text = "Start"

$MuteButton = New-Object System.Windows.Forms.Button
$MuteButton.Location = New-Object System.Drawing.Point(145,95)
$MuteButton.Size = New-Object System.Drawing.Size(100,34)
$MuteButton.Text = "Mute"

$Form.Controls.Add($StartStopButton)
$Form.Controls.Add($MuteButton)

# Timer ------------------------------------------------------------------------
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000

$Timer.Add_Tick({

    $script:Remaining--

    if ($script:Remaining -le 0) {

        if (-not $script:Muted) {
            $Player.Play()
        }

        $script:Remaining = $script:IntervalSeconds
    }

    $minutes = [Math]::Floor($script:Remaining / 60)
    $seconds = $script:Remaining % 60

    $Display.Text = "{0}:{1:00}" -f $minutes, $seconds
})

# Start / Stop -----------------------------------------------------------------
$StartStopButton.Add_Click({

    if ($script:Running) {

        $Timer.Stop()
        $script:Running = $false
        $StartStopButton.Text = "Start"

    }
    else {

        $Timer.Start()
        $script:Running = $true
        $StartStopButton.Text = "Stop"
    }
})

# Mute / Unmute ----------------------------------------------------------------
$MuteButton.Add_Click({

    $script:Muted = -not $script:Muted

    if ($script:Muted) {
        $MuteButton.Text = "Unmute"
    }
    else {
        $MuteButton.Text = "Mute"
    }
})

# Save window position on exit -------------------------------------------------
$Form.Add_FormClosing({

    try {
        if (-not (Test-Path $ConfigDir)) {
            New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        }

        @{
            X = $Form.Location.X
            Y = $Form.Location.Y
        } |
        ConvertTo-Json |
        Set-Content -Path $ConfigFile
    }
    catch {
        # Close regardless. Death comes for us all.
    }
})



# Run --------------------------------------------------------------------------
[void]$Form.ShowDialog()

$Timer.Dispose()
$Player.Dispose()
$ChimeStream.Dispose()