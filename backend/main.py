import argparse
from aiohttp import web
import json
import os
from album import Album

RESIZES=[
    # (width, height, square)
    (200, 200, True),
    (1024, 768, False),
    (1920, 1080, False),
    ]

class Gallery(object):
    def __init__(self, rootdir, cachedir):
        self.rootdir = rootdir
        self.cachedir = cachedir
        self.rootalbum = Album("", rootdir)

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
        return web.Response(body=self.to_json().encode('utf-8'))

    async def web_resize_handler(self, request):
        width = request.match_info['width']
        height = request.match_info['height']
        path = request.match_info['path']

        cache_path = os.path.join(self.cachedir,
                "resized/%sx%s" % (width, height),
                path)
        media_path = os.path.join(self.rootdir, path)

        response = "Request thumb (%s, %s) for %s" % (width, height, path)
        return web.Response(body=response.encode('utf-8'))



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
