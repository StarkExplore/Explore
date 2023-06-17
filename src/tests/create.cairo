use traits::Into;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;

use dojo_core::interfaces::{IWorldDispatcher, IWorldDispatcherTrait};

use explore::components::{game::Game, tile::Tile};
use explore::systems::{create::Create};

use explore::tests::setup::{spawn_game, NAME};
use explore::constants::{DIFFICULTY, MAX_X, MAX_Y, START_X, START_Y, ALIVE};


#[test]
#[available_gas(100000000)]
fn test_create_game() {
    // [Setup] World
    let (world_address, game_id) = spawn_game();

    // [Check] Number of games
    let (games, _) = IWorldDispatcher {
        contract_address: world_address
    }.entities('Game'.into(), game_id.into());
    assert(games.len() == 1, 'wrong number of games');

    // [Check] Game state
    let mut games = IWorldDispatcher {
        contract_address: world_address
    }.entity('Game'.into(), game_id.into(), 0, 0);
    let game = serde::Serde::<Game>::deserialize(ref games).expect('deserialization failed');

    assert(game.name == NAME, 'wrong name');
    assert(game.status == ALIVE, 'wrong status');
    assert(game.score == 1, 'wrong score');
    assert(game.x == START_X, 'wrong x');
    assert(game.y == START_Y, 'wrong y');
    assert(game.difficulty == DIFFICULTY, 'wrong difficulty');
    assert(game.max_x == MAX_X, 'wrong max_x');
    assert(game.max_y == MAX_Y, 'wrong max_y');
}