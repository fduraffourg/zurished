import os

from zurished.media import Media

class Album(object):
    def __init__(self, path, rootdir):
        self.path = path
        self.rootdir = rootdir
        self.realpath = os.path.join(rootdir, path)

        self._albums = None
        self._medias = None

    def list_content(self):
        albums = []
        medias = []

        for direntry in os.scandir(self.realpath):
            # If this is a directory, add it as a new album
            if direntry.is_dir():
                album = Album(os.path.join(self.path, direntry.name), self.rootdir)
                albums.append(album)
                continue

            # Else this is a file
            media = Media(direntry.name,
                    direntry.path,
                    self)
            if not media.is_unknown():
                medias.append(media)

        self._albums = albums
        self._medias = sorted(medias, key=lambda m: m.name)

    @property
    def albums(self):
        if self._albums is None:
            self.list_content()
        return self._albums

    @property
    def medias(self):
        if self._medias is None:
            self.list_content()
        return self._medias

    def to_dict(self):
        return {
                'path': self.path,
                'albums': self.albums,
                'medias': self.medias
                }
