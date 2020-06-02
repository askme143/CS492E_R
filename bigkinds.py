import os
from selenium import webdriver
from bs4 import BeautifulSoup
import requests
import response

currentPath = os.getcwd()
bigkinds = 'https://www.bigkinds.or.kr'
search = '//*[@id="total-search-key"]'
enter_key = '//*[@id="news-search-form"]/div/div/div/div[1]/span/button'
related_word = '/html/body/div[10]/div[2]/div/form/div/div/div/div[2]/ul/li[1]/a'

# ChromeDriver 83.0.4103.39
# 2020 05 22 Chrome
keyword = input('search for : ')        # 검색하고자 하는 인물 입력받기
driver = webdriver.Chrome(currentPath + '/chromedriver.exe')
driver.implicitly_wait(3)
driver.get(bigkinds)

search_box = driver.find_element_by_xpath(search)
search_box.send_keys(keyword)
driver.implicitly_wait(1000)
#검색어와 관련된 키워드가 있는지 체크
try:
    driver.find_element_by_xpath(related_word).click()
except:
    pass
driver.implicitly_wait(1000)
driver.find_element_by_xpath(enter_key).click()

result_html = driver.page_source
soup = BeautifulSoup(result_html)
name_html = soup.select(".total-search-key")
name_html = str(name_html[0]).split(">")[1].split("<")[0].split(" AND ")

# 인물 연관 키워드 정렬
# 인물 연관 키워드는 AND, OR 로 구성되어 있음
# ex) ((A) OR (B)) AND (C) OR (D) OR (E) ...
# name_list[AND 목록][OR 목록]
name_list = []
for sub_list in name_html:
	name_list.append([])
	for or_words in sub_list.split(" OR "):
		or_words = or_words.replace("(", "")
		or_words = or_words.replace(")", "")
		or_words = or_words.replace("'", "")
		name_list[-1].append(or_words)
