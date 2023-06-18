#!/bin/bash

# Variables globales
declare -A grid
declare -A visited
ADDRESS=0
PLAYER_NAME=0 
GAME_STATE=0
player_score=0
seed=0
timestamp=0
player_x=0
player_y=0
player_level=0
grid_width=0
grid_height=0
action=0

read_address() {
  file_path="Scarb.toml"
  address_line=$(grep "account_address" "$file_path")
  ADDRESS=$(echo "$address_line" | cut -d '"' -f 2)
}

fetch_game() {
    command_output=$(sozo component entity Game $ADDRESS)
    IFS=$'\n' read -d '' -ra game_info <<< "$command_output"
    
    PLAYER_NAME=$(echo "${game_info[0]#0x}" | xxd -r -p)  
    GAME_STATE=$((16#${game_info[1]#0x}))
    player_score=$((16#${game_info[2]#0x}))
    seed=$((16#${game_info[3]#0x}))
    timestamp=$((16#${game_info[4]#0x}))
    player_x=$((16#${game_info[5]#0x}))
    player_y=$((16#${game_info[6]#0x}))
    player_level=$((16#${game_info[7]#0x}))
    grid_width=$((16#${game_info[8]#0x}))
    grid_height=$((16#${game_info[9]#0x}))
    action=$((16#${game_info[10]#0x}))
}

fetch_tiles() {
    for ((i=0; i<$grid_height; i++)); do
        for ((j=0; j<$grid_width; j++)); do
          command_output=$(sozo component entity Tile $ADDRESS,$i,$j)
          IFS=$'\n' read -d '' -ra tile_info <<< "$command_output"

          explored=$((16#${tile_info[0]#0x}))
          clue=$((16#${tile_info[1]#0x}))
          x=$((16#${tile_info[2]#0x}))
          y=$((16#${tile_info[3]#0x}))

          if [[ $explored -eq 1 ]]; then
              visited["$i,$j"]=$clue
          fi
        done
    done
}

fetch_tile() {
    command_output=$(sozo component entity Tile $ADDRESS,$player_x,$player_y)
    IFS=$'\n' read -d '' -ra tile_info <<< "$command_output"
    echo $((16#${tile_info[0]#0x}))
}

execute_move_left() {
    sozo execute Move -c 0,0
    explored=$(fetch_tile)
    if [[ $explored -eq 0 ]]; then
        sozo execute Reveal
    fi
}

execute_move_up() {
    sozo execute Move -c 0,2
    explored=$(fetch_tile)
    if [[ $explored -eq 0 ]]; then
        sozo execute Reveal
    fi
}

execute_move_right() {
    sozo execute Move -c 0,4
    explored=$(fetch_tile)
    if [[ $explored -eq 0 ]]; then
        sozo execute Reveal
    fi
}

execute_move_down() {
    sozo execute Move -c 0,6
    explored=$(fetch_tile)
    if [[ $explored -eq 0 ]]; then
        sozo execute Reveal
    fi
}

# Fonction pour effacer l'écran
clear_screen() {
    printf "\033c"
}

# Fonction pour afficher la grille
display_grid() {
    clear_screen
    count=$((grid_width * 4 - 1))

    # Top edge
    printf "\n╭"
    for ((i=0; i<$count; i++)); do
      printf "%s" "─"
    done
    printf "╮\n"

    for ((i=0; i<$grid_height; i++)); do
        for ((j=0; j<$grid_width; j++)); do
            if [[ "$i" -eq "$player_y" && "$j" -eq "$player_x" ]]; then
                printf "│┊${visited["$i,$j"]}┊"
            elif [[ "${visited["$i,$j"]}" =~ ^[0-9]+$ ]]; then
                printf "│ ${visited["$i,$j"]} "
            else
                printf "│   "
            fi
        done

        # Separator
        if [[ $i -ne $((grid_height - 1)) ]]; then
          printf "│\n├"
          for ((k=0; k<$count; k++)); do
            printf "%s" "─"
          done
          printf "┤\n"
        else
          printf "│\n"
        fi

    done

    # Bottom edge
    printf "╰"
    for ((i=0; i<$count; i++)); do
      printf "%s" "─"
    done
    printf "╯\n"
}

# Function to display the menu
display_menu() {
    printf "Use the following keys:\n"
    printf "    \e[32m↑\e[0m : Move up\n"
    printf "    \e[32m↓\e[0m : Move down\n"
    printf "    \e[32m←\e[0m : Move left\n"
    printf "    \e[32m→\e[0m : Move right\n"
    printf "    \e[32mQ\e[0m : Quit the game\n"
    printf "\n"
}

# Function to move the player
move_player() {
    while true; do
        fetch_game
        fetch_tiles
        display_grid
        display_menu

        read -rsn1 key  # Read a single key without displaying it
        case "$key" in
            "q")  # Quit the game
                clear_screen
                exit 0
                ;;
            $'\x1b')  # Arrow key detected
                read -rsn2 key  # Read the next two keys (arrow code)
                case "$key" in
                    "[A")  # Up arrow
                        if [[ $player_y -gt 0 ]]; then
                            execute_move_up
                        fi
                        ;;
                    "[B")  # Down arrow
                        if [[ $player_y -lt $((grid_width - 1)) ]]; then
                            execute_move_down
                        fi
                        ;;
                    "[D")  # Left arrow
                        if [[ $player_x -gt 0 ]]; then
                            execute_move_left
                        fi
                        ;;
                    "[C")  # Right arrow
                        if [[ $player_x -lt $((grid_height - 1)) ]]; then
                            execute_move_right
                        fi
                        ;;
                esac
                ;;
        esac
    done
}

# Fonction principale
main() {
    read_address
    move_player
}

# Appel de la fonction principale
main
