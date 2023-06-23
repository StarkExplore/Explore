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
    pub async fn get_component_raw(&self, name: String, keys: Vec<FieldElement>) -> Result<Vec<FieldElement>> {
        let component = self.world.component(&name, BlockId::Tag(BlockTag::Pending)).await?;
        Ok(component.entity(0_u8.into(), keys, BlockId::Tag(BlockTag::Pending)).await?)
    }

    // gets the game for the current account
    pub async fn get_game(&self) -> Result<Vec<FieldElement>> {
        self.get_component_raw(String::from("Game"), vec![self.world.address.into()]).await
    }
}
