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

celeb_list = c('방탄소년단', '방탄소년단 RM', '방탄소년단 진', '방탄소년단 슈가', '방탄소년단 제이홉', '방탄소년단 지민', '방탄소년단 뷔', '방탄소년단 정국')
#celeb_list = c('방탄소년단', '엑소', '블랙핑크', '레드벨벳', '트와이스')
#celeb_list = c('방탄소년단')

total_week_table = data.frame()
mean_total_table = data.frame()
ma15_table = data.frame()
ma3_table = data.frame()
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
  
  # mark celeb name
  total_week$celeb = as.factor(celeb)
  
  total_week_table = rbind(total_week_table, total_week)

  if (length(mean_total_table) == 0) {
    mean_total_table = data.frame(ts(total_week$mean_total))
    ma15_table = data.frame(ts(total_week$ma15[15:178]))
    ma3_table = data.frame(ts(total_week$ma3[15:178]))
  } else {
    mean_total_table = cbind(mean_total_table, c(ts(total_week$mean_total)))
    ma15_table = cbind(ma15_table, c(ts(total_week$ma15[15:178])))
    ma3_table = cbind(ma3_table, c(ts(total_week$ma3[15:178])))
  }
  count = count + 1
}
colnames(mean_total_table) = c("bts", "rm", "jin", "sugar", "jhope", "jimin", "v", "jungkook")
colnames(ma15_table) = c("bts", "rm", "jin", "sugar", "jhope", "jimin", "v", "jungkook")
colnames(ma3_table) = c("bts", "rm", "jin", "sugar", "jhope", "jimin", "v", "jungkook")

str(total_week_table)
total_week_table = total_week_table %>%
  mutate(week_start = week_to_date(nth_week))

# Member, Group 15 MA Plot
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

# Member-Group Regression
png(filename="rm_bts_plot.png")
rm_bts = tslm(rm ~ bts, data=mean_total_table)
plot(mean_total_table$bts,
     mean_total_table$rm,
     xlab = "BTS total emoticon",
     ylab = "RM total emoticon",
     main = "RM - BTS")
abline(rm_bts)
summary(rm_bts)
checkresiduals(rm_bts)
dev.off()

png(filename="jin_bts_plot.png")
jin_bts = tslm(jin ~ bts, data=mean_total_table)
plot(ma3_table$bts,
     ma3_table$jin,
     xlab = "BTS total emoticon",
     ylab = "JIN total emoticon",
     main = "JIN - BTS")
abline(jin_bts)
summary(jin_bts)
dev.off()

png(filename="sugar_bts_plot.png")
sugar_bts = tslm(sugar ~ bts, data=mean_total_table)
plot(ma3_table$bts,
     ma3_table$sugar,
     ylab = "SUGAR total emoticon",
     xlab = "BTS total emoticon",
     main = "SUGAR - BTS")
abline(sugar_bts)
summary(sugar_bts)
dev.off()

png(filename="jhope_bts_plot.png")
jhope_bts = tslm(jhope ~ bts, data=mean_total_table)
plot(ma3_table$bts,
     ma3_table$jhope,
     ylab = "JHOPE total emoticon",
     xlab = "BTS total emoticon",
     main = "JHOPE - BTS")
abline(jhope_bts)
summary(jhope_bts)
dev.off()

png(filename="jimin_bts_plot.png")
jimin_bts = tslm(jimin ~ bts, data=mean_total_table)
plot(ma3_table$bts,
     ma3_table$jimin,
     ylab = "JIMIN total emoticon",
     xlab = "BTS total emoticon",
     main = "JIMIN - BTS")
abline(jimin_bts)
summary(jimin_bts)
dev.off()

png(filename="v_bts_plot.png")
v_bts = tslm(v ~ bts, data=mean_total_table)
plot(ma3_table$bts,
     ma3_table$v,
     ylab = "V total emoticon",
     xlab = "BTS total emoticon",
     main = "V - BTS")
abline(v_bts)
summary(v_bts)
dev.off()

png(filename="jungkook_bts_plot.png")
jungkook_bts = tslm(jungkook ~ bts, data=mean_total_table)
plot(ma3_table$bts,
     ma3_table$jungkook,
     ylab = "JUNGKOOK total emoticon",
     xlab = "BTS total emoticon",
     main = "JUNGKOOK - BTS")
abline(jungkook_bts)
summary(jungkook_bts)
dev.off()

png(filename="scatterplot_matrix.png")
mean_total_table %>%
  GGally::ggpairs()
dev.off()

# BTS ~ MEMBERS with first-difference method
mean_total_table2 = data.frame(bts = diff(mean_total_table$bts))
str(mean_total_table)
mean_total_table2$rm = diff(mean_total_table$rm)
mean_total_table2$jin = diff(mean_total_table$jin)
mean_total_table2$sugar = diff(mean_total_table$sugar)
mean_total_table2$jhope = diff(mean_total_table$jhope)
mean_total_table2$jimin = diff(mean_total_table$jimin)
mean_total_table2$v = diff(mean_total_table$v)
mean_total_table2$jungkook = diff(mean_total_table$jungkook)

plot(mean_total_table2)
#View(mean_total_table2)

mean_total_table2
bts_member_lm = tslm(bts ~ rm + jin + sugar + jhope + jimin + v + jungkook, data=mean_total_table2)
coef(bts_member_lm)
summary(bts_member_lm)
checkresiduals(bts_member_lm)
  # Prediction plot
df1 = data.frame(total = as.numeric(mean_total_table$bts), data = "observed", nth_week = 0:177)
df2 = data.frame(total = predict(bts_member_lm, mean_total_table[,-1]), data = "predict", nth_week = 0:177)
df = rbind(df1, df2)
df = df %>%
  mutate(week_start = week_to_date(nth_week))

p = ggplot(df, aes(x = week_start, y = total, color = data, group=data)) +
  labs(color = "", shape = "", x = "Month",
       y = "# of emoticons", title = " Regression using first-difference method") + 
  theme_light(base_size = 12) +
  theme(panel.grid.minor = element_blank()) +
  theme(axis.text.x=element_text(angle=60, hjust=1)) +
  scale_x_date(labels = date_format("%Y-%m-%d"), breaks = date_breaks(width = "8 week")) +
  geom_line()
p
ggsave("1st_dff_bts-members.png")

# BTS ~ MEMBERS with STL
bts_mstl = mstl(mean_total_table$bts)
plot(bts_mstl)
mean_total_table3 = data.frame(mean_total_table$bts, bts_mstl) %>%
  mutate(bts = mean_total_table.bts - Trend) %>%
  select(bts)
str(mean_total_table3)
mean_total_table3$rm = data.frame(mean_total_table$rm, mstl(mean_total_table$rm)) %>%
  mutate(rm = mean_total_table.rm - Trend) %>%
  .$rm %>%
  ts()
mean_total_table3$jin = data.frame(mean_total_table$jin, mstl(mean_total_table$jin)) %>%
  mutate(jin = mean_total_table.jin - Trend) %>%
  .$jin %>%
  ts()
mean_total_table3$sugar = data.frame(mean_total_table$sugar, mstl(mean_total_table$sugar)) %>%
  mutate(sugar = mean_total_table.sugar - Trend) %>%
  .$sugar %>%
  ts()
mean_total_table3$jhope = data.frame(mean_total_table$jhope, mstl(mean_total_table$jhope)) %>%
  mutate(jhope = mean_total_table.jhope - Trend) %>%
  .$jhope %>%
  ts()
mean_total_table3$jimin = data.frame(mean_total_table$jimin, mstl(mean_total_table$jimin)) %>%
  mutate(jimin = mean_total_table.jimin - Trend) %>%
  .$jimin %>%
  ts()
mean_total_table3$v = data.frame(mean_total_table$v, mstl(mean_total_table$v)) %>%
  mutate(v = mean_total_table.v - Trend) %>%
  .$v %>%
  ts()
mean_total_table3$jungkook = data.frame(mean_total_table$jungkook, mstl(mean_total_table$jungkook)) %>%
  mutate(jungkook = mean_total_table.jungkook - Trend) %>%
  .$jungkook %>%
  ts()

bts_member_lm = tslm(bts ~ rm + jin + jhope + v + jungkook + sugar + jimin, data=mean_total_table3)
summary(bts_member_lm)
coef(bts_member_lm)
checkresiduals(bts_member_lm)

df1 = data.frame(total = as.numeric(mean_total_table$bts), data = "observed", nth_week = 0:177)
df3 = data.frame(total = predict(bts_member_lm, mean_total_table[,-1]), data = "predict", nth_week = 0:177)
df = rbind(df1, df3)
df = df %>%
  mutate(week_start = week_to_date(nth_week))

p = ggplot(df, aes(x = week_start, y = total, color = data, group=data)) +
  labs(color = "", shape = "", x = "Month",
       y = "# of emoticons", title = "Regression using stl method") + 
  theme_light(base_size = 12) +
  theme(panel.grid.minor = element_blank()) +
  theme(axis.text.x=element_text(angle=60, hjust=1)) +
  scale_x_date(labels = date_format("%Y-%m-%d"), breaks = date_breaks(width = "8 week")) +
  geom_line()
p
ggsave("stl-members.png")


# BTS ETS
bts_ets = ets(mean_total_table$bts, model="ZZZ", damped=NULL, alpha=NULL, beta=NULL, gamma=NULL,
              phi=NULL, lambda=NULL, biasadj=FALSE, additive.only=FALSE,
              restrict=TRUE, allow.multiplicative.trend=FALSE)
coef(bts_ets)
accuracy(bts_ets)
autoplot(bts_ets)
autoplot(simulate(bts_ets))
autoplot(mean_total_table$bts)

bts_ets %>%
  forecast(h = 5) %>%
  autoplot()