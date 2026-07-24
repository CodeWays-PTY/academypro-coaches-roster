import os
from PIL import Image

src_path = r"C:\Development\academypro\academypro_app\assets\images\app_logo.jpg"
png_path = r"C:\Development\academypro\academypro_app\assets\images\app_logo.png"

img = Image.open(src_path)
img.save(png_path, "PNG")

densities = ['hdpi', 'mdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']
for d in densities:
    target = os.path.join(r"C:\Development\academypro\academypro_app\android\app\src\main\res", f"mipmap-{d}", "ic_launcher.png")
    img.save(target, "PNG")
    print(f"Saved {target}")
