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
]

source_suffix = '.rst'
master_doc = 'index'
language = 'English'
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
pygments_style = None
html_theme = "sphinx_rtd_theme"