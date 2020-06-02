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

politicsArticleTitleList = []
politicsArticleBodyList = []
politicsCommentList = []

for link in politicsLinkList:
	driver.get(link)
	html = driver.page_source
	soup = BeautifulSoup(html, 'html.parser')

	# articleCode = 
	# articleType = "politics"
	date = soup.select_one("span.t11").string
	title = soup.select_one("#articleTitle").string
	body = soup.select_one("#articleBodyContents")
	# Todo: parse body
	commentNum = soup.select_one("ul.u_cbox_comment_count.u_cbox_comment_count3 span.u_cbox_info_txt").string
	if soup.select("div.u_cbox_slider.u_cbox_slider_open").attrs['style'] == "display:none" :
		commentMaleRatio = ""
		commentFemaleRatio = ""
		commentAge = ""
	else :
		commentMaleRatio = soup.select_one("div.u_cbox_chart_male > span.u_cbox_chart_per").string
		commentFemaleRatio = soup.select_one("div.u_cbox_chart_female > span.u_cbox_chart_per").string
		tempCommentAge = soup.select("div.u_cbox_chart_age span.u_cbox_chart_per")
		commentAge = [tempCommentAge[i].string for i in range(tempCommentAge)]

	# Click 'More' bottons to get all comments
	link = driver.find_element_by_css_selector("a.pi_btn_count").get_attribute('href')
	driver.get(link)

	time.sleep(1)

	soup = BeautifulSoup(driver.page_source, 'html.parser')
	numComments = int(soup.select_one("div.u_cbox_head > a > span.u_cbox_count").string)
	count = 0
	while count < numComments:
		time.sleep(0.5)
		soup = BeautifulSoup(driver.page_source, 'html.parser')

		commentList = soup.select("span.u_cbox_contents")
		likeList = soup.select("em.u_cbox_cnt_recomm")
		dislikeList = soup.select("em.u_cbox_cnt_unrecomm")
		replyNumList = soup.select("span.u_cbox_reply_cnt")

		commentList2 = [commentList[i].string for i in range(len(commentList))]
		likeList2 = [likeList[i].string for i in range(len(likeList))]
		dislikeList2 = [dislikeList[i].string for i in range(len(dislikeList))]
		replyNumList2 = [replyNumList[i].string for i in range(len(replyNumList))]

		count += 20

		if count < numComments:
			driver.find_element_by_class_name("u_cbox_btn_more").click()
	# Write on a csv file