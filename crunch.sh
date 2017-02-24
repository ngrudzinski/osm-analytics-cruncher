#!/bin/bash -ex

## todo: make it run in another directory
## todo: drop unneccessary osm tags

BINNINGFACTOR=${3:-64}

### make temporary directory for intermediate results
##mkdir -p intermediate

# apply filter, merge with user experience data, aggregate to bins
# and create z13-z14 tiles for raw data
./src/index.js $1 $2.json
cp empty.mbtiles out.mbtiles
./merge-mbtile.sh out.mbtiles $2.geom.*.mbtiles
cp empty.mbtiles out.12.mbtiles
./merge-mbtile.sh out.12.mbtiles $2.aggr.*.mbtiles

# downscale bins to zoom levels 11 to 0
for i in {11..0}; do
    ./src/downscale.js out.$((i+1)).mbtiles $BINNINGFACTOR
    cp empty.mbtiles out.$i.mbtiles
    ./merge-mbtile.sh out.$i.mbtiles out.tmp.*.mbtiles
done

# merge in aggredate data zoom levels
./merge-mbtile.sh out.mbtiles out.*.mbtiles
mv out.mbtiles $2.mbtiles

### clean up temporary data
##rm intermediate/*
##rmdir intermediate
