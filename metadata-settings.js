//this file is not used anywhere (and shouldn't)
//it's just for dev purpose
//Edit it and copy-paste it in the site settings of the sync-server : page /site_settings


////////////// Email from Benoit LE ROUX
// The fields where null is acceptable are explicitly specified. For example :
// •   "inCatalogueFrom":{"type":["integer", "null" ] }

// All fields where null is not specified must have a non null value.
// For those fields, we have to decide which value to use when nothing has been entered in the UI.
// I propose to use the « default » attribute  of JSON schema.

// For each field, rules to apply in SyncServer UI are : 
// •   If a non-blank value has been entered (trim(value).length > 0) —> use this value
// •   If a blank value has been entered (trim(value).length = 0)
//      o   If « default » is defined for that field —> use default value
//      o   If « default » is not defined for that field
//             If the field is nullable –-> use null value
//             If the field is not nullable –-> use null value —> this is an error to report in the UI

// You can pre-filled all the UI with de default values (better for the user, although in most cases, default is blank string).

// Updated JSON schema is joined.

// Regards,
// Benoît.
///////////////


[{
    "name": "type",
    "type": "string",
    "options": ["", "movie", "serie", "book", "newspaper", "music"]
}, {
    "name": "id",
    "type": "string"
}, {
    "name": "typeLabel",
    "type": "string"
}, {
    "name": "title",
    "type": "string"
}, {
    "name": "description",
    "type": "string"
}, {
    "name": "imageUrl",
    "type": "string"
}, {
    "name": "size",
    "type": "int",
    "info": "in bytes"
}, {
    "name": "releaseDate",
    "type": "date",
    "info": "local time"
}, {
    "name": "inCatalogueFrom",
    "type": "epoch",
    "info": "local time"
}, {
    "name": "inCatalogueUntil",
    "type": "epoch",
    "info": "local time"
}, {
    "name": "validationPlatform",
    "type": "string",
    "options": ["", "orange", "labgency"]
}, {
    "showif": "validationPlatform=orange",
    "name": "validationPlatformData.mediaUrl",
    "type": "string"
}, {
    "showif": "validationPlatform=labgency",
    "name": "validationPlatformData.cid",
    "type": "string"
}, {
    "name": "mimeType",
    "type": "string",
    "options": ["", "audio/mpeg", "audio/mp3", "video/mp4", "application/pdf"]
}, {
    "name": "adImageUrl",
    "type": "string",
    "default": ""
}, {
    "name": "adWebSiteUrl",
    "type": "string",
    "default": ""
}, {
    "name": "contentSponsor",
    "type": "string",
    "default": ""
}, {
    "showif": "type=movie,serie",
    "name": "ageRating",
    "type": "string",
    "options": ["all public", "-10", "-12", "-16", "-18"],
    "default": "all public"
}, {
    "showif": "type=movie,serie",
    "name": "ageRatingCountry",
    "type": "string",
    "default": "",
    "info": "country code (example: fr, uk, de, es, it, etc...)"
}, {
    "name": "paymentPlatform",
    "type": "string",
    "options": ["none", "labgency-coupon"],
    "default": "none"
}, {
    "name": "isPromo",
    "type": "boolean",
    "default": false,
    "info": "promotional content (trailer, preview, etc…)"
}, {
    "showif": "type=movie",
    "name": "genre",
    "type": "string",
    "default": ""
}, {
    "showif": "type=movie,serie",
    "name": "director",
    "type": "string",
    "default": ""
}, {
    "showif": "type=movie,serie",
    "name": "actors",
    "type": "array",
    "default": [],
    "info": "comma separated list"
}, {
    "showif": "type=movie,serie",
    "name": "country",
    "type": "string",
    "default": ""
}, {
    "showif": "type=movie,serie,music",
    "name": "duration",
    "type": "int",
    "default": 0,
    "info": "in seconds"
}, {
    "showif": "type=movie,serie",
    "name": "rating",
    "type": "int",
    "default": 0,
    "info": "a number between 0 and 5"
}, {
    "showif": "type=serie",
    "name": "episodeTitle",
    "type": "string",
    "default": ""
}, {
    "showif": "type=serie",
    "name": "seasonNumber",
    "type": "string",
    "default": ""
}, {
    "showif": "type=serie",
    "name": "episodeNumber",
    "type": "string",
    "default": ""
}, {
    "showif": "type=music",
    "name": "trackTitle",
    "type": "string",
    "default": ""
}, {
    "showif": "type=book,music",
    "name": "author",
    "type": "string",
    "default": ""
}, {
    "showif": "type=book,newspaper,music",
    "name": "editor",
    "type": "string",
    "default": ""
}, {
    "showif": "type=newspaper",
    "name": "number",
    "type": "string",
    "default": ""
}]