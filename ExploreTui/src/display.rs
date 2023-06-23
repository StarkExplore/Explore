use crate::minesweeper::{MinesweeperInterface, BoardState, TileStatus};
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::{error::Error, io};
use tui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Layout, Direction, Alignment, Rect},
    style::{Color, Modifier, Style},
    text::{Spans, Span},
    widgets::{Block, Borders, Cell, Row, Table, Paragraph, Wrap},
    Frame, Terminal,
};

#[derive(Default)]
struct App {
    board: BoardState,
}


impl App {
    pub fn new() -> Self {
        App::default()
    }
}

pub fn start(_interface: impl MinesweeperInterface) -> Result<(), Box<dyn Error>> {
    // setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // create app and run it
    let app = App::new();
    let res = run_app(&mut terminal, app);

    // restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("{:?}", err)
    }

    Ok(())
}

fn run_app<B: Backend>(terminal: &mut Terminal<B>, mut app: App) -> io::Result<()> {
    loop {
        terminal.draw(|f| renderer(f, &mut app))?;

        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') => return Ok(()),
                // KeyCode::Down => app.next(),
                // KeyCode::Up => app.previous(),
                _ => {}
            }
        }
    }
}

// Render a board onto the given rectangle with the frame
fn render_board<B: Backend>(f: &mut Frame<B>, canvas: Rect, board: &BoardState) {
    let tiles: Vec<Row> = (0..board.size.1).map(|i| {
        Row::new((0..board.size.0).map(|j| {
            if board.player_position == (i, j) {
                return Cell::from("👨");
            }
            match board.board.get(i * board.size.0 + j) {
                Some(TileStatus::Hidden) => Cell::from("⬜"),
                Some(TileStatus::Revealed(danger_level)) => Cell::from(format!("{}", danger_level)),
                Some(TileStatus::Flagged) => Cell::from("🚩"),
                None => Cell::from("⬜"),
            }
        }))
    }).collect();

    let widths = (0..board.size.0).map(|_| {Constraint::Min(2)}).collect::<Vec<Constraint>>();

    let minefield = Table::new(tiles)
        .style(Style::default().fg(Color::White))
        .widths(&widths)
        .column_spacing(0);

    f.render_widget(minefield, canvas);
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
    
    Q: Quit the game
    
        ";
    
        let instructions = Paragraph::new(instructions_text)
            .block(Block::default().title("Controls").borders(Borders::ALL))
            .style(Style::default().fg(Color::White).bg(Color::Black))
            .alignment(Alignment::Left)
            .wrap(Wrap { trim: true });
        f.render_widget(instructions, canvas);

}

fn render_score<B: Backend>(f: &mut Frame<B>, canvas: Rect, board: &BoardState) {
    let score_text = "Mines: 0";

    let score = Paragraph::new(score_text)
            .block(Block::default().title("Score").borders(Borders::ALL))
            .style(Style::default().fg(Color::White).bg(Color::Black))
            .alignment(Alignment::Left)
            .wrap(Wrap { trim: true });
        f.render_widget(score, canvas);
}


// split a rect into equal parts
fn split(r: Rect, into: usize, direction: Direction) -> Vec<Rect> {
    Layout::default()
        .direction(direction)
        .constraints(
            (0..into).map(|_| Constraint::Ratio(1, into as u32)).collect::<Vec<Constraint>>().as_ref()
        )
        .split(r)
}

// Render the entire
fn renderer<B: Backend>(f: &mut Frame<B>, app: &mut App) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints(
            [
                Constraint::Percentage(70),
                Constraint::Percentage(30),
            ]
            .as_ref(),
        )
        .split(f.size());

    let board_chunk = split(split(chunks[0], 3, Direction::Vertical)[1], 3, Direction::Horizontal)[1];
    let sidebar = split(chunks[1], 2, Direction::Vertical);
    let score_chunk = sidebar[0];
    let instructions_chunk = sidebar[1];


    app.board.size = (5, 5);
    app.board.player_position = (3,3);

    render_board(f, board_chunk, &app.board);
    render_instructions(f, instructions_chunk);
    render_score(f, score_chunk, &app.board);

}
