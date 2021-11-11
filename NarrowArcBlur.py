#!/usr/bin/env python
"""
Closely-spaced arc simulator
"""
from __future__ import annotations
import scipy.ndimage as nd
import argparse
import numpy as np
from pathlib import Path
import imageio
import typing as T

import cvphantom
import cvphantom.plots as cp


def run(U: dict[str, T.Any], two_arcs: bool = False) -> np.ndarray:
    # %% computing
    bg = cvphantom.phantomTexture(U)
    if two_arcs:
        # can wrap uint intensity values if arcs overlap
        bg = bg + nd.shift(bg, [0, 15])

    return cvphantom.translateTexture(bg, U)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("savefn", help="filename to save simulted video", nargs="?")
    p.add_argument("-two", help="make two arcs", action="store_true")
    P = p.parse_args()

    # user parameters
    U = {
        "dtype": "uint16",
        "rowcol": (512, 512),
        "dxy": (1, 1),
        "xy": (0, 0),  # displacement
        "nframe": 100,
        "fwidth": 5,
        "fstep": 1,
        "gausssigma": 10,
        "texture": "vertsine",
        "motion": "swirl",
        "fmt": None,
        "x0": [256],  # swirl centers
        "y0": [256],  # swirl centers
        "strength": 10,  # swirl
        "radius": 30,  # swirl
    }

    imgs = run(U, P.two)

    if P.savefn:
        savefn = Path(P.savefn).expanduser()
        print("writing video to", savefn)
        imageio.mimwrite(savefn, cvphantom.sixteen2eight(imgs))
    else:
        cp.play(imgs, U)
