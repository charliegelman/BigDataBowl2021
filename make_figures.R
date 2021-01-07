#### Packages ####
library(cowplot)
library(dplyr)
library(gganimate)
library(ggplot2)
library(patchwork)

#### Make data frames ####
final_data <- read.csv("data/final_data_imputed.csv")

summed_data <- final_data %>%
  group_by(defender_name) %>%
  summarise(count = n(), avg_downfield_distance = mean(downfield_distance, na.rm = TRUE), avg_hip_reaction_time = mean(hip_reaction_time, na.rm = TRUE), num_verts = sum(route_name == "Go")) %>%
  mutate(num_break_routes = count - num_verts)

#### Rank Defenders by Hip Reaction ####
summed_data %>%
  filter(num_break_routes >= 15) %>%
  arrange(avg_hip_reaction_time) %>%
  head(15) %>%
  ggplot(aes(y = reorder(defender_name, -avg_hip_reaction_time), x = avg_hip_reaction_time))+
  geom_col(fill = "#00009c", color = "black")+
  theme_cowplot()+
  labs(x = "Avg. Hip Reaction Time (sec)", y = "Defender Name", 
       title = "Top Defenders by Hip Reaction Time",
       subtitle = "2018 NFL Regular Season\nMinimum 15 snaps in press-man against a curl/hitch/comeback")
ggsave("figures/hip_reaction_rankings.png", width = 8, height = 4)

#### Rank Defenders by Downfield Distance ####
summed_data %>%
  filter(num_verts >= 15) %>%
  arrange(desc(avg_downfield_distance)) %>%
  head(15) %>%
  ggplot(aes(y = reorder(defender_name, avg_downfield_distance), x = avg_downfield_distance))+
  geom_col(fill = "#00009c", color = "black")+
  theme_cowplot()+
  labs(x = "Avg. Downfield Distance (yards)", y = "Defender Name", 
       title = "Top Defenders by Downfield Distance",
       subtitle = "2018 NFL Regular Season\nMinimum 15 snaps in press-man against a vertical")
ggsave("figures/vert_reaction_rankings.png", width = 8, height = 4)


#### Hip Reaction Stats vs Separation Plot ####
# Hip Reaction Time vs Separation
hip_vs_sep_plot <- final_data %>%
  filter(!is.na(hip_reaction_time)) %>%
  filter(!is.na(separation)) %>%
  ggplot(aes(x = hip_reaction_time, y = separation))+
  geom_point()+
  geom_smooth()+
  xlim(0,1)+
  ylim(0,5)+
  theme_cowplot()+
  labs(x = "Hip Reaction Time (sec)", y = "Separation (yards)", title = "Separation at the Catch Point vs. Hip Reaction Measurements")

# Downfield Distance vs Separation
vert_vs_sep_plot <- final_data %>%
  filter(!is.na(downfield_distance)) %>%
  filter(!is.na(separation)) %>%
  filter(separation < 30) %>%
  ggplot(aes(x = downfield_distance, y = separation))+
  geom_point()+
  geom_smooth()+
  xlim(-5,5)+
  theme_cowplot()+
  labs(x = "Downfield Distance (yards)", y = "Separation (yards)")

hip_vs_sep_plot + vert_vs_sep_plot
ggsave("figures/separation_plots.png", width = 8, height = 4)

#### Plot gif of Hip Reaction Time ####
# Get hip reaction time plays that are around the same downfield depth
hip_reacs <- final_data %>%
  filter(!is.na(hip_reaction_time)) %>%
  filter(route_name == "Hitch/Curl") %>%
  filter(route_depth > 5) %>%
  filter(route_depth < 6) %>%
  filter(typeDropback == "TRADITIONAL") %>%
  filter(targeted == 1) %>%
  arrange(hip_reaction_time)

# Function for getting tracking data for a given play
get_hip_reac <- function(row){
  read.csv(sprintf('data/week%d.csv', row[['week']])) %>%
    filter(gameId == 	row[['gameId']]) %>%
    filter(playId == 	row[['playId']]) %>%
    filter((displayName == row[['receiver_name']]) | (displayName == row[['defender_name']])) 
}


# Get the Christian Kirk vs Tramaine Brock play tracking data
good_hip_reac <- get_hip_reac(hip_reacs[4,])

# Get the DJ Moore vs Eli Apple play tracking data
bad_hip_reac <- get_hip_reac(hip_reacs[33,])

# Save the dataframes for posterity
write.csv(good_hip_reac, 'data/good_hip_react_dots.csv')
write.csv(bad_hip_reac, 'data/bad_hip_react_dots.csv')

# Plot speed and reaction time plot of DJ Moore vs Eli Apple
ggplot(bad_hip_reac, aes(x = frameId/10, y = s, color = displayName))+
  geom_point()+
  geom_line()+
  annotate("rect", xmin=filter(bad_hip_reac, displayName == "D.J. Moore")[which.max(filter(bad_hip_reac, displayName == "D.J. Moore")$s),]$frameId/10 - 0.15, 
                xmax=filter(bad_hip_reac, displayName == "Eli Apple")[which.max(filter(bad_hip_reac, displayName == "Eli Apple")$s),]$frameId/10 + 0.05, 
                ymin=0, ymax=Inf, alpha = 0.1, color = "blue")+
  annotate("text", x=filter(bad_hip_reac, displayName == "D.J. Moore")[which.max(filter(bad_hip_reac, displayName == "D.J. Moore")$s),]$frameId/10 + 0.15, 
           y = 3, color = "blue", angle = 90, size = 6,
           label = "Hip Reaction - 0.6s")+
  scale_color_manual(values = c("purple", "green"))+
  labs(x = "Time (sec)", y = "Speed (yards/sec)", 
       title = "Speed of Players during a Curl versus Press-Man Coverage", 
       color = "Player",
       subtitle = "GSIS play 98 of the 2018 Week 15 game between the Panthers and Saints\nEli Apple's hip reaction time indicated")+
  theme_cowplot()
ggsave("figures/hip_reaction_plot.png", width = 8, height = 4)


# Plot animation of both plays side by side
ggplot(bad_hip_reac, aes(y = 113 - x, x = y, label = jerseyNumber))+
  annotate("text", x = 21, 
           y = 52:68, label = "____", hjust = 1, vjust = -0.3) + 
  geom_hline(yintercept = seq(51,66,5), color = "black")+
  geom_hline(yintercept = 66, color = "blue", size = 2)+
  geom_hline(yintercept = 56, color = "yellow", size = 2)+
  geom_point(aes(shape = position, fill = displayName), size = 5, alpha = 0.7, colour = "black") +
  geom_point(data = good_hip_reac, aes(y = x, x = y - 20, shape = position, fill = displayName), colour="black", size = 5, alpha = 0.7)+
  scale_shape_manual(values=c("CB" = 21, "WR" = 22))+
  scale_fill_manual(values = c("red", "purple", "green", "blue"))+
  guides(fill = guide_legend(override.aes=list(shape=21)))+
  geom_text(colour = "white", size = 3.5)+
  geom_text(data = good_hip_reac, aes(y = x, x = y - 20), colour = "white", size = 3.5)+
  annotate("text", x = 15, y = 67.75, label = "Hip Reaction: 0.6s")+
  annotate("text", x = 27, y = 67.75, label = "Hip Reaction: 0.1s")+
  coord_fixed() +  
  theme_nothing()+
  labs(fill = "Player", shape = "Position",
       caption = "Plot of hip reactions by Eli Apple (green) and Tramaine Brock (blue)\nagainst D.J. Moore (purple) and Christian Kirk (red), respectively.\nLeft Play: GSIS play 98, Week 15, Panthers vs. Saints\nRight Play: GSIS play 1324, Week 7, Broncos vs. Cardinals")+
  theme(legend.position = "right", plot.caption.position = "plot", plot.caption = element_text(size=12))+
  transition_states(frameId)
anim_save("figures/good_bad_hip_reactions.gif")

#### Plot gif of Downfield Distance ####
# Get downfield distance plays that are around the same downfield depth
vert_reacs <- final_data %>%
  filter(!is.na(downfield_distance)) %>%
  filter(route_depth > 16) %>%
  filter(typeDropback == "TRADITIONAL") %>%
  filter(targeted == 1) %>%
  arrange(desc(downfield_distance))

# Get the Russell Shepard vs Chandon Sullivan play tracking data
good_vert_reac <- get_hip_reac(vert_reacs[4,])

# Get the Kelvin Benjamin vs Jaire Alexander play tracking data
bad_vert_reac <- get_hip_reac(vert_reacs[18,])

# Save the dataframes for posterity
write.csv(good_vert_reac, 'data/good_vert_react_dots.csv')
write.csv(bad_vert_reac, 'data/bad_vert_react_dots.csv')

# Plot animation of both plays side by side
ggplot(bad_vert_reac, aes(y = x, x = y, label = jerseyNumber))+
  annotate("text", x = 23, 
           y = 36:74, label = "____", hjust = 1, vjust = -0.3) + 
  geom_hline(yintercept = seq(35,70,5), color = "black")+
  geom_hline(yintercept = 70, color = "blue", size = 2)+
  geom_hline(yintercept = 60, color = "yellow", size = 2)+
  geom_hline(yintercept = 53, color = "red", size = 1, linetype = "dashed")+
  geom_point(aes(shape = position, fill = displayName), size = 5, alpha = 0.7, colour = "black") +
  geom_point(data = good_vert_reac, aes(y = 95 - x, x = y + 25, shape = position, fill = displayName), colour="black", size = 5, alpha = 0.7)+
  scale_shape_manual(values=c("CB" = 21, "WR" = 22))+
  scale_fill_manual(values = c("blue", "green", "purple",  "red"))+
  guides(fill = guide_legend(override.aes=list(shape=21)))+
  geom_text(colour = "white", size = 3.5)+
  geom_text(data = good_vert_reac, aes(y = 95 - x, x = y + 25), colour = "white", size = 3.5)+
  annotate("text", x = 12, y = 73.5, label = "Downfield Dist.: -3.04 yds")+
  annotate("text", x = 34, y = 73.5, label = "Downfield Dist.: +0.11 yds")+
  coord_fixed() +  
  theme_nothing()+
  labs(fill = "Player", shape = "Position",
       caption = "Plot of downfield distances by Jaire Alexander (green) and Chandon Sullivan (blue)\nagainst Kelvin Benjamin (purple) and Russell Shepard (red), respectively\nLeft Play: GSIS play 1735, Week 4, Bills vs. Packers\nRight Play: GSIS play 1076, Week 12, Giants vs. Eagles")+
  theme(legend.position = "right", plot.caption.position = "plot", plot.caption = element_text(size=12))+
  xlim(5, 40)+
  ylim(45,74)+
  transition_states(frameId)
anim_save("figures/good_bad_vert_reactions.gif")
#### end ####

