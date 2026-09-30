# Road vs Cars

[English](README.md) | 简体中文

Road vs Cars 是一个基于 Godot 4.7 的 3D 驾驶原型。道路会在模拟运行期间持续生成：
道路构建相机负责定义路线，`DynamicRoad` 创建对应的网格与碰撞路段，AI 车队沿生成的
道路路径行驶。

## 功能

- 运行时动态生成道路，支持自适应路段长度、碰撞几何、路径采样和旧路段自动清理。
- 程序化道路 Shader，包括沥青、9 米实线加 6 米间隔的中央虚线、路肩和草地。
- 20 辆车组成的交错发车阵列，每辆车具有不同的颜色、悬挂参数、驾驶参数和随机路径目标。
- Pure Pursuit 转向、弯道感知速度规划、PI 速度控制、刹车和大角度航向恢复。
- 车辆间碰撞、驶离道路检测，以及脱离动态道路后的自动清理。
- 道路、追踪和观察三种相机模式，以及实时速度、控制量和车队状态界面。
- 所有车辆共享的程序化轮胎和轮毂材质。

## 环境要求

- [Godot Engine 4.7.x](https://godotengine.org/)
- Forward Plus 渲染器

仓库的 `addons/` 已包含 GdUnit4 和 Godot AI 编辑器插件，运行项目本身不需要额外安装
依赖。

## 运行

使用 Godot 打开仓库并运行主场景，或者在终端中执行：

```sh
godot --path .
```

macOS 标准 Godot 应用可以使用：

```sh
'/Applications/Godot.app/Contents/MacOS/Godot' --path .
```

主场景为 `res://Scenes/Levels/level.tscn`，默认视口尺寸为 1600 x 900。

## 操作

| 输入 | 功能 |
| --- | --- |
| 鼠标位置 | 控制道路构建相机的转向和俯仰 |
| `Space` | 临时降低道路构建相机速度 |
| `Left` / `Right` | 观察上一辆或下一辆仍在运行的车辆 |
| 界面中的 `Road` / `Chase` / `Observer` 按钮 | 切换相机模式 |
| `F` | 切换全屏 |
| `Esc` | 启用鼠标捕获时切换捕获状态 |
| `W` / `S` | 手动车辆油门和倒车 |
| `A` / `D` | 手动车辆转向 |
| `Space` | 手动车辆刹车 |

车辆默认使用 AI 控制。只有启用 `BasicVehicle.manual_control` 后，`W`、`A`、`S`、`D`
和手动刹车操作才会控制车辆。

## 工作原理

1. `RoadBuilderCamera` 在世界中持续前进，并根据鼠标位置确定道路方向。
2. `DynamicRoad` 采样相机变换，生成道路网格、碰撞体、连续 UV 和路径数据。
3. 道路 Shader 根据横向位置和累计路径距离绘制沥青、路肩、草地、表面变化和中央虚线。
4. `VehicleFleet` 创建不同的车辆配置，并分配限制在道路范围内的随机横向和纵向目标。
5. `BasicAI` 将每辆车投影到道路采样路径上，计算转向、油门和刹车指令。
6. `BasicVehicle` 通过 Godot 车辆物理系统执行指令，并向界面发送遥测数据。

道路材质仅影响视觉效果：草地、路肩和沥青共用同一块连续的道路碰撞表面。

## 项目结构

```text
Scenes/
  Entities/          车辆场景、物理、AI 和车轮材质
  Levels/            主关卡、道路生成器、相机、车队和道路 Shader
  Temp/              运行时驾驶界面
Scripts/Driving/     道路路径和车辆控制计算
Graphics/            模型与纹理源资源
tests/               GdUnit4 驾驶和界面测试
docs/                功能规格、计划和检查清单
```

`Scenes/Levels/road_meterial.tres` 的文件名拼写会被保留，因为现有场景通过该路径引用它。

## 测试

运行全部 GdUnit4 测试：

```sh
./addons/gdUnit4/runtest.sh \
  --godot_binary /path/to/godot \
  --headless --ignoreHeadlessMode \
  --add tests
```

执行无头项目导入和脚本、场景加载检查：

```sh
godot --headless --path . --editor --quit
```

## 导出

仓库包含 Windows Desktop x86_64 导出预设：

```sh
godot --headless --path . --export-release RoadVSCars
```

配置的输出文件为 `Road vs Cars.exe`。
