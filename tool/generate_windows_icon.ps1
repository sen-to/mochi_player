$ErrorActionPreference = 'Stop'

# 把已提交的 Windows 图标 PNG 打包成 ICO；不需要图像库或 SDK。
#
# 源图必须是透明底：圆角以外 alpha = 0。macOS AppIcon 资产按 Apple HIG 保持
# 满幅不透明，四角是白色，直接拿来打包会让任务栏与窗口图标显示一圈白角。
# 因此 Windows 单独保存一份透明底导出，不要改回读取 macOS 资产。
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceDirectory = Join-Path $projectRoot 'windows/runner/resources'
$destination = Join-Path $sourceDirectory 'app_icon.ico'
$sizes = @(16, 32, 48, 64, 128, 256)
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
