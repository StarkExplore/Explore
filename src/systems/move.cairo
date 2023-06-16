#[derive(Serde, Copy, Drop, PartialEq)]
enum Direction {
    Left: (),
    Right: (),
    Up: (),
    Down: (),
}

#[system]
mod Move {
    use array::ArrayTrait;
    use traits::Into;
    use super::Direction;

    use explore::components::game::Game;

    fn execute(ctx: Context, game_id: u32, direction: Direction) {
        // [Query] Game entity
        let game_sk: Query = game_id.into();
        let game = commands::<Game>::entity(game_sk);

        // [Check] Next block
        let time = starknet::get_block_timestamp();
        assert(time > game.commited_block_timestamp, 'Cannot move twice in a block');
        let (x, y) = next_position(game, direction);

        // [Compute] Updated explorer
        let updated = Game {
            player: game.player,
            name: game.name,
            status: game.status,
            score: game.score,
            seed: game.seed,
            commited_block_timestamp: time,
            x: x,
            y: y,
            difficulty: game.difficulty,
            max_x: game.max_x,
            max_y: game.max_y,
        };

        commands::set_entity(game_sk, (updated, ));
        return ();
    }

    fn next_position(game: Game, direction: Direction) -> (u16, u16) {
        match direction {
            Direction::Left(()) => {
                assert(game.x != 0, 'Cannot move left');
                (game.x - 1, game.y)
            },
            Direction::Right(()) => {
                assert(game.x + 1 != game.max_x, 'Cannot move right');
                (game.x + 1, game.y)
            },
            Direction::Up(()) => {
                assert(game.y != 0, 'Cannot move up');
                (game.x, game.y - 1)
            },
            Direction::Down(()) => {
                assert(game.y + 1 != game.max_y, 'Cannot move down');
                (game.x, game.y + 1)
            },
        }
    }
}
