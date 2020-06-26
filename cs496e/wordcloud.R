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

tbl_titlecount0 <- tbl_title %>% # tbl_TEXTFILE µ¥ÀÌÅÍ »ç¿ë 
  mutate(noun=str_match(value, '([°¡-ÆR]+)/N')[,2]) %>% # ¸í»çÇü(/N) ÀÚ·á¸¸ °ñ¶ó³½ ÈÄ /N »©°í ÀúÀå 
  na.omit %>% # ºñ¾îÀÖ´Â °ª(NA) Á¦¿Ü 
  filter(str_length(noun)>=2) %>%  # ÀÇ¹Ì°¡ ¾ø´Â ÀÇÁ¸¸í»ç¸¦ Á¦¿Ü
  count(noun, sort=TRUE)

View(tbl_titlecount0)
# ÀÇ¹Ì¾ø´Â ´Ü¾î Á¦¿Ü
tbl_titlecount1 <- tbl_titlecount0 %>% filter(n>=5) %>% filter(!noun %in% c(
  "±âÀÚ","¾ï¿ø","ÀÌ³¯", "¾ïºä", "ºê·£µåÆòÆÇ"
))

tbl_titlecount2 <- tbl_titlecount1[1:200,]
wordcloud2(tbl_titlecount2, fontFamily = "Malgun Gothic", size = 5, minRotation=0, maxRotation = 0)

# -------------------------------------------------------------------------------------
