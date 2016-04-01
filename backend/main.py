import argparse
from aiohttp import web
import json
import os
import asyncio
from album import Album

THUMBNAIL = (200, 200)
RESIZES = [
    # (width, height)
    (1024, 768),
    (1920, 1080),
    ]


def prepare_cache_directory(path):
    pass


def serve_static_file(path):
    BUFSIZE=1024
    with open(path, "rb") as fo:
        response = web.StreamResponse()
        return web.Response(body=fo.read())


class Gallery(object):
    def __init__(self, rootdir, cachedir):
        self.rootdir = rootdir
        self.cachedir = cachedir
        self.rootalbum = Album("", rootdir)

    def list_all_medias(self):
        medias = []
        queue = [ self.rootalbum ]
        while len(queue) > 0:
            album = queue.pop()

            for new_album in album.albums:
                queue.append(new_album)

            for media in album.medias:
                medias.append(media.to_dict())
        return medias

    def to_json(self):
        def fallback_to_dict(obj):
            to_dict = getattr(obj, "to_dict", None)
            if callable(to_dict):
                return obj.to_dict()
            else:
                raise TypeError

        return json.dumps(self, default=fallback_to_dict)

    def to_dict(self):
        return {
                'album': self.rootalbum,
                'sizes': RESIZES,
                }

    async def web_gallery_handler(self, request):
        result = {
            "sizes": RESIZES,
            "images": self.list_all_medias()
            }
        dump = json.dumps(result)
        return web.Response(body=dump.encode('utf-8'))

    @asyncio.coroutine
    def web_resize_handler(self, request):
        width = request.match_info['width']
        height = request.match_info['height']
        path = request.match_info['path']

        # Verify that the given size is correct
        try:
            size = (int(width), int(height))
        except ValueError:
            return web.Response(body="Bad dimensions for resising".encode('utf-8'))

        square = None
        for w, h, s in RESIZES:
            if size == (w, h):
                square = s
                break
        if square is None:
            return web.Response(body="Bad dimensions for resising".encode('utf-8'))


        # Build paths of the image and of the cache
        cache_path = os.path.join(self.cachedir,
                "resized/%sx%s" % (width, height),
                path)
        media_path = os.path.join(self.rootdir, path)

        # If the image is already on the cache, send it
        if os.path.isfile(cache_path):
            print("Serve from cache (%s)" % cache_path)
            return serve_static_file(cache_path)

        # Otherwise, need to create the cache file
        command = "convert %s -resize %sx%s %s" % (
                media_path,
                width,
                height,
                cache_path)
        create_process = asyncio.create_subprocess_shell(command)
        process = yield from create_process
        return_code = yield from process.wait()
        if return_code == 0:
            return serve_static_file(cache_path)
        else:
            return web.Response(body="Error when resizing the media".encode('utf-8'))


def main():
    parser = argparse.ArgumentParser(description='Simple photo gallery server')
    parser.add_argument('-r', '--root', type=str, required=True,
            help="Root directory of the photo gallery")
    parser.add_argument('-c', '--cache', type=str, default="/var/cache/zurished",
            help="Cache folder to use")
    args = parser.parse_args()


    # Create the main gallery
    gallery = Gallery(args.root, args.cache)


    # Run the webserver
    app = web.Application()
    app.router.add_route('GET', '/gallery', gallery.web_gallery_handler)
    app.router.add_route('GET', '/resize/{width}/{height}/{path:.*}', gallery.web_resize_handler)
    web.run_app(app)

if __name__ == '__main__':
    main()
