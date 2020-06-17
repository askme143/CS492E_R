library(dplyr)

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

celeb_list = read.csv("직업군.csv", header = T)

for (celeb in celeb_list$singer){
  celeb_csv = read.csv(paste0("data/", celeb, "_data.csv"))
  colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")
  celeb_csv[9:19] = sapply(celeb_csv[9:19], as.numeric)
  celeb_csv = celeb_csv %>%
    mutate(week_start = week_to_date(nth_week))
  
  # Total emos per week
  total_week = celeb_csv %>%
    select(month, total) %>%
    filter(total>30) %>%
    group_by(month) %>%
    summarize(mean_total = mean(total))
  png(filename=paste0("singer_plot/","월간관심도_", celeb, ".png"))
  plot(total_week, main = paste(celeb, "월간 관심도"), ylim=c(30, 1000))
  dev.off()
  
  emos = celeb_csv %>%
    filter(total>30) %>%
    .[10:19]
  pie(x = apply(emos, 2, mean))
  
  # Positive, negative emotions per week
  pos_neg_week = celeb_csv %>%
    filter(total>30) %>%
    mutate(positive = total-sad-surprise-angry,
           negative = total - positive) %>%
    select(month, positive, negative, total) %>%
    mutate(ratio = positive/total) %>%
    select(month, ratio) %>%
    group_by(month) %>%
    summarize(ratio = mean(ratio))
  
  # Positive ratio per week
  ratio_week = pos_neg_week %>%
    select (month, ratio)
  png(filename=paste0("singer_plot/","월간긍정비율_", celeb, ".png"))
  plot(ratio_week, main=paste(celeb, "월간 긍정 비율"), ylim = c(0, 1))
  dev.off()
}

