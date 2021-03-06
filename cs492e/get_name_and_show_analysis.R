library(dplyr)
library(ggplot2)
library(reshape2)
library(stringr)
library(memoise)
library(KoNLP)
library(tidyverse)
library(wordcloud2)
library(rJava) 

useNIADic()

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

get_name = function(name) {
  celeb_csv = read.csv(paste0("../tmp/ano", name, "_data.csv"), encoding="CP949")
  return(celeb_csv)
}

result = list()

name = readline(prompt = "Who do you want to search? ")
celeb_csv = read.csv(paste0("../tmp/ano", name, "_data.csv"))#, encoding="CP949")
colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "is_pos")
#colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")

celeb_csv$total <- as.integer(celeb_csv$total)
celeb_csv$like <- as.integer(celeb_csv$like)
celeb_csv$sad <- as.integer(celeb_csv$sad)
celeb_csv$angry <- as.integer(celeb_csv$angry)
celeb_csv$surpise <- as.integer(celeb_csv$surprise)

# transform(celeb_csv, total=as.integer(total), like=as.integer(like), angry=as.integer(angry))

image_ch = celeb_csv %>%
  select(nth_week, total, is_pos) %>%
  filter(total > 30) %>%
  group_by(nth_week) %>%
  summarize(total_pos = sum(abs(is_pos)), pos = sum(is_pos), pos_ratio = pos/total_pos)
 plot(image_ch$nth_week, image_ch$pos_ratio, type='o', main="exo 긍정/부정 기사 비율", xlab="주", ylab="긍정/전체")
 View(image_ch)

# extract negative news list
# neg_news_list = celeb_csv %>%
#   filter(total > 30, is_pos == -1) %>%
#   summarize(title, nth_week, year, month, date, total, url)

# Positive, negative emotions per week
pos_neg_week = celeb_csv %>%
  filter(total > 30) %>%
  select(title, nth_week, total, sad, surprise, angry) %>%
  mutate(negative = as.numeric(sad + surprise + angry),
         positive = as.numeric(total - negative)) %>%
  # mutate(positive = total - sad - surprise - angry,
  #       negative = total - positive) %>%
  group_by(nth_week) %>%
  summarize(title, neg_ratio = 1-negative/total, sad_ratio = sad/total, sur_ratio = surprise/total, ang_ratio = angry/total, total, positive, negative, sad, surprise, angry)

pos_neg_graph = pos_neg_week %>%
  filter(neg_ratio < 0.6)

neg_emo_list = pos_neg_week %>%
  filter(neg_ratio < 0.6) %>%
  rowwise() %>%
  mutate(maxval = max(sad, surprise, angry)) %>%
  mutate(newschar = case_when(
    sad == maxval ~ "sad",
    surprise == maxval ~ "surprise",
    angry == maxval ~ "angry",
    TRUE ~ NA_character_)
  ) %>%
  summarize(title, nth_week, neg_ratio, sad, surprise, angry, maxval, newschar)

# list.append(result, neg_emo_list)
result = append(result, neg_emo_list)

neg_emo = neg_emo_list %>%
  .[4:6]
layout(matrix(c(1,2,3,4), 2, 2, byrow=T))
# graph1
plot(image_ch$nth_week, image_ch$pos_ratio, type='o', main=paste(name," 긍정/부정 기사 비율"), xlab="주", ylab="긍정/전체", ylim=c(0,1))  
# graph2
plot(pos_neg_week$nth_week, pos_neg_week$neg_ratio, type='o', main=paste(name," 여론 결과"), xlab="주", ylab="호감도")
# graph3
plot(pos_neg_graph$nth_week, pos_neg_graph$sad_ratio, type='o', col="blue", main=paste(name," 부정 감정 변화"), xlab="주", ylab="비율")
lines(pos_neg_graph$nth_week, pos_neg_graph$sur_ratio, type='o', col="green")
lines(pos_neg_graph$nth_week, pos_neg_graph$ang_ratio, type='o', col="red")
# graph4
pie(x = apply(neg_emo, 2, mean), main=paste(name," 부정감정 비율 분석"))

View(neg_emo_list)

# ------------------------------------------------

data = as.character(celeb_csv$title)

tbl_title = data %>%
  SimplePos09 %>%
  melt %>%
  as_tibble %>%
  select(3, 1)

tbl_titlecount0 <- tbl_title %>% # tbl_TEXTFILE 데이터 사용 
  mutate(noun=str_match(value, '([가-힣]+)/N')[,2]) %>% # 명사형(/N) 자료만 골라낸 후 /N 빼고 저장 
  na.omit %>% # 비어있는 값(NA) 제외 
  filter(str_length(noun)>=2) %>%  # 의미가 없는 의존명사를 제외
  count(noun, sort=TRUE)

#head(tbl_titlecount0)
# 의미없는 단어 제외
tbl_titlecount1 <- tbl_titlecount0 %>% filter(n>=5) %>% filter(!noun %in% c(
  "기자","억원","이날", "억뷰", "브랜드평판"
))

tbl_titlecount2 <- tbl_titlecount1[1:200,]

wordcloud2(tbl_titlecount2, fontFamily = "Malgun Gothic", size = 5, minRotation=0, maxRotation = 0)

# ------------------------------------------------------------

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


