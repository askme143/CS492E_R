library(dplyr)

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

celeb_list = read.csv("직업군.csv", header = T)
{
actor_statistics = data.frame()

for (celeb in celeb_list$actor){
  celeb_csv = read.csv(paste0("../tmp/ano", celeb, "_data.csv"), encoding="CP949")
  colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "pos_article")
  celeb_csv[9:19] = sapply(celeb_csv[9:19], as.numeric)
  celeb_csv = celeb_csv %>%
    mutate(week_start = week_to_date(nth_week))
  
  # Total emos per week
  total_week = celeb_csv %>%
    select(nth_week, total) %>%
    filter(total>30) %>%
    group_by(nth_week) %>%
    summarize(mean_total = mean(total))
  #png(filename=paste0("actor_plot_2/","주간관심도_", celeb, ".png"))
  #plot(total_week, main = paste(celeb, "주간 관심도"), ylim=c(30, 1000))
  #dev.off()
  
  total_avg = mean(total_week$mean_total)
  total_sd = sd(total_week$mean_total)
  
  emos = celeb_csv %>%
    filter(total>30) %>%
    .[10:19]
  pie(x = apply(emos, 2, mean))
  
  # Positive, negative emotions per week
  pos_neg_week = celeb_csv %>%
    filter(total>30) %>%
    mutate(positive = ifelse(pos_article==1, total-sad-surprise-angry, sad+surprise+angry) ,
           negative = total - positive) %>%
    select(nth_week, positive, negative, total) %>%
    mutate(ratio = positive/total) %>%
    select(nth_week, ratio) %>%
    group_by(nth_week) %>%
    summarize(ratio = mean(ratio))

  ratio_avg = mean(pos_neg_week$ratio)
  ratio_sd = sd(pos_neg_week$ratio)
  row = list(total_avg, total_sd, ratio_avg, ratio_sd)
  actor_statistics = rbind(actor_statistics, row)
  
  # Positive ratio per week
  ratio_week = pos_neg_week %>%
    select (nth_week, ratio)
  #png(filename=paste0("actor_plot_2/","주간긍정비율_", celeb, ".png"))
  #plot(ratio_week, main=paste(celeb, "주간 긍정 비율"), ylim = c(0, 1))
  #dev.off()
}
colnames(actor_statistics)<- c("total_avg", "total_sd", "ratio_avg", "ratio_sd")
}
plot(actor_statistics$total_avg, ylim = c(30, 500), main="배우 관심도 평균", xlab="배우#")
plot(actor_statistics$total_sd, ylim = c(30, 500), main="배우 관심도 표준편차")
plot(actor_statistics$ratio_avg, ylim = c(0.5, 1), main="배우 긍정 비율 평균")
plot(actor_statistics$ratio_sd, ylim = c(0, 1), main="배우 긍정 비율 표준편차")

{
idol_statistics = data.frame()

for (celeb in celeb_list$idol){
  if (celeb=="에버글로우") {
    break
  }
  #celeb_csv = read.csv(paste0("../tmp/ano", celeb, "_data.csv"), sep = ",")
  celeb_csv = read.csv(paste0("data/", celeb, "_data.csv"))
  #colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "pos_article")
  colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")
  celeb_csv[9:19] = sapply(celeb_csv[9:19], as.numeric)
  celeb_csv = celeb_csv %>%
    mutate(week_start = week_to_date(nth_week))
  
  # Total emos per week
  total_week = celeb_csv %>%
    select(nth_week, total) %>%
    filter(total>30) %>%
    group_by(nth_week) %>%
    summarize(mean_total = mean(total))
  #png(filename=paste0("actor_plot_2/","주간관심도_", celeb, ".png"))
  #plot(total_week, main = paste(celeb, "주간 관심도"), ylim=c(30, 1000))
  #dev.off()
  
  
  emos = celeb_csv %>%
    filter(total>30) %>%
    .[10:19]
  pie(x = apply(emos, 2, mean))
  
  # Positive, negative emotions per week
  pos_neg_week = celeb_csv %>%
    filter(total>30) %>%
    #mutate(positive = ifelse(pos_article==1, total-sad-surprise-angry, sad+surprise+angry) ,
    mutate(positive = total-sad-surprise-angry,
           negative = total - positive) %>%
    select(nth_week, positive, negative, total) %>%
    mutate(ratio = positive/total) %>%
    select(nth_week, ratio) %>%
    group_by(nth_week) %>%
    summarize(ratio = mean(ratio))
  
  total_avg = mean(total_week$mean_total)
  total_sd = sd(total_week$mean_total)
  ratio_avg = mean(pos_neg_week$ratio)
  ratio_sd = sd(pos_neg_week$ratio)
  row = list(total_avg, total_sd, ratio_avg, ratio_sd)
  idol_statistics = rbind(idol_statistics, row)
  
  # Positive ratio per week
  ratio_week = pos_neg_week %>%
    select (nth_week, ratio)
  #png(filename=paste0("actor_plot_2/","주간긍정비율_", celeb, ".png"))
  #plot(ratio_week, main=paste(celeb, "주간 긍정 비율"), ylim = c(0, 1))
  #dev.off()
}
colnames(idol_statistics)<- c("total_avg", "total_sd", "ratio_avg", "ratio_sd")
}

plot(idol_statistics$total_avg, ylim = c(30, 500), main="아이돌 관심도 평균", xlab="배우#")
plot(idol_statistics$total_sd, ylim = c(30, 500), main="아이돌 관심도 표준편차")
plot(idol_statistics$ratio_avg, ylim = c(0.5, 1), main="아이돌 긍정 비율 평균")
plot(idol_statistics$ratio_sd, ylim = c(0, 1), main="아이돌 긍정 비율 표준편차")

