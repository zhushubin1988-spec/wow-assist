"""
Main Window UI - OCR-based version with keybind configuration
"""
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
                             QLabel, QPushButton, QComboBox, QCheckBox, QGroupBox,
                             QDialog, QGridLayout, QLineEdit, QTabWidget, QTextEdit)
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QFont
import sys

from core.screenshot_reader import ScreenshotReader
from core.key_simulator import KeySimulator
from core.rotation_engine import RotationEngine


# Default spell keybinds for each class
DEFAULT_KEYBINDS = {
    "death_knight": {
        "暗影打击": "1",
        "传染": "2",
        "心脏打击": "3",
        "灵界打击": "4",
        "符文打击": "5",
        "枯萎凋零": "q",
        "血液沸腾": "e",
    },
    "hunter": {
        "杀戮命令": "1",
        "奥术射击": "2",
        "多重射击": "3",
        "稳固射击": "4",
        "钉刺": "5",
        "狂野怒火": "q",
        "误导": "e",
    },
    "warrior": {
        "致死打击": "1",
        "巨人打击": "2",
        "压制": "3",
        "顺劈斩": "4",
        "英勇打击": "5",
        "撕裂": "q",
        "冲锋": "e",
    },
    "monk": {
        "猛虎掌": "1",
        "幻灭踢": "2",
        "碎玉闪电": "3",
        "连击": "4",
        "腿击": "q",
        "旭日东升踢": "e",
    },
    "shaman": {
        "闪电箭": "1",
        "大地震击": "2",
        "风暴打击": "3",
        "烈焰震击": "4",
        "元素冲击": "q",
        "冰霜震击": "e",
    },
    "druid": {
        "凶猛撕咬": "1",
        "斜掠": "2",
        "割裂": "3",
        "爪击": "4",
        "裂伤": "5",
        "狂暴": "q",
    },
}


