import os
import csv
import time
import requests
import calendar
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException, TimeoutException

from multiprocessing import Pool
from concurrent.futures import ThreadPoolExecutor
from functools import partial
import concurrent.futures
import threading

thread_local = threading.local()

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
def get_link_of_celeb(celeb, driver):
	# Link list
	link_list = []
	week_list = []

	# Search celeb
	search_url = 'https://search.naver.com/search.naver?where=news&query=' + celeb
	
	y_start, m_start, d_start = '2019', '06', '02'
	y_finish, m_finish, d_finish = '2019', '06', '08'
	for nth_week in range(num_weeks):
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

def make_row_for_link(link, celeb, nth_week, emo_idx_offset, emo_type_dict, driver):
	# Move to the url
	driver.get(link)
	wait = WebDriverWait(driver, 2)

	# If there is no emotion votes, return
	try:
		total_vote = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, 'span.u_likeit_text._count.num'))).text
		# total_vote = driver.find_element_by_css_selector('span.u_likeit_text._count.num').text
	except TimeoutException:
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

def do_thread_collect_data (celeb_list):
	with ThreadPoolExecutor(max_workers=8) as executor:
		thread_list = []
		for celeb in celeb_list:
			thread_list.append(executor.submit(do_collect_data, celeb))
		for execution in concurrent.futures.as_completed(thread_list):
			execution.result()

def do_collect_data (celeb):
	fa = open(str(celeb) + '_data' + '.csv', 'a', encoding='UTF-8', newline='')
	writer_csv = csv.writer(fa)

	driver = get_driver()

	link_list, week_list = get_link_of_celeb(celeb, driver)

	for i in range(len(link_list)):
		new_row = make_row_for_link(link_list[i], celeb, week_list[i], emo_idx_offset, emo_type_dict, driver)
		if new_row != None:
			writer_csv.writerow(new_row)
	fininsh_list.append(celeb)
	print(fininsh_list)
	driver.close()
	fa.close()

def get_driver():
	driver = getattr(thread_local, 'driver', None)
	if driver is None:
		chromeOptions = webdriver.ChromeOptions()
		# chromeOptions.add_argument("headless")
		chromeOptions.add_argument("--disable-gpu")
		chromeOptions.add_argument("--window-size=1920x1080")

		driver = webdriver.Chrome(chrome_options=chromeOptions)
		setattr(thread_local, 'driver', driver)
	return driver

############################################################
############################################################

if __name__ == '__main__':
	# Variables
	num_weeks = 52

	# celeb_list = ["유재석", "블랙핑크", "아이유", "방탄소년단", "슈가"]
	# celeb_list = ["블랙핑크", "트와이스", "레드벨벳", "방탄소년단", "엑소"]
	# celeb_list = ["문재인", "조국", "홍준표", "나경원", "김정은", "아베", "트럼프"]
	# celeb_list = ["가수 비", "박서준", "정경호", "조정석"]
	# celeb_list = ["정준영", "승리", "용준형"]
	celeb_list = "이태임, 이하늬, 이시언, 고준희, 진구, 송중기, \
		송혜교, 윤세아, 엄정화, 이상엽, 이다희, 박세영, 정혜성, 안소희, 송지효, 조보아, 고아라, 이준기, 강동원, 이성민, 윤제문, 수애, 김유정, \
		윤균상, 라미란, 김서형, 오나라, 최수종, 조정석, 이제훈, 권상우, 김희원, 김성균, 강소라, 안재홍, 김성오, 전여빈, 진서연, 김성령, 박신혜, \
		곽도원, 김대명, 안보현, 박서준, 김다미, 권나라, 유재명"
	celeb_list = celeb_list.replace("\t", "")
	celeb_list = celeb_list.split(", ")
	fininsh_list = []
	
	emo_type_dict = {"좋아요": 0, "훈훈해요": 1, "슬퍼요": 2, "화나요": 3, "후속기사 원해요": 4, \
		"응원해요": 5, "축하해요": 6, "기대해요": 7, "놀랐어요": 8, "팬이에요": 9}
	emo_idx_offset = 9

	# epoch_size = 8
	# epoch_list = []
	# i = 0
	# while i < len(celeb_list):
	# 	epoch_list.append(celeb_list[i:(i+epoch_size-1)])
	# 	i += epoch_size


	# # Make CELEB_data.csv
	# for i in range(len(epoch_list)):
	# 	do_thread_collect_data(epoch_list[i])
	# 	print ("epoch: ", i)
	do_thread_collect_data(celeb_list)