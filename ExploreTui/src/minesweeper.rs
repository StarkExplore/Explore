use crate::movement::{Action, Direction};
use anyhow::Result;
use async_trait::async_trait;
use starknet::core::types::FieldElement;
use crate::components::{Game, Tile};

#[async_trait]
pub trait MinesweeperInterface {
    async fn get_game(&self) -> Result<Game>;
    async fn get_tile(&self, x: FieldElement, y: FieldElement) -> Result<Tile>;
    async fn create_game(&self, name: FieldElement) -> Result<FieldElement>;
    async fn make_move(&self, action: Action, direction: Direction) -> Result<FieldElement>;
    async fn reveal(&self) -> Result<FieldElement>;
}

#[derive(Default, Debug)]
pub struct BoardState {
    pub size: (usize, usize),
    pub player_position: (usize, usize),
    pub board: Vec<TileStatus>, // row-major order
}

impl BoardState {
    pub fn from_components(game: Game, tiles: Vec<Tile>) -> Self {
        let mut board = vec![TileStatus::default(); (game.size * game.size) as usize];
        for tile in tiles {
            let index = tile.x as usize + tile.y as usize * game.size as usize;
            board[index] = if tile.explored {
                TileStatus::Revealed(tile.clue)
            } else if tile.danger {
                TileStatus::Flagged
            } else {
                TileStatus::Hidden
            };
        }
        BoardState {
            size: (game.size as usize, game.size as usize),
            player_position: (game.x as usize, game.y as usize),
            board,
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub enum TileStatus {
    Hidden,
    Revealed(u8), // contains the danger level
    Flagged,
}

impl Default for TileStatus {
    fn default() -> Self {
        TileStatus::Hidden
    }
}
