"""List installed distributions not named by any QMCSoftware dependency group."""

import importlib.metadata as metadata
import os
from pathlib import Path
import tomllib

from packaging.requirements import Requirement
from packaging.utils import canonicalize_name


repositories_root = Path(
    os.environ.get("SOFTWARE_REPOS_ROOT", Path.home() / "SoftwareRepositories")
)
qmcpy_repository = Path(os.environ.get("QMCPY_REPO", repositories_root / "QMCSoftware"))
pyproject = qmcpy_repository / "pyproject.toml"

with pyproject.open("rb") as stream:
    project = tomllib.load(stream)["project"]

declared = set()
requirement_groups = [project.get("dependencies", [])]
requirement_groups.extend(project.get("optional-dependencies", {}).values())
for group in requirement_groups:
    for value in group:
        declared.add(canonicalize_name(Requirement(value).name))

installed = {
    canonicalize_name(distribution.metadata["Name"])
    for distribution in metadata.distributions()
    if distribution.metadata["Name"]
}

for name in sorted(installed - declared):
    print(name)
