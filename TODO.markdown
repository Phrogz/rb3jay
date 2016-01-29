* Populate Live Queue from My Queues
	* Add random songs in a stable pattern, minus added songs
	* Limit by song length accumulated per day (live query db + proposed songs)
	* Record the queue a song came from (via sticker; remove sticker when played, record with play event and time accumulation)
	* Remove songs from user queues once played
	* Limit random songs by weight
* Control Rating for active song with keyboard
* Control Rating for inspected song with keyboard
* Batch import ratings per user
* Multiple-inspect - apply inspector ratings to all selected songs
* Calculate Ranking
* Load Ranking
* Bug: can't start playing when launching and idle
* Bug: same song twice in playlist highlights both as active
* Handle song changes not during `watch_status`, but during `watch_player`
* Reorder My Queue
* Save Queue as a playlist
* Calculate fallback playlist
* Populate Live Queue from Fallback Playlist
* Support composer and other metadata on demand
* Load Artwork
* Delete from Live (?)

---

* playback metadata, e.g. skips, play count, last played as stickers
* stale love rankings
* calculated playlists
	* compile to queries (or just expressed as query?)
* shuffle weighted by ranking
* ranking based on multiple user votes, skip count
	* http://www.evanmiller.org/how-not-to-sort-by-average-rating.html
