import json
import os
import re
import pandas as pd
import requests

allapts = []

# %%
# Take destination 
dest = '1210 W Dayton St Madison WI 53706'
# https://www.geeksforgeeks.org/python-calculate-distance-duration-two-places-using-google-distance-matrix-api/
api_key = '' # enter your api key here
url ='https://maps.googleapis.com/maps/api/distancematrix/json?'

# %%
def gettime(source, dest, key, method='driving'):
    source = re.sub('#', 'unit ', source)
    # return response object
    r = requests.get(url + 'origins=' + source +
                    '&destinations=' + dest +
                    '&mode=' + method +
                    '&key=' + api_key)
    # json method of response object
    # return json format result
    return r.json()

# %%

for name in os.listdir('rawdata'):
    if not name.endswith('.txt'): continue
    print(name)
    with open('rawdata/' + name, 'r') as f:
        s = f.read()

    # %%
    s = re.sub(f'\[?\d+ items', '', s)
    s = re.sub(f'(?<=[L\"\de])\n(?!}})', ',\n', s)
    s = re.sub(f'NULL', '-1', s)
    s = re.sub(f'(\d+):', '\"\g<1>\":', s)
    s = re.sub(f"\"props\":\n", '', s)
    s = re.sub('}', '},', s)
    s= re.sub(f'\n]\n', f'\n', s)
    s = s.strip()[:-1] #since an extra comma is at the end

    # %%
    contents = json.loads(s)
    contents.pop('resultsPerPage')
    contents.pop('totalResultCount')
    contents.pop('totalPages')

    # %%
    df = pd.DataFrame(contents).T
    df.drop(['listingDateTime', 'listingStatus', 'zpid', 'lotAreaUnit', 'daysOnZillow', 'country', 'currency'], axis=1, inplace=True)

    # %%
    source = df['address'].to_list()

    # %%
    for m in ['driving', 'walking', 'bicycling']:
        results = []
        for i in range(len(source)//25):
            subsource = source[25*i : 25*(i+1)]
            print(len(subsource))
            subsourcestr = '|'.join(subsource)
            r = gettime(subsourcestr, dest, api_key, m)
            results.append(r)

        subsource = source[25*(len(source)//25) : ]
        print(len(subsource))
        subsourcestr = '|'.join(subsource)
        r = gettime(subsourcestr, dest, api_key, m)
        results.append(r)

        seconds = []
        for r in results:
            for e in r['rows']:
                seconds.append(e['elements'][0]['duration']['value'])
        df[m] = seconds
        df[m] = (df[m]/60).astype(int)

    df['price'] = df['price']/100
    allapts.append(df)

df = pd.concat(allapts)
df.to_csv('apartments.csv', index=False)
