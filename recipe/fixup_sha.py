# Call like python3 __file__ python/ray/_version.py 2.49.2

import json
import os
import sys
import time
from urllib.request import HTTPError, urlopen


def get_commit_sha(ver: str) -> str:
    """
    Return sha from version tag commit
    
    Use retry information in headers and exponential backoff to address rate limiting issues.
    See: https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api?apiVersion=2022-11-28#handle-rate-limit-errors-appropriately
    """
    exp_backoff = 60
    retry_count = 0
    while True:
        try:
            content = urlopen(
                f"https://api.github.com/repos/ray-project/ray/git/ref/tags/ray-{ver}"
            ).read()
            return json.loads(content)["object"]["sha"]
        except HTTPError as e:
            if retry_count < 10 and e.code == 403 and e.msg == "rate limit exceeded":
                retry_count += 1
                timeout = exp_backoff
                if "retry-after" in e.hdrs:
                    timeout = int(e.hdrs["retry-after"])
                elif e.hdrs.get("x-ratelimit-remaining", None) == "0":
                    timeout = max(int(e.hdrs["x-ratelimit-reset"]) - time.gmtime(), 0)
                else:
                    exp_backoff *= 1.5
                print(f"{e}:, retrying after {timeout} s", file=sys.stderr)
                time.sleep(timeout)
                continue
            raise


versionpy = sys.argv[1]
ver = sys.argv[2]

assert os.path.exists(versionpy)

with open(versionpy, "r") as fid:
    txt = fid.read()

sha = get_commit_sha(ver)

txt = txt.replace("{{RAY_COMMIT_SHA}}", sha)
assert f'version = "{ver}"' in txt
assert f'commit = "{sha}"' in txt
with open(versionpy, "w") as fid:
    fid.write(txt)
