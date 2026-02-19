"""
WoW Assist - Main Entry Point
"""
import sys
from ui.main_window import MainWindow


def main():
    app = MainWindow()
    sys.exit(app.run())


if __name__ == "__main__":
    main()
