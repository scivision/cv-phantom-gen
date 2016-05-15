#!/usr/bin/env python3
from cvphantom.genphantom import genphantom
from numpy.testing import assert_allclose

imgs = genphantom((128,128), 1, 1, (1,1), 'vertsine','horizslide',16,
                  10,None)

assert imgs[31,6]==42125