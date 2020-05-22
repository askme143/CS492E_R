import os
from selenium import webdriver

currentPath = os.getcwd()
naverPolitics = 'https://news.naver.com/main/main.nhn?mode=LSD&mid=shm&sid1=100'
naverTVEnter = 'https://entertain.naver.com/home'

# ChromeDriver 83.0.4103.39
# 2020 05 22 Chrome
driver = webdriver.Chrome(currentPath + '/chromedriver.exe')
driver.implicitly_wait(3)

politicsXpath = "//*[@id=\"main_content\"]/div/div[2]/div[1]/div[1]/div[1]/ul/li[1]/div[2]/a"
driver.get(naverPolitics)
# driver.find_element_by_xpath(politicsXpath).get_attribute()
html = driver.page_source
print (html)