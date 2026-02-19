"""
Screenshot Reader - Captures game screen and extracts data via OCR
Uses: mss for screenshot, pytesseract for OCR
"""
import time
import os
import sys

# Only import on Windows
if sys.platform == "win32":
    import mss
    import numpy as np
    try:
        import pytesseract
    except ImportError:
        pytesseract = None


class ScreenshotReader:
    def __init__(self):
        self.sct = None
        if sys.platform == "win32":
            try:
                self.sct = mss.mss()
            except Exception as e:
                print(f"Failed to init mss: {e}")

    def capture_screen(self, region=None):
        """
        Capture screen or region
        region: {"top": y, "left": x, "width": w, "height": h}
        """
        if not self.sct:
            return None

        try:
            if region:
                screenshot = self.sct.grab(region)
            else:
                # Capture primary monitor
                screenshot = self.sct.grab(self.sct.monitors[1])

            # Convert to numpy array for OCR
            img = np.array(screenshot)
            return img
        except Exception as e:
            print(f"Screenshot error: {e}")
            return None

    def capture_player_info(self):
        """
        Capture player info region (top-left of screen)
        Returns image for OCR processing
        """
        # Typical player frame position - may need adjustment
        # This captures the player unit frame area
        region = {
            "top": 100,
            "left": 50,
            "width": 250,
            "height": 100
        }
        return self.capture_screen(region)

    def capture_target_info(self):
        """
        Capture target info region
        """
        region = {
            "top": 100,
            "left": 400,
            "width": 250,
            "height": 100
        }
        return self.capture_screen(region)

    def capture_action_bars(self):
        """
        Capture action bars (bottom of screen)
        """
        region = {
            "top": 700,
            "left": 300,
            "width": 800,
            "height": 200
        }
        return self.capture_screen(region)

    def extract_text(self, image):
        """
        Extract text from image using OCR
        """
        if pytesseract is None:
            print("pytesseract not installed")
            return ""

        try:
            text = pytesseract.image_to_string(image)
            return text
        except Exception as e:
            print(f"OCR error: {e}")
            return ""

    def parse_health_from_text(self, text):
        """
        Parse health percentage from OCR text
        Example: "85%" or "85 / 100"
        """
        import re
        # Look for patterns like "85%" or "85/100"
        match = re.search(r'(\d+)\s*%', text)
        if match:
            return int(match.group(1))

        match = re.search(r'(\d+)\s*/\s*(\d+)', text)
        if match:
            current = int(match.group(1))
            max_val = int(match.group(2))
            if max_val > 0:
                return int(current / max_val * 100)

        return None

    def parse_power_from_text(self, text):
        """
        Parse power/energy from OCR text
        """
        import re
        match = re.search(r'(\d+)\s*/\s*(\d+)', text)
        if match:
            return int(match.group(1)), int(match.group(2))
        return None, None

    def get_game_state(self):
        """
        Main function to get complete game state from screenshots
        """
        state = {
            "healthPercent": 100,
            "power": 0,
            "maxPower": 100,
            "inCombat": False,
            "targetName": "",
            "targetHealthPercent": 100,
            "spells": {}  # Spell cooldowns
        }

        # Capture player info
        player_img = self.capture_player_info()
        if player_img:
            text = self.extract_text(player_img)
            hp = self.parse_health_from_text(text)
            if hp:
                state["healthPercent"] = hp

        # Capture target info
        target_img = self.capture_target_info()
        if target_img:
            text = self.extract_text(target_img)
            hp = self.parse_health_from_text(text)
            if hp:
                state["targetHealthPercent"] = hp

        return state

    def close(self):
        """Close screenshot capture"""
        if self.sct:
            self.sct.close()


# Alternative: Read from memory (more advanced, may be blocked)
class MemoryReader:
    """
    Read game data directly from memory
    WARNING: This may trigger anti-cheat systems
    """

    def __init__(self):
        self.process_handle = None

    def find_wow_process(self):
        """Find WoW process"""
        if sys.platform != "win32":
            return None

        try:
            import ctypes
            from ctypes import wintypes

            PROCESS_QUERY_INFORMATION = 0x0400
            PROCESS_VM_READ = 0x0010

            # Enum processes
            EnumProcesses = ctypes.windll.psapi.EnumProcesses
            EnumProcesses.restype = ctypes.c_bool

            # This is a simplified version - full implementation would need
            # to find "World of Warcraft.exe" process
            return None
        except Exception as e:
            print(f"Error finding process: {e}")
            return None
