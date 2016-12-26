'use strict';
var fs = require('fs');

var geojsonVt = require('geojson-vt');
var vtpbf = require('vt-pbf');
var zlib = require('zlib');
var MBTiles = require('mbtiles');
//var queue = require('queue-async')(1);

var filter = JSON.parse(fs.readFileSync(global.mapOptions.filterPath));

var mbtiles;
var initialized = false;

var users = {};
if (filter.experience.file)
    users = JSON.parse(fs.readFileSync(filter.experience.file));

// Filter features touched by list of users defined by users.json
module.exports = function _(tileLayers, tile, writeData, done) {
    if (!initialized) {
        mbtiles = new MBTiles('.oqt-filter-native.'+process.pid+'.mbtiles', function(err) {
            if (err) return console.error('""""', err);
            mbtiles.startWriting(function(err) {
                if (err) return console.error('####', err);
                initialized = true;
                _(tileLayers, tile, writeData, done); // restart process after initialization
            });
        });
        return;
    }

//console.log(arguments)
    var layer = tileLayers.osmqatiles.osm;
//console.log(layer)

    //var pbfout = vtpbf({layers: {osm: layer}})
//console.log(pbfout)
    //fs.writeFileSync(__dirname + '/out/'+tile.join('-')+'.pbf', zlib.gzipSync(pbfout));
    //done(); return;

    // filter
    function hasTag(feature, tag) {
        return feature.properties[tag] && feature.properties[tag] !== 'no';
    }
    layer.features = layer.features.filter(function(feature) {
        return feature.geometry.type === filter.geometry && hasTag(feature, filter.tag);
    });

    // enhance with user experience data
    layer.features.forEach(function(feature) {
        var props = feature.properties;
        var user = props['@uid'];
        feature.properties = {
            _uid : user,
            _timestamp: props['@timestamp']
        };
        feature.properties[filter.tag] = props[filter.tag];
        if (users[user] && users[user][filter.experience.field])
            feature.properties._userExperience = users[user][filter.experience.field]; // todo: include all/generic experience data?
    });

    if (layer.features.length === 0) return done();
    var tileData = geojsonVt(layer, {
        maxZoom: 14,
        buffer: 0,
        tolerance: 1, // todo: faster if >0? (default is 3)
        indexMaxZoom: 12
    }).getTile(tile[2], tile[0], tile[1]);
    var pbfout = zlib.gzipSync(vtpbf.fromGeojsonVt({ 'osm': tileData }));
    //fs.writeFile(__dirname + '/out/'+tile.join('-')+'.pbf', pbfout, function(err) {
    //    if (err) console.error(err);
    //});
    //done();
    mbtiles.putTile(tile[2], tile[0], tile[1], pbfout, function(err) {
        if (err) console.log(err);
        done();
    });
    //done();
    return;

    // output
    if (layer.features.length > 0)
        writeData(JSON.stringify(layer)+'\n');

    done();
};

process.on('SIGHUP', function() {
    //console.error('before exit');
    if (mbtiles) {
        mbtiles.stopWriting(function(err) {
            if (err) { console.log(err); process.exit(); }
            mbtiles.close(function(err) {
                if (err) console.log(err);
                process.exit();
            });
        });
    }
});
