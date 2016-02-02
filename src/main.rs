extern crate iron;
extern crate image;

use iron::prelude::*;
use iron::status;

use std::fs;
use std::fs::{DirEntry};
use std::path::Path;

mod media;
mod explorer;

fn main() {
        Iron::new(|_: &mut Request| {
            Ok(Response::with((status::Ok, "Hello world!")))
                }).http("localhost:3000").unwrap();
}
