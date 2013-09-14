#!/usr/bin/env python

import os
import sys
import string
import osgeo.osr

if (len(sys.argv) <> 2):
        print 'Usage: proj2wkt.py [Proj4 Projection Text]'
else:
        srs = osgeo.osr.SpatialReference()
        srs.ImportFromProj4(sys.argv[1])
        print srs.ExportToWkt()
