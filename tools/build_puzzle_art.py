"""Original game-specific vector-style puzzle backgrounds, rasterized with Pillow.
No downloaded or third-party copyrighted images are used.
"""
from PIL import Image,ImageDraw,ImageFilter
from pathlib import Path
import math,random
OUT=Path(__file__).resolve().parent.parent/'assets'/'ui'
W,H=860,470
GOLD=(221,177,101,255);PALE=(238,217,175,255);CYAN=(102,191,205,255);RED=(212,100,111,255)
random.seed(45)
def rgba(x,alpha=255):return (x[0],x[1],x[2],alpha)
def create():
 im=Image.new('RGBA',(W,H),(0,0,0,0));d=ImageDraw.Draw(im,'RGBA')
 d.rounded_rectangle((12,12,W-12,H-12),24,fill=(10,24,37,225),outline=(190,147,88,220),width=3)
 d.rounded_rectangle((28,28,W-28,H-28),18,outline=(103,123,137,130),width=1)
 for x in range(85,W-10,42):d.line((x,27,x+8,27),fill=(174,142,90,140),width=1)
 for i in range(38):
  x=random.randrange(40,W-40);y=random.randrange(40,H-40)
  d.ellipse((x,y,x+1,y+1),fill=(224,194,135,75))
 return im,d
def circle(d,x,y,r,color=GOLD,width=5):d.ellipse((x-r,y-r,x+r,y+r),outline=color,width=width)
def wire(d,points,color,thickness=11):
 d.line(points,fill=(8,9,19,240),width=thickness+7,joint='curve')
 d.line(points,fill=color,width=thickness,joint='curve')
 d.line(points,fill=(255,255,255,60),width=2,joint='curve')
def gear(d,x,y,r=85,teeth=12):
 poly=[]
 for i in range(teeth*4):
  a=math.pi*2*i/(teeth*4)
  rr=r*(1.12 if i%4 in (0,1) else .89)
  poly.append((x+math.cos(a)*rr,y+math.sin(a)*rr))
 d.polygon(poly,fill=(28,51,67,235),outline=GOLD,width=4)
 circle(d,x,y,int(r*.51),GOLD,4);circle(d,x,y,12,CYAN,4)
def header_ticks(d):
 for j in range(4):
  yy=102+j*70
  d.rounded_rectangle((60,yy,145,yy+45),10,fill=(31,50,64,255),outline=(191,154,95,235),width=2)
  d.line((91,yy+10,91,yy+34),fill=PALE,width=4)
  d.line((111,yy+10,111,yy+34),fill=PALE,width=4)

