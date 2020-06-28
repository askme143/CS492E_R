library(dplyr)
library(RcppRoll)
library(ggplot2)
library(scales)
library(forecast)
library(GGally)
library(dtwclust)

week_to_date = function(nth_week) {
  start = as.Date("2017-01-01", "%Y-%m-%d")
  start + nth_week*7
}

celeb_list = c('방탄소년단', '엑소', '블랙핑크', '트와이스', '레드벨벳')

total_week_table = data.frame()
mean_total_table = data.frame()
ma15_table = data.frame()
ma3_table = data.frame()
trend_table = data.frame()
count = 1
for (celeb in celeb_list){
  celeb_csv = read.csv(paste0("3year_data/", celeb, "_data.csv"), sep=",")
  colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")
  celeb_csv[9:19] = lapply(celeb_csv[9:19], function(x){as.numeric(gsub(",", "", x))})
  celeb_csv = celeb_csv %>%
    mutate(week_start = week_to_date(nth_week))
  
  # Total emos per week
  total_week = celeb_csv %>%
    select(nth_week, total)
  
  for (i in 0:177) {
    if (!(i %in% total_week$nth_week)) {
      print(i)
      print(celeb)
      total_week = rbind(total_week, c(i, 1))
    }
  }
  
  total_week = total_week %>%
    group_by(nth_week) %>%
    summarize(mean_total = mean(total))
  
  # moving average 15 weeks
  ma15 = roll_mean(total_week$mean_total, 15)
  for (i in 1:14) {
    ma15 = c(0, ma15)
  }
  total_week$ma15 = ma15
  
  ma3 = roll_mean(total_week$mean_total, 3)
  for (i in 1:2) {
    ma3 = c(0, ma3)
  }
  total_week$ma3 = ma3
  
  trend = trendcycle(mstl(total_week$mean_total))
  total_week$trend = as.numeric(trend)
  
  # mark celeb name
  total_week$celeb = as.factor(celeb)
  
  total_week_table = rbind(total_week_table, total_week)
  
  if (length(mean_total_table) == 0) {
    mean_total_table = data.frame(ts(total_week$mean_total))
    ma15_table = data.frame(ts(total_week$ma15[15:178]))
    ma3_table = data.frame(ts(total_week$ma3[15:178]))
    trend_table = data.frame(trend[15:178])
  } else {
    mean_total_table = cbind(mean_total_table, c(ts(total_week$mean_total)))
    ma15_table = cbind(ma15_table, c(ts(total_week$ma15[15:178])))
    ma3_table = cbind(ma3_table, c(ts(total_week$ma3[15:178])))
    trend_table = cbind(trend_table, c(trend[15:178]))
  }
  count = count + 1
}
colnames(mean_total_table) = celeb_list
colnames(ma15_table) = celeb_list
colnames(ma3_table) = celeb_list
colnames(trend_table) = celeb_list

str(total_week_table)
total_week_table = total_week_table %>%
  mutate(week_start = week_to_date(nth_week))

# Group 15 MA Plot
p = ggplot(total_week_table, aes(x = week_start, y = ma15, color = celeb, group=celeb)) +
  labs(color = "Idol", shape = "Idol", x = "Month",
       y = "# of emoticons", title = "15 Week-MA Emoticon Number of Idol Group") + 
  theme_light(base_size = 12) +
  theme(panel.grid.minor = element_blank()) +
  theme(axis.text.x=element_text(angle=60, hjust=1)) +
  scale_x_date(labels = date_format("%Y-%m"), breaks = date_breaks(width = "8 week")) +
  geom_line()
jit = position_jitter(seed = 123, width = 0.1)
p + geom_jitter(aes(color=celeb), size=1, position=jit)

for (i in 1:length(celeb_list)) {
  df1 = data.frame(trend = as.numeric(ma15_table[[i]]), type = "ma15")
  df2 = data.frame(trend = as.numeric(trend_table[[i]]), type = "mstl")
  df = rbind(df1, df2)
  
  df_ = total_week_table %>%
    filter(celeb == celeb_list[i]) %>%
    select(ma15, trend, week_start)
  df1 = data.frame(trend = df_$ma15, week_start = df_$week_start, type = "ma15")[15:178, ]
  df2 = data.frame(trend = df_$trend, week_start = df_$week_start, type = "stl")[15:178, ]
  df = rbind(df1, df2)
  
  p = ggplot(df, aes(x = week_start, y = trend, color = type, group=type)) +
    labs(color = "", shape = "", x = "Month",
         y = "# of emoticons", title = paste(celeb_list[i], "Trend graph")) + 
    theme_light(base_size = 12) +
    theme(panel.grid.minor = element_blank()) +
    theme(axis.text.x=element_text(angle=60, hjust=1)) +
    scale_x_date(labels = date_format("%Y-%m"), breaks = date_breaks(width = "8 week")) +
    geom_line()
  p
  ggsave(paste0(celeb_list[i]," trend.png"))
  
  p = ggplot(df1, aes(x = week_start, y = trend, color = type, group=type)) +
    labs(color = "", shape = "", x = "Month",
         y = "# of emoticons", title = paste(celeb_list[i], "MA15 trend graph")) + 
    theme_light(base_size = 12) +
    theme(panel.grid.minor = element_blank()) +
    theme(axis.text.x=element_text(angle=60, hjust=1)) +
    scale_x_date(labels = date_format("%Y-%m"), breaks = date_breaks(width = "8 week")) +
    geom_line()
  p
  ggsave(paste0(celeb_list[i],"MA15 trend.png"))
  
  p = ggplot(df2, aes(x = week_start, y = trend, color = type, group=type)) +
    labs(color = "", shape = "", x = "Month",
         y = "# of emoticons", title = paste(celeb_list[i], "STL trend graph")) + 
    theme_light(base_size = 12) +
    theme(panel.grid.minor = element_blank()) +
    theme(axis.text.x=element_text(angle=60, hjust=1)) +
    scale_x_date(labels = date_format("%Y-%m"), breaks = date_breaks(width = "8 week")) +
    geom_line()
  p
  ggsave(paste0(celeb_list[i],"STL trend.png"))
}

# Trend decomposition with MSTL
bts_mstl = mstl(mean_total_table$방탄소년단)
plot(trendcycle(bts_mstl))
plot(ma15_table$방탄소년단)
plot(bts_mstl)
exo_mstl = mstl(mean_total_table$엑소)
plot(exo_mstl)
blackpink_mstl = mstl(mean_total_table$블랙핑크)
plot(blackpink_mstl)
twice_mstl = mstl(mean_total_table$트와이스)
plot(twice_mstl)
redvelvet_mstl = mstl(mean_total_table$레드벨벳)
plot(redvelvet_mstl)
