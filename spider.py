import requests
from bs4 import BeautifulSoup


def spider(maxPages):
    header = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) '
                            'Chrome/76.0.3809.146 Whale/2.6.90.16 Safari/537.36'}
    url = 'https://creativeworks.tistory.com/category/?page='

    page = 1
    while page <= maxPages:
        source_code = requests.get(url + str(page), headers=header)
        # sourceCode.encoding = 'utf-8'
        plain_text = source_code.text
        soup = BeautifulSoup(plain_text, 'lxml')

        print('list of page #' + str(page))
        # print(soup.select('#mArticle'))
        for post in soup.select('#mArticle > .list_content > a.link_post'):
            post_link = 'https://creativeworks.tistory.com/' + post.get('href')
            post_title = post.select('.tit_post')[0].string
            print('Title: ' + post_title + '\n' + 'Link: ' + post_link + '\n')
        page += 1
