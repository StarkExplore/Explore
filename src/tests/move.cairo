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
use explore::constants::{DIFFICULTY, MAX_X, MAX_Y, START_X, START_Y, ALIVE};

use explore::tests::setup::{spawn_game, NAME};

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
