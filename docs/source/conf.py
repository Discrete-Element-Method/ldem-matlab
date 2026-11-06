"""Sphinx configuration for LDEM-MATLAB."""
import os
import subprocess
import sys

project = "LDEM-MATLAB"
author = "Boris Rojo Tanzi"
copyright = "2026, Boris Rojo Tanzi"
release = "0.1.0"

extensions = [
    "sphinxcontrib.matlab",
    "sphinx.ext.autodoc",
    "myst_parser",
]

# --- MATLAB API (generated from the .m comments) ---------------------------
matlab_src_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
matlab_short_links = True
matlab_auto_link = "basic"
primary_domain = "mat"
highlight_language = "matlab"

# --- General ----------------------------------------------------------------
source_suffix = {".rst": "restructuredtext", ".md": "markdown"}
exclude_patterns = ["_build", "_generated/*"]
language = "en"

# --- Authors: generated from the git history on every build -----------------
_tools = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "tools"))
subprocess.run([sys.executable, os.path.join(_tools, "generate_authors.py")],
               check=True, stdout=subprocess.DEVNULL)

templates_path = ["_templates"]
html_sidebars = {
    "**": [
        "sidebar/scroll-start.html",
        "sidebar/brand.html",
        "sidebar/search.html",
        "sidebar/languages.html",
        "sidebar/navigation.html",
        "sidebar/ethical-ads.html",
        "sidebar/scroll-end.html",
    ]
}

html_theme = "furo"
html_title = "LDEM-MATLAB"
html_static_path = ["_static"]
