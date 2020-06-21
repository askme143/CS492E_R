library(dplyr)
library(caret)
library(e1071)
library(cluster)
set.seed(1712)

week_to_date = function(nth_week) {
  start = as.Date("2019-06-02", "%Y-%m-%d")
  start + nth_week*7
}

get_job = function (celeb) {
  count = 1
  for (col in celeb_list){
    if (celeb %in% col) {
      return(colnames(celeb_list)[count])
    }
    count = count + 1
  }
}

celeb_list = read.csv("직업군.csv", header = T)
celeb_all = c()

for (col in celeb_list) {
  celeb_all = c(celeb_all, as.character(col))
}
celeb_all = as.character(celeb_all[celeb_all!=""])

emo_vector_table = data.frame()
for (celeb in celeb_all){
  #celeb_csv = read.csv(paste0("../tmp/ano", celeb, "_data.csv"), sep=",")
  celeb_csv = read.csv(paste0("data/", celeb, "_data.csv"), sep=",")
  #colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url", "pos_article")
  colnames(celeb_csv) = c("celeb","title","article_type","nth_week","year","month","date","time","total","like","warm","sad","angry","want","cheer","congrats","expect","surprise","fan","url")
  celeb_csv[9:19] = lapply(celeb_csv[9:19], function(x){as.numeric(gsub(",", "", x))})
  
  emo_frame = celeb_csv %>%
    .[9:19]
  for (i in 1:nrow(emo_frame)){
    for (j in 11:1) {
      emo_frame[i, j] = emo_frame[i, j] / emo_frame[i,1]
    }
  }
  emo_vector = lapply(emo_frame, mean)[-1]
  emo_vector = append(emo_vector, celeb)
  emo_vector = append(emo_vector, get_job(celeb))
  names(emo_vector)[11:12] = c("celeb", "job")
  str(emo_vector)
  
  emo_vector_table = rbind(emo_vector_table, data.frame(emo_vector))
}
str(emo_vector_table)

inTrain <- createDataPartition(y = emo_vector_table$job, p = 0.7, list = F)
training <- emo_vector_table[inTrain,]
testing <- emo_vector_table[-inTrain,]

scale_training = scale(training[,1:10])
View(scale_training)

# kmeans
## elbow method
wss = 0
for (i in 1:100) {
  emo_vector_kmeans <- kmeans(scale_training, centers = i, iter.max = 10000)
  wss[i] = sum(emo_vector_kmeans$withinss)
  
}
plot(1:100, wss, type="b")

## decide kmeans model
emo_vector_kmeans <- kmeans(training[1:10], centers = 4, iter.max = 10000)
training$cluster <- as.factor(emo_vector_kmeans$cluster)
View(training %>%
  arrange(cluster))

# Reinit
training <- emo_vector_table[inTrain,]
testing <- emo_vector_table[-inTrain,]
str(training)

#svm
tune(svm, job ~., data=training[,-11], gamma=2^(-1:1), cost=2^(2:4))
emo_vector_svm <- svm(job ~ ., data = training[,-11], type = "C-classification")
str(emo_vector_table)
emo_vector_table[1:11] = lapply(emo_vector_table[1:11], as.numeric)
str(emo_vector_table)
