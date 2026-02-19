"""
Key Simulator
Simulates key presses using Windows API
"""
import time
import sys

# Only import win32 on Windows
if sys.platform == "win32":
    import win32api
    import win32con
    import ctypes


class KeySimulator:
    def __init__(self):
        self.key_map = self._init_key_map()

    def _init_key_map(self) -> dict:
        """Initialize key code mapping"""
        return {
            '1': 0x31, '2': 0x32, '3': 0x33, '4': 0x34, '5': 0x35,
            '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39, '0': 0x30,
            'q': 0x51, 'w': 0x57, 'e': 0x45, 'r': 0x52, 't': 0x54,
            'y': 0x59, 'u': 0x55, 'i': 0x49, 'o': 0x4F, 'p': 0x50,
            'a': 0x41, 's': 0x53, 'd': 0x44, 'f': 0x46, 'g': 0x47,
            'h': 0x48, 'j': 0x4A, 'k': 0x4B, 'l': 0x4C,
            'z': 0x5A, 'x': 0x58, 'c': 0x43, 'v': 0x56, 'b': 0x42,
            'n': 0x4E, 'm': 0x4D,
        }

    def press_key(self, key: str, duration: float = 0.05):
        """
        Press a key
        Args:
            key: Key to press (e.g., '1', 'q', 'w')
            duration: How long to hold the key in seconds
        """
        if sys.platform != "win32":
            print(f"[模拟按键] {key}")
            return

        key = key.lower()
        if key not in self.key_map:
            print(f"Unknown key: {key}")
            return

        vk_code = self.key_map[key]

        try:
            # Key down
            win32api.keybd_event(vk_code, 0, 0, 0)
            time.sleep(duration)
            # Key up
            win32api.keybd_event(vk_code, 0, win32con.KEYEVENTF_KEYUP, 0)
        except Exception as e:
            print(f"Error pressing key {key}: {e}")

    def press_key_with_modifier(self, modifier: str, key: str, duration: float = 0.05):
        """
        Press a key with modifier (Ctrl, Alt, Shift)
        Args:
            modifier: Modifier key ('ctrl', 'alt', 'shift')
            key: Key to press
            duration: How long to hold the keys
        """
        if sys.platform != "win32":
            print(f"[模拟按键] {modifier}+{key}")
            return

        modifier = modifier.lower()
        key = key.lower()

        modifier_codes = {
            'ctrl': 0x11,
            'alt': 0x12,
            'shift': 0x10
        }

        if modifier not in modifier_codes or key not in self.key_map:
            print(f"Unknown modifier or key: {modifier}, {key}")
            return

        mod_vk = modifier_codes[modifier]
        key_vk = self.key_map[key]

        try:
            # Modifier down
            win32api.keybd_event(mod_vk, 0, 0, 0)
            time.sleep(0.02)
            # Key down
            win32api.keybd_event(key_vk, 0, 0, 0)
            time.sleep(duration)
            # Key up
            win32api.keybd_event(key_vk, 0, win32con.KEYEVENTF_KEYUP, 0)
            time.sleep(0.02)
            # Modifier up
            win32api.keybd_event(mod_vk, 0, win32con.KEYEVENTF_KEYUP, 0)
        except Exception as e:
            print(f"Error pressing {modifier}+{key}: {e}")

    def cast_spell(self, key: str, gcd_check: bool = True):
        """
        Cast a spell by pressing the corresponding key
        Args:
            key: Key to press
            gcd_check: Whether to check global cooldown
        """
        self.press_key(key, 0.05)

    def use_item(self, slot: str):
        """
        Use an item in a specific slot
        Args:
            slot: Item slot (e.g., 'trinket1', 'trinket2', 'potion')
        """
        slot_keys = {
            'trinket1': '=',
            'trinket2': '-',
            'potion': '/'
        }

        if slot in slot_keys:
            self.press_key(slot_keys[slot], 0.1)
