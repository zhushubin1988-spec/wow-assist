"""
Rotation configurations for each class
"""

def get_rotation(class_name: str) -> list:
    """Get rotation for the specified class"""
    rotations = {
        "death_knight": death_knight_rotation,
        "hunter": hunter_rotation,
        "warrior": warrior_rotation,
        "monk": monk_rotation,
        "shaman": shaman_rotation,
        "druid": druid_rotation
    }
    return rotations.get(class_name, death_knight_rotation)()


def death_knight_rotation() -> list:
    """
    Blood DK Rotation
    """
    return [
        # Out of combat: Apply diseases
        {
            "name": "枯萎凋零",
            "key": "q",
            "conditions": {"has_not_debuff": "枯萎凋零", "power": 1},
            "gcd": 1.5
        },
        {
            "name": "暗影打击",
            "key": "1",
            "conditions": {"has_not_debuff": "血之疫病", "power": 1},
            "gcd": 0
        },
        {
            "name": "传染",
            "key": "2",
            "conditions": {"has_buff": "血之疫病", "has_buff": "冰之疫病", "power": 1},
            "gcd": 0
        },
        # In combat: Maintain diseases, then spam heart strike
        {
            "name": "枯萎凋零",
            "key": "q",
            "conditions": {"has_not_debuff": "枯萎凋零", "power": 1},
            "gcd": 1.5
        },
        {
            "name": "暗影打击",
            "key": "1",
            "conditions": {"has_not_debuff": "血之疫病", "power": 1},
            "gcd": 0
        },
        {
            "name": "传染",
            "key": "2",
            "conditions": {"has_buff": "血之疫病", "has_buff": "冰之疫病", "power": 1},
            "gcd": 0
        },
        {
            "name": "心脏打击",
            "key": "3",
            "conditions": {"power": 25},
            "gcd": 0
        },
        {
            "name": "灵界打击",
            "key": "4",
            "conditions": {"power": 40},
            "gcd": 0
        },
        {
            "name": "符文打击",
            "key": "5",
            "conditions": {"power": 30},
            "gcd": 1.5
        },
        {
            "name": "血液沸腾",
            "key": "e",
            "conditions": {"power": 10},
            "gcd": 0
        },
    ]


def hunter_rotation() -> list:
    """
    Beast Mastery Hunter Rotation
    """
    return [
        # Cooldowns
        {
            "name": "狂野怒火",
            "key": "q",
            "conditions": {"target_health_above": 20},
            "gcd": 1.5
        },
        {
            "name": "误导",
            "key": "e",
            "conditions": {},
            "gcd": 0
        },
        # Maintain dots
        {
            "name": "钉刺",
            "key": "1",
            "conditions": {"has_not_debuff": "钉刺", "power": 10},
            "gcd": 1.5
        },
        # Main damage
        {
            "name": "杀戮命令",
            "key": "2",
            "conditions": {"power": 40},
            "gcd": 0
        },
        {
            "name": "奥术射击",
            "key": "3",
            "conditions": {"power": 20},
            "gcd": 0
        },
        {
            "name": "多重射击",
            "key": "4",
            "conditions": {"power": 35},
            "gcd": 0
        },
        {
            "name": "眼镜蛇射击",
            "key": "5",
            "conditions": {"power": 30},
            "gcd": 0
        },
    ]


def warrior_rotation() -> list:
    """
    Arms Warrior Rotation
    """
    return [
        # Cooldowns
        {
            "name": "鲁莽",
            "key": "q",
            "conditions": {},
            "gcd": 1.5
        },
        {
            "name": "战旗",
            "key": "e",
            "conditions": {},
            "gcd": 1.5
        },
        # Maintain rend
        {
            "name": "撕裂",
            "key": "1",
            "conditions": {"has_not_debuff": "撕裂", "power": 10},
            "gcd": 1.5
        },
        # Main damage
        {
            "name": "致死打击",
            "key": "2",
            "conditions": {"power": 30},
            "gcd": 0
        },
        {
            "name": "巨人打击",
            "key": "3",
            "conditions": {"power": 30},
            "gcd": 1.5
        },
        {
            "name": "压制",
            "key": "4",
            "conditions": {"has_buff": "压制"},
            "gcd": 0
        },
        {
            "name": "顺劈斩",
            "key": "5",
            "conditions": {"power": 20},
            "gcd": 0
        },
        {
            "name": "英勇打击",
            "key": "6",
            "conditions": {"power": 40},
            "gcd": 0
        },
    ]


