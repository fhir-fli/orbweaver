"""The orbweaver checkout that a tool script lives in.

Every script under tool/ resolves the books, the PDFs and its output folder
from here, so the scripts run on any machine and in CI. Measured 2026-09-22:
CI run 35782849915 printed, from tool/crossbook_dose_extract.py,
FileNotFoundError for /home/grey/dev/fhir/orbweaver/assets/books/protocolbook/
formulary.yaml; 30 scripts carried that same hardcoded checkout path.
"""
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
