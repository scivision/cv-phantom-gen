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
     'nframe':   1,
     'fwidth':   5,
     'fstep':    1,
     'gausssigma':10,
     'texture':  'vertsine',
     'motion':   'horizslide',
     'fmt': None,
}
#%% computing
bg = phantomTexture(U)
bg = bg + shift(bg,[0,15]) # this line can wrap values if you overlap

data = translateTexture(bg,U)
#%% plotting / saving
playwrite(data,U)

show()
