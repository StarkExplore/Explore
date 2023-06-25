use starknet::core::types::FieldElement;

#[derive(Debug, Default)]
pub struct Inventory {
    pub shield: bool,
    pub kits: u16,
}

impl TryFrom<Vec<FieldElement>> for Inventory {
    type Error = anyhow::Error;

    fn try_from(value: Vec<FieldElement>) -> Result<Self, Self::Error> {
        Ok(Inventory {
            shield: value[0] != FieldElement::ZERO,
            kits: value[1].try_into()?,
        })
    }
}
