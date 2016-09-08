# Booli filter

  This script filters out results from booli.se based on the distance to your points of interest (work, city center, etc).
  It uses Google API to measure the transit distance, walking distance to T-bana and removes results which do not match your criteria.
  It also shows closing prices for similar apartments in the same area.

## Installation

```Shell
git clone https://github.com/vzctl/booli-filter.git
cd booli-filter
bundle install
```

## Configuration

Configuration is stored in [config.yaml](config.yaml). All the options are described inline.

## API keys

You need to update 3 keys in `config.yaml`:

* [Booli.se](https://www.booli.se/api/key)
* [GoogleMaps API key](https://developers.google.com/maps/documentation/directions/get-api-key)
* [GoogleMaps JavaScript API key](https://developers.google.com/maps/documentation/javascript/get-api-key) (Optional)

## Usage

```Shell
bundle exec ./search.rb
chrome list.html
```

## Output example

![list.html]
(list.html.png)
