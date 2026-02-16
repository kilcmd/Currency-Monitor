#!/bin/bash
# ═══════════════════════════════════════════════════════════
# 💱 Currency Monitor - tmux Edition (v5)
# Bloomberg-style table grid - 9 currencies vs base
# Stacked layout: country name on top, rate on bottom
# Fixed-width cells with clean vertical + horizontal dividers
# ═══════════════════════════════════════════════════════════
# Data source: open.er-api.com
# Free, no API key needed, 150+ currencies supported
# ═══════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════
# 💵 BASE CURRENCY - EASY TO CHANGE!
# ═══════════════════════════════════════════════════════════

BASE_CURRENCY="USD"     # Change to switch base currency
BASE_FLAG="🇺🇸"         # Change flag to match base currency

# ═══════════════════════════════════════════════════════════
# 🌍 TARGET CURRENCIES - 3x3 GRID (9 total)
# ═══════════════════════════════════════════════════════════
# Common codes:
#   DOP = Dominican Peso        HNL = Honduran Lempira
#   JPY = Japanese Yen          GBP = British Pound
#   EUR = Euro                  COP = Colombian Peso
#   BRL = Brazilian Real        CAD = Canadian Dollar
#   MXN = Mexican Peso          CNY = Chinese Yuan

# ── ROW 1 ──────────────────────────────────────────────────
CURRENCY_1="DOP"  ;  FLAG_1="🇩🇴"  ;  NAME_1="Dominican Peso"
CURRENCY_2="HNL"  ;  FLAG_2="🇭🇳"  ;  NAME_2="Honduran Lempira"
CURRENCY_3="JPY"  ;  FLAG_3="🇯🇵"  ;  NAME_3="Japanese Yen"

# ── ROW 2 ──────────────────────────────────────────────────
CURRENCY_4="GBP"  ;  FLAG_4="🇬🇧"  ;  NAME_4="British Pound"
CURRENCY_5="EUR"  ;  FLAG_5="🇩🇪"  ;  NAME_5="Euro"
CURRENCY_6="COP"  ;  FLAG_6="🇨🇴"  ;  NAME_6="Colombian Peso"

# ── ROW 3 ──────────────────────────────────────────────────
CURRENCY_7="BRL"  ;  FLAG_7="🇧🇷"  ;  NAME_7="Brazilian Real"
CURRENCY_8="CAD"  ;  FLAG_8="🇨🇦"  ;  NAME_8="Canadian Dollar"
CURRENCY_9="MXN"  ;  FLAG_9="🇲🇽"  ;  NAME_9="Mexican Peso"

# ═══════════════════════════════════════════════════════════
# ⏰ REFRESH RATE
# ═══════════════════════════════════════════════════════════
#UPDATE_INTERVAL=3600    # 1 hour  (recommended)
#UPDATE_INTERVAL=21600   # 6 hours
#UPDATE_INTERVAL=43200   # 12 hours
#UPDATE_INTERVAL=86400   # 24 hours

UPDATE_INTERVAL=3600

# ═══════════════════════════════════════════════════════════
# ⚙️  CACHE SETTINGS
# ═══════════════════════════════════════════════════════════

CACHE_FILE="/tmp/currency_cache_${BASE_CURRENCY}_$USER.txt"
CACHE_PREV_FILE="/tmp/currency_cache_${BASE_CURRENCY}_prev_$USER.txt"
CACHE_MAX_AGE=300

# ═══════════════════════════════════════════════════════════
# 🎨 COLORS
# Purple = title/branding
# Orange = Bloomberg-style borders and headers
# ═══════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[38;5;208m'
BORANGE='\033[1;38;5;208m'
PURPLE='\033[0;35m'
BPURPLE='\033[1;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════
# 🔧 FETCH FUNCTION
# ═══════════════════════════════════════════════════════════

