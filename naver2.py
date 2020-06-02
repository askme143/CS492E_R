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
# celeb	title	article_type	year	month	date	time	like	warm	sad	angry	want	cheer	congrats	expect	surprise	fan

fa = open('naver_emo.csv', 'a', newline='')
writer_csv = csv.writer(fa)

for i in range(len(link_list)):
	driver.get(link_list[i])
	time.sleep(0.5)

	total_vote = driver.find_element_by_css_selector('span.u_likeit_text._count.num').text
	vote_types_elems = driver.find_elements_by_css_selector('#ends_addition span.u_likeit_list_name._label')
	vote_numbers_elems = driver.find_elements_by_css_selector('#ends_addition span.u_likeit_list_count._count')

	vote_types = [vote_types_elems[j].text for j in range(len(vote_types_elems))]
	vote_numbers = [vote_numbers_elems[j].text for j in range(len(vote_types_elems))]

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
	for j in range(len(vote_types)):
		new_row[vote_type_dict[vote_types[j]]] = vote_numbers[j]
	
	writer_csv.writerow(new_row)