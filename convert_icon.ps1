Add-Type -AssemblyName System.Drawing
$imgPath = "C:\Development\academypro\academypro_app\assets\images\app_logo.jpg"
$pngPath = "C:\Development\academypro\academypro_app\assets\images\app_logo.png"

$img = [System.Drawing.Image]::FromFile($imgPath)
$img.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

$densities = @('hdpi', 'mdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi')
foreach ($d in $densities) {
    $target = "C:\Development\academypro\academypro_app\android\app\src\main\res\mipmap-$d\ic_launcher.png"
    $img.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Converted $target"
}
$img.Dispose()
