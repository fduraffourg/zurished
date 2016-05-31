# Zurished web photo gallery

If you have a well defined structure to organize your photo and just want a
tool that exposes this structure on the web, Zurished is made for you!

Zurished reads the content of a directory and show it on your browser. Zurished
displays resized images to increase load time and reduce network usage. Images
are resized on-demand and cached.

The frontend is simple: browse your folder list and show images. No useless
animations. Developed with Elm, it provides great stability. It fits all in one
page that do the job. All further communication with the backend is to retrieve
content.

## Installation and usage

The backend can be installed with python:

    python3 setup.py install

The frontend need to be compiled and integrated into the final page:

    ./make-frontend.sh

The final page will be located at `target/index.html`.

You can now start the backend server:

    zurished -r /folder/with/photos -s target

`target` is the folder that holds the `index.html` file.
