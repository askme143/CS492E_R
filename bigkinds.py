import os
from selenium import webdriver

currentPath = os.getcwd()
bigkinds = 'https://www.bigkinds.or.kr'
enter_keywords = '''
/html/body/div[10]/div[2]/div/form/div/div/div/div[1]/input[1]
'''

# ChromeDriver 83.0.4103.39
# 2020 05 22 Chrome
driver = webdriver.Chrome(currentPath + '/chromedriver.exe')
driver.implicitly_wait(3)

driver.get(bigkinds)
html = driver.page_source()
print (html)