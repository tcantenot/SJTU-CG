### py2exe setup file ###

from distutils.core import setup
import py2exe, glob, os

includes = [
    'OpenGL.platform.win32',
    "OpenGL_accelerate.formathandler"
] + [
    'OpenGL.arrays.%s'%x for x in [
        'ctypesarrays','ctypesparameters','ctypespointers',
        'lists','nones','numbers','numpymodule','strings','vbo'
    ]
]

excludes = [
    '_gtkagg', '_tkagg', 'bsddb', 'curses', 'email', 'pywin.debugger',
    'pywin.debugger.dbgcon', 'pywin.dialogs', 'tcl', 'Tkconstants', 'Tkinter',
    'ode', '_ssl', 'bz2', 'email', 'calendar', 'doctest', 'ftplib',
    'getpass', 'gopherlib', 'macpath', 'macurl2path', 'PIL.PaletteFile',
    'multiprocessing', 'Pyrex', 'distutils', 'pydoc', 'py_compile',
    'compiler',
]

packages = []
dll_excludes = ['w9xpopen.exe'] # For Windows 95/98

def copy_dir(dir):
    base_dir = dir
    for (dirpath, dirnames, files) in os.walk(base_dir):
        for f in files:
            t = dirpath, [os.path.join(dirpath, f)]
            yield t

data_files=[f for f in copy_dir('assets')]

setup(windows = ['main.py'],
    options = {
        "py2exe": {
            "includes": includes,
            "excludes": excludes,
            "packages": packages,
            "dll_excludes": dll_excludes,
            "bundle_files": 1,
            "dist_dir": "dist",
            "skip_archive": False,
            "ascii": False,
            "custom_boot_script": '',
            "compressed": True,
            "optimize": 2,
            "unbuffered": True,
            "xref": False
        }
    },
    zipfile = None,
    data_files = data_files
)
