"""Create original, locally synthesized audio for Mystery Escape's V2.
Requires Python with numpy; all generated WAV files are included in the Godot project.
"""
import os, numpy as np
from scipy.io.wavfile import write
from pathlib import Path
BASE=Path(__file__).resolve().parent.parent/'assets'
SR=16000
rng=np.random.default_rng(20261010)

def save(rel,a):
    path=BASE/rel
    path.parent.mkdir(parents=True,exist_ok=True)
    a=np.asarray(a,dtype=np.float64)
    peak=np.max(np.abs(a)) if a.size else 0
    if peak>.96: a*=.96/peak
    write(str(path),SR,np.int16(np.clip(a,-1,1)*32767))
    print(path.relative_to(BASE),path.stat().st_size)

def tgrid(seconds):return np.arange(int(SR*seconds))/SR

def tone(freq,t,kind='bell'):
    if kind=='bell':
        return .78*np.sin(2*np.pi*freq*t)+.19*np.sin(2*np.pi*freq*2*t)+.07*np.sin(2*np.pi*freq*3.01*t)
    if kind=='warm':
        return (.60*np.sin(2*np.pi*freq*t)+.20*np.sin(2*np.pi*2*freq*t+.13)+.10*np.sin(2*np.pi*3*freq*t+.25))
    return np.sin(2*np.pi*freq*t)

def note(arr,sec,freq,start,duration,amp=.13,kind='bell'):
    begin=int(start*SR); end=min(len(arr),begin+int(duration*SR))
    if begin>=len(arr):return
    t=np.arange(end-begin)/SR
    if kind=='bell':
        env=(1-np.exp(-t*70))*np.exp(-t*2.45)
    else:
        attack=np.minimum(1.0,t/.55)
        release=np.minimum(1.0,(duration-t)/.75)
        env=np.maximum(0,attack*release)
    arr[begin:end]+=amp*env*tone(freq,t,kind)

def music(scene,root,variant):
    # Four-bar original minor-mode ambient loop with piano and warm bowed synth pads.
    duration=24
    wave=np.zeros(int(SR*duration))
    chords=[(root,root+3,root+7),(root-2,root+2,root+5),(root-5,root-1,root+2),(root-7,root-3,root)]
    midi=lambda n: 440*2**((n-69)/12)
    base_shift=[0,2,-1,3,0,-2][variant]
    for bar,chord in enumerate(chords):
        for idx,n in enumerate(chord):
            note(wave,duration,midi(n-12+base_shift),bar*6,5.95,.036 if idx==0 else .027,'warm')
        note(wave,duration,midi(chord[0]-24),bar*6.0,3.0,.045,'warm')
        note(wave,duration,midi(chord[1]+12),bar*6+1.1,1.4,.055,'bell')
        note(wave,duration,midi(chord[2]+12),bar*6+3.75,1.2,.045,'bell')
        if variant in (2,4):
            note(wave,duration,midi(chord[0]+12),bar*6+4.6,.9,.035,'bell')
    tt=tgrid(duration)
    wave+=.003*np.sin(2*np.pi*(.15+.08*variant)*tt) * np.sin(2*np.pi*62*tt)
    # seamless fade for player.finished -> play() looping
    fade=int(.18*SR)
    wave[:fade]*=np.linspace(0,1,fade)
    wave[-fade:]*=np.linspace(1,0,fade)
    save('music/'+scene+'.wav',wave)

for j,(name,root) in enumerate([('menu',57),('manor',57),('laboratory',55),('prison',53),('museum',60),('clocktower',52)]):
    music(name,root,j)
# Tension layer: dry heartbeat pulse at 72 BPM that intensifies by blending in to the original bed.
duration=12;t=tgrid(duration);a=np.zeros(len(t))
for k in range(14):
    st=.14+k*.83
    ix=np.arange(int(.36*SR))/SR
    env=np.exp(-ix*18)
    pos=int(st*SR); end=min(pos+len(ix),len(a))
    if pos<len(a):a[pos:end]+=.16*env[:end-pos]*(np.sin(2*np.pi*(71-31*ix[:end-pos])*ix[:end-pos]))
