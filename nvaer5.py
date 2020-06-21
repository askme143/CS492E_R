# coding=<utf-8>
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
	
	y_start, m_start, d_start = '2017', '01', '01'
	y_finish, m_finish, d_finish = '2017', '01', '07'
	nth_week = 0
	while True:
		# Search for the week
		start = y_start +'.'+ m_start +'.'+ d_start
		finish = y_finish +'.'+ m_finish +'.'+ d_finish
		search_url_week = search_url + '&pd=3&ds=' + start + '&de=' + finish
		driver.get(search_url_week)

		# Get links and count
		length = 0
		temp = driver.find_elements_by_css_selector('dd.txt_inline > a')
		link_list_1 = [(temp[i].get_attribute('href'), nth_week, celeb) for i in range(len(temp))]

		temp = driver.find_elements_by_css_selector('span.txt_sinfo > a')
		link_list_2 = [(temp[i].get_attribute('href'), nth_week, celeb) for i in range(len(temp))]

		# Append the result
		link_list += link_list_1 + link_list_2
		
		if (y_finish, m_finish, d_finish) == ('2020', '05', '30'):
			break

		# Advance
		y_start, m_start, d_start = get_next_week(y_start, m_start, d_start)
		y_finish, m_finish, d_finish = get_next_week(y_finish, m_finish, d_finish)
		nth_week += 1
	
	return link_list

def make_row_for_link(search_result, driver):
	global row_list
	link, nth_week, celeb = search_result
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
	
	title = title.encode('cp949', 'ignore').decode('cp949')

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
	
	row_list.append(new_row)

def do_thread_get_row (search_result_list):
	with ThreadPoolExecutor(max_workers=8) as executor:
		thread_list = []
		for search_result in search_result_list:
			thread_list.append(executor.submit(do_get_row, search_result))
		for execution in concurrent.futures.as_completed(thread_list):
			execution.result()

def do_thread_get_link (celeb_list):
	with ThreadPoolExecutor(max_workers=8) as executor:
		thread_list = []
		for celeb in celeb_list:
			thread_list.append(executor.submit(do_get_link, celeb))
		for execution in concurrent.futures.as_completed(thread_list):
			execution.result()

def do_get_row (search_result):
	driver = get_driver()

	try:
		make_row_for_link(search_result, driver)
	except NoSuchElementException:
		return None

def do_get_link (celeb):
	global search_result_list
	driver = get_driver()

	search_result_list += get_link_of_celeb(celeb, driver)

def get_driver():
	driver = getattr(thread_local, 'driver', None)
	if driver is None:
		chromeOptions = webdriver.ChromeOptions()
		chromeOptions.add_argument("disable-gpu")
		chromeOptions.add_argument("window-size=1920x1080")
		chromeOptions.add_argument("start-maximized")

		driver = webdriver.Chrome(chrome_options=chromeOptions)
		driver_list.append(driver)
		setattr(thread_local, 'driver', driver)
	return driver

############################################################
############################################################

if __name__ == '__main__':
	# Variables
	celeb_list = "엑소, 트와이스, 레드벨벳, 블랙핑크"
	celeb_list = celeb_list.replace("\t", "")
	celeb_list = celeb_list.split(", ")

	row_list = []
	search_result_list = []
	driver_list = []
	
	emo_type_dict = {"좋아요": 0, "훈훈해요": 1, "슬퍼요": 2, "화나요": 3, "후속기사 원해요": 4, \
		"응원해요": 5, "축하해요": 6, "기대해요": 7, "놀랐어요": 8, "팬이에요": 9}
	emo_idx_offset = 9

	for celeb in celeb_list:
		do_thread_get_link([celeb])
		driver_list.pop().close()

		do_thread_get_row(search_result_list)
		while len(driver_list) > 0:
			driver_list.pop().close()

		fa = open(str(celeb) + '_data' + '.csv', 'a', encoding='CP949', newline='')
		writer_csv = csv.writer(fa)

		writer_csv.writerows(row_list)
		fa.close()

		row_list, search_result_list = [], []