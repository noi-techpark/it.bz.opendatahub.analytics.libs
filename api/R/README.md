# bzar: BZ Analytics for R

`bzar` is an R package that contains a set of functions to access [BZ
Analytics](https://analytics.opendatahub.bz.it/) from R.


## Installation

### Prerequisites

You need an installation of R including the package `httr` from CRAN.

In Linux (Debian), just install the packages `r-base` and `r-cran-httr`:
```
apt install r-base r-cran-httr
```

In macOS just install the official R package from the [R
site](https://cran.r-project.org), then open the package installer and get
`httr` from CRAN.

### Installing the package

Clone this repository and change directory:
```
git clone git@github.com:noi-techpark/it.bz.opendatahub.analytics.libs.git
cd it.bz.opendatahub.analytics.libs
```

Start the R prompt (switch to the root folder of this library first):
```
cd api/R
R
```

In the R prompt, install the bzar package from the local source:

```R
install.packages("./bzar", repos = NULL, type="source")
```

and load it:

```R
library(bzar)
```

### Removing the package

Should you ever want to remove bzar from your R installation, run:

```R
remove.packages("bzar")
```

## Usage

Load the package using

```R
library(bzar)
```

The main function is ```bzar.get_data()``` and serves to fetch the
time series data.

Here is a sample invocation that fetches air temperature for the station
in Rabbi (code T0076) im May 2020, requesting the smallest sample period
available:

```R
data = bzar.get_data("Weather", "T0076", "air_temperature", "2020-05-01T00:00:00+0200", "2020-06-01T00:00:00+0200", 1)
```

data is a data frame with columns time and value:

```R
> data
                    time value
1    2020-04-30 22:00:00   5.4
2    2020-04-30 22:15:00   5.3
3    2020-04-30 22:30:00   5.2
4    2020-04-30 22:45:00     5
5    2020-04-30 23:00:00   4.9
[...]
2972 2020-05-31 20:45:00   9.7
2973 2020-05-31 21:00:00   9.5
2974 2020-05-31 21:15:00   9.5
2975 2020-05-31 21:30:00   9.4
2976 2020-05-31 21:45:00   9.3
```

that can be plotted with:

```R
plot(data$time, data$value)
```

Some data sets can be fetched only by authenticated users. ```bzar.get_data()``` has optional username and password arguments
to make authenticated requests. The following line shows the same request again, this time authenticated as user "user" with
password "password":

```R
data = bzar.get_data("Weather", "T0076", "air_temperature", "2020-05-01T00:00:00+0200", "2020-06-01T00:00:00+0200", 1, "user", "password")
```

To see what station types (like "Weather") are available, use:

```R
bzar.get_station_types()
```

Given a station type, to get the list of available station names and codes (like "T0076") use:

```R
bzar.get_stations("Weather")
```

Given a station, to get the list of available data sets (like "air_temperature") use:

```R
bzar.get_data_sets("Weather", "T0076")
```

Man pages for each function are available in the R help browser by invoking:

```R
??bzar
```

If you want to open that help pages in a browser instead, do:

```R
options(help_type = "html")
??bzar
```

You can switch back to "text" help pages with:
```R
options(help_type = "text") # open help internally
```

## Links of interest

- access other open databases in South Tyrol with MonalisR: https://github.com/mattia6690/MonalisR

