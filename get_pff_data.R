library(httr)
library(jsonlite)
library(dplyr)

# PFF API KEY REQUIRED FOR THIS TO WORK
warning("PFF API key required for this script to run.\nJust knit the RMD file and use CSV/RMD files to reproduce model and results.")
api_key <- readline(prompt="Enter PFF API key: ")

base_url = 'https://api.profootballfocus.com'
bearer_auth <- POST(url = paste0(base_url, "/auth/login"), add_headers('x-api-key' =  api_key))

if(bearer_auth$status_code == 401){
  stop("PFF API key required for this script to run.\nJust knit the RMD file and use CSV/RMD files to reproduce model and results.")
} else {
  jwt = fromJSON(content(bearer_auth, "text"))$jwt
  headers = add_headers('Accept-Encoding'= 'gzip', 'Content-Type'= 'application/json', 'Authorization'= paste0('Bearer ', jwt))
  
  pbp2018_req <- GET(paste0(base_url, "/v1/video/nfl/2018/plays"), headers)
  pbp2018 <- fromJSON(content(pbp2018_req, "text"))$plays
  rm(pbp2018_req)
  
  pff_man_coverage <- pbp2018 %>%
    dplyr::filter(run_pass == "P") %>%
    dplyr::filter(pass_result != "SPIKE") %>%
    dplyr::filter(pass_result != "LATERAL") %>%
    mutate(coverage_type = ifelse((grepl("1", pass_coverage) | grepl("0", pass_coverage) | grepl("B", pass_coverage) | grepl("2M", pass_coverage)),
                              "MAN",
                              "ZONE")) %>%
    mutate(pass_rushers = as.numeric(sub("\\;.*", "", pass_rush_players))) %>%
    mutate(coverage_type = ifelse(pass_rushers > 6, "MAN", coverage_type)) %>%
    dplyr::filter(coverage_type == "MAN") %>%
    dplyr::filter(!is.na(press_players))
  
  saveRDS(pff_man_coverage, "data/pff_press_man_plays.RDS")
  rm(pbp2018)
}

