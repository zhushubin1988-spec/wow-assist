"""
Memory Reader - Reads game data directly from memory
WARNING: This may trigger anti-cheat systems
"""
import sys
import time

if sys.platform == "win32":
    import ctypes
    from ctypes import wintypes


# Windows API definitions
PROCESS_QUERY_INFORMATION = 0x0400
PROCESS_VM_READ = 0x0010


class MemoryReader:
    def __init__(self):
        self.process_handle = None
        self.base_address = None
        self.wow_window = None
        self.find_wow_process()

    def find_wow_process(self):
        """Find World of Warcraft process"""
        try:
            # Find WoW window
            self.wow_window = ctypes.windll.user32.FindWindowW(None, "World of Warcraft")
            if not self.wow_window:
                print("WoW window not found")
                return False

            # Get process ID
            pid = wintypes.DWORD()
            ctypes.windll.user32.GetWindowThreadProcessId(
                self.wow_window,
                ctypes.byref(pid)
            )

            if pid.value == 0:
                print("Failed to get process ID")
                return False

            # Open process
            self.process_handle = ctypes.windll.kernel32.OpenProcess(
                PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
                False,
                pid.value
            )

            if not self.process_handle:
                print("Failed to open process")
                return False

            print(f"Connected to WoW process: {pid.value}")
            return True

        except Exception as e:
            print(f"Error finding WoW: {e}")
            return False

    def read_memory(self, address, size=4):
        """Read memory at address"""
        if not self.process_handle:
            return None

        try:
            buffer = ctypes.create_string_buffer(size)
            bytes_read = ctypes.c_size_t()

            result = ctypes.windll.kernel32.ReadProcessMemory(
                self.process_handle,
                ctypes.c_void_p(address),
                buffer,
                size,
                ctypes.byref(bytes_read)
            )

            if result:
                return buffer.raw[:bytes_read.value]
            return None

        except Exception as e:
            return None

    def read_int(self, address):
        """Read integer from memory"""
        data = self.read_memory(address, 4)
        if data and len(data) == 4:
            return int.from_bytes(data, byteorder='little')
        return 0

    def read_float(self, address):
        """Read float from memory"""
        data = self.read_memory(address, 4)
        if data and len(data) == 4:
            import struct
            return struct.unpack('f', data)[0]
        return 0.0

    def read_string(self, address, max_length=256):
        """Read string from memory"""
        data = self.read_memory(address, max_length)
        if data:
            # Find null terminator
            null_pos = data.find(b'\x00')
            if null_pos > 0:
                return data[:null_pos].decode('utf-8', errors='ignore')
        return ""

    def get_pointer(self, base, offsets):
        """Follow pointer chain"""
        addr = base
        for offset in offsets:
            addr = self.read_int(addr + offset)
            if addr == 0:
                return 0
        return addr

    def get_player_health(self, player_ptr):
        """Get player health"""
        # Offset to health - varies by game version
        health = self.read_int(player_ptr + 0xF8)  # Example offset
        max_health = self.read_int(player_ptr + 0xFC)
        if max_health > 0:
            return int(health / max_health * 100), health, max_health
        return 100, health, max_health

    def get_player_power(self, player_ptr):
        """Get player power"""
        power = self.read_int(player_ptr + 0x104)  # Example offset
        max_power = self.read_int(player_ptr + 0x108)
        return power, max_power

    def get_combat_status(self, player_ptr):
        """Check if in combat"""
        # Combat flag offset - varies by version
        flags = self.read_int(player_ptr + 0x94)
        return (flags & 0x80000) != 0

    def get_target_info(self, target_ptr):
        """Get target information"""
        if target_ptr == 0:
            return "", 100, 0

        name = ""
        for i in range(12):
            char = self.read_int(target_ptr + 0x200 + i * 4)
            if char:
                name += chr(char)
        name = name.strip('\x00')

        health = self.read_int(target_ptr + 0xF8)
        max_health = self.read_int(target_ptr + 0xFC)
        health_pct = 0
        if max_health > 0:
            health_pct = int(health / max_health * 100)

        return name, health_pct, max_health

    def get_spell_cooldowns(self, spellbook_ptr):
        """Get spell cooldowns"""
        cooldowns = {}

        # This is simplified - real implementation needs specific offsets
        # Each spell has a cooldown entry at specific offsets

        return cooldowns

    def get_game_state(self):
        """
        Get complete game state from memory
        Note: Offsets need to be adjusted for specific game version
        """
        if not self.process_handle:
            return {
                "healthPercent": 100,
                "power": 0,
                "maxPower": 100,
                "inCombat": False,
                "targetName": "",
                "targetHealthPercent": 100,
                "spells": {}
            }

        # These offsets need to be updated for each game version
        # They're just placeholders

        try:
            # Get client connection (dynamic, changes on login)
            client_ptr = self.get_pointer(0x00DDF704, [0x78, 0x18C, 0x228])  # Example

            if client_ptr == 0:
                return {
                    "healthPercent": 100,
                    "power": 0,
                    "maxPower": 100,
                    "inCombat": False,
                    "targetName": "",
                    "targetHealthPercent": 100,
                    "spells": {}
                }

            # Player and target pointers
            player_ptr = self.read_int(client_ptr + 0xC98)  # Local player
            target_ptr = self.read_int(client_ptr + 0xCA0)  # Current target

            # Read player data
            health_pct, health, max_health = self.get_player_health(player_ptr)
            power, max_power = self.get_player_power(player_ptr)
            in_combat = self.get_combat_status(player_ptr)

            # Read target data
            target_name, target_hp, _ = self.get_target_info(target_ptr)

            return {
                "healthPercent": health_pct,
                "health": health,
                "maxHealth": max_health,
                "power": power,
                "maxPower": max_power,
                "inCombat": in_combat,
                "targetName": target_name,
                "targetHealthPercent": target_hp,
                "spells": {}
            }

        except Exception as e:
            print(f"Error reading game state: {e}")
            return {
                "healthPercent": 100,
                "power": 0,
                "maxPower": 100,
                "inCombat": False,
                "targetName": "",
                "targetHealthPercent": 100,
                "spells": {}
            }

    def close(self):
        """Close process handle"""
        if self.process_handle:
            ctypes.windll.kernel32.CloseHandle(self.process_handle)
            self.process_handle = None


# For testing without WoW running
class MockMemoryReader:
    """Mock memory reader for testing"""

    def __init__(self):
        print("Using mock memory reader (no WoW connected)")

    def get_game_state(self):
        return {
            "healthPercent": 85,
            "power": 50,
            "maxPower": 100,
            "inCombat": False,
            "targetName": "",
            "targetHealthPercent": 100,
            "spells": {}
        }

    def close(self):
        pass


def create_memory_reader():
    """Create appropriate memory reader based on platform"""
    if sys.platform == "win32":
        reader = MemoryReader()
        if reader.process_handle:
            return reader
        else:
            print("Failed to connect to WoW, using mock reader")
            return MockMemoryReader()
    else:
        return MockMemoryReader()
