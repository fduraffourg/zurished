from setuptools import setup

setup(
    name="zurished",
    version="0.1",
    license="GPL",
    packages=['zurished'],
    package_dir={'zurished': 'backend'},
    entry_points = {'console_scripts': ['zurished = zurished.main:main']},
)
