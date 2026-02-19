"""
Game State Reader
Reads game state from JSON file
"""
import json
import os
from pathlib import Path


class StateReader:
    def __init__(self, state_file: str = None):
        if state_file is None:
            # Default path for Windows
            state_file = os.path.join(os.path.expanduser("~"), "AppData", "Local", "LokiAssist", "game_state.json")
        self.state_file = state_file
        self.last_state = {}

    def read_state(self) -> dict:
        """Read game state from JSON file"""
        try:
            if not os.path.exists(self.state_file):
                return self._get_default_state()

            with open(self.state_file, 'r', encoding='utf-8') as f:
                state = json.load(f)
                self.last_state = state
                return state
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error reading state: {e}")
            return self._get_default_state()

    def _get_default_state(self) -> dict:
        """Return default state when file doesn't exist"""
        return {
            "playerName": "",
            "playerClass": "",
            "healthPercent": 100,
            "power": 0,
            "maxPower": 100,
            "inCombat": False,
            "targetName": "",
            "targetHealthPercent": 100,
            "bossName": "",
            "bossHealthPercent": 100,
            "cooldowns": {},
            "buffs": {},
            "debuffs": {},
            "trinketReady": True,
            "potionReady": True,
            "position": {"x": 0, "y": 0},
            "targetPosition": {"x": 0, "y": 0}
        }

    def is_in_combat(self) -> bool:
        """Check if player is in combat"""
        return self.last_state.get("inCombat", False)

    def get_health_percent(self) -> float:
        """Get player health percentage"""
        return self.last_state.get("healthPercent", 100)

    def get_power(self) -> float:
        """Get player current power"""
        return self.last_state.get("power", 0)

    def get_cooldown(self, spell_name: str) -> float:
        """Get cooldown for a specific spell (in seconds)"""
        cooldowns = self.last_state.get("cooldowns", {})
        return cooldowns.get(spell_name, 0)

    def has_buff(self, buff_name: str) -> bool:
        """Check if player has a specific buff"""
        buffs = self.last_state.get("buffs", {})
        return buff_name in buffs

    def has_debuff(self, debuff_name: str) -> bool:
        """Check if target has a specific debuff"""
        debuffs = self.last_state.get("debuffs", {})
        return debuff_name in debuffs

    def get_target_health_percent(self) -> float:
        """Get target health percentage"""
        return self.last_state.get("targetHealthPercent", 100)
