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

def genphantom(xy,writeformat,texture,motion,dtype,fwidth):
    if system() == 'Windows':
        octexe='C:/Octave/Octave-4.0.0/bin/octave.exe' #lame
    else:
        octexe=None
    oc = Oct2Py(executable=octexe,oned_as='column',convert_to_float=True,timeout=5)
    #bg = oc.phantomTexture(texture,dtype,xy[1],xy[0],bgmaxval(dtype),fwidth)
    bg = oc.zeros(10)

    return bg



def bgmaxval(dtype):
    if dtype == 'float' or dtype is float:
        return 1.0
    elif dtype is int: #assuming uint16 is implied
        return np.uint16(65535)
    else:
        return np.iinfo(dtype).max

if __name__ == '__main__':
    from argparse import ArgumentParser
    p = ArgumentParser(description="Auroral Phantom Generator")
    p.add_argument('--xy',help='number of X Y pixels',nargs=2,type=int,default=(512,512))
    p.add_argument('-f','--format',help='write format (avi, png, pnm) for the output',default=None)
    p.add_argument('-t','--texture',help='select texture (vertsize,...)',default='vertsine')
    p.add_argument('-m','--motion',help='how the phantom moves (vertslide,horizslide,swirl,...)',default='horizslide')
    p.add_argument('-d','--dtype',help='data format (float, uint16,...) of data',default='uint16')
    p.add_argument('-w','--width',help='feature width',type=float,default=30)
    p = p.parse_args()

    data = genphantom(p.xy, p.format, p.texture,p.motion,p.dtype,p.width)
