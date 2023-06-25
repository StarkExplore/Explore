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
            (Game {
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
            })
        );

        // [Command] Create the defused Tile, with unknown attributes for now
        commands::set_entity(
            (ctx.caller_account, x, y).into(),
            (
                Tile {
                    explored: false, // Unexplored
                    defused: true,
                    mine: false,
                    shield: false,
                    kit: false,
                    clue: 0_u8,
                    x: 0_u16,
                    y: 0_u16
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
    use dojo_core::storage::query::Query;
    use dojo_core::interfaces::{IWorldDispatcher, IWorldDispatcherTrait};
    use explore::components::game::{Game, GameTrait};
    use explore::components::tile::{Tile, TileTrait};
    use explore::systems::{create::Create};
    use explore::tests::setup::spawn_game;

    #[test]
    #[available_gas(100000000)]
    fn test_defuse_left() {
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

        // [Execute] Defuse left
        let mut calldata = array::ArrayTrait::<felt252>::new();
        calldata.append(0);
        let mut res = world.execute('Defuse'.into(), calldata.span());

        // [Check] Game state
        let mut finals = IWorldDispatcher {
            contract_address: world_address
        }.entity('Game'.into(), caller.into(), 0, 0);
        let final = serde::Serde::<Game>::deserialize(ref finals).expect('deserialization failed');
        assert(final.kits == initial.kits - 1, 'Defuse left failed');

        // [Check] Tile state
        let tile_id: Query = (caller, final.x - 1_u16, final.y).into();
        let mut tiles = IWorldDispatcher {
            contract_address: world_address
        }.entity('Tile'.into(), tile_id.into(), 0, 0);
        let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('deserialization failed');

        assert(tile.explored == false, 'wrong explored');
        assert(tile.defused == true, 'wrong defused');
    }
}
