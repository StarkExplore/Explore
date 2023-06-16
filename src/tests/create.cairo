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

use explore::components::game::{Game, GameComponent};
use explore::systems::{create::Create, move::Move};
use explore::constants::{DIFFICULTY, MAX_X,MAX_Y, START_X, START_Y, ALIVE};

const NAME : felt252 = 'NAME';

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
fn test_spawn_game() {
    // [Check] Number of games
    let (world_address, game_id) = spawn_game();
    let (games, _) = IWorldDispatcher {
        contract_address: world_address
    }.entities('Game'.into(), game_id.into());
    assert(games.len() == 1, 'wrong number of games');

    // [Check] Game state
    let mut games = IWorldDispatcher {
        contract_address: world_address
    }.entity('Game'.into(), game_id.into(), 0, 0);
    let game = serde::Serde::<Game>::deserialize(ref games)
        .expect('deserialization failed');

    assert(game.name == NAME, 'wrong name');
    assert(game.status == ALIVE, 'wrong status');
    assert(game.score == 0, 'wrong score');
    // assert(game.seed == 0, 'wrong seed');   
    // assert(game.commited_block_timestamp == 0, 'wrong commited_block_timestamp');
    assert(game.x == START_X, 'wrong x');
    assert(game.y == START_Y, 'wrong y');
    assert(game.difficulty == DIFFICULTY, 'wrong difficulty');
    assert(game.max_x == MAX_X, 'wrong max_x');
    assert(game.max_y == MAX_Y, 'wrong max_y');
}

#[test]
#[should_panic]
#[available_gas(100000000)]
fn test_move_explorer() {
    let (world_address, game_id) = spawn_game();
    let world = IWorldDispatcher { contract_address: world_address };

    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    spawn_location_calldata.append(0);  // Move to left

    let mut res = world.execute('Move'.into(), spawn_location_calldata.span());

    let mut games = IWorldDispatcher {
        contract_address: world_address
    }.entity('Game'.into(), game_id.into(), 0, 0);

    // check game
    let game = serde::Serde::<Game>::deserialize(ref games)
        .expect('deserialization failed');
}