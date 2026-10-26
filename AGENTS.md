# 编码入口

开始修改前阅读 [开发文档索引](docs/README.md)、[架构总览](docs/architecture/overview.md) 和 [代码组织与新增功能](docs/guides/code-organization.md)，再阅读受影响功能的文档及 ADR。

后续代码按指南中的 `app / features / core / l10n` 骨架落位，命名遵循编码指南，依赖作用域和资源所有权遵循架构说明。按实际需要创建目录，复用现有业务入口；不要为了目录或名称统一进行无关重构。

验证按 [测试指南](docs/guides/testing.md) 执行，Flutter / Dart 命令使用项目 FVM 固定 SDK。只同步受影响的机制与验证文档；阶段变化更新 status.md，技术方向变化才修订 ADR。未来计划与已实现行为分别描述。
