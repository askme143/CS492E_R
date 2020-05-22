import sample

html = sample.html
parsed = html.split('<br>')

for entry in parsed :
    if '<' in entry or '>' in entry :
        parsed.remove(entry)

print(parsed)





