use crate::options::{account::AccountOptions, starknet::StarknetOptions, world::WorldOptions};
use clap::Parser;
use options::dojo_metadata_from_workspace;
use scarb::core::Config;

use dojo_world::world::WorldContract;

mod display;
mod game_interface;
mod movement;
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
    pub manifest_path: Option<camino::Utf8PathBuf>,

    #[command(flatten)]
    pub world: WorldOptions,

    #[command(flatten)]
    pub starknet: StarknetOptions,

    #[command(flatten)]
    pub account: AccountOptions,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    let Args {
        world,
        starknet,
        account,
        ..
    } = args;

    let manifest_path = scarb::ops::find_manifest_path(args.manifest_path.as_deref())?;

    let config = Config::builder(manifest_path).build()?;

    let env_metadata = if config.manifest_path().exists() {
        let ws = scarb::ops::read_workspace(config.manifest_path(), &config)?;
        let env_metadata = dojo_metadata_from_workspace(&ws)
            .and_then(|dojo_metadata| dojo_metadata.get("env").cloned());
        env_metadata
            .as_ref()
            .and_then(|env_metadata| env_metadata.get(ws.config().profile().as_str()).cloned())
            .or(env_metadata)
    } else {
        None
    };

    let world_address = world.address(env_metadata.as_ref())?;
    let provider = starknet.provider(env_metadata.as_ref())?;

    let account = account.account(provider, env_metadata.as_ref()).await?;
    let world = WorldContract::new(world_address, &account);

    let interface = game_interface::GameInterface::new(world);

    let game = interface.get_game().await?;
    print!("{:?}", game);
    Ok(())
    // game_display::start(interface)
}