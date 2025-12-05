#!/usr/bin/env zsh
set -euo pipefail

UPGRADE_FLAG=""
DO_CONDA_UPGRADE="0"
if [[ "${1:-}" == "--upgrade" ]]; then
    UPGRADE_FLAG="--upgrade"
    DO_CONDA_UPGRADE="1"
fi

eval "$(conda shell.zsh hook)"
conda activate qmcpy

if [[ "$DO_CONDA_UPGRADE" == "1" ]]; then
    conda update --all -y
fi

QMCPY_BRANCH="${QMCPY_BRANCH:-develop}"

cd "$HOME/SoftwareRepositories/QMCSoftware"
git fetch origin "$QMCPY_BRANCH" --quiet
git checkout "$QMCPY_BRANCH" --quiet
git pull --rebase origin "$QMCPY_BRANCH" --quiet
pip install -e ".[dev,class]"

cd "$HOME/SoftwareRepositories/HickernellClassLib"
git pull --quiet
pip install -e . 

cd "$HOME/Documents/SharedConfigs/python"
if [[ -f "$HOME/Documents/SharedConfigs/python/requirements-qmcpy-extras-fred.txt" ]]; then
    pip install $UPGRADE_FLAG -r "$HOME/Documents/SharedConfigs/python/requirements-qmcpy-extras-fred.txt"
fi

if [[ -f "$HOME/SoftwareRepositories/MATH565Fall2025/requirements-course.txt" ]]; then
    cd "$HOME/SoftwareRepositories/MATH565Fall2025"
    pip install $UPGRADE_FLAG -r "$HOME/SoftwareRepositories/MATH565Fall2025/requirements-course.txt"
fi

echo "✓ qmcpy environment synced successfully"