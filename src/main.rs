extern crate iron;
extern crate image;
extern crate router;
extern crate rustc_serialize;

use std::fs;
use std::fs::{DirEntry};
use std::path::PathBuf;

mod media;
mod explorer;

use iron::prelude::*;
use iron::status;
use router::Router;

use rustc_serialize::json;


fn index(_: &mut Request) -> IronResult<Response> {
    Ok(Response::with((status::Ok, "index")))
}


fn list_albums(_: &mut Request) -> IronResult<Response> {
    let path = PathBuf::from("src/test");
    let albums = explorer::get_album(path).unwrap();
    let payload = json::encode(&albums).unwrap();

    Ok(Response::with((status::Ok, payload)))
}


fn main() {
    let mut router = Router::new();

    router.get("/albums", list_albums);
    router.get("/", index);


    Iron::new(router).http("localhost:3000").unwrap();
}
