use args::Args;
use clap::Parser;

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
    let account = match args.get_account().await {
        Ok(account) => account,
        Err(e) => {
            eprintln!("\n\nError: Could not connect to RPC. Did you start katana already?");
            return Ok(());
        }
    };
    let interface = args.build_starknet_interface(&account)?;

    display::start(interface).await?;

    Ok(())
}
