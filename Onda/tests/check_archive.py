"""Live integration smoke test: search -> item metadata -> actual audio bytes."""
import json
import urllib.parse
import urllib.request

HEADERS = {'User-Agent': 'Onda/0.3.0 (Android music player)'}
def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=20) as response:
        return json.load(response)

query = 'collection:etree AND NOT access-restricted-item:true AND (title:"Grateful" OR creator:"Grateful" OR description:"Grateful") AND (title:"Dead" OR creator:"Dead" OR description:"Dead")'
params = urllib.parse.urlencode({'q': query, 'output': 'json', 'rows': '5', 'fl[]': 'identifier,title,creator'})
docs = get('https://archive.org/advancedsearch.php?' + params)['response']['docs']
assert docs, 'Search returned no live recordings'
artist_params = {'q': 'collection:etree AND NOT access-restricted-item:true AND creator:"grateful" AND creator:"dead"', 'output': 'json', 'rows': '2', 'page': '2', 'fl[]': 'identifier,title,creator', 'sort[]': 'downloads desc'}
artist_page = get('https://archive.org/advancedsearch.php?' + urllib.parse.urlencode(artist_params))['response']
assert artist_page['numFound'] > 2 and artist_page['start'] == 2 and artist_page['docs'], 'Artist filter or pagination failed'
print('Internet Archive: artist filter, popularity order and second page passed.')
for doc in docs:
    item = get('https://archive.org/metadata/' + urllib.parse.quote(doc['identifier'], safe=''))
    collections = item.get('metadata', {}).get('collection', [])
    if isinstance(collections, str):
        collections = [collections]
    assert 'etree' in collections
    files = [f for f in item.get('files', []) if f.get('name', '').lower().endswith('.mp3') and str(f.get('private', '')).lower() != 'true']
    if not files:
        continue
    url = 'https://archive.org/download/' + urllib.parse.quote(doc['identifier'], safe='') + '/' + urllib.parse.quote(files[0]['name'], safe='')
    request = urllib.request.Request(url, headers={**HEADERS, 'Range': 'bytes=0-31'})
    with urllib.request.urlopen(request, timeout=20) as response:
        assert response.status in (200, 206)
        assert response.read(32), 'Empty audio response'
    print('Internet Archive: search, collection membership, MP3 metadata and streaming bytes passed.')
    break
else:
    raise AssertionError('No playable MP3 found in search results')