class MainWindow:
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.window = QMainWindow()
        self.window.setWindowTitle("WoW Assist - 魔兽世界自动输出辅助")
        self.window.setGeometry(100, 100, 600, 700)

        # Core components
        self.screenshot_reader = ScreenshotReader()
        self.key_simulator = KeySimulator()
        self.rotation_engine = RotationEngine(self.screenshot_reader, self.key_simulator)

        # Keybinds
        self.current_class_keybinds = {}

        self.is_running = False
        self.setup_ui()

        # Update timer
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_loop)
        self.timer.start(100)

    def setup_ui(self):
        central_widget = QWidget()
        self.window.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)

        # Title
        title = QLabel("WoW Assist - OCR版本")
        title.setFont(QFont("Arial", 16, QFont.Weight.Bold))
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title)

        # Status
        self.status_label = QLabel("状态: 未运行")
        self.status_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.status_label)

        # Tabs
        tabs = QTabWidget()

        # Tab 1: Main
        main_tab = QWidget()
        main_layout = QVBoxLayout()

        # Info
        info_group = QGroupBox("游戏状态")
        info_layout = QVBoxLayout()
        self.health_label = QLabel("生命值: 0%")
        self.energy_label = QLabel("能量: 0")
        self.in_combat_label = QLabel("战斗状态: 否")
        info_layout.addWidget(self.health_label)
        info_layout.addWidget(self.energy_label)
        info_layout.addWidget(self.in_combat_label)
        info_group.setLayout(info_layout)
        main_layout.addWidget(info_group)

        # Settings
        settings_group = QGroupBox("设置")
        settings_layout = QVBoxLayout()

        class_layout = QHBoxLayout()
        class_layout.addWidget(QLabel("职业:"))
        self.class_combo = QComboBox()
        self.class_combo.addItems(["死亡骑士", "猎人", "战士", "武僧", "萨满", "德鲁伊"])
        self.class_combo.currentTextChanged.connect(self.on_class_changed)
        class_layout.addWidget(self.class_combo)
        settings_layout.addLayout(class_layout)

        self.combat_protect_check = QCheckBox("战斗保护")
        self.combat_protect_check.setChecked(True)
        settings_layout.addWidget(self.combat_protect_check)

        self.trinket_check = QCheckBox("饰品自动使用")
        settings_layout.addWidget(self.trinket_check)

        self.potion_check = QCheckBox("药水自动使用")
        settings_layout.addWidget(self.potion_check)

        settings_group.setLayout(settings_layout)
        main_layout.addWidget(settings_group)

        # Buttons
        button_layout = QHBoxLayout()
        self.start_button = QPushButton("开始")
        self.start_button.clicked.connect(self.start_rotation)
        button_layout.addWidget(self.start_button)

        self.stop_button = QPushButton("停止")
        self.stop_button.clicked.connect(self.stop_rotation)
        self.stop_button.setEnabled(False)
        button_layout.addWidget(self.stop_button)

        self.config_button = QPushButton("配置按键")
        self.config_button.clicked.connect(self.open_keybind_config)
        button_layout.addWidget(self.config_button)

        main_layout.addLayout(button_layout)
        main_tab.setLayout(main_layout)
        tabs.addTab(main_tab, "主界面")

        # Tab 2: Keybinds
        keybind_tab = QWidget()
        keybind_layout = QVBoxLayout()

        self.keybind_text = QTextEdit()
        self.keybind_text.setReadOnly(True)
        self.keybind_text.setFont(QFont("Courier", 10))
        keybind_layout.addWidget(QLabel("当前按键配置:"))
        keybind_layout.addWidget(self.keybind_text)

        self.refresh_keybinds_button = QPushButton("刷新显示")
        self.refresh_keybinds_button.clicked.connect(self.refresh_keybind_display)
        keybind_layout.addWidget(self.refresh_keybinds_button)

        keybind_tab.setLayout(keybind_layout)
        tabs.addTab(keybind_tab, "按键配置")

        layout.addWidget(tabs)

        # Log
        self.log_label = QLabel("日志: 就绪")
        self.log_label.setWordWrap(True)
        layout.addWidget(self.log_label)

        # Initialize keybinds
        self.on_class_changed("死亡骑士")

    def on_class_changed(self, class_name):
        """When class is changed, load default keybinds"""
        class_map = {
            "死亡骑士": "death_knight",
            "猎人": "hunter",
            "战士": "warrior",
            "武僧": "monk",
            "萨满": "shaman",
            "德鲁伊": "druid"
        }
        key = class_map.get(class_name, "death_knight")
        self.current_class_keybinds = DEFAULT_KEYBINDS.get(key, {}).copy()

        # Update rotation engine
        self.rotation_engine.set_keybinds(self.current_class_keybinds)

        self.refresh_keybind_display()

    def refresh_keybind_display(self):
        """Display current keybinds"""
        text = "技能 -> 按键\n"
        text += "=" * 30 + "\n"
        for spell, key in self.current_class_keybinds.items():
            text += f"{spell}: {key}\n"
        self.keybind_text.setText(text)

    def open_keybind_config(self):
        """Open keybind configuration dialog"""
        dialog = QDialog(self.window)
        dialog.setWindowTitle("配置按键绑定")
        dialog.setGeometry(200, 200, 400, 400)

        layout = QGridLayout()
        layout.addWidget(QLabel("技能"), 0, 0)
        layout.addWidget(QLabel("按键"), 0, 1)

        row = 1
        self.keybind_inputs = {}

        for spell, key in self.current_class_keybinds.items():
            layout.addWidget(QLabel(spell), row, 0)
            input_field = QLineEdit(key)
            input_field.setMaxLength(3)
            input_field.textChanged.connect(lambda text, s=spell: self.update_keybind(s, text))
            layout.addWidget(input_field, row, 1)
            self.keybind_inputs[spell] = input_field
            row += 1

        close_btn = QPushButton("关闭")
        close_btn.clicked.connect(dialog.close)
        layout.addWidget(close_btn, row, 0, 1, 2)

        dialog.setLayout(layout)
        dialog.exec()

    def update_keybind(self, spell, key):
        """Update a single keybind"""
        key = key.upper()
        self.current_class_keybinds[spell] = key
        self.rotation_engine.set_keybinds(self.current_class_keybinds)
        self.refresh_keybind_display()

    def start_rotation(self):
        selected_class = self.class_combo.currentText()
        self.rotation_engine.set_class(selected_class)
        self.rotation_engine.set_keybinds(self.current_class_keybinds)
        self.rotation_engine.set_options(
            combat_protect=self.combat_protect_check.isChecked(),
            auto_trinket=self.trinket_check.isChecked(),
            auto_potion=self.potion_check.isChecked(),
        )
        self.rotation_engine.start()
        self.is_running = True
        self.start_button.setEnabled(False)
        self.stop_button.setEnabled(True)
        self.status_label.setText("状态: 运行中")

    def stop_rotation(self):
        self.rotation_engine.stop()
        self.is_running = False
        self.start_button.setEnabled(True)
        self.stop_button.setEnabled(False)
        self.status_label.setText("状态: 已停止")

    def update_loop(self):
        state = self.screenshot_reader.get_game_state()

        self.health_label.setText(f"生命值: {state.get('healthPercent', 0)}%")
        self.energy_label.setText(f"能量: {state.get('power', 0)}/{state.get('maxPower', 100)}")
        self.in_combat_label.setText(f"战斗状态: {'是' if state.get('inCombat', False) else '否'}")

        if self.is_running:
            self.rotation_engine.update()

    def log(self, message):
        self.log_label.setText(f"日志: {message}")

    def run(self):
        self.window.show()
        return self.app.exec()


if __name__ == "__main__":
    main = MainWindow()
    main.run()
