use std::fs;

fn read_prog(filename: &str) -> Vec<usize> {
    let s = match fs::read_to_string(filename) {
        Err(why) => panic!("reading jacked up {} {}", filename, why),
        Ok(s) => s.trim().to_string()
    };

    s.split(',').map(|s| match s.parse::<usize>() {
        Err(why) => panic!("Parse error {}", why),
        Ok(s) => s
    }).collect::<Vec<usize>>()
}

fn computer(program:&mut Vec<usize>) {
    let mut index = 0;

    loop {
       let opcode = program[index];
       let (arg1, arg2) = (program[program[index + 1]], program[program[index + 2]]);
       let store = program[index + 3];

       match opcode {
           1 => program[store] = arg1 + arg2,
           2 => program[store] = arg1 * arg2,
           99 => (),
           x => panic!("Bad times {}", x)
       };

       if opcode == 99 {
           break;
       }

       index += 4;
    }
}


fn part_one() {
    let mut program = read_prog("input.txt");
    program[1] = 12;
    program[2] = 2;

    computer(&mut program);

    println!("Done {}", program[0]);
}


fn part_two() {
    let program = read_prog("input.txt");

    for noun in 0..85 {
        for verb in 0..100 {
            let mut tmp_prog = program.clone();

            tmp_prog[1] = noun;
            tmp_prog[2] = verb;
            computer(&mut tmp_prog);

            if tmp_prog[0] == 19690720 {
                println!("Nailed it {} ({} {})", 100 * noun + verb, noun, verb);
                return;
            }
        }
    }
}



fn main() {
    part_two();
}
