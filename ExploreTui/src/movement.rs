use starknet::core::types::FieldElement;
pub enum Direction {
    Left,
    UpLeft,
    Up,
    UpRight,
    Right,
    DownRight,
    Down,
    DownLeft,
}

impl Into<FieldElement> for Direction {
    fn into(self) -> FieldElement {
        match self {
            Direction::Left => 0_u8.into(),
            Direction::UpLeft => 1_u8.into(),
            Direction::Up => 2_u8.into(),
            Direction::UpRight => 3_u8.into(),
            Direction::Right => 4_u8.into(),
            Direction::DownRight => 5_u8.into(),
            Direction::Down => 6_u8.into(),
            Direction::DownLeft => 7_u8.into(),
        }
    }
}

pub enum Action {
    Safe,
    Unsafe,
}

impl Into<FieldElement> for Action {
    fn into(self) -> FieldElement {
        match self {
            Action::Safe => 0_u8.into(),
            Action::Unsafe => 1_u8.into(),
        }
    }
}
