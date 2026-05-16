Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot "..\assets\splash_image.png"
$webDir = Join-Path $PSScriptRoot "..\web"
$iconsDir = Join-Path $webDir "icons"

function Test-IsNearWhite {
    param([System.Drawing.Color]$Color)

    if ($Color.A -le 16) { return $true }
    return ($Color.R -ge 235 -and $Color.G -ge 235 -and $Color.B -ge 235)
}

function ConvertTo-RgbaBitmap {
    param([System.Drawing.Bitmap]$Source)

    $rgba = New-Object System.Drawing.Bitmap $Source.Width, $Source.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($rgba)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($Source, 0, 0, $Source.Width, $Source.Height)
    $g.Dispose()
    return $rgba
}

function Remove-WhiteBackground {
    param([System.Drawing.Bitmap]$Source)

    $result = New-Object System.Drawing.Bitmap $Source.Width, $Source.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    for ($y = 0; $y -lt $Source.Height; $y++) {
        for ($x = 0; $x -lt $Source.Width; $x++) {
            $color = $Source.GetPixel($x, $y)
            if (Test-IsNearWhite -Color $color) {
                $result.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
            else {
                $result.SetPixel($x, $y, $color)
            }
        }
    }

    return $result
}

function Get-VisibleBounds {
    param([System.Drawing.Bitmap]$Source)

    $minX = $Source.Width
    $minY = $Source.Height
    $maxX = 0
    $maxY = 0
    $found = $false

    for ($y = 0; $y -lt $Source.Height; $y++) {
        for ($x = 0; $x -lt $Source.Width; $x++) {
            $color = $Source.GetPixel($x, $y)
            if ($color.A -gt 16 -and -not (Test-IsNearWhite -Color $color)) {
                $found = $true
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if (-not $found) {
        return [PSCustomObject]@{
            X = 0
            Y = 0
            Width = $Source.Width
            Height = $Source.Height
        }
    }

    return [PSCustomObject]@{
        X = $minX
        Y = $minY
        Width = ($maxX - $minX + 1)
        Height = ($maxY - $minY + 1)
    }
}

function New-SquareIcon {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$Size,
        [double]$PaddingRatio = 0.08
    )

    $bounds = Get-VisibleBounds -Source $Source
    $crop = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gCrop = [System.Drawing.Graphics]::FromImage($crop)
    $gCrop.Clear([System.Drawing.Color]::Transparent)
    $gCrop.DrawImage(
        $Source,
        0,
        0,
        (New-Object System.Drawing.Rectangle $bounds.X, $bounds.Y, $bounds.Width, $bounds.Height),
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $gCrop.Dispose()

    $out = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver

    $pad = [int]($Size * $PaddingRatio)
    $inner = $Size - (2 * $pad)
    $scale = [Math]::Min($inner / $bounds.Width, $inner / $bounds.Height)
    $drawW = [int]($bounds.Width * $scale)
    $drawH = [int]($bounds.Height * $scale)
    $dx = [int](($Size - $drawW) / 2)
    $dy = [int](($Size - $drawH) / 2)
    $g.DrawImage($crop, $dx, $dy, $drawW, $drawH)
    $g.Dispose()
    $crop.Dispose()
    return $out
}

if (-not (Test-Path $srcPath)) {
    throw "Source logo not found: $srcPath"
}

if (-not (Test-Path $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir | Out-Null
}

$loaded = New-Object System.Drawing.Bitmap $srcPath
$rgba = ConvertTo-RgbaBitmap -Source $loaded
$loaded.Dispose()
$source = Remove-WhiteBackground -Source $rgba
$rgba.Dispose()

try {
    $sizes = @{
        (Join-Path $webDir "favicon.png") = 32
        (Join-Path $iconsDir "Icon-192.png") = 192
        (Join-Path $iconsDir "Icon-512.png") = 512
        (Join-Path $iconsDir "Icon-maskable-192.png") = 192
        (Join-Path $iconsDir "Icon-maskable-512.png") = 512
    }

    foreach ($entry in $sizes.GetEnumerator()) {
        $path = $entry.Key
        $size = $entry.Value
        $padding = if ($path -like "*maskable*") { 0.18 } else { 0.06 }
        $icon = New-SquareIcon -Source $source -Size $size -PaddingRatio $padding
        $icon.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $icon.Dispose()
        Write-Host "Wrote $path ($size x $size, transparent)"
    }
}
finally {
    $source.Dispose()
}
