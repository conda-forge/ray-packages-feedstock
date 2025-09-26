# Call like python3 __file__ python/ray/_version.py 2.49.2

import json; 
import os
import sys
from urllib.request import urlopen; 

versionpy = sys.argv[1]
ver = sys.argv[2]

assert os.path.exists(versionpy)

content = urlopen(f'https://api.github.com/repos/ray-project/ray/git/ref/tags/ray-{ver}').read()
sha = json.loads(content)['object']['sha']
with open(versionpy, 'r') as fid:
    txt = fid.read()
txt = txt.replace("{{RAY_COMMIT_SHA}}", sha)
assert f'version = "{ver}"' in txt
assert f'commit = "{sha}"' in txt
with open(versionpy, 'w') as fid:
    fid.write(txt)