def monk_rotation() -> list:
    """
    Windwalker Monk Rotation
    """
    return [
        # Cooldowns
        {
            "name": "轮回之触",
            "key": "q",
            "conditions": {"target_health_below": 10},
            "gcd": 1.5
        },
        {
            "name": "猛虎掌",
            "key": "1",
            "conditions": {"power": 40},
            "gcd": 0
        },
        {
            "name": "幻灭踢",
            "key": "2",
            "conditions": {"power": 50},
            "gcd": 0
        },
        {
            "name": "连击",
            "key": "3",
            "conditions": {"has_not_debuff": "震荡掌", "power": 30},
            "gcd": 1.5
        },
        {
            "name": "碎玉闪电",
            "key": "4",
            "conditions": {"power": 30},
            "gcd": 0
        },
        {
            "name": "旭日东升踢",
            "key": "5",
            "conditions": {"power": 2},
            "gcd": 0
        },
        {
            "name": "腿击",
            "key": "e",
            "conditions": {"power": 25},
            "gcd": 0
        },
    ]


def shaman_rotation() -> list:
    """
    Enhancement Shaman Rotation
    """
    return [
        # Cooldowns
        {
            "name": "元素冲击",
            "key": "q",
            "conditions": {},
            "gcd": 1.5
        },
        {
            "name": "风怒图腾",
            "key": "e",
            "conditions": {},
            "gcd": 1.5
        },
        # Maintain flames
        {
            "name": "烈焰震击",
            "key": "1",
            "conditions": {"has_not_debuff": "烈焰震击", "power": 10},
            "gcd": 1.5
        },
        {
            "name": "冰霜震击",
            "key": "2",
            "conditions": {"has_not_debuff": "冰霜震击", "power": 10},
            "gcd": 1.5
        },
        # Main damage
        {
            "name": "闪电箭",
            "key": "3",
            "conditions": {"power": 20},
            "gcd": 0
        },
        {
            "name": "大地震击",
            "key": "4",
            "conditions": {"power": 20},
            "gcd": 0
        },
        {
            "name": "风暴打击",
            "key": "5",
            "conditions": {"power": 30},
            "gcd": 0
        },
        {
            "name": "火舌",
            "key": "6",
            "conditions": {"power": 20},
            "gcd": 0
        },
    ]


def druid_rotation() -> list:
    """
    Feral Druid Rotation
    """
    return [
        # Cooldowns
        {
            "name": "狂暴",
            "key": "q",
            "conditions": {},
            "gcd": 1.5
        },
        # Maintain rip and rake
        {
            "name": "斜掠",
            "key": "1",
            "conditions": {"has_not_debuff": "斜掠", "power": 35},
            "gcd": 0
        },
        {
            "name": "割裂",
            "key": "2",
            "conditions": {"has_not_debuff": "割裂", "power": 30, "target_health_above": 30},
            "gcd": 1.5
        },
        # Main damage
        {
            "name": "凶猛撕咬",
            "key": "3",
            "conditions": {"has_debuff": "割裂", "power": 50, "target_health_above": 30},
            "gcd": 0
        },
        {
            "name": "爪击",
            "key": "4",
            "conditions": {"power": 40},
            "gcd": 0
        },
        {
            "name": "裂伤",
            "key": "5",
            "conditions": {"power": 40},
            "gcd": 0
        },
        {
            "name": "猫的攻击",
            "key": "e",
            "conditions": {"power": 15},
            "gcd": 0
        },
    ]
