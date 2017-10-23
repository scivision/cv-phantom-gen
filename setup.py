#!/usr/bin/env python
req = ['nose','numpy','scipy','scikit-image','pillow','matplotlib']
# %%
import pip
try:
    import conda.cli
    conda.cli.main('install',*req)
except Exception as e:
    pip.main(['install'] +req)

# %%
from setuptools import setup


setup(name='cvphantom',
      packages=['cvphantom'],   
      author='Michael Hirsch, Ph.D.',
	  description='Generate basic phantoms for computer vision work',
      install_requires=req,
	  )
