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
 plot(image_ch$nth_week, image_ch$pos_ratio, type='o', main="exo ±àÁ¤/ºÎÁ¤ ±â»ç ºñÀ²", xlab="ÁÖ", ylab="±àÁ¤/ÀüÃ¼")
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
plot(image_ch$nth_week, image_ch$pos_ratio, type='o', main=paste(name," ±àÁ¤/ºÎÁ¤ ±â»ç ºñÀ²"), xlab="ÁÖ", ylab="±àÁ¤/ÀüÃ¼", ylim=c(0,1))  
# graph2
plot(pos_neg_week$nth_week, pos_neg_week$neg_ratio, type='o', main=paste(name," ¿©·Ð °á°ú"), xlab="ÁÖ", ylab="È£°¨µµ")
# graph3
plot(pos_neg_graph$nth_week, pos_neg_graph$sad_ratio, type='o', col="blue", main=paste(name," ºÎÁ¤ °¨Á¤ º¯È­"), xlab="ÁÖ", ylab="ºñÀ²")
lines(pos_neg_graph$nth_week, pos_neg_graph$sur_ratio, type='o', col="green")
lines(pos_neg_graph$nth_week, pos_neg_graph$ang_ratio, type='o', col="red")
# graph4
pie(x = apply(neg_emo, 2, mean), main=paste(name," ºÎÁ¤°¨Á¤ ºñÀ² ºÐ¼®"))

View(neg_emo_list)

# ------------------------------------------------

data = as.character(celeb_csv$title)

tbl_title = data %>%
  SimplePos09 %>%
  melt %>%
  as_tibble %>%
  select(3, 1)

tbl_titlecount0 <- tbl_title %>% # tbl_TEXTFILE µ¥ÀÌÅÍ »ç¿ë 
  mutate(noun=str_match(value, '([°¡-ÆR]+)/N')[,2]) %>% # ¸í»çÇü(/N) ÀÚ·á¸¸ °ñ¶ó³½ ÈÄ /N »©°í ÀúÀå 
  na.omit %>% # ºñ¾îÀÖ´Â °ª(NA) Á¦¿Ü 
  filter(str_length(noun)>=2) %>%  # ÀÇ¹Ì°¡ ¾ø´Â ÀÇÁ¸¸í»ç¸¦ Á¦¿Ü
  count(noun, sort=TRUE)

#head(tbl_titlecount0)
# ÀÇ¹Ì¾ø´Â ´Ü¾î Á¦¿Ü
tbl_titlecount1 <- tbl_titlecount0 %>% filter(n>=5) %>% filter(!noun %in% c(
  "±âÀÚ","¾ï¿ø","ÀÌ³¯", "¾ïºä", "ºê·£µåÆòÆÇ"
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