get_rates() {
    local current_time=$(date +%s)

    if [ -f "$CACHE_FILE" ]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
        local cache_age=$((current_time - cache_time))
        if [ $cache_age -lt $CACHE_MAX_AGE ]; then
            cat "$CACHE_FILE"
            return 0
        fi
    fi

    local url="https://open.er-api.com/v6/latest/$BASE_CURRENCY"
    local response=$(curl -s --max-time 10 "$url" 2>/dev/null)

    if [ -z "$response" ]; then echo "ERROR: Cannot reach exchange rate API"; return 1; fi
    if echo "$response" | grep -q '"error"'; then echo "ERROR: API returned an error"; return 1; fi

    local r1=$(echo "$response" | grep -o "\"$CURRENCY_1\":[0-9.]*" | cut -d':' -f2)
    local r2=$(echo "$response" | grep -o "\"$CURRENCY_2\":[0-9.]*" | cut -d':' -f2)
    local r3=$(echo "$response" | grep -o "\"$CURRENCY_3\":[0-9.]*" | cut -d':' -f2)
    local r4=$(echo "$response" | grep -o "\"$CURRENCY_4\":[0-9.]*" | cut -d':' -f2)
    local r5=$(echo "$response" | grep -o "\"$CURRENCY_5\":[0-9.]*" | cut -d':' -f2)
    local r6=$(echo "$response" | grep -o "\"$CURRENCY_6\":[0-9.]*" | cut -d':' -f2)
    local r7=$(echo "$response" | grep -o "\"$CURRENCY_7\":[0-9.]*" | cut -d':' -f2)
    local r8=$(echo "$response" | grep -o "\"$CURRENCY_8\":[0-9.]*" | cut -d':' -f2)
    local r9=$(echo "$response" | grep -o "\"$CURRENCY_9\":[0-9.]*" | cut -d':' -f2)

    local output="$r1|$r2|$r3|$r4|$r5|$r6|$r7|$r8|$r9"
    [ -f "$CACHE_FILE" ] && cp "$CACHE_FILE" "$CACHE_PREV_FILE"
    echo "$output" > "$CACHE_FILE"
    echo "$output"
}

# ═══════════════════════════════════════════════════════════
# 📊 HELPERS
# ═══════════════════════════════════════════════════════════

get_trend() {
    local current=$1 previous=$2
    [ -z "$previous" ] || [ -z "$current" ] && echo "→" && return
    awk -v c="$current" -v p="$previous" 'BEGIN {
        if (c > p) print "↑"
        else if (c < p) print "↓"
        else print "→"
    }'
}

get_pct() {
    local current=$1 previous=$2
    [ -z "$previous" ] || [ -z "$current" ] || [ "$previous" = "0" ] && echo "---" && return
    awk -v c="$current" -v p="$previous" 'BEGIN {
        diff = ((c - p) / p) * 100
        if (diff > 0) printf "+%.2f%%", diff
        else printf "%.2f%%", diff
    }'
}

# ═══════════════════════════════════════════════════════════
# 📐 FIXED WIDTH CELL PRINTER
# Cell inner width = 28 chars
# Each line: "║ " + 28 chars + " " = 31 chars + border
# ═══════════════════════════════════════════════════════════

