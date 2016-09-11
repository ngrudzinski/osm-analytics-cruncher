#!/bin/bash -ex

# usage: ./upload.sh mapbox-username
# set a MapboxAccessToken environment variable before running, e.g.
# export MapboxAccessToken=<access token with uploads:write scope enabled>
# ./upload.sh rodowi

npm install --global mapbox-upload
mapbox-upload $1.osm-analytics-buildings buildings.mbtiles
