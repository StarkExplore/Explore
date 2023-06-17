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
    let (world_address, game_id) = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    // [Execute] Move up
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    spawn_location_calldata.append(2);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    // [Execute] Reveal
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());

    // [Execute] Move down left
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    spawn_location_calldata.append(7);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    // [Execute] Reveal
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());
}

#[test]
#[should_panic]
#[available_gas(100000000000)]
fn test_play_revert_game_over() {
    // [Setup] World
    let (world_address, game_id) = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    // [Execute] Move right
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    spawn_location_calldata.append(4);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    // [Execute] Reveal
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());

    // [Execute] Move to left
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    spawn_location_calldata.append(0);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());
}
