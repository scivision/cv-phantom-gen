import typing
import numpy as np
import scipy.ndimage.filters as ndf
import scipy.ndimage.interpolation as ndi
from skimage.data import checkerboard
from numpy.random import rand


def phantomTexture(U: typing.Dict[str, typing.Any]):
    nrow, ncol = U["rowcol"]
    fwidth = U["fwidth"]
    if "dtype" in U and U["dtype"] is not None:
        U["dtype"] = U["dtype"]
    else:
        U["dtype"] = "uint8"

    bgmax = valmax(U["dtype"])
    bstep = np.round(bgmax / (nrow / 2))
    rmax = bgmax

    texture = U["texture"].lower()

    if texture == "wall":
        bg = bgmax * np.ones(U["rowcol"], U["dtype"])
    elif texture == "uniformrandom":
        bg = (bgmax * rand(U["rowcol"])).astype(U["dtype"])
    elif texture == "gaussian":
        bg = np.zeros(U["rowcol"], float)
        bg[nrow // 2, ncol // 2] = 1.0
        bg = ndf.gaussian_filter(bg, U["gausssigma"])
        bg = bgmax * bg / bg.max()  # normalize to full bit range
        bg = bg.astype(U["dtype"])
        assert bg[nrow // 2, ncol // 2] == bgmax, "did you wrap value?"
    elif texture == "vertsine":
        bgr = np.zeros(ncol, float)  # yes, double to avoid quantization
        bg = np.zeros(U["rowcol"], U["dtype"])
        s = slice(ncol // 2 - fwidth // 2, ncol // 2 + fwidth // 2 + 1)
        bgr[s] = np.sin(
            np.radians(np.linspace(0, 180, len(bgr[s])))
        )  # don't do int8 yet or you'll quantize it to zero!
        rowind = range(nrow // 4, nrow * 3 // 4)
        bg[rowind, :] = bgmax * bgr
        bg = bg.astype(U["dtype"])  # needs to be its own line
    elif texture == "laplacian":
        bg = np.zeros(U["rowcol"], float)
        bg[nrow // 2, ncol // 2] = 1.0
        bg = -ndf.gaussian_laplace(bg, U["gausssigma"])
        bg -= bg.min()
        bg = bgmax * bg / bg.max()  # normalize to full bit range
    elif texture == "xtriangle":
        bg = np.zeros(ncol, U["dtype"])
        bg[: ncol // 2] = np.arange(0, rmax, bstep, U["dtype"])
        bg[ncol // 2:] = bg[: ncol // 2][::-1]
        bg = np.tile(bg[None, :], [nrow, 1])
    elif texture == "ytriangle":
        bg = np.zeros(nrow, U["dtype"])
        bg[: nrow // 2] = np.arange(0, rmax, bstep, U["dtype"])
        bg[nrow // 2:] = bg[: nrow // 2][::-1]
        bg = np.tile(bg[:, None], [1, ncol])
    elif texture in ("pyramid", "pyramid45"):
        bg = np.zeros(U["rowcol"], U["dtype"])
        temp = np.arange(0, rmax, bstep, U["dtype"])
        for i in range(1, nrow // 2):
            bg[i, i:-i] = temp[i]  # north face
            bg[i:-i, i] = temp[i]  # west face
            bg[-i - 1, i:-i] = temp[i]  # south face
            bg[i:-i, -i - 1] = temp[i]  # east face

        if U["texture"] == "pyramid45":
            bg = ndi.rotate(bg, 45, reshape=False)
    elif texture == "spokes":  # 3 pixels wide
        # float to avoid overflow
        bg = np.zeros(U["rowcol"])
        # horizontal line
        bg[nrow // 2 - fwidth // 2: nrow // 2 + fwidth // 2, :ncol] = bgmax
        # vertical line
        bg[:nrow, ncol // 2 - fwidth // 2: ncol // 2 + fwidth // 2] = bgmax
        # diagonal line
        bg = np.clip(bg + ndi.rotate(bg, 45, reshape=False), 0, bgmax).astype(
            U["dtype"]
        )
    elif texture == "vertbar":  # vertical bar, starts center of image
        bg = np.zeros(U["rowcol"], U["dtype"])

        # bg(1:nRow,end-4:end) = bgMaxVal; %vertical line, top to bottom

        # vertical bar starts 1/4 from bottom and 1/4 from top of image
        bg[
            nrow * 1 // 4: nrow * 3 // 4,
            ncol // 2 - fwidth // 2: ncol // 2 + fwidth // 2,
        ] = bgmax
    elif texture == "checkerboard":
        bg = checkerboard()  # no input options, it's loading an image
    else:
        raise TypeError(f'unspecified texture {U["texture"]} selected')

    return bg


def valmax(dtype):
    try:
        bgmax = np.iinfo(dtype).max
    except ValueError:
        if dtype is float:
            bgmax = 1.0  # normalize
        else:
            raise ValueError(f"unknown dtype {dtype}")

    print(f"max pixel intensities for {dtype} are taken to be: {bgmax}")

    return bgmax
