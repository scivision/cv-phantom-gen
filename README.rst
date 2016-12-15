.. image:: https://travis-ci.org/scienceopen/cv-phantom-gen.svg?branch=master
    :target: https://travis-ci.org/scienceopen/cv-phantom-gen
.. image:: https://coveralls.io/repos/github/scienceopen/cv-phantom-gen/badge.svg?branch=master
    :target: https://coveralls.io/github/scienceopen/cv-phantom-gen?branch=master

==============
cv-phantom-gen
==============

Computer Vision phantom generation, particularly useful for simulated images of the aurora borealis. Usable from Python, Octave, or Matlab.
This was originally an Octave/Matlab program, but it's now simply ``.m`` code called by Oct2Py from Python.


.. contents::

Prereq
======
::

    sudo apt install octave

    octave --eval 'pkg install -forge -verbose image'

    pip install --upgrade oct2py

Install
=======
::

    python setup.py develop

Usage
=====
::

    ./AuroraPhantom.py
