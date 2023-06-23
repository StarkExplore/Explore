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
        // You can set the style of the entire Table.
        .style(Style::default().fg(Color::White))
        // As any other widget, a Table can be wrapped in a Block.
        .block(Block::default().borders(Borders::ALL).title("Table"))
        // Columns widths are constrained in the same way as Layout...
        .widths(&widths)
        // ...and they can be separated by a fixed spacing.q
        .column_spacing(0);

    f.render_widget(minefield, canvas);
}

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

    

    let controls = "
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

    let controls = Paragraph::new(controls)
        .block(Block::default().title("Controls").borders(Borders::ALL))
        .style(Style::default().fg(Color::White).bg(Color::Black))
        .alignment(Alignment::Left)
        .wrap(Wrap { trim: true });

        app.board.size = (5, 7);
        app.board.player_position = (3,3);

    render_board(f, chunks[0], &app.board);
    f.render_widget(controls, chunks[1]);


}
