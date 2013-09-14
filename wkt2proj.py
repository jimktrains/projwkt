#!/usr/bin/env python

import os
import sys
import string
import osgeo.osr

srs = osgeo.osr.SpatialReference()
srs.ImportFromESRI([sys.stdin.read()])
print(srs.ExportToProj4())
