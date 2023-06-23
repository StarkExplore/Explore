use anyhow::Result;
use starknet::{accounts::{SingleOwnerAccount}, providers::{JsonRpcClient, jsonrpc::HttpTransport}, signers::LocalWallet};
use starknet::core::types::{BlockId, BlockTag, FieldElement};
use dojo_world::world::WorldContract;

type LocalAccount = SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>;

// used for reading and writing a Explore game
pub struct GameInterface<'a> {
    world: WorldContract<'a, LocalAccount>,
}

impl<'a> GameInterface<'a> {
    pub fn new(world: WorldContract<'a, LocalAccount>) -> Self {
        GameInterface {
            world
        }
    }

    // return the raw bytes of the entity for a given component given its name and entity key
    async fn get_component_raw(&self, name: &str, keys: Vec<FieldElement>) -> Result<Vec<FieldElement>> {
        let component = self.world.component(name, BlockId::Tag(BlockTag::Pending)).await?;
        Ok(component.entity(0_u8.into(), keys, BlockId::Tag(BlockTag::Pending)).await?)
    }

    async fn execute_system_raw(&self, system: &str, calldata: Vec<FieldElement>) -> Result<FieldElement> {
        let res =
        self.world.execute(&system, calldata).await?;
        Ok(res.transaction_hash)
    }

    // gets the game for the current account
    pub async fn get_game(&self) -> Result<Vec<FieldElement>> {
        self.get_component_raw("Game", vec![self.world.address.into()]).await
    }

    pub async fn create_game(&self, name: FieldElement) -> Result<FieldElement> {
        self.execute_system_raw("Move", vec![name]).await
    }
    
}
