#!/bin/bash

# Welcome to cli-blackjack!
# Fuel your blackjack addiction without leaving your terminal.
# Play against a computer dealer and see if you can beat the house!
# Full rules and how to play here: https://bicyclecards.com/how-to-play/blackjack

# Set this to FALSE if you DO NOT want your screen cleared!!!
clear_screen=true

suits=("♠" "♥" "♦" "♣")
ranks=("2" "3" "4" "5" "6" "7" "8" "9" "10" "J" "Q" "K" "A")

deck_index=0

red='\033[0;31m'
blue='\033[0;34m'
green='\033[0;32m'
yellow='\033[0;33m'
nc='\033[0m'

wins=0
losses=0
ties=0

# Generates and shuffles a new deck of cards.
create_deck() {
    deck=()
    for suit in "${suits[@]}"; do
        for rank in "${ranks[@]}"; do
            deck+=("$rank$suit")
        done
    done
    deck=($(printf '%s\n' "${deck[@]}" | shuf))
    deck_index=0  # ← ADD THIS
}

# Calculates value of a hand of cards.
calc_hand_value() {
    local hand=("$@")
    local total=0
    local aces=0

    for card in "${hand[@]}"; do
        rank="${card%?}"

        if [[ "$rank" =~ ^(J|Q|K)$ ]]; then
            ((total += 10))
        elif [[ "$rank" == "A" ]]; then
            ((aces++))
            ((total +=11))
        else
            ((total+=rank))
        fi
    done

    while [[ $total -gt 21 && $aces -gt 0 ]]; do
        ((total -= 10))
        ((aces--))
    done

    echo $total
}

# Draws a single card as ASCII art.
draw_single_card() {
    local card="$1"
    local rank="${card%?}"
    local suit_raw="${card: -1}"
    
    if [[ "$suit_raw" == "♥" || "$suit_raw" == "♦" ]]; then
        local suit="${red}$suit_raw${nc}"
    else
        local suit="$suit_raw"
    fi

    if [[ "$rank" == "10" ]]; then
        local top_rank="10"
        local bot_rank="10"
    else
        local top_rank="$rank "
        local bot_rank=" $rank"
    fi

    printf "┌─────────┐\n"
    printf "│${top_rank}       │\n"
    printf "│         │\n"
    printf "│    $suit    │\n"
    printf "│         │\n"
    printf "│       ${bot_rank}│\n"
    printf "└─────────┘\n"
}

draw_hidden_card() {
    printf "┌─────────┐\n"
    printf "│░░░░░░░░░│\n"
    printf "│░░░░░░░░░│\n"
    printf "│░░░░░░░░░│\n"
    printf "│░░░░░░░░░│\n"
    printf "│░░░░░░░░░│\n"
    printf "└─────────┘\n"
}

# Draws a hand of cards as ASCII art.
draw_hand() {
    local hide_second=false
    if [[ "$1" == "--hide-second" ]]; then
        hide_second=true
        shift
    fi

    local cards=("$@")
    local card_lines=()

    for i in "${!cards[@]}"; do
        if [[ $hide_second == true && $i -eq 1 ]]; then
            card_lines[$i]=$(draw_hidden_card)
        else
            card_lines[$i]=$(draw_single_card "${cards[$i]}")
        fi
    done

    for line_num in {0..6}; do
        for i in "${!cards[@]}"; do
            local card_line=$(echo "${card_lines[$i]}" | sed -n "$((line_num + 1))p")
            echo -n "$card_line "
        done
        echo ""
    done
}

