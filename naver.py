import os
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.support import expected_conditions as EC

currentPath = os.getcwd()
naverPolitics = 'https://news.naver.com/main/main.nhn?mode=LSD&mid=shm&sid1=100'
naverTVEnter = 'https://entertain.naver.com/home'

# ChromeDriver 83.0.4103.39
# 2020 05 22 Chrome
driver = webdriver.Chrome(currentPath + '/chromedriver')
driver.implicitly_wait(2)
driver.get(naverPolitics)

politicsMainPage = driver.page_source
soup = BeautifulSoup(politicsMainPage, 'html.parser')

politicsLinkList = soup.select(".cluster_text_headline")
articleBodyList = []
articleTitleList = []

for i in range(len(politicsLinkList)):
	politicsLinkList[i] = politicsLinkList[i].attrs['href']

for link in politicsLinkList:
	driver.get(link)
	soup = BeautifulSoup(driver.page_source, 'html.parser')

	articleBodyList.append(soup.select_one("#articleBodyContents"))
	articleTitleList.append(soup.select_one("#articleTitle").string)