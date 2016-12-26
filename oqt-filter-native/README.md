# oqt-filter

Filters out specific features from [osm-qa-tiles](http://osmlab.github.io/osm-qa-tiles/) and enhances feature properties with external [user experience](../oqt-user-experience) data.

Usage:

    node index.js <path-to-osmqatiles.mbtiles> <job.json> | tippecanoe …

See `job.example.json` for how to set up a job's properties.
