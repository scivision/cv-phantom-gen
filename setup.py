#!/usr/bin/env python
from setuptools import setup
import subprocess

try:
    subprocess.call(['conda','install','--file','requirements.txt'])
except Exception as e:
    pass

#%% install
setup(name='cvphantom',
	  description='Generate basic phantoms for computer vision work',
      packages=['cvphantom'],
	  )
