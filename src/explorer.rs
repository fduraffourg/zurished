use std::fs;
use std::path;
use std::io::Result;

use media::{Media, path_to_media};

struct Album {
    albums: Vec<Album>,
    medias: Vec<Media>,
}

fn get_album<P: AsRef<path::Path>>(path: P) -> Result<Album> {
    let fscontent = try!(fs::read_dir(path))
        .filter_map(|e| match e {
            Ok(d) => Some(d),
            Err(_) => None,
        });

    let (dirs, files): (Vec<fs::DirEntry>, Vec<fs::DirEntry>) = fscontent.partition(|e| e.path().is_dir());

    let albums: Vec<Album> = dirs.into_iter()
        .map(|de| get_album(de.path()))
        .filter_map(|e| match e {
            Ok(d) => Some(d),
            Err(_) => None,
        }).collect();

    let medias: Vec<Media> = files.into_iter()
        .map(|d| d.path())
        .filter_map(path_to_media)
        .collect();

    Ok(Album {
        albums: albums,
        medias: medias,
    })
}

#[test]
fn test_get_album() {
    let album = get_album("src/test").unwrap();

    assert!(album.albums.len() == 1);
    assert!(album.medias.len() == 2);
}


struct WalkDir {
    queue: Vec<fs::DirEntry>,
    current: fs::ReadDir,
}


impl Iterator for WalkDir {
    type Item = fs::DirEntry;

    fn next(&mut self) -> Option<fs::DirEntry> {
        match self.current.next() {
            // A new entry is found
            Some(Ok(entry)) => {
                // If this entry is a directory, queue it for further walking
                let path = entry.path();
                if path.is_dir() {
                    if keep_dir(path) {
                        self.queue.push(entry);
                    }
                    self.next()
                }
                // Otherwise, return it
                else {
                    if keep_file(entry.path()) {
                        Some(entry)
                    } else {
                        self.next()
                    }
                }
            }
            // An error was found with the following entry
            // Just ignore it
            Some(Err(_)) => self.next(),
            // End of the current directory, parse the queued directories
            None => {
                match self.queue.pop() {
                    Some(direntry) => {
                        match fs::read_dir(direntry.path()) {
                            Ok(readdir) => {
                                self.current = readdir;
                                self.next()
                            }
                            Err(_) => self.next(),
                        }
                    }
                    // Queue is empty, nothing to do
                    None => None,
                }
            }
        }
    }
}

fn walk_dir(path: &str) -> Result<WalkDir> {
    match fs::read_dir(path) {
        Ok(readdir) => Ok(WalkDir{ queue: vec![], current: readdir }),
        Err(e) => Err(e),
    }
}


fn keep_dir(path: path::PathBuf) -> bool {
    match path.file_name() {
        Some(filename) => {
            match filename.to_str() {
                Some(name) => {
                    if name.starts_with(".") {
                        return false
                    }
                    true
                },
                None => false,
            }
        },
        None => false,
    }
}

fn keep_file(path: path::PathBuf) -> bool {
    match path.file_name() {
        Some(filename) => {
            match filename.to_str() {
                Some(name) => {
                    if name.starts_with(".") {
                        return false
                    }
                    true
                },
                None => false,
            }
        },
        None => false,
    }
}

fn main() {
    // let paths = fs::read_dir("./").unwrap();

    // for path in paths {
    //     println!("Name: {}", path.unwrap().path().display())
    // }
    //
    let pw = walk_dir("./").unwrap();
    for path in pw {
        println!("Name: {}", path.path().display())
    }
}
