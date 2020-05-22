import os
from selenium import webdriver
from bs4 import BeautifulSoup

currentPath = os.getcwd()
naverPolitics = 'https://news.naver.com/main/main.nhn?mode=LSD&mid=shm&sid1=100'
naverTVEnter = 'https://entertain.naver.com/home'

# ChromeDriver 83.0.4103.39
# 2020 05 22 Chrome
driver = webdriver.Chrome(currentPath + '/chromedriver.exe')
driver.implicitly_wait(3)

politicsXpath = "//*[@id=\"main_content\"]/div/div[2]/div[1]/div[1]/div[1]/ul/li[1]/div[2]/a"
# //*[@id="main_content"]/div/div[2]/div[1]/div[1]/div[1]/ul/li[2]/div/a
# 62

politicsPage = driver.get(naverPolitics)
politicsMainPage = driver.page_source
soup = BeautifulSoup(politicsMainPage, 'html.parser')

linkList = soup.select()
driver.find_element_by_xpath(politicsXpath).click()
driver.implicitly_wait(1)
driver.find_element_by_xpath('//*[@id="articleBodyContents"]')
html = driver.page_source

