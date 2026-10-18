$ErrorActionPreference = 'Stop'

# Reuse the committed branding renders; no image library or SDK is required.
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceDirectory = Join-Path $projectRoot 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
$destination = Join-Path $projectRoot 'windows/runner/resources/app_icon.ico'
$sizes = @(16, 32, 64, 128, 256)
$images = @($sizes | ForEach-Object {
    ,([System.IO.File]::ReadAllBytes((Join-Path $sourceDirectory "app_icon_$_.png")))
})

$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.BinaryWriter]::new($stream)
try {
    $writer.Write([uint16]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($index = 0; $index -lt $sizes.Count; $index++) {
        $dimension = $sizes[$index] % 256
        $writer.Write([byte]$dimension)
        $writer.Write([byte]$dimension)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]32)
        $writer.Write([uint32]$images[$index].Length)
        $writer.Write([uint32]$offset)
        $offset += $images[$index].Length
    }
    foreach ($image in $images) {
        $writer.Write([byte[]]$image)
    }
    $writer.Flush()
    [System.IO.File]::WriteAllBytes($destination, $stream.ToArray())
} finally {
    $writer.Dispose()
    $stream.Dispose()
}
Write-Output "Generated $destination"
