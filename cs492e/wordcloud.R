library(dplyr)
library(reshape2)
library(KoNLP)
library(tidyverse)
library(wordcloud2)
library(rJava) 

name = readline(prompt = "Who do you want to search? ")
celeb_csv = read.csv(paste0("../tmp/", name, "_data.csv"), encoding="CP949")
#colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "is_pos")
colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")

celeb_csv$total <- as.integer(celeb_csv$total)
celeb_csv$like <- as.integer(celeb_csv$like)
celeb_csv$sad <- as.integer(celeb_csv$sad)
celeb_csv$angry <- as.integer(celeb_csv$angry)
celeb_csv$surpise <- as.integer(celeb_csv$surprise)

pos_neg_week = celeb_csv %>%
  filter(total > 30) %>%
  select(title, nth_week, total, sad, surprise, angry) %>%
  mutate(negative = as.numeric(sad + surprise + angry),
         positive = as.numeric(total - negative)) %>%
  group_by(nth_week) %>%
  summarize(title, neg_ratio = 1-negative/total, sad_ratio = sad/total, sur_ratio = surprise/total, ang_ratio = angry/total, total, positive, negative, sad, surprise, angry)

neg_emo_list = pos_neg_week %>%
  filter(neg_ratio < 0.7) %>%
  rowwise() %>%
  mutate(maxval = max(sad, surprise, angry)) %>%
  mutate(newschar = case_when(
    sad == maxval ~ "sad",
    surprise == maxval ~ "surprise",
    angry == maxval ~ "angry",
    TRUE ~ NA_character_)
  ) %>%
  summarize(title, nth_week, neg_ratio, sad, surprise, angry, maxval, newschar)

View(neg_emo_list)

data = as.character(neg_emo_list$title)
#data = as.character(celeb_csv$title)

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

View(tbl_titlecount0)
# 의미없는 단어 제외
tbl_titlecount1 <- tbl_titlecount0 %>% filter(n>=5) %>% filter(!noun %in% c(
  "기자","억원","이날", "억뷰", "브랜드평판"
))

tbl_titlecount2 <- tbl_titlecount1[1:200,]
wordcloud2(tbl_titlecount2, fontFamily = "Malgun Gothic", size = 5, minRotation=0, maxRotation = 0)

# -------------------------------------------------------------------------------------