# Prints one line of a cell with exact padding (no color in padding)
# Usage: print_cell_line "content" [color]
print_cell_line() {
    local content="$1"
    local color="$2"
    # Strip color codes to measure real length
    local plain=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    local plain_len=${#plain}
    local pad_needed=$((26 - plain_len))
    [ $pad_needed -lt 0 ] && pad_needed=0
    local padding=$(printf '%*s' "$pad_needed" '')
    echo -ne "${BORANGE}║${NC} ${color}${content}${NC}${padding} "
}

# ═══════════════════════════════════════════════════════════
# 🖥️  DISPLAY FUNCTION
# ═══════════════════════════════════════════════════════════

show_rates() {
    clear

    # Cell width = 28, 3 cells + 4 borders = 96 chars total
    local SEP="════════════════════════════"  # 28 chars per cell

    local TOPDIV="${BORANGE}╔${SEP}╦${SEP}╦${SEP}╗${NC}"
    local MIDDIV="${BORANGE}╠${SEP}╬${SEP}╬${SEP}╣${NC}"
    local BOTDIV="${BORANGE}╚${SEP}╩${SEP}╩${SEP}╝${NC}"
    local ENDPIPE="${BORANGE}║${NC}"

    # ── Purple Title ────────────────────────────────────────
    # Exactly matches grid width: 88 chars total, 86 inner
    echo -e "${BPURPLE}╔══════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BPURPLE}║${NC}           ${BOLD}${WHITE}💱  Currency Monitor  ·  tmux Edition  ·  9 Currencies vs $BASE_CURRENCY${NC}                  ${BPURPLE}║${NC}"
    echo -e "${BPURPLE}╚══════════════════════════════════════════════════════════════════════════════════════════╝${NC}"

    # ── Orange Base + Time ──────────────────────────────────
    echo -e "${BORANGE}  $BASE_FLAG  Base: ${WHITE}$BASE_CURRENCY${BORANGE}   │   🕐  $(date '+%A, %b %d  %I:%M %p')${NC}"
    echo ""

    local DATA=$(get_rates)

    if [[ "$DATA" == ERROR:* ]]; then
        echo -e "$TOPDIV"
        echo -e "${BORANGE}║${NC}  ${RED}⚠  ${DATA}${NC}"
        echo -e "${BORANGE}║${NC}  Check your connection."
        for i in {1..4}; do echo -e "${BORANGE}║${NC}"; done
        echo -e "$BOTDIV"
    else
        IFS='|' read -r R1 R2 R3 R4 R5 R6 R7 R8 R9 <<< "$DATA"

        local P1="" P2="" P3="" P4="" P5="" P6="" P7="" P8="" P9=""
        if [ -f "$CACHE_PREV_FILE" ]; then
            IFS='|' read -r P1 P2 P3 P4 P5 P6 P7 P8 P9 < "$CACHE_PREV_FILE"
        fi

        # Build trend colors inline
        tline() {
            local rate=$1 prev=$2 code=$3
            local trend=$(get_trend "$rate" "$prev")
            local pct=$(get_pct "$rate" "$prev")
            local tcolor=""
            case $trend in
                "↑") tcolor="${GREEN}"  ;;
                "↓") tcolor="${RED}"    ;;
                *)   tcolor="${YELLOW}" ;;
            esac
            local short_rate=$(echo "$rate" | cut -c1-10)
            [ -z "$rate" ] && echo "N/A" || echo -e "${YELLOW}${short_rate} ${code}${NC}  ${tcolor}${trend} ${pct}${NC}"
        }

        # Name line - flag + name truncated to 22 chars
        nline() {
            local flag=$1 name=$2
            local short=$(echo "$name" | cut -c1-18)
            echo -e "${WHITE}${flag} ${short}${NC}"
        }

        # ── ROW 1 ─────────────────────────────────────────
        echo -e "$TOPDIV"
        print_cell_line "$(nline "$FLAG_1" "$NAME_1")" ; print_cell_line "$(nline "$FLAG_2" "$NAME_2")" ; print_cell_line "$(nline "$FLAG_3" "$NAME_3")" ; echo -e "$ENDPIPE"
        print_cell_line "$(tline "$R1" "$P1" "$CURRENCY_1")" ; print_cell_line "$(tline "$R2" "$P2" "$CURRENCY_2")" ; print_cell_line "$(tline "$R3" "$P3" "$CURRENCY_3")" ; echo -e "$ENDPIPE"

        # ── ROW 2 ─────────────────────────────────────────
        echo -e "$MIDDIV"
        print_cell_line "$(nline "$FLAG_4" "$NAME_4")" ; print_cell_line "$(nline "$FLAG_5" "$NAME_5")" ; print_cell_line "$(nline "$FLAG_6" "$NAME_6")" ; echo -e "$ENDPIPE"
        print_cell_line "$(tline "$R4" "$P4" "$CURRENCY_4")" ; print_cell_line "$(tline "$R5" "$P5" "$CURRENCY_5")" ; print_cell_line "$(tline "$R6" "$P6" "$CURRENCY_6")" ; echo -e "$ENDPIPE"

        # ── ROW 3 ─────────────────────────────────────────
        echo -e "$MIDDIV"
        print_cell_line "$(nline "$FLAG_7" "$NAME_7")" ; print_cell_line "$(nline "$FLAG_8" "$NAME_8")" ; print_cell_line "$(nline "$FLAG_9" "$NAME_9")" ; echo -e "$ENDPIPE"
        print_cell_line "$(tline "$R7" "$P7" "$CURRENCY_7")" ; print_cell_line "$(tline "$R8" "$P8" "$CURRENCY_8")" ; print_cell_line "$(tline "$R9" "$P9" "$CURRENCY_9")" ; echo -e "$ENDPIPE"

        echo -e "$BOTDIV"
    fi

    # ── Footer ────────────────────────────────────────────
    echo ""
    if [ -f "$CACHE_FILE" ]; then
        local current_time=$(date +%s)
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
        local cache_age=$((current_time - cache_time))
        local cache_remaining=$((CACHE_MAX_AGE - cache_age))

        if [ $cache_remaining -gt 0 ]; then
            local cache_mins=$((cache_remaining / 60))
            echo -e "  ${BORANGE}💾${NC} Cached (${cache_mins}m)  ${BORANGE}│${NC}  ${BORANGE}⏰${NC} Next: $(date -d "+$UPDATE_INTERVAL seconds" '+%I:%M %p' 2>/dev/null || date -v+${UPDATE_INTERVAL}S '+%I:%M %p' 2>/dev/null)  ${BORANGE}│${NC}  ${GREEN}'r'${NC} refresh  ${BORANGE}│${NC}  ${RED}Ctrl+C${NC} quit"
        else
            echo -e "  ${YELLOW}🔄 Fetching fresh data...${NC}"
        fi
    else
        echo -e "  ${BORANGE}⏰${NC} Next: $(date -d "+$UPDATE_INTERVAL seconds" '+%I:%M %p' 2>/dev/null || date -v+${UPDATE_INTERVAL}S '+%I:%M %p' 2>/dev/null)  ${BORANGE}│${NC}  ${GREEN}'r'${NC} refresh  ${BORANGE}│${NC}  ${RED}Ctrl+C${NC} quit"
    fi
}

# ═══════════════════════════════════════════════════════════
# 🔄 MAIN LOOP
# ═══════════════════════════════════════════════════════════

while true; do
    show_rates
    read -t $UPDATE_INTERVAL -n 1 key
    if [ "$key" = "r" ]; then continue; fi
done
