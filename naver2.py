import os
import csv
import time
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

currentPath = os.getcwd()

naver_news_link = "https://news.naver.com/"
driver = webdriver.Chrome(currentPath + '/chromedriver')
driver.implicitly_wait(3)
driver.get(naver_news_link)

## Get titles ##
celeb = "유재석"
title_list = ["유재석-이효리-비 '혼성그룹' 정말 탄생?…'놀면 뭐하니'"]
link_list = []
################
vote_type_dict = {"좋아요": 8, "훈훈해요": 9, "슬퍼요": 10, "화나요": 11, "후속기사 원해요": 12, \
	"응원해요": 13, "축하해요": 14, "기대해요": 15, "놀랐어요": 16, "팬이에요": 17}

query = driver.find_element_by_name("query")
query.send_keys("None")

for i in range(len(title_list)):
	query = driver.find_element_by_name("query")

	query.send_keys(Keys.CONTROL + "a" + Keys.DELETE)
	query.send_keys(title_list[i] + "\n")
	driver.switch_to.window(driver.window_handles[1])

	search_link_list = driver.find_elements_by_css_selector("a._sp_each_url")
	search_title_list = driver.find_elements_by_css_selector("a._sp_each_title")

	for j in range(len(search_title_list)):
		if search_title_list[j].get_attribute('title') == title_list[i]:
			link_list.append(search_link_list[j].get_attribute('href'))

# Total vote number selector : span.u_likeit_text._count num	-> text
# Vote button selector : a.u_likeit_button		-> click it !!
# Vote Type : span.u_likeit_list_name._label	-> text
# Vote number : span.u_likeit_list_count._count	-> text

fr = open('naver_emo.csv', 'r', newline='')
fa = open('naver_emo.csv', 'a', newline='')
reader_csv = csv.reader(fr)
writer_csv = csv.writer(fa)
row_count = sum(1 for row in reader_csv)

for i in range(len(link_list)):
	driver.get(link_list[i])
	time.sleep(0.5)

	total_vote = driver.find_element_by_css_selector('span.u_likeit_text._count.num').text
	vote_types_elems = driver.find_elements_by_css_selector('#ends_addition span.u_likeit_list_name._label')
	vote_numbers_elems = driver.find_elements_by_css_selector('#ends_addition span.u_likeit_list_count._count')

	vote_types = [vote_types_elems[i].text for i in range(len(vote_types_elems))]
	vote_numbers = [vote_numbers_elems[i].text for i in range(len(vote_types_elems))]

	if '응원해요' in vote_types:
		article_type = '연예'
		date = ('dummy ' + driver.find_element_by_css_selector("div.article_info em").text).split()
	elif '팬이에요' in vote_types:
		article_type = '스포츠'
		date = driver.find_element_by_css_selector("div.info > span").text.split()
	else:
		type = driver.find_element_by_css_selector('em.guide_categorization_item').text
		date = ('dummy ' + driver.find_element_by_css_selector("span.t11").text).split()
	
	time_ = date[3]
	time_ = time_.split(':')
	if date[2] == '오후':
		time_[0] = str(int(time_[0]) + 12)
	time_ = time_[0] + ':' + time_[1]
	date = date[1].split('.')
	
	new_row = [celeb, title_list[i], article_type, date[0], date[1], date[2], time_, total_vote, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	print(new_row)
	for j in range(len(vote_types)):
		new_row[vote_type_dict[vote_types[j]]] = vote_numbers[j]
	
	writer_csv.writerow(new_row)
	

###############################################################################

# for i in range(len(link_list)):
# 	driver.get()
# 	driver.find_element_by_css_selector("u_likeit_button").click()
# 	icon_name_list = driver.find_element_by_css_selector("u_likeit_list_name")
# 	icon_num_list = driver.find_element_by_css_selector("u_likeit_list_count")

	# for i in range(len())

# # Click 'More' botton until it hides
# tempElement1 = "div.cluster._news_cluster_more_layer.is_hidden"
# tempElement2 = "a.cluster_more_inner"
# while len(driver.find_elements_by_css_selector(tempElement1)) == 0 :
# 	driver.find_element_by_css_selector(tempElement2).click()
# 	driver.implicitly_wait(0.5)

# politicsMainPage = driver.page_source
# soup = BeautifulSoup(politicsMainPage, 'html.parser')

# # Get article links
# politicsLinkList = soup.select(".cluster_foot_more")#.nclicks(cls_pol.clstitle)
# length = len(politicsLinkList)
# for i in range(length) :
# 	subPage = requests.get("https://news.naver.com" + politicsLinkList[i].attrs['href']).text
# 	soup = BeautifulSoup(subPage, 'html.parser')
# 	numArticle = int(soup.select_one(".cluster_banner_count_icon_num").text)

# 	tempList = soup.select("ul > li > dl > dt:nth-child(2) > a")
# 	tempList2 = [tempList[j].attrs['href'] for j in range(len(tempList))]

# 	politicsLinkList += tempList2
# politicsLinkList = list(set(politicsLinkList[length:-1]))

# politicsArticleTitleList = []
# politicsArticleBodyList = []
# politicsCommentList = []

# for link in politicsLinkList:
# 	driver.get(link)
# 	html = driver.page_source
# 	soup = BeautifulSoup(html, 'html.parser')

# 	# articleCode = 
# 	# articleType = "politics"
# 	date = soup.select_one("span.t11").string
# 	title = soup.select_one("#articleTitle").string
# 	body = soup.select_one("#articleBodyContents")
# 	# Todo: parse body
# 	commentNum = soup.select_one("ul.u_cbox_comment_count.u_cbox_comment_count3 span.u_cbox_info_txt").string
# 	if soup.select("div.u_cbox_slider.u_cbox_slider_open").attrs['style'] == "display:none" :
# 		commentMaleRatio = ""
# 		commentFemaleRatio = ""
# 		commentAge = ""
# 	else :
# 		commentMaleRatio = soup.select_one("div.u_cbox_chart_male > span.u_cbox_chart_per").string
# 		commentFemaleRatio = soup.select_one("div.u_cbox_chart_female > span.u_cbox_chart_per").string
# 		tempCommentAge = soup.select("div.u_cbox_chart_age span.u_cbox_chart_per")
# 		commentAge = [tempCommentAge[i].string for i in range(tempCommentAge)]

# 	# Click 'More' bottons to get all comments
# 	link = driver.find_element_by_css_selector("a.pi_btn_count").get_attribute('href')
# 	driver.get(link)

# 	time.sleep(1)

# 	soup = BeautifulSoup(driver.page_source, 'html.parser')
# 	numComments = int(soup.select_one("div.u_cbox_head > a > span.u_cbox_count").string)
# 	count = 0
# 	while count < numComments:
# 		time.sleep(0.5)
# 		soup = BeautifulSoup(driver.page_source, 'html.parser')

# 		commentList = soup.select("span.u_cbox_contents")
# 		likeList = soup.select("em.u_cbox_cnt_recomm")
# 		dislikeList = soup.select("em.u_cbox_cnt_unrecomm")
# 		replyNumList = soup.select("span.u_cbox_reply_cnt")

# 		commentList2 = [commentList[i].string for i in range(len(commentList))]
# 		likeList2 = [likeList[i].string for i in range(len(likeList))]
# 		dislikeList2 = [dislikeList[i].string for i in range(len(dislikeList))]
# 		replyNumList2 = [replyNumList[i].string for i in range(len(replyNumList))]

# 		count += 20

# 		if count < numComments:
# 			driver.find_element_by_class_name("u_cbox_btn_more").click()
# 	# Write on a csv file