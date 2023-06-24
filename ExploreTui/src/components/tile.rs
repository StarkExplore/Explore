use starknet::core::types::FieldElement;

#[derive(Debug)]
pub struct Tile {
    pub explored: bool,
    pub danger: bool,
    pub clue: u8,
    pub x: u16,
    pub y: u16,
}

impl TryFrom<Vec<FieldElement>> for Tile {
    type Error = anyhow::Error;

    fn try_from(value: Vec<FieldElement>) -> Result<Self, Self::Error> {
        Ok(Tile {
            explored: value[0] != FieldElement::ZERO,
            danger: value[1] != FieldElement::ZERO,
            clue: value[2].try_into()?,
            x: value[3].try_into()?,
            y: value[4].try_into()?,
        })
    }
}
