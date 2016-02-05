extern crate iron;
extern crate image;
extern crate router;
extern crate rustc_serialize;
extern crate clap;

use std::path::PathBuf;

mod media;
mod explorer;

use iron::prelude::*;
use iron::status;
use iron::response;
use router::Router;

use rustc_serialize::json;

use clap::{Arg, App};


fn index(_: &mut Request) -> IronResult<Response> {
    Ok(Response::with((status::Ok, "index")))
}

/*
 * AlbumsHandler
 */

struct AlbumsHandler {
    album: PathBuf,
}

impl iron::middleware::Handler for AlbumsHandler {
    fn handle(&self, _: &mut Request) -> IronResult<Response> {
        let albums = explorer::get_album(&self.album).unwrap();
        let payload = json::encode(&albums).unwrap();

        Ok(Response::with((status::Ok, payload)))
    }
}

/*
 * MediasHandler
 */

struct MediasHandler {
    album: PathBuf,
    cache: PathBuf,
}

impl iron::middleware::Handler for MediasHandler {
    fn handle(&self, request: &mut Request) -> IronResult<Response> {
        let mut path_iter = request.url.path.clone().into_iter();

        // First part should be 'medias', just skip it
        if let None = path_iter.next() {
            return Ok(Response::with((status::BadRequest, "Request too short")))
        }

        // Second part should be the size of the media
        let size = match path_iter.next() {
            Some(string) => string,
            None => return Ok(Response::with((status::BadRequest, "Request too short"))),
        };
        let size = match size.parse::<u32>() {
            Ok(i) => i,
            Err(_) => return Ok(Response::with((status::BadRequest, "Bad size, unable to parse it to an integer"))),
        };


        // The rest is the path of the media
        let source = path_iter.fold(String::new(), |s, x| if s.len() == 0 { x } else { s + "/" + &x });
        let source = PathBuf::from(source);
        let source = self.album.join(source);


        // Create the response
        // let response_body = iron::response::ResponseBody::new();
        // let response = Response::with((status::Ok, response_body));

        // let image = media::resize_media(source, size, response_body);

        //Ok(response)
        Ok(Response::with((status::Ok, "Serving media")))
    }
}

impl MediasHandler {
    fn new(album_path: &str, cache_path: &str) -> MediasHandler {
        let album = PathBuf::from(album_path);
        let cache = PathBuf::from(cache_path);
        MediasHandler {
            album: album,
            cache: cache,
        }
    }
}


fn start_web_server(address: &str, album: &str, cache: &str) {
    let path = PathBuf::from(album);

    let mut router = Router::new();

    // Serves albums content
    let albums_handler = AlbumsHandler {
        album: path,
    };
    router.get("/albums", albums_handler);

    // Serves media content
    let media_handler = MediasHandler::new(album, cache);
    router.get("/medias/*", media_handler);

    // Serves index page
    router.get("/", index);

    Iron::new(router).http(address).unwrap();
}


fn main() {
    let matches = App::new("Zurished web server")
        .version("0.1")
        .author("Florian Duraffourg")
        .about("Simple photo album")
        .arg(Arg::with_name("address")
             .short("a")
             .long("address")
             .value_name("address")
             .help("Address and port to address to (default to localhost:3000)")
             )
        .arg(Arg::with_name("album")
             .short("d")
             .long("dir")
             .value_name("album")
             .help("Directory of the photos (default to .)")
             //.required(true)
             )
        .arg(Arg::with_name("cache")
             .short("c")
             .long("cache")
             .value_name("CACHE")
             .help("Directory of the cache to use (default to /var/cache/zurished)")
             )
        .get_matches();

    let address = matches.value_of("address").unwrap_or("localhost:3000");
    let album = matches.value_of("album").unwrap_or(".");
    let cache = matches.value_of("cache").unwrap_or("/var/cache/zurished");


    println!("Port: {}\nAlbum: {}\nCache: {}\n", address, album, cache);

    start_web_server(address, album, cache);

}
