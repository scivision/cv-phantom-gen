#!/usr/bin/env python3
"""
Auroral Phantom Generator
"""
from scipy.misc import bytescale
from oct2py import Oct2Py

def genphantom(rc,nFrame,step,dxy, texture,motion,bits,fwidth,gausssigma):
    oc = Oct2Py(oned_as='column',convert_to_float=False,timeout=5)

#%% build user parameter dict
    U = {'bitdepth':bits,
         'rowcol':rc,
         'dxy':dxy,
         'nframe':nFrame,
         'fwidth':fwidth,
         'fstep':step,
         'gaussiansigma':gausssigma,
         'texture':texture,
         'motion':motion,
         'playvideo':False
    }

    bg,data = oc.phantomTexture(U)

    data = oc.translateTexture(bg,data,[],U)


    return data

if __name__ == '__main__':
    from matplotlib.pyplot import figure,draw, pause,show

    from argparse import ArgumentParser
    p = ArgumentParser(description="Auroral Phantom Generator")
    p.add_argument('--rc',help='number of rows, column pixels in image',nargs=2,type=int,default=(512,512))
    p.add_argument('-o','--format',help='write format (avi, png, pnm) for the output',default=None)
    p.add_argument('-t','--texture',help='select texture (vertsize,...)',default='vertsine')
    p.add_argument('-m','--motion',help='how the phantom moves (vertslide,horizslide,swirl,...)',default='horizslide')
    p.add_argument('-b','--bits',help='bits per pixel of data',default=16,type=int)
    p.add_argument('-w','--width',help='feature width',type=float,default=30)
    p.add_argument('-n','--nframe',help='number of frames (time steps) to create',type=int,default=10)
    p.add_argument('--gausssigma',help='Gaussian std dev (only for gaussian phantoms)',type=float,default=35)
    p.add_argument('--step',help='jump size in sim',type=int,default=1)
    p.add_argument('--dxy',help='dx dx spatial step size',type=float,nargs=2,default=(1,1))
    p = p.parse_args()
#%% computing
    imgs = genphantom(p.rc, p.nframe, p.step,p.dxy, p.texture,p.motion,p.bits,
                      p.width,p.gausssigma)
#%% plotting / saving
    fg = figure()
    ax=fg.gca()
    hi = ax.imshow(imgs[...,0])
    fg.colorbar(hi)

    if p.format == 'avi': #output video requested
        ofn = '{}_{}.avi'.format(p.texture,p.motion)
        print('writing {}'.format(ofn))
        from pyimagevideo.writeavi_opencv import videoWriter
        hv = videoWriter(ofn,'FFV1',imgs.shape[:2][::-1],usecolor=False)
    elif p.format is not None:
        from skimage import io
        io.use_plugin('freeimage')
        hv = p.format
    else:
        hv = None


    for i in range(p.nframe):
        hi.set_data(imgs[...,i])
        ax.set_title('{}'.format(i))
        draw(), pause(0.02)
        if hv is not None:
            if isinstance(hv,str):
                ofn = '{}_{}_{}.{}'.format(p.texture,p.motion,i,hv)
                print('writing {}'.format(ofn))
                io.imsave(ofn,imgs[...,i])
            else:
                hv.write(bytescale(imgs[...,i],cmin=0,cmax=imgs.max()))

    try:
        hv.release()
    except AttributeError:
        pass

    show()