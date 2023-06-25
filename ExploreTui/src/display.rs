use crate::components::{Game, Tile};
use crate::minesweeper::MinesweeperInterface;
use crate::movement;
use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::io;
use tui::{
    backend::{Backend, CrosstermBackend},
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Style},
    widgets::{Block, Borders, Paragraph, Wrap},
    Frame, Terminal,
};

const CLUE_NO_MINE: [char; 10] = ['⓪','①','②','③','④','⑤','⑥','⑦','⑧','⑨'];
const CLUE_MINE: [char; 10] = ['⓿', '❶', '❷', '❸', '❹', '❺', '❻', '❼', '❽', '❾'];

#[derive(Default)]
struct App<I> {
    game: Game,
    tiles: Vec<Tile>,
    error_message: String,
    defuse_mode: bool,
    interface: I,
}

impl<I: MinesweeperInterface> App<I> {
    pub fn new(interface: I) -> Self {
        Self {
            interface,
            game: Game::default(),
            error_message: String::new(),
            defuse_mode: false,
            tiles: Vec::new(),
        }
    }

    pub async fn sync(&mut self) -> Result<()> {
        self.game = self.interface.get_game().await?;
        self.tiles.clear();
        for j in 0..self.game.size {
            for i in 0..self.game.size {
                self.tiles
                    .push(self.interface.get_tile(i.into(), j.into()).await?);
            }
        }
        Ok(())
    }

    pub async fn make_move(&mut self, direction: movement::Direction) -> Result<()> {
        let result = if self.defuse_mode {
            self.interface.defuse(direction).await
        } else {
            self.interface.make_move(direction).await
        };
        if let Err(_e) = result {
            // unfortunately these errors don't propagate the failure reasons from the contract
            // we can infer our own but they may be wrong
            self.error_message = "Move failed. Remember you can only move once the current square has been revealed. You also cannot move outside the board.".to_string();
            Ok(())
        } else {
            self.error_message = if self.defuse_mode { "Defuse Successful".to_string() } else { "Move successful".to_string() };
            self.sync().await
        }
    }

    pub async fn reveal(&mut self) -> Result<()> {
        if let Err(e) = self.interface.reveal().await {
            self.error_message = e.to_string();
            Ok(())
        } else {
            self.error_message = "Reveal successful".to_string();
            self.sync().await
        }
    }

    pub async fn new_game(&mut self) -> Result<()> {
        self.interface.new_game().await?;
        self.sync().await
    }
}

pub async fn start(interface: impl MinesweeperInterface) -> Result<()> {
    // setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // create app and run it
    let app = App::new(interface);
    run_app(&mut terminal, app).await?;

    // restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    Ok(())
}

async fn run_app<B: Backend, I: MinesweeperInterface>(
    terminal: &mut Terminal<B>,
    mut app: App<I>,
) -> Result<()> {
    app.sync().await?;

    loop {
        terminal.draw(|f| renderer(f, &mut app))?;

        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') => return Ok(()),
                KeyCode::Char('n') => app.new_game().await?,
                KeyCode::Char('1') => app.make_move(movement::Direction::DownLeft).await?,
                KeyCode::Char('2') | KeyCode::Down => {
                    app.make_move(movement::Direction::Down).await?
                }
                KeyCode::Char('3') => app.make_move(movement::Direction::DownRight).await?,
                KeyCode::Char('4') | KeyCode::Left => {
                    app.make_move(movement::Direction::Left).await?
                }
                KeyCode::Char('6') | KeyCode::Right => {
                    app.make_move(movement::Direction::Right).await?
                }
                KeyCode::Char('7') => app.make_move(movement::Direction::UpLeft).await?,
                KeyCode::Char('8') | KeyCode::Up => app.make_move(movement::Direction::Up).await?,
                KeyCode::Char('9') => app.make_move(movement::Direction::UpRight).await?,
                KeyCode::Char('r') => app.reveal().await?,
                KeyCode::Char(' ') => app.defuse_mode = !app.defuse_mode,
                _ => {}
            }
        }
    }
}

