#!/usr/bin/env python
"""Generate the list of authors from the git history.

The authors are the people who made commits (``git shortlog``, with the
identities merged through ``.mailmap``) plus the authors listed in
``CITATION.cff`` who have no commit yet (original code, scientific
supervision, ...). Nothing is typed by hand: run this script, or build the
documentation, and the list is up to date.

Outputs
  AUTHORS.md                              list for the repository root
  docs/source/_generated/authors.rst      table included by the "Authors" pages

Usage:  python docs/tools/generate_authors.py
"""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def git_authors():
    """Return [(name, commits)] ordered by number of commits (mailmap applied)."""
    try:
        out = subprocess.run(
            ["git", "shortlog", "-sn", "--all"],
            cwd=ROOT, capture_output=True, text=True, check=True, encoding="utf-8",
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return None
    authors = []
    for line in out.splitlines():
        match = re.match(r"\s*(\d+)\s+(.+)", line)
        if match and "[bot]" not in match.group(2):
            authors.append((match.group(2).strip(), int(match.group(1))))
    return authors


def citation_authors():
    """Names listed under ``authors:`` in CITATION.cff."""
    path = ROOT / "CITATION.cff"
    if not path.is_file():
        return []
    names, family = [], None
    in_authors = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if re.match(r"^authors:", line):
            in_authors = True
        elif in_authors and re.match(r"^\S", line):
            in_authors = False
        if not in_authors:
            continue
        m = re.search(r"family-names:\s*(.+)", line)
        if m:
            family = m.group(1).strip().strip('"')
        m = re.search(r"given-names:\s*(.+)", line)
        if m and family:
            names.append(f"{m.group(1).strip().strip(chr(34))} {family}")
            family = None
    return names


def collect():
    authors = git_authors()
    cited = citation_authors()
    if authors is None:  # no git available: only the citation file
        return [(n, None) for n in cited]
    known = {n.casefold() for n, _ in authors}
    return authors + [(n, 0) for n in cited if n.casefold() not in known]


def write(authors):
    gen = ROOT / "docs" / "source" / "_generated"
    gen.mkdir(parents=True, exist_ok=True)

    def commits(n):
        return "" if n is None else str(n)

    rows = "\n".join(
        f"   * - {name}\n     - {commits(n) if n else '-'}" for name, n in authors
    )
    (gen / "authors.rst").write_text(
        ".. list-table::\n   :header-rows: 1\n   :widths: 75 25\n\n"
        "   * - Name\n     - Commits\n" + rows + "\n",
        encoding="utf-8",
    )

    md = ["# Authors", "",
          "Generated from the git history and `CITATION.cff` by "
          "`docs/tools/generate_authors.py`. Do not edit by hand.", "",
          "| Name | Commits |", "|------|---------|"]
    md += [f"| {name} | {commits(n) if n else '-'} |" for name, n in authors]
    (ROOT / "AUTHORS.md").write_text("\n".join(md) + "\n", encoding="utf-8")


if __name__ == "__main__":
    result = collect()
    write(result)
    for name, n in result:
        print(f"{name}: {n}")
