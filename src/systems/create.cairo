#[system]
mod Create {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use poseidon::poseidon_hash_span;
    use explore::components::game::Game;
    use explore::components::tile::{Tile, TileTrait};
    use explore::constants::{LEVEL, MAX_X, MAX_Y};

    fn execute(ctx: Context, name: felt252) {
        let time = starknet::get_block_timestamp();

        // [Command] Create game
        let seed = ctx.caller_system; // TODO: use tx hash instead
        let x: u16 = MAX_X / 2_u16;
        let y: u16 = MAX_Y / 2_u16;
        commands::set_entity(
            ctx.caller_account.into(),
            (
                Game {
                    name: name,
                    status: true,
                    score: 1_u64,
                    seed: seed,
                    commited_block_timestamp: starknet::get_block_timestamp(),
                    x: x,
                    y: y,
                    level: LEVEL,
                    max_x: MAX_X,
                    max_y: MAX_Y,
                    action: 0_u8,
                },
            )
        );

        // [Compute] Create a tile
        let clue = TileTrait::get_clue(seed, LEVEL, MAX_X, MAX_Y, x, y);
        commands::set_entity(
            (ctx.caller_account, x, y).into(), (Tile { x: x, y: y, explored: true, clue: clue }, )
        );
    }
}

mod Test {
    use traits::Into;
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use dojo_core::storage::query::Query;
    use dojo_core::interfaces::{IWorldDispatcher, IWorldDispatcherTrait};
    use explore::components::{game::Game, tile::Tile};
    use explore::systems::{create::Create};
    use explore::tests::setup::{spawn_game, NAME};
    use explore::constants::{LEVEL, MAX_X, MAX_Y};

    #[test]
    #[available_gas(100000000)]
    fn test_create_game() {
        // [Setup] World
        let world_address = spawn_game();
        let caller = starknet::get_caller_address();

        // [Check] Number of games
        let (games, _) = IWorldDispatcher {
            contract_address: world_address
        }.entities('Game'.into(), caller.into());
        assert(games.len() == 1, 'wrong number of games');

        // [Check] Game state
        let mut games = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let game = serde::Serde::<Game>::deserialize(ref games).expect('deserialization failed');

        assert(game.name == NAME, 'wrong name');
        assert(game.status, 'wrong status');
        assert(game.score == 1_u64, 'wrong score');
        assert(game.x == MAX_X / 2_u16, 'wrong x');
        assert(game.y == MAX_Y / 2_u16, 'wrong y');
        assert(game.level == LEVEL, 'wrong level');
        assert(game.max_x == MAX_X, 'wrong max_x');
        assert(game.max_y == MAX_Y, 'wrong max_y');
        assert(game.action == 0_u8, 'wrong action');

        // [Check] Tile state
        let tile_id: Query = (caller, game.x, game.y).into();
        let mut tiles = IWorldDispatcher {
            contract_address: world_address
        }.entity('Tile'.into(), tile_id.into(), 0, 0);
        let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('deserialization failed');

        assert(tile.x == MAX_X / 2_u16, 'wrong x');
        assert(tile.y == MAX_Y / 2_u16, 'wrong y');
        assert(tile.explored == true, 'wrong explored');
        assert(tile.clue == 2_u8, 'wrong clue');
    }
}
