#[system]
mod Create {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use box::BoxTrait;
    use poseidon::poseidon_hash_span;
    use explore::components::game::Game;
    use explore::components::inventory::Inventory;
    use explore::components::tile::{Tile, TileTrait, level};
    use explore::constants::{LEVEL};

    fn execute(ctx: Context, name: felt252) {
        let time = starknet::get_block_timestamp();
        let info = starknet::get_tx_info().unbox();

        // [Command] Create game
        let seed = info.transaction_hash;
        let (size, n_mines) = level(LEVEL);
        let x: u16 = size / 2_u16;
        let y: u16 = size / 2_u16;
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
                    size: size,
                    }, Inventory {
                    shield: false, kits: n_mines, 
                }
            )
        );

        // [Command] Delete all existing tiles
        let mut idx: u16 = 0_u16;
        loop {
            if idx >= size * size {
                break ();
            }

            let mut col: u16 = idx % size;
            let mut row: u16 = idx / size;

            // [Error] The command has no effect, then use ctx function
            let mut tile_sk: Query = (ctx.caller_account, col, row).into();
            ctx.world.delete_entity(ctx, 'Tile'.into(), tile_sk);

            idx += 1_u16;
        };

        // [Command] Create a tile
        let clue = TileTrait::get_clue(seed, LEVEL, size, x, y);
        let mine = TileTrait::is_mine(seed, LEVEL, x, y);
        let shield = TileTrait::is_shield(seed, LEVEL, x, y);
        let kit = TileTrait::is_kit(seed, LEVEL, x, y);
        commands::set_entity(
            (ctx.caller_account, x, y).into(),
            (
                Tile {
                    explored: true,
                    mine: mine,
                    danger: false,
                    shield: shield,
                    kit: kit,
                    clue: clue,
                    x: x,
                    y: y
                },
            )
        );
    }
}

mod Test {
    use traits::Into;
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use dojo_core::storage::query::Query;
    use dojo_core::interfaces::{IWorldDispatcher, IWorldDispatcherTrait};
    use explore::components::{game::Game, tile::{Tile, level}};
    use explore::systems::{create::Create};
    use explore::tests::setup::{spawn_create_game, NAME};
    use explore::constants::{LEVEL};

    #[test]
    #[available_gas(100000000)]
    fn test_create_game() {
        // [Setup] World
        let world_address = spawn_create_game();
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
        assert(game.x == 3 / 2_u16, 'wrong x');
        assert(game.y == 3 / 2_u16, 'wrong y');
        assert(game.level == LEVEL, 'wrong level');
        assert(game.size == 3, 'wrong size');

        // [Check] Tile state
        let tile_id: Query = (caller, game.x, game.y).into();
        let mut tiles = IWorldDispatcher {
            contract_address: world_address
        }.entity('Tile'.into(), tile_id.into(), 0, 0);
        let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('deserialization failed');

        assert(tile.x == 3 / 2_u16, 'wrong x');
        assert(tile.y == 3 / 2_u16, 'wrong y');
        assert(tile.explored == true, 'wrong explored');
        assert(tile.danger == false, 'wrong danger');
        assert(tile.shield == false, 'wrong shield');
        assert(tile.kit == false, 'wrong kit');
        assert(tile.clue == 1_u8, 'wrong clue');
    }
}
