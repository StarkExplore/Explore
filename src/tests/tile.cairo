use traits::Into;
use core::result::ResultTrait;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use traits::TryInto;
use box::BoxTrait;
use clone::Clone;
use debug::PrintTrait;
use poseidon::poseidon_hash_span;
use serde::Serde;
use starknet::{ContractAddress, syscalls::deploy_syscall};
use starknet::class_hash::{ClassHash, Felt252TryIntoClassHash};
use dojo_core::storage::query::{IntoPartitioned, IntoPartitionedQuery};
use dojo_core::interfaces::{
    IWorldDispatcher, IWorldDispatcherTrait, IComponentLibraryDispatcher, IComponentDispatcherTrait,
    ISystemLibraryDispatcher, ISystemDispatcherTrait
};

use dojo_core::executor::Executor;
use dojo_core::world::World;
use dojo_core::test_utils::spawn_test_world;
use dojo_core::auth::systems::{Route, RouteTrait, GrantAuthRole};

use explore::components::tile::{Tile, TileComponent};
use explore::components::game::{Game, GameComponent};
use explore::systems::{create::Create, move::Move};
use explore::constants::{DIFFICULTY, MAX_X, MAX_Y, START_X, START_Y, ALIVE};

const NAME: felt252 = 'NAME';

fn spawn_game() -> (ContractAddress, felt252) {
    // [Setup] Components
    let mut components = array::ArrayTrait::new();
    components.append(GameComponent::TEST_CLASS_HASH);

    // [Setup] Systems
    let mut systems = array::ArrayTrait::new();
    systems.append(Create::TEST_CLASS_HASH);
    systems.append(Move::TEST_CLASS_HASH);

    // [Setup] Routes
    let mut routes = array::ArrayTrait::new();
    routes.append(RouteTrait::new('Create'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Move'.into(), 'GameWriter'.into(), 'Game'.into()));

    let world = spawn_test_world(components, systems, routes);

    let mut spawn_game_calldata = array::ArrayTrait::<felt252>::new();
    spawn_game_calldata.append(NAME.into());

    let mut res = world.execute('Create'.into(), spawn_game_calldata.span());
    assert(res.len() > 0, 'did not create');

    let game_id = serde::Serde::<felt252>::deserialize(ref res)
        .expect('spawn deserialization failed');

    (world.contract_address, game_id)
}

#[test]
#[available_gas(100000000)]
fn test_create_tile() {
    // Spawn a game first
    let (world_address, game_id) = spawn_game();

    // Define the x and y coordinates for the tile
    let x = 5;
    let y = 5;

    // Create the world dispatcher
    let world = IWorldDispatcher { contract_address: world_address };

    // Prepare the calldata for the Tile system
    let mut spawn_tile_calldata = array::ArrayTrait::<felt252>::new();
    spawn_tile_calldata.append(game_id);
    spawn_tile_calldata.append(x.into());
    spawn_tile_calldata.append(y.into());

    // Execute the Tile system
    let mut res = world.execute('Tile'.into(), spawn_tile_calldata.span());

    // Check the result
    assert(res.len() > 0, 'did not create tile');

    // Deserialize the tile ID
    let tile_id = serde::Serde::<felt252>::deserialize(ref res)
        .expect('tile deserialization failed');

    // Query for the tile entity
    let mut tiles = IWorldDispatcher {
        contract_address: world_address
    }.entity('Tile'.into(), tile_id.into(), 0, 0);

    // Deserialize the tile
    let tile = serde::Serde::<Tile>::deserialize(ref tiles).expect('tile deserialization failed');

    // Perform assertions on the tile
    assert(tile.x == x, 'wrong x');
    assert(tile.y == y, 'wrong y');
    assert(tile.explored == 1, 'tile not explored');
    assert(tile.dangers == DIFFICULTY, 'wrong difficulty');
}
