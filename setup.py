#!/usr/bin/env python
from setuptools import setup

req = ['nose','numpy','scipy','scikit-image','pillow','matplotlib']

#%% install
setup(name='cvphantom',
      packages=['cvphantom'],   
      author='Michael Hirsch, Ph.D.',
	  description='Generate basic phantoms for computer vision work',
      install_requires=req,
	  )
