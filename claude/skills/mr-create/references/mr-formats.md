# MR Format Examples

## Simple change

**Title:** `SWITCH-4350: Исправить отображение времени в show ip dhcp snooping blocked`

```markdown
## Описание

В выводе команд `show ip dhcp snooping blocked` и `show am blocked` отображалось время по GMT вместо локального. В `nsm_blocked_record_show()` заменён вызов `pal_time_gmt()` на `pal_time_loc()`.

## Заметки для ревью

- Изменение затрагивает только формат вывода, логика блокировки не меняется
```

---

## Multi-commit change with review order

**Title:** `CPE-3417: Поднять минимальную версию до 10 (API 29+)`

```markdown
## Описание

Приложение больше не поддерживает Android 9 и ниже. `minSdkVersion` поднята с 21 до 29. Удалены устаревшие проверки `SDK_INT`, мёртвые разрешения (`CHANGE_WIFI_STATE`, `WRITE_EXTERNAL_STORAGE`), флаг `requestLegacyExternalStorage` и lint-аннотации `tools:targetApi` для API ≤ 28. Код недоступного legacy-дерева (`ConfigurationFragment`, `PathCompat` и т.д.) намеренно не тронут.

## Заметки для ревью

- `checkLocPermissions` в `MainActivity` упрощён с `when` на `if/else` — проверить поведение permission flow на API 29–30 (fine only) и 31+ (fine + coarse)
- `MyPermission.isNewPermissionModel` удалён (всегда true) — затрагивает `hasPermission`, `hasPermissions`, `reRequestPermissions`
- Разрешения `CHANGE_WIFI_STATE` и `WRITE_EXTERNAL_STORAGE` удалены из манифеста — живые пути их не используют, но мёртвый код в `ConfigurationFragment` и `ApplyFragment` ссылается на них. Это ожидаемо, т.к. legacy-дерево недоступно в текущем app flow

## Порядок ревью

1. Первый коммит: `app/build.gradle` + `AndroidManifest.xml` — база
2. Второй коммит: Kotlin-файлы — runtime-упрощения, это основная часть
3. Третий коммит: XML-ресурсы — механическое удаление `tools:targetApi`, можно бегло
```
