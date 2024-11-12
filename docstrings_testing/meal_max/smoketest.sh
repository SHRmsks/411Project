#!/bin/bash

# Define the base URL for the Flask API
BASE_URL="http://localhost:5000/api"

# Flag to control whether to echo JSON output
ECHO_JSON=false

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    --echo-json) ECHO_JSON=true ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done


###############################################
#
# Health checks
#
###############################################

# Function to check the health of the service
check_health() {
  echo "Checking health status..."
  curl -s -X GET "$BASE_URL/health" | grep -q '"status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Service is healthy."
  else
    echo "Health check failed."
    exit 1
  fi
}

# Function to check the database connection
check_db() {
  echo "Checking database connection..."
  curl -s -X GET "$BASE_URL/db-check" | grep -q '"database_status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Database connection is healthy."
  else
    echo "Database check failed."
    exit 1
  fi
}


##########################################################
#
# Song Management
#
##########################################################

clear_meals() {
  echo "Clearing the meal list..."
  curl -s -X DELETE "$BASE_URL/clear-meals" | grep -q '"status": "success"'
}

create_meal() {
  meal=$1
  cuisine=$2
  price=$3
  difficulty=$4

  echo "Adding meal ($meal, $cuisine, $price, $difficulty) to the meal list..."
  curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}" | grep -q '"status": "success"'

  if [ $? -eq 0 ]; then
    echo "meal added successfully."
  else
    echo "Failed to add meal."
    exit 1
  fi
}

delete_meal() {
  meal_id=$1

  echo "Deleting meal by ID ($meal_id)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal deleted successfully by ID ($meal_id)."
  else
    echo "Failed to delete meal by ID ($meal_id)."
    exit 1
  fi
}

get_leaderboard() {
  sort_by=$1

  echo "Getting all meals in the leaderboard..."
  response=$(curl -s -X GET "$BASE_URL/leaderboard?sort=$sort_by")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meals JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meals."
    exit 1
  fi
}

get_meal_by_id() {
  meal_id=$1

  echo "Getting meal by ID ($meal_id)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-id/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by ID ($meal_id)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (ID $meal_id):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by ID ($meal_id)."
    exit 1
  fi
}



############################################################
#
# Playlist Management
#
############################################################

