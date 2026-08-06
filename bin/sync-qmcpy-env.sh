#!/usr/bin/env zsh
set -euo pipefail

GREEN_BOLD=$'\033[1;32m'
MAGENTA_BOLD=$'\033[1;35m'
YELLOW_BOLD=$'\033[1;33m'
RED_BOLD=$'\033[1;31m'
NC=$'\033[0m'

timestamp() {
  /bin/date '+%Y-%m-%d %H:%M:%S %Z'
}

banner() {
  printf "\n${GREEN_BOLD}===== [%s] %s =====${NC}\n" "$(timestamp)" "$1"
}

section() {
  printf "\n${MAGENTA_BOLD}--- %s ---${NC}\n" "$1"
}

warn() {
  printf "${YELLOW_BOLD}Warning:${NC} %s\n" "$1"
}

error() {
  printf "${RED_BOLD}Error:${NC} %s\n" "$1" >&2
}

usage() {
  cat <<'EOF'
Usage: sync-qmcpy-env.sh [--upgrade]

Synchronize editable QMCPy development installs and run environment smoke tests.
Use --upgrade for the May 15, August 1, and December 15 academic maintenance runs.

Optional environment overrides:
  CONDA_ROOT                 Miniconda root (default: /opt/miniconda3)
  QMCPY_ENV_NAME             Conda environment name (default: qmcpy)
  EXPECTED_PYTHON            Required Python major.minor (default: 3.13)
  SOFTWARE_REPOS_ROOT        Repository parent directory
  SHARED_CONFIGS_ROOT        SharedConfigs checkout
  QMCPY_REPO, QMCPY_BRANCH   QMCSoftware checkout and branch
  HCL_REPO, HCL_BRANCH       HickernellAcademicLib checkout and branch
  QMCPY_MAINTENANCE_CONFIG   Active-course config file
  QMCPY_ACTIVE_COURSE_REPO   Active course repository (relative or absolute)
  QMCPY_ACTIVE_COURSE_NOTEBOOK
                              Course notebook relative to the course repository
  QMCPY_ACTIVE_COURSE_QUARTO_DOCUMENT
                              Course .qmd relative to the course repository
  QMCPY_NOTEBOOK             Override the canonical environment notebook set
  QMCPY_ENV_QUARTO_DOCUMENT  Override the environment Quarto smoke fixture
EOF
}

UPGRADE_FLAG=""
DO_CONDA_UPGRADE="0"

case "${1:-}" in
  "") ;;
  --upgrade)
    UPGRADE_FLAG="--upgrade"
    DO_CONDA_UPGRADE="1"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    error "unknown option: $1"
    usage >&2
    exit 2
    ;;
esac

