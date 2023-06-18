#[derive(Serde, Copy, Drop, PartialEq)]
enum Direction {
    Left: (),
    UpLeft: (),
    Up: (),
    UpRight: (),
    Right: (),
    DownRight: (),
    Down: (),
    DownLeft: (),
}

#[derive(Serde, Copy, Drop, PartialEq)]
enum Action {
    Safe: (),
    Unsafe: (),
}

#[system]
mod Move {
    use array::ArrayTrait;
    use traits::Into;
    use super::{Direction, Action};

    use explore::components::game::Game;
    use explore::components::tile::Tile;
    use explore::constants::{SECURITY_OFFSET};

    fn execute(ctx: Context, action: Action, direction: Direction) {
        // [Check] Game is not over
        let game = commands::<Game>::entity(ctx.caller_account.into());
        assert(game.status, 'Game is finished');

        // [Check] Current Tile has been revealed
        let tile = commands::<Tile>::try_entity((ctx.caller_account, game.x, game.y).into());
        let revealed = match tile {
            Option::Some(tile) => {
                tile.explored
            },
            Option::None(_) => {
                false
            },
        };
        assert(revealed, 'Current tile must be revealed');

        // [Compute] Updated game entity
        let commit = next_action(action);
        let (x, y) = next_position(game, direction);
        let time = starknet::get_block_timestamp();
        commands::set_entity(
            ctx.caller_account.into(),
            (
                Game {
                    name: game.name,
                    status: game.status,
                    score: game.score,
                    seed: game.seed,
                    commited_block_timestamp: time,
                    x: x,
                    y: y,
                    level: game.level,
                    max_x: game.max_x,
                    max_y: game.max_y,
                    action: commit,
                },
            )
        );
        return ();
    }

    fn next_action(action: Action) -> u8 {
        match action {
            Action::Safe(()) => {
                0_u8
            },
            Action::Unsafe(()) => {
                1_u8
            },
        }
    }

    fn next_position(game: Game, direction: Direction) -> (u16, u16) {
        match direction {
            Direction::Left(()) => {
                assert(game.x != 0, 'Cannot move left');
                (game.x - 1, game.y)
            },
            Direction::UpLeft(()) => {
                assert(game.x != 0, 'Cannot move left');
                assert(game.y != 0, 'Cannot move up');
                (game.x - 1, game.y - 1)
            },
            Direction::Up(()) => {
                assert(game.y != 0, 'Cannot move up');
                (game.x, game.y - 1)
            },
            Direction::UpRight(()) => {
                assert(game.x + 1 != game.max_x, 'Cannot move right');
                assert(game.y != 0, 'Cannot move up');
                (game.x + 1, game.y - 1)
            },
            Direction::Right(()) => {
                assert(game.x + 1 != game.max_x, 'Cannot move right');
                (game.x + 1, game.y)
            },
            Direction::DownRight(()) => {
                assert(game.x + 1 != game.max_x, 'Cannot move right');
                assert(game.y + 1 != game.max_y, 'Cannot move down');
                (game.x + 1, game.y + 1)
            },
            Direction::Down(()) => {
                assert(game.y + 1 != game.max_y, 'Cannot move down');
                (game.x, game.y + 1)
            },
            Direction::DownLeft(()) => {
                assert(game.x != 0, 'Cannot move left');
                assert(game.y + 1 != game.max_y, 'Cannot move down');
                (game.x - 1, game.y + 1)
            },
        }
    }
}

mod Test {
    use traits::Into;
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use dojo_core::interfaces::{IWorldDispatcher, IWorldDispatcherTrait};
    use explore::components::{game::Game, tile::Tile};
    use explore::systems::{create::Create};
    use explore::tests::setup::spawn_game;

    #[test]
    #[available_gas(100000000)]
    fn test_move_left() {
        // [Setup] World
        let world_address = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };
        let caller = starknet::get_caller_address();

        // [Check] Game state
        let mut initials = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let initial = serde::Serde::<Game>::deserialize(ref initials)
            .expect('deserialization failed');

        // [Execute] Move to left and commit to Safe
        let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
        spawn_location_calldata.append(0);
        spawn_location_calldata.append(0);
        let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

        // [Check] Game state
        let mut finals = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let final = serde::Serde::<Game>::deserialize(ref finals).expect('deserialization failed');

        // [Check] Move
        assert(final.x == initial.x - 1, 'Move left failed');
    }

    // @dev: This test is not working because the new tile must be revealed before moving
    // @notice: #[should_panic(expected: ('Current tile must be revealed', ))] does not work
    #[test]
    #[should_panic]
    #[available_gas(100000000)]
    fn test_move_twice_revert_unrevealed() {
        // [Setup] World
        let world_address = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };

        // [Execute] Move to left and commit safe
        let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
        spawn_location_calldata.append(0);
        spawn_location_calldata.append(0);
        let mut res = world.execute('Move'.into(), spawn_location_calldata.span());
        let mut res = world.execute('Move'.into(), spawn_location_calldata.span());
    }
}
