#!/usr/bin/env zsh
UPGRADE_FLAG=""
if [[ "$1" == "--upgrade" ]]; then
    UPGRADE_FLAG="--upgrade"
fi

eval "$(conda shell.zsh hook)"
conda activate qmcpy

cd "$HOME/SoftwareRepositories/QMCSoftware"
git fetch origin develop --quiet
git checkout develop --quiet
git pull --rebase origin develop --quiet

pip install -e ".[dev]" -q
pip install $UPGRADE_FLAG -r "$HOME/Documents/SharedConfigs/python/requirements-qmcpy-fred.txt" -q
pip install $UPGRADE_FLAG -r "$HOME/SoftwareRepositories/MATH565Fall2025/requirements-course.txt" -q

cd "$HOME/SoftwareRepositories/HickernellClassLib"
git pull --quiet
pip install -e . -q

echo "✓ qmcpy environment synced successfully"