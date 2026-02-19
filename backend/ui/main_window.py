"""
Main Window UI - OCR-based version
"""
from PyQt6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout
from PyQt6.QtWidgets import QLabel, QPushButton, QComboBox, QCheckBox, QGroupBox
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QFont
import sys

from core.screenshot_reader import ScreenshotReader
from core.key_simulator import KeySimulator
from core.rotation_engine import RotationEngine


class MainWindow:
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.window = QMainWindow()
        self.window.setWindowTitle("WoW Assist - 魔兽世界自动输出辅助")
        self.window.setGeometry(100, 100, 500, 600)

        # Core components - using screenshot instead of chat log
        self.screenshot_reader = ScreenshotReader()
        self.key_simulator = KeySimulator()
        self.rotation_engine = RotationEngine(self.screenshot_reader, self.key_simulator)

        self.is_running = False
        self.setup_ui()

        # Update timer - check every 100ms
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

        # Info
        info_group = QGroupBox("游戏状态")
        info_layout = QVBoxLayout()

        self.player_name_label = QLabel("等待截图...")
        self.class_label = QLabel("职业: 未选择")
        self.health_label = QLabel("生命值: 0%")
        self.energy_label = QLabel("能量: 0")
        self.in_combat_label = QLabel("战斗状态: 否")

        info_layout.addWidget(self.player_name_label)
        info_layout.addWidget(self.class_label)
        info_layout.addWidget(self.health_label)
        info_layout.addWidget(self.energy_label)
        info_layout.addWidget(self.in_combat_label)
        info_group.setLayout(info_layout)
        layout.addWidget(info_group)

        # Settings
        settings_group = QGroupBox("设置")
        settings_layout = QVBoxLayout()

        # Class selection
        class_layout = QHBoxLayout()
        class_layout.addWidget(QLabel("职业:"))
        self.class_combo = QComboBox()
        self.class_combo.addItems(["死亡骑士", "猎人", "战士", "武僧", "萨满", "德鲁伊"])
        class_layout.addWidget(self.class_combo)
        settings_layout.addLayout(class_layout)

        # Options
        self.combat_protect_check = QCheckBox("战斗保护 (仅在战斗中使用技能)")
        self.combat_protect_check.setChecked(True)
        settings_layout.addWidget(self.combat_protect_check)

        self.trinket_check = QCheckBox("饰品自动使用")
        self.trinket_check.setChecked(False)
        settings_layout.addWidget(self.trinket_check)

        self.potion_check = QCheckBox("药水自动使用")
        self.potion_check.setChecked(False)
        settings_layout.addWidget(self.potion_check)

        self.follow_check = QCheckBox("自动跟随")
        self.follow_check.setChecked(False)
        settings_layout.addWidget(self.follow_check)

        self.interrupt_check = QCheckBox("手动打断")
        self.interrupt_check.setChecked(False)
        settings_layout.addWidget(self.interrupt_check)

        settings_group.setLayout(settings_layout)
        layout.addWidget(settings_group)

        # Buttons
        button_layout = QHBoxLayout()

        self.start_button = QPushButton("开始")
        self.start_button.clicked.connect(self.start_rotation)
        button_layout.addWidget(self.start_button)

        self.stop_button = QPushButton("停止")
        self.stop_button.clicked.connect(self.stop_rotation)
        self.stop_button.setEnabled(False)
        button_layout.addWidget(self.stop_button)

        layout.addLayout(button_layout)

        # Log
        self.log_label = QLabel("日志: 就绪 (使用OCR截屏方案)")
        self.log_label.setWordWrap(True)
        layout.addWidget(self.log_label)

    def start_rotation(self):
        selected_class = self.class_combo.currentText()
        self.rotation_engine.set_class(selected_class)
        self.rotation_engine.set_options(
            combat_protect=self.combat_protect_check.isChecked(),
            auto_trinket=self.trinket_check.isChecked(),
            auto_potion=self.potion_check.isChecked(),
            auto_follow=self.follow_check.isChecked(),
            manual_interrupt=self.interrupt_check.isChecked()
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
        # Update game state from screenshot
        state = self.screenshot_reader.get_game_state()

        # Update UI
        self.health_label.setText(f"生命值: {state.get('healthPercent', 0)}%")
        self.energy_label.setText(f"能量: {state.get('power', 0)}/{state.get('maxPower', 100)}")
        self.in_combat_label.setText(f"战斗状态: {'是' if state.get('inCombat', False) else '否'}")

        # Update rotation if running
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
