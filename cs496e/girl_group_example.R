library(dplyr)
library(ggplot2)
library(scales)

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

celeb_list = c('블랙핑크', '트와이스', '레드벨벳')
celeb_csv = data.frame()
for (celeb in celeb_list) {
  celeb_csv = rbind(celeb_csv, read.csv(paste0("data/", celeb, "_data.csv")))
}
celeb_csv = celeb_csv %>%
  mutate(week_start = week_to_date(nth_week))
View(celeb_csv)

# Total emos per week
total_week = celeb_csv %>%
  select(celeb, week_start, total) %>%
  filter(total>30) %>%
  group_by(celeb, week_start = as.Date(week_start)) %>%
  summarize(mean_total = mean(total))
View(total_week)

p = ggplot(total_week, aes(x = week_start, y = mean_total)) +
  labs(color = "Girl_group", shape = "Girl_group", x = "Week",
       y = "Average of total emos") + 
  theme_light(base_size = 12) +
  theme(panel.grid.minor = element_blank()) +
  theme(axis.text.x=element_text(angle=60, hjust=1)) +
  scale_x_date(labels = date_format("%Y-%m-%d"), breaks = date_breaks(width = "1 week"))
jit = position_jitter(seed = 123, width = 0.1)
p + geom_jitter(aes(color=celeb), size=3, position=jit)

# Positive, negative emotions per week
pos_neg_week = celeb_csv %>%
  filter(total>30) %>%
  mutate(positive = total-sad-surprise-angry,
         negative = total - positive) %>%
  select(celeb, week_start, positive, negative) %>%
  group_by(celeb, week_start) %>%
  summarize(pos = mean(positive), neg = mean(negative))
plot(pos_neg_week)

# Positive ratio per week
ratio_week = pos_neg_week %>%
  mutate(ratio = pos/(pos+neg)) %>%
  select (celeb, week_start, ratio)

p = ggplot(ratio_week, aes(x = week_start, y = ratio)) +
  labs(color = "Girl_group", shape = "Girl_group", x = "Week",
       y = "Positive emo ratio") + 
  theme_light(base_size = 12) +
  theme(panel.grid.minor = element_blank()) +
  theme(axis.text.x=element_text(angle=60, hjust=1)) +
  scale_x_date(labels = date_format("%Y-%m-%d"), breaks = date_breaks(width = "1 week")) +
  geom_line()
#jit = position_jitter(seed = 123, width = 0.1)
#p + geom_jitter(aes(color=celeb), size=3, position=jit)