use traits::Into;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use dojo_core::storage::query::Query;
use dojo_core::interfaces::{IWorldDispatcher, IWorldDispatcherTrait};
use explore::components::{game::Game, tile::Tile};
use explore::systems::{create::Create};
use explore::tests::setup::spawn_game;

#[test]
#[available_gas(100000000000)]
fn test_play() {
    // [Setup] World
    let world_address = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    // [Execute] Move left and commit safe
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(0);
    spawn_location_calldata.append(0);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    // [Execute] Reveal
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());

    // [Execute] Move up-right and commit unsafe
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(1);
    spawn_location_calldata.append(3);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    // [Execute] Reveal
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());
}

#[test]
#[should_panic]
#[available_gas(100000000000)]
fn test_play_revert_game_over() {
    // [Setup] World
    let world_address = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    // [Execute] Move up and commit safe
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(0);
    spawn_location_calldata.append(2);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    // [Execute] Reveal
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());

    // [Execute] Move to left and commit safe
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(0);
    spawn_location_calldata.append(0);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());
}
