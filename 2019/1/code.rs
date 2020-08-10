use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}


fn part_one() {
    let mut m = 0;

    if let Ok(lines) = read_lines("input.txt") {
        for l in lines {
            if let Ok(module) = l {
                m += module.parse::<u64>().unwrap() / 3 - 2;
            }
        }
    }

    println!("Part one {}", m);
}


fn recursive_fuel(mass: i64) -> i64 {
    let new_mass = mass / 3 - 2;
    if new_mass < 0 {
        0
    }
    else {
        new_mass + recursive_fuel(new_mass)
    }
}


fn part_two() {
    let mut m = 0;

    if let Ok(lines) = read_lines("input.txt") {
        for l in lines {
            if let Ok(module) = l {
                m += recursive_fuel(module.parse::<i64>().unwrap());
            }
        }
    }

    println!("Part two {}", m);
}


fn main() {
    part_one();
    part_two();
}
