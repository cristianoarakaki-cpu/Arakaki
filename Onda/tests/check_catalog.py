"""Live regression for the user's exact example, including actual preview bytes."""
import json
import unicodedata
import urllib.parse
import urllib.request

def normalize(value):
    return ''.join(c for c in unicodedata.normalize('NFD',value.lower()) if unicodedata.category(c)!='Mn').replace('&',' ').split()

def get(url):
    with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Onda/0.7.0'}),timeout=25) as response:
        return json.load(response)

params={'term':'chitaozinho xororo','country':'BR','entity':'song','attribute':'artistTerm','limit':30,'lang':'pt_br'}
response=get('https://itunes.apple.com/search?'+urllib.parse.urlencode(params))
tracks=[t for t in response['results'] if 'chitaozinho' in normalize(t.get('artistName','')) and 'xororo' in normalize(t.get('artistName','')) and t.get('previewUrl') and t.get('trackViewUrl')]
assert tracks,'The artist Chitãozinho & Xororó was not found'
preview=tracks[0]['previewUrl']
assert urllib.parse.urlparse(preview).hostname.endswith('.itunes.apple.com')
with urllib.request.urlopen(urllib.request.Request(preview,headers={'User-Agent':'Onda/0.7.0','Range':'bytes=0-63'}),timeout=25) as response:
    assert response.status in (200,206) and response.read(64)
print('Catálogo: Chitãozinho & Xororó encontrado com nome sem acentos, prévia e link para a música completa.')
print('Exemplos:',[(t['trackName'],t['artistName']) for t in tracks[:3]])
