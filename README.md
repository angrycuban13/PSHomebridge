# API Endpoints Checklist

## Accessories

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **GET**    | `/api/accessories`                                 | ✅     |
| **GET**    | `/api/accessories/layout`                          | ✅     |
| **GET**    | `/api/accessories/{uniqueId}`                      | ✅     |
| **PUT**    | `/api/accessories/{uniqueId}`                      | ❌     |

## Authentication

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **GET**    | `/api/auth/check`                                  | ✅     |
| **GET**    | `/api/auth/settings`                               | ✅     |
| **POST**   | `/api/auth/login`                                  | ✅     |
| **POST**   | `/api/auth/noauth`                                 | ✅     |

## Backup & Restore

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **DELETE** | `/api/backup/scheduled-backups/{backupId}`         | ❌     |
| **GET**    | `/api/backup/download`                             | ✅     |
| **GET**    | `/api/backup/scheduled-backups`                    | ✅     |
| **GET**    | `/api/backup/scheduled-backups/next`               | ✅     |
| **GET**    | `/api/backup/scheduled-backups/{backupId}`         | ✅     |
| **POST**   | `/api/backup/restore`                              | ❌     |
| **POST**   | `/api/backup/restore/hbfx`                         | ❌     |
| **POST**   | `/api/backup/scheduled-backups/{backupId}/restore` | ❌     |
| **PUT**    | `/api/backup/restart`                              | ❌     |
| **PUT**    | `/api/backup/restore/trigger`                      | ❌     |

## Homebridge

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **DELETE** | `/api/server/cached-accessories`                   | ❌     |
| **DELETE** | `/api/server/cached-accessories/{uuid}`            | ❌     |
| **DELETE** | `/api/server/pairings`                             | ❌     |
| **DELETE** | `/api/server/pairings/accessories`                 | ❌     |
| **DELETE** | `/api/server/pairings/{deviceId}`                  | ❌     |
| **DELETE** | `/api/server/pairings/{deviceId}/accessories`      | ❌     |
| **GET**    | `/api/server/cached-accessories`                   | ✅     |
| **GET**    | `/api/server/mdns-advertiser`                      | ✅     |
| **GET**    | `/api/server/network-interfaces/bridge`            | ✅     |
| **GET**    | `/api/server/network-interfaces/system`            | ✅     |
| **GET**    | `/api/server/pairing`                              | ✅     |
| **GET**    | `/api/server/pairings`                             | ✅     |
| **GET**    | `/api/server/port`                                 | ✅     |
| **GET**    | `/api/server/port/new`                             | ✅     |
| **PUT**    | `/api/server/mdns-advertiser`                      | ❌     |
| **PUT**    | `/api/server/name`                                 | ❌     |
| **PUT**    | `/api/server/network-interfaces/bridge`            | ❌     |
| **PUT**    | `/api/server/reset-cached-accessories`             | ❌     |
| **PUT**    | `/api/server/reset-homebridge-accessory`           | ❌     |
| **PUT**    | `/api/server/restart`                              | ❌     |
| **PUT**    | `/api/server/restart/{deviceId}`                   | ❌     |
| **PUT**    | `/api/server/start/{deviceId}`                     | ❌     |
| **PUT**    | `/api/server/stop/{deviceId}`                      | ❌     |

## Homebridge Config Editor

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **DELETE** | `/api/config-editor/backups`                       | ❌     |
| **GET**    | `/api/config-editor`                               | ✅     |
| **GET**    | `/api/config-editor/backups`                       | ✅     |
| **GET**    | `/api/config-editor/backups/{backupId}`            | ✅     |
| **GET**    | `/api/config-editor/plugin/{pluginName}`           | ✅     |
| **POST**   | `/api/config-editor`                               | ❌     |
| **POST**   | `/api/config-editor/plugin/{pluginName}`           | ❌     |
| **PUT**    | `/api/config-editor/plugin/{pluginName}/disable`   | ❌     |
| **PUT**    | `/api/config-editor/plugin/{pluginName}/enable`    | ❌     |
| **PUT**    | `/api/config-editor/ui`                            | ❌     |

