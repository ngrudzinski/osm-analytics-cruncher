#!/bin/bash -ex

# usage: ./upload.sh mapbox-username
# set a MapboxAccessToken environment variable before running, e.g.
# export MapboxAccessToken=<access token with uploads:write scope enabled>
# ./upload.sh rodowi

node_modules/mapbox-upload/bin/upload.js $1.osm-analytics-buildings buildings.mbtiles

