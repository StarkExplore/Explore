use traits::Into;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use starknet::ContractAddress;
use dojo_core::interfaces::IWorldDispatcherTrait;
use dojo_core::test_utils::spawn_test_world;
use dojo_core::auth::systems::{Route, RouteTrait, GrantAuthRole};

use explore::components::tile::TileComponent;
use explore::components::game::GameComponent;
use explore::systems::{create::Create, move::Move, defuse::Defuse, reveal::Reveal};

const NAME: felt252 = 'NAME';

fn spawn_game() -> ContractAddress {
    // [Setup] Components
    let mut components = array::ArrayTrait::new();
    components.append(GameComponent::TEST_CLASS_HASH);
    components.append(TileComponent::TEST_CLASS_HASH);

    // [Setup] Systems
    let mut systems = array::ArrayTrait::new();
    systems.append(Create::TEST_CLASS_HASH);
    systems.append(Move::TEST_CLASS_HASH);
    systems.append(Defuse::TEST_CLASS_HASH);
    systems.append(Reveal::TEST_CLASS_HASH);

    // [Setup] Routes
    let mut routes = array::ArrayTrait::new();
    routes.append(RouteTrait::new('Create'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Create'.into(), 'TileWriter'.into(), 'Tile'.into()));
    routes.append(RouteTrait::new('Move'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Move'.into(), 'TileReader'.into(), 'Tile'.into()));
    routes.append(RouteTrait::new('Reveal'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Reveal'.into(), 'TileWriter'.into(), 'Tile'.into()));
    routes.append(RouteTrait::new('Defuse'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Defuse'.into(), 'TileWriter'.into(), 'Tile'.into()));

    let world = spawn_test_world(components, systems, routes);

    let mut spawn_game_calldata = array::ArrayTrait::<felt252>::new();
    spawn_game_calldata.append(NAME.into());

    world.execute('Create'.into(), spawn_game_calldata.span());

    world.contract_address
}
