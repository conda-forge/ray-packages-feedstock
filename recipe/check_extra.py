"""Fail if the test env does not satisfy ray's own Requires-Dist for one extra.

pip check (run by the python tests) only covers unconditional requirements, so
dependency drift in the ray[extra] outputs would otherwise go unnoticed.

Usage: python check_extra.py <extra> [skipped-dist-name ...]
"""

import json
import sys
from importlib.metadata import PackageNotFoundError, distribution, version
from pathlib import Path

from packaging.requirements import Requirement
from packaging.utils import canonicalize_name

extra = sys.argv[1]
skip = {canonicalize_name(name) for name in sys.argv[2:]}

# Some conda packages (e.g. py-spy) ship only a binary and no Python dist-info,
# so fall back to conda's own install records.
conda_versions = {}
for record in (Path(sys.prefix) / "conda-meta").glob("*.json"):
    meta = json.loads(record.read_text())
    conda_versions[canonicalize_name(meta["name"])] = meta["version"]


def installed_version(name):
    try:
        return version(name)
    except PackageNotFoundError:
        return conda_versions.get(canonicalize_name(name))


bad = []
for req in map(Requirement, distribution("ray").requires or []):
    # Unconditional requirements are already covered by pip check.
    if req.marker is None or canonicalize_name(req.name) in skip:
        continue
    if not req.marker.evaluate({"extra": extra}):
        continue
    have = installed_version(req.name)
    if have is None:
        bad.append(f"{req}  -> missing")
        continue
    if not req.specifier.contains(have, prereleases=True):
        bad.append(f"{req}  -> have {have}")

if bad:
    sys.exit(f"ray[{extra}] requirements not met:\n  " + "\n  ".join(bad))
print(f"ray[{extra}] OK")
