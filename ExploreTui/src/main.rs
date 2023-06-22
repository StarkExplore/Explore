use clap::Parser;
use std::error::Error;

mod game_display;

/// Terminal interface for StarkExplore
#[derive(Parser, Debug)]
#[command(version, about)]
struct Args {
   /// StarkNet RPC endpoint
   #[arg(short, long, default_value = "http://localhost:5050")]
   rpc: String,
}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    game_display::start()
}
