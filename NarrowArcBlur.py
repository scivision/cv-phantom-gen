#!/usr/bin/env python
"""
Closely-spaced arc simulator
"""
from scipy.ndimage import shift
from matplotlib.pyplot import show
#
from cvphantom import phantomTexture,translateTexture
from cvphantom.plots import playwrite
#%% build user parameter dict
U = {'dtype':    'uint16',
     'rowcol':   (512,512),
     'dxy':      (1,1),
     'xy':       (0,0), # displacement
     'nframe':   100,
     'fwidth':   5,
     'fstep':    1,
     'gausssigma':10,
     'texture':  'vertsine',
     'motion':   'swirl',
     'fmt':     None,
     'x0':      [256], #swirl centers
     'y0':      [256], #swirl centers
     'strength': 10, #swirl
     'radius' : 30, #swirl
}
#%% computing
bg = phantomTexture(U)
#bg = bg + shift(bg,[0,15]) # this line can wrap values if you overlap

data = translateTexture(bg,U)
#%% plotting / saving
playwrite(data,U)

show()
