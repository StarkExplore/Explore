#[system]
mod Create {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use poseidon::poseidon_hash_span;

    use explore::components::game::Game;
    use explore::constants::{DIFFICULTY, MAX_X,MAX_Y, START_X, START_Y, ALIVE};

    // note: ignore linting of Context and commands
    fn execute(ctx: Context, name: felt252) -> felt252 {
        let time = starknet::get_block_timestamp();

        let game_id = commands::uuid();

        commands::set_entity(
            game_id.into(),
            ( Game {
                player: ctx.caller_account.into(),
                name: name,
                status: ALIVE,
                score: 0,
                seed: ctx.caller_system,
                commited_block_timestamp: starknet::get_block_timestamp(),
                x: START_X,
                y: START_Y,
                difficulty: DIFFICULTY,
                max_x: MAX_X,
                max_y: MAX_Y,
            }, )
        );
        
        game_id.into()
    }
}
