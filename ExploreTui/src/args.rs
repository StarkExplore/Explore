use anyhow::Result;
use clap::Parser;
use dojo_world::world::WorldContract;
use scarb::core::Config;
use starknet::{
    accounts::SingleOwnerAccount,
    providers::{jsonrpc::HttpTransport, JsonRpcClient},
    signers::LocalWallet,
};
use toml::Value;

use crate::options::dojo_metadata_from_workspace;
use crate::options::{account::AccountOptions, starknet::StarknetOptions, world::WorldOptions};
use crate::rpc_game_interface::RpcGameInterface;

/// Terminal interface for StarkExplore
#[derive(Parser, Debug)]
#[command(version, about)]
pub struct Args {
    #[arg(long)]
    #[arg(global = true)]
    #[arg(hide_short_help = true)]
    #[arg(env = "DOJO_MANIFEST_PATH")]
    #[arg(help = "Override path to a directory containing a Scarb.toml file.")]
    pub manifest_path: Option<camino::Utf8PathBuf>,

    #[command(flatten)]
    pub world: WorldOptions,

    #[command(flatten)]
    pub starknet: StarknetOptions,

    #[command(flatten)]
    pub account: AccountOptions,
}

impl Args {
    fn env_metadata(&self) -> Result<Option<Value>> {
        let manifest_path = scarb::ops::find_manifest_path(self.manifest_path.as_deref())?;
        let config = Config::builder(manifest_path).build()?;

        if config.manifest_path().exists() {
            let ws = scarb::ops::read_workspace(config.manifest_path(), &config)?;
            let env_metadata = dojo_metadata_from_workspace(&ws)
                .and_then(|dojo_metadata| dojo_metadata.get("env").cloned());
            Ok(env_metadata
                .as_ref()
                .and_then(|env_metadata| env_metadata.get(ws.config().profile().as_str()).cloned())
                .or(env_metadata))
        } else {
            Ok(None)
        }
    }

    pub async fn get_account(
        &self,
    ) -> Result<SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>> {
        let Args {
            starknet, account, ..
        } = self;
        let env_metadata = self.env_metadata()?;
        let provider = starknet.provider(env_metadata.as_ref())?;
        account.account(provider, env_metadata.as_ref()).await
    }

    pub fn build_starknet_interface<'a>(
        &self,
        account: &'a SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>,
    ) -> Result<RpcGameInterface<'a>> {
        let Args { world, .. } = self;
        let world_address = world.address(self.env_metadata()?.as_ref())?;
        let world = WorldContract::new(world_address, account);
        Ok(RpcGameInterface::new(world))
    }
}
