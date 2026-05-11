# QMC Environment Notes

This note tracks knowledge related to QMCPy environments, requirements, notebook practices, and upgrade routines.

---

## Environment Upgrade Cadence

- December 15
- May 15
- August 1

These dates align with your semester maintenance cycle.

---

## Upgrade Script Workflow

Use the script:
sync-qmcpy-env.sh

Steps:
1. Activate the qmcpy conda environment.
2. Fetch the develop branch of QMCSoftware.
3. Reinstall in editable mode using the `[dev]` extras group.

---

## Requirements Files to Track

Your personal files in SharedConfigs/python:

- requirements-qmcpy-fred.txt  
- requirements-qmcpy-fred-monster.txt

Compare these occasionally with QMCPy’s pyproject optional dependencies to avoid drift.

---

## Notebook Practices

- Use the Colab header cell standardized in QMCPy_Introduction.ipynb.
- Use nbstripout (and the check script) to ensure clean notebooks before committing.
- Maintain a canonical set of notebooks inside each teaching repo.
- When distributing notebooks to students, ensure full run-through without errors.

---

## Related

- [[Software/qmcpy|QMCSoftware]]
- [[MasterLists/Master Tech Projects]]