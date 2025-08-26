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
done | progress_bar $total
```


The input above is ordered and complete, containing all integers from `0` to `100`.
That's not at all necessary for successful execution, however.

While shuffled input may be pretty laggy due to drawing gradients, it's fully supported.

```sh
total=1000
for ((i = 0; i <= total; i += 23)); do
  echo $i
done | shuf | progress_bar $total # Kinda useless, but totally fine!
```

> Note that `progress_bar` will clamp input between 0% and 100%.
> For example, if `total` is `4000`, and `5000` is received through `stdin`,
> the output will look as though `4000` had been piped in instead.
> Any non-integer input will be ignored entirely.


For testing purposes, you can pass the `--demo` argument.
This will simulate piping an ordered series of integers to `progress_bar`.

```sh
# Animates a progress bar from 0 to 250
progress_bar --demo

# Or up to a specified total like 1000
progress_bar --demo 1000
```

