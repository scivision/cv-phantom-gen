from oct2py import Oct2Py

def genphantom(rc,nFrame,step,dxy, texture,motion,bits,fwidth,gausssigma):
    oc = Oct2Py(oned_as='column',convert_to_float=False,timeout=5)

#%% build user parameter dict
    U = {'bitdepth':bits,
         'rowcol':rc,
         'dxy':dxy,
         'nframe':nFrame,
         'fwidth':fwidth,
         'fstep':step,
         'gaussiansigma':gausssigma,
         'texture':texture,
         'motion':motion,
         'playvideo':False
    }

    bg,data = oc.phantomTexture(U)

    data = oc.translateTexture(bg,data,[],U)

    return data
