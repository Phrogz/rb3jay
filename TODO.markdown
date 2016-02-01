* Reorder My Queue
* Pad Up Next with Random songs
	* Add random songs in a stable pattern, minus added songs
	* Limit random songs by weight
	* Preserve songs added from other players behind queues, ahead of random. (Priority 0/1/2?)
* Show last n played songs above "up next", allow ranking
* Control Rating for active song with keyboard
* Control Rating for inspected song(s) with keyboard
* Batch import ratings per user
* Multiple-inspect - apply inspector ratings to all selected songs
* Calculate Ranking
* Load Ranking
* Bug: can't start playing when launching and idle
* Bug: same song twice in playlist highlights both as active
* Bug: re-adding song to queue leaves ghost entry higher in queue
* Handle song changes not during `watch_status`, but during `watch_player`
* Save Queue as a playlist
* Calculate fallback playlist
* Populate Live Queue from Fallback Playlist
* Load Artwork
* Delete from Live (?)
* Delegate draggable code to the tbody parent, so it's not re-created for each new row
* stale love rankings

---

* calculated playlists
	* compile to queries (or just expressed as query?)
* ranking based on multiple user votes, skip count
	* http://www.evanmiller.org/how-not-to-sort-by-average-rating.html
