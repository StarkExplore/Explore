use array::ArrayTrait;


#[derive(Component, Copy, Drop, Serde)]
struct Achievement {
    name: felt252,
    description: felt252,
    aquired: bool,
}

#[derive(Component, Serde, Drop)]
struct Achievements {
    player_address: felt252,
    achievements: Array<Achievement>,
}

trait AchievementsTrait{
    // fn get(address: felt252) -> Achievements;
    fn create(address: felt252) -> Achievements;
    fn createLevelUpAchievement(level: felt252) -> Achievement;
    fn createPerfectAchievement(level: felt252) -> Achievement;
    fn createLooserAchievement(level: felt252) -> Achievement;
}

impl AchievementsImpl of AchievementsTrait {
    // fn get(address: felt252) -> Achievements {
    //     // let mut achievements = HashMap::new();
    //     // let achievement = Achievement {
    //     //     name: "First".to_felt252(),
    //     //     description: "First achievement".to_felt252(),
    //     //     aquired: false,
    //     // };
    //     // achievements.insert("First".to_felt252(), achievement);
    //     // Achievements {
    //     //     player_address: address,
    //     //     achievements: achievements,
    //     // }
    // }

    fn createLevelUpAchievement(level: felt252) -> Achievement {
        let name : felt252 = ('Level '+ level);

        let description = 'Level' + level +' is completed';
        Achievement {
            name: name,
            description: description,
            aquired: false,
        }
    }

    fn createPerfectAchievement(level: felt252) -> Achievement {
        let name = ('Perfect ' + level);
        let description = ('Perfect level ' + level + '!');
        Achievement {
            name: name,
            description: description,
            aquired: false,
        }
    }

    fn createLooserAchievement(level: felt252) -> Achievement {
        let name = ('Looser ' + level);
        let description = ('5 loose on level ' + level + '!');
        Achievement {
            name: name,
            description: description,
            aquired: false,
        }
    }

    fn create(address: felt252) -> Achievements {
        let mut achievements = ArrayTrait::<Achievement>::new();
        achievements.append(AchievementsTrait::createLevelUpAchievement(1));
        achievements.append(AchievementsTrait::createLevelUpAchievement(2));
        achievements.append(AchievementsTrait::createLevelUpAchievement(3));
        achievements.append(AchievementsTrait::createPerfectAchievement(1));
        achievements.append(AchievementsTrait::createPerfectAchievement(2));
        achievements.append(AchievementsTrait::createPerfectAchievement(3));
        achievements.append(AchievementsTrait::createLooserAchievement(1));
        achievements.append(AchievementsTrait::createLooserAchievement(2));
        achievements.append(AchievementsTrait::createLooserAchievement(3));
        
        Achievements {
            player_address: address,
            achievements: achievements,
        }
    }
}