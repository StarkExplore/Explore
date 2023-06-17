use traits::Into;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use starknet::ContractAddress;
use dojo_core::interfaces::IWorldDispatcherTrait;
use dojo_core::test_utils::spawn_test_world;
use dojo_core::auth::systems::{Route, RouteTrait, GrantAuthRole};

use explore::components::tile::TileComponent;
use explore::components::game::GameComponent;
use explore::systems::{create::Create, move::Move, reveal::Reveal};
use explore::constants::{DIFFICULTY, MAX_X, MAX_Y, START_X, START_Y, ALIVE};

const NAME: felt252 = 'NAME';

fn spawn_game() -> (ContractAddress, felt252) {
    // [Setup] Components
    let mut components = array::ArrayTrait::new();
    components.append(GameComponent::TEST_CLASS_HASH);
    components.append(TileComponent::TEST_CLASS_HASH);

    // [Setup] Systems
    let mut systems = array::ArrayTrait::new();
    systems.append(Create::TEST_CLASS_HASH);
    systems.append(Move::TEST_CLASS_HASH);
    systems.append(Reveal::TEST_CLASS_HASH);

    // [Setup] Routes
    let mut routes = array::ArrayTrait::new();
    routes.append(RouteTrait::new('Create'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Move'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Reveal'.into(), 'GameReader'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Reveal'.into(), 'TileWriter'.into(), 'Tile'.into()));

    let world = spawn_test_world(components, systems, routes);

    let mut spawn_game_calldata = array::ArrayTrait::<felt252>::new();
    spawn_game_calldata.append(NAME.into());

    let mut res = world.execute('Create'.into(), spawn_game_calldata.span());
    assert(res.len() > 0, 'did not create');

    let game_id = serde::Serde::<felt252>::deserialize(ref res)
        .expect('spawn deserialization failed');

    (world.contract_address, game_id)
}