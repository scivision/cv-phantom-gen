# CV phantom generator

[![image](https://zenodo.org/badge/31153745.svg)](https://zenodo.org/badge/latestdoi/31153745)

Computer Vision phantom generation, particularly useful for simulated images of the aurora borealis.

```sh
python -m pip install -e .[io]
```

The [io] parameter installs
[imageio](http://imageio.github.io/)
and
[imageio-ffmpeg](https://pypi.org/project/imageio-ffmpeg/,
necessary to write files to disk, which is what you normally want to do.

## Usage

* swirls: [NarrowArcBlur.py](./NarrowArcBlur.py)
* full variety of forms: [AuroraPhantom.py](./AuroraPhantom.py)

type the desired filename to save to e.g.

```sh
python NarrowArcBlur.py swirl.avi
```
