#[system]
mod Reveal {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use poseidon::poseidon_hash_span;

    use explore::components::game::Game;
    use explore::components::tile::{Tile, TileTrait};
    use explore::constants::{SECURITY_OFFSET};

    fn execute(ctx: Context) {
        // [Check] Game is not over
        let game = commands::<Game>::entity(ctx.caller_account.into());
        assert(game.status, 'Game is finished');

        // [Check] Two moves in a single block security
        let time = starknet::get_block_timestamp();
        assert(
            time >= game.commited_block_timestamp + SECURITY_OFFSET, 'Cannot perform two actions'
        );

        // [Check] Current Tile has not been explored yet
        let mut tile_sk: Query = (ctx.caller_account, game.x, game.y).into();
        let tile = commands::<Tile>::try_entity(tile_sk);
        let exists = match tile {
            Option::Some(tile) => {
                !tile.explored
            },
            Option::None(_) => {
                true
            },
        };
        assert(exists, 'Current tile must be unrevealed');

        // [Check] Tile danger does not match the committed action
        let danger = TileTrait::get_danger(game.seed, game.level, game.x, game.y);
        if danger != game.action {
            // [Compute] Updated game entity
            commands::set_entity(
                ctx.caller_account.into(),
                (
                    Game {
                        name: game.name,
                        status: false,
                        score: game.score,
                        seed: game.seed,
                        commited_block_timestamp: game.commited_block_timestamp,
                        x: game.x,
                        y: game.y,
                        level: game.level,
                        max_x: game.max_x,
                        max_y: game.max_y,
                        action: game.action,
                    },
                )
            );
            return ();
        }

        // [Command] Create the tile entity
        let clue = TileTrait::get_clue(
            game.seed, game.level, game.max_x, game.max_y, game.x, game.y
        );
        commands::set_entity(
            (ctx.caller_account, game.x, game.y).into(),
            (Tile { x: game.x, y: game.y, explored: true, clue: clue }, ),
        );

        // [Command] Max score reached then level up and reset score, otherwise increase the score
        let max_score : u64 = (game.max_x * game.max_y).into();
        if game.score == max_score {
            let max_x : u16 = game.max_x + 2_u16;
            let max_y : u16 = game.max_y + 2_u16;
            let x : u16 = max_x / 2_u16;
            let y : u16 = max_y / 2_u16;
            commands::set_entity(
                ctx.caller_account.into(),
                (
                    Game {
                        name: game.name,
                        status: game.status,
                        score: 1_u64,  // reset score
                        seed: game.seed,
                        commited_block_timestamp: game.commited_block_timestamp,
                        x: x,
                        y: y,
                        level: game.level + 1_u8,  // level up
                        max_x: max_x,
                        max_y: max_y,
                        action: game.action,
                    },
                )
            );
            return ();
        }
        commands::set_entity(
            ctx.caller_account.into(),
            (
                Game {
                    name: game.name,
                    status: game.status,
                    score: game.score + 1_u64,
                    seed: game.seed,
                    commited_block_timestamp: game.commited_block_timestamp,
                    x: game.x,
                    y: game.y,
                    level: game.level,
                    max_x: game.max_x,
                    max_y: game.max_y,
                    action: game.action,
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
    #[available_gas(100000000)]
    fn test_reveal_position_commit_safe() {
        // [Setup] World
        let world_address = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };
        let caller = starknet::get_caller_address();

        // [Execute] Move up and commit safe
        let mut calldata = array::ArrayTrait::<felt252>::new();
        calldata.append(0);
        calldata.append(2);
        let mut res = world.execute('Move'.into(), calldata.span());

        // [Execute] Reveal
        let mut calldata = array::ArrayTrait::<felt252>::new();
        let mut res = world.execute('Reveal'.into(), calldata.span());

        // [Check] Game state
        let mut games = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let game = serde::Serde::<Game>::deserialize(ref games)
            .expect('game deserialization failed');
        assert(game.score == 1_u64, 'wrong score');
    }

    #[test]
    #[available_gas(100000000)]
    fn test_reveal_position_commit_unsafe() {
        // [Setup] World
        let world_address = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };
        let caller = starknet::get_caller_address();

        // [Execute] Move up and commit unsafe
        let mut calldata = array::ArrayTrait::<felt252>::new();
        calldata.append(1);
        calldata.append(2);
        let mut res = world.execute('Move'.into(), calldata.span());

        // [Execute] Reveal
        let mut calldata = array::ArrayTrait::<felt252>::new();
        let mut res = world.execute('Reveal'.into(), calldata.span());

        // [Check] Game state
        let mut games = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let game = serde::Serde::<Game>::deserialize(ref games)
            .expect('game deserialization failed');
        assert(game.score == 2_u64, 'wrong score');

        // [Check] Tile state
        let mut tiles = IWorldDispatcher {
            contract_address: world_address
        }.entity('Tile'.into(), (caller, game.x, game.y).into(), 0, 0);
        let tile = serde::Serde::<Tile>::deserialize(ref tiles)
            .expect('tile deserialization failed');

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
        let world_address = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };

        // [Execute] Reveal
        let mut calldata = array::ArrayTrait::<felt252>::new();
        let mut res = world.execute('Reveal'.into(), calldata.span());
    }
}
