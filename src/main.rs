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
use router::Router;

use rustc_serialize::json;

use clap::{Arg, App};


fn index(_: &mut Request) -> IronResult<Response> {
    Ok(Response::with((status::Ok, "index")))
}


fn list_albums(_: &mut Request) -> IronResult<Response> {
    let path = PathBuf::from("src/test");
    let albums = explorer::get_album(path).unwrap();
    let payload = json::encode(&albums).unwrap();

    Ok(Response::with((status::Ok, payload)))
}

fn start_web_server(address: &str) {
    let mut router = Router::new();

    router.get("/albums", list_albums);
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

    start_web_server(address);

}
