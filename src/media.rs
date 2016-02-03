extern crate image;

use std::path;

use image::GenericImage;


#[derive(RustcEncodable)]
pub struct Media {
    name: String,
    dimensions: (u32, u32),
}


pub fn path_to_media(path: path::PathBuf) -> Option<Media> {
    let img = match image::open(&path) {
        Ok(i) => i,
        Err(_) => return None,
    };

    let name = match path.as_path()
        .file_name()
        .and_then(|e| e.to_str())
        .map(|e| e.to_string()) {
            Some(n) => n,
            None => return None,
        };

    Some(Media{
        name: name,
        dimensions: img.dimensions(),
    })
}


#[test]
fn test_path_to_media_1() {
    let media = path_to_media(path::Path::new("src/test/1.jpeg").to_path_buf()).unwrap();

    assert!(media.dimensions == (225, 225));
}

#[test]
fn test_path_to_media_2() {
    let media = path_to_media(path::Path::new("src/test/2.jpeg").to_path_buf()).unwrap();

    assert!(media.dimensions == (107, 182));
}

#[test]
fn test_path_to_media_3() {
    let media = path_to_media(path::Path::new("src/test/2016/3.jpeg").to_path_buf()).unwrap();

    assert!(media.dimensions == (225, 225));
}
