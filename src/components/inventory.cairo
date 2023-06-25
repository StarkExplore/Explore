use array::ArrayTrait;

// @notice The is the Inventory component that is used to store player's objects
// @dev Merged into Game component until the gas limit of tests is increased
// @param shield A boolean that indicates if the player has a shield
// @param kits The number of kits the player has
#[derive(Component, Copy, Drop, Serde)]
struct Inventory {
    shield: bool,
    kits: u16,
}
