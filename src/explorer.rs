use std::fs;
use std::path;

use media::{Media, path_to_media};

#[derive(RustcEncodable)]
pub struct Album {
    name: String,
    albums: Vec<Album>,
    medias: Vec<Media>,
}

pub fn get_album(path: path::PathBuf) -> Option<Album> {
    let readdir = match fs::read_dir(&path) {
        Ok(r) => r,
        Err(_) => return None,
    };
    let fscontent = readdir
        .filter_map(|e| match e {
            Ok(d) => Some(d),
            Err(_) => None,
        });

    let (dirs, files): (Vec<fs::DirEntry>, Vec<fs::DirEntry>) = fscontent.partition(|e| e.path().is_dir());

    let albums: Vec<Album> = dirs.into_iter()
        .map(|de| get_album(de.path()))
        .filter_map(|e| e).collect();

    let medias: Vec<Media> = files.into_iter()
        .map(|d| d.path())
        .filter_map(path_to_media)
        .collect();

    // let name = path.to_path_buf().file_name()
        // .and_then(|e| e.to_str())
        // .and_then(|e| String::from_str(e))
        // .or(String::from_str(""));

    let name = match path.as_path()
        .file_name()
        .and_then(|e| e.to_str())
        .map(|e| e.to_string()) {
            Some(n) => n,
            None => return None,
        };

    Some(Album {
        name: name,
        albums: albums,
        medias: medias,
    })
}

#[test]
fn test_get_album() {
    let album = get_album(path::PathBuf::from("src/test")).unwrap();

    // assert!(album.name == "test", album.name);
    assert!(album.albums.len() == 1);
    assert!(album.medias.len() == 2);
}
