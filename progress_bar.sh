#!/bin/bash

STATUS_FORMAT=' {done}/{todo} ({perc}%)'
GRADIENT=('60C0C0' 'C080D8')
BARCHARS=('>' '%' '#')
BEGINSTR='['
CLOSESTR=']'
EMPTYCHR='-'

###################
# COOLER SETTINGS #
###################

GRADIENT=('CC2222' 'CCCC22' '22CC22' '22CCCC' '2222CC' 'CC22CC')
BARCHARS=('▏' '▎' '▍' '▌' '▋' '▊' '▉' '█')
BEGINSTR='PROGRESS :▕'
CLOSESTR='▏::'
 
function hexlerp {
  local a="$1"; local b="$2"; local step="$3"; local steps="$4"
  echo "$((16#${a} + (16#${b} - 16#${a}) * step / steps))"
}
function pb_get-color {
  local cur="$(($1 - 1))"
  local last="$(($2 - 1))"

  local grad_full_i="$((cur * (${#GRADIENT[@]} - 1)))"
  local lerp_val="$((grad_full_i % last))"
  local i="$((grad_full_i / last))"
  local j="$((i + 1))"

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
  
  echo "\033[38;2;${r};${g};${b}m"
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

pb_last_cols=''
pb_last_bar_perc=''
pb_last_status_text=''
function pb_reset-vars {
  pb_last_cols=''
  pb_last_bar_perc=''
  pb_last_status_text=''
}

# Returns ANSII code to move cursor left or right
function pb_move {
  m="$1"
  [ "$m" -eq 0 ] && echo ''
  [ "$m" -gt 0 ] && echo "\033[${m}C"
  [ "$m" -lt 0 ] && echo "\033[$((0 - m))D"
}

function pb_print-bar {
  local done="$1"
  local todo="$2"
  local cols="$(tput cols)"
  [ -n "$WIDTHPERC" ] && cols=$((cols * WIDTHPERC / 100))
  [ -n "$MAXWIDTH" ] && [ "$cols" -gt "$MAXWIDTH" ] && cols="$MAXWIDTH"

  local bfactor="${#BARCHARS[@]}"
  local status_text="$(pb_get-status-text "$done" "$todo")"
  local final_status="$(pb_get-status-text "$todo" "$todo")"
  local reserved="$((${#BEGINSTR} + ${#CLOSESTR} + ${#final_status}))"
  local available="$((cols - reserved))"
  local full_bar="$((available * bfactor))"
  local bar_perc="$((done * full_bar / todo))"
  local sub_i="$((bar_perc % bfactor))"

  # Work variables
  local i; local a; local b; local c
  local ma="-${#pb_last_status_text}"
  local mc='0'
  local color

  local draw_to_bar=''
  local full_redraw=''
  if [ "$pb_last_cols" != "$cols" ]; then
    # Terminal window changed -> Redraw everything
    pb_last_cols="$cols"
    pb_last_bar_perc='0'
    draw_to_bar='1'
    full_redraw='1'
  elif [ "$pb_last_bar_perc" != "$bar_perc" ]; then
    # Only progress changed -> Add new bar-characters
    # Calculate cursor offset to overwrite only the changed section
    ma="$((ma - ${#CLOSESTR} - available + (pb_last_bar_perc / bfactor)))"
    mc="$((mc + (full_bar - bar_perc) / bfactor + ${#CLOSESTR}))"
    draw_to_bar='1'
  fi

  if [ -n "$full_redraw" ]; then
    # Full redraw: Clear the line and draw all elements
    a="\r\033[K${BEGINSTR}"
    c="${CLOSESTR}"
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

    # Pad with empty characters if fully redrawing
    if [ -n "$full_redraw" ]; then
      for ((; i < available; i++)); do
        b+="$EMPTYCHR"
      done
    fi
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

function demo_numbers {
  total="$1"
  for ((n = 0; n <= total; n++)); do
    echo "$n"
  done
}

demo_total=500
stty -echo -icanon
demo_numbers "$demo_total" \
| pb_animate-progress-bar "$demo_total"
s
