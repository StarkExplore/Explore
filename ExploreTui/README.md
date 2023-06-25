# Explore Terminal UI

A Terminal UI for Explore written in Rust

## Usage

For simple usage just ensure that katana is running and run:

```
cargo run
```

If no game is displayed then press `n` to create a new game.

## Advanced Usage

The TUI accepts the same command line arguments as sozo and these can be used to configure different accounts or networks

```shell
Terminal interface for StarkExplore

Usage: explore_tui [OPTIONS]

Options:
      --manifest-path <MANIFEST_PATH>
          Override path to a directory containing a Scarb.toml file.
          
          [env: DOJO_MANIFEST_PATH=]

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version

World options:
      --world <WORLD_ADDRESS>
          The address of the World contract.

Starknet options:
      --rpc-url <URL>
          The Starknet RPC endpoint.

Account options:
      --account-address <ACCOUNT_ADDRESS>
          

Signer options - RAW:
      --private-key <PRIVATE_KEY>
          The raw private key associated with the account contract.

Signer options - KEYSTORE:
      --keystore <PATH>
          Use the keystore in the given folder or file.

      --password <PASSWORD>
          The keystore password. Used with --keystore.
```
