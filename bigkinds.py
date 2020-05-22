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

# div class = cluster_text -> div class = "cluster_text_headline nclicks(cls_pol.clsart)"
# main_content > div > div._persist > div:nth-child(1) > div:nth-child(1) > div.cluster_body > ul > li:nth-child(1) > div.cluster_text > a
linkClass = "cluster_text_headline nclicks(cls_pol.clsart)"
driver.get(bigkinds)
find_element_by_class_name('')
html = driver.page_source()
print (html)