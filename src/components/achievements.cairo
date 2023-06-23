use std::collections::HashMap;
use array::ArrayTrait;


#[derive(Component, Copy, Drop, Serde)]
struct Achievement {
    name: String,
    description: String,
    aquired: bool,
}

#[derive(Component, Copy, Serde)]
struct Achievements {
    player_address: String,
    achievements: HashMap<String, Achievement>,
}

trait AchievmentsTrait{
    fn get(address: String) -> Achievements;
    fn create(address: String) -> Achievements;
}

impl AchievmentsImpl of AchievmentsTrait {
    fn get(address: String) -> Achievements {
        // let mut achievements = HashMap::new();
        // let achievement = Achievement {
        //     name: "First".to_string(),
        //     description: "First achievement".to_string(),
        //     aquired: false,
        // };
        // achievements.insert("First".to_string(), achievement);
        // Achievements {
        //     player_address: address,
        //     achievements: achievements,
        // }
    }

    fn createLevelUpAchievement(level: u8) -> Achievement {
        let name = format!('Level {}', level);
        let description = format!('Level {} is completed', level);
        Achievement {
            name: name,
            description: description,
            aquired: false,
        }
    }

    fn createPerfectAchievement(level: u8) -> Achievement {
        let name = format!('Perfect {}', level);
        let description = format!('Perfect level {}!', level);
        Achievement {
            name: name,
            description: description,
            aquired: false,
        }
    }

    fn createLooserAchievement(level: u8) -> Achievement {
        let name = format!('Looser {}', level);
        let description = format!('5 loose on level {}!', level);
        Achievement {
            name: name,
            description: description,
            aquired: false,
        }
    }

    fn create(address: String) -> Achievements {
        let mut achievements = HashMap::new();
        achievements.insert('Level 1', createLevelUpAchievement(1));
        achievements.insert('Level 2', createLevelUpAchievement(2));
        achievements.insert('Level 3', createLevelUpAchievement(3));
        achievements.insert('Perfect1', createPerfectAchievement(1));
        achievements.insert('Perfect2', createPerfectAchievement(2));
        achievements.insert('Perfect3', createPerfectAchievement(3));
        achievements.insert('Looser1', createLooserAchievement(1));
        achievements.insert('Looser2', createLooserAchievement(2));
        achievements.insert('Looser3', createLooserAchievement(3));
        
        Achievements {
            player_address: address,
            achievements: achievements,
        }
    }
}