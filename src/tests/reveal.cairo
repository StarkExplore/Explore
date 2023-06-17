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
fn test_reveal_position() {
    // [Setup] World
    let (world_address, game_id) = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    // [Execute] Reveal
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    let mut res = world.execute('Reveal'.into(), spawn_location_calldata.span());

    // [Check] Game state
    let mut games = IWorldDispatcher {
        contract_address: world_address
    }.entity('Game'.into(), game_id.into(), 0, 0);
    let game = serde::Serde::<Game>::deserialize(ref games).expect('deserialization failed');

    // [Check] Tile state
    let tile_id : Query = (game_id, game.x, game.y).into();
    let mut tiles = IWorldDispatcher {
        contract_address: world_address
    }.entity('Tile'.into(), tile_id.into(), 0, 0);
    let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('deserialization failed');

    // [Check] Reveal has been operated
    assert(tile.x == game.x, 'wrong x');
    assert(tile.y == game.y, 'wrong y');
    assert(tile.explored == 1, 'tile not explored');
    assert(tile.dangers == 1, 'wrong number of dangers');
}
