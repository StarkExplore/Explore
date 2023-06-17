#[system]
mod Tile {
    use traits::Into;

    use explore::components::tile::Tile;
    use explore::components::game::Game;
    use explore::constants::{DIFFICULTY};

    fn execute(ctx: Context, game_id: u32, x: u16, y: u16) -> felt252 {

        let tileId =  (game_id, x, y);

        // [Compute] Create a tile
        let tile = Tile {
            x: x, y: y, explored: 1, dangers: DIFFICULTY //TODO add randomness around that
        };

        //set the storage partition to the owner. so the storage key would be like (owner_id, (army_id)). 
        //that way you can query for all armies an owner owns like storage::<Army>::entities(owner_id)

        // [Command] create the tile entity
        commands::set_entity(tileId.into(), (game_id, tile));
        //commands::set_entity(tileId.into(), tile);

        tileId.into()
    }
}
