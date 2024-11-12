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
  id=$0
  meal=$1
  cuisine=$2
  price=$3
  difficulty=$4

  echo "Adding meal ($id, $meal, $cuisine, $price, $difficulty) to the meal list..."
  curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"id\":\"$id\",\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}" | grep -q '"status": "success"'

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
# Combatant System Management
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

remove_meal_from_list() {
  id= $0
  meal=$1
  cuisine=$2
  price=$3

  echo "Removing song from playlist: $meal - $cuisine ($price)..."
  response=$(curl -s -X DELETE "$BASE_URL/remove-meal-from-list" \
    -H "Content-Type: application/json" \
    -d "{\"id\":\"$id\",\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal has been removed from list successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to remove meal from meal list."
    exit 1
  fi
}

remove_meal_by_track_number() {
  track_number=$1

  echo "Removing song by track number: $track_number..."
  response=$(curl -s -X DELETE "$BASE_URL/remove-meal-from-list-by-track-number/$track_number")

  if echo "$response" | grep -q '"status":'; then
    echo "Song removed from meal list by track number ($track_number) successfully."
  else
    echo "Failed to remove meal from meal list by track number."
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


######################################################
#
# Leaderboard
#
######################################################

# Function to get the song leaderboard sorted by play count
get_combat_leaderboard() {
  echo "Getting combatant leaderboard sorted by play count..."
  response=$(curl -s -X GET "$BASE_URL/song-combat?sort=score")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "combatant leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON (sorted by play count):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get combatant leaderboard."
    exit 1
  fi
}sm


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
