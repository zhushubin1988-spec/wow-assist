"""
Chat Log Reader
Reads game state from WoW chat log
"""
import os
import re
import json
from datetime import datetime


class ChatLogReader:
    def __init__(self):
        # Default WoW chat log path
        self.chat_log_path = None
        self.last_position = 0
        self.state = {}
        self.keybinds = {}

    def find_chat_log(self):
        """Find the WoW chat log file"""
        # Common paths
        paths = [
            os.path.expanduser("~/Documents/WoW/Logs/Chat.log"),
            os.path.expanduser("~/Documents/World of Warcraft/_retail_/Logs/Chat.log"),
            os.path.expanduser("~/Documents/World of Warcraft/Logs/Chat.log"),
        ]

        for path in paths:
            if os.path.exists(path):
                self.chat_log_path = path
                return True
        return False

    def read_state(self) -> dict:
        """Read latest state from chat log"""
        if not self.chat_log_path:
            if not self.find_chat_log():
                return self._get_default_state()

        try:
            with open(self.chat_log_path, 'r', encoding='utf-8', errors='ignore') as f:
                f.seek(self.last_position)
                new_lines = f.readlines()
                self.last_position = f.tell()

                # Parse new lines
                for line in new_lines:
                    self._parse_line(line)

        except (IOError, OSError) as e:
            print(f"Error reading chat log: {e}")

        return self.state

    def _parse_line(self, line: str):
        """Parse a chat log line"""
        # Look for our marker: @LOKI@Data|
        if "@LOKI@Data|" in line:
            try:
                # Extract data after marker
                data_str = line.split("@LOKI@Data|")[1].strip()
                data = self._parse_data(data_str)

                if data:
                    self.state = data.get('state', {})
                    self.keybinds = data.get('keybinds', {})
            except Exception as e:
                print(f"Error parsing LOKI data: {e}")

    def _parse_data(self, data_str: str) -> dict:
        """Parse the data string"""
        # Format: p:name,c:CLASS,hp:100,pp:50,mp:100,ic:1,tn:target,thp:80,kb:{...}
        result = {
            'state': {},
            'keybinds': {}
        }

        # Simple parsing
        parts = data_str.split(',')
        state = {}
        keybinds = {}

        for part in parts:
            if ':' in part:
                key, value = part.split(':', 1)

                # Keybinds (special handling)
                if key == 'kb':
                    # This would need more complex parsing
                    continue

                # Parse state values
                if key == 'p':
                    state['playerName'] = value
                elif key == 'c':
                    state['playerClass'] = value
                elif key == 'hp':
                    state['healthPercent'] = int(value)
                elif key == 'pp':
                    state['power'] = int(value)
                elif key == 'mp':
                    state['maxPower'] = int(value)
                elif key == 'ic':
                    state['inCombat'] = value == '1'
                elif key == 'tn':
                    state['targetName'] = value
                elif key == 'thp':
                    state['targetHealthPercent'] = int(value)
                elif key == 'bf':
                    state['buffs'] = {'count': int(value)}
                elif key == 'df':
                    state['debuffs'] = {'count': int(value)}

        result['state'] = state
        result['keybinds'] = keybinds
        return result

    def _get_default_state(self) -> dict:
        """Return default state"""
        return {
            "playerName": "",
            "playerClass": "",
            "healthPercent": 100,
            "power": 0,
            "maxPower": 100,
            "inCombat": False,
            "targetName": "",
            "targetHealthPercent": 100,
            "buffs": {},
            "debuffs": {}
        }

    def get_keybinds(self) -> dict:
        """Get current keybinds"""
        return self.keybinds

    def is_in_combat(self) -> bool:
        """Check if player is in combat"""
        return self.state.get("inCombat", False)

    def get_health_percent(self) -> float:
        """Get player health percentage"""
        return self.state.get("healthPercent", 100)

    def get_power(self) -> float:
        """Get player current power"""
        return self.state.get("power", 0)

    def get_target_health_percent(self) -> float:
        """Get target health percentage"""
        return self.state.get("targetHealthPercent", 100)
