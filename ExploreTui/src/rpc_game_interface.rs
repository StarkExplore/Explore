use crate::minesweeper::MinesweeperInterface;
use crate::movement::{Action, Direction};
use anyhow::Result;
use async_trait::async_trait;

use dojo_world::world::WorldContract;
use starknet::accounts::Account;
use starknet::core::types::{BlockId, BlockTag, FieldElement};
use starknet::{
    accounts::SingleOwnerAccount,
    providers::{jsonrpc::HttpTransport, JsonRpcClient},
    signers::LocalWallet,
};
use crate::components::{Game, Tile};

type LocalAccount = SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>;

pub struct RpcGameInterface<'a> {
    world: WorldContract<'a, LocalAccount>,
}

impl<'a> RpcGameInterface<'a> {
    pub fn new(world: WorldContract<'a, LocalAccount>) -> Self {
        RpcGameInterface { world }
    }

    // return the raw bytes of the entity for a given component given its name and entity key
    async fn get_component_raw(
        &self,
        name: &str,
        keys: Vec<FieldElement>,
    ) -> Result<Vec<FieldElement>> {
        let component = self
            .world
            .component(name, BlockId::Tag(BlockTag::Pending))
            .await?;
        Ok(component
            .entity(0_u8.into(), keys, BlockId::Tag(BlockTag::Pending))
            .await?)
    }

    async fn execute_system_raw(
        &self,
        system: &str,
        calldata: Vec<FieldElement>,
    ) -> Result<FieldElement> {
        let res = self.world.execute(system, calldata).await?;
        Ok(res.transaction_hash)
    }
}

#[async_trait]
impl<'a> MinesweeperInterface for RpcGameInterface<'a> {
    // gets the game for the current account
    async fn get_game(&self) -> Result<Game> {
        self.get_component_raw("Game", vec![self.world.account.address()])
            .await.map(TryInto::try_into)?
    }

    async fn get_tile(&self, x: FieldElement, y: FieldElement) -> Result<Tile> {
        self.get_component_raw("Tile", vec![self.world.account.address(), x, y])
            .await.map(TryInto::try_into)?
    }

    async fn create_game(&self, name: FieldElement) -> Result<FieldElement> {
        self.execute_system_raw("Move", vec![name]).await
    }

    async fn make_move(&self, action: Action, direction: Direction) -> Result<FieldElement> {
        self.execute_system_raw("Move", vec![action.into(), direction.into()])
            .await
    }

    async fn reveal(&self) -> Result<FieldElement> {
        self.execute_system_raw("Reveal", vec![]).await
    }
}
