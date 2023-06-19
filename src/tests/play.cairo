use traits::Into;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use dojo_core::storage::query::Query;
use dojo_core::interfaces::{IWorldDispatcher, IWorldDispatcherTrait};
use explore::components::{game::Game, tile::Tile};
use explore::systems::{create::Create};
use explore::tests::setup::spawn_game;
use debug::PrintTrait;

#[test]
#[available_gas(100000000000000)]
fn test_play() {
    // [Setup] World
    let world_address = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };
    let mut empty = array::ArrayTrait::<felt252>::new();

    // [Execute] Move left and commit safe
    let mut calldata = array::ArrayTrait::<felt252>::new();
    calldata.append(0);
    calldata.append(0);
    world.execute('Move'.into(), calldata.span());
    world.execute('Reveal'.into(), empty.span());

    // [Execute] Move up-right and commit unsafe
    let mut calldata = array::ArrayTrait::<felt252>::new();
    calldata.append(1);
    calldata.append(3);
    world.execute('Move'.into(), calldata.span());
    world.execute('Reveal'.into(), empty.span());

    // [Execute] Move left and commit safe
    let mut calldata = array::ArrayTrait::<felt252>::new();
    calldata.append(0);
    calldata.append(0);
    world.execute('Move'.into(), calldata.span());
    world.execute('Reveal'.into(), empty.span());

    // [Check] Game state
    // [Error] Test ran out of gas
    let mut tiles = IWorldDispatcher {
        contract_address: world_address
    }.entity('Tile'.into(), starknet::get_caller_address().into(), 0, 0);
    assert(tiles.len() == 0_u32, 'wrong number of tile');
}

#[test]
#[should_panic]
#[available_gas(100000000000000)]
fn test_play_revert_game_over() {
    // [Setup] World
    let world_address = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    // [Execute] Move up and commit safe
    let mut calldata = array::ArrayTrait::<felt252>::new();
    calldata.append(0);
    calldata.append(2);
    let mut res = world.execute('Move'.into(), calldata.span());

    // [Execute] Reveal
    let mut calldata = array::ArrayTrait::<felt252>::new();
    let mut res = world.execute('Reveal'.into(), calldata.span());

    // [Execute] Move to left and commit safe
    let mut calldata = array::ArrayTrait::<felt252>::new();
    calldata.append(0);
    calldata.append(0);
    let mut res = world.execute('Move'.into(), calldata.span());
}
