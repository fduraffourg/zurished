from setuptools import setup

setup(
        name="zurished",
        version="0.1",
        license="GPL",
        packages=['backend'],
        entry_points = {'console_scripts': ['zurished = backend:main']},
        )
