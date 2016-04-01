import os
from enum import Enum
from PIL import Image

class MediaType(Enum):
    unknown = 0
    image = 1


class Media(object):
    def __init__(self, name, realpath, album):
        self.name = name
        self.realpath = realpath
        self.album = album

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
                'path': os.path.join(self.album.path, self.name),
                }
