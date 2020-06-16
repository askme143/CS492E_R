import csv

celeb = "ITZY"

celeb_list = ["블랙핑크", "트와이스", "레드벨벳", "방탄소년단", "엑소"]
# celeb_list = celeb_list.replace("\t", "")
# celeb_list = celeb_list.split(", ")

for celeb in celeb_list:
	fr = open('cs496e/data/' + str(celeb) + '_data' + '.csv', 'r', encoding='UTF-8')
	fw = open(str(celeb) + '_data' + '.csv', 'w', encoding='CP949', newline="")
	reader = csv.reader(fr)
	writer = csv.writer(fw)
	for row in reader:
		row[1] = row[1].encode('cp949', 'ignore').decode('cp949')
		writer.writerow(row)
