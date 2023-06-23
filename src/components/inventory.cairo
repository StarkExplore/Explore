use array::ArrayTrait;

#[derive(Component, Copy, Drop, Serde)]
struct Inventory {
    shield: bool,
    defuse_kit: u8,
}
