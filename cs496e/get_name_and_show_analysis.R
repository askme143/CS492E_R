library(dplyr)

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

get_name = function(name) {
  celeb_csv = read.csv(paste0("../tmp/ano", name, "_data.csv"), encoding="CP949")
  return(celeb_csv)
}

name = readline(prompt = "Who do you want to search? ")
celeb_csv = read.csv(paste0("../tmp/ano", name, "_data.csv"), encoding="CP949")
# celeb_df = data.frame(matrix(unlist(celeb_csv), ncol=21))
# celeb_csv = as.data.frame(celeb_csv)
colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "is_pos")
# colnames(celeb_df) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "is_pos")

celeb_csv$total <- as.integer(celeb_csv$total)
celeb_csv$like <- as.integer(celeb_csv$like)
celeb_csv$angry <- as.integer(celeb_csv$angry)

# transform(celeb_csv, total=as.integer(total), like=as.integer(like), angry=as.integer(angry))

image_ch = celeb_csv %>%
  select(nth_week, total, is_pos) %>%
  filter(total > 30) %>%
  group_by(nth_week) %>%
  summarize(total_pos = sum(abs(is_pos)), pos = sum(is_pos), pos_ratio = pos/total_pos)
# plot(image_ch$nth_week, image_ch$pos_ratio, type='o', main="exo 긍정/부정 기사 비율", xlab="주", ylab="긍정/전체")
# View(image_ch)

# extract negative news list
neg_news_list = celeb_csv %>%
  filter(total > 30, is_pos == -1) %>%
  summarize(title, nth_week, year, month, date, total, url)

# Positive, negative emotions per week
pos_neg_week = celeb_csv %>%
  filter(total > 30) %>%
  select(title, nth_week, total, sad, surprise, angry) %>%
  mutate(negative = as.numeric(sad + surprise + angry),
         positive = as.numeric(total - negative)) %>%
  # mutate(positive = total - sad - surprise - angry,
  #       negative = total - positive) %>%
  group_by(nth_week) %>%
  summarize(title, neg_ratio = 1-negative/total, total, positive, negative)

neg_emo_list = pos_neg_week %>%
  filter(neg_ratio < 0.6) %>%
  summarize(title, nth_week, neg_ratio)

par(mfrow=c(2,1))
plot(image_ch$nth_week, image_ch$pos_ratio, type='o', main=paste(name," 긍정/부정 기사 비율"), xlab="주", ylab="긍정/전체")  
plot(pos_neg_week$nth_week, pos_neg_week$neg_ratio, type='o', main=paste(name," 여론 결과"), xlab="", ylab="호감도")
# lines(pos_neg_week$nth_week, pos_neg_week$neg_ratio, type='o', col="red")

# Positive ratio per week
ratio_week = pos_neg_week %>%
  mutate(ratio = pos/(pos+neg)) %>%
  select (nth_week, ratio)
plot(ratio_week)

# Total emos per week
total_week = celeb_csv %>%
  select(nth_week, total) %>%
  filter(total>30) %>%
  group_by(nth_week) %>%
  summarize(mean_total = mean(total))
plot(total_week)

emos = celeb_csv %>%
  filter(total>30) %>%
  .[10:19]
pie(x = apply(emos, 2, mean))


