# MR Format Examples

## Simple change (1-line fix)

**Title:** `SWITCH-4350: Некорректное время в выводе команды show ip dhcp snooping blocked`

**Description:**

```markdown
## Описание

Исправлено отображение времени в выводе команд `show ip dhcp snooping blocked` и `show am blocked`. Вместо времени по GMT теперь используется локальное время устройства. В функции `nsm_blocked_record_show()` заменён вызов `pal_time_gmt()` на `pal_time_loc()`.

## Связанная задача

- **SWITCH-4350:** Некорректное время в выводе команды show ip dhcp snooping blocked
```

---

## Complex change (new functionality, multiple files)

**Title:** `SWITCH-4296: Запретить применение команды speed-duplex force10g-full high-leq`

**Description:**

```markdown
## Описание

Добавлена проверка модели устройства перед применением параметра `high-leq` в команде `speed-duplex`. На неподдерживаемых моделях команда теперь отклоняется с соответствующим сообщением об ошибке. Проверка реализована для всех путей управления: CLI, SNMP и config write.

## Связанная задача

- **SWITCH-4296:** Запретить применение команды speed-duplex force10g-full high-leq

## Что исправлено

### Проверка поддержки high-leq по модели устройства

- Добавлена функция `nsm_is_high_leq_supported()`, которая определяет поддержку high-leq на основании идентификатора устройства (`/sys/rtk_hw_info/deviceid`)
- Поддержка ограничена моделями серии SNR-S5210 (включая варианты UPS, DC, RPS, 2AC, POE, R)

### CLI

- При попытке выполнить `speed-duplex force10g-full high-leq` на неподдерживаемой модели пользователь получает сообщение: `high-leq is not supported on this device model`
- Команда возвращает `CLI_ERROR`, предотвращая применение некорректной конфигурации

### SNMP

- В SNMP write-обработчике (`nsm_pri_port_table_snmp.c`) добавлена аналогичная проверка
- При попытке установить high-leq через SNMP на неподдерживаемой модели возвращается `SNMP_ERR_WRONGVALUE`

### Config write (show running-config)

- Параметр `high-leq` записывается в running-config только на устройствах, которые его поддерживают
- Предотвращает появление неподдерживаемых команд в конфигурации при переносе между моделями
```
