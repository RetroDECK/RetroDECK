project = 'RetroDECK'
author = 'RetroDECK Team'

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.doctest',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
    'sphinx.ext.coverage',
    'sphinx.ext.mathjax',
    'sphinx.ext.ifconfig',
    'sphinx.ext.viewcode',
    'sphinx_rtd_theme',
    'myst_parser',
]

language = 'English'
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
html_theme = "sphinx_rtd_theme"

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
source_suffix = [".md"]
# source_suffix = '.rst'

# The master toctree document.
master_doc = "index"