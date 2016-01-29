use std::fs;
use std::io::Result;

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
                if entry.path().is_dir() {
                    self.queue.push(entry);
                    self.next()
                }
                // Otherwise, return it
                else {
                    Some(entry)
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
