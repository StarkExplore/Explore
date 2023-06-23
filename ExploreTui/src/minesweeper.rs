use crate::movement::{Action, Direction};
use anyhow::Result;
use async_trait::async_trait;
use starknet::core::types::FieldElement;

#[async_trait]
pub trait MinesweeperInterface {
    async fn get_game(&self) -> Result<Vec<FieldElement>>;
    async fn get_tile(&self, x: FieldElement, y: FieldElement) -> Result<Vec<FieldElement>>;
    async fn create_game(&self, name: FieldElement) -> Result<FieldElement>;
    async fn make_move(&self, action: Action, direction: Direction) -> Result<FieldElement>;
    async fn reveal(&self) -> Result<FieldElement>;
}

#[derive(Default)]
pub struct BoardState {
    pub size: (usize, usize),
    pub player_position: (usize, usize),
    pub board: Vec<TileStatus>, // row-major order
}

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
