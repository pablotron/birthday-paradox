# Birthday Paradox Scripts

Scripts used to generate the chart and table in my [Birthday Paradox
article][bp].

Use these scripts as you see fit.  The scripts are commented but they're
not going to win any beauty awards.

## Usage

To generate the [YAML][] for the probability table:

```sh
# generate table as yaml on standard output
ruby ./birthday.rb yaml > table.yaml
```

Generate the [SVG][] for the probability chart:

```sh
# write chart svg to birthday-chart.svg
BDAY_SVG_PATH=birthday-chart.svg ruby ./birthday.rb svg
```

You can also generate a [CSV][] of the table contents, like so:

```sh
ruby ./birthday.rb csv > table.csv
```

[bp]: https://pablotron.org/articles/the-birthday-paradox
  "The Birthday Paradox."
[yaml]: https://en.wikipedia.org/wiki/YAML
  "YAML Ain't a Markup Language."
[svg]: https://en.wikipedia.org/wiki/Scalable_Vector_Graphics
  "Scalable Vector Graphics file."
[csv]: https://en.wikipedia.org/wiki/Comma-separated_values
  "Comma-separated Values file."