a+=.014*(np.sin(2*np.pi*110*t)+np.sin(2*np.pi*111.2*t))
save('music/tension.wav',a)
# Victory sting and level unlock
v=np.zeros(int(SR*2.7))
for f,s in [(440,0),(554.37,.19),(659.26,.4),(880,.75),(1108.73,.95)]:note(v,2.7,f,s,1.2,.13,'bell')
save('music/victory.wav',v)

# Sound beds: filtered naturalistic procedural noise, gentle and unobtrusive.
def smoothed_noise(length,smoothing,seed):
    r=np.random.default_rng(seed).normal(size=int(length/smoothing)+3)
    return np.interp(np.arange(length),np.arange(len(r))*smoothing,r)
length=int(12*SR)
for name in ['rain','wind','clock','fire']:
    n=rng.normal(size=length)
    t=np.arange(length)/SR
    if name=='rain':
        a=.018*n+.018*smoothed_noise(length,50,200)
        for sec in np.arange(.3,12,.3):
            p=int(sec*SR);m=min(600,length-p)
            if m>0:a[p:p+m]+=.016*np.exp(-np.arange(m)/90)*rng.normal(size=m)
    elif name=='wind':
        a=.025*smoothed_noise(length,140,211)+.008*n
        a*=.75+.25*np.sin(2*np.pi*.065*t)
    elif name=='clock':
        a=.002*smoothed_noise(length,80,200)
        for sec in np.arange(.5,12,1.):
            p=int(sec*SR);ix=np.arange(1800)/SR
            a[p:p+len(ix)]+=.060*np.sin(2*np.pi*740*ix)*np.exp(-ix*32)
    else:
        a=.015*smoothed_noise(length,30,300)+.009*n
        for _ in range(62):
            p=int(rng.integers(0,length-750));ix=np.arange(750)/SR
            a[p:p+750]+=.065*rng.normal(size=750)*np.exp(-ix*45)
    fade=int(.32*SR)
    a[:fade]*=np.linspace(0,1,fade);a[-fade:]*=np.linspace(1,0,fade)
    save('ambience/'+name+'.wav',a)

# Short UI effects, distinctive timbres, quiet enough not to compete with music.
def sfx(name,length,func):
    t=tgrid(length);a=func(t)
    fade=min(int(.012*SR),len(a)//4)
    a[-fade:]*=np.linspace(1,0,fade)
    save('sounds/'+name+'.wav',a)

sfx('typing',.066,lambda t: (.035*rng.normal(size=len(t))+.018*np.sin(2*np.pi*580*t))*np.exp(-t*76))
sfx('click',.12,lambda t: (.07*np.sin(2*np.pi*730*t)+.022*rng.normal(size=len(t)))*np.exp(-t*43))
sfx('paper',.40,lambda t: .055*rng.normal(size=len(t))*np.sin(np.pi*t/.4)**2)
sfx('lock_click',.45,lambda t: (.11*np.sin(2*np.pi*(210-85*t)*t)+.06*rng.normal(size=len(t)))*np.exp(-t*12))
sfx('gear',.35,lambda t: (.045*np.sin(2*np.pi*210*t)+.035*rng.normal(size=len(t)))*np.exp(-t*12))
sfx('wrong_soft',.43,lambda t: (.07*np.sin(2*np.pi*240*t)+.035*np.sin(2*np.pi*200*t))*np.exp(-t*5.5))
sfx('solved',.95,lambda t: (.07*np.sin(2*np.pi*523*t)+.07*np.sin(2*np.pi*659*t)*(t>.17)+.08*np.sin(2*np.pi*784*t)*(t>.36))*np.exp(-t*2.4))
sfx('coins',.55,lambda t: (.06*np.sin(2*np.pi*1000*t)+.045*np.sin(2*np.pi*1320*t)*(t>.12))*np.exp(-t*6))
sfx('tick',.085,lambda t: (.07*np.sin(2*np.pi*1200*t)+.022*rng.normal(size=len(t)))*np.exp(-t*80))
sfx('alarm',.7,lambda t: (.08*np.sin(2*np.pi*580*t)+.06*np.sin(2*np.pi*740*t))*np.exp(-t*2.0))
sfx('unlock',1.05,lambda t: (.06*np.sin(2*np.pi*300*t)*np.exp(-t*5.0)+.055*np.sin(2*np.pi*800*t)*(t>.25)+.05*np.sin(2*np.pi*1020*t)*(t>.44))*np.exp(-t*2.0))
