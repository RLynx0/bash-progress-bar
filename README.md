# Showing Off

In this repository's root directory, invoke the following code for a display of what this script is capable of.  
It displays gradients, updating multiple bars at once, scaling to 32% of the terminal,
sub-character progress bar updates and self-padding string formatting.  
Yeah, I'm pretty proud of this. :)

```sh
./multibar-sample-input \
| ./progress-bar \
    -w 80 \
    -W 76 \
    -E '. ' \
    -b blocky \
    -s ' [' \
    -e ']  ' \
    -c sunset \
    -f '{"{done}/{todo}":^11} ({perc:3}%)' \
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
./progress-bar --show-off --width 40 1
```

# Usage

`progress-bar` accepts an integer argument `total`, representing 100% completion.
The script reads step values from `stdin` and updates the bar incrementally.
In the following code, `command` should emmit integers between `0` and `3000`.

```sh
command | progress-bar 3000
```


This snippet provides a more concrete example of how the script can be used.

```sh
total=100
for ((i = 0; i <= total; i++)); do
  echo $i
done | ./progress-bar $total
```


The input above is ordered and complete, containing all integers from `0` to `100`.
That's not at all necessary for successful execution, however.

While shuffled input may be pretty laggy due to drawing gradients, it's fully supported.

```sh
total=1000
for ((i = 0; i <= total; i += 23)); do
  echo $i
done | shuf | ./progress-bar $total # Kinda useless, but totally fine!
```

> Note that `progress-bar` will clamp input between 0% and 100%.
> For example, if `total` is `4000`, and `5000` is received through `stdin`,
> the output will look as though `4000` had been piped in instead.
> Negative input will also be clamped to `0`.
> Any invalid input will be ignored entirely.


For testing purposes, you can pass the `--demo` argument.
This will simulate piping an ordered series of integers to `progress-bar`.

```sh
# Animates a progress bar from 0 to 250
./progress-bar --demo

# Or up to a specified total like 1000
./progress-bar --demo 1000
```

## Complex Input
`progress-bar` supports a bit more than just plain integers as input.

Instead of providing an absolute value, you can tell `progress-bar` to increment or decrement the
current bar by passing in `+<increment>` or `-<decremen>`.

If you need to, you can also set the `total` value of the bar to a new number by appending `/<total>` to an input.
For example, the input `+0/500` will set the `total` of the bar to `500` while preserving the previous `completed` value.

`progress-bar` is also capable of maintaining multiple bars at once.
Any input can be redirected to a specific bar by prefixing it with `<index>:`.
If no index is supplied, the previously targeted bar will receive the input.
The first bar has index `0`.

This snippet will print 3 bars at once:

```bash
    for ((i = 0; i <= 100; i++)); do
        echo "0:${i}"
        echo "1:${i}"
        echo "2:${i}"
    done | ./progress-bar 100
```

> Note: You cannot target a negative index!
> Bar `0` will always be the first bar.


## CLI Options

| Option             | Shorthand  | Description                                                       | Default     |
|--------------------|------------|-------------------------------------------------------------------|-------------|
| `--preset NAME`    | `-p`       | Applay a style preset.                                            | --          |
| `--colors LIST`    | `-c`       | Gradient of hex colors or preset name.                            | `'none'`    |
| `--bar CHARS`      | `-b`       | Characters used to fill the bar or preset name.                   | `'minimal'` |
| `--empty-str STR`  | `-E`       | Pattern used to pad empty space in the bar.                       | `' '`       |
| `--bar-start STR`  | `-s`       | String shown before the bar.                                      | `'['`       |
| `--bar-end STR`    | `-e`       | String shown after the bar.                                       | `'] '`      |
| `--status-fmt STR` | `-f`       | Format string for status.                                         | `'{perc}%'` |
| `--interval N`     | `-i`       | Update only if input is divisible by N.                           | `'1'`       |
| `--width PERCENT`  | `-w`       | Set bar width as percentage of terminal width.                    | `'100'`     |
| `--max-width COLS` | `-W`       | Maximum bar width in columns.                                     | `''`        |
| `--size-strict`    | `-S`       | Prevent overflowing width constraints.                            | --          |
| `--list [SET]`     | `-l`       | List available presets for `preset`, `bar`, `colors` or `all`.    | --          |
| `--show-off [SET]` | --         | Preview available presets for `preset`, `bar`, `colors` or `all`. | --          |
| `--demo`           | --         | Run a demo progress bar with the current settings.                | --          |
| `--help`           | `-?`, `-h` | Show help message and exit.                                       | --          |


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
done | progress-bar -w 50 -W 120 -p 'fancy' -c 'cool' "$total"
```

> Note that parameters are evaluated in the order they are passed in.  
> For example, `progress-bar -c 'forest' -p 'slick'` will first load the 'forest'
> color scheme, and then overwrite it with the color scheme from the 'slick' preset.


## Status Format

The padding behavior can get very involved and nested.
Try to work through what this monster of an expression does, for example:

```bash
./progress-bar --demo --status-fmt '{"{"done ->{"{"{done:<4}{todo:>4}":<10}":>12}<- todo":>28}":<30}'
```

Tip: This does pretty much the same:

```bash
./progress-bar --demo -f '{"done ->{"{done:<4}{todo:>4}":^12}<- todo":^30}'
```
