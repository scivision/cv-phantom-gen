#!/usr/bin/env python
import pytest
from cvphantom import phantomTexture


def test_textures():
    U = {'dtype': 'uint16',
         'rowcol':   (128, 128),
         'dxy':      (1, 1),
         'nframe':   1,
         'fwidth':   10,
         'fstep':    1,
         'texture':  'vertsine',
         }

    imgs = phantomTexture(U)

    assert imgs.dtype == U['dtype']
    assert imgs[62, 62] == 53018


if __name__ == '__main__':
    pytest.main([__file__])
