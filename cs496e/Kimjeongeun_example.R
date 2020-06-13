library(dplyr)

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

celeb_csv = read.csv("data/김정은_data.csv")
View (celeb_csv)

# Total emos per week
total_week = celeb_csv %>%
  select(nth_week, total) %>%
  filter(total>30) %>%
  group_by(nth_week) %>%
  summarize(mean_total = mean(total))
plot(total_week)

# Positive, negative emotions per week
pos_neg_week = celeb_csv %>%
  filter(total>30) %>%
  mutate(positive = total-sad-surprise-angry,
         negative = total - positive) %>%
  select(nth_week, positive, negative) %>%
  group_by(nth_week) %>%
  summarize(pos = mean(positive), neg = mean(negative))
plot(pos_neg_week)

# Positive ratio per week
ratio_week = pos_neg_week %>%
  mutate(ratio = pos/(pos+neg)) %>%
  select (nth_week, ratio)
plot(ratio_week)

