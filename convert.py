import csv
import glob


file_list = glob.glob("C:\\Users\\Yeongil Yoon\\Desktop\\tmp\\*.csv")
# celeb_list = "거미, 김나영, 백아연, 백예린, 벤, 볼빨간사춘기, 소향, 손승연, 아이유, 에일리, 백지영, 윤하, 이하이, 박정현, 이소라, \
# 	박효신, 이적, 임재범, 박완규, 김태원, 김경호, 홍진영, 하현우, 김진호, 장범준, 폴킴, 윤종신, 임영웅, 영탁, \
# 	유재석, 박나래, 백종원, 박명수, 정준하, 강호동, 이광수, 김종국, 이영자, 김숙"
# celeb_list = celeb_list.replace("\t", "")
# celeb_list = celeb_list.split(", ")

# for celeb in celeb_list:
for file in file_list:
	# fr = open('cs496e/data/' + str(celeb) + '_data' + '.csv', 'r', encoding='UTF-8')
	fr = open(file, 'r', encoding='UTF-8')
	fw = open("C:\\Users\\Yeongil Yoon\\Desktop\\tmp\\*.csv", 'w', encoding='CP949', newline="")
	reader = csv.reader(fr)
	writer = csv.writer(fw)
	for row in reader:
		row[1] = row[1].encode('cp949', 'ignore').decode('cp949')
		writer.writerow(row)
