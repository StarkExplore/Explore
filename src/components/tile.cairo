use array::ArrayTrait;
use serde::Serde;
use traits::Into;
use poseidon::poseidon_hash_span;

// @notice: This is the tile component used to know what is explored
// and what is not. It also contains the number of dangers around.
// @param explored: 0: unexplored, 1: explored
// @param clue: Number of dangers around
// @param x: x coordinate
// @param y: y coordinate
#[derive(Component, Copy, Drop, Serde)]
struct Tile {
    explored: bool,
    clue: u8,
    x: u16,
    y: u16,
}

trait TileTrait {
    fn get_clue(
        seed: felt252, diff: u8, max_x: u16, max_y: u16, x: u16, y: u16
    ) -> u8;
    fn get_danger(
        seed: felt252, diff: u8, x: u16, y: u16
    ) -> u8;
}

impl TileImpl of TileTrait {
    fn get_clue(
        seed: felt252, diff: u8, max_x: u16, max_y: u16, x: u16, y: u16
    ) -> u8 {
        // [Compute] Dangerousness of each neighbor based on their position
        let mut clue: u8 = 0;

        // [Compute] Left neighbors
        if x > 0 {
            clue += compute_danger(seed, diff, x - 1, y);
            if y > 0 {
                clue += compute_danger(seed, diff, x - 1, y - 1);
            }
            if y + 1 < max_y {
                clue += compute_danger(seed, diff, x - 1, y + 1);
            }
        }

        // [Compute] Right neighbors
        if x + 1 < max_x {
            clue += compute_danger(seed, diff, x + 1, y);
            if y > 0 {
                clue += compute_danger(seed, diff, x + 1, y - 1);
            }
            if y + 1 < max_y {
                clue += compute_danger(seed, diff, x + 1, y + 1);
            }
        }

        // [Compute] Top and bottom neighbors
        if y > 0 {
            clue += compute_danger(seed, diff, x, y - 1);
        }
        if y + 1 < max_y {
            clue += compute_danger(seed, diff, x, y + 1);
        }

        clue
    }

    fn get_danger(
        seed: felt252, diff: u8, x: u16, y: u16
    ) -> u8 {
        compute_danger(seed, diff, x, y)
    }
}

fn compute_danger(seed: felt252, diff: u8, x: u16, y: u16) -> u8 {
    // [Compute] Hash the position
    let mut serialized = ArrayTrait::new();
    serialized.append(seed);
    serialized.append(x.into());
    serialized.append(y.into());

    let hash: u256 = poseidon_hash_span(serialized.span()).into();

    // [Compute] Difficulty * 10% chance of being a danger
    let probability = diff * 10_u8;
    let result: u128 = hash.low % 100;
    if result <= probability.into() {
        return 1_u8;
    }
    0_u8
}

#[test]
#[available_gas(100000000)]
fn test_get_clue() {
    let clue = TileTrait::get_clue(0, 0_u8, 0_u16, 0_u16, 0_u16, 0_u16);
    assert(clue == 0_u8, 'wrong clue')
}

#[test]
#[available_gas(100000000)]
fn test_get_danger() {
    let danger = TileTrait::get_danger(0, 0_u8, 0_u16, 0_u16);
    assert(danger == 0_u8, 'wrong danger')
}
