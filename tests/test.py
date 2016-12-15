#!/usr/bin/env python
from cvphantom import genphantom
#from numpy.testing import assert_allclose

U = {'bitdepth': 16,
     'rowcol':   (128,128),
     'dxy':      (1,1),
     'nframe':   1,
     'fwidth':   10,
     'fstep':    1,
     'texture':  'vertsine',
}

imgs = genphantom(U)

assert imgs[31,6]==42125