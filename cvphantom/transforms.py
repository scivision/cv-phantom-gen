import typing
import numpy as np
import scipy.ndimage.interpolation as ndi
import scipy.ndimage as nd
import skimage.transform as skt


def sixteen2eight(img: np.ndarray, Clim: typing.Tuple[int, int] = None) -> np.ndarray:
    """
    stretch uint16 data to uint8 data e.g. images

    Parameters
    ----------
    img: numpy.ndarray
        N-D Numpy array of grayscale image data
    Clim: tuple of int, optional
        lowest and highest expected values

    Returns
    -------
    img: numpy.ndarray
        N-D Numpy array of uint8 grayscale image data
    """
    # full dynamic range if not specified
    if Clim is None:
        Clim = (0, np.iinfo(img.dtype).max)

    # stretch to [0,255] as a float
    Q = normframe(img, Clim) * 255

    return Q.astype(np.uint8)  # convert to uint8


def normframe(img: np.ndarray, Clim: typing.Tuple[int, int] = None) -> np.ndarray:
    """
    Normalize array to [0, 1]

    Parameters
    ----------
    img: numpy.ndarray
        data to be normalized
    Clim: tuple of int
        lowest and highest expected values

    Returns
    -------
    img: numpy.ndarray
        N-D Numpy array of normalized float32 grayscale image data
    """
    # full dynamic range if not specified
    if Clim is None:
        Clim = (0, np.iinfo(img.dtype).max)
    Vmin = Clim[0]
    Vmax = Clim[1]

    return (img.astype(np.float32).clip(Vmin, Vmax) - Vmin) / (Vmax - Vmin)


def translateTexture(bg: np.ndarray, U: typing.Dict[str, typing.Any]) -> np.ndarray:
    """
     to make multiple simultaneous phantoms, call this function repeatedly and sum the result
    """
    if "motion" not in U:
        U["motion"] = None
    if "nframe" not in U:
        U["nframe"] = 1
    if "fstep" not in U or not U["fstep"]:
        U["fstep"] = 1

    nrow, ncol = bg.shape
    nframe = U["nframe"]
    data = np.zeros((nframe, nrow, ncol), bg.dtype)  # initialize all frame

    # %% indices for frame looping
    img = range(0, nframe, U["fstep"])

    if isinstance(U["motion"], str):
        motion = U["motion"].lower()
    else:
        motion = U["motion"]

    # %% implement motion
    if motion in (None, "none"):
        for i in img:
            data[i, ...] = bg
    elif motion == "swirl":
        for i in img:
            strength = i / nframe * U["strength"]
            for x, y in zip(U["x0"], U["y0"]):  # for each swirl center...
                data[i, ...] = skt.swirl(
                    bg,
                    (x, y),
                    strength,
                    radius=U["radius"],
                    rotation=0,
                    clip=True,
                    preserve_range=True,
                )

    elif motion == "rotate360ccw":
        for i in img:
            q = (nframe - i) / nframe * 360  # degrees
            data[i, ...] = ndi.rotate(bg, q, reshape=False)
    elif motion == "rotate180ccw":
        for i in img:
            q = (nframe - i) / nframe * 180  # degrees
            data[i, ...] = ndi.rotate(bg, q, reshape=False)
    elif motion == "rotate90ccw":
        for i in img:
            q = (nframe - i) / nframe * 90  # degrees
            data[i, ...] = ndi.rotate(bg, q, reshape=False)
    elif motion == "shearright":
        for i in img:
            data[i, ...] = doShearRight(bg, i, U)
    elif motion == "diagslide":
        for i in img:
            data[i, ...] = nd.shift(
                bg, [-nframe + i * U["dxy"][1], -nframe + i * U["dxy"][0]]
            )
    elif motion == "horizslide":
        print(f"Horizontally moving feature, dim: {data.shape}")
        for i in img:
            data[i, ...] = nd.shift(bg, [0, -nframe + i * U["dxy"][0]])
    elif motion == "vertslide":
        for i in img:
            data[i, ...] = nd.shift(bg, [-nframe + i * U["dxy"][1], 0])
    else:
        ValueError(f"Unknown motion method {U['translate']}")

    return data


def doShearRight(bg: np.ndarray, i: int, U: typing.Dict[str, typing.Any]) -> np.ndarray:
    """
    see also http://scikit-image.org/docs/dev/api/skimage.transform.html#affinetransform
    """
    nframe = U["nframe"]

    T = [[1, 0, 0], [(nframe - i * U["dxy"][0]) / nframe, 1, 0], [0, 0, 1]]

    return ndi.affine_transform(bg, T)
