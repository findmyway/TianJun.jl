from requests_html import HTMLSession

session = HTMLSession()

r = session.get('https://pkg.julialang.org/')

repo_names = [x.text for x in r.html.find('h2')]
repo_links = [list(x.links)[0] for x in r.html.find('h2')]
stars = [int(x.text[:-3]) for x in r.html.find('span[title$="stars"]')]
up_deps = [int(x.text[:-2]) for x in r.html.find('span[title$="package"]')]

total = sorted(zip(up_deps, stars, repo_names, repo_links), reverse=True)

head = '''
|#|N_up_deps|Stars|Link|
|-|---------|-----|----|
'''
body = '\n'.join(['|{}|{}|[{}]({})|'.format(i+1, *row)
                  for i, row in enumerate([x for x in total if x[1] > 50][:30])])

print(head + body)
