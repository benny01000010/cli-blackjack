#!/bin/bash

# Welcome to cli-blackjack!
# Fuel your blackjack addiction without leaving your terminal.
# Play against a computer dealer and see if you can beat the house!
# Full rules and how to play here: https://bicyclecards.com/how-to-play/blackjack


# Card suits and ranks (standard 52-card deck, no jokers) (relatively self explanatory)
suits=("♠" "♥" "♦" "♣")
ranks=("2" "3" "4" "5" "6" "7" "8" "9" "10" "J" "Q" "K" "A")
deck_index=0

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

# Display cards
show_hand() {
    local label="$1"
    shift
    local hand=("$@")
    echo -n "$label: "
    printf '%s ' "${hand[@]}"
    echo ""
}

# Deal


# Main game logic
play_game() {
    create_deck

    player_hand=()
    dealer_hand=()

    # Initial deal
    player_hand+=("${deck[$deck_index]}"); ((deck_index++))
    dealer_hand+=("${deck[$deck_index]}"); ((deck_index++))
    player_hand+=("${deck[$deck_index]}"); ((deck_index++))
    dealer_hand+=("${deck[$deck_index]}"); ((deck_index++))

    # Show initial hands
    show_hand "Your hand:" "${player_hand[@]}"
    echo "Your total: ($(calc_hand_value "${player_hand[@]}"))"
    echo ""
    echo "Dealer's hand: ${dealer_hand[0]}"
    echo ""

    # Player's turn
    while true; do
        player_total=$(calc_hand_value "${player_hand[@]}")

        if [[ $player_total -eq 21 ]]; then
            echo "Blackjack! You have 21! Winner!"
            return
        elif [[ $player_total -gt 21 ]]; then
            echo "Bust! You exceeded 21. You lose."
            return
        fi

    read -p "Hit or Stand? (h/s): " choice
    echo ""

    if [[ "$choice" =~ ^[Hh]$ ]]; then
        new_card="${deck[$deck_index]}"
        ((deck_index++))
        player_hand+=("$new_card")
        echo "You drew: $new_card"
        show_hand "Your hand:" "${player_hand[@]}"
        echo "Your total: ($(calc_hand_value "${player_hand[@]}"))"
        echo ""
    else
        break
    fi
done


player_total=$(calc_hand_value "${player_hand[@]}")
[[ $player_total -gt 21 ]] && return

# Dealer's turn
echo "Dealer reveals:"
show_hand "Dealer's hand:" "${dealer_hand[@]}"
dealer_total=$(calc_hand_value "${dealer_hand[@]}")
echo "Dealer's total: $dealer_total"
echo ""

while [[ $dealer_total -lt 17 ]]; do
    echo "Dealer hits..."
    sleep 0.5
     new_card="${deck[$deck_index]}"
    ((deck_index++))
    dealer_hand+=("$new_card")
    echo "Dealer drew: $new_card"
    show_hand "Dealer's hand:" "${dealer_hand[@]}"
    dealer_total=$(calc_hand_value "${dealer_hand[@]}")
    echo "Dealer's total: $dealer_total"
    echo ""
done

# Determine winner
if [[ $dealer_total -gt 21 ]]; then
    echo "Dealer busts! Winner!"
elif [[ $dealer_total -gt $player_total ]]; then
    echo "Dealer wins with $dealer_total against your $player_total. You lose."
elif [[ $dealer_total -lt $player_total ]]; then
    echo "You win with $player_total against dealer's $dealer_total! Congratulations!"
else
    echo "It's a tie at $player_total!"
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
while true; do
    play_game
    echo ""
    read -p "Play again? (y/n): " again
    if [[ ! "$again" =~ ^[Yy]$ ]]; then
        break
    fi
    echo ""
done

echo "Thanks for playing cli-blackjack! Goodbye!"
echo "@benny01000010 on Github"
