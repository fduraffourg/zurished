extern crate iron;
extern crate image;
extern crate router;

use std::fs;
use std::fs::{DirEntry};
use std::path::Path;

mod media;
mod explorer;

use iron::prelude::*;
use iron::status;
use router::Router;


fn index(_: &mut Request) -> IronResult<Response> {
    Ok(Response::with((status::Ok, "index")))
}


fn list_albums(_: &mut Request) -> IronResult<Response> {
    Ok(Response::with((status::Ok, "albums")))
}


fn main() {
    let mut router = Router::new();

    router.get("/albums", list_albums);
    router.get("/", index);


    Iron::new(router).http("localhost:3000").unwrap();
}
