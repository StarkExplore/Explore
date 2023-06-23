use clap::Parser;
use std::{error::Error, path::PathBuf};
use crate::options::{world::WorldOptions, starknet::StarknetOptions, account::AccountOptions};

use dojo_world::world::WorldContract;

mod game_display;
mod game_interface;
mod options;

/// Terminal interface for StarkExplore
#[derive(Parser, Debug)]
#[command(version, about)]
pub struct Args {
    #[arg(long)]
    #[arg(global = true)]
    #[arg(hide_short_help = true)]
    #[arg(env = "DOJO_MANIFEST_PATH")]
    #[arg(help = "Override path to a directory containing a Scarb.toml file.")]
    pub manifest_path: Option<PathBuf>,

    #[command(flatten)]
    pub world: WorldOptions,

    #[command(flatten)]
    pub starknet: StarknetOptions,

    #[command(flatten)]
    pub account: AccountOptions,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    let env_metadata = None;
    
    let Args { world, starknet, account, .. } = args;

    let world_address = world.address(env_metadata.as_ref())?;
    let provider = starknet.provider(env_metadata.as_ref())?;

    let account = account.account(provider, env_metadata.as_ref()).await?;
    let world = WorldContract::new(world_address, &account);

    let interface = game_interface::GameInterface::new(world);

    game_display::start(interface)
}
