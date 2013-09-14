#!/bin/sh

# Make sure we're given shapefiles
if [ $# -lt 1 ]; then
    echo "Must supply at least 1 SHP file"
    exit 1
fi

for f in $@; do
    case $f in
        *shp);;
        *)
            echo "$f is does not have a shp extention"
            exit 2
        ;;
    esac
done

# We need the first file later on
# to generate the schema
first_file=$1

base=`basename $first_file .shp`
sql=$base.sql

# Check for a WKT projection file
if [ ! -e $base.prj ]; then
    echo "No prj file found"
    exit 5
fi

wkt=`cat $base.prj`

# Get the proj4 text for the WKT
prj4=`gdalsrsinfo $base.prj | grep PROJ | awk -F \' '{ print $2}' `
echo $prj4
exit

# If there was an error, then :(
if [ $? -ne 0 ]; then
    echo "$prj4 returned when converting $base.prj"
    exit 3
fi

# Check to see if that proj4 exists
# If so, use it, otherwise insert
# the WKT and proj4 into the spatial_ref_sys table
# with an auth_name of the file and an auth_srid of 1
# Not the best solution, but ?
srid=`echo "SELECT srid
        FROM spatial_ref_sys
        WHERE "proj4text" = '$prj4';" | psql -t | tr -d '\n '`

if [ "x$srid" != "x" ]; then
    echo "Found SRID ${srid}"
else
    srid=`echo "INSERT INTO spatial_ref_sys ( srid, auth_name, auth_srid, srtext, proj4text) 
VALUES ((SELECT MAX(srid) + 1 FROM spatial_ref_sys),
      '$base', 1, '$wkt', '$prj4') RETURNING srid" | psql -t | grep -v INSERT | tr -d '\n '`
    echo "Using SRID $srid"
fi

# Create the table definition
shp2pgsql -s $srid -p $first_file $base  > $sql

# Put all the data into the table
for i in $@; do
    shp2pgsql -s $srid -a -D $i $base >> $sql
done

