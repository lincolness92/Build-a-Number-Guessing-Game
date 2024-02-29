#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))


MAIN () {
  echo "Enter your username:"
  read USERNAME
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  
  if [[ -z "$USER_ID" ]]
  then
    #echo required message
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    #insert username in db
    INSERT_NAME_DB=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
    #get user id
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
    #start new game
    GAME $USER_ID $PSQL
  else
    #query games for games played and minimum number of guesses
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID")
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."

    GAME $USER_ID $PSQL
  fi
}

GAME () {
  i=0
  echo "Guess the secret number between 1 and 1000:"
  read GUESS
  
  while [[ $GUESS -ne $SECRET_NUMBER ]]
  do
    if [[ ! $GUESS =~ ^-?[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
      read GUESS
    elif [[ "$GUESS" -lt "$SECRET_NUMBER" ]]
    then
      echo "It's higher than that, guess again:"
      let i++
      read GUESS
    else
      echo "It's lower than that, guess again:"
      let i++
      read GUESS
    fi
  done
  let i++
  INSERT_GAME=$($PSQL "INSERT INTO games(number_of_guesses, user_id, won, secret_number) VALUES($i, $USER_ID, true, $SECRET_NUMBER)")
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id=$USER_ID AND won = TRUE")
  UPDATE_BG_GP=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE user_id = $USER_ID")
  echo "You guessed it in $i tries. The secret number was $SECRET_NUMBER. Nice job!"
  exit 0
}

MAIN $PSQL