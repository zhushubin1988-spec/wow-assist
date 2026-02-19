"""
Rotation Engine
Manages the combat rotation logic - works with screenshot reader
"""
import time
from typing import Dict, List, Optional

from core.key_simulator import KeySimulator
from config.rotations import get_rotation


class RotationEngine:
    def __init__(self, memory_reader, key_simulator: KeySimulator):
        self.memory_reader = memory_reader
        self.key_simulator = key_simulator
        self.is_running = False

        # Current class and settings
        self.current_class = None
        self.rotation = None

        # Options
        self.combat_protect = True
        self.auto_trinket = False
        self.auto_potion = False
        self.auto_follow = False
        self.manual_interrupt = False

        # State tracking
        self.last_action_time = 0
        self.action_cooldown = 0.1  # 100ms between actions
        self.gcd_remaining = 0
        self.last_gcd_time = 0

        # Keybinds: spell name -> key
        self.keybinds = {}

    def set_keybinds(self, keybinds: dict):
        """Set the keybinds (spell name -> key)"""
        self.keybinds = keybinds

    def set_class(self, class_name: str):
        """Set the current class and load its rotation"""
        class_map = {
            "死亡骑士": "death_knight",
            "猎人": "hunter",
            "战士": "warrior",
            "武僧": "monk",
            "萨满": "shaman",
            "德鲁伊": "druid"
        }
        self.current_class = class_map.get(class_name, "death_knight")
        self.rotation = get_rotation(self.current_class)

    def set_options(self, combat_protect: bool = True, auto_trinket: bool = False,
                   auto_potion: bool = False, auto_follow: bool = False,
                   manual_interrupt: bool = False):
        """Set the rotation options"""
        self.combat_protect = combat_protect
        self.auto_trinket = auto_trinket
        self.auto_potion = auto_potion
        self.auto_follow = auto_follow
        self.manual_interrupt = manual_interrupt

    def start(self):
        """Start the rotation engine"""
        self.is_running = True
        print(f"Rotation started for class: {self.current_class}")

    def stop(self):
        """Stop the rotation engine"""
        self.is_running = False
        print("Rotation stopped")

    def update(self):
        """Main update loop called every tick"""
        if not self.is_running or not self.rotation:
            return

        # Rate limiting
        current_time = time.time()
        if current_time - self.last_action_time < self.action_cooldown:
            return

        # Get game state from memory reader
        state = self.memory_reader.get_game_state()

        # Check if we should be in combat
        in_combat = state.get("inCombat", False)

        if self.combat_protect and not in_combat:
            return

        # Execute rotation
        self._execute_rotation(state)

        self.last_action_time = current_time

    def _execute_rotation(self, state: dict):
        """Execute the rotation based on current state"""
        if not self.rotation:
            return

        # Check GCD
        if self.gcd_remaining > 0:
            current_time = time.time()
            self.gcd_remaining = max(0, self.gcd_remaining - (current_time - self.last_gcd_time))
            self.last_gcd_time = current_time
            return

        # Check health for self-preservation
        health_percent = state.get("healthPercent", 100)
        if health_percent < 20:
            # Use healthstone or self-heal
            self.key_simulator.press_key('7', 0.05)
            return

        # Execute each spell in priority
        for spell in self.rotation:
            if self._should_cast_spell(spell, state):
                self._cast_spell(spell)
                return

    def _should_cast_spell(self, spell: dict, state: dict) -> bool:
        """Check if a spell should be cast based on conditions"""
        spell_name = spell.get("name")
        key = spell.get("key")
        conditions = spell.get("conditions", {})

        # Check power requirement
        power = state.get("power", 0)
        power_cost = conditions.get("power", 0)
        if power < power_cost:
            return False

        # Check target health
        if "target_health_above" in conditions:
            if state.get("targetHealthPercent", 0) < conditions["target_health_above"]:
                return False

        if "target_health_below" in conditions:
            if state.get("targetHealthPercent", 100) > conditions["target_health_below"]:
                return False

        return True

    def _cast_spell(self, spell: dict):
        """Cast a spell using configured keybind"""
        spell_name = spell.get("name")

        # Look up the key from our keybinds config
        key = self.keybinds.get(spell_name)
        if not key:
            # Fallback to spell key if not in keybinds
            key = spell.get("key")

        if not key:
            return

        # Check if it's a modifier key combo
        modifier = spell.get("modifier")
        if modifier:
            self.key_simulator.press_key_with_modifier(modifier, key)
        else:
            self.key_simulator.press_key(key)

        # Set GCD
        gcd = spell.get("gcd", 1.5)
        self.gcd_remaining = gcd
        self.last_gcd_time = time.time()
