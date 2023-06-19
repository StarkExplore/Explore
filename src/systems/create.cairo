#[system]
mod Create {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use box::BoxTrait;
    use poseidon::poseidon_hash_span;
    use explore::components::game::Game;
    use explore::components::tile::{Tile, TileTrait};
    use explore::constants::{LEVEL, SIZE};

    fn execute(ctx: Context, name: felt252) {
        let time = starknet::get_block_timestamp();
        let info = starknet::get_tx_info().unbox();

        // [Command] Create game
        let seed = info.transaction_hash;
        let x: u16 = SIZE / 2_u16;
        let y: u16 = SIZE / 2_u16;
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
                    size: SIZE,
                    action: 0_u8,
                },
            )
        );

        // [Command] Delete all existing tiles
        let mut idx: u16 = 0_u16;
        loop {
            if idx >= SIZE * SIZE {
                break ();
            }

            let mut col: u16 = idx % SIZE;
            let mut row: u16 = idx / SIZE;

            // [Error] This command has no effect
            // let mut tile_sk: Query = (ctx.caller_account, col, row).into();
            // commands::<Tile>::delete_entity(tile_sk);

            // [Workaround] Set all entities to 0
            commands::set_entity(
                (ctx.caller_account, col, row).into(),
                (Tile { explored: false, danger: false, clue: 0_u8, x: 0_u16, y: 0_u16 }, ),
            );

            idx += 1_u16;
        };

        // [Compute] Create a tile
        let clue = TileTrait::get_clue(seed, LEVEL, SIZE, x, y);
        let danger = TileTrait::is_danger(seed, LEVEL, x, y);
        commands::set_entity(
            (ctx.caller_account, x, y).into(),
            (Tile { explored: true, danger: danger, clue: clue, x: x, y: y }, )
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
    use explore::constants::{LEVEL, SIZE};

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
        assert(game.x == SIZE / 2_u16, 'wrong x');
        assert(game.y == SIZE / 2_u16, 'wrong y');
        assert(game.level == LEVEL, 'wrong level');
        assert(game.size == SIZE, 'wrong size');
        assert(game.action == 0_u8, 'wrong action');

        // [Check] Tile state
        let tile_id: Query = (caller, game.x, game.y).into();
        let mut tiles = IWorldDispatcher {
            contract_address: world_address
        }.entity('Tile'.into(), tile_id.into(), 0, 0);
        let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('deserialization failed');

        assert(tile.x == SIZE / 2_u16, 'wrong x');
        assert(tile.y == SIZE / 2_u16, 'wrong y');
        assert(tile.explored == true, 'wrong explored');
        assert(tile.danger == true, 'wrong danger');
        assert(tile.clue == 1_u8, 'wrong clue');
    }
}