## Platform - Docker

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **GET**    | `/api/platform-tools/docker/startup-script`        | ✅     |
| **PUT**    | `/api/platform-tools/docker/restart-container`     | ❌     |
| **PUT**    | `/api/platform-tools/docker/startup-script`        | ❌     |

## Platform - HB Service

| Method     | Endpoint                                                       | Status |
| ---------- | -------------------------------------------------------------- | ------ |
| **GET**    | `/api/platform-tools/hb-service/homebridge-startup-settings`   | ✅     |
| **GET**    | `/api/platform-tools/hb-service/log/download`                  | ✅     |
| **PUT**    | `/api/platform-tools/hb-service/homebridge-startup-settings`   | ❌     |
| **PUT**    | `/api/platform-tools/hb-service/log/truncate`                  | ❌     |
| **PUT**    | `/api/platform-tools/hb-service/set-full-service-restart-flag` | ❌     |

## Platform - Linux

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **PUT**    | `/api/platform-tools/linux/restart-host`           | ❌     |
| **PUT**    | `/api/platform-tools/linux/shutdown-host`          | ❌     |

## Plugins

| Method     | Endpoint                                                  | Status |
| ---------- | --------------------------------------------------------- | ------ |
| **GET**    | `/api/plugins`                                            | ✅     |
| **GET**    | `/api/plugins/alias/{pluginName}`                         | ✅     |
| **GET**    | `/api/plugins/changelog/{pluginName}`                     | ✅     |
| **GET**    | `/api/plugins/config-schema/{pluginName}`                 | ✅     |
| **GET**    | `/api/plugins/custom-plugins/homebridge-deconz/dump-file` | ❌     |
| **GET**    | `/api/plugins/custom-plugins/homebridge-hue/dump-file`    | ❌     |
| **GET**    | `/api/plugins/lookup/{pluginName}`                        | ✅     |
| **GET**    | `/api/plugins/lookup/{pluginName}/versions`               | ✅     |
| **GET**    | `/api/plugins/release/{pluginName}`                       | ✅     |
| **GET**    | `/api/plugins/search/{query}`                             | ✅     |
| **GET**    | `/api/plugins/settings-ui/{pluginName}/*`                 | ❌     |

## Server Status

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **GET**    | `/api/status/cpu`                                  | ✅     |
| **GET**    | `/api/status/homebridge`                           | ✅     |
| **GET**    | `/api/status/homebridge-version`                   | ✅     |
| **GET**    | `/api/status/homebridge/child-bridges`             | ✅     |
| **GET**    | `/api/status/network`                              | ✅     |
| **GET**    | `/api/status/nodejs`                               | ✅     |
| **GET**    | `/api/status/ram`                                  | ✅     |
| **GET**    | `/api/status/rpi/throttled`                        | ✅     |
| **GET**    | `/api/status/server-information`                   | ✅     |
| **GET**    | `/api/status/uptime`                               | ✅     |

## Setup Wizard

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **GET**    | `/api/setup-wizard/get-setup-wizard-token`         | ✅     |
| **POST**   | `/api/setup-wizard/create-first-user`              | ❌     |

## User Management

| Method     | Endpoint                                           | Status |
| ---------- | -------------------------------------------------- | ------ |
| **DELETE** | `/api/users/{userId}`                              | ❌     |
| **GET**    | `/api/users`                                       | ✅     |
| **PATCH**  | `/api/users/{userId}`                              | ❌     |
| **POST**   | `/api/users`                                       | ❌     |
| **POST**   | `/api/users/change-password`                       | ❌     |
| **POST**   | `/api/users/otp/activate`                          | ❌     |
| **POST**   | `/api/users/otp/deactivate`                        | ❌     |
| **POST**   | `/api/users/otp/setup`                             | ❌     |
