# Big Data Bowl 2021: Hip Reaction Drill  
## Measuring Reactions of Defenders in Press-Man against Vertical-Breaking Routes

Charles Gelman

Contact me on [LinkedIn](https://www.linkedin.com/in/charles-g-7a2314107/) or [Twitter](https://twitter.com/CharlieGel)  


## Getting started

Begin by cloning this repo:

`git clone git@github.com:charliegelman/BigDataBowl2021.git`

Change into the directory:

`cd BigDataBowl2021`

Then make sure to download the Big Data Bowl 2021 data by going to the [Kaggle contest data page](https://www.kaggle.com/c/nfl-big-data-bowl-2021/data), selecting `Download All`, unzipping `nfl-big-data-bowl-2021.zip`, and moving the contents of resulting folder to the `data` folder in the repository.

## Data Pulling and Merging

If you would like to recreate pulling data and merging, you will need a ProFootballFocus API key. If you do not have one, skip to data cleaning.

Run `get_pff_data.R` and enter your PFF API key when prompted to.

Once you've ran that, you should have `pff_press_man_plays.RDS` in your `data` folder.

Now run `merge_data.R`.

In this process, we pulled the PFF data and filtered down to just passing plays where the defense was playing man coverage and had someone pressing, which gave us 5,980 plays. We then merged each of the plays from the Big Data Bowl data to the PFF plays identified as press-man based on GSIS play ID, possession team, and week number. After removing 472 plays that were missing game IDs, we were left with 5,508 plays and saved it in `data/merged_data.csv`.

## Data Cleaning

Run `clean_merged_data.py`.

In this script, we first created a new row for every press player and their respective receiver/route that they were covering. This gave us 11,450 rows, which is in `data/cleaned_data.csv`. Knowing that we only want to examine vertical-breaking routes, we then filtered for just the four routes in question which left us with 4,502 routes to examine, with 2,824 of those being verticals and 1,678 of those being comebacks, curls, and hitches. This is saved in `data/cleaned_vertical_route_data.csv`. We are now ready to start measuring hip reactions.

## Creating Hip-Reaction Statistics

Run `get_player_tracking_stats.py`.

You can find more details on this script in the Methods section of the writeup. Essentially, in this script, we look at each route ran and either measured hip reaction time (if it's a comeback, curl, or hitch) or downfield distance (if it's a vertical). We would then measure separation at the point of pass arrival if the receiver was targeted.

## Figures

Run `make_figures.R`.

In this script, we create each of the figures found in the final report and save them in the figures folder.

## Final Writeup

Knit `writeup.Rmd` to recreate an html version of the final Kaggle submission.
