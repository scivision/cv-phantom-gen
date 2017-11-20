#!/usr/bin/env python
req = ['nose','numpy','scipy','scikit-image','pillow']
# %%
from setuptools import setup, find_packages


setup(name='cvphantom',
      packages=find_packages(),
      version='0.5.0',   
      author='Michael Hirsch, Ph.D.',
	  description='Generate basic phantoms for computer vision work',
	  long_description=open('README.rst').read(),
      install_requires=req,
      extras_require={'plot':['matplotlib','pyimagevideo']},
      python_requires='>=3.6',
	  )
