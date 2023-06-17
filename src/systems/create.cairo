#[system]
mod Create {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use poseidon::poseidon_hash_span;
    use explore::components::game::Game;
    use explore::components::tile::{Tile, TileTrait};
    use explore::constants::{DIFFICULTY, MAX_X, MAX_Y, START_X, START_Y, ON};

    fn execute(ctx: Context, name: felt252) -> felt252 {
        let time = starknet::get_block_timestamp();

        // [Command] Create game
        let game_id = commands::uuid();
        let seed = ctx.caller_system; // TODO: use tx hash instead
        commands::set_entity(
            game_id.into(),
            (
                Game {
                    player: ctx.caller_account.into(),
                    name: name,
                    status: ON,
                    score: 1_u64,
                    seed: seed,
                    commited_block_timestamp: starknet::get_block_timestamp(),
                    x: START_X,
                    y: START_Y,
                    difficulty: DIFFICULTY,
                    max_x: MAX_X,
                    max_y: MAX_Y,
                },
            )
        );

        // [Compute] Create a tile
        let clue = TileTrait::get_clue(seed, DIFFICULTY, MAX_X, MAX_Y, START_X, START_Y);
        commands::set_entity(
            (game_id, START_X, START_Y).into(),
            (Tile { x: START_X, y: START_Y, explored: true, clue: clue }, )
        );

        game_id.into()
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
    use explore::constants::{DIFFICULTY, MAX_X, MAX_Y, START_X, START_Y, ON};

    #[test]
    #[available_gas(100000000)]
    fn test_create_game() {
        // [Setup] World
        let (world_address, game_id) = spawn_game();

        // [Check] Number of games
        let (games, _) = IWorldDispatcher {
            contract_address: world_address
        }.entities('Game'.into(), game_id.into());
        assert(games.len() == 1, 'wrong number of games');

        // [Check] Game state
        let mut games = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), game_id.into(), 0, 0);
        let game = serde::Serde::<Game>::deserialize(ref games).expect('deserialization failed');

        assert(game.name == NAME, 'wrong name');
        assert(game.status == ON, 'wrong status');
        assert(game.score == 1_u64, 'wrong score');
        assert(game.x == START_X, 'wrong x');
        assert(game.y == START_Y, 'wrong y');
        assert(game.difficulty == DIFFICULTY, 'wrong difficulty');
        assert(game.max_x == MAX_X, 'wrong max_x');
        assert(game.max_y == MAX_Y, 'wrong max_y');

        // [Check] Tile state
        let tile_id: Query = (game_id, game.x, game.y).into();
        let mut tiles = IWorldDispatcher {
            contract_address: world_address
        }.entity('Tile'.into(), tile_id.into(), 0, 0);
        let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('deserialization failed');

        assert(tile.x == START_X, 'wrong x');
        assert(tile.y == START_Y, 'wrong y');
        assert(tile.explored == true, 'wrong explored');
        assert(tile.clue == 1_u8, 'wrong clue');
    }
}
