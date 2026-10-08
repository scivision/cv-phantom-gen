#!/usr/bin/env python3
"""
Auroral Phantom Generator

# stationary vertical bar
./AuroraPhantom.py -t vertbar -n 1
"""

import argparse
import scipy.ndimage as nd
import imageio
from pathlib import Path

import cvphantom
import cvphantom.plots as cp

if __name__ == "__main__":
    p = argparse.ArgumentParser(description="Auroral Phantom Generator")
    p.add_argument("savefn", help="filename to save simulted video", nargs="?")
    p.add_argument("-two", help="two auroral arcs", action="store_true")
    p.add_argument(
        "--rc",
        help="number of rows, column pixels in image",
        nargs=2,
        type=int,
        default=(512, 512),
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
    args = p.parse_args()

    # %% build user parameter dict
    U = {
        "bitdepth": args.bits,
        "rowcol": args.rc,
        "dxy": args.dxy,
        "nframe": args.nframe,
        "fwidth": args.width,
        "fstep": args.step,
        "gaussiansigma": args.gausssigma,
        "texture": args.texture,
        "motion": args.motion,
    }
    # %% computing
    bg = cvphantom.phantomTexture(U)
    if args.two:
        bg = bg + nd.shift(bg, [0, 15])  # this line can wrap values if you overlap

    imgs = cvphantom.translateTexture(bg, U)

    if args.savefn:
        savefn = Path(args.savefn).expanduser()
        print("writing video to", savefn)
        imageio.mimwrite(savefn, cvphantom.sixteen2eight(imgs))
    else:
        cp.play(imgs, U)
