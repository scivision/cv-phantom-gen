#!/usr/bin/env python3
"""
Auroral Phantom Generator
GPLv3+
Michael Hirsch
uses Oct2Py to call legacy code I wrote in 2012 for Octave in Python
"""
from __future__ import division
from oct2py import Oct2Py
import numpy as np
from platform import system

def genphantom(xy,nFrame,step,dxy,writeformat,texture,motion,bits,fwidth,gausssigma):
    if system() == 'Windows':
        octexe='C:/Octave/Octave-4.0.0/bin/octave.exe' #lame
    else:
        octexe=None
    oc = Oct2Py(executable=octexe,oned_as='column',convert_to_float=True,timeout=5)

    bg,bgminmax,data,dtype = oc.phantomTexture(texture,xy[1],xy[0],nFrame,fwidth,gausssigma,bits)

    data = oc.translateTexture(bg,data,step,dxy[0],dtype,1,np.nan, 1,
                               np.nan, texture,0,
                               0,'',str(motion))


    return data

if __name__ == '__main__':
    from matplotlib.pyplot import figure,draw, pause
    from argparse import ArgumentParser
    p = ArgumentParser(description="Auroral Phantom Generator")
    p.add_argument('--xy',help='number of X Y pixels',nargs=2,type=int,default=(512,512))
    p.add_argument('-f','--format',help='write format (avi, png, pnm) for the output',default=None)
    p.add_argument('-t','--texture',help='select texture (vertsize,...)',default='vertsine')
    p.add_argument('-m','--motion',help='how the phantom moves (vertslide,horizslide,swirl,...)',default='horizslide')
    p.add_argument('-b','--bits',help='bits per pixel of data',default=16,type=int)
    p.add_argument('-w','--width',help='feature width',type=float,default=30)
    p.add_argument('-n','--nframe',help='number of frames (time steps) to create',type=int,default=10)
    p.add_argument('--gausssigma',help='Gaussian std dev (only for gaussian phantoms)',type=float,default=35)
    p.add_argument('--step',help='jump size in sim',type=int,default=1)
    p.add_argument('--dxy',help='dx dx spatial step size',type=float,nargs=2,default=(1,1))
    p = p.parse_args()

    data = genphantom(p.xy, p.nframe, p.step,p.dxy,p.format, p.texture,p.motion,p.bits,
                      p.width,p.gausssigma)
#%%
    fg = figure()
    ax=fg.gca()
    hi = ax.imshow(data[...,0])
    fg.colorbar(hi)
    for i in range(p.nframe):
        hi.set_data(data[...,i])
        ax.set_title('t=' + str(i) + ' ' +p.texture + ' ' + p.motion)
        draw(), pause(0.02)