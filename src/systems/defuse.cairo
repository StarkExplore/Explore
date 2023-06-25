#[system]
mod Defuse {
    use array::ArrayTrait;
    use traits::Into;
    use explore::components::game::{Game, GameTrait, Direction};
    use explore::components::tile::{Tile, TileTrait};

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

        // [Check] Next tile is not revealed
        let (x, y) = GameTrait::next_position(game.x, game.y, game.size, direction);
        let tile = commands::<Tile>::try_entity((ctx.caller_account, x, y).into());
        let revealed = match tile {
            Option::Some(tile) => {
                tile.explored
            },
            Option::None(_) => {
                false
            },
        };
        assert(!revealed, 'Current tile must be unrevealed');

        // [Check] Enough kits
        assert(game.kits > 0_u16, 'Not enough kits');

        // [Command] Update game entity
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
                    x: game.x,
                    y: game.y,
                    level: game.level,
                    size: game.size,
                    shield: game.shield,
                    kits: game.kits - 1_u16, // Remove 1 kit 
                }
            )
        );

        // [Command] Create the defused Tile
        let clue = TileTrait::get_clue(game.seed, game.level, game.size, x, y);
        let mine = TileTrait::is_mine(game.seed, game.level, x, y);
        let shield = TileTrait::is_shield(game.seed, game.level, x, y);
        let kit = TileTrait::is_kit(game.seed, game.level, x, y);
        commands::set_entity(
            (ctx.caller_account, x, y).into(),
            (
                Tile {
                    explored: false,  // Unexplored
                    mine: mine,
                    danger: false,  // Not dangerous
                    shield: shield,
                    kit: kit,
                    clue: clue,
                    x: x,
                    y: y
                },
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
    use explore::components::game::{Game, GameTrait};
    use explore::systems::{create::Create};
    use explore::tests::setup::spawn_defuse_game;

    #[test]
    #[available_gas(100000000)]
    fn test_defuse_left() {
        // [Setup] World
        let world_address = spawn_defuse_game();
        let world = IWorldDispatcher { contract_address: world_address };
        let caller = starknet::get_caller_address();

        // [Check] Game state
        let mut initials = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let initial = serde::Serde::<Game>::deserialize(ref initials)
            .expect('deserialization failed');

        // [Execute] Defuse left
        let mut calldata = array::ArrayTrait::<felt252>::new();
        calldata.append(0);
        let mut res = world.execute('Defuse'.into(), calldata.span());

        // [Check] Game state
        let mut finals = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let final = serde::Serde::<Game>::deserialize(ref finals)
            .expect('deserialization failed');

        // [Check] Move
        assert(final.kits == initial.kits - 1, 'Defuse left failed');
    }
}
