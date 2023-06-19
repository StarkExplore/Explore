#!/bin/bash

# Variables globales
declare -A visited
declare -A dangers
ADDRESS=0
PLAYER_NAME=0 
GAME_STATE=0
# PLAYER_SCORE=0
# seed=0
# timestamp=0
PLAYER_X=0
PLAYER_Y=0
PLAYER_LEVEL=0
GRID_SIZE=0
ACTION=0

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
    PLAYER_SCORE=$((16#${game_info[2]#0x}))
    # seed=$((16#${game_info[3]#0x}))
    # timestamp=$((16#${game_info[4]#0x}))
    PLAYER_X=$((16#${game_info[5]#0x}))
    PLAYER_Y=$((16#${game_info[6]#0x}))
    PLAYER_LEVEL=$((16#${game_info[7]#0x}))
    GRID_SIZE=$((16#${game_info[8]#0x}))
    # action=$((16#${game_info[9]#0x}))
}

fetch_tiles() {
    visited=()
    for ((col=0; col<$GRID_SIZE; col++)); do
        for ((row=0; row<$GRID_SIZE; row++)); do
          command_output=$(sozo component entity Tile $ADDRESS,$col,$row)
          IFS=$'\n' read -d '' -ra tile_info <<< "$command_output"

          explored=$((16#${tile_info[0]#0x}))
          danger=$((16#${tile_info[1]#0x}))
          clue=$((16#${tile_info[2]#0x}))
          x=$((16#${tile_info[3]#0x}))
          y=$((16#${tile_info[4]#0x}))

          if [[ $explored -eq 1 ]]; then
              visited["$col,$row"]=$clue
              dangers["$col,$row"]=$danger
          fi
        done
    done
}

fetch_tile() {
    fetch_game
    command_output=$(sozo component entity Tile $ADDRESS,$PLAYER_X,$PLAYER_Y)
    IFS=$'\n' read -d '' -ra tile_info <<< "$command_output"
    echo $((16#${tile_info[0]#0x}))
}

execute_move() {
    sozo execute Move -c $1,$2
    explored=$(fetch_tile)
    if [[ $explored -eq 0 ]]; then
        sozo execute Reveal
    fi
}

execute_create() {
    sozo execute Create -c 0x42616c3768617a6172
}

clear_screen() {
    printf "\033c"
}

display_header() {
    clear_screen
    printf "Name : ${PLAYER_NAME}\n"
    printf "Level: ${PLAYER_LEVEL}\n"
    printf "Score: ${PLAYER_SCORE}\n"
}

display_grid() {
    count=$((GRID_SIZE * 4 - 1))

    # Top edge
    printf "\n╭"
    for ((col=0; col<$count; col++)); do
      printf "%s" "─"
    done
    printf "╮\n"

    for ((row=0; row<$GRID_SIZE; row++)); do
        for ((col=0; col<$GRID_SIZE; col++)); do
            if [[ "$col" -eq "$PLAYER_X" && "$row" -eq "$PLAYER_Y" ]]; then
                if [[ "$GAME_STATE" -eq 0 ]]; then
                    printf "│<💀"
                elif [[ "${dangers["$col,$row"]}" -eq 1 ]]; then
                    printf "│<\e[31m${visited["$col,$row"]}\e[0m>"
                else
                    printf "│<\e[32m${visited["$col,$row"]}\e[0m>"
                fi
            elif [[ "${visited["$col,$row"]}" =~ ^[0-9]+$ ]]; then
                if [[ "${dangers["$col,$row"]}" -eq 1 ]]; then
                    printf "│ \e[31m${visited["$col,$row"]}\e[0m "
                else
                    printf "│ \e[32m${visited["$col,$row"]}\e[0m "
                fi
            else
                printf "│   "
            fi
        done

        # Separator
        if [[ $row -ne $((GRID_SIZE - 1)) ]]; then
          printf "│\n├"
          for ((col=0; col<$count; col++)); do
            printf "%s" "─"
          done
          printf "┤\n"
        else
          printf "│\n"
        fi

    done

    # Bottom edge
    printf "╰"
    for ((col=0; col<$count; col++)); do
      printf "%s" "─"
    done
    printf "╯\n"
}

display_menu() {
    printf "Use the following keys:\n"
    printf "    \e[32m1\e[0m : Move down left\n"
    printf "    \e[32m2\e[0m : Move down\n"
    printf "    \e[32m3\e[0m : Move down right\n"
    printf "    \e[32m4\e[0m : Move left\n"
    printf "    \e[32m6\e[0m : Move right\n"
    printf "    \e[32m7\e[0m : Move up left\n"
    printf "    \e[32m8\e[0m : Move up\n"
    printf "    \e[32m9\e[0m : Move up right\n"
    if [[ "$ACTION" -eq "0" ]]; then
        printf "   <\e[32mS\e[0m>: Switch to safe mode\n"
        printf "    \e[32mU\e[0m : Switch to unsafe mode\n"
    else
        printf "    \e[32mS\e[0m : Switch to safe mode\n"
        printf "   <\e[32mU\e[0m>: Switch to unsafe mode\n"
    fi
    printf "    \e[32mR\e[0m  : Reset the game\n"
    printf "    \e[32mQ\e[0m  : Quit the game\n"
    printf "\n"
}

move_player() {
    while true; do
        fetch_game
        fetch_tiles
        display_header
        display_grid
        display_menu

        read -rsn1 key  # Read a single key without displaying it
        case "$key" in
            "q")  # Quit the game
                clear_screen
                exit 0
                ;;
            "s")  # Switch to safe mode
                ACTION=0
                ;;
            "u")  # Switch to unsafe mode
                ACTION=1
                ;;
            "r")  # Switch to unsafe mode
                execute_create
                ;;

            "1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9")  # Number keys
                case "$key" in
                    "1")  # Move down and left
                        if [[ $PLAYER_Y -lt $((GRID_SIZE - 1)) && $PLAYER_X -gt 0 ]]; then
                            execute_move $ACTION 7
                        fi
                        ;;
                    "2")  # Move down
                        if [[ $PLAYER_Y -lt $((GRID_SIZE - 1)) ]]; then
                            execute_move $ACTION 6
                        fi
                        ;;
                    "3")  # Move down and right
                        if [[ $PLAYER_Y -lt $((GRID_SIZE - 1)) && $PLAYER_X -lt $((GRID_SIZE - 1)) ]]; then
                            execute_move $ACTION 5
                        fi
                        ;;
                    "4")  # Move left
                        if [[ $PLAYER_X -gt 0 ]]; then
                            execute_move $ACTION 0
                        fi
                        ;;
                    "6")  # Move right
                        if [[ $PLAYER_X -lt $((GRID_SIZE - 1)) ]]; then
                            execute_move $ACTION 4
                        fi
                        ;;
                    "7")  # Move up and left
                        if [[ $PLAYER_Y -gt 0 && $PLAYER_X -gt 0 ]]; then
                            execute_move $ACTION 1
                        fi
                        ;;
                    "8")  # Move up
                        if [[ $PLAYER_Y -gt 0 ]]; then
                            execute_move $ACTION 2
                        fi
                        ;;
                    "9")  # Move up and right
                        if [[ $PLAYER_Y -gt 0 && $PLAYER_X -lt $((GRID_SIZE - 1)) ]]; then
                            execute_move $ACTION 3
                        fi
                        ;;
                esac
                ;;
        esac
    done
}

main() {
    read_address
    move_player
}

main
