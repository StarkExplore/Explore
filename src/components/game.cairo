use array::ArrayTrait;

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
// @param action: Committed action, 1: safe, 2: neutralize
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
    max_x: u16,
    max_y: u16,
    action: u8,
}
