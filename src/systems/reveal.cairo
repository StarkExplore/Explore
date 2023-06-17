#[system]
mod Reveal {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use poseidon::poseidon_hash_span;

    use explore::components::game::Game;
    use explore::components::tile::Tile;
    use explore::constants::{DIFFICULTY, SECURITY_OFFSET};

    fn execute(ctx: Context, game_id: u32) {
        // [Query] Game entity
        let game_sk: Query = game_id.into();
        let game = commands::<Game>::entity(game_sk);

        // [Check] Not the same block
        let time = starknet::get_block_timestamp();
        assert(time >= game.commited_block_timestamp + SECURITY_OFFSET, 'Cannot do twice actions');

        // [Compute] Create a tile
        let tile_id =  (game_id, game.x, game.y);
        let dangers = compute_dangers(game, game.x, game.y);

        // [Example] Set the storage partition to the owner, so the storage key would be like (owner_id, (army_id)). 
        // that way you can query for all armies an owner owns like storage::<Army>::entities(owner_id)

        // [Command] Create the tile entity
        commands::set_entity(
            tile_id.into(),
            (
                Tile {
                    x: game.x,
                    y: game.y,
                    explored: 1,
                    dangers: dangers
                },
            )
        );
    }

    fn compute_dangers(game: Game, x: u16, y: u16) -> u8 {
        // [Compute] Dangerousness of each neighbor based on their position
        let mut dangers: u8 = 0;

        let mut idx: u8 = 0;
        let max_x = game.max_x - 1;
        let max_y = game.max_y - 1;

        // [Compute] Left neighbors
        if x > 0 {
            dangers += compute_danger(game.seed, x - 1, y);
            if y > 0 {
                dangers += compute_danger(game.seed, x - 1, y - 1);
            }
            if y < max_y {
                dangers += compute_danger(game.seed, x - 1, y + 1);
            }
        }
        
        // [Compute] Right neighbors
        if x < max_x {
            dangers += compute_danger(game.seed, x + 1, y);
            if y > 0 {
                dangers += compute_danger(game.seed, x + 1, y - 1);
            }
            if y < max_y {
                dangers += compute_danger(game.seed, x + 1, y + 1);
            }
        }

        // [Compute] Top and bottom neighbors
        if y > 0 {
            dangers += compute_danger(game.seed, x, y - 1);
        }
        if y < max_y {
            dangers += compute_danger(game.seed, x, y + 1);
        }

        dangers
    }

    fn compute_danger(seed: felt252, x: u16, y: u16) -> u8 {
        // [Compute] Hash the position
        let mut serialized = ArrayTrait::new();
        serialized.append(seed);
        serialized.append(x.into());
        serialized.append(y.into());

        let hash: u256 = poseidon_hash_span(serialized.span()).into();
        
        // [Compute] Difficulty * 10% chance of being a danger
        let probability = DIFFICULTY * 10_u8;
        let result: u128 = hash.low % 100;
        if result <= probability.into() {
            return 1_u8;
        }
        0_u8
    }
}
