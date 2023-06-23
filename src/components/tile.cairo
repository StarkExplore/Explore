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
    mine: bool,
    danger: bool,
    shield: bool,
    kit: bool,
    clue: u8,
    x: u16,
    y: u16,
}

trait TileTrait {
    fn get_clue(seed: felt252, level: u8, size: u16, x: u16, y: u16) -> u8;
    fn is_mine(seed: felt252, level: u8, x: u16, y: u16) -> bool;
    fn is_shield(seed: felt252, level: u8, x: u16, y: u16) -> bool;
    fn is_kit(seed: felt252, level: u8, x: u16, y: u16) -> bool;
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

    fn is_mine(seed: felt252, level: u8, x: u16, y: u16) -> bool {
        if compute_danger(seed, level, x, y) == 1_u8 {
            return true;
        }
        false
    }

    fn is_shield(seed: felt252, level: u8, x: u16, y: u16) -> bool {
        if compute_shield(seed, level, x, y) == 1_u8 {
            return true;
        }
        false
    }

    fn is_kit(seed: felt252, level: u8, x: u16, y: u16) -> bool {
        if compute_kits(seed, level, x, y) == 1_u8 {
            return true;
        }
        false
    }
}

fn compute_danger(seed: felt252, level: u8, x: u16, y: u16) -> u8 {
    let (size, n_mines) = level(level);
    is_object(seed + 'danger', n_mines, size * size, x + y * size)
}

fn compute_shield(seed: felt252, level: u8, x: u16, y: u16) -> u8 {
    let (size, _) = level(level);
    is_object(seed + 'shield', 1_u16, size * size, x + y * size)
}

fn compute_kits(seed: felt252, level: u8, x: u16, y: u16) -> u8 {
    let (size, _) = level(level);
    is_object(seed + 'kit', 1_u16, size * size, x + y * size)
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
        let tile_object_probability: u128 = objects_to_place.into()
            * MULTIPLIER
            / (n_tiles - i).into();
        let tile_is_object = if rand <= tile_object_probability {
            objects_to_place -= 1;
            1_u8
        } else {
            0_u8
        };
        if i == index {
            break tile_is_object;
        }
        i += 1;
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
    // ~ 15% + 1% per level
    let probability_num = 15 + level.into();
    let probability_den = 100;
    let bomb = size * size * probability_num / probability_den;
    (size, bomb)
}

#[test]
#[available_gas(100000000)]
fn test_get_clue() {
    let clue = TileTrait::get_clue(0, 0_u8, 1_u16, 0_u16, 0_u16);
    assert(clue == 0_u8, 'wrong clue')
}

#[test]
#[available_gas(100000000)]
fn test_is_mine() {
    let mine = TileTrait::is_mine(0, 1_u8, 0_u16, 0_u16);
    assert(mine == false, 'wrong mine')
}

#[test]
#[available_gas(100000000)]
fn test_is_shield() {
    let shield = TileTrait::is_shield(0, 1_u8, 0_u16, 0_u16);
    assert(shield == false, 'wrong shield')
}

#[test]
#[available_gas(100000000)]
fn test_is_kit() {
    let kit = TileTrait::is_kit(0, 1_u8, 0_u16, 0_u16);
    assert(kit == false, 'wrong kit')
}

#[test]
#[available_gas(100000000)]
fn test_is_object() {
    // allocate some number of objects in a board and check this number is actually added
    let n_objects = 17_u16;
    let n_tiles = 32_u16;
    let seed: felt252 = 0;

    let mut seen_objects = 0_u8;
    let mut i = 0_u16;
    loop {
        seen_objects += is_object(seed, n_objects, n_tiles, i);
        if i >= n_tiles - 1 {
            break ();
        }
        i += 1;
    };
    assert(seen_objects.into() == n_objects, 'incorrect number objects');
}
