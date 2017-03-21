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
# * SOURCE_FILE - mbtiles tiles file name to be used to extract features
# * SOURCE_URL - URL to download SOURCE_FILE from 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# config
WORKING_DIR=/mnt/data
RESULTS_DIR=~/results
SERVER_SCRIPT=/home/ubuntu/server/serve.js
SOURCE_FILE=laos.mbtiles
SOURCE_URL=https://s3.amazonaws.com/mapbox/osm-qa-tiles/latest.country/$SOURCE_FILE.gz

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
curl $SOURCE_URL --silent | gzip -d > $SOURCE_FILE

# generate user experience data
./experiences.sh $SOURCE_FILE

# generate osm-analytics data
# buildings
./crunch.sh $SOURCE_FILE buildings 64
cp buildings.mbtiles $RESULTS_DIR/buildings.mbtiles.tmp
rm $RESULTS_DIR/buildings.mbtiles -f
mv $RESULTS_DIR/buildings.mbtiles.tmp $RESULTS_DIR/buildings.mbtiles
forever restart $SERVER_SCRIPT
rm buildings.mbtiles
# highways
./crunch.sh $SOURCE_FILE highways 32
cp highways.mbtiles $RESULTS_DIR/highways.mbtiles.tmp
rm $RESULTS_DIR/highways.mbtiles -f
mv $RESULTS_DIR/highways.mbtiles.tmp $RESULTS_DIR/highways.mbtiles
forever restart $SERVER_SCRIPT
rm highways.mbtiles
# waterways
./crunch.sh $SOURCE_FILE waterways 32
cp waterways.mbtiles $RESULTS_DIR/waterways.mbtiles.tmp
rm $RESULTS_DIR/waterways.mbtiles -f
mv $RESULTS_DIR/waterways.mbtiles.tmp $RESULTS_DIR/waterways.mbtiles
forever restart $SERVER_SCRIPT
rm waterways.mbtiles
# railways
./crunch.sh $SOURCE_FILE railways 32
cp railways.mbtiles $RESULTS_DIR/railways.mbtiles.tmp
rm $RESULTS_DIR/railways.mbtiles -f
mv $RESULTS_DIR/railways.mbtiles.tmp $RESULTS_DIR/railways.mbtiles
forever restart $SERVER_SCRIPT
rm railways.mbtiles

rm planet.mbtiles
