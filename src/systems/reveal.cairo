#[system]
mod Reveal {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use box::BoxTrait;
    use poseidon::poseidon_hash_span;
    use debug::PrintTrait;
    use starknet::ContractAddress;

    use explore::components::game::Game;
    use explore::components::inventory::Inventory;
    use explore::components::tile::{Tile, TileTrait, level};
    use explore::constants::SECURITY_OFFSET;

    #[event]
    fn ScoreUpdated(player: ContractAddress, score: u64) {}

    fn execute(ctx: Context) {
        // [Check] Game is not over
        let game = commands::<Game>::entity(ctx.caller_account.into());
        let inventory = commands::<Inventory>::entity(ctx.caller_account.into());
        assert(game.status, 'Game is finished');

        // [Check] Two moves in a single block security
        let time = starknet::get_block_timestamp();
        assert(
            time >= game.commited_block_timestamp + SECURITY_OFFSET, 'Cannot perform two actions'
        );

        // [Check] Current Tile has not been explored yet
        let mut tile_sk: Query = (ctx.caller_account, game.x, game.y).into();
        let tile_option = commands::<Tile>::try_entity(tile_sk);
        let tile = match tile_option {
            Option::Some(tile) => {
                tile
            },
            Option::None(_) => {
                let mine = TileTrait::is_mine(game.seed, game.level, game.x, game.y);
                let shield = TileTrait::is_shield(game.seed, game.level, game.x, game.y);
                let kit = TileTrait::is_kit(game.seed, game.level, game.x, game.y);
                let clue = TileTrait::get_clue(game.seed, game.level, game.size, game.x, game.y);
                Tile {
                    explored: false,
                    mine: mine,
                    danger: mine,
                    shield: shield,
                    kit: kit,
                    clue: clue,
                    x: game.x,
                    y: game.y,
                }
            },
        };
        assert(!tile.explored, 'Current tile must be unexplored');

        // [Check] Tile is dangerous
        if tile.danger {
            // [Check] No shield
            if !inventory.shield {
                // [Compute] Updated game entity, game over
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
                            size: game.size,
                            }, Inventory {
                            shield: inventory.shield, kits: inventory.kits, 
                        }
                    )
                );
                return ();
            } else {
                // [Compute] Remove shield
                let inventory = Inventory { shield: false, kits: inventory.kits,  };
            }
        }

        // [Compute] Tile is a shield
        let mut shield = false;
        if tile.shield {
            shield = true;
        };
        if inventory.shield {
            shield = true;
        };

        // [Compute] Tile is kit, add 1 if tile is a kit
        let mut add_kit = 0_u16;
        if tile.kit {
            add_kit = 1_u16;
        };

        // [Command] Create the tile entity
        commands::set_entity(
            (ctx.caller_account, game.x, game.y).into(),
            (
                Tile {
                    explored: true,
                    mine: tile.mine,
                    danger: tile.danger,
                    shield: tile.shield,
                    kit: tile.kit,
                    clue: tile.clue,
                    x: tile.x,
                    y: tile.y
                },
            ),
        );

        // [Check] Max score not reached
        let max_score: u64 = (game.size * game.size).into();
        if game.score + 1_u64 != max_score {
            // [Compute] Updated game, increase score
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
                        size: game.size,
                        }, Inventory {
                        shield: shield, kits: inventory.kits + add_kit, 
                    }
                )
            );
            return ();
        }

        // [Command] Update Game, level-up and reset score
        let seed = starknet::get_tx_info().unbox().transaction_hash;
        let level = game.level + 1_u8;
        let (size, n_mines) = level(level);
        let x: u16 = size / 2_u16;
        let y: u16 = size / 2_u16;
        commands::set_entity(
            ctx.caller_account.into(),
            (
                Game {
                    name: game.name,
                    status: game.status,
                    score: 1_u64, // reset score
                    seed: seed,
                    commited_block_timestamp: game.commited_block_timestamp,
                    x: x,
                    y: y,
                    level: level, // level up
                    size: size,
                    }, Inventory {
                    shield: shield, // Set to true if Tile is shield
                     kits: n_mines,
                }
            )
        );

        // [Command] Delete all previous tiles
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

        // [Compute] Create a tile
        let clue = TileTrait::get_clue(seed, level, size, x, y);
        let mine = TileTrait::is_mine(seed, level, x, y);
        let shield = TileTrait::is_shield(seed, level, x, y);
        let kit = TileTrait::is_kit(seed, level, x, y);
        commands::set_entity(
            (ctx.caller_account, x, y).into(),
            (
                Tile {
                    explored: true,
                    mine: mine,
                    danger: mine,
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
    use explore::components::{game::Game, tile::Tile};
    use explore::systems::{create::Create};
    use explore::tests::setup::spawn_game;

    #[test]
    #[available_gas(100000000)]
    fn test_reveal_defused_position() {
        // [Setup] World
        let world_address = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };
        let caller = starknet::get_caller_address();

        // [Execute] Defuse up
        let mut calldata = array::ArrayTrait::<felt252>::new();
        calldata.append(2);
        let mut res = world.execute('Defuse'.into(), calldata.span());

        // [Execute] Move up
        let mut calldata = array::ArrayTrait::<felt252>::new();
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
    }

    #[test]
    #[available_gas(1000000000)]
    fn test_reveal_safe_position() {
        // [Setup] World
        let world_address = spawn_game();
        let world = IWorldDispatcher { contract_address: world_address };
        let caller = starknet::get_caller_address();

        // [Execute] Move up
        let mut calldata = array::ArrayTrait::<felt252>::new();
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
        assert(tile.danger == false, 'wrong danger');
        assert(tile.shield == false, 'wrong shield');
        assert(tile.kit == true, 'wrong kit');
        assert(tile.clue == 1_u8, 'wrong clue');
    }

    // @dev: This test is not working because of the tile is already explored
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