{
  singer_statistics = data.frame()
  
  for (celeb in celeb_list$singer){
    if (celeb=="") {
      break
    }
    celeb_csv = read.csv(paste0("../tmp/ano", celeb, "_data.csv"), sep = ",")
    #celeb_csv = read.csv(paste0("data/", celeb, "_data.csv"))
    colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "pos_article")
    #colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")
    celeb_csv[9:19] = sapply(celeb_csv[9:19], as.numeric)
    celeb_csv = celeb_csv %>%
      mutate(week_start = week_to_date(nth_week))
    
    # Total emos per week
    total_week = celeb_csv %>%
      select(nth_week, total) %>%
      filter(total>30) %>%
      group_by(nth_week) %>%
      summarize(mean_total = mean(total))
    #png(filename=paste0("actor_plot_2/","주간관심도_", celeb, ".png"))
    #plot(total_week, main = paste(celeb, "주간 관심도"), ylim=c(30, 1000))
    #dev.off()
    
    
    emos = celeb_csv %>%
      filter(total>30) %>%
      .[10:19]
    pie(x = apply(emos, 2, mean))
    
    # Positive, negative emotions per week
    pos_neg_week = celeb_csv %>%
      filter(total>30) %>%
      #mutate(positive = ifelse(pos_article==1, total-sad-surprise-angry, sad+surprise+angry) ,
      mutate(positive = total-sad-surprise-angry,
             negative = total - positive) %>%
      select(nth_week, positive, negative, total) %>%
      mutate(ratio = positive/total) %>%
      select(nth_week, ratio) %>%
      group_by(nth_week) %>%
      summarize(ratio = mean(ratio))
    
    total_avg = mean(total_week$mean_total)
    total_sd = sd(total_week$mean_total)
    ratio_avg = mean(pos_neg_week$ratio)
    ratio_sd = sd(pos_neg_week$ratio)
    row = list(total_avg, total_sd, ratio_avg, ratio_sd)
    singer_statistics = rbind(singer_statistics, row)
    
    # Positive ratio per week
    ratio_week = pos_neg_week %>%
      select (nth_week, ratio)
    #png(filename=paste0("actor_plot_2/","주간긍정비율_", celeb, ".png"))
    #plot(ratio_week, main=paste(celeb, "주간 긍정 비율"), ylim = c(0, 1))
    #dev.off()
  }
  colnames(singer_statistics)<- c("total_avg", "total_sd", "ratio_avg", "ratio_sd")
}

plot(singer_statistics$total_avg, ylim = c(30, 500), main="가수 관심도 평균", xlab="배우#")
plot(singer_statistics$total_sd, ylim = c(30, 500), main="가수 관심도 표준편차")
plot(singer_statistics$ratio_avg, ylim = c(0.5, 1), main="가수 긍정 비율 평균")
plot(singer_statistics$ratio_sd, ylim = c(0, 1), main="가수 긍정 비율 표준편차")

{
  entertainer_statistics = data.frame()
  
  for (celeb in celeb_list$entertainer){
    if (celeb=="") {
      break
    }
    celeb_csv = read.csv(paste0("../tmp/ano", celeb, "_data.csv"), sep = ",")
    colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "pos_article")
    celeb_csv[9:19] = sapply(celeb_csv[9:19], as.numeric)
    celeb_csv = celeb_csv %>%
      mutate(week_start = week_to_date(nth_week))
    
    # Total emos per week
    total_week = celeb_csv %>%
      select(nth_week, total) %>%
      filter(total>30) %>%
      group_by(nth_week) %>%
      summarize(mean_total = mean(total))
    #png(filename=paste0("actor_plot_2/","주간관심도_", celeb, ".png"))
    #plot(total_week, main = paste(celeb, "주간 관심도"), ylim=c(30, 1000))
    #dev.off()
    
    
    emos = celeb_csv %>%
      filter(total>30) %>%
      .[10:19]
    pie(x = apply(emos, 2, mean))
    
    # Positive, negative emotions per week
    pos_neg_week = celeb_csv %>%
      filter(total>30) %>%
      #mutate(positive = ifelse(pos_article==1, total-sad-surprise-angry, sad+surprise+angry) ,
      mutate(positive = total-sad-surprise-angry,
             negative = total - positive) %>%
      select(nth_week, positive, negative, total) %>%
      mutate(ratio = positive/total) %>%
      select(nth_week, ratio) %>%
      group_by(nth_week) %>%
      summarize(ratio = mean(ratio))
    
    total_avg = mean(total_week$mean_total)
    total_sd = sd(total_week$mean_total)
    ratio_avg = mean(pos_neg_week$ratio)
    ratio_sd = sd(pos_neg_week$ratio)
    row = list(total_avg, total_sd, ratio_avg, ratio_sd)
    entertainer_statistics = rbind(entertainer_statistics, row)
    
    # Positive ratio per week
    ratio_week = pos_neg_week %>%
      select (nth_week, ratio)
    #png(filename=paste0("actor_plot_2/","주간긍정비율_", celeb, ".png"))
    #plot(ratio_week, main=paste(celeb, "주간 긍정 비율"), ylim = c(0, 1))
    #dev.off()
  }
  colnames(entertainer_statistics)<- c("total_avg", "total_sd", "ratio_avg", "ratio_sd")
}

plot(entertainer_statistics$total_avg, ylim = c(30, 500), main="방송인 관심도 평균", xlab="배우#")
plot(entertainer_statistics$total_sd, ylim = c(30, 500), main="방송인 관심도 표준편차")
plot(entertainer_statistics$ratio_avg, ylim = c(0.5, 1), main="방송인 긍정 비율 평균")
plot(entertainer_statistics$ratio_sd, ylim = c(0, 1), main="방송인 긍정 비율 표준편차")
