mod Disarm {
    use array::ArrayTrait;
    use traits::Into;
    use super::{Action};

    use explore::components::game::{Game};
    use explore::components::tile::{Tile, compute_danger};
    use explore::constants::{SECURITY_OFFSET};
    use explore::direction::{Direction, next_position};

    fn execute(ctx: Context, action: Action, direction: Direction) {
        // [Check] Game is not over
        let game = commands::<Game>::entity(ctx.caller_account.into());
        assert(game.status, 'Game is finished');

        // position to disarm
        let (x, y) = next_position(game, direction);

        // use up a disarm device
        // .. is there a better way to mutate entities...?
        let key = (ctx.caller_account, DISARM_DEVICE);
        let count = commands::<ItemCount>::entity(key.into()).count;
        commands::set_entity(
            key.into(),
            (ItemCount { count: count - 1 }, )
        );

       // if the position moved into is a mine then the game is over
       if compute_danger(game.seed, game.level, x, y) == 1 {
            // this was a mine. It was successfully diarmed
       } else {
            // this wasn't actually a mine... wasted a disarm device
       }

        let time = starknet::get_block_timestamp();
        commands::set_entity(
            ctx.caller_account.into(),
            (
                Game {
                    name: game.name,
                    status: game.status,
                    score: game.score,
                    seed: game.seed,
                    commited_block_timestamp: time,
                    x: x,
                    y: y,
                    level: game.level,
                    size: game.size,
                },
            )
        );
        return ();
    }
}