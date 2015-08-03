# rb3jay
A democratic, crowd-controlled music player for the workplace.


# Features
* Smart Playlists (don't hear the same song in the same week; don't hear Christmas music except for 3 weeks prior).
* Headless core server application can support multiple front-ends.
* Includes a web-based front-end, allowing an iTunes-like experience.
* Vote on upcoming songs through web interface; songs are group-ranked (not a single ranking)


# Requirements & Installation

## rb3jay Core Server
* Requires the [`taglib-ruby`](http://robinst.github.io/taglib-ruby/) gem to be installed
  * This, in turn, requires that you have [`taglib`](http://developer.kde.org/~wheeler/taglib.html) installed along with header files.
* Requires the `sequel` and `sqlite3` gems to be installed.
  * This, in tern, requires that you have SQLite installed.
* `gem install rb3jay`

## rb3jay-www Web Server
* Requires `sinatra`, and `haml` gems installed.
  * Suggest that you also install `thin` and use that to run the web server.

# Starting the Servers

## rb3jay Core Server
* `rb3jay --help` for command-line options.

## rb3jay-www Web Server
* _TODO_

# Communicating with the Server

The rb3jay server is a headless application that manages songs, playlists,
voting, and actually plays the music. All communication with the server occurs
through TCP sockets carrying a JSON object.

Every query you send to the server is identified by a `cmd` property
describing your intent, sometimes along with additional arguments.

The supported commands are summarized here, and described in detail below that.

**Querying**

* `playlists`: get a list of all playlists, with summary information
* `playlist`: get a list of all songs for a playlist
* `playing`: get details about the currently-playing song and playlist
* `upcoming`: see a summary of upcoming songs
* `songs`: get a summary of all songs in the library
* `song`: get detailed information about a particular song


**Playback Control**

* `stop`: pause playback
* `play`: resume playback, or start a particular playlist or song
* `next`: skip to the next song
* `back`: restart the current song, or go to a previous song
* `seek`: jump to a particular playback time
* `want`: add a particular song to the upcoming playlist
* `nope`: remove a particular song from the upcoming playlist


**Voting**

* `love`: indicate +2 for a song for a particular user
* `like`: indicate +1 for a song for a particular user
* `zero`: indicate +0 for a song for a particular user
* `bleh`: indicate -1 for a song for a particular user
* `hate`: indicate -2 for a song for a particular user


**Modifying the Library**

* `scan`: add songs found in a directory to the library
* `makePlaylist`: create a new playlist
* `editPlaylist`: update a playlist
* `killPlaylist`: delete a playlist
* `editSong`: update metadata for a particular song
* `killSong`: remove a song from the library

**Admin**

* `removeUser`: clear all actions by a particular user
* `history`: show the log of all actions taken in a particular time period
* `quit`: quit the server

## Query Commands

### `{ "cmd":"playlists" }` → _array of playlists_

Returns a JSON array of all JSON playlist objects in the system, sorted by name.

Each playlist object looks like the following:

~~~ json
{
  "name"  : "Party Time",
  "added" : "2015-07-29T14:59:08Z",
  "songs" : 42,
  "code"  : null
}
~~~

If the playlist is "live" the `code` key will have a string of the query
used to generate the playlist.

Use the `playlist` query to get the list of songs for a particular playlist.

### `{"cmd":"playlist", "name":"…"}` → _array of song summaries_
Returns a JSON array of JSON song summary objects for a playlist specified by name.

Songs are sorted by artist, album, track, and title.
Each song summary object looks like the following:

~~~ json
{
	"id"     : 7347,
	"title"  : "Sanctuary (feat. Lucy Saunders) (Original Mix)",
	"artist" : "Gareth Emery",
	"album"  : "Northern Lights",
	"genre"  : "Dance",
	"year"   : 2010,
	"length" : 447.752,
	"rank"   : 0.4327
}
~~~

The `length` value is the duration the song in seconds.

The `rank` value is the relative value of the song (based on complex voting),
and is normalized between 0 and 1 (inclusive).

Metadata missing for a song (e.g. no `year` information) will be missing from
the object; there will not be a key with a `null` value.

### `{"cmd":"playing"}`
get details about the currently-playing song and playlist

### `{"cmd":"upcoming"}`
see a summary of upcoming songs

### `{"cmd":"songs"}` → _array of song summaries_
Returns a JSON array of JSON song summary objects for every song tracked in the library.

Songs are sorted by artist, album, track, and title.
Each song summary object looks like the following:

~~~ json
{
	"id"     : 7347,
	"title"  : "Sanctuary (feat. Lucy Saunders) (Original Mix)",
	"artist" : "Gareth Emery",
	"album"  : "Northern Lights",
	"genre"  : "Dance",
	"year"   : 2010,
	"length" : 447.752,
	"rank"   : 0.4327
}
~~~


### `{"cmd":"song"}`
get detailed information about a particular song

## Playback Control Commands

### `{"cmd":"stop"}`
pause playback

### `{"cmd":"play"}`
resume playback, or start a particular playlist or song

### `{"cmd":"next"}`
skip to the next song

### `{"cmd":"back"}`
restart the current song, or go to a previous song

### `{"cmd":"seek"}`
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

Voting on a song requires the song id and user name:

~~~ json
{
  "cmd":"like",
  "song":12345,
  "user":"phrogz"
}
~~~


## Modifying Commands

### `{"cmd":"scan", "directory":"...", "andsubdirs":false}` → _array of song summaries_
Find all songs in a directory and add them to the library.

Returns a JSON array of JSON song summary objects for every new, non-duplicate song found.

The `directory` argument should be an absolute path to the directory to search.
By default, this command searches sub-directories as well. Use the `andsubdirs` option to
limit searching only to the specified directory.

### `{"cmd":"makePlaylist", "name":"…"}`
The `name` parameter is the name of the new playlist.
You may optionally include a `code` parameter set to a string to create this
as a "live" playlist.

### `{"cmd":"editPlaylist"}`
create a new playlist, or modify an existing one
### `{"cmd":"editPlaylist"}`
create a new playlist, or modify an existing one

### `{"cmd":"editSong"}`
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
