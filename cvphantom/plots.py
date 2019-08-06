from matplotlib.pyplot import figure, draw, pause
import typing
import numpy as np


def play(imgs: np.ndarray, U: typing.Dict[str, typing.Any]):
    if not imgs.ndim == 3:
        raise ValueError("Expected N x X x Y 3-D image stack.")

    figure(1).clf()
    fg = figure(1)
    ax = fg.gca()
    hi = ax.imshow(imgs[0, ...], origin="bottom", interpolation="none")
    fg.colorbar(hi, ax=ax)

    for i in range(U["nframe"]):
        hi.set_data(imgs[i, ...])
        ax.set_title(f"{i}")
        draw(), pause(0.02)