if (( $# > 1 )); then
  error "too many arguments"
  usage >&2
  exit 2
fi

CONDA_ROOT="${CONDA_ROOT:-/opt/miniconda3}"
CONDA_EXE="$CONDA_ROOT/bin/conda"
CONDA_SH="$CONDA_ROOT/etc/profile.d/conda.sh"
QMCPY_ENV_NAME="${QMCPY_ENV_NAME:-qmcpy}"

SOFTWARE_REPOS_ROOT="${SOFTWARE_REPOS_ROOT:-${HOME}/SoftwareRepositories}"
SHARED_CONFIGS_ROOT="${SHARED_CONFIGS_ROOT:-${HOME}/Documents/SharedConfigs}"
QMCPY_REPO="${QMCPY_REPO:-$SOFTWARE_REPOS_ROOT/QMCSoftware}"
HCL_REPO="${HCL_REPO:-$SOFTWARE_REPOS_ROOT/HickernellAcademicLib}"
QMCPY_BRANCH="${QMCPY_BRANCH:-develop}"
HCL_BRANCH="${HCL_BRANCH:-main}"

MAINTENANCE_CONFIG="${QMCPY_MAINTENANCE_CONFIG:-$SHARED_CONFIGS_ROOT/settings/qmcpy-env.conf}"
ACTIVE_COURSE_REPO=""
ACTIVE_COURSE_NOTEBOOK=""
ACTIVE_COURSE_QUARTO_DOCUMENT=""

if [[ -f "$MAINTENANCE_CONFIG" ]]; then
  source "$MAINTENANCE_CONFIG"
fi

if [[ -n "${QMCPY_COURSE_REPO:-}" && -z "${QMCPY_ACTIVE_COURSE_REPO:-}" ]]; then
  warn "QMCPY_COURSE_REPO is deprecated; use QMCPY_ACTIVE_COURSE_REPO"
fi

ACTIVE_COURSE_REPO_SETTING="${QMCPY_ACTIVE_COURSE_REPO:-${QMCPY_COURSE_REPO:-$ACTIVE_COURSE_REPO}}"
ACTIVE_COURSE_NOTEBOOK_SETTING="${QMCPY_ACTIVE_COURSE_NOTEBOOK:-$ACTIVE_COURSE_NOTEBOOK}"
ACTIVE_COURSE_QUARTO_SETTING="${QMCPY_ACTIVE_COURSE_QUARTO_DOCUMENT:-$ACTIVE_COURSE_QUARTO_DOCUMENT}"

if [[ -n "$ACTIVE_COURSE_REPO_SETTING" ]]; then
  if [[ "$ACTIVE_COURSE_REPO_SETTING" == /* ]]; then
    ACTIVE_COURSE_REPO_PATH="$ACTIVE_COURSE_REPO_SETTING"
  else
    ACTIVE_COURSE_REPO_PATH="$SOFTWARE_REPOS_ROOT/$ACTIVE_COURSE_REPO_SETTING"
  fi
else
  ACTIVE_COURSE_REPO_PATH=""
fi

if [[ -n "$ACTIVE_COURSE_NOTEBOOK_SETTING" ]]; then
  if [[ "$ACTIVE_COURSE_NOTEBOOK_SETTING" == /* ]]; then
    ACTIVE_COURSE_NOTEBOOK_PATH="$ACTIVE_COURSE_NOTEBOOK_SETTING"
  else
    ACTIVE_COURSE_NOTEBOOK_PATH="$ACTIVE_COURSE_REPO_PATH/$ACTIVE_COURSE_NOTEBOOK_SETTING"
  fi
else
  ACTIVE_COURSE_NOTEBOOK_PATH=""
fi

if [[ -n "$ACTIVE_COURSE_QUARTO_SETTING" ]]; then
  if [[ "$ACTIVE_COURSE_QUARTO_SETTING" == /* ]]; then
    ACTIVE_COURSE_QUARTO_PATH="$ACTIVE_COURSE_QUARTO_SETTING"
  else
    ACTIVE_COURSE_QUARTO_PATH="$ACTIVE_COURSE_REPO_PATH/$ACTIVE_COURSE_QUARTO_SETTING"
  fi
else
  ACTIVE_COURSE_QUARTO_PATH=""
fi

ACTIVE_COURSE_REQUIREMENTS=""
if [[ -n "$ACTIVE_COURSE_REPO_PATH" ]]; then
  for candidate in \
    "$ACTIVE_COURSE_REPO_PATH/requirements.txt" \
    "$ACTIVE_COURSE_REPO_PATH/requirements-course.txt"; do
    if [[ -f "$candidate" ]]; then
      ACTIVE_COURSE_REQUIREMENTS="$candidate"
      break
    fi
  done
fi

NOTEBOOKS=()
if [[ -n "${QMCPY_NOTEBOOK:-}" ]]; then
  NOTEBOOKS+=("$QMCPY_NOTEBOOK")
else
  for candidate in \
    "$QMCPY_REPO/demos/quickstart.ipynb" \
    "$QMCPY_REPO/demos/qmcpy_intro.ipynb"; do
    [[ -f "$candidate" ]] && NOTEBOOKS+=("$candidate")
  done
fi

ENV_QUARTO_DOCUMENT="${QMCPY_ENV_QUARTO_DOCUMENT:-$SHARED_CONFIGS_ROOT/python/qmcpy-env-smoke.qmd}"

for repo in "$QMCPY_REPO" "$HCL_REPO"; do
  if [[ ! -d "$repo/.git" ]]; then
    error "required Git checkout not found: $repo"
    exit 1
  fi
done

if [[ ! -x "$CONDA_EXE" ]]; then
  error "conda not found at $CONDA_EXE"
  exit 1
fi

if [[ ! -f "$CONDA_SH" ]]; then
  error "conda shell setup not found at $CONDA_SH"
  exit 1
fi

source "$CONDA_SH"

if ! "$CONDA_EXE" env list | awk '{print $1}' | grep -qx "$QMCPY_ENV_NAME"; then
  error "$QMCPY_ENV_NAME environment not found"
  echo "Create it first with:"
  echo "  conda create -y -n $QMCPY_ENV_NAME python=3.13"
  exit 1
fi

conda activate "$QMCPY_ENV_NAME"

EXPECTED_PYTHON="${EXPECTED_PYTHON:-3.13}"
ACTUAL_PYTHON="$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')"

if [[ "$ACTUAL_PYTHON" != "$EXPECTED_PYTHON" ]]; then
  error "expected Python $EXPECTED_PYTHON, got $(python --version 2>&1) at $(command -v python)"
  exit 1
fi

REPORT_DIR="$SHARED_CONFIGS_ROOT/reports/qmcpy-env"
mkdir -p "$REPORT_DIR"
RUN_STAMP="$(/bin/date '+%Y%m%d-%H%M%S')"
VALIDATION_REPORT="$REPORT_DIR/qmcpy-validation-$RUN_STAMP.txt"
LATEST_REPORT="$REPORT_DIR/qmcpy-validation-latest.txt"
SMOKE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/qmcpy-env-smoke.XXXXXX")"
trap 'rm -rf "$SMOKE_TMP"' EXIT
export MPLCONFIGDIR="${MPLCONFIGDIR:-$SMOKE_TMP/matplotlib}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$SMOKE_TMP/cache}"
mkdir -p "$MPLCONFIGDIR" "$XDG_CACHE_HOME"

COURSE_WARNINGS=()
course_warn() {
  warn "$1"
  COURSE_WARNINGS+=("$1")
}

banner "qmcpy environment sync started"
echo "Mode: $([[ "$DO_CONDA_UPGRADE" == "1" ]] && echo upgrade || echo sync)"
echo "Maintenance config: ${MAINTENANCE_CONFIG:-not found}"
echo "Active course repository: ${ACTIVE_COURSE_REPO_PATH:-not configured}"
if (( ${#NOTEBOOKS[@]} > 0 )); then
  printf "Environment notebooks:\n"
  printf "  %s\n" "${NOTEBOOKS[@]}"
else
  echo "Environment notebooks: not found"
fi
echo "Environment Quarto document: $ENV_QUARTO_DOCUMENT"

python -m pip install --upgrade pip wheel
python -m pip install "setuptools<82"

if [[ "$DO_CONDA_UPGRADE" == "1" ]]; then
  conda update --all -y
fi

ACTUAL_PYTHON="$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')"
if [[ "$ACTUAL_PYTHON" != "$EXPECTED_PYTHON" ]]; then
  error "upgrade changed the environment to unsupported $(python --version 2>&1)"
  exit 1
fi

section "Required environment setup"

for repo in "$QMCPY_REPO" "$HCL_REPO"; do
  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
    error "source checkout has uncommitted changes: $repo"
    exit 1
  fi
done

git -C "$QMCPY_REPO" fetch origin "$QMCPY_BRANCH" --quiet
git -C "$QMCPY_REPO" checkout "$QMCPY_BRANCH" --quiet
git -C "$QMCPY_REPO" pull --rebase origin "$QMCPY_BRANCH" --quiet

ARCH="$(uname -m)"
EXTRAS="dev,class"
if [[ "$ARCH" == "x86_64" ]]; then
  EXTRAS="class"
fi
# Reinstall source without re-resolving QMCPy's self-referential dev/docs/test
# extras. Conda and the maintained requirement files update dependencies; the
# mandatory pip check below detects missing or incompatible requirements.
python -m pip install --no-deps -e "${QMCPY_REPO}[${EXTRAS}]"

git -C "$HCL_REPO" fetch origin "$HCL_BRANCH" --quiet
git -C "$HCL_REPO" checkout "$HCL_BRANCH" --quiet
git -C "$HCL_REPO" pull --rebase origin "$HCL_BRANCH" --quiet
python -m pip install --no-deps -e "$HCL_REPO"

PERSONAL_REQUIREMENTS="$SHARED_CONFIGS_ROOT/python/requirements-qmcpy-extras-fred.txt"
if [[ -f "$PERSONAL_REQUIREMENTS" ]]; then
  python -m pip install $UPGRADE_FLAG -r "$PERSONAL_REQUIREMENTS"
else
  warn "personal requirements file not found: $PERSONAL_REQUIREMENTS"
fi

section "Required environment kernel validation"

python -m ipykernel install --user --name "$QMCPY_ENV_NAME" --display-name "$QMCPY_ENV_NAME"
jupyter kernelspec list

QMCPY_KERNEL_DIR="${HOME}/Library/Jupyter/kernels/$QMCPY_ENV_NAME"
if [[ ! -f "$QMCPY_KERNEL_DIR/kernel.json" ]]; then
  error "$QMCPY_ENV_NAME user kernel not found"
  exit 1
fi

KERNEL_PYTHON="$(python -c 'import json, pathlib, sys; print(pathlib.Path(json.load(open(sys.argv[1]))["argv"][0]).resolve())' "$QMCPY_KERNEL_DIR/kernel.json")"
ACTIVE_PYTHON="$(python -c 'import pathlib, sys; print(pathlib.Path(sys.executable).resolve())')"
if [[ "$KERNEL_PYTHON" != "$ACTIVE_PYTHON" ]]; then
  error "$QMCPY_ENV_NAME kernel uses $KERNEL_PYTHON instead of $ACTIVE_PYTHON"
  exit 1
fi

if [[ -d "${HOME}/Library/Jupyter/kernels/qmcpy-dev" ]]; then
  warn "legacy qmcpy-dev kernel still exists; remove it if no workflow uses it"
fi

section "Required environment package validation"

python -m pip check
QMCPY_REPO="$QMCPY_REPO" HCL_REPO="$HCL_REPO" \
  python "$SHARED_CONFIGS_ROOT/python/dev_check.py"

python - <<'PY'
import jupyterlab
import matplotlib
import numpy
import scipy
import yaml

print("numpy:", numpy.__version__)
print("scipy:", scipy.__version__)
print("matplotlib:", matplotlib.__version__)
print("jupyterlab:", jupyterlab.__version__)
print("yaml: import OK")
PY

section "Required environment notebook validation"

if (( ${#NOTEBOOKS[@]} == 0 )); then
  error "representative notebook not found"
  exit 1
fi

for notebook in "${NOTEBOOKS[@]}"; do
  if [[ ! -f "$notebook" ]]; then
    error "representative notebook not found: $notebook"
    exit 1
  fi
  jupyter nbconvert \
    --to notebook \
    --execute "$notebook" \
    --ExecutePreprocessor.kernel_name="$QMCPY_ENV_NAME" \
    --ExecutePreprocessor.timeout=900 \
    --output-dir "$SMOKE_TMP"
done

section "Required environment Quarto validation"

export QUARTO_PYTHON="$ACTIVE_PYTHON"
echo "QUARTO_PYTHON=$QUARTO_PYTHON"

if [[ -f "$ENV_QUARTO_DOCUMENT" ]]; then
  ENV_QUARTO_COPY="$SMOKE_TMP/${ENV_QUARTO_DOCUMENT:t}"
  cp "$ENV_QUARTO_DOCUMENT" "$ENV_QUARTO_COPY"
  (
    cd "$SMOKE_TMP"
    quarto render "${ENV_QUARTO_COPY:t}"
  )
else
  error "environment Quarto document not found: $ENV_QUARTO_DOCUMENT"
  exit 1
fi

section "Active course validation (advisory)"

COURSE_STATUS="NOT CONFIGURED"
COURSE_REQUIREMENTS_STATUS="NOT CONFIGURED"
COURSE_NOTEBOOK_STATUS="NOT CONFIGURED"
COURSE_QUARTO_STATUS="NOT CONFIGURED"
COURSE_WARNING_LOG="none"
COURSE_LOG_TMP="$SMOKE_TMP/active-course-validation.log"
: > "$COURSE_LOG_TMP"

if [[ -z "$ACTIVE_COURSE_REPO_PATH" ]]; then
  echo "No active course is configured; course validation skipped."
elif [[ ! -d "$ACTIVE_COURSE_REPO_PATH" ]]; then
  COURSE_STATUS="WARNING"
  COURSE_REQUIREMENTS_STATUS="NOT RUN"
  COURSE_NOTEBOOK_STATUS="NOT RUN"
  COURSE_QUARTO_STATUS="NOT RUN"
  course_warn "active course repository not found on this Mac: $ACTIVE_COURSE_REPO_PATH"
else
  COURSE_STATUS="PASS"
  echo "Repository: $ACTIVE_COURSE_REPO_PATH"

  if [[ -n "$ACTIVE_COURSE_REQUIREMENTS" ]]; then
    COURSE_REQUIREMENTS_STATUS="PRESENT (not installed by maintenance)"
    echo "Requirements: $ACTIVE_COURSE_REQUIREMENTS"
  else
    COURSE_REQUIREMENTS_STATUS="NOT PRESENT"
    echo "Requirements: none"
  fi

  if [[ -z "$ACTIVE_COURSE_NOTEBOOK_PATH" ]]; then
    COURSE_NOTEBOOK_STATUS="WARNING"
    course_warn "active course notebook is not configured"
  elif [[ ! -f "$ACTIVE_COURSE_NOTEBOOK_PATH" ]]; then
    COURSE_NOTEBOOK_STATUS="WARNING"
    course_warn "active course notebook not found: $ACTIVE_COURSE_NOTEBOOK_PATH"
  elif jupyter nbconvert \
      --to notebook \
      --execute "$ACTIVE_COURSE_NOTEBOOK_PATH" \
      --ExecutePreprocessor.kernel_name="$QMCPY_ENV_NAME" \
      --ExecutePreprocessor.timeout=900 \
      --output-dir "$SMOKE_TMP" >> "$COURSE_LOG_TMP" 2>&1; then
    COURSE_NOTEBOOK_STATUS="PASS"
    echo "Notebook: PASS"
  else
    COURSE_NOTEBOOK_STATUS="WARNING"
    course_warn "active course notebook failed; review course or experimental development dependencies without changing the canonical maintenance checkout"
  fi

  if [[ -z "$ACTIVE_COURSE_QUARTO_PATH" ]]; then
    COURSE_QUARTO_STATUS="WARNING"
    course_warn "active course Quarto document is not configured"
  elif [[ ! -f "$ACTIVE_COURSE_QUARTO_PATH" ]]; then
    COURSE_QUARTO_STATUS="WARNING"
    course_warn "active course Quarto document not found: $ACTIVE_COURSE_QUARTO_PATH"
  else
    ACTIVE_COURSE_QUARTO_REPO="$(git -C "${ACTIVE_COURSE_QUARTO_PATH:h}" rev-parse --show-toplevel 2>/dev/null || print -r -- "${ACTIVE_COURSE_QUARTO_PATH:h}")"
    if (
      cd "$ACTIVE_COURSE_QUARTO_REPO"
      quarto render "${ACTIVE_COURSE_QUARTO_PATH#$ACTIVE_COURSE_QUARTO_REPO/}"
    ) >> "$COURSE_LOG_TMP" 2>&1; then
      COURSE_QUARTO_STATUS="PASS"
      echo "Quarto: PASS"
    else
      COURSE_QUARTO_STATUS="WARNING"
      course_warn "active course Quarto rendering failed; environment validation remains independent"
    fi
  fi

  if (( ${#COURSE_WARNINGS[@]} > 0 )); then
    COURSE_STATUS="WARNING"
    COURSE_WARNING_LOG="$REPORT_DIR/qmcpy-course-warning-$RUN_STAMP.log"
    cp "$COURSE_LOG_TMP" "$COURSE_WARNING_LOG"
    echo "Course diagnostic log: $COURSE_WARNING_LOG"
  fi
fi

if (( ${#COURSE_WARNINGS[@]} > 0 )); then
  OVERALL_STATUS="PASS WITH COURSE WARNINGS"
else
  OVERALL_STATUS="PASS"
fi

section "Writing validation report"

{
  echo "QMCPy environment validation"
  echo "Date: $(timestamp)"
  echo "Host: $(hostname -s)"
  echo "Mode: $([[ "$DO_CONDA_UPGRADE" == "1" ]] && echo upgrade || echo sync)"
  echo "Overall status: $OVERALL_STATUS"
  echo "Environment validation: PASS"
  echo "Python: $(python --version 2>&1)"
  echo "Python executable: $ACTIVE_PYTHON"
  echo "QMCPy: $(python -c 'import qmcpy; print(qmcpy.__version__)')"
  echo "QMCPy source: $(python -c 'import qmcpy; print(qmcpy.__file__)')"
  echo "QMCPy revision: $(git -C "$QMCPY_REPO" rev-parse --short HEAD) ($QMCPY_BRANCH)"
  echo "classlib source: $(python -c 'import classlib; print(classlib.__file__)')"
  echo "HickernellAcademicLib revision: $(git -C "$HCL_REPO" rev-parse --short HEAD) ($HCL_BRANCH)"
  echo "Kernel Python: $KERNEL_PYTHON"
  printf "Environment notebooks: %s\n" "${NOTEBOOKS[*]}"
  echo "Environment Quarto document: $ENV_QUARTO_DOCUMENT"
  echo "Environment pip check: PASS"
  echo "Environment notebook execution: PASS"
  echo "Environment Quarto render: PASS"
  echo "Active course validation: $COURSE_STATUS"
  echo "Active course repository: ${ACTIVE_COURSE_REPO_PATH:-none}"
  echo "Active course requirements: $COURSE_REQUIREMENTS_STATUS"
  echo "Active course notebook: $COURSE_NOTEBOOK_STATUS"
  echo "Active course Quarto render: $COURSE_QUARTO_STATUS"
  echo "Active course warning log: $COURSE_WARNING_LOG"
  echo "Warnings:"
  if (( ${#COURSE_WARNINGS[@]} == 0 )); then
    echo "  none"
  else
    printf "  - %s\n" "${COURSE_WARNINGS[@]}"
  fi
} | tee "$VALIDATION_REPORT"

cp "$VALIDATION_REPORT" "$LATEST_REPORT"
echo "$(hostname -s)  $(timestamp)  $(python --version 2>&1)  qmcpy $(python -c 'import qmcpy; print(qmcpy.__version__)')  $([[ "$DO_CONDA_UPGRADE" == "1" ]] && echo upgrade || echo sync)  $OVERALL_STATUS" >> "$REPORT_DIR/qmcpy-upgrade-log.txt"

section "Recent qmcpy upgrade history"
tail -n 20 "$REPORT_DIR/qmcpy-upgrade-log.txt"

banner "qmcpy environment maintenance completed: $OVERALL_STATUS"
