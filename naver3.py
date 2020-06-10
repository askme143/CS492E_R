import os
import csv
import time
import requests
import calendar
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException

def get_next_week(year, month, date):
	year, month, date = int(year), int(month), int(date)
	last_date = calendar.monthrange(year, month)[1]
	
	date += 7
	if date > last_date:
		month += 1; date -= last_date
	if month > 12:
		year += 1; month = 1
	
	if month < 10:	month = '0'+str(month)
	else:			month = str(month)
	if date < 10:	date = '0'+str(date)
	else:			date = str(date)
	year = str(year)

	return year, month, date

# From 2019 06 02 ~ 2020 05 30
def get_link_of_celeb(celeb):
	# Link list
	link_list = []
	week_list = []

	# Search celeb
	search_url = 'https://search.naver.com/search.naver?where=news&query=' + celeb
	
	y_start, m_start, d_start = '2019', '06', '02'
	y_finish, m_finish, d_finish = '2019', '06', '08'
	for nth_week in range(26):
		# Search for the week
		start = y_start +'.'+ m_start +'.'+ d_start
		finish = y_finish +'.'+ m_finish +'.'+ d_finish
		search_url_week = search_url + '&pd=3&ds=' + start + '&de=' + finish
		driver.get(search_url_week)

		# Get links and count
		length = 0
		temp = driver.find_elements_by_css_selector('dd.txt_inline > a')
		link_list_1 = [temp[i].get_attribute('href') for i in range(len(temp))]
		length += len(link_list_1)

		temp = driver.find_elements_by_css_selector('span.txt_sinfo > a')
		link_list_2 = [temp[i].get_attribute('href') for i in range(len(temp))]
		length += len(link_list_2)

		# Append the result
		link_list += link_list_1 + link_list_2
		week_list += [nth_week for temp in range(length)]
		
		# Advance
		y_start, m_start, d_start = get_next_week(y_start, m_start, d_start)
		y_finish, m_finish, d_finish = get_next_week(y_finish, m_finish, d_finish)
	
	return link_list, week_list

def make_row_for_link(link, celeb, nth_week, emo_idx_offset, emo_type_dict):
	# Move to the url
	driver.get(link)

	# If there is no emotion votes, return
	try:
		total_vote = driver.find_element_by_css_selector('span.u_likeit_text._count.num').text
	except NoSuchElementException:
		return

	# Make EMO_TYPE_LIST and EMO_NUMBER_LIST
	temp = driver.find_elements_by_css_selector('div.end_btn span.u_likeit_list_name._label')
	if len(temp) == 0:
		temp = driver.find_elements_by_css_selector('div.news_end_btn span.u_likeit_list_name._label')
	emo_type_list = [temp[i].text for i in range(len(temp))]

	temp = driver.find_elements_by_css_selector('div.end_btn span.u_likeit_list_count._count')
	if len(temp) == 0:
		temp = driver.find_elements_by_css_selector('div.news_end_btn span.u_likeit_list_count._count')
	emo_number_list = [temp[i].text for i in range(len(temp))]

	# Classification: Article_type
	# Make Title
	if '응원해요' in emo_type_list:
		title = driver.find_element_by_css_selector("#content > div.end_ct > div > h2").text

		article_type = '연예'
		date = ('dummy ' + driver.find_element_by_css_selector("div.article_info em").text).split()
	elif '팬이에요' in emo_type_list:
		title = driver.find_element_by_css_selector("#content > div > div.content > div > div.news_headline > h4").text

		article_type = '스포츠'
		date = driver.find_element_by_css_selector("div.info > span").text.split()
	else:
		title = driver.find_element_by_css_selector("#articleTitle").text

		temp = driver.find_elements_by_css_selector('div.article_body div.guide_categorization em.guide_categorization_item')
		if len(temp) > 0:
			article_type = temp[0].text
		else:
			article_type = ''
		date = ('dummy ' + driver.find_element_by_css_selector("span.t11").text).split()
	
	# Get date
	time_ = date[3]
	time_ = time_.split(':')
	if date[2] == '오후':
		time_[0] = str(int(time_[0]) + 12)
	time_ = time_[0] + ':' + time_[1]
	date = date[1].split('.')
	
	new_row = [celeb, title, article_type, nth_week, date[0], date[1], date[2], time_, total_vote, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, link]
	for i in range(len(emo_type_list)):
		new_row[emo_type_dict[emo_type_list[i]] + emo_idx_offset] = emo_number_list[i]
	
	return new_row

############################################################
############################################################

if __name__ == '__main__':
	# Variables
	# celeb_list = ["유재석", "블랙핑크", "아이유", "방탄소년단", "슈가"]
	# celeb_list = ["블랙핑크", "트와이스", "레드벨벳", "방탄소년단", "엑소"]
	celeb_list = [""]
	emo_type_dict = {"좋아요": 0, "훈훈해요": 1, "슬퍼요": 2, "화나요": 3, "후속기사 원해요": 4, \
		"응원해요": 5, "축하해요": 6, "기대해요": 7, "놀랐어요": 8, "팬이에요": 9}
	emo_idx_offset = 9

	# Start driver
	currentPath = os.getcwd()
	driver = webdriver.Chrome(currentPath + '/chromedriver')
	driver.implicitly_wait(3)

	# Code for testing
	# test_link = 'https://sports.news.naver.com/news.nhn?oid=241&aid=0002936074'
	# new_row = make_row_for_link(test_link, "블랙핑크", 0, emo_idx_offset, emo_type_dict)

	# Make CELEB_data.csv
	for celeb in celeb_list:
		fa = open(str(celeb) + '_data' + '.csv', 'a', encoding='UTF-8', newline='')
		writer_csv = csv.writer(fa)
		link_list, week_list = get_link_of_celeb(celeb)

		for i in range(len(link_list)):
			new_row = make_row_for_link(link_list[i], celeb, week_list[i], emo_idx_offset, emo_type_dict)
			if new_row != None:
				writer_csv.writerow(new_row)
	driver.close()
	fa.close()