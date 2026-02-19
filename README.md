# WoW Assist

魔兽世界自动输出辅助工具

## 项目结构

```
wow-assist/
├── backend/                    # Python 后端
│   ├── main.py                # 主程序入口
│   ├── ui/                    # PyQt6 界面
│   │   └── main_window.py
│   ├── core/                  # 核心逻辑
│   │   ├── state_reader.py    # 读取游戏状态
│   │   ├── key_simulator.py  # 按键模拟
│   │   └── rotation_engine.py # 循环引擎
│   ├── config/                # 配置
│   │   └── rotations.py      # 职业技能循环
│   └── requirements.txt
├── plugin/                    # 游戏内 Lua 插件
│   └── LokiAssist/
│       ├── LokiAssist.toc
│       ├── LokiAssist.lua
│       └── core.lua
├── .github/
│   └── workflows/
│       └── build.yml          # Git Actions 构建
└── README.md
```

## 开发

### 后端开发

```bash
cd backend
pip install -r requirements.txt
python main.py
```

### 构建 Windows exe

推送代码到 GitHub，Git Actions 会自动构建。

## 支持职业

- 死亡骑士 (DK)
- 猎人
- 战士
- 武僧
- 萨满
- 德鲁伊
