"""Verify that qmcpy and classlib import from their editable source checkouts."""

import os
from pathlib import Path
import sys

import classlib
import qmcpy


def verify_editable(module: object, repository: Path) -> None:
    module_path = Path(module.__file__).resolve()
    repository = repository.expanduser().resolve()
    if not module_path.is_relative_to(repository):
        raise RuntimeError(f"{module.__name__} imports from {module_path}, not {repository}")
    print(f"{module.__name__}: editable import OK ({module_path})")


repositories_root = Path(
    os.environ.get("SOFTWARE_REPOS_ROOT", Path.home() / "SoftwareRepositories")
)
qmcpy_repository = Path(os.environ.get("QMCPY_REPO", repositories_root / "QMCSoftware"))
hcl_repository = Path(
    os.environ.get("HCL_REPO", repositories_root / "HickernellAcademicLib")
)

print("Python:", Path(sys.executable).resolve())
verify_editable(qmcpy, qmcpy_repository)
verify_editable(classlib, hcl_repository)
