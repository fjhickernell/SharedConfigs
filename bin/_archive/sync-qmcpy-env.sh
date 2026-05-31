#!/usr/bin/env zsh
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
CONDA_SH="/opt/miniconda3/etc/profile.d/conda.sh"

if [[ ! -x "$CONDA_EXE" ]]; then
    echo "${BOLD}${YELLOW}ERROR: conda not found at $CONDA_EXE${RESET}"
    exit 1
fi

if [[ ! -f "$CONDA_SH" ]]; then
    echo "${BOLD}${YELLOW}ERROR: conda shell setup not found at $CONDA_SH${RESET}"
    exit 1
fi

source "$CONDA_SH"

if ! "$CONDA_EXE" env list | awk '{print $1}' | grep -qx "qmcpy"; then
    echo "${BOLD}${YELLOW}ERROR: qmcpy environment not found${RESET}"
    echo "Create it first with:"
    echo "  conda create -y -n qmcpy python=3.13"
    exit 1
fi

conda activate qmcpy

EXPECTED_PYTHON="${EXPECTED_PYTHON:-3.13}"
ACTUAL_PYTHON="$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')"

if [[ "$ACTUAL_PYTHON" != "$EXPECTED_PYTHON" ]]; then
    echo "${BOLD}${YELLOW}ERROR: expected Python $EXPECTED_PYTHON, got $(python --version 2>&1) at $(which python)${RESET}"
    exit 1
fi

echo
echo "${BOLD}${YELLOW}===== qmcpy environment sync started: $(date '+%Y-%m-%d %H:%M:%S %Z') =====${RESET}"

python -m pip install --upgrade pip wheel
python -m pip install "setuptools<82"

if [[ "$DO_CONDA_UPGRADE" == "1" ]]; then
    conda update --all -y
fi

QMCPY_BRANCH="${QMCPY_BRANCH:-develop}"
HCL_BRANCH="${HCL_BRANCH:-main}"

cd "$HOME/SoftwareRepositories/QMCSoftware"
git fetch origin "$QMCPY_BRANCH" --quiet
git checkout "$QMCPY_BRANCH" --quiet
git pull --rebase origin "$QMCPY_BRANCH" --quiet

ARCH="$(uname -m)"
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
echo "${BOLD}${YELLOW}===== refreshing Jupyter kernel =====${RESET}"

python -m ipykernel install --user --name qmcpy --display-name "qmcpy"

if [[ -d "$HOME/Library/Jupyter/kernels/qmcpy-dev" ]]; then
    echo "${BOLD}${YELLOW}WARNING: stale qmcpy-dev kernel still exists; remove with:${RESET}"
    echo "  jupyter kernelspec remove -f qmcpy-dev"
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
import yaml

print("qmcpy: import OK")
print("numpy:", numpy.__version__)
print("scipy:", scipy.__version__)
print("matplotlib:", matplotlib.__version__)
print("jupyterlab:", jupyterlab.__version__)
print("yaml: import OK")
PY

echo
echo "${BOLD}${YELLOW}===== checking Jupyter kernels =====${RESET}"

jupyter kernelspec list

if [[ ! -d "$HOME/Library/Jupyter/kernels/qmcpy" ]]; then
    echo "${BOLD}${YELLOW}ERROR: qmcpy user kernel not found${RESET}"
    exit 1
fi

echo
echo "${BOLD}${YELLOW}===== checking Quarto Python =====${RESET}"

export QUARTO_PYTHON="$(python -c 'import sys; print(sys.executable)')"

echo "QUARTO_PYTHON=$QUARTO_PYTHON"

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

mkdir -p "$HOME/Documents/SharedConfigs/reports/qmcpy-env"

echo "$(hostname -s)  $(date '+%Y-%m-%d %H:%M:%S %Z')  $(python --version 2>&1)  qmcpy $(python -c 'import qmcpy; print(qmcpy.__version__)')" >> "$HOME/Documents/SharedConfigs/reports/qmcpy-env/qmcpy-upgrade-log.txt"

echo
echo "${BOLD}${YELLOW}===== qmcpy upgrade log =====${RESET}"
tail -n 20 "$HOME/Documents/SharedConfigs/reports/qmcpy-env/qmcpy-upgrade-log.txt"

echo
echo "${BOLD}${GREEN}===== qmcpy environment synced successfully: $(date '+%Y-%m-%d %H:%M:%S %Z') =====${RESET}"