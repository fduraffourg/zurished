import argparse
from aiohttp import web
import json
import os
import asyncio
from enum import Enum
from PIL import Image

THUMBNAIL = (200, 200)
RESIZES = [
    # (width, height)
    (800, 600),
    (1024, 768),
    (1920, 1080),
    ]


class CacheCreationException(Exception):
    """Raised when we can't create thing in the cache"""
    pass

class Cache(object):
    def __init__(self, path):
        # Root path of the cache
        self.root = path

    def get_full_path(self, path):
        return os.path.join(self.root, self.path)

    def get_and_prepare_path(self, path):
        """
        From the relative `path` given as input, compute the absolute path and
        prepare it by creating missing directories.
        """
        fullpath = os.path.join(self.root, path)

        dir = os.path.dirname(fullpath)
        if os.path.isdir(dir):
            return fullpath

        try:
            os.makedirs(dir, exist_ok=True)
            return fullpath
        except OSError:
            raise CacheCreationException


class Folder(object):
    def __init__(self, path, gallery):
        self.path = path
        self.gallery = gallery

        self._folders = None
        self._medias = None

    def list_content(self):
        print("List content for %s" % self.path)
        folders = []
        medias = []

        fullpath = os.path.join(self.gallery.rootdir, self.path)
        for direntry in os.scandir(fullpath):
            # If this is a directory, add it as a new folder
            if direntry.is_dir():
                folder = Folder(os.path.join(self.path, direntry.name), self.gallery)
                folders.append(folder)
                continue

            # Else this is a file
            media = Media(direntry.name,
                    direntry.path,
                    self)
            if not media.is_unknown():
                medias.append(media)

        self._folders = sorted(folders, key=lambda f: f.path)
        self._medias = sorted(medias, key=lambda m: m.name)

    @property
    def folders(self):
        if self._folders is None:
            self.list_content()
        return self._folders

    @property
    def medias(self):
        if self._medias is None:
            self.list_content()
        return self._medias

    def to_dict(self):
        return {
                'path': self.path,
                'folder': self.folders,
                'medias': self.medias
                }


class MediaType(Enum):
    unknown = 0
    image = 1


class Media(object):
    def __init__(self, name, realpath, folder):
        self.name = name
        self.realpath = realpath
        self.folder = folder

        try:
            image = Image.open(realpath)
            self.width = image.width
            self.height = image.height
            self.type = MediaType.image
        except:
            self.type = MediaType.unknown


    def is_unknown(self):
        return self.type == MediaType.unknown

    def to_dict(self):
        return {
                'name': self.name,
                'width': self.width,
                'height': self.height,
                'path': os.path.join(self.folder.path, self.name),
                }


def serve_static_file(path):
    BUFSIZE=1024
    with open(path, "rb") as fo:
        response = web.StreamResponse()
        return web.Response(body=fo.read())


class Gallery(object):
    def __init__(self, rootdir, cache, resize_cmd="", thumbnail_cmd=""):
        self.rootdir = rootdir
        self.cache = cache
        self.rootfolder = Folder("", self)

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
        queue = [ self.rootfolder ]
        while len(queue) > 0:
            folder = queue.pop()

            for new_folder in folder.folders:
                queue.append(new_folder)

            for media in folder.medias:
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
        try:
            cache_path = self.cache.get_and_prepare_path(path)
        except CacheCreationException:
            return web.Response(body="Unable to create cache directory".encode('utf-8'))

        media_path = os.path.join(self.rootdir, path)

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
        try:
            cache_path = self.cache.get_and_prepare_path(path)
        except CacheCreationException:
            return web.Response(body="Unable to create cache directory".encode('utf-8'))

        media_path = os.path.join(self.rootdir, path)

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
    cache = Cache(args.cache)
    gallery = Gallery(args.root, cache, resize_cmd=args.resize_cmd, thumbnail_cmd=args.thumbnail_cmd)


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
