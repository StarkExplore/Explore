use array::ArrayTrait;

#[derive(Component, Copy, Drop, Serde)]
struct Game {
    player: felt252,
    name: felt252,
    status: u8,
    score: u64,
    seed: felt252,
    commited_block_timestamp: u64,
    x: u16,
    y: u16,
    difficulty: u8,
    max_x: u16,
    max_y: u16,
}
