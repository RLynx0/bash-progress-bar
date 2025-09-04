# Showing Off

In this repository's root directory, invoke the following code for a display of what this script is capable of.  
It displays gradients, updating multiple bars at once, scaling to 32% of the terminal,
sub-character progress bar updates and self-padding string formatting.  
Yeah, I'm pretty proud of this. :)

```sh
./multibar-sample-input \
| ./progress_bar \
    -w 32 \
    -E '. ' \
    -b blocky \
    -e ']  ' \
    -c sunset \
    -f '{"{done:0<3}/{todo:>3}": ->11} ({perc:3}%)' \
    250
```

You can also pass the `--show-off` flag to compare different builtin presets.  
`--show-off` can optionally take one of these arguments:
- `all` or `a` : This is the default beaviour - Show off everything.
- `preset` or `p`: Show off available presets for full configurations.
- `colors` or `c`: Show off predefined color settings.
- `bar` or `b`: Show off predefined bar settings.

If you don't want to sit through having every available preset animated for you,
but still want to see them all, set a small total like `1`.
This will essentially print all the bars in just two steps: `0%` completion and `100%` completion.
The latter step might still be rather slow for wide bars with more than one color.
I guess that's just what I get for printing 180 ANSII codes in a single `echo`.

```bash
./progress_bar --show-off --width 40 1
```

# Usage

`progress_bar` accepts an integer argument `total`, representing 100% completion.
The script reads step values from `stdin` and updates the bar incrementally.
In the following code, `command` should emmit integers between `0` and `3000`.

```sh
command | progress_bar 3000
```


This snippet provides a more concrete example of how the script can be used.

```sh
total=100
for ((i = 0; i <= total; i++)); do
  echo $i
done | ./progress_bar $total
```


The input above is ordered and complete, containing all integers from `0` to `100`.
That's not at all necessary for successful execution, however.

While shuffled input may be pretty laggy due to drawing gradients, it's fully supported.

```sh
total=1000
for ((i = 0; i <= total; i += 23)); do
  echo $i
done | shuf | ./progress_bar $total # Kinda useless, but totally fine!
```

> Note that `progress_bar` will clamp input between 0% and 100%.
> For example, if `total` is `4000`, and `5000` is received through `stdin`,
> the output will look as though `4000` had been piped in instead.
> Negative input will also be clamped to `0`.
> Any invalid input will be ignored entirely.


For testing purposes, you can pass the `--demo` argument.
This will simulate piping an ordered series of integers to `progress_bar`.

```sh
# Animates a progress bar from 0 to 250
./progress_bar --demo

# Or up to a specified total like 1000
./progress_bar --demo 1000
```

## Complex Input
`progress_bar` supports a bit more than just plain integers as input.

Instead of providing an absolute value, you can tell `progress_bar` to increment or decrement the
current bar by passing in `+<increment>` or `-<decremen>`.

If you need to, you can also set the `total` value of the bar to a new number by appending `/<total>` to an input.
For example, the input `+0/500` will set the `total` of the bar to `500` while preserving the previous `completed` value.

`progress_bar` is also capable of maintaining multiple bars at once.
Any input can be redirected to a specific bar by prefixing it with `<index>:`.
If no index is supplied, the previously targeted bar will receive the input.
The first bar has index `0`.

This snippet will print 3 bars at once:

```bash
    for ((i = 0; i <= 100; i++)); do
        echo "0:${i}"
        echo "1:${i}"
        echo "2:${i}"
    done | ./progress_bar 100
```

> Note: You cannot target a negative index!
> Bar `0` will always be the first bar.


## CLI Options

```bash
# --preset; -p
progress_bar --preset fast  # COLORS='none';  BAR='minimal'; EMPTY_CHAR=' '; BAR_START='[';           BAR_END='] ';   STATUS_FORMAT='{perc}%'
progress_bar --preset slick # COLORS='cool';  BAR='blocky';  EMPTY_CHAR='-'; BAR_START='[';           BAR_END='] ';   STATUS_FORMAT='{done}/{todo}'
progress_bar --preset fancy # COLORS='pride'; BAR='smooth';  EMPTY_CHAR='-'; BAR_START='PROGRESS :▕'; BAR_END='▏:: '; STATUS_FORMAT='{done}/{todo} ({perc}%)'

# --colors; -c; COLORS="${COLORS:-'none'}"
# Gradient that the filled bar will be rendered with
progress_bar --colors none               # GRADIENT=()
progress_bar --colors cool               # GRADIENT=('60C0C0' 'C080D8')
progress_bar --colors pride              # GRADIENT=('CC2222' 'CCCC22' '22CC22' '22CCCC' '2222CC' 'CC22CC')
progress_bar --colors 'CC22CC,CC2222'    # GRADIENT=('CC22CC' 'CC2222')
progress_bar --colors '#CC22CC, #CC2222' # GRADIENT=('CC22CC' 'CC2222')

# --bar; -b; BAR="${BAR:-'minimal'}"
# Characters used to render filled parts of the bar
progress_bar --bar minimal # BARCHARS=('#')
progress_bar --bar blocky  # BARCHARS=('>' '%' '#')
progress_bar --bar smooth  # BARCHARS=('▏' '▎' '▍' '▌' '▋' '▊' '▉' '█')
progress_bar --bar '.:!|'  # BARCHARS=('.' ':' '!' '|')

# --empty-char; -E; EMPTY_CHAR="${EMPTY_CHAR:-' '}"
# Character used to render empty parts of the bar
progress_bar --empty-char ' '
progress_bar --empty-char '-'

# --bar-start; -s; BAR_START="${BAR_START:-'['}"
# Static string rendered right before the bar
progress_bar --bar-start ''
progress_bar --bar-start '['
progress_bar --bar-start 'PROGRESS :▕'

# --bar-end; -e; BAR_END="${BAR_END:-'] '}"
# Static string rendered right after the bar
progress_bar --bar-end ''
progress_bar --bar-end '] '
progress_bar --bar-end '▏:: '

# --status-format; -f; STATUS_FORMAT="${STATUS_FORMAT:-'{perc}%'}"
# Dynamic string rendered after the very right of the output
# Can use the following tokens:
# - `{done}` : Number of completed steps
# - `{todo}` : Total number of defined steps
# - `{perc}` : The current completion percentage
progress_bar --status-fmt ''
progress_bar --status-fmt '{perc}%'
progress_bar --status-fmt '{done}/{todo} ({perc}%)'

# --width; -w; WIDTH="${WIDTH:-'100'}"
# Percentage of terminal width the bar will take up
progress_bar --width 75

# --max-width; -W; MAX_WIDTH="${MAX_WIDTH:-''}"
# Maximum columns the bar will take up
progress_bar --max-width 120

# --interval; -i; INTERVAL="${INTERVAL:-'1'}"
# Render only for every nth input
progress_bar --interval 1
progress_bar --interval 100

# --demo
progress_bar --demo
```

The following snippet renders a progress bar that
- takes up 50% of the terminal width
- is never wider than 120 columns
- uses the 'fancy' preset
- uses the color-scheme 'cool'
- receives reversed input

```bash
total=1000
for ((i = total; i >= 0; i--)); do
  echo "$i"
done | progress_bar -w 50 -W 120 -p 'fancy' -c 'cool' "$total"
```

> Note that parameters are evaluated in the order they are passed in.  
> For example, `progress_bar -c 'forest' -p 'slick'` will first load the 'forest'
> color scheme, and then overwrite it with the color scheme from the 'slick' preset.
