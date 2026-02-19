"""
Advanced Screenshot Reader - Uses OpenCV for image recognition
"""
import time
import os
import sys
import re

if sys.platform == "win32":
    import mss
    import numpy as np
    import cv2


class AdvancedScreenshotReader:
    def __init__(self):
        self.sct = None
        self.monitor = None

        if sys.platform == "win32":
            try:
                self.sct = mss.mss()
                # Get primary monitor
                self.monitor = self.sct.monitors[1]
            except Exception as e:
                print(f"Failed to init mss: {e}")

    def capture_screen(self, region=None):
        """Capture screen or region"""
        if not self.sct:
            return None

        try:
            if region:
                screenshot = self.sct.grab(region)
            else:
                screenshot = self.sct.grab(self.monitor)

            # Convert to numpy array (BGRA to BGR)
            img = np.array(screenshot)
            img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
            return img
        except Exception as e:
            print(f"Screenshot error: {e}")
            return None

    def find_health_bar(self, image):
        """
        Find and read player health bar
        Returns: health percentage (0-100)
        """
        if image is None:
            return 100

        try:
            # Typical player health bar position - need to adjust for user's UI
            # Usually top-left of screen
            h, w = image.shape[:2]

            # Search in top-left area (player frame position)
            roi = image[50:150, 50:300]

            # Convert to HSV for color detection
            hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)

            # Health bar is typically green/red
            # Green range
            lower_green = np.array([35, 50, 50])
            upper_green = np.array([85, 255, 255])
            green_mask = cv2.inRange(hsv, lower_green, upper_green)

            # Red range (for low health)
            lower_red = np.array([0, 50, 50])
            upper_red = np.array([15, 255, 255])
            red_mask = cv2.inRange(hsv, lower_red, upper_red)

            # Combine masks
            health_mask = cv2.bitwise_or(green_mask, red_mask)

            # Find contours to locate the bar
            contours, _ = cv2.findContours(health_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            if contours:
                # Get the largest green/red area
                largest = max(contours, key=cv2.contourArea)
                x, y, cw, ch = cv2.boundingRect(largest)

                # Calculate percentage based on width
                if cw > 10:
                    return min(100, int(cw / 2))

            return 100
        except Exception as e:
            print(f"Health bar detection error: {e}")
            return 100

    def find_power_bar(self, image):
        """
        Find and read player power bar (energy/mana/rage)
        Returns: (current_power, max_power)
        """
        if image is None:
            return 0, 100

        try:
            h, w = image.shape[:2]

            # Power bar is usually below health bar
            roi = image[140:180, 50:300]

            # Convert to HSV
            hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)

            # Blue for mana, yellow for energy, red for rage
            # Blue (mana)
            lower_blue = np.array([100, 50, 50])
            upper_blue = np.array([130, 255, 255])
            blue_mask = cv2.inRange(hsv, lower_blue, upper_blue)

            # Yellow (energy)
            lower_yellow = np.array([20, 50, 50])
            upper_yellow = np.array([30, 255, 255])
            yellow_mask = cv2.inRange(hsv, lower_yellow, upper_yellow)

            # Red (rage)
            lower_red = np.array([0, 50, 50])
            upper_red = np.array([15, 255, 255])
            red_mask = cv2.inRange(hsv, lower_red, upper_red)

            # Combine
            power_mask = cv2.bitwise_or(blue_mask, yellow_mask)
            power_mask = cv2.bitwise_or(power_mask, red_mask)

            contours, _ = cv2.findContours(power_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            if contours:
                largest = max(contours, key=cv2.contourArea)
                x, y, cw, ch = cv2.boundingRect(largest)

                # Estimate power (simplified)
                if cw > 10:
                    power = int(cw / 2)
                    return power, 100

            return 0, 100
        except Exception as e:
            print(f"Power bar detection error: {e}")
            return 0, 100

    def detect_combat_state(self, image):
        """
        Detect if player is in combat
        Returns: True/False
        """
        if image is None:
            return False

        try:
            # Combat indicator is typically near player frame
            # Look for specific UI elements or colors

            h, w = image.shape[:2]
            roi = image[0:200, 0:400]

            # Look for red/orange tint around frame (combat indicator)
            hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)

            # Orange-red (combat)
            lower_combat = np.array([0, 50, 50])
            upper_combat = np.array([20, 255, 255])
            combat_mask = cv2.inRange(hsv, lower_combat, upper_combat)

            # Count colored pixels
            colored_pixels = cv2.countNonZero(combat_mask)

            # If significant orange/red area, likely in combat
            return colored_pixels > 500
        except:
            return False

    def detect_skill_cooldowns(self, image):
        """
        Detect skill cooldowns by analyzing action bar icons
        Returns: dict of {skill_name: cooldown_remaining}
        """
        if image is None:
            return {}

        cooldowns = {}

        try:
            # Capture action bar area (bottom of screen)
            h, w = image.shape[:2]
            action_bar = image[h-200:h-50, w//4:w*3//4]

            # Convert to grayscale
            gray = cv2.cvtColor(action_bar, cv2.COLOR_BGR2GRAY)

            # Skills on cooldown appear darker/grayed out
            # Skills ready are brighter

            # Calculate average brightness of each skill slot (assuming ~10 skills)
            skill_width = gray.shape[1] // 10

            for i in range(10):
                slot = gray[:, i*skill_width:(i+1)*skill_width]
                avg_brightness = np.mean(slot)

                # Bright = ready (cooldown 0), Dark = on cooldown
                # This is simplified - real implementation would use template matching

                if avg_brightness > 100:
                    cooldowns[f"skill_{i}"] = 0  # Ready
                else:
                    cooldowns[f"skill_{i}"] = 1  # On cooldown (simplified)

        except Exception as e:
            print(f"Cooldown detection error: {e}")

        return cooldowns

    def get_game_state(self):
        """
        Main function to get complete game state
        """
        state = {
            "healthPercent": 100,
            "power": 0,
            "maxPower": 100,
            "inCombat": False,
            "targetName": "",
            "targetHealthPercent": 100,
            "spells": {}
        }

        # Capture full screen
        screen = self.capture_screen()
        if screen is None:
            return state

        # Get health
        state["healthPercent"] = self.find_health_bar(screen)

        # Get power
        power, maxPower = self.find_power_bar(screen)
        state["power"] = power
        state["maxPower"] = maxPower

        # Get combat state
        state["inCombat"] = self.detect_combat_state(screen)

        # Get skill cooldowns
        state["spells"] = self.detect_skill_cooldowns(screen)

        return state

    def close(self):
        """Close screenshot capture"""
        if self.sct:
            self.sct.close()
