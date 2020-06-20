library(dplyr)

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

celeb_list = read.csv("직업군.csv", header = T)

for (celeb in celeb_list$entertainer){
  if (celeb == "")
    break
  celeb_csv = read.csv(paste0("../tmp/ano", celeb, "_data.csv"), sep=",")
  colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "pos_article")
  celeb_csv[9:19] = lapply(celeb_csv[9:19], function(x){as.numeric(gsub(",", "", x))})
  celeb_csv = celeb_csv %>%
    mutate(week_start = week_to_date(nth_week))
  
  # Total emos per week
  total_week = celeb_csv %>%
    select(nth_week, total) %>%
    #filter(total>30) %>%
    group_by(nth_week) %>%
    summarize(mean_total = mean(total))
  png(filename=paste0("entertainer_plot/","주간관심도_", celeb, ".png"))
  plot(total_week, main = paste(celeb, "주간 관심도"), ylim=c(30, 6000))
  dev.off()
  
  emos = celeb_csv %>%
    filter(total>30) %>%
    .[10:19]
  pie(x = apply(emos, 2, mean))
  
  # Positive, negative emotions per week
  pos_neg_week = celeb_csv %>%
    #filter(total>30) %>%
    mutate(positive = ifelse(pos_article==1, total-sad-surprise-angry, sad+surprise+angry),
           negative = total - positive) %>%
    select(nth_week, positive, negative, total) %>%
    mutate(ratio = positive/total) %>%
    select(nth_week, ratio) %>%
    group_by(nth_week) %>%
    summarize(ratio = mean(ratio))
  
  # Positive ratio per week
  ratio_week = pos_neg_week %>%
    select (nth_week, ratio)
  png(filename=paste0("entertainer_plot/","주간긍정비율_", celeb, ".png"))
  plot(ratio_week, main=paste(celeb, "주간 긍정 비율"), ylim = c(0, 1))
  dev.off()
  
  total_week_ts = total_week
  for (i in 0:51) {
    if (!(i %in% total_week$nth_week)) {
      total_week_ts = rbind(total_week_ts, c(i, 0))
    }
  }
}

