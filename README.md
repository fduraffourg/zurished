# Zurished web photo gallery

If you have a well defined structure to organize your photos and just want a
tool that exposes this structure on the web, Zurished is made for you!

Zurished reads the content of a directory and show it on your browser. Zurished
displays resized images to increase load time and reduce network usage. Images
are resized on-demand and cached.

The frontend is simple: browse your folder list and show images. No useless
animations. Developed with Elm, it provides great stability. It fits all in one
page that do the job. All further communication with the backend is to retrieve
content.

## Installation and usage

### Backend

It depends on the following python3 modules:

- asyncio
- aiohttp
- pyinotify

By default, the backend uses ImageMagick to resize images. But you can use your
own program by specifying a command to use (see `zurished --help`).

It can be installed with:

    python3 setup.py install

### Frontend

It depends on Elm version 0.17.

Use the following command to compile and create the HTML page:

    ./make-frontend.sh

The final page will be located at `target/index.html`.

### Usage

You can now start the backend server:

    zurished -r /folder/with/photos -s target -c cache/dir

`target` is the folder that holds the `index.html` file.

See `zurished --help` for available options

Finally go to:

http://localhost:8080/index.html