# Main game logic
play_game() {

    if [[ $deck_index -gt 40 ]]; then
        echo "Shuffling new deck..."
        sleep 1
        create_deck
    fi
    
    create_deck

    player_hand=()
    dealer_hand=()

    # Initial deal
    player_hand+=("${deck[$deck_index]}"); ((deck_index++))
    dealer_hand+=("${deck[$deck_index]}"); ((deck_index++))
    player_hand+=("${deck[$deck_index]}"); ((deck_index++))
    dealer_hand+=("${deck[$deck_index]}"); ((deck_index++))

    echo ""
    echo "Your hand:"
    draw_hand "${player_hand[@]}"
    echo "Total: $(calc_hand_value "${player_hand[@]}")"
    echo ""

    echo "Dealer's hand:"
    draw_hand --hide-second "${dealer_hand[@]}"
    echo ""

    # Player's turn
    while true; do
        player_total=$(calc_hand_value "${player_hand[@]}")

        if [[ $player_total -eq 21 ]]; then
            echo -e "${green}Blackjack! You have 21! Winner!${nc}"
            ((wins++))
            return
        elif [[ $player_total -gt 21 ]]; then
            echo -e "${red}Bust! You exceeded 21. You lose.${nc}"
            ((losses++))
            return
        fi

    read -p "Hit or Stand? (h/s/?): " choice
    echo ""

    # Help option
    if [[ "$choice" == "?" ]]; then
        echo "----------------------------------"
        echo "          BLACKJACK HELP          "
        echo "----------------------------------"
        echo "Your goal is to get as close to 21"
        echo "as possible without going over."
        echo ""
        echo "Card Values:"
        echo "Number Cards (2-10): Face value"
        echo "Face Cards (J, Q, K): 10 points"
        echo "Aces: 11 points (or 1 point if 11 would bust)"
        echo ""
        echo "Commands:"
        echo "h - Hit (draw another card)"
        echo "s - Stand (end your turn)"
        echo "? - Show this help message"
        echo ""
        echo "Tips:"
        echo "If your initial two cards total 21,"
        echo "you have a Blackjack and win instantly!"
        echo ""
        echo "The dealer will hit until their total is at least 17."
        echo ""
        echo "If you still need help, visit:"
        echo "https://bicyclecards.com/how-to-play/blackjack"
        echo ""
        echo "Good luck!"
        echo ""
        continue

    elif [[ "$choice" =~ ^[Hh]$ ]]; then
        new_card="${deck[$deck_index]}"
        ((deck_index++))
        player_hand+=("$new_card")
        echo "Your hand:"
        draw_hand "${player_hand[@]}"
        echo "Total: $(calc_hand_value "${player_hand[@]}")"
        echo ""
    elif [[ "$choice" =~ ^[Ss]$ ]]; then
        break
    else
        echo -e "${red}Invalid choice. Please enter 'h' to Hit, 's' to Stand, or '?' for help.${nc}"
    fi
done


player_total=$(calc_hand_value "${player_hand[@]}")
[[ $player_total -gt 21 ]] && return

# Dealer's turn
echo "Dealer's turn..."
sleep 0.75
echo "Dealer reveals:"
draw_hand "${dealer_hand[@]}"
dealer_total=$(calc_hand_value "${dealer_hand[@]}")
echo "Dealer's total: $dealer_total"

while [[ $dealer_total -lt 17 ]]; do
    echo "Dealer hits..."
    sleep 1
   new_card="${deck[$deck_index]}"
    ((deck_index++))
    dealer_hand+=("$new_card")
   
    draw_hand "${dealer_hand[@]}"
    dealer_total=$(calc_hand_value "${dealer_hand[@]}")
    echo "Dealer's total: $dealer_total"
    echo ""
done

# Determine winner
if [[ $dealer_total -gt 21 ]]; then
    echo -e "${green}Dealer busts! Winner!${nc}"
    ((wins++))
elif [[ $dealer_total -gt $player_total ]]; then
    echo -e "${red}Dealer wins with $dealer_total against your $player_total. You lose.${nc}"
    ((losses++))
elif [[ $dealer_total -lt $player_total ]]; then
    echo -e "${green}You win with $player_total against the dealer's $dealer_total! Congratulations!${nc}"
    ((wins++))
else
    echo -e "${yellow}It's a tie at $player_total!${nc}"
    ((ties++))
fi

}

echo "Welcome to cli-blackjack!"
echo "Fuel your gambling addiction without leaving your terminal."

cat <<'EOF'
    ____  _                             ___  _  ___   ___   ___   ___  _  ___  
   / __ \| |__   ___ _ __  _ __  _   _ / _ \/ |/ _ \ / _ \ / _ \ / _ \/ |/ _ \ 
  / / _` | '_ \ / _ \ '_ \| '_ \| | | | | | | | | | | | | | | | | | | | | | | |
 | | (_| | |_) |  __/ | | | | | | |_| | |_| | | |_| | |_| | |_| | |_| | | |_| |
  \ \__,_|_.__/ \___|_| |_|_| |_|\__, |\___/|_|\___/ \___/ \___/ \___/|_|\___/ 
   \____/ __     __ _(_) |_| |__ |___/_| |__                                   
  / _ \| '_ \   / _` | | __| '_ \| | | | '_ \                                  
 | (_) | | | | | (_| | | |_| | | | |_| | |_) |                                 
  \___/|_| |_|  \__, |_|\__|_| |_|\__,_|_.__/                                  
                |___/                                                          
EOF

# Gambling addiction
first_game=true
while true; do
    if [[ $first_game == true ]]; then
        first_game=false
    else
        if [[ $clear_screen == true ]]; then
            clear
        fi
    fi

    play_game
    echo ""
    read -p "Play again? (y/n): " again
    if [[ ! "$again" =~ ^[Yy]$ ]]; then
        break
    fi
    echo ""
done

echo ""
echo "-----------------------------"
echo "         GAME STATS          "
echo "-----------------------------"
echo "Total Games Played: $((wins + losses + ties))"
echo -e "${green}Wins:   ${wins}${nc}"
echo -e "${red}Losses: ${losses}${nc}"
echo -e "${yellow}Ties:   ${ties}${nc}"
total_games=$((wins + losses + ties))
if [[ $total_games -gt 0 ]]; then
    win_pct=$((wins * 100 / total_games))
    echo "% of Games Won: ${win_pct}%"
fi
echo ""

sleep 0.5
echo -e "${green}Thanks for playing cli-blackjack! Goodbye!${nc}"
echo -e "${blue}@benny01000010 on Github${nc}"