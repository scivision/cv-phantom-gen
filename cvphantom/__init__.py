from numpy import ones, zeros, linspace, radians, sin, arange, iinfo, tile, clip
from numpy.random import rand
from scipy.ndimage.filters import gaussian_filter, gaussian_laplace
from scipy.ndimage.interpolation import rotate, affine_transform
from scipy.ndimage import shift
from skimage.data import checkerboard
from skimage.transform import swirl


def phantomTexture(U: dict):
    nrow, ncol = U['rowcol']
    fwidth = U['fwidth']
    if 'dtype' in U and U['dtype'] is not None:
        U['dtype'] = U['dtype']
    else:
        U['dtype'] = 'uint8'

    bgmax = valmax(U['dtype'])
    bstep = round(bgmax/(nrow/2))
    rmax = bgmax

    texture = U['texture'].lower()

    if texture == 'wall':
        bg = bgmax * ones(U['rowcol'], U['dtype'])
    elif texture == 'uniformrandom':
        bg = (bgmax * rand(U['rowcol'])).astype(U['dtype'])
    elif texture == 'gaussian':
        bg = zeros(U['rowcol'], float)
        bg[nrow//2, ncol//2] = 1.
        bg = gaussian_filter(bg, U['gausssigma'])
        bg = bgmax * bg / bg.max()  # normalize to full bit range
        bg = bg.astype(U['dtype'])
        assert bg[nrow//2, ncol//2] == bgmax, 'did you wrap value?'
    elif texture == 'vertsine':
        bgr = zeros(ncol, float)  # yes, double to avoid quantization
        bg = zeros(U['rowcol'], U['dtype'])
        s = slice(ncol//2-fwidth//2, ncol//2+fwidth//2+1)
        bgr[s] = sin(radians(linspace(0, 180, len(bgr[s]))))  # don't do int8 yet or you'll quantize it to zero!
        rowind = range(nrow//4, nrow*3//4)
        bg[rowind, :] = bgmax * bgr
        bg = bg.astype(U['dtype'])  # needs to be its own line
    elif texture == 'laplacian':
        bg = zeros(U['rowcol'], float)
        bg[nrow//2, ncol//2] = 1.
        bg = -gaussian_laplace(bg, U['gausssigma'])
        bg -= bg.min()
        bg = bgmax * bg / bg.max()  # normalize to full bit range
    elif texture == 'xtriangle':
        bg = zeros(ncol, U['dtype'])
        bg[:ncol//2] = arange(0, rmax, bstep, U['dtype'])
        bg[ncol//2:] = bg[:ncol//2][::-1]
        bg = tile(bg[None, :], [nrow, 1])
    elif texture == 'ytriangle':
        bg = zeros(nrow, U['dtype'])
        bg[:nrow//2] = arange(0, rmax, bstep, U['dtype'])
        bg[nrow//2:] = bg[:nrow//2][::-1]
        bg = tile(bg[:, None], [1, ncol])
    elif texture in ('pyramid', 'pyramid45'):
        bg = zeros(U['rowcol'], U['dtype'])
        temp = arange(0, rmax, bstep, U['dtype'])
        for i in range(1, nrow//2):
            bg[i, i:-i] = temp[i]  # north face
            bg[i:-i, i] = temp[i]  # west face
            bg[-i-1, i:-i] = temp[i]  # south face
            bg[i:-i, -i-1] = temp[i]  # east face

        if U['texture'] == 'pyramid45':
            bg = rotate(bg, 45, reshape=False)
    elif texture == 'spokes':  # 3 pixels wide
        bg = zeros(U['rowcol'])  # float to avoid overflow
        bg[nrow//2-fwidth//2:nrow//2 + fwidth//2, :ncol] = bgmax  # horizontal line
        bg[:nrow, ncol//2 - fwidth//2:ncol//2 + fwidth//2] = bgmax  # vertical line
        bg = clip(bg + rotate(bg, 45, reshape=False), 0, bgmax).astype(U['dtype'])  # diagonal line
    elif texture == 'vertbar':  # vertical bar, starts center of image
        bg = zeros(U['rowcol'], U['dtype'])

        # bg(1:nRow,end-4:end) = bgMaxVal; %vertical line, top to bottom

        # vertical bar starts 1/4 from bottom and 1/4 from top of image
        bg[nrow*1//4:nrow*3//4, ncol//2 - fwidth//2:ncol//2 + fwidth//2] = bgmax
    elif texture == 'checkerboard':
        bg = checkerboard()  # no input options, it's loading an image
    else:
        raise TypeError('unspecified texture {} selected'.format(U['texture']))

    return bg


def valmax(dtype):
    try:
        bgmax = iinfo(dtype).max
    except ValueError:
        if dtype is float:
            bgmax = 1.  # normalize
        else:
            raise ValueError('unknown dtype {}'.format(dtype))

    print('max pixel intensities for {} are taken to be: {}'.format(dtype, bgmax))

    return bgmax


def translateTexture(bg, U: dict):
    """
     to make multiple simultaneous phantoms, call this function repeatedly and sum the result
    """
    if 'motion' not in U:
        U['motion'] = None
    if 'nframe' not in U:
        U['nframe'] = 1
    if 'fstep' not in U or not U['fstep']:
        U['fstep'] = 1

    nrow, ncol = bg.shape
    nframe = U['nframe']
    data = zeros((nframe, nrow, ncol), bg.dtype)  # initialize all frame

# %% indices for frame looping
    img = range(0, nframe, U['fstep'])

    if isinstance(U['motion'], str):
        motion = U['motion'].lower()
    else:
        motion = U['motion']

# %% implement motion
    if motion in (None, 'none'):
        for i in img:
            data[i, ...] = bg
    elif motion == 'swirl':
        for i in img:
            strength = i/nframe*U['strength']
            for x, y in zip(U['x0'], U['y0']):  # for each swirl center...
                data[i, ...] = swirl(bg, (x, y), strength,
                                     radius=U['radius'], rotation=0, clip=True, preserve_range=True)

    elif motion == 'rotate360ccw':
        for i in img:
            q = (nframe-i)/nframe*360  # degrees
            data[i, ...] = rotate(bg, q, reshape=False)
    elif motion == 'rotate180ccw':
        for i in img:
            q = (nframe-i)/nframe*180  # degrees
            data[i, ...] = rotate(bg, q, reshape=False)
    elif motion == 'rotate90ccw':
        for i in img:
            q = (nframe-i)/nframe*90  # degrees
            data[i, ...] = rotate(bg, q, reshape=False)
    elif motion == 'shearright':
        for i in img:
            data[i, ...] = doShearRight(bg, i, U)
    elif motion == 'diagslide':
        for i in img:
            data[i, ...] = shift(bg, [-nframe+i*U['dxy'][1], -nframe+i*U['dxy'][0]])
    elif motion == 'horizslide':
        print('Horizontally moving feature, dim: {}'.format(data.shape))
        for i in img:
            data[i, ...] = shift(bg, [0, -nframe+i*U['dxy'][0]])
    elif motion == 'vertslide':
        for i in img:
            data[i, ...] = shift(bg, [-nframe+i*U['dxy'][1], 0])
    else:
        ValueError('Unknown motion method {}'.format(U['translate']))

    return data


def doShearRight(bg, i, U):
    """
    see also http://scikit-image.org/docs/dev/api/skimage.transform.html#affinetransform
    """
    nframe = U['nframe']

    T = [[1, 0, 0],
         [(nframe-i*U['dxy'][0])/nframe, 1, 0],
         [0, 0, 1]]

    return affine_transform(bg, T)
