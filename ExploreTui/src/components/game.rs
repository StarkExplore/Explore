use starknet::core::types::FieldElement;
use toml::de;

#[derive(Debug)]
pub struct Game {
    pub name: String,
    pub status: bool,
    pub score: u64,
    pub seed: [u8; 32],
    pub commited_block_timestamp: u64,
    pub x: u16,
    pub y: u16,
    pub level: u8,
    pub size: u16,
    pub action: u8,
}

impl TryFrom<Vec<FieldElement>> for Game {
    type Error = anyhow::Error;

    fn try_from(value: Vec<FieldElement>) -> Result<Self, Self::Error> {
        Ok(Game {
            name: String::from_utf8(value[0].to_bytes_be().to_vec())?,
            status: value[1] == 0_u8.into(),
            score: value[2].try_into()?,
            seed: value[3].to_bytes_be(),
            commited_block_timestamp: value[4].try_into()?,
            x: value[5].try_into()?,
            y: value[6].try_into()?,
            level: value[7].try_into()?,
            size: value[8].try_into()?,
            action: value[9].try_into()?,
        })
    }
}
