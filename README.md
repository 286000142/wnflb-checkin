# 福利吧论坛自动签到（账号密码版）

基于 [appcctv/wnflb-checkin](https://github.com/appcctv/wnflb-checkin) 二次开发。
原版只支持 Cookie 签到，本版新增 **账号密码登录**：Cookie 过期后自动用账号密码重新登录，
新 IP 登录需要验证码时用 [ddddocr](https://github.com/sml2h3/ddddocr) 自动识别。

论坛：`https://www.wnflb2023.com/` （Discuz! X3.4）

---

## 逆向分析结论（已确认的接口）

| 功能 | 方法 / 地址 | 说明 |
|------|------------|------|
| 登录页 | `GET member.php?mod=logging&action=login` | 返回 `formhash`、`loginhash` |
| 提交登录 | `POST member.php?mod=logging&action=login&loginsubmit=yes&loginhash={loginhash}` | 表单字段：`formhash` `username` `password` `questionid` `answer` `cookietime`；需要验证码时追加 `seccodeverify` `seccodehash` |
| 验证码图片 | `GET misc.php?mod=seccode&update={rand}&idhash={idhash}` | 同一 session 拉取，提交时携带同一 `idhash` |
| 签到 | `GET plugin.php?id=fx_checkin:checkin&formhash={A}&{B}&inajax=1` | `fx_checkin` 插件，formhash 从首页 HTML 里 `fx_checkin:checkin&formhash=...` 提取 |

> 验证码是**条件触发**的：登录过的 IP 不需要验证码，新 IP 登录才需要（与你的描述一致）。
> 脚本对此做了**自适应**：登录页出现验证码字段就识别并提交；即使被服务端要求验证码也能重试。

---

## 方式一：GitHub Actions（推荐）

1. **Fork** 本仓库到你的账号。
2. 进入 `Settings → Secrets and variables → Actions → New repository secret`，添加：
   - `FORUM_USERNAME`：论坛账号（**必填**）
   - `FORUM_PASSWORD`：论坛密码（**必填**）
   - `FORUM_COOKIE`：（可选）直接填 Cookie 字符串，优先级高于下面两种方式
   - `PUSHPLUS_TOKEN` / `SERVERCHAN_KEY`：（可选）微信推送通知
3. 进入 `Actions` 标签页，手动 **Run workflow** 跑一次验证；之后会按 cron
   （北京时间 09:00 / 22:00）自动运行。
4. Cookie 会通过 **Artifacts（名为 `wnflb-cookies`）** 在每次运行间缓存：
   有效就直接签到，过期才用账号密码重新登录。

> ⚠️ GitHub 的运行机 IP 每次可能变化，因此 Actions 里**大概率每次都要识别一次验证码**，
> 本地（固定 IP）则登录一次后长期复用 Cookie。若 Actions 提示连不上论坛（GFW/网络原因），
> 可改用本地运行或自建国内 runner。

---

## 方式二：本地运行

```bash
pip install -r requirements.txt

# 方式 A：用账号密码
python wnflb_checkin.py --username "你的账号" --password "你的密码"

# 方式 B：直接用 Cookie（兼容旧版）
FORUM_COOKIE="xxx=yyy; ..." python wnflb_checkin.py

# 仅解析登录页、确认 formhash/loginhash/验证码（无需账号，排查用）
python wnflb_checkin.py --inspect
```

Windows 用户也可双击 `test_local.bat`，按提示输入账号密码（密码不会被写入文件）。

登录成功后会在当前目录生成 `cookies.json`，下次运行优先复用，**无需重复输入密码**。

---

## 测试账号

如果你希望我直接帮你实跑验证（含验证码分支），请提供：
- 一个**测试账号**的账号 + 密码
- 以及该账号当前是否在新 IP 环境（决定是否走验证码分支）

账号密码仅用于本次联调，我不会写入仓库，验证完请及时改密。

---

## 说明 / 注意

- 论坛页面为 GBK 编码，脚本已做解码兼容。
- 验证码识别率依赖 ddddocr，极端情况下可能失败；脚本会重试 3 次，仍失败则报错退出。
- 若论坛改版（formhash 字段名、签到插件变动），先看 `--inspect` 输出，再相应调整正则。
