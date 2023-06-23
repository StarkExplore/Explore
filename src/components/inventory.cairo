use array::ArrayTrait;

#[derive(Component, Copy, Drop, Serde)]
struct Inventory {
    shield: bool,
    kits: u16,
}
