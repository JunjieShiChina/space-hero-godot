# Unity 素材使用场景参考

用途：辅助把 `/data/space-hero/Space-Hero` 迁移到 `/data/space-hero/space-hero-godot`。

## 生成方式

- 扫描 Unity `.meta` 文件，建立 GUID 到素材路径的映射。
- 扫描 `.unity`、`.prefab`、`.asset`、`.controller`、`.anim`、`.mat`、`.shadergraph` 等文本/YAML 文件中的 `guid:` 引用。
- “场景使用”是递归依赖：如果场景引用 Prefab，而 Prefab 引用脚本/精灵/音频，这些素材也会归到该场景。
- 运行时字符串加载、代码动态查找、编辑器工具生成的资源无法仅靠 YAML 证明，文档会按文件名或脚本职责标记为候选。
- 第三方包单独汇总，避免 JMO/Joystick/TMP 的大量资源干扰核心迁移清单。

## 项目素材盘点

| 分组 | 文件数 | 迁移备注 |
|---|---:|---|
| `JMO Assets` | 723 | 第三方 VFX 包，优先按需替换，不建议整体迁移 |
| `Sprite` | 117 | 核心游戏精灵、UI 图集、动画图集 |
| `Root C# scripts` | 61 | 根目录核心玩法脚本 |
| `Joystick Pack` | 43 | 第三方移动摇杆包，按移动端需求重建 |
| `Audio` | 36 | 核心游戏音频目录 |
| `TextMesh Pro` | 32 | Unity TMP 包，Godot 中用 Font/Theme/Label 替代 |
| `Excluded` | 9 | 排除/示例/编辑器辅助资源 |
| `Scenes` | 7 | 7 个主 Unity 场景 |
| `SerializableDictionary` | 7 | 序列化字典辅助 |
| `Font` | 4 | 字体与字体数据 |
| `Laser` | 4 | 激光材质/Shader 相关 |
| `Settings` | 4 | Unity 项目/渲染设置 |
| `Shield` | 4 | 护盾材质/Shader 相关 |
| `Root Unity assets` | 1 |  |
| `Root scene files` | 1 |  |

核心迁移数量：

- 核心音频文件：37（其中 `36` 个在 `Assets/Audio`，另有 `Assets/Sprite/arrow.mp3`）
- `Assets/Sprite` 下核心精灵/图片文件：89
- 核心 C# 脚本：67
- 核心 Prefab：0（核心玩法对象主要直接序列化在场景中，不是独立 Prefab）
- 核心动画/Controller：25
- 核心材质/Shader：8

## 场景依赖总览

### GameOver.unity

- 直接引用：36；递归依赖：36
- 脚本：`Assets/Asteroies.cs`; `Assets/BackgroundController.cs`; `Assets/Blink.cs`; `Assets/CleanupOutOfBounds.cs`; `Assets/ColorGradient.cs`; `Assets/DimensionsChangeController.cs`; `Assets/MobileSystemController.cs`; `Assets/NewGameButtonFunc.cs`; `Assets/OrbitAround.cs`; `Assets/QuitGameButtonFunc.cs`; `Assets/ShakeController.cs`; `Assets/SystemController.cs`
- 精灵/图片：`Assets/Sprite/Asteroids 01.png`; `Assets/Sprite/Asteroids 02.png`; `Assets/Sprite/Asteroids 03.png`; `Assets/Sprite/Asteroids 04.png`; `Assets/Sprite/Asteroids 05.png`; `Assets/Sprite/Asteroids 06.png`; `Assets/Sprite/Asteroids 07.png`; `Assets/Sprite/Asteroids 08.png`; `Assets/Sprite/Asteroids 09.png`; `Assets/Sprite/Asteroids 10.png`; `Assets/Sprite/Asteroids 11.png`; `Assets/Sprite/Asteroids 12.png`; `Assets/Sprite/Asteroids 13.png`; `Assets/Sprite/Asteroids 14.png`; `Assets/Sprite/Asteroids 15.png`; `Assets/Sprite/Asteroids 16.png`; `Assets/Sprite/Spaceship_Enemy - SingleShot.png`; `Assets/Sprite/Spaceship_Protagonist - P1.png`; ...(+3)
- 音频：`Assets/Audio/gameover.mp3`; `Assets/Audio/gamestart.wav`; `Assets/Audio/select.wav`
- Prefab：-
- 动画/Controller：-

### stage0.unity

- 直接引用：40；递归依赖：40
- 脚本：`Assets/Asteroies.cs`; `Assets/BackgroundController.cs`; `Assets/Blink.cs`; `Assets/CleanupOutOfBounds.cs`; `Assets/ColorGradient.cs`; `Assets/Data.cs`; `Assets/DimensionsChangeController.cs`; `Assets/InitFrameScript.cs`; `Assets/MobileSystemController.cs`; `Assets/NewGameButtonFunc.cs`; `Assets/OrbitAround.cs`; `Assets/PlayMusic.cs`; `Assets/QuitGameButtonFunc.cs`; `Assets/ShakeController.cs`; `Assets/SystemController.cs`
- 精灵/图片：`Assets/Sprite/Asteroids 01.png`; `Assets/Sprite/Asteroids 02.png`; `Assets/Sprite/Asteroids 03.png`; `Assets/Sprite/Asteroids 04.png`; `Assets/Sprite/Asteroids 05.png`; `Assets/Sprite/Asteroids 06.png`; `Assets/Sprite/Asteroids 07.png`; `Assets/Sprite/Asteroids 08.png`; `Assets/Sprite/Asteroids 09.png`; `Assets/Sprite/Asteroids 10.png`; `Assets/Sprite/Asteroids 11.png`; `Assets/Sprite/Asteroids 12.png`; `Assets/Sprite/Asteroids 13.png`; `Assets/Sprite/Asteroids 14.png`; `Assets/Sprite/Asteroids 15.png`; `Assets/Sprite/Asteroids 16.png`; `Assets/Sprite/Background_01.png`; `Assets/Sprite/Spaceship_Enemy - SingleShot.png`; ...(+4)
- 音频：`Assets/Audio/gamestart.wav`; `Assets/Audio/select.wav`; `Assets/Audio/stagebg.mp3`
- Prefab：-
- 动画/Controller：-

### stage1.unity

- 直接引用：127；递归依赖：163
- 脚本：`Assets/AbstractEnemy.cs`; `Assets/Asteroies.cs`; `Assets/AutoRotate.cs`; `Assets/BOSSController.cs`; `Assets/BackgroundController.cs`; `Assets/Blink.cs`; `Assets/BloodController.cs`; `Assets/BossExplosion.cs`; `Assets/Bullet.cs`; `Assets/BulletManager.cs`; `Assets/BullletTypePic.cs`; `Assets/CleanupOutOfBounds.cs`; `Assets/Coin.cs`; `Assets/ContinueButtonFuc.cs`; `Assets/DimensionsChangeController.cs`; `Assets/EnemyAI1.cs`; `Assets/EnemyPlaneManager.cs`; `Assets/FollowBullet.cs`; ...(+27)
- 精灵/图片：`Assets/Sprite/5HP Bar - 0.png`; `Assets/Sprite/5HP Bar - 1.png`; `Assets/Sprite/5HP Bar - 2.png`; `Assets/Sprite/5HP Bar - 3.png`; `Assets/Sprite/5HP Bar - 4.png`; `Assets/Sprite/5HP Bar - 5.png`; `Assets/Sprite/All_Fire_Bullet_Pixel_16x16_00.png`; `Assets/Sprite/Asteroids 01.png`; `Assets/Sprite/Asteroids 02.png`; `Assets/Sprite/Asteroids 03.png`; `Assets/Sprite/Asteroids 04.png`; `Assets/Sprite/Asteroids 05.png`; `Assets/Sprite/Asteroids 06.png`; `Assets/Sprite/Asteroids 07.png`; `Assets/Sprite/Asteroids 08.png`; `Assets/Sprite/Asteroids 09.png`; `Assets/Sprite/Asteroids 10.png`; `Assets/Sprite/Asteroids 11.png`; ...(+27)
- 音频：`Assets/Audio/bgsound.mp3`; `Assets/Audio/biu.wav`; `Assets/Audio/bossfight.mp3`; `Assets/Audio/bulletfire.wav`; `Assets/Audio/bulletyue.wav`; `Assets/Audio/buqiang.mp3`; `Assets/Audio/explosion.wav`; `Assets/Audio/failed.wav`; `Assets/Audio/gamestart.wav`; `Assets/Audio/getcoin.wav`; `Assets/Audio/hit.wav`; `Assets/Audio/hurt.wav`; `Assets/Audio/jian.wav`; `Assets/Audio/laser.wav`; `Assets/Audio/missile.wav`; `Assets/Audio/missileboom.wav`; `Assets/Audio/passstage.wav`; `Assets/Audio/pickup.wav`; ...(+4)
- Prefab：-
- 动画/Controller：`Assets/Sprite/Boom.controller`; `Assets/Sprite/BoomAnimation.anim`; `Assets/Sprite/BulletFire.anim`; `Assets/Sprite/BulletFire.controller`; `Assets/Sprite/BulletMissile 1.controller`; `Assets/Sprite/BulletYue.anim`; `Assets/Sprite/BulletYue.controller`; `Assets/Sprite/Diamond.controller`; `Assets/Sprite/MissileAnimation.anim`; `Assets/Sprite/NewCoin1.controller`; `Assets/Sprite/NewCoin2.controller`; `Assets/Sprite/NewCoin3.controller`; `Assets/Sprite/diamond.anim`; `Assets/Sprite/goid.anim`; `Assets/Sprite/gold.controller`; `Assets/Sprite/newcoin1.anim`; `Assets/Sprite/newcoin2.anim`; `Assets/Sprite/newcoin3.anim`
- 材质/Shader：`Assets/Laser/LaserMaterial.mat`; `Assets/Laser/LaserParticle.mat`; `Assets/Laser/LaserShader.shadergraph`; `Assets/Shield/ShieldM.mat`; `Assets/Shield/ShieldUnlitGraph.shadergraph`

### stage2.unity

- 直接引用：130；递归依赖：176
- 脚本：`Assets/AbstractEnemy.cs`; `Assets/Asteroies.cs`; `Assets/AutoRotate.cs`; `Assets/BackgroundController.cs`; `Assets/Blink.cs`; `Assets/BloodController.cs`; `Assets/Boss2AI.cs`; `Assets/BossBarController.cs`; `Assets/BossExplosion.cs`; `Assets/Bullet.cs`; `Assets/BulletManager.cs`; `Assets/BullletTypePic.cs`; `Assets/CleanupOutOfBounds.cs`; `Assets/Coin.cs`; `Assets/ContinueButtonFuc.cs`; `Assets/EnemyAI1.cs`; `Assets/EnemyPlaneManager.cs`; `Assets/FollowBullet.cs`; ...(+28)
- 精灵/图片：`Assets/Sprite/5HP Bar - 0.png`; `Assets/Sprite/5HP Bar - 1.png`; `Assets/Sprite/5HP Bar - 2.png`; `Assets/Sprite/5HP Bar - 3.png`; `Assets/Sprite/5HP Bar - 4.png`; `Assets/Sprite/5HP Bar - 5.png`; `Assets/Sprite/All_Fire_Bullet_Pixel_16x16_00.png`; `Assets/Sprite/Asteroids 01.png`; `Assets/Sprite/Asteroids 02.png`; `Assets/Sprite/Asteroids 03.png`; `Assets/Sprite/Asteroids 04.png`; `Assets/Sprite/Asteroids 05.png`; `Assets/Sprite/Asteroids 06.png`; `Assets/Sprite/Asteroids 07.png`; `Assets/Sprite/Asteroids 08.png`; `Assets/Sprite/Asteroids 09.png`; `Assets/Sprite/Asteroids 10.png`; `Assets/Sprite/Asteroids 11.png`; ...(+39)
- 音频：`Assets/Audio/bgsound.mp3`; `Assets/Audio/biu.wav`; `Assets/Audio/bossfight.mp3`; `Assets/Audio/bulletfire.wav`; `Assets/Audio/bulletyue.wav`; `Assets/Audio/buqiang.mp3`; `Assets/Audio/explosion.wav`; `Assets/Audio/failed.wav`; `Assets/Audio/gamestart.wav`; `Assets/Audio/getcoin.wav`; `Assets/Audio/hit.wav`; `Assets/Audio/hurt.wav`; `Assets/Audio/jian.wav`; `Assets/Audio/jiguang.wav`; `Assets/Audio/laser.wav`; `Assets/Audio/meteor.wav`; `Assets/Audio/missile.wav`; `Assets/Audio/missileboom.wav`; ...(+6)
- Prefab：-
- 动画/Controller：`Assets/Sprite/Boom.controller`; `Assets/Sprite/BoomAnimation.anim`; `Assets/Sprite/BulletFire.anim`; `Assets/Sprite/BulletFire.controller`; `Assets/Sprite/BulletMissile 1.controller`; `Assets/Sprite/BulletYue.anim`; `Assets/Sprite/BulletYue.controller`; `Assets/Sprite/Diamond.controller`; `Assets/Sprite/Meteor.controller`; `Assets/Sprite/MissileAnimation.anim`; `Assets/Sprite/NewCoin1.controller`; `Assets/Sprite/NewCoin2.controller`; `Assets/Sprite/NewCoin3.controller`; `Assets/Sprite/diamond.anim`; `Assets/Sprite/goid.anim`; `Assets/Sprite/gold.controller`; `Assets/Sprite/meteor.anim`; `Assets/Sprite/newcoin1.anim`; ...(+2)
- 材质/Shader：`Assets/Laser/LaserMaterial.mat`; `Assets/Laser/LaserParticle.mat`; `Assets/Laser/LaserShader.shadergraph`; `Assets/Shield/ShieldM.mat`; `Assets/Shield/ShieldUnlitGraph.shadergraph`

### stage3.unity

- 直接引用：133；递归依赖：179
- 脚本：`Assets/AbstractEnemy.cs`; `Assets/Asteroies.cs`; `Assets/AutoRotate.cs`; `Assets/BOSS3AI.cs`; `Assets/BackgroundController.cs`; `Assets/Blink.cs`; `Assets/BloodController.cs`; `Assets/Boss2AI.cs`; `Assets/BossBarController.cs`; `Assets/BossExplosion.cs`; `Assets/Bullet.cs`; `Assets/BulletManager.cs`; `Assets/BullletTypePic.cs`; `Assets/CleanupOutOfBounds.cs`; `Assets/Coin.cs`; `Assets/ContinueButtonFuc.cs`; `Assets/EnemyAI1.cs`; `Assets/EnemyPlaneManager.cs`; ...(+30)
- 精灵/图片：`Assets/Sprite/5HP Bar - 0.png`; `Assets/Sprite/5HP Bar - 1.png`; `Assets/Sprite/5HP Bar - 2.png`; `Assets/Sprite/5HP Bar - 3.png`; `Assets/Sprite/5HP Bar - 4.png`; `Assets/Sprite/5HP Bar - 5.png`; `Assets/Sprite/All_Fire_Bullet_Pixel_16x16_00.png`; `Assets/Sprite/Asteroids 01.png`; `Assets/Sprite/Asteroids 02.png`; `Assets/Sprite/Asteroids 03.png`; `Assets/Sprite/Asteroids 04.png`; `Assets/Sprite/Asteroids 05.png`; `Assets/Sprite/Asteroids 06.png`; `Assets/Sprite/Asteroids 07.png`; `Assets/Sprite/Asteroids 08.png`; `Assets/Sprite/Asteroids 09.png`; `Assets/Sprite/Asteroids 10.png`; `Assets/Sprite/Asteroids 11.png`; ...(+40)
- 音频：`Assets/Audio/bgsound.mp3`; `Assets/Audio/biu.wav`; `Assets/Audio/bossfight.mp3`; `Assets/Audio/bulletfire.wav`; `Assets/Audio/bulletyue.wav`; `Assets/Audio/buqiang.mp3`; `Assets/Audio/explosion.wav`; `Assets/Audio/failed.wav`; `Assets/Audio/gamestart.wav`; `Assets/Audio/getcoin.wav`; `Assets/Audio/hit.wav`; `Assets/Audio/hurt.wav`; `Assets/Audio/jian.wav`; `Assets/Audio/jiguang.wav`; `Assets/Audio/laser.wav`; `Assets/Audio/meteor.wav`; `Assets/Audio/missile.wav`; `Assets/Audio/missileboom.wav`; ...(+6)
- Prefab：-
- 动画/Controller：`Assets/Sprite/Boom.controller`; `Assets/Sprite/BoomAnimation.anim`; `Assets/Sprite/BulletFire.anim`; `Assets/Sprite/BulletFire.controller`; `Assets/Sprite/BulletMissile 1.controller`; `Assets/Sprite/BulletYue.anim`; `Assets/Sprite/BulletYue.controller`; `Assets/Sprite/Diamond.controller`; `Assets/Sprite/Meteor.controller`; `Assets/Sprite/MissileAnimation.anim`; `Assets/Sprite/NewCoin1.controller`; `Assets/Sprite/NewCoin2.controller`; `Assets/Sprite/NewCoin3.controller`; `Assets/Sprite/diamond.anim`; `Assets/Sprite/goid.anim`; `Assets/Sprite/gold.controller`; `Assets/Sprite/meteor.anim`; `Assets/Sprite/newcoin1.anim`; ...(+2)
- 材质/Shader：`Assets/Laser/LaserMaterial.mat`; `Assets/Laser/LaserParticle.mat`; `Assets/Laser/LaserShader.shadergraph`; `Assets/Shield/ShieldM.mat`; `Assets/Shield/ShieldUnlitGraph.shadergraph`

### thanks.unity

- 直接引用：44；递归依赖：53
- 脚本：`Assets/Asteroies.cs`; `Assets/BackgroundController.cs`; `Assets/Blink.cs`; `Assets/CleanupOutOfBounds.cs`; `Assets/MobileSystemController.cs`; `Assets/NewGameButtonFunc.cs`; `Assets/NumberDisplay.cs`; `Assets/QuitGameButtonFunc.cs`; `Assets/Settlement.cs`; `Assets/ShakeController.cs`; `Assets/SystemController.cs`
- 精灵/图片：`Assets/Sprite/Asteroids 01.png`; `Assets/Sprite/Asteroids 02.png`; `Assets/Sprite/Asteroids 03.png`; `Assets/Sprite/Asteroids 04.png`; `Assets/Sprite/Asteroids 05.png`; `Assets/Sprite/Asteroids 06.png`; `Assets/Sprite/Asteroids 07.png`; `Assets/Sprite/Asteroids 08.png`; `Assets/Sprite/Asteroids 09.png`; `Assets/Sprite/Asteroids 10.png`; `Assets/Sprite/Asteroids 11.png`; `Assets/Sprite/Asteroids 12.png`; `Assets/Sprite/Asteroids 13.png`; `Assets/Sprite/Asteroids 14.png`; `Assets/Sprite/Asteroids 15.png`; `Assets/Sprite/Asteroids 16.png`; `Assets/Sprite/Spaceship_Boss 1.png`; `Assets/Sprite/Spaceship_Boss 3.png`; ...(+9)
- 音频：`Assets/Audio/gamestart.wav`; `Assets/Audio/huanhu.wav`; `Assets/Audio/select.wav`; `Assets/Audio/settlement.wav`; `Assets/Audio/success.mp3`
- Prefab：-
- 动画/Controller：-

### transition.unity

- 直接引用：6；递归依赖：6
- 脚本：`Assets/BackgroundController.cs`; `Assets/ColorGradient.cs`; `Assets/ShakeController.cs`; `Assets/ShowController.cs`
- 精灵/图片：`Assets/Sprite/Stars.png`; `Assets/Sprite/duat font corporal.png`
- 音频：-
- Prefab：-
- 动画/Controller：-

## 核心音频使用场景

| 音频文件 | 用途/迁移备注 | 场景使用 | Unity 直接引用位置 |
|---|---|---|---|
| `Assets/Audio/bgsound.mp3` | 关卡背景音乐候选 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/biu.wav` | 基础 Bullet1/玩家射击音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/boom.aiff` | 爆炸音效候选 | - | - |
| `Assets/Audio/bossboom.wav` | Boss 爆炸/冲击音效候选 | - | - |
| `Assets/Audio/bossexplode.mp3` | Boss 爆炸音乐/音效候选 | - | - |
| `Assets/Audio/bossfight.mp3` | Boss 战音乐 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/bullet2.wav` | Bullet2 射击音效 | - | - |
| `Assets/Audio/bullet3.wav` | Bullet3 射击音效 | - | - |
| `Assets/Audio/bulletfire.wav` | BulletFire 射击音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/bulletyue.wav` | BulletYue 射击音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/buqiang.mp3` | 枪/武器音效候选 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/coinsplash.ogg` | 金币飞溅/拾取音效候选 | - | - |
| `Assets/Audio/explosion.wav` | 爆炸音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/failed.wav` | 购买/操作失败音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/gameover.mp3` | Game Over 音乐 | `GameOver.unity` | `GameOver.unity` |
| `Assets/Audio/gamestart.wav` | New Game 确认/开始音效 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Audio/getcoin.wav` | 金币拾取音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/hit.wav` | 命中反馈 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/huanhu.wav` | 欢呼/庆祝音效 | `thanks.unity` | `thanks.unity` |
| `Assets/Audio/hurt.wav` | 受伤反馈 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/jian.wav` | 箭/武器音效候选 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/jiguang.wav` | 激光音效候选 | `stage2.unity`; `stage3.unity` | `stage2.unity`; `stage3.unity` |
| `Assets/Audio/laser.mp3` | 激光音效 | - | - |
| `Assets/Audio/laser.wav` | 激光音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/meteor.wav` | 陨石音效 | `stage2.unity`; `stage3.unity` | `stage2.unity`; `stage3.unity` |
| `Assets/Audio/missile.wav` | 导弹发射音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/missileboom.wav` | 导弹爆炸音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/passstage.wav` | 过关音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/pickup.wav` | 通用拾取音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/select.wav` | 菜单光标移动/选择音效 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Audio/settlement.wav` | 结算界面音效 | `thanks.unity` | `thanks.unity` |
| `Assets/Audio/shieldtrigger.wav` | 护盾命中/反弹音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/shopping.mp3` | 商店购买音效或音乐 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Audio/stagebg.mp3` | 菜单/关卡背景音乐候选；当前 Godot 已映射为 menu/stage 音乐 | `stage0.unity` | `stage0.unity` |
| `Assets/Audio/success.mp3` | 胜利/成功音乐或音效 | `thanks.unity` | `thanks.unity` |
| `Assets/Audio/warning.wav` | Boss 警告音效 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/arrow.mp3` | 箭/方向弹音效候选 | - | - |

## 核心精灵/图片使用场景

| 精灵/图片文件 | 用途/迁移备注 | 场景使用 | Unity 直接引用位置 |
|---|---|---|---|
| `Assets/Sprite/1.png` | UI 字体、数字、按钮或 HUD 元素 | - | - |
| `Assets/Sprite/2.png` | UI 字体、数字、按钮或 HUD 元素 | - | - |
| `Assets/Sprite/3.png` | UI 字体、数字、按钮或 HUD 元素 | - | - |
| `Assets/Sprite/4.png` | UI 字体、数字、按钮或 HUD 元素 | - | - |
| `Assets/Sprite/5.png` | UI 字体、数字、按钮或 HUD 元素 | - | - |
| `Assets/Sprite/5HP Bar - 0.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/5HP Bar - 1.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/5HP Bar - 2.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/5HP Bar - 3.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/5HP Bar - 4.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/5HP Bar - 5.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/6.png` | UI 字体、数字、按钮或 HUD 元素 | - | - |
| `Assets/Sprite/All_Fire_Bullet_Pixel_16x16_00.png` | 子弹、导弹、武器投射物或子弹道具图标 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity`; `BulletFire.anim`; `BulletYue.anim`; `followbullet.anim` |
| `Assets/Sprite/Asteroids 01.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 02.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 03.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 04.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 05.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 06.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 07.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 08.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 09.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 10.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 11.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 12.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 13.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 14.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 15.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Asteroids 16.png` | 小行星/陨石敌人或菜单漂浮石块 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Background_01.png` | 背景、菜单或关卡星空 | `stage0.unity` | `stage0.unity` |
| `Assets/Sprite/Background_02.png` | 背景、菜单或关卡星空 | - | - |
| `Assets/Sprite/Background_03.png` | 背景、菜单或关卡星空 | - | - |
| `Assets/Sprite/Background_04.png` | 背景、菜单或关卡星空 | - | - |
| `Assets/Sprite/Background_05.png` | 背景、菜单或关卡星空 | - | - |
| `Assets/Sprite/Blue.png` | UI 字体、数字、按钮或 HUD 元素 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `Blue.asset` |
| `Assets/Sprite/Nebula Aqua-Pink.png` | 背景、菜单或关卡星空 | `stage2.unity` | `stage2.unity` |
| `Assets/Sprite/Nebula Red.png` | 背景、菜单或关卡星空 | `stage3.unity` | `stage3.unity` |
| `Assets/Sprite/Pixilart Sprite Sheet (17).png` | 根据 Unity 场景/Prefab 引用推断用途 | - | `MissileExplosion.anim` |
| `Assets/Sprite/PowerUp_HP.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/Spaceship_Boss 1.png` | Boss、Boss 激光或 Boss 血条 UI | `stage3.unity`; `thanks.unity` | `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Spaceship_Boss 3.png` | Boss、Boss 激光或 Boss 血条 UI | `stage2.unity`; `stage3.unity`; `thanks.unity` | `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Spaceship_Enemy - ArcShot.png` | 敌机 | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Spaceship_Enemy - DualShot.png` | 敌机 | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Spaceship_Enemy - QuadShot.png` | 敌机 | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Spaceship_Enemy - SingleShot.png` | 敌机 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` |
| `Assets/Sprite/Spaceship_Protagonist - P1.png` | 玩家主角飞船候选 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/Stars.png` | 背景、菜单或关卡星空 | `GameOver.unity`; `stage0.unity`; `thanks.unity`; `transition.unity` | `GameOver.unity`; `stage0.unity`; `thanks.unity`; `transition.unity` |
| `Assets/Sprite/WyvernHornBow.png` | 子弹、导弹、武器投射物或子弹道具图标 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/arrow.png` | 子弹、导弹、武器投射物或子弹道具图标 | - | - |
| `Assets/Sprite/badlogic.jpg` | 根据 Unity 场景/Prefab 引用推断用途 | - | - |
| `Assets/Sprite/bg.png` | 背景、菜单或关卡星空 | - | - |
| `Assets/Sprite/bkblue.png` | UI 字体、数字、按钮或 HUD 元素 | `stage1.unity` | `stage1.unity` |
| `Assets/Sprite/blood bar.png` | HP 拾取物或血条/Boss 血条 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/border.png` | UI 字体、数字、按钮或 HUD 元素 | - | - |
| `Assets/Sprite/boss1.png` | Boss、Boss 激光或 Boss 血条 UI | `stage1.unity`; `thanks.unity` | `stage1.unity`; `thanks.unity` |
| `Assets/Sprite/bossblood.png` | Boss、Boss 激光或 Boss 血条 UI | - | - |
| `Assets/Sprite/bosslaser.png` | Boss、Boss 激光或 Boss 血条 UI | `stage2.unity`; `stage3.unity` | `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/bullet.png` | 子弹、导弹、武器投射物或子弹道具图标 | - | - |
| `Assets/Sprite/bullet3.png` | 子弹、导弹、武器投射物或子弹道具图标 | - | - |
| `Assets/Sprite/bullet4.png` | 子弹、导弹、武器投射物或子弹道具图标 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/bullet5.png` | 子弹、导弹、武器投射物或子弹道具图标 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/bullet6.png` | 子弹、导弹、武器投射物或子弹道具图标 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/bulletitem.png` | 子弹、导弹、武器投射物或子弹道具图标 | - | - |
| `Assets/Sprite/duat font corporal.png` | UI 字体、数字、按钮或 HUD 元素 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity`; `transition.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity`; `transition.unity` |
| `Assets/Sprite/ep2.png` | 敌机 | - | - |
| `Assets/Sprite/explosion.png` | 爆炸 VFX 图集 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `BoomAnimation.anim` |
| `Assets/Sprite/f.PNG` | 僚机/友方小飞机 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/font.png` | UI 字体、数字、按钮或 HUD 元素 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/friendplane.png` | 僚机/友方小飞机 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/gdb-coinsgemsetc-1.png` | 金币拾取物或金币动画图集 | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `thanks.unity`; `diamond.anim`; `goid.anim`; `newcoin1.anim`; `newcoin2.anim`; `newcoin3.anim` |
| `Assets/Sprite/gold1.png` | 金币拾取物或金币动画图集 | - | - |
| `Assets/Sprite/gold2.png` | 金币拾取物或金币动画图集 | - | - |
| `Assets/Sprite/gold3.png` | 金币拾取物或金币动画图集 | - | - |
| `Assets/Sprite/goods.png` | 商店商品/可购买物品 UI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |
| `Assets/Sprite/meteor0001.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity`; `thanks.unity` | `thanks.unity`; `meteor.anim` |
| `Assets/Sprite/meteor0002.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0003.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0004.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0005.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0006.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0007.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0008.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0009.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0010.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/meteor0011.png` | 小行星/陨石敌人或菜单漂浮石块 | `stage2.unity`; `stage3.unity` | `meteor.anim` |
| `Assets/Sprite/pixelbullets.png` | 子弹、导弹、武器投射物或子弹道具图标 | - | - |
| `Assets/Sprite/plane.png` | 玩家主角飞船候选 | - | - |
| `Assets/Sprite/ship.png` | 玩家主角飞船候选 | - | - |
| `Assets/Sprite/spr_missile.png` | 子弹、导弹、武器投射物或子弹道具图标 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` |

## 字体与 UI 数据资源

| 资源 | 类型 | 场景使用 | Unity 直接引用位置 | 迁移备注 |
|---|---|---|---|---|
| `Assets/Font/STHUPO.TTF` | Font | - | `myfont.asset`; `myfont2.asset` | 复制/导入为 Godot FontFile 或 Theme；TMP `.asset` 需要人工替代 |
| `Assets/Font/myfont.asset` | Unity Asset/Data | - | - | 复制/导入为 Godot FontFile 或 Theme；TMP `.asset` 需要人工替代 |
| `Assets/Font/myfont.txt` | TXT | - | - | 复制/导入为 Godot FontFile 或 Theme；TMP `.asset` 需要人工替代 |
| `Assets/Font/myfont2.asset` | Unity Asset/Data | - | - | 复制/导入为 Godot FontFile 或 Theme；TMP `.asset` 需要人工替代 |

## 核心脚本使用场景与 Godot 迁移目标

| Unity 脚本 | Unity 职责 | 场景使用 | 直接挂载/引用位置 | Godot 迁移目标 |
|---|---|---|---|---|
| `Assets/AbstractEnemy.cs` | 敌人标记/基类，用于子弹碰撞过滤 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Asteroies.cs` | 小行星/陨石行为 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/AutoMove.cs` | 通用自动移动 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/AutoRotate.cs` | 通用自动旋转 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/BOSS3AI.cs` | Boss 3 跟随玩家 X、散射/导弹/激光模式 | `stage3.unity` | `stage3.unity` | 从 `scripts/entities/boss.gd` 拆出 Boss3 策略 |
| `Assets/BOSSController.cs` | Boss 1 移动、Boss 血条、主弹幕/特殊弹幕 | `stage1.unity` | `stage1.unity` | 从 `scripts/entities/boss.gd` 拆出 Boss1 策略 |
| `Assets/BackgroundController.cs` | 背景控制辅助 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity`; `transition.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity`; `transition.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Blink.cs` | Sprite 闪烁辅助 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/BlinkText.cs` | 文字闪烁辅助 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/BloodController.cs` | 血条控制 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Boss2AI.cs` | Boss 2 随机移动、环形弹、激光 | `stage2.unity`; `stage3.unity` | `stage2.unity`; `stage3.unity` | 从 `scripts/entities/boss.gd` 拆出 Boss2 策略 |
| `Assets/BossBarController.cs` | Boss 血条显示辅助 | `stage2.unity`; `stage3.unity` | `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/BossExplosion.cs` | Boss 死亡爆炸序列 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Bullet.cs` | 子弹碰撞、伤害、爆炸、回收到对象池 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/entities/bullet.gd` + 未来对象池/VFX |
| `Assets/BulletManager.cs` | 子弹 Prefab/音频/间隔/对象池名称注册表 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 未来 Bullet 资源注册表；当前在 `SpaceBullet.bullet_info()` |
| `Assets/BullletTypePic.cs` | 子弹槽图标元数据 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/ButtonFunc.cs` | 菜单按钮基类 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/CleanupOutOfBounds.cs` | 越界销毁/回收 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Coin.cs` | 金币拾取行为 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/entities/pickup.gd` 金币路径 |
| `Assets/ColorGradient.cs` | 颜色渐变显示辅助 | `GameOver.unity`; `stage0.unity`; `transition.unity` | `GameOver.unity`; `stage0.unity`; `transition.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/ContinueButtonFuc.cs` | 继续/重开按钮行为 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Data.cs` | 持久化运行数据：金币、关卡索引、HP、子弹槽、僚机数量、统计计数 | `stage0.unity` | `stage0.unity` | `autoload/game_data.gd` |
| `Assets/DimensionsChangeController.cs` | 尺寸/缩放动画辅助 | `GameOver.unity`; `stage0.unity`; `stage1.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/EnemyAI1.cs` | 特殊敌人 AI | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/EnemyPlaneManager.cs` | 关卡刷怪、Warning 时间、Boss 激活 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/game/stage.gd` 或未来 StageDirector 资源 |
| `Assets/EpGenerator.cs` | 敌人生成辅助 | `stage3.unity` | `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/FollowBullet.cs` | 追踪弹行为 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `SpaceBullet` homing 路径，仍需 parity pass |
| `Assets/GameObjectPool.cs` | Unity 子弹/效果对象池 | - | - | 需要新增 Godot `ObjectPool` autoload/system |
| `Assets/Goods.cs` | 商店商品数据与触发行为 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/entities/pickup.gd` goods 路径，建议改为 Product 场景/资源 |
| `Assets/Health.cs` | 生命值、伤害数字、受击闪烁、死亡动画、掉落、GameOver 触发 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/entities/combat_body.gd`，仍缺伤害数字/掉落细节 |
| `Assets/HpPickUp.cs` | HP 拾取行为 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/entities/pickup.gd` HP 路径 |
| `Assets/InitFrameScript.cs` | 初始帧/初始化辅助 | `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/KeyValueData.cs` | 序列化键值数据 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/Laser/LaserController2.cs` | 激光位置/伤害控制 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `SpaceBullet` 激光路径 + 未来激光 Shader/Scene |
| `Assets/MobileInput.cs` | 移动端输入桥接 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/MobileSystemController.cs` | 移动端 UI/系统控制 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/MyDictionary.cs` | 字典辅助 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/NewGameButtonFunc.cs` | New Game 按钮音效/闪烁/切场景 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `scripts/game/menu.gd` 确认流程 |
| `Assets/NumberDisplay.cs` | 数字显示、伤害数字、金币数字 | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/OrbitAround.cs` | 环绕运动 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/PauseController.cs` | 暂停界面/输入 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/PickUpManager.cs` | 拾取物生成/管理 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/PlaneController.cs` | 玩家触摸/键盘移动、边界限制、切换子弹 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/entities/player.gd` |
| `Assets/PlayMusic.cs` | 音乐播放辅助 | `stage0.unity` | `stage0.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/QuitGameButtonFunc.cs` | 退出按钮行为 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `scripts/game/menu.gd` 退出流程 |
| `Assets/RotationEpShootController.cs` | 旋转敌人射击行为 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/ScrollBackground.cs` | 滚动背景 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/SerializableDictionary/Editor/SerializableDictionaryPropertyDrawer.cs` | Unity C# 行为脚本；迁移前需要按源码确认精确逻辑 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/SerializableDictionary/Example/Editor/UserSerializableDictionaryPropertyDrawers.cs` | Unity C# 行为脚本；迁移前需要按源码确认精确逻辑 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/SerializableDictionary/Example/SerializableDictionaryExample.cs` | Unity C# 行为脚本；迁移前需要按源码确认精确逻辑 | - | `SerializableDicitonary Example.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/SerializableDictionary/Example/UserSerializableDictionaries.cs` | Unity C# 行为脚本；迁移前需要按源码确认精确逻辑 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/SerializableDictionary/SerializableDictionary.cs` | 通用可序列化字典实现 | - | - | 尚未映射到专用 Godot 文件 |
| `Assets/Settlement.cs` | 结算/统计展示 | `thanks.unity` | `thanks.unity` | `scripts/game/thanks.gd`，仍需视觉 parity |
| `Assets/ShakeController.cs` | 相机/对象震动 | `GameOver.unity`; `stage0.unity`; `thanks.unity`; `transition.unity` | `GameOver.unity`; `stage0.unity`; `thanks.unity`; `transition.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Shield.cs` | 护盾跟随、子弹反弹、接触伤害、护盾 HP | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/entities/shield.gd`，接触伤害仍缺 |
| `Assets/ShootBullet.cs` | 玩家、敌人、Boss 的射击模式与子弹实例化 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 未来 BulletPattern 辅助；当前分散在 player/enemy/boss |
| `Assets/ShowController.cs` | 显示/隐藏控制 | `transition.unity` | `transition.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/ShowSmallCount.cs` | 僚机数量显示 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/ShowSubObjectsDelayed.cs` | 延迟显示子对象 | `stage2.unity`; `stage3.unity` | `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/SmoothMovement.cs` | 平滑移动插值 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/SpaceHeroGameManager.cs` | 关卡/全局游戏管理与音乐切换 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `autoload/scene_flow.gd` + StageDirector |
| `Assets/SystemController.cs` | 菜单/系统光标与按钮控制 | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `GameOver.unity`; `stage0.unity`; `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | `scripts/game/menu.gd` |
| `Assets/SystemUIController.cs` | HUD/商店：金币、子弹槽、僚机、护盾、购买流程 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/ui/hud.gd` + 未来 HUD/shop 场景 |
| `Assets/TouchSwitchBulletButton.cs` | 触摸切换武器按钮 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/VictoryAnimationController.cs` | 通关后玩家胜利动画 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |
| `Assets/Warning.cs` | Warning 表现 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | `scripts/ui/hud.gd`，仍需美术 parity |
| `Assets/WudiButton.cs` | 无敌/调试按钮 | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 尚未映射到专用 Godot 文件 |

## 核心 Prefab 使用场景

未发现非第三方核心 `.prefab`。当前 Unity 核心玩法对象主要直接序列化在 `.unity` 场景中；迁移到 Godot 时仍建议拆成可复用 `.tscn`/`.tres`。

## 核心动画、Controller、材质与 Shader

| 资源 | 类型 | 场景使用 | Unity 直接引用位置 | 迁移备注 |
|---|---|---|---|---|
| `Assets/Laser/LaserMaterial.mat` | Material/Shader | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 转为 Godot ShaderMaterial，或用 Line2D/TextureRect/Area2D 简化实现激光 |
| `Assets/Laser/LaserParticle.mat` | Material/Shader | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 转为 Godot ShaderMaterial，或用 Line2D/TextureRect/Area2D 简化实现激光 |
| `Assets/Laser/LaserShader.shadergraph` | Material/Shader | `stage1.unity`; `stage2.unity`; `stage3.unity` | `LaserMaterial.mat` | 转为 Godot ShaderMaterial，或用 Line2D/TextureRect/Area2D 简化实现激光 |
| `Assets/Shield/Shader Graphs_ShieldShader Graph.mat` | Material/Shader | - | - | 转为 Godot ShaderMaterial，或用程序化圆环/粒子实现护盾 |
| `Assets/Shield/ShieldM.mat` | Material/Shader | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 转为 Godot ShaderMaterial，或用程序化圆环/粒子实现护盾 |
| `Assets/Shield/ShieldShader Graph.shadergraph` | Material/Shader | - | `Shader Graphs_ShieldShader Graph.mat` | 转为 Godot ShaderMaterial，或用程序化圆环/粒子实现护盾 |
| `Assets/Shield/ShieldUnlitGraph.shadergraph` | Material/Shader | `stage1.unity`; `stage2.unity`; `stage3.unity` | `ShieldM.mat` | 转为 Godot ShaderMaterial，或用程序化圆环/粒子实现护盾 |
| `Assets/Sprite/BlueSkybox.mat` | Material/Shader | - | - | 迁移前确认材质/Shader 是否仍被核心场景依赖 |
| `Assets/Sprite/Boom.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/BoomAnimation.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `Boom.controller`; `BulletMissile 1.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/BulletFire.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `BulletFire.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/BulletFire.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/BulletMissile 1.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/BulletYue.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `BulletYue.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/BulletYue.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/Diamond.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/FollowBullet.controller` | Animation/Controller | - | - | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/Meteor.controller` | Animation/Controller | `stage2.unity`; `stage3.unity` | `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/MissileAnimation.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `BulletMissile 1.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/MissileExplosion.anim` | Animation/Controller | - | - | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/NewCoin1.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/NewCoin2.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/NewCoin3.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/b.controller` | Animation/Controller | - | - | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/boss1Animation.anim` | Animation/Controller | - | - | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/diamond.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `Diamond.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/followbullet.anim` | Animation/Controller | - | `FollowBullet.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/goid.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `gold.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/gold.controller` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `stage1.unity`; `stage2.unity`; `stage3.unity` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/meteor.anim` | Animation/Controller | `stage2.unity`; `stage3.unity` | `Meteor.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/newcoin1.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `NewCoin1.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/newcoin2.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `NewCoin2.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |
| `Assets/Sprite/newcoin3.anim` | Animation/Controller | `stage1.unity`; `stage2.unity`; `stage3.unity` | `NewCoin3.controller` | 重建为 Godot `AnimationPlayer`、`AnimatedSprite2D/SpriteFrames` 或脚本驱动 VFX |

## 无 YAML 引用的核心音频

这些文件没有出现在 `.unity`/`.prefab`/`.asset`/`.controller`/`.anim`/`.mat` 的直接引用中；可能只通过代码、导入设置或迁移候选用途存在。

- `Assets/Audio/boom.aiff`
- `Assets/Audio/bossboom.wav`
- `Assets/Audio/bossexplode.mp3`
- `Assets/Audio/bullet2.wav`
- `Assets/Audio/bullet3.wav`
- `Assets/Audio/coinsplash.ogg`
- `Assets/Audio/laser.mp3`
- `Assets/Sprite/arrow.mp3`

## 无 YAML 引用的核心精灵/图片

这些文件没有出现在 `.unity`/`.prefab`/`.asset`/`.controller`/`.anim`/`.mat` 的直接引用中；可能只通过代码、导入设置或迁移候选用途存在。

- `Assets/Sprite/1.png`
- `Assets/Sprite/2.png`
- `Assets/Sprite/3.png`
- `Assets/Sprite/4.png`
- `Assets/Sprite/5.png`
- `Assets/Sprite/6.png`
- `Assets/Sprite/Background_02.png`
- `Assets/Sprite/Background_03.png`
- `Assets/Sprite/Background_04.png`
- `Assets/Sprite/Background_05.png`
- `Assets/Sprite/arrow.png`
- `Assets/Sprite/badlogic.jpg`
- `Assets/Sprite/bg.png`
- `Assets/Sprite/border.png`
- `Assets/Sprite/bossblood.png`
- `Assets/Sprite/bullet.png`
- `Assets/Sprite/bullet3.png`
- `Assets/Sprite/bulletitem.png`
- `Assets/Sprite/ep2.png`
- `Assets/Sprite/gold1.png`
- `Assets/Sprite/gold2.png`
- `Assets/Sprite/gold3.png`
- `Assets/Sprite/pixelbullets.png`
- `Assets/Sprite/plane.png`
- `Assets/Sprite/ship.png`

## 第三方与可选资源包

| 资源组 | GUID 映射资源数 | 主场景是否递归使用 | 迁移建议 |
|---|---:|---|---|
| `Assets/JMO Assets/` | 802 | `stage1.unity`; `stage2.unity`; `stage3.unity`; `thanks.unity` | 作为可选 VFX 来源。优先用 Godot 粒子或选定贴图重建需要的爆炸/命中/拾取效果，不建议整体迁移。 |
| `Assets/Joystick Pack/` | 54 | `stage1.unity` | 只有需要移动端摇杆 parity 时才迁移；否则用 Godot 触摸控件重建轻量虚拟摇杆。 |
| `Assets/TextMesh Pro/` | 40 | `stage1.unity`; `stage2.unity`; `stage3.unity` | Godot 中用 Label、FontFile、Theme 替代，TMP 内部资源不直接迁移。 |
| `Assets/Excluded/` | 10 | - | 排除/示例/编辑器辅助资源；只有主场景实际引用的音频或图像才按需迁移。 |

## 迁移检查顺序建议

1. 先处理 `stage0.unity` 相关素材，因为 Godot 主菜单已经最接近 parity，可作为场景转换模板。
2. 再把核心玩法对象拆成 Godot `.tscn`/`.tres`：子弹、敌人、Boss、拾取物、护盾、HUD、Warning、结算行。
3. `.anim`/`.controller` 不能只靠 PNG 复制，需要重建为 `AnimationPlayer`、`SpriteFrames` 或脚本动画。
4. 高弹幕/Boss/VFX parity 前，先迁移 `GameObjectPool.cs` 的对象池语义。
5. 音频保持当前文件名映射，缺漏音效按“Unity 直接引用位置”回接。
6. JMO 和 Joystick 优先按需替换，不作为第一阶段核心迁移目标。
