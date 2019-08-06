#!/usr/bin/env python
"""
Auroral Phantom Generator

# stationary vertical bar
./AuroraPhantom.py -t vertbar -n 1
"""
from matplotlib.pyplot import show

#
from cvphantom import phantomTexture, translateTexture
from cvphantom.plots import playwrite

if __name__ == "__main__":
    from argparse import ArgumentParser

    p = ArgumentParser(description="Auroral Phantom Generator")
    p.add_argument(
        "--rc",
        help="number of rows, column pixels in image",
        nargs=2,
        type=int,
        default=(512, 512),
    )
    p.add_argument(
        "-o",
        "--format",
        help="write format (avi, png, pnm) for the output",
        default=None,
    )
    p.add_argument(
        "-t", "--texture", help="select texture (vertsize,...)", default="vertsine"
    )
    p.add_argument(
        "-m",
        "--motion",
        help="how the phantom moves (vertslide,horizslide,swirl,...)",
        default="horizslide",
    )
    p.add_argument("-b", "--bits", help="bits per pixel of data", default=8, type=int)
    p.add_argument("-w", "--width", help="feature width", type=float, default=30)
    p.add_argument(
        "-n",
        "--nframe",
        help="number of frames (time steps) to create",
        type=int,
        default=10,
    )
    p.add_argument(
        "--gausssigma",
        help="Gaussian std dev (only for gaussian phantoms)",
        type=float,
        default=35,
    )
    p.add_argument("-s", "--step", help="jump size in sim", type=int, default=1)
    p.add_argument(
        "-d",
        "--dxy",
        help="dx dx spatial step size",
        type=float,
        nargs=2,
        default=(1, 1),
    )
    p = p.parse_args()

    # %% build user parameter dict
    U = {
        "bitdepth": p.bits,
        "rowcol": p.rc,
        "dxy": p.dxy,
        "nframe": p.nframe,
        "fwidth": p.width,
        "fstep": p.step,
        "gaussiansigma": p.gausssigma,
        "texture": p.texture,
        "motion": p.motion,
        "fmt": p.format,
    }
    # %% computing
    bg = phantomTexture(U)
    # bg = bg + shift(bg,[0,15]) # this line can wrap values if you overlap
    imgs = translateTexture(bg, U)
    # %% plotting / saving
    playwrite(imgs, U)

    show()
