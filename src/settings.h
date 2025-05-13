#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QDebug>
#include <QStandardPaths>
#include <QSettings>

class Settings: public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool savePosition READ getSavePosition WRITE setSavePosition NOTIFY savePositionChanged)
public:
    explicit Settings(const QString &confFilePath =
                            QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
                            .append("/config.ini"), QObject* parent = nullptr);
    ~Settings();

    bool hasConfigs();
    void setHasConfig(bool isSuccess);

    bool getSavePosition();
    void setSavePosition(bool save_pos);

private:
    QSettings* _settings;
    const QString configSuccessKey = "config/isSuccess";
    const QString configSavePosition = "config/savePosistion";
signals:
    void savePositionChanged();
};

#endif // SETTINGSS_H