prep_combatant() {
  meal=$1

  echo "Prepping Meal for battle: $meal ..."
  response=$(curl -s -X POST "$BASE_URL/prep-combatant/$meal" \
    -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\"}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal prepared successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to prepare Meal."
    exit 1
  fi
}

remove_song_from_playlist() {
  meal=$1
  cuisine=$2
  price=$3

  echo "Removing song from playlist: $meal - $cuisine ($price)..."
  response=$(curl -s -X DELETE "$BASE_URL/remove-song-from-playlist" \
    -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song removed from playlist successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Song JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to remove song from playlist."
    exit 1
  fi
}

remove_song_by_track_number() {
  track_number=$1

  echo "Removing song by track number: $track_number..."
  response=$(curl -s -X DELETE "$BASE_URL/remove-song-from-playlist-by-track-number/$track_number")

  if echo "$response" | grep -q '"status":'; then
    echo "Song removed from playlist by track number ($track_number) successfully."
  else
    echo "Failed to remove song from playlist by track number."
    exit 1
  fi
}

clear_combatants() {
  echo "Clearing combatants..."
  response=$(curl -s -X POST "$BASE_URL/clear-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatants cleared successfully."
  else
    echo "Failed to clear combatants."
    exit 1
  fi
}


############################################################
#
# Play Playlist
#
############################################################

play_current_song() {
  echo "Playing current song..."
  response=$(curl -s -X POST "$BASE_URL/play-current-song")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Current song is now playing."
  else
    echo "Failed to play current song."
    exit 1
  fi
}

rewind_playlist() {
  echo "Rewinding playlist..."
  response=$(curl -s -X POST "$BASE_URL/rewind-playlist")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Playlist rewound successfully."
  else
    echo "Failed to rewind playlist."
    exit 1
  fi
}

get_all_songs_from_playlist() {
  echo "Retrieving all songs from playlist..."
  response=$(curl -s -X GET "$BASE_URL/get-all-songs-from-playlist")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "All songs retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Songs JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to retrieve all songs from playlist."
    exit 1
  fi
}

get_song_from_playlist_by_track_number() {
  track_number=$1
  echo "Retrieving song by track number ($track_number)..."
  response=$(curl -s -X GET "$BASE_URL/get-song-from-playlist-by-track-number/$track_number")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song retrieved successfully by track number."
    if [ "$ECHO_JSON" = true ]; then
      echo "Song JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to retrieve song by track number."
    exit 1
  fi
}

get_current_song() {
  echo "Retrieving current song..."
  response=$(curl -s -X GET "$BASE_URL/get-current-song")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Current song retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Current Song JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to retrieve current song."
    exit 1
  fi
}

get_playlist_length_duration() {
  echo "Retrieving playlist length and duration..."
  response=$(curl -s -X GET "$BASE_URL/get-playlist-length-duration")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Playlist length and duration retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Playlist Info JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to retrieve playlist length and duration."
    exit 1
  fi
}

go_to_track_number() {
  track_number=$1
  echo "Going to track number ($track_number)..."
  response=$(curl -s -X POST "$BASE_URL/go-to-track-number/$track_number")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Moved to track number ($track_number) successfully."
  else
    echo "Failed to move to track number ($track_number)."
    exit 1
  fi
}

play_entire_playlist() {
  echo "Playing entire playlist..."
  curl -s -X POST "$BASE_URL/play-entire-playlist" | grep -q '"status": "success"'
  if [ $? -eq 0 ]; then
    echo "Entire playlist played successfully."
  else
    echo "Failed to play entire playlist."
    exit 1
  fi
}

# Function to play the rest of the playlist
play_rest_of_playlist() {
  echo "Playing rest of the playlist..."
  curl -s -X POST "$BASE_URL/play-rest-of-playlist" | grep -q '"status": "success"'
  if [ $? -eq 0 ]; then
    echo "Rest of playlist played successfully."
  else
    echo "Failed to play rest of playlist."
    exit 1
  fi
}

############################################################
#
# Arrange Playlist
#
############################################################

move_song_to_beginning() {
  meal=$1
  cuisine=$2
  price=$3

  echo "Moving song ($meal - $cuisine, $price) to the beginning of the playlist..."
  response=$(curl -s -X POST "$BASE_URL/move-song-to-beginning" \
    -H "Content-Type: application/json" \
    -d "{\"meal\": \"$meal\", \"cuisine\": \"$cuisine\", \"price\": $price}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song moved to the beginning successfully."
  else
    echo "Failed to move song to the beginning."
    exit 1
  fi
}

move_song_to_end() {
  meal=$1
  cuisine=$2
  price=$3

  echo "Moving song ($meal - $cuisine, $price) to the end of the playlist..."
  response=$(curl -s -X POST "$BASE_URL/move-song-to-end" \
    -H "Content-Type: application/json" \
    -d "{\"meal\": \"$meal\", \"cuisine\": \"$cuisine\", \"price\": $price}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song moved to the end successfully."
  else
    echo "Failed to move song to the end."
    exit 1
  fi
}

move_song_to_track_number() {
  meal=$1
  cuisine=$2
  price=$3
  track_number=$4

  echo "Moving song ($meal - $cuisine, $price) to track number ($track_number)..."
  response=$(curl -s -X POST "$BASE_URL/move-song-to-track-number" \
    -H "Content-Type: application/json" \
    -d "{\"meal\": \"$meal\", \"cuisine\": \"$cuisine\", \"price\": $price, \"track_number\": $track_number}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song moved to track number ($track_number) successfully."
  else
    echo "Failed to move song to track number ($track_number)."
    exit 1
  fi
}

swap_songs_in_playlist() {
  track_number1=$1
  track_number2=$2

  echo "Swapping songs at track numbers ($track_number1) and ($track_number2)..."
  response=$(curl -s -X POST "$BASE_URL/swap-songs-in-playlist" \
    -H "Content-Type: application/json" \
    -d "{\"track_number_1\": $track_number1, \"track_number_2\": $track_number2}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Songs swapped successfully between track numbers ($track_number1) and ($track_number2)."
  else
    echo "Failed to swap songs."
    exit 1
  fi
}

######################################################
#
# Leaderboard
#
######################################################

# Function to get the song leaderboard sorted by play count
get_song_leaderboard() {
  echo "Getting song leaderboard sorted by play count..."
  response=$(curl -s -X GET "$BASE_URL/song-leaderboard?sort=play_count")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON (sorted by play count):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get song leaderboard."
    exit 1
  fi
}


# Health checks
check_health
check_db

clear_meals
# Create meals
create_meal "Chicken Parm" "Italian" 10.0 "HIGH"
create_meal "Pizza" "Italian" 12.0 "MED"
create_meal "Tacos" "Mexican" 8.0 "MED"
create_meal "Sandwich" "American" 8.4 "LOW"
create_meal "Steak" "Japanese" 43.5 "HIGH"

delete_meal 1
get_leaderboard 'wins'

get_meal_by_id 2
get_meal_by_id 3
get_meal_by_id 4

clear_combatants
prep_combatant "Chicken Parm"
prep_combatant "Pizza" 



remove_song_from_playlist "The Beatles" "Let It Be" 1970
remove_song_by_track_number 2

get_all_songs_from_playlist

add_song_to_playlist "Queen" "Bohemian Rhapsody" 1975
add_song_to_playlist "The Beatles" "Let It Be" 1970

move_song_to_beginning "The Beatles" "Let It Be" 1970
move_song_to_end "Queen" "Bohemian Rhapsody" 1975
move_song_to_track_number "Led Zeppelin" "Stairway to Heaven" 1971 2
swap_songs_in_playlist 1 2

get_all_songs_from_playlist
get_song_from_playlist_by_track_number 1

get_playlist_length_duration

play_current_song
rewind_playlist

play_entire_playlist
play_current_song
play_rest_of_playlist

get_song_leaderboard

echo "All tests passed successfully!"
