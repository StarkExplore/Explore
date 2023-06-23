use array::ArrayTrait;
use serde::Serde;
use traits::Into;
use poseidon::poseidon_hash_span;

use explore::constants::{BASE_SEED, START_SIZE};

// @notice: This is the tile component used to know what is explored
// and what is not. It also contains the number of dangers around.
// @param explored: 0: unexplored, 1: explored
// @param danger: 0: safe, 1: unsafe
// @param clue: Number of dangers around
// @param x: x coordinate
// @param y: y coordinate
#[derive(Component, Copy, Drop, Serde)]
struct Tile {
    explored: bool,
    danger: bool,
    clue: u8,
    x: u16,
    y: u16,
}

trait TileTrait {
    fn get_clue(seed: felt252, level: u8, size: u16, x: u16, y: u16) -> u8;
    fn get_danger(seed: felt252, level: u8, x: u16, y: u16) -> u8;
    fn is_danger(seed: felt252, level: u8, x: u16, y: u16) -> bool;
}

impl TileImpl of TileTrait {
    fn get_clue(seed: felt252, level: u8, size: u16, x: u16, y: u16) -> u8 {
        // [Compute] Dangerousness of each neighbor based on their position
        let mut clue: u8 = 0;

        // [Compute] Left neighbors
        if x > 0_u16 {
            clue += compute_danger(seed, level, x - 1_u16, y);
            if y > 0_u16 {
                clue += compute_danger(seed, level, x - 1_u16, y - 1_u16);
            }
            if y + 1_u16 < size {
                clue += compute_danger(seed, level, x - 1_u16, y + 1_u16);
            }
        }

        // [Compute] Right neighbors
        if x + 1_u16 < size {
            clue += compute_danger(seed, level, x + 1_u16, y);
            if y > 0_u16 {
                clue += compute_danger(seed, level, x + 1_u16, y - 1_u16);
            }
            if y + 1_u16 < size {
                clue += compute_danger(seed, level, x + 1_u16, y + 1_u16);
            }
        }

        // [Compute] Top and bottom neighbors
        if y > 0_u16 {
            clue += compute_danger(seed, level, x, y - 1_u16);
        }
        if y + 1_u16 < size {
            clue += compute_danger(seed, level, x, y + 1_u16);
        }

        clue
    }

    fn get_danger(seed: felt252, level: u8, x: u16, y: u16) -> u8 {
        compute_danger(seed, level, x, y)
    }

    fn is_danger(seed: felt252, level: u8, x: u16, y: u16) -> bool {
        if compute_danger(seed, level, x, y) == 1_u8 {
            return true;
        }
        false
    }
}

fn compute_danger(seed: felt252, level: u8, x: u16, y: u16) -> u8 {
    let (size, n_mines) = level(level);
    is_object(seed, n_mines, size * size, x + y * size)
}

// @notice Compute if there is a object at the given position.
// Using an algorithm that uniformly disperses the objects across the board.
// @dev Assuming a linear board (which can be wrapped into a square).
fn is_object(seed: felt252, n_objects: u16, n_tiles: u16, index: u16) -> u8 {
    assert(n_objects < n_tiles, 'too many objects');

    let MULTIPLIER = 10000_u128; // like a percentage but larger to prevent underflow
    let mut objects_to_place = n_objects;
    let mut i = 0;
    return loop {
        if objects_to_place == 0 {
            break 0_u8;
        }
        // [Compute] Uniform random number between 0 and MULTIPLIER
        let rand = uniform_random(seed + i.into(), MULTIPLIER);
        let tile_object_probability: u128 = objects_to_place.into() * MULTIPLIER / (n_tiles - i).into();
        let tile_is_object = if rand <= tile_object_probability {
            objects_to_place -= 1;
            1_u8
        } else { 0_u8 };
        if i == index {
            break tile_is_object;
        }
        i+=1;
    };
}

fn uniform_random(seed: felt252, max: u128) -> u128 {
    let mut serialized = ArrayTrait::new();
    serialized.append(BASE_SEED);
    serialized.append(seed);
    let hash: u256 = poseidon_hash_span(serialized.span()).into();
    hash.low % max
}

// @notice Return the size of the board and the number of mines for a given level
fn level(level: u8) -> (u16, u16) {
    let size = START_SIZE + 2_u16 * level.into();
    let bomb = size / 7 + level.into(); // (~ 15% + 1% per level)
    (size, bomb)
}

#[test]
#[available_gas(100000000)]
fn test_get_clue() {
    let clue = TileTrait::get_clue(0, 0_u8, 0_u16, 0_u16, 0_u16);
    assert(clue == 0_u8, 'wrong clue')
}

#[test]
#[available_gas(100000000)]
fn test_get_danger() {
    let danger = TileTrait::get_danger(0, 0_u8, 0_u16, 0_u16);
    assert(danger == 0_u8, 'wrong danger')
}

#[test]
#[available_gas(100000000)]
fn test_is_mine() {
    // allocate some number of mines in a board and check this number is actually added
    let n_mines = 17_u16;
    let n_tiles = 32_u16;
    let seed: felt252 = 0;

    let mut seen_mines = 0_u8;
    let mut i = 0_u16;
    loop {
        seen_mines += is_object(seed, n_mines, n_tiles, i);
        if i >= n_tiles - 1 {
            break ();
        }
        i+=1;
    };
    assert(seen_mines.into() == n_mines, 'incorrect number mines');
}
