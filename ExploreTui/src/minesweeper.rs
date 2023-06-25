use anyhow::Result;
use async_trait::async_trait;
use starknet::core::types::FieldElement;

use crate::components::{Game, Tile, Inventory};
use crate::movement::{Action, Direction};

#[async_trait]
pub trait MinesweeperInterface {
    async fn get_game(&self) -> Result<Game>;
    async fn get_tile(&self, x: FieldElement, y: FieldElement) -> Result<Tile>;
    async fn get_inventory(&self) -> Result<Inventory>;
    async fn create_game(&self, name: FieldElement) -> Result<FieldElement>;
    async fn make_move(&self, action: Action, direction: Direction) -> Result<FieldElement>;
    async fn reveal(&self) -> Result<FieldElement>;
    async fn new_game(&self) -> Result<FieldElement>;
}
