import argparse
from aiohttp import web
import json
import os
import asyncio
from zurished.album import Album

THUMBNAIL = (200, 200)
RESIZES = [
    # (width, height)
    (800, 600),
    (1024, 768),
    (1920, 1080),
    ]


def prepare_cache_directory(path):
    dir = os.path.dirname(path)
    if os.path.isdir(dir):
        return True

    try:
        os.makedirs(dir, exist_ok=True)
        return True
    except OSError:
        return False


def serve_static_file(path):
    BUFSIZE=1024
    with open(path, "rb") as fo:
        response = web.StreamResponse()
        return web.Response(body=fo.read())


class Gallery(object):
    def __init__(self, rootdir, cachedir, resize_cmd="", thumbnail_cmd=""):
        self.rootdir = rootdir
        self.cachedir = cachedir
        self.rootalbum = Album("", rootdir)

        if resize_cmd != "":
            self.resize_cmd = resize_cmd
        else:
            self.resize_cmd = "convert '{src}' -resize {width}x{height} '{dst}'"

        if thumbnail_cmd != "":
            self.thumbnail_cmd = thumbnail_cmd
        else:
            self.thumbnail_cmd = "convert '{src}' -thumbnail {width}x{height}^ -gravity center -extent {width}x{height} '{dst}'"

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

        if size not in RESIZES:
            return web.Response(body="Bad dimensions for resising".encode('utf-8'))


        # Build paths of the image and of the cache
        cache_path = os.path.join(self.cachedir,
                "resized/%sx%s" % (width, height),
                path)
        media_path = os.path.join(self.rootdir, path)

        # Create the cache directory if necessary
        if not prepare_cache_directory(cache_path):
            return web.Response(body="Unable to create cache directory".encode('utf-8'))


        # If the image is already on the cache, send it
        if os.path.isfile(cache_path):
            print("Serve from cache (%s)" % cache_path)
            return serve_static_file(cache_path)

        # Otherwise, need to create the cache file
        command = self.resize_cmd.format(
                src=media_path,
                dst=cache_path,
                width=width,
                height=height,
                )
        create_process = asyncio.create_subprocess_shell(command)
        process = yield from create_process
        return_code = yield from process.wait()
        if return_code == 0:
            return serve_static_file(cache_path)
        else:
            return web.Response(body="Error when resizing the media".encode('utf-8'))

    @asyncio.coroutine
    def web_thumbnail_handler(self, request):
        path = request.match_info['path']

        # Build paths of the image and of the cache
        cache_path = os.path.join(self.cachedir,
                "thumbnails",
                path)
        media_path = os.path.join(self.rootdir, path)

        # Create the cache directory if necessary
        if not prepare_cache_directory(cache_path):
            return web.Response(body="Unable to create cache directory".encode('utf-8'))


        # If the image is already on the cache, send it
        if os.path.isfile(cache_path):
            print("Serve from cache (%s)" % cache_path)
            return serve_static_file(cache_path)

        # Otherwise, need to create the cache file
        command = self.thumbnail_cmd.format(
                src=media_path,
                dst=cache_path,
                width=THUMBNAIL[0],
                height=THUMBNAIL[1],
                )
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
    parser.add_argument('-s', '--static', type=str, default="",
            help="Static content to serve")
    parser.add_argument('-p', '--port', type=int, default=8080,
            help="Port to listen to")
    parser.add_argument('--resize-cmd', type=str, default="",
            help="""Command used to resize images
                    You can use {src} {dst} {width} and {height}""")
    parser.add_argument('--thumbnail-cmd', type=str, default="",
            help="""Command used to resize images
                    You can use {src} {dst} {width} and {height}""")
    args = parser.parse_args()


    # Create the main gallery
    gallery = Gallery(args.root, args.cache, resize_cmd=args.resize_cmd, thumbnail_cmd=args.thumbnail_cmd)


    # Run the webserver
    app = web.Application()
    app.router.add_route('GET', '/gallery', gallery.web_gallery_handler)
    app.router.add_route('GET', '/medias/resized/{width}x{height}/{path:.*}', gallery.web_resize_handler)
    app.router.add_route('GET', '/medias/thumbnail/{path:.*}', gallery.web_thumbnail_handler)
    app.router.add_static('/medias/full/', args.root)
    app.router.add_static('/', args.static)
    web.run_app(app, port=args.port)

if __name__ == '__main__':
    main()
