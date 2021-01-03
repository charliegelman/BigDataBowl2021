library(dplyr)

pff_plays <- readRDS("data/pff_press_man_plays.RDS") %>%
  filter(!is.na(as.numeric(week))) %>%
  mutate(week = as.numeric(week))
ngs_plays <- read.csv("data/plays.csv")
ngs_games <- read.csv("data/games.csv") #  %>%
#   mutate(game_date = format(strptime(as.character(gameDate), "%m/%d/%Y"), "%Y-%m-%d"))

ngs_plays <- ngs_plays %>%
  left_join(ngs_games)

merged_data <- pff_plays %>%
  mutate(poss_team_fixed = case_when(offense == "CLV" ~ "CLE",
                                     offense == "BLT" ~ "BAL",
                                     offense == "HST" ~ "HOU",
                                     offense == "ARZ" ~ "ARI",
                                     TRUE ~ offense)) %>%
  left_join(ngs_plays, by = c("gsis_play_id" = "playId", "week" = "week", "poss_team_fixed" = "possessionTeam")) %>%
  mutate(playId = gsis_play_id,
         possessionTeam = poss_team_fixed,
         quarter = quarter.y,
         down = down.y) %>%
  dplyr::filter(!is.na(gameId)) %>% #472 missing plays
  dplyr::select(gameId, gsis_play_id, poss_team_fixed, offense, defense, coverage_type, pass_coverage, pass_pattern_by_player, pass_pattern_basic, pass_breakup, pass_receiver_target, press_players, names(ngs_plays))
  
write.csv(merged_data, "data/merged_data.csv")
rm(merged_data)
rm(pff_plays)
rm(ngs_plays)
rm(ngs_games)

