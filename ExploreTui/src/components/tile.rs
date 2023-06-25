use starknet::core::types::FieldElement;

#[derive(Debug)]
pub struct Tile {
    pub explored: bool,
    pub mine: bool,
    pub danger: bool,
    pub shield: bool,
    pub kit: bool,
    pub clue: u8,
    pub x: u16,
    pub y: u16,
}

impl TryFrom<Vec<FieldElement>> for Tile {
    type Error = anyhow::Error;

    fn try_from(value: Vec<FieldElement>) -> Result<Self, Self::Error> {
        Ok(Tile {
            explored: value[0] != FieldElement::ZERO,
            mine: value[1] != FieldElement::ZERO,
            danger: value[2] != FieldElement::ZERO,
            shield: value[3] != FieldElement::ZERO,
            kit: value[4] != FieldElement::ZERO,
            clue: value[5].try_into()?,
            x: value[6].try_into()?,
            y: value[7].try_into()?,
        })
    }
}
