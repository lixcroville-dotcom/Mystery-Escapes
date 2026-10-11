"""Rebuild the authored V8 notebook icon and the 20 illustrated avatar crops.
Source illustrations were generated specifically for this project.
"""
from pathlib import Path
from PIL import Image, ImageEnhance, ImageDraw, ImageFilter
root=Path(__file__).resolve().parents[1]
source=root/'assets/source/notebook_source.png'
portraits=root/'assets/source/avatar_sheet_source.png'
icon=Image.open(source).convert('RGB')
icon=icon.resize((1024,1024),Image.Resampling.LANCZOS)
icon.save(root/'assets/ui/ios_app_icon.png', optimize=True)
icon.save(root/'assets/ui/detective_notebook_v8.png', optimize=True)
# A cinematic, understated splash, maintaining pre-existing noir desk composition.
old=Image.open(root/'assets/ui/loading_background.png').convert('RGB')
base=ImageEnhance.Color(old).enhance(1.15)
canvas=Image.new('RGB',base.size)
canvas.paste(base)
over=Image.new('RGBA',canvas.size,(0,0,0,0))
d=ImageDraw.Draw(over)
d.rounded_rectangle((64,140,656,840),radius=39,fill=(10,15,26,177),outline=(223,170,106,125),width=3)
# Soft gilt lines under the notebook and at the foot of the screen.
d.line([(148,862),(572,862)],fill=(241,184,107,165),width=3)
over=over.filter(ImageFilter.GaussianBlur(0.35))
canvas=Image.alpha_composite(canvas.convert('RGBA'),over)
canvas.convert('RGB').save(root/'assets/ui/loading_background_v8.png',optimize=True)
# Portrait grid is an original 5x4 illustration, each character a separate square.
sheet=Image.open(portraits).convert('RGB')
w,h=sheet.size
out=root/'assets/ui/avatars'
out.mkdir(parents=True,exist_ok=True)
for row in range(4):
 for col in range(5):
  x0=round(col*w/5)+6;y0=round(row*h/4)+6
  x1=round((col+1)*w/5)-6;y1=round((row+1)*h/4)-6
  tile=sheet.crop((x0,y0,x1,y1)).resize((256,256),Image.Resampling.LANCZOS)
  tile.save(out/f'detective_{row*5+col+1:02d}.png',optimize=True)
print('V8 VISUAL ASSETS: notebook, splash, 20 avatars generated.')
