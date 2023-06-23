use array::ArrayTrait;
use serde::Serde;
use traits::Into;
use poseidon::poseidon_hash_span;

// @notice: This is the main game component
// @param player: Player address
// @param name: Player name
// @param status: false: dead, true: alive
// @param score: Number of tiles explored
// @param seed: Initial seed used to define bomb positions
// @param commited_block_timestamp: Security to avoid a player to move twice in a block
// @param x: Explorer coordinate X
// @param y: Explorer coordinate Y
// @param level: Difficulity used to scale the number of bombs
// @param max_x: Map edges, at any moment 0 <= x < max_x
// @param max_y: Map edges, at any moment 0 <= y < max_y
#[derive(Component, Copy, Drop, Serde)]
struct Game {
    name: felt252,
    status: bool,
    score: u64,
    seed: felt252,
    commited_block_timestamp: u64,
    x: u16,
    y: u16,
    level: u8,
    size: u16,
}

#[derive(Serde, Copy, Drop, PartialEq)]
enum Direction {
    Left: (),
    UpLeft: (),
    Up: (),
    UpRight: (),
    Right: (),
    DownRight: (),
    Down: (),
    DownLeft: (),
}

trait GameTrait {
    fn next_position(x: u16, y: u16, size: u16, direction: Direction) -> (u16, u16);
}

impl GameImpl of GameTrait {
    fn next_position(x: u16, y: u16, size: u16, direction: Direction) -> (u16, u16) {
        match direction {
            Direction::Left(()) => {
                assert(x != 0, 'Cannot move left');
                (x - 1, y)
            },
            Direction::UpLeft(()) => {
                assert(x != 0, 'Cannot move left');
                assert(y != 0, 'Cannot move up');
                (x - 1, y - 1)
            },
            Direction::Up(()) => {
                assert(y != 0, 'Cannot move up');
                (x, y - 1)
            },
            Direction::UpRight(()) => {
                assert(x + 1 != size, 'Cannot move right');
                assert(y != 0, 'Cannot move up');
                (x + 1, y - 1)
            },
            Direction::Right(()) => {
                assert(x + 1 != size, 'Cannot move right');
                (x + 1, y)
            },
            Direction::DownRight(()) => {
                assert(x + 1 != size, 'Cannot move right');
                assert(y + 1 != size, 'Cannot move down');
                (x + 1, y + 1)
            },
            Direction::Down(()) => {
                assert(y + 1 != size, 'Cannot move down');
                (x, y + 1)
            },
            Direction::DownLeft(()) => {
                assert(x != 0, 'Cannot move left');
                assert(y + 1 != size, 'Cannot move down');
                (x - 1, y + 1)
            },
        }
    }
}
