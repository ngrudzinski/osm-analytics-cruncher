#!/bin/bash -ex

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# this is an example script for how to invoke  osm-analytics-cruncher to
# regenerate vector tiles for osm-analytics from osm-qa-tiles
#
# config parameters:
# * WORKING_DIR - working directory where intermediate data is stored
#                 (requires at least around ~160 GB for planet wide calc.)
# * RESULTS_DIR - directory where resulting .mbtiles files are stored
# * SERVER_SCRIPT - node script that serves the .mbtiles (assumed to be already
#                   started with `forever`)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# config
WORKING_DIR=/mnt/data
RESULTS_DIR=~/results
SERVER_SCRIPT=/home/ubuntu/server/serve.js

# clean up
trap cleanup EXIT
function cleanup {
  rm -rf $WORKING_DIR/osm-analytics-cruncher
}

# init repo
cd $WORKING_DIR
git clone https://github.com/ngrudzinski/osm-analytics-cruncher
cd osm-analytics-cruncher
npm install --silent

# update hot projects data
./hotprojects.sh || true

# download latest planet from osm-qa-tiles
curl https://s3.amazonaws.com/mapbox/osm-qa-tiles/latest.planet.mbtiles.gz --silent | gzip -d > planet.mbtiles

# generate user experience data
./experiences.sh planet.mbtiles

# generate osm-analytics data
# buildings
./crunch.sh planet.mbtiles buildings 64
cp buildings.mbtiles $RESULTS_DIR/buildings.mbtiles.tmp
rm $RESULTS_DIR/buildings.mbtiles -f
mv $RESULTS_DIR/buildings.mbtiles.tmp $RESULTS_DIR/buildings.mbtiles
forever restart $SERVER_SCRIPT
rm buildings.mbtiles
# highways
./crunch.sh planet.mbtiles highways 32
cp highways.mbtiles $RESULTS_DIR/highways.mbtiles.tmp
rm $RESULTS_DIR/highways.mbtiles -f
mv $RESULTS_DIR/highways.mbtiles.tmp $RESULTS_DIR/highways.mbtiles
forever restart $SERVER_SCRIPT
rm highways.mbtiles
# waterways
./crunch.sh planet.mbtiles waterways 32
cp waterways.mbtiles $RESULTS_DIR/waterways.mbtiles.tmp
rm $RESULTS_DIR/waterways.mbtiles -f
mv $RESULTS_DIR/waterways.mbtiles.tmp $RESULTS_DIR/waterways.mbtiles
forever restart $SERVER_SCRIPT
rm waterways.mbtiles
# railways
./crunch.sh planet.mbtiles railways 32
cp railways.mbtiles $RESULTS_DIR/railways.mbtiles.tmp
rm $RESULTS_DIR/railways.mbtiles -f
mv $RESULTS_DIR/railways.mbtiles.tmp $RESULTS_DIR/railways.mbtiles
forever restart $SERVER_SCRIPT
rm railways.mbtiles

rm planet.mbtiles
