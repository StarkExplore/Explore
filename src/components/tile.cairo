use array::ArrayTrait;
use serde::Serde;
use traits::Into;
use poseidon::poseidon_hash_span;

use explore::constants::BASE_SEED;

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
    // [Compute] Hash the position
    let mut serialized = ArrayTrait::new();
    serialized.append(BASE_SEED);
    serialized.append(seed);
    serialized.append(x.into());
    serialized.append(y.into());

    let hash: u256 = poseidon_hash_span(serialized.span()).into();

    // [Compute] Level + 19% chance of being a danger
    let probability = 19_u8 + level;
    let result: u128 = hash.low % 100;
    if result < probability.into() {
        return 1_u8;
    }
    0_u8
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
