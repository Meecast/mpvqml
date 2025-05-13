#include "settings.h"

Settings::Settings(const QString &confFilePath, QObject *parent) : QObject(parent){
    _settings = new QSettings(confFilePath, QSettings::IniFormat, this);
}

Settings::~Settings(){
}

bool Settings::hasConfigs(){
    return _settings->value(configSuccessKey, false).toBool();
}

void Settings::setHasConfig(bool isSuccess){
    _settings->setValue(configSuccessKey, isSuccess);
    _settings->sync();
}

bool Settings::getSavePosition(){
    _settings->sync();
    return _settings->value(configSavePosition, false).toBool();
}

void Settings::setSavePosition(bool save){
    _settings->setValue(configSavePosition, save);
    _settings->sync();
}
