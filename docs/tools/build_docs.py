#!/usr/bin/env python
"""Build the documentation in every language.

The pages are written in English (``docs/source/``); the other languages are
built from the same pages with the translation catalogs of ``docs/locale/``.
Each language is its own site, in ``docs/build/html/<language>/``, and
``docs/build/html/index.html`` sends the reader to the English one. Warnings are
errors (``-W``), so the documentation must build without any.

Usage:
    python docs/tools/build_docs.py                       all languages
    python docs/tools/build_docs.py --languages en es     only some
    python docs/tools/build_docs.py --output some/folder
"""
import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs" / "source"
LANGUAGES = [("en", "English"), ("es", "Español"), ("pt", "Português"), ("it", "Italiano")]


def build(language, output):
    """Run Sphinx for one language; return True when it built without warnings."""
    print("== Building the documentation in %s" % language, flush=True)
    result = subprocess.run(
        [sys.executable, "-m", "sphinx", "-W", "--keep-going", "-q", "-b", "html",
         "-D", "language=%s" % language, str(SOURCE), str(output / language)],
    )
    return result.returncode == 0


def write_redirect(output, languages):
    links = " &middot; ".join('<a href="%s/index.html">%s</a>' % (code, name)
                              for code, name in LANGUAGES if code in languages)
    (output / "index.html").write_text(
        '<!doctype html>\n<meta charset="utf-8">\n<title>LDEM-MATLAB</title>\n'
        '<meta http-equiv="refresh" content="0; url=en/index.html">\n'
        '<p>LDEM-MATLAB documentation: %s</p>\n' % links,
        encoding="utf-8",
    )


def main():
    codes = [code for code, _ in LANGUAGES]
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--languages", nargs="+", default=codes, choices=codes)
    parser.add_argument("--output", default=str(ROOT / "docs" / "build" / "html"))
    args = parser.parse_args()
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)

    failed = [language for language in args.languages if not build(language, output)]
    write_redirect(output, args.languages)
    if failed:
        print("The documentation did not build without warnings in: %s" % ", ".join(failed))
        return 1
    print("Documentation written to %s (open %s)" % (output, output / "index.html"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
