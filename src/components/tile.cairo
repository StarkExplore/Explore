use array::ArrayTrait;

// @notice: This is the tile component used to know what is explored
// and what is not. It also contains the number of dangers around.
// @param explored: 0: unexplored, 1: explored
// @param dangers: Number of dangers around
// @param x: x coordinate
// @param y: y coordinate
#[derive(Component, Copy, Drop, Serde)]
struct Tile {
    explored: u8,
    dangers: u8,
    x: u16,
    y: u16,
}
