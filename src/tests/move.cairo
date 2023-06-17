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
    let (world_address, game_id) = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    // [Check] Game state
    let mut initials = IWorldDispatcher {
        contract_address: world_address
    }.entity('Game'.into(), game_id.into(), 0, 0);
    let initial = serde::Serde::<Game>::deserialize(ref initials).expect('deserialization failed');

    // [Execute] Move to left
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    spawn_location_calldata.append(0);
    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    // [Check] Game state
    let mut finals = IWorldDispatcher {
        contract_address: world_address
    }.entity('Game'.into(), game_id.into(), 0, 0);
    let final = serde::Serde::<Game>::deserialize(ref finals).expect('deserialization failed');

    // [Check] Move has been operated
    assert(initial.x - final.x == 1, 'Move left failed');
}
