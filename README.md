# postgres-pgroonga-pgvector

基于官方 `postgres:18.4-trixie` 的定制 PostgreSQL 镜像, 内置两个扩展:

- **pgroonga** — 全文检索 (含 mecab 中文分词、normalizer-mysql、stem、language-model 插件)
- **pgvector** — 向量检索

GitHub Actions 每天自动检查三个上游源, 有新版本就自动重新构建并推送, 无需人工干预。

## 镜像

`ghcr.io/appthing-dev/postgres-pgroonga-pgvector`

| tag | 含义 |
|---|---|
| `latest` | 跟随 `postgres:latest` |
| `18.4` | 对应 postgres 小版本 |
| `18.4-trixie` | 对应 postgres 基础镜像 tag |

> 首次推送后 ghcr 包默认 **private**。需要公开时, 在
> https://github.com/users/appthing-dev/packages/container/package/postgres-pgroonga-pgvector
> 的 Package settings 里把可见性改为 Public。

## 使用

```bash
docker pull ghcr.io/appthing-dev/postgres-pgroonga-pgvector:latest
docker run --rm -e POSTGRES_PASSWORD=secret -p 5432:5432 ghcr.io/appthing-dev/postgres-pgroonga-pgvector:latest
```

```sql
CREATE EXTENSION pgroonga;
CREATE EXTENSION vector;
```

docker compose:

```yaml
services:
  db:
    image: ghcr.io/appthing-dev/postgres-pgroonga-pgvector:latest
    environment:
      POSTGRES_PASSWORD: secret
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

## 自动更新机制

`versions.txt` 记录当前构建使用的版本, 每次构建成功后自动更新, 作为每日检查的依据:

| 上游 | 检查方式 | 变更后动作 |
|---|---|---|
| postgres | 读 `docker.io/library/postgres:latest` 镜像 config 的 `PG_VERSION` env (当前 18.4-1.pgdg13+1) | 换用新基础镜像 `postgres:<新版本>-trixie` 重建 |
| pgroonga | 读官方 apt 源 `packages.groonga.org/debian/dists/trixie/main/binary-amd64/Packages` 中 `postgresql-<major>-pgdg-pgroonga` 的最高版本 | 更新版本号重建 |
| pgvector | 读 GitHub tags (pgvector 不发 release): `api.github.com/repos/pgvector/pgvector/tags` 最新 `v*` 标签 | 更新版本号重建 |

调度: 每天 03:00 UTC (北京时间 11:00)。也可在 Actions 页面手动运行 `build`
workflow 并勾选 force 强制重建, 或直接修改 Dockerfile 推送触发重建。

构建产物: 推送到 GHCR 的 `latest` / `<postgres版本>` / `<postgres版本>-trixie` 三个 tag,
同时把新版本写回 `versions.txt` 并提交。

## 注意事项

- **pgroonga 对新 PostgreSQL 大版本的支持可能滞后**: 如果 postgres 发布新大版本而
  groonga apt 源还没有对应的 `postgresql-<major>-pgdg-pgroonga` 包, workflow 会报错中止,
  versions.txt 保持原样, 镜像不变; 等 pgroonga 跟上后每天会自动恢复。
- 目前只构建 `linux/amd64`。需要 arm64 时把 workflow 里 `platforms` 改为
  `linux/amd64,linux/arm64` 即可 (构建时间会明显变长)。
- 镜像 tag 只体现 postgres 版本, 扩展版本见 `versions.txt` 与 workflow run 记录。

## 文件

- `Dockerfile` — 合并自 pgroonga/docker (debian/18) 与 pgvector/pgvector 官方 Dockerfile,
  基础镜像 `postgres:18.4-trixie`, 扩展版本通过 build-arg 传入
- `.github/workflows/build.yml` — 每日版本检查 + 构建 + 推送 GHCR + 更新 versions.txt
- `versions.txt` — 当前构建使用的版本记录 (自动维护)
