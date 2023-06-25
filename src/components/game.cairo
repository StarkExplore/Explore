use array::ArrayTrait;
use serde::Serde;
use traits::Into;
use poseidon::poseidon_hash_span;

// @notice This is the main game component
// @param name Player name
// @param status Boolean which is false if game is over, true otherwise
// @param score The number of tiles explored
// @param seed Initial seed used to define bomb positions
// @param commited_block_timestamp Security to avoid a player to move twice in a block
// @param x Player coordinate X
// @param y Player coordinate Y
// @param level The dangerifficulity used to scale the number of bombs
// @param size The size of the current grid
// @param shield A boolean that indicates if the player has a shield
// @param kits The number of kits the player has
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
    shield: bool,
    kits: u16,
}

// @notice The allowed directions
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

// @notice The GameTrait definition
// @dev Methods relative to Game logic are defined here
trait GameTrait {
    fn next_position(x: u16, y: u16, size: u16, direction: Direction) -> (u16, u16);
}

// @notice The implementation of the GameTrait
// @dev Methods relative to Game logic are implemented here
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
