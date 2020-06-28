library(dplyr)
library(RcppRoll)
library(ggplot2)
library(scales)
library(forecast)
library(GGally)
library(dtwclust)

celeb_list = c('방탄소년단', '엑소', '블랙핑크', '트와이스', '레드벨벳', '워너원', 'NCT', '에이핑크', '마마무', '비투비', '위너', '몬스타엑스', '오마이걸', '아이즈원', '러블리즈', '(여자)아이들', '뉴이스트', '아스트로', '투모로우바이투게더', '갓세븐', 'ITZY', '드림캐쳐', '스트레이키즈', '에버글로우')

vectors = list()
count = 1
for (celeb in celeb_list){
  celeb_csv = read.csv(paste0("data/", celeb, "_data.csv"), sep=",")
  colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")
  celeb_csv[9:19] = lapply(celeb_csv[9:19], function(x){as.numeric(gsub(",", "", x))})
  celeb_csv = celeb_csv %>%
    mutate(week_start = week_to_date(nth_week))
  
  # Total emos per week
  total_week = celeb_csv %>%
    select(nth_week, total)
  
  for (i in 0:51) {
    if (!(i %in% total_week$nth_week)) {
      total_week = rbind(total_week, c(i, 1))
    }
  }
  
  total_week = total_week %>%
    arrange(nth_week)
  
  total_week = total_week %>%
    group_by(nth_week) %>%
    summarize(mean_total = log(mean(total)))
  
  vectors = append(vectors, list((total_week$mean_total)))
  if (count == 1) {
    df = data.frame(cumsum(total_week$mean_total))
  } else {
    df = cbind(df, cumsum(total_week$mean_total))
  }
  count  = count + 1
}
colnames(df) = celeb_list

cluster = tsclust(vectors, k = 4L,
                  distance = "L2", centroid = "pam",
                  seed = 3247, trace = TRUE,
                  control = partitional_control(nrep = 20))

sapply(cluster, cvi, b = as.factor(celeb_list))

cluster_h <- tsclust(vectors, type = "hierarchical",
                 k = 4L, trace = TRUE,
                 control = hierarchical_control(method = "all", distmat = cluster[[1]]@distmat))

clust_fin = cluster_h[[which.min(sapply(cluster, cvi, b = as.factor(celeb_list), type = "VI"))]]
cl = slot(clust_fin, "cluster")

df = data.frame(x = as.factor(celeb_list), y = cl)
ggplot() + geom_point(data = df, aes(x = x, y = y,color = y), size=4) +
  labs(color = "Idol Group", shape = "Idol Group", x = "Week",
       y = "Group Number", title = "Grouping Result") + 
  theme_light(base_size = 15) +
  theme(panel.grid.minor = element_blank()) +
  theme(axis.text.x=element_text(angle=60, hjust=1))
