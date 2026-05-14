#!/usr/bin/env zsh

# NOTE:
# This Quarto render below is a representative smoke test for the current active
# teaching/research stack. When this course repo becomes archival, replace
# the path below with a newer active course/talk repo or a dedicated
# environment smoke-test repo.

set -euo pipefail

BOLD=$'\033[1m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'

UPGRADE_FLAG=""
DO_CONDA_UPGRADE="0"

if [[ "${1:-}" == "--upgrade" ]]; then
    UPGRADE_FLAG="--upgrade"
    DO_CONDA_UPGRADE="1"
fi

CONDA_EXE="/opt/miniconda3/bin/conda"
eval "$("$CONDA_EXE" shell.zsh hook)"
QMCPY_ENV="${QMCPY_ENV:-/opt/miniconda3/envs/qmcpy}"
conda activate "$QMCPY_ENV"

echo
echo "${BOLD}${YELLOW}===== qmcpy environment sync started: $(date '+%Y-%m-%d %H:%M:%S %Z') =====${RESET}"

python -m pip install --upgrade pip setuptools wheel

if [[ "$DO_CONDA_UPGRADE" == "1" ]]; then
    conda update --all -y
fi

QMCPY_BRANCH="${QMCPY_BRANCH:-develop}"
HCL_BRANCH="${HCL_BRANCH:-main}"

cd "$HOME/SoftwareRepositories/QMCSoftware"
git fetch origin "$QMCPY_BRANCH" --quiet
git checkout "$QMCPY_BRANCH" --quiet
git pull --rebase origin "$QMCPY_BRANCH" --quiet

ARCH=$(uname -m)
EXTRAS="dev,class"

if [[ "$ARCH" == "x86_64" ]]; then
    EXTRAS="class"
fi

python -m pip install $UPGRADE_FLAG -e ".[${EXTRAS}]"

cd "$HOME/SoftwareRepositories/HickernellAcademicLib"
git fetch origin "$HCL_BRANCH" --quiet
git checkout "$HCL_BRANCH" --quiet
git pull --rebase origin "$HCL_BRANCH" --quiet
python -m pip install $UPGRADE_FLAG -e .

if [[ -f "$HOME/Documents/SharedConfigs/python/requirements-qmcpy-extras-fred.txt" ]]; then
    cd "$HOME/Documents/SharedConfigs/python"
    python -m pip install $UPGRADE_FLAG -r "$HOME/Documents/SharedConfigs/python/requirements-qmcpy-extras-fred.txt"
fi

if [[ -f "$HOME/SoftwareRepositories/MATH565Fall2025/requirements-course.txt" ]]; then
    cd "$HOME/SoftwareRepositories/MATH565Fall2025"
    python -m pip install $UPGRADE_FLAG -r "$HOME/SoftwareRepositories/MATH565Fall2025/requirements-course.txt"
fi

echo
echo "${BOLD}${YELLOW}===== verifying qmcpy environment =====${RESET}"

python -m pip check

python - <<'PY'
import qmcpy
import numpy
import scipy
import matplotlib
import jupyterlab

print("qmcpy: import OK")
print("numpy:", numpy.__version__)
print("scipy:", scipy.__version__)
print("matplotlib:", matplotlib.__version__)
print("jupyterlab:", jupyterlab.__version__)
PY

echo
echo "${BOLD}${YELLOW}===== checking Jupyter kernels =====${RESET}"

jupyter kernelspec list

if [[ ! -d "$HOME/Library/Jupyter/kernels/qmcpy" ]]; then
    echo "${BOLD}${YELLOW}WARNING: qmcpy user kernel not found${RESET}"
fi

if [[ ! -d "$HOME/Library/Jupyter/kernels/qmcpy-dev" ]]; then
    echo "${BOLD}${YELLOW}WARNING: qmcpy-dev user kernel not found${RESET}"
fi

echo
echo "${BOLD}${YELLOW}===== rendering representative Quarto slide deck =====${RESET}"

if [[ -f "$HOME/SoftwareRepositories/MATH563Spring2026/slides/01-intro.qmd" ]]; then
    cd "$HOME/SoftwareRepositories/MATH563Spring2026"
    quarto render slides/01-intro.qmd
else
    echo "${BOLD}${YELLOW}WARNING: representative slide deck not found; skipping Quarto render test${RESET}"
fi

echo
python --version
which python

echo
echo "${BOLD}${GREEN}===== qmcpy environment synced successfully: $(date '+%Y-%m-%d %H:%M:%S %Z') =====${RESET}"
