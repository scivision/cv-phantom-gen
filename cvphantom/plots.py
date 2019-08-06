from scipy.misc import bytescale, imsave
from matplotlib.pyplot import figure, draw, pause
import typing
import numpy as np

# import imageio  # TODO use for video writing
VideoWriter = None


def playwrite(imgs: np.ndarray, U: typing.Dict[str, typing.Any]):
    assert imgs.ndim == 3

    figure(1).clf()
    fg = figure(1)
    ax = fg.gca()
    hi = ax.imshow(imgs[0, ...], origin="bottom", interpolation="none")
    fg.colorbar(hi, ax=ax)

    if U["fmt"] == "avi" and VideoWriter is not None:  # output video requested
        ofn = f"{U['texture']}_{U['motion']}.avi"
        print("writing", ofn)
        hv = VideoWriter(ofn, "FFV1", imgs.shape[:2][::-1], usecolor=False)
    elif U["fmt"] is not None:
        hv = U["fmt"]
    else:
        hv = None

    for i in range(U["nframe"]):
        hi.set_data(imgs[i, ...])
        ax.set_title(f"{i}")
        draw(), pause(0.02)

        if hv is None:
            continue
        elif isinstance(hv, str):
            ofn = f"{U['texture']}_{U['motion']}_{i}.{hv}"
            print("writing", ofn)
            imsave(ofn, imgs[i, ...])
        else:
            hv.write(bytescale(imgs[i, ...], cmin=0, cmax=imgs.max()))