// Render a board onto the given rectangle with the frame
fn render_game<B: Backend>(f: &mut Frame<B>, canvas: Rect, game: &Game, tiles: &[Tile]) {
    let mut s = String::new();
    // top edge
    s.push_str("╭");
    for _ in 1..game.size {
        s.push_str("─────")
    }
    s.push_str("────╮");
    s.push('\n');

    // tile grid
    for j in 0..game.size {
        s.push('│');
        for i in 0..game.size {
            let tile_body = match tiles.iter().find(|tile| tile.x == i && tile.y == j) {
                Some(tile) => {
                    match (tile.mine, tile.defused, tile.explored) {
                        (true, _, true) => String::from(CLUE_MINE[tile.clue as usize]),
                        (false, _, true) => String::from(CLUE_NO_MINE[tile.clue as usize]),
                        _ => String::from(" ")
                    }
                }
                None => String::from(" "),
            };

            if (game.x, game.y) == (i, j) {
                if !game.status {
                    s.push_str(format!("<{}>│", String::from('💥')).as_str());  
                } else {
                    s.push_str(format!("<{} >│", tile_body).as_str());
                }
            } else {
                s.push_str(format!(" {}  │", tile_body).as_str());
            }
        }

        // bottom edge
        if j == game.size - 1 {
            s.push_str("\n╰");
            for _ in 1..game.size {
                s.push_str("─────")
            }
            s.push_str("────╯");
            s.push('\n');
        } else { // separator
            s.push_str("\n├");
            for _ in 1..game.size {
                s.push_str("─────")
            }
            s.push_str("────┤\n");
        }
    }

    let board = Paragraph::new(s).alignment(Alignment::Center);

    f.render_widget(board, canvas);
}

fn render_instructions<B: Backend>(f: &mut Frame<B>, canvas: Rect) {
    let instructions_text = "
    1: Move down left
    2: Move down
    3: Move down right
    4: Move left
    6: Move right
    7: Move up left
    8: Move up
    9: Move up right

    R: Reval current tile
    <Space>: Toggle Defuse Mode

    N: Start a new game
    Q: Quit the game";

    let instructions = Paragraph::new(instructions_text)
        .block(Block::default().title("Controls").borders(Borders::ALL))
        .style(Style::default().fg(Color::White).bg(Color::Black))
        .alignment(Alignment::Left)
        .wrap(Wrap { trim: true });
    f.render_widget(instructions, canvas);
}

fn render_score<B: Backend>(
    f: &mut Frame<B>,
    canvas: Rect,
    game: &Game,
    defuse_mode: bool,
) {
    let score_text = format!(
        "
    Name: {}
    Status: {}
    Level: {}
    Score: {}

    Shield: {}
    Defuses kits Remaining: {}

   Move Mode: {}
",
        game.name,
        if game.status { "Active" } else { "Game Over" },
        game.level,
        game.score,
        game.shield,
        game.kits,
        if defuse_mode { "Defuse" } else { "Move" }
    );

    let score = Paragraph::new(score_text)
        .block(Block::default().title("Score").borders(Borders::ALL))
        .style(Style::default().fg(Color::White).bg(Color::Black))
        .alignment(Alignment::Left)
        .wrap(Wrap { trim: true });
    f.render_widget(score, canvas);
}

fn render_info<B: Backend>(f: &mut Frame<B>, canvas: Rect, info: &str) {
    let info = Paragraph::new(info)
        .block(Block::default().title("Info").borders(Borders::ALL))
        .style(Style::default().fg(Color::White).bg(Color::Black))
        .alignment(Alignment::Left)
        .wrap(Wrap { trim: true });
    f.render_widget(info, canvas);
}

// split a rect into equal parts
fn split(r: Rect, into: usize, direction: Direction) -> Vec<Rect> {
    Layout::default()
        .direction(direction)
        .constraints(
            (0..into)
                .map(|_| Constraint::Ratio(1, into as u32))
                .collect::<Vec<Constraint>>()
                .as_ref(),
        )
        .split(r)
}

// Render the entire
fn renderer<B: Backend, I>(f: &mut Frame<B>, app: &mut App<I>) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Percentage(80), Constraint::Percentage(20)].as_ref())
        .split(f.size());

    let error_chunk = chunks[1];

    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(70), Constraint::Percentage(30)].as_ref())
        .split(chunks[0]);

    let board_chunk = chunks[0];
    let sidebar = split(chunks[1], 2, Direction::Vertical);
    let score_chunk = sidebar[0];
    let instructions_chunk = sidebar[1];

    // Calculate the center of the board_chunk
    let board_center_x = board_chunk.x + (board_chunk.width / 2_u16);
    let board_center_y = board_chunk.y + (board_chunk.height / 2);

    // Calculate the top-left position of the game within the board_chunk
    let game_width = (board_chunk.width * 80 / 100) as u16; // Adjust as needed
    let game_height = (board_chunk.height * 80 / 100) as u16; // Adjust as needed
    let game_x = board_center_x - (game_width / 2);
    let game_y = board_center_y - (game_height / 2);

    // Create a Rect for the game within the board_chunk
    let game_chunk = Rect::new(game_x, game_y, game_width, game_height);

    render_game(f, game_chunk, &app.game, &app.tiles);
    render_instructions(f, instructions_chunk);
    render_score(f, score_chunk, &app.game, app.defuse_mode);
    render_info(f, error_chunk, &app.error_message);
}
