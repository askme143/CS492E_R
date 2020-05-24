import os
import csv
import time
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


currentPath = os.getcwd()
naverPolitics = 'https://news.naver.com/main/main.nhn?mode=LSD&mid=shm&sid1=100'
naverTVEnter = 'https://entertain.naver.com/home'

# politicsMainPage = requests.get(naverPolitics).text
driver = webdriver.Chrome(currentPath + '/chromedriver.exe')
driver.implicitly_wait(3)
driver.get(naverPolitics)

# Click 'More' botton until it hides
tempElement1 = "div.cluster._news_cluster_more_layer.is_hidden"
tempElement2 = "a.cluster_more_inner"
while len(driver.find_elements_by_css_selector(tempElement1)) == 0 :
	driver.find_element_by_css_selector(tempElement2).click()
	driver.implicitly_wait(0.5)

politicsMainPage = driver.page_source
soup = BeautifulSoup(politicsMainPage, 'html.parser')

# Get article links
politicsLinkList = soup.select(".cluster_foot_more")#.nclicks(cls_pol.clstitle)
length = len(politicsLinkList)
for i in range(length) :
	subPage = requests.get("https://news.naver.com" + politicsLinkList[i].attrs['href']).text
	soup = BeautifulSoup(subPage, 'html.parser')
	numArticle = int(soup.select_one(".cluster_banner_count_icon_num").text)

	tempList = soup.select("ul > li > dl > dt:nth-child(2) > a")
	tempList2 = [tempList[j].attrs['href'] for j in range(len(tempList))]

	politicsLinkList += tempList2
politicsLinkList = list(set(politicsLinkList[length:-1]))

politicsArticleBodyList = []
politicsArticleTitleList = []
politicsCommentList = []

for link in politicsLinkList:
	driver.get(link)
	html = driver.page_source
	soup = BeautifulSoup(html, 'html.parser')

	politicsArticleBodyList.append(soup.select_one("#articleBodyContents"))
	politicsArticleTitleList.append(soup.select_one("#articleTitle").string)
	
	commentList = []
	likes = []
	dislikes = []

	# Click 'More' bottons to get all comments
	link = driver.find_element_by_css_selector("a.pi_btn_count").get_attribute('href')
	driver.get(link)

	time.sleep(1)

	html = driver.page_source
	soup = BeautifulSoup(html, 'html.parser')
	numComments = int(soup.select_one("div.u_cbox_head > a > span.u_cbox_count").string)
	count = 0

	while count < numComments:
		time.sleep(0.5)
		soup = BeautifulSoup(driver.page_source, 'html.parser')
		for _ in range(min(numComments - count, 20)):
			commentBox = "div.u_cbox_content_wrap > ul > li:nth-child(" + str(count + 1) + ")"
			comment = soup.select_one(commentBox + " span.u_cbox_contents")
			if comment:
				commentList.append(comment.string)
				print(comment.string)

			count += 1

		if count < numComments:
			driver.find_element_by_class_name("u_cbox_btn_more").click()

	# print(len(commentList))
		
	# politicsCommentList.append(commentList)

# for i in range(len(politicsArticleTitleList)):
# 	print(politicsArticleBodyList[i])
# 	print(politicsArticleTitleList[i])
# 	print()