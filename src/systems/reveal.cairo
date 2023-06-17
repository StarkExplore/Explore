#[system]
mod Reveal {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use poseidon::poseidon_hash_span;

    use explore::components::game::Game;
    use explore::components::tile::{Tile, TileTrait};
    use explore::constants::{DIFFICULTY, SECURITY_OFFSET, OFF};

    fn execute(ctx: Context, game_id: u32) {
        // [Query] Game entity
        let game_sk: Query = game_id.into();
        let game = commands::<Game>::entity(game_sk);

        // [Check] Two moves in a single block security
        let time = starknet::get_block_timestamp();
        assert(
            time >= game.commited_block_timestamp + SECURITY_OFFSET, 'Cannot perform two actions'
        );

        // [Check] Current Tile has not been explored yet
        let mut tile_sk: Query = (game_id, game.x, game.y).into();
        let tile = commands::<Tile>::try_entity(tile_sk);
        match tile {
            Option::Some(tile) => {
                assert(!tile.explored, 'Current tile must be unrevealed');
            },
            Option::None(_) => { return (); },
        }

        // [Check] Position is mine turn off the game, continue otherwise
        let danger = TileTrait::get_danger(game.seed, game.difficulty, game.x, game.y);
        if danger == 1_u8 {
            // [Compute] Updated game entity
            commands::set_entity(
                game_sk,
                (
                    Game {
                        player: game.player,
                        name: game.name,
                        status: OFF,
                        score: game.score,
                        seed: game.seed,
                        commited_block_timestamp: game.commited_block_timestamp,
                        x: game.x,
                        y: game.y,
                        difficulty: game.difficulty,
                        max_x: game.max_x,
                        max_y: game.max_y,
                    },
                )
            );
        }

        // [Command] Create the tile entity
        let tile_id = (game_id, game.x, game.y);
        let clue = TileTrait::get_clue(game.seed, game.difficulty, game.max_x, game.max_y, game.x, game.y);
        commands::set_entity(
            tile_id.into(), (Tile { x: game.x, y: game.y, explored: true, clue: clue }, )
        );

        // [Command] Update the game entity to increse score
        commands::set_entity(
            game_sk,
            (
                Game {
                    player: game.player,
                    name: game.name,
                    status: game.status,
                    score: game.score + 1_u64,
                    seed: game.seed,
                    commited_block_timestamp: game.commited_block_timestamp,
                    x: game.x,
                    y: game.y,
                    difficulty: game.difficulty,
                    max_x: game.max_x,
                    max_y: game.max_y,
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
    use explore::components::{game::Game, tile::Tile};
    use explore::systems::{create::Create};
    use explore::tests::setup::spawn_game;

    #[test]
    #[should_panic]
    #[available_gas(100000000)]
    fn test_reveal_position() {
        // [Setup] World
        let (world_address, game_id) = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };

        // [Execute] Move to left
        let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
        spawn_location_calldata.append(game_id);
        spawn_location_calldata.append(0);
        let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

        // [Execute] Reveal
        let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
        spawn_location_calldata.append(game_id);
        let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());

        // [Check] Game state
        let mut games = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), game_id.into(), 0, 0);
        let game = serde::Serde::<Game>::deserialize(ref games).expect('deserialization failed');
        assert(game.score == 2_u64, 'wrong score');

        // [Check] Tile state
        let tile_id: Query = (game_id, game.x, game.y).into();
        let mut tiles = IWorldDispatcher {
            contract_address: world_address
        }.entity('Tile'.into(), tile_id.into(), 0, 0);
        let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('deserialization failed');

        // [Check] Reveal has been operated
        assert(tile.x == game.x, 'wrong x');
        assert(tile.y == game.y, 'wrong y');
        assert(tile.explored == true, 'tile not explored');
        assert(tile.clue == 1_u8, 'wrong clue');
    }

    // @dev: This test is not working because of the tile is already explored
    // @notice: #[should_panic(expected: ('Current tile must be unrevealed', ))] does not work
    #[test]
    #[should_panic]
    #[available_gas(100000000)]
    fn test_reveal_revert_revealed() {
        // [Setup] World
        let (world_address, game_id) = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };

        // [Execute] Reveal
        let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
        spawn_location_calldata.append(game_id);
        let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());
    }
}
