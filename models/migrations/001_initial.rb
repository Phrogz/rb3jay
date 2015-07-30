Sequel.migration do
  change do
    create_table(:songs) do
      primary_key :id
      String  :file
      String  :title
      String  :artist
      String  :album
      String  :year
      String  :genre
      String  :track
      Float   :length
      Integer :bpm
      Time    :date_added
    end
    create_table(:playlists) do
      primary_key :id
      String :name, unique:true
      String :query
    end
    create_table(:playlist_songs) do
      foreign_key :playlist_id, :playlists
      foreign_key :song_id,     :songs
      primary_key [:playlist_id, :song_id]
    end
    create_table(:plays) do
      foreign_key :song_id,     :songs
      Time        :when
      primary_key [:song_id, :when]
    end
    create_table(:skips) do
      foreign_key :song_id,  :songs
      Time        :when
      String      :user_id
      primary_key [:song_id, :when]
    end
    create_table(:votes) do
      foreign_key :song_id,     :songs
      String      :user_id
      Integer     :vote
      primary_key [:song_id, :user_id]
    end
    create_table(:upcoming_songs) do
      foreign_key :playlist_id, :playlists
      foreign_key :song_id,     :songs
      Integer     :order
      primary_key [:playlist_id, :song_id]
    end
  end
end
