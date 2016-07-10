#!/usr/bin/env python
from setuptools import setup
import subprocess

try:
    subprocess.call(['conda','install','--yes','--file','requirements.txt'])
except Exception as e:
    print('you will need to install packages in requirements.txt  {}'.format(e))


#%% install
setup(name='cvphantom',
	  description='Generate basic phantoms for computer vision work',
	  author='Michael Hirsch',
      install_requires=['oct2py'],
	  url='https://github.com/scienceopen/cv-phantom-gen',
        packages=['cvphantom']
	  )
