from numpy import ndarray
from oct2py import Oct2Py

def genphantom(U:dict) -> ndarray:
    oc = Oct2Py(oned_as='column',convert_to_float=False,timeout=5)
    oc.addpath('..')


    bg,data = oc.phantomTexture(U)

    data = oc.translateTexture(bg,data,[],U)

    return data