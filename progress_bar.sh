#!/bin/bash

DEFAULT__BAR='minimal'
DEFAULT__EMPTY_CHAR=' '
DEFAULT__COLORS='none'
DEFAULT__BAR_START='['
DEFAULT__BAR_END='] '
DEFAULT__STATUS_FORMAT='{perc}%'
DEFAULT__WIDTH_PERCENT='100'
DEFAULT__MAX_WIDTH=''
DEFAULT__INTERVAL='1'

BAR="${BAR:-"$DEFAULT__BAR"}"
EMPTY_CHAR="${EMPTY_CHAR:-"$DEFAULT__EMPTY_CHAR"}"
COLORS="${COLORS:-"$DEFAULT__COLORS"}"
BAR_START="${BAR_START:-"$DEFAULT__BAR_START"}"
BAR_END="${BAR_END:-"$DEFAULT__BAR_END"}"
STATUS_FORMAT="${STATUS_FORMAT:-"$DEFAULT__STATUS_FORMAT"}"
WIDTH_PERCENT="${WIDTH_PERCENT:-"$DEFAULT__WIDTH_PERCENT"}"
MAX_WIDTH="${MAX_WIDTH:-"$DEFAULT__MAX_WIDTH"}"
INTERVAL="${INTERVAL:-"$DEFAULT__INTERVAL"}"

BARCHARS=('#')
GRADIENT=()

pb_last_cols=''
pb_last_color=''
pb_last_bar_perc=''
pb_last_status_text=''
function pb_reset-vars {
  pb_last_cols=''
  pb_last_color=''
  pb_last_bar_perc=''
  pb_last_status_text=''
}

function hexlerp {
  local a="$1"; local b="$2"; local step="$3"; local steps="$4"
  echo "$((16#${a} + (16#${b} - 16#${a}) * step / steps))"
}

function pb_get-color {
  local cur="$(($1 - 1))"
  local last="$(($2 - 1))"
  local n_colors="${#GRADIENT[@]}"
  [ "$n_colors" -eq 0 ] && echo '' && return

  local grad_full_i="$((cur * (n_colors - 1)))"
  local lerp_val="$((grad_full_i % last))"
  local i="$(((grad_full_i / last) % n_colors))"
  local j="$(((i + 1) % n_colors))"

  local c0; local c1
  local r; local g; local b
  if [ "$lerp_val" -eq 0 ]; then
    c0="${GRADIENT["$i"]}"
    r="$((16#${c0:0:2}))"
    g="$((16#${c0:2:2}))"
    b="$((16#${c0:4:2}))"
  else
    c0="${GRADIENT["$i"]}"
    c1="${GRADIENT["$j"]}"
    r="$(hexlerp "${c0:0:2}" "${c1:0:2}" "$lerp_val" "$last")"
    g="$(hexlerp "${c0:2:2}" "${c1:2:2}" "$lerp_val" "$last")"
    b="$(hexlerp "${c0:4:2}" "${c1:4:2}" "$lerp_val" "$last")"
  fi

  local color="\033[38;2;${r};${g};${b}m"
  [ "$color" == "$pb_last_color" ] && echo '' && return
  pb_last_color="$color"
  echo "$color"
}

function pb_get-status-text {
  local done="$1"
  local todo="$2"
  local perc="$((done * 100 / todo))"
  local text="$STATUS_FORMAT"

  # Replace placeholders
  text="${text//\{done\}/$done}"
  text="${text//\{todo\}/$todo}"
  text="${text//\{perc\}/$perc}"

  echo "$text"
}

# Returns ANSII code to move cursor left or right
function pb_move {
  m="$1"
  if   [ "$m" -eq 0 ]; then echo ''
  elif [ "$m" -gt 0 ]; then echo "\033[${m}C"
  elif [ "$m" -lt 0 ]; then echo "\033[$((0 - m))D"
  fi
}

function pb_print-bar {
  local done="$1"
  local todo="$2"

  # Sanity checks
  [ "$todo" -le 0 ] && todo='1'
  [ "$done" -lt 0 ] && done='0'
  [ "$done" -gt "$todo" ] && done="$todo"

  # Get terminal space and reserved area length
  local cols="${COLUMNS:-$(tput cols)}"
  local status_text="$(pb_get-status-text "$done" "$todo")"
  local final_status="$(pb_get-status-text "$todo" "$todo")"
  local reserved="$((${#BAR_START} + ${#BAR_END} + ${#final_status}))"

  # Scale cols to width-perc and max-width
  [ "$WIDTH_PERCENT" -le 100 ] && cols=$((cols * WIDTH_PERCENT / 100))
  [ -n "$MAX_WIDTH" ] && [ "$cols" -gt "$MAX_WIDTH" ] && cols="$MAX_WIDTH"
  [ "$cols" -lt "$reserved" ] && cols="$reserved"

  # Pad out status_text to overwrite longer old one
  while [ "${#status_text}" -lt "${#pb_last_status_text}" ]; do
    status_text+=" "
  done

  # Variables related to the actual bar
  local bfactor="${#BARCHARS[@]}"
  local available="$((cols - reserved))"
  local full_bar="$((available * bfactor))"
  local bar_perc="$((done * full_bar / todo))"
  local sub_i="$((bar_perc % bfactor))"

  # Return early if nothing changed
  [ "$cols" == "$pb_last_cols" ] \
  && [ "$bar_perc" == "$pb_last_bar_perc" ] \
  && [ "$status_text" == "$pb_last_status_text" ] \
  && return
  
  # Work variables
  local i; local a; local b; local c
  local ma="-${#pb_last_status_text}"
  local mc='0'
  local color

  # Choose draw mode
  local draw_to_bar=''
  local full_redraw=''
  local draw_empty_to='0'
  if [ "$pb_last_cols" != "$cols" ]; then
    # Terminal window changed -> Redraw everything
    draw_empty_to="$available"
    pb_last_cols="$cols"
    pb_last_bar_perc='0'
    draw_to_bar='1'
    full_redraw='1'
  elif [ "$pb_last_bar_perc" -lt "$bar_perc" ]; then
    # Only progress changed -> Add new bar-characters
    # Calculate cursor offset to overwrite only the changed section
    ma="$((ma - ${#BAR_END} - available + (pb_last_bar_perc / bfactor)))"
    mc="$((mc + (full_bar - bar_perc) / bfactor + ${#BAR_END}))"
    draw_to_bar='1'
  elif [ "$pb_last_bar_perc" -gt "$bar_perc" ]; then
    # Redraw bar section cleanly
    ma="$((ma - ${#BAR_END} - available + (bar_perc / bfactor)))"
    draw_empty_to="$(((pb_last_bar_perc + bfactor - 1) / bfactor))"
    mc="$((mc + available - draw_empty_to + ${#BAR_END}))"
    pb_last_bar_perc="$bar_perc"
    draw_to_bar='1'
  fi

  if [ -n "$full_redraw" ]; then
    # Full redraw: Clear the line and draw all elements
    a="\r\033[K${BAR_START}"
    c="${BAR_END}"
  else
    # Incremental update: Just move cursor to the right places
    a="$(pb_move "$ma")"
    c="$(pb_move "$mc")"
  fi

  if [ -n "$draw_to_bar" ]; then
    # Continue drawing bar from last progress point
    i="$((pb_last_bar_perc / bfactor))"
    for ((; i < bar_perc / bfactor; i++)); do
      color="$(pb_get-color "$(((i + 1) * bfactor))" "$full_bar")"
      b+="${color}${BARCHARS[-1]}"
    done

    # Add sub-character for fractional progress
    if [ "$sub_i" -gt 0 ]; then
      color="$(pb_get-color "$bar_perc" "$full_bar")"
      b+="${color}${BARCHARS["$((sub_i - 1))"]}"
      i="$((i + 1))"
    fi

    # Reset color
    b+="\033[0m"

    # Pad with empty characters
    for ((; i < draw_empty_to; i++)); do
      b+="$EMPTY_CHAR"
    done
  fi

  # Save current state for next update
  pb_last_bar_perc="$bar_perc"
  pb_last_status_text="$status_text"

  # Draw the bar and status
  echo -ne "${a}${b}${c}${status_text}"
}

function pb_animate-progress-bar {
  total="$1"
  pb_reset-vars
  while read n; do
    pb_print-bar "$n" "$total"
  done; echo
}

function demo {
  total="${1:-250}"
  stty -echo -icanon
  for ((n = 0; n <= total; n++)); do echo "$n"
  done | COLUMNS='' pb_animate-progress-bar "$total"
  stty sane; echo
}

demo "$1"
