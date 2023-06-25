#[system]
mod Move {
    use array::ArrayTrait;
    use traits::Into;
    use explore::components::game::{Game, GameTrait, Direction};
    use explore::components::tile::Tile;

    fn execute(ctx: Context, direction: Direction) {
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

        // [Compute] Update game entity
        let (x, y) = GameTrait::next_position(game.x, game.y, game.size, direction);
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
                    size: game.size,
                    shield: game.shield,
                    kits: game.kits,
                }
            )
        );
        return ();
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
        let mut calldata = array::ArrayTrait::<felt252>::new();
        calldata.append(0);
        let mut res = world.execute('Move'.into(), calldata.span());

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
        let mut calldata = array::ArrayTrait::<felt252>::new();
        calldata.append(0);
        let mut res = world.execute('Move'.into(), calldata.span());
        let mut res = world.execute('Move'.into(), calldata.span());
    }
}
