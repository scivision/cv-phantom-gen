#!/usr/bin/env python
"""
Closely-spaced arc simulator
"""
from matplotlib.pyplot import show
#
from cvphantom import genphantom
from cvphantom.plots import playwrite
#%% build user parameter dict
U = {'bitdepth': 16,
     'rowcol':   (512,512),
     'dxy':      (1,1),
     'nframe':   100,
     'fwidth':   5,
     'fstep':    1,
     'gaussiansigma':10,
     'texture':  'spokes',#'horizbar',
     'motion':   'horizslide',
     'fmt': None,
}
#%% computing
imgs = genphantom(U)
#%% plotting / saving
playwrite(imgs,U)

show()