def sketch(kind, d):
 if kind=='code':
  d.rounded_rectangle((250,84,620,174),18,fill=(3,20,29,255),outline=GOLD,width=5)
  for i in range(4):
   x=300+i*78
   d.line((x,114,x+41,114),fill=CYAN,width=5);d.line((x,145,x+41,145),fill=CYAN,width=5)
  for i in range(12):
   x=320+(i%4)*65;y=237+(i//4)*72
   circle(d,x,y,23,(214,167,95,220),3)
 elif kind=='lock':
  d.arc((322,85,538,326),185,355,fill=PALE,width=24)
  d.arc((344,105,518,304),185,355,fill=(119,92,67,255),width=7)
  d.rounded_rectangle((290,236,570,399),24,fill=(45,61,68,245),outline=GOLD,width=8)
  for x in (352,430,508):circle(d,x,315,28,CYAN,5)
 elif kind=='cipher':
  d.polygon([(249,100),(609,77),(632,358),(266,385)],fill=(211,194,153,230),outline=(126,102,74,230),width=5)
  for j in range(6):
   y=132+j*38
   d.line((306,y,570,y-10),fill=(38,63,71,220),width=5)
  for x in [320,430,540]:d.arc((x-15,89,x+15,120),0,300,fill=RED,width=3)
 elif kind=='memory':
  for i in range(4):
   x=280+(i%2)*220;y=145+(i//2)*175
   d.rounded_rectangle((x-70,y-59,x+70,y+59),22,fill=(34,53,70,255),outline=GOLD,width=5)
   if i==0:d.polygon([(x,y-36),(x+34,y),(x,y+36),(x-34,y)],outline=CYAN,width=5)
   if i==1:circle(d,x,y,37,CYAN,6)
   if i==2:d.polygon([(x,y-41),(x+43,y+36),(x-43,y+36)],outline=RED,width=6)
   if i==3:d.rectangle((x-30,y-30,x+30,y+30),outline=PALE,width=6)
 elif kind=='wires':
  for j,col in enumerate([GOLD,CYAN,RED,(110,198,150,255)]):
   y=107+j*82
   circle(d,190,y,14,col,5);circle(d,670,y,14,col,5)
   wire(d,[(190,y),(320+25*j,y-20-12*j),(500+20*j,y+15),(670,y)],col,8)
 elif kind=='deduction':
  for i in range(3):
   x=240+i*165
   d.rounded_rectangle((x-61,122,x+61,321),15,fill=(38,55,68,240),outline=GOLD,width=4)
   circle(d,x,187,33,PALE,4)
   d.arc((x-45,216,x+45,289),185,355,fill=CYAN,width=7)
  d.line((192,364,672,364),fill=(198,155,91,190),width=5)
 elif kind=='hidden':
  d.polygon([(219,125),(609,100),(631,353),(248,379)],fill=(214,187,134,233),outline=(146,105,62,240),width=6)
  for j in range(4):d.line((281,164+j*35,555,153+j*35),fill=(75,80,79,220),width=4)
  circle(d,530,286,90,CYAN,9)
  wire(d,[(595,351),(680,408)],GOLD,15)
 elif kind=='logic':
  for i in range(5):
   x=220+i*109
   circle(d,x,200,34,GOLD,5)
   d.line((x,155,x,170),fill=CYAN,width=4)
   if i<4: d.line((x+43,200,x+65,200),fill=RED,width=5)
  d.line((230,306,632,306),fill=GOLD,width=3)
  for j in range(7): d.line((249+j*56,306,249+j*56,327),fill=PALE,width=2)
 elif kind=='time':
  circle(d,430,239,161,GOLD,8);circle(d,430,239,148,PALE,2)
  for i in range(12):
   a=(i/12)*math.tau
   x=430+math.sin(a)*133;y=239-math.cos(a)*133
   d.ellipse((x-4,y-4,x+4,y+4),fill=CYAN)
  wire(d,[(430,239),(430,148)],PALE,5);wire(d,[(430,239),(512,277)],GOLD,7)
  circle(d,430,239,12,PALE,5)
 elif kind=='hangman':
  for i in range(5):
   x=221+i*110;d.rounded_rectangle((x,170,x+80,250),12,fill=(35,52,66,255),outline=GOLD,width=4)
   d.line((x+15,229,x+64,229),fill=CYAN,width=4)
  d.polygon([(300,323),(550,323),(530,362),(322,362)],fill=(79,80,77,180),outline=GOLD,width=4)
 elif kind=='mechanism':
  gear(d,331,220,112);gear(d,536,256,94)
  d.arc((246,92,409,253),0,90,fill=PALE,width=3)
 elif kind=='maze':
  cell=55; x0=260;y0=94
  for row in range(6):
   for col in range(6):
    xx=x0+col*cell; yy=y0+row*cell
    d.rectangle((xx,yy,xx+cell,yy+cell),outline=(114,150,152,220),width=2)
  for col,row in [(1,0),(1,1),(2,1),(4,2),(3,3),(1,4),(3,5)]:
   xx=x0+col*cell+4; yy=y0+row*cell+4
   d.rectangle((xx,yy,xx+cell-8,yy+cell-8),fill=(209,167,106,230))
  circle(d,x0+cell//2,y0+cell//2,13,CYAN,4)
 elif kind=='inventory':
  d.rounded_rectangle((236,127,627,342),21,fill=(49,62,72,235),outline=GOLD,width=7)
  d.arc((360,82,500,170),180,360,fill=GOLD,width=16)
  for i in range(4):
   x=295+(i%2)*195;y=161+(i//2)*100
   d.rounded_rectangle((x,y,x+149,y+78),12,fill=(22,37,47,240),outline=CYAN,width=3)
 elif kind=='sound':
  center=246
  xs=list(range(213,650,16))
  for idx,x in enumerate(xs):
   h=abs(math.sin(idx*.46)+.40*math.sin(idx*.92+1.3))*76+14
   d.line((x,center-h,x,center+h),fill=CYAN if idx%3 else GOLD,width=7)
  circle(d,171,245,46,GOLD,6)
for k in ['code','lock','cipher','memory','wires','deduction','hidden','logic','time','hangman','mechanism','maze','inventory','sound']:
 im,d=create();sketch(k,d)
 im.save(OUT/f'apparatus_{k}.png',optimize=True)
 print('wrote',k)
