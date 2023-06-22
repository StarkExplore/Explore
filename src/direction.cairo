use explore::components::game::Game;

#[derive(Serde, Copy, Drop, PartialEq)]
enum Direction {
    Left: (),
    UpLeft: (),
    Up: (),
    UpRight: (),
    Right: (),
    DownRight: (),
    Down: (),
    DownLeft: (),
}

fn next_position(game: Game, direction: Direction) -> (u16, u16) {
    match direction {
        Direction::Left(()) => {
            assert(game.x != 0, 'Cannot move left');
            (game.x - 1, game.y)
        },
        Direction::UpLeft(()) => {
            assert(game.x != 0, 'Cannot move left');
            assert(game.y != 0, 'Cannot move up');
            (game.x - 1, game.y - 1)
        },
        Direction::Up(()) => {
            assert(game.y != 0, 'Cannot move up');
            (game.x, game.y - 1)
        },
        Direction::UpRight(()) => {
            assert(game.x + 1 != game.size, 'Cannot move right');
            assert(game.y != 0, 'Cannot move up');
            (game.x + 1, game.y - 1)
        },
        Direction::Right(()) => {
            assert(game.x + 1 != game.size, 'Cannot move right');
            (game.x + 1, game.y)
        },
        Direction::DownRight(()) => {
            assert(game.x + 1 != game.size, 'Cannot move right');
            assert(game.y + 1 != game.size, 'Cannot move down');
            (game.x + 1, game.y + 1)
        },
        Direction::Down(()) => {
            assert(game.y + 1 != game.size, 'Cannot move down');
            (game.x, game.y + 1)
        },
        Direction::DownLeft(()) => {
            assert(game.x != 0, 'Cannot move left');
            assert(game.y + 1 != game.size, 'Cannot move down');
            (game.x - 1, game.y + 1)
        },
    }
}
