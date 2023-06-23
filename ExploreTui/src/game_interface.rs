use starknet::{accounts::{SingleOwnerAccount}, providers::{JsonRpcClient, jsonrpc::HttpTransport}, signers::LocalWallet};
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
}
