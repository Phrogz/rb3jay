# rb3jay
A democratic, crowd-controlled music player for the workplace.


# Features
* Smart Playlists (don't hear the same song in the same week; don't hear Christmas music except for 3 weeks prior).
* Headless core server application can support multiple front-ends.
* Includes a web-based front-end, allowing an iTunes-like experience.
* Vote on upcoming songs through web interface; songs are group-ranked (not a single ranking)


# Requirements & Installation

* Requires the [`sequel`](http://sequel.jeremyevans.net) and [`sqlite3`](https://github.com/sparklemotion/sqlite3-ruby) gems to be installed.
  * This, in turn, requires that you have SQLite installed, including the development headers (e.g. `apt-get install libsqlite3-dev`)
* Requires the [`ruby-mpd`](https://github.com/archSeer/ruby-mpd) gem to be installed.
  * This, in turn, requires that you have [`mpd`](http://www.musicpd.org) installed.
  * This needs to run on a machine with fast file-level access to the "sticker" file for MPD. Most simply this means running on the same machine as MPD.
  * Currently this requires that you have [`mpc`](http://www.musicpd.org/clients/mpc/) is installed on the same machine as RB3Jay.
* Requires the [`faye`](https://github.com/faye/faye) gem to be installed.
* Requires the [`haml`](https://github.com/haml/haml) gem to be installed.
* Editing tags requires the [`taglib-ruby`](http://robinst.github.io/taglib-ruby/) gem to be installed
  * This, in turn, requires that you have [`taglib`](http://developer.kde.org/~wheeler/taglib.html) installed along with header files.
* Requires `sinatra`, and `moneta` gems installed.
  * Suggest that you also install `thin` and use that to run the web server.
* `gem install rb3jay`

In summary:

```
sudo apt-get install build-essentials sqlite3 libsqlite3-dev mpd mpc ruby ruby-dev
sudo gem install sqlite3 sequel ruby-mpd faye haml sinatra moneta thin
```


# Starting the Servers

## rb3jay Core Server
* `rb3jay --help` for command-line options.

## rb3jay-www Web Server
* _TODO_

# Communicating with the Server

The rb3jay server is a headless application that manages songs, playlists,
voting, and actually plays the music (via MPD). All communication with the server occurs
through TCP sockets carrying a JSON object.

Every query you send to the server is identified by a `cmd` property
describing your intent, sometimes along with additional arguments.

The supported commands are summarized here, and described in detail below that.


**Querying**

* `playlists`: get a list of all playlists, with summary information
* `playlist`: get a list of all songs for a playlist
* _(TODO)_ `playing`: get details about the currently-playing song and playlist
* _(TODO)_ `upcoming`: see a summary of upcoming songs
* `songs`: get a summary of all songs in the library
* `song`: get detailed information about a particular song
* `search`: find songs in the library


**Playback Control**

* `stop`: pause playback
* _(TODO)_ `play`: resume playback, or start a particular playlist or song
* `next`: skip to the next song
* `back`: restart the current song, or go to a previous song
* `seek`: jump to a particular playback time
* _(TODO)_ `want`: add a particular song to the upcoming playlist
* _(TODO)_ `nope`: remove a particular song from the upcoming playlist


**Voting**

* _(TODO)_ `love`: indicate +2 for a song for a particular user
* _(TODO)_ `like`: indicate +1 for a song for a particular user
* _(TODO)_ `zero`: indicate +0 for a song for a particular user
* _(TODO)_ `bleh`: indicate -1 for a song for a particular user
* _(TODO)_ `hate`: indicate -2 for a song for a particular user


**Modifying the Library**

* `update`: check for new/changed/deleted songs in the library
* `makePlaylist`: create a new playlist
* _(TODO)_ `editPlaylist`: update a playlist
* _(TODO)_ `killPlaylist`: delete a playlist
* _(TODO)_ `editSong`: update metadata for a particular song
* _(TODO)_ `killSong`: remove a song from the library

**Admin**

* _(TODO)_ `removeUser`: clear all actions by a particular user
* _(TODO)_ `history`: show the log of all actions taken in a particular time period
* `quit`: quit the server

## Query Commands

### `{ "cmd":"playlists" }` → _array of playlists_

Returns a JSON array of all JSON playlist objects in the system, sorted by name.

Each playlist summary object looks like the following:

~~~ json
{
  "name"  : "Party Time",
  "songs" : 42,
  "code"  : null
}
~~~

If the playlist is "live" the `code` key will have a string of the query
used to generate the playlist.

Use the `playlist` query to get the list of songs for a particular playlist.


### `{"cmd":"playlist", "name":"…"}` → _playlist details_
Returns a JSON object identical to those returned by `playlists`,
except that the `songs` key is an array of of JSON song summary objects
for the playlist.

Songs are sorted by artist, album, track, and title.
Each song summary object looks like the following:

~~~ json
{
  "file"    : "Chicane/Giants/12 Titles.m4a",
  "title"   : "Titles",
  "artist"  : "Chicane",
  "album"   : "Giants",
  "genre"   : "Dance",
  "date"    : 2010,
  "time"    : 261,
  "rank"    : 0.6327,
  "artwork" : "Chicane/Giants/12 Titles.m4a.jpg"
}
~~~

The `length` value is the duration the song in seconds.

The `rank` value is the relative value of the song (based on complex voting),
and is normalized between 0 and 1 (inclusive).

Metadata missing for a song (e.g. no `year` information) will be missing from
the object; there will not be a key with a `null` value.


### `{"cmd":"playing"}` → _array of song summaries_
Returns a song summary object.

### `{"cmd":"upcoming"}`
see a summary of upcoming songs


### `{"cmd":"songs"}` → _array of song summaries_
Returns a JSON array of JSON song summary objects for every song tracked in the library.

Songs are sorted by artist, album, track, and title.
Each song summary object looks like the following:

~~~ json
{
  "file"    : "Chicane/Giants/12 Titles.m4a",
  "title"   : "Titles",
  "artist"  : "Chicane",
  "album"   : "Giants",
  "genre"   : "Dance",
  "date"    : 2010,
  "time"    : 261,
  "rank"    : 0.6327,
  "artwork" : "Chicane/Giants/12 Titles.m4a.jpg"
}
~~~


### `{"cmd":"song", "file":…}` → _song details_
Returns a JSON object with detailed information about the song with the
supplied file.

Song details look like the following:

~~~ json
{
  "file"        : "Chicane/Giants/12 Titles.m4a",
  "title"       : "Titles",
  "artist"      : "Chicane",
  "album"       : "Giants",
  "genre"       : "Dance",
  "date"        : 2010,
  "time"        : 261,
  "rank"        : 0.6327,
  "artwork"     : "Chicane/Giants/12 Titles.m4a.jpg",
  "modified"    : "2015-07-29 04:46:01 UTC",
  "track"       : 12,
  "composer"    : "N. Bracegirdle/J. Hockley",
  "disc"        : 1,
  "albumartist" : "Chicane",
  "bpm"         : 134
}
~~~

### `{"cmd":"search", "query":"…"}` → _array of song summaries_
Returns a JSON array of JSON song summary objects for every song tracked in the library.

The simple `query` field is matched loosely against `title`, `artist`, `album`, `genre`, and `year`.

## Playback Control Commands

### `{"cmd":"stop"}`
pause playback


### `{"cmd":"play", …}`
To start or resume playback from the current song list,
issue this command with no additional parameters.


### `{"cmd":"next"}`
skip to the next song


### `{"cmd":"back"}`
restart the current song, or go to a previous song


### `{"cmd":"seek", "time":4.71}`
jump to a particular playback time


### `{"cmd":"want"}`
add a particular song to the upcoming playlist


### `{"cmd":"nope"}`
remove a particular song from the upcoming playlist


## Song Voting

Each user of rb3jay can express their opinion about a song.
The relative desirability of each song is based on a complex formula
taking overall voting into account.

The five voting levels are:

* `love` +2 : I'm not tired of this song, play it every day.
* `like` +1 : This song should come up more often than others.
* `zero`  0 : I'm okay with this song.
* `bleh` -1 : I'm getting tired of this song. Play it every other week.
* `hate` -2 : If it were up to me, this song would never be played.

Voting on a song requires the song's file and the name of the user who is voting:

~~~ json
{
  "cmd"  : "like",
  "file" : "Chicane/Giants/12 Titles.m4a",
  "user" : "phrogz"
}
~~~



## Modifying Commands

### `{"cmd":"makePlaylist", "name":"…"}`
The `name` parameter is the name of the new playlist.
You may optionally include a `code` parameter set to a string to create this
as a "live" playlist.

### `{"cmd":"editPlaylist", "name"="…", …}`
Update the information about a playlist, or its song contents.
Along with the `editPlaylist` command and the `name` attribute identifying the
playlist to modify, you must supply one or more of the following changes to make:

* `{…, "newName"="…"}` — rename the playlist.
* `{…, "code"="…"}` — set the query to use for a "live" playlist.
  Set this to `null` to make this a normal playlist.
* `{…, "add"=["file1","file3","file2"]}` — add the songs (specified by song `file`).
  Playlists are unordered; the order of songs has no impact on the result.
  Adding songs will be ignored if the playlist is "live".
* `{…, "remove"=["file7","file3"]}` — remove the songs (specified by song `file`).
  Songs that are not already in the playlist will be silently ignored.
  Removing songs will be ignored if the playlist is "live".


### `{"cmd":"killPlaylist", "name"="…"}`
Delete a playlist, specified by name.

### `{"cmd":"editSong", "file"="…"}`
update metadata for a particular song



## Admin Commands

### `{"cmd":"removeUser"}`
Clear all actions (especially votes) by a particular user.

### `{"cmd":"history"}`
show the log of all actions taken in a particular time period

### `{"cmd":"quit"}`
Cleanly shut down the server. Does not send a response.



# Contact
Gavin Kistner <!@phrogz.net>
