
use clap::Parser;





use args::Args;

mod args;
mod components;
mod display;
mod minesweeper;
mod movement;
mod options;
mod rpc_game_interface;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let account = args.get_account().await?;
    let interface = args.build_starknet_interface(&account)?;

    display::start(interface).await?;

    Ok(())
}
