#ifndef MPVRENDERER_H_
#define MPVRENDERER_H_

#include <QtQuick/QQuickFramebufferObject>

#include <mpv/client.h>
#include <mpv/render_gl.h>
#include "qthelper.hpp"

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT

    mpv_handle *mpv;
    mpv_render_context *mpv_gl;

    friend class MpvRenderer;

public:
    static void on_update(void *ctx);

    MpvObject(QQuickItem * parent = 0);
    virtual ~MpvObject();
    virtual Renderer *createRenderer() const;

private:
    QString mpvversion;
    bool mpvversion_is_done;
private Q_SLOTS:
    void on_mpv_events();

public slots:
    void command(const QVariant& params);
    void get_display_brightness();
    void set_display_brightness(int brightness);
    void setProperty(const QString& name, const QVariant& value);
    QVariant getProperty(const QString& name);
    QString getMpvVersion();

signals:
    void mpvVersionIsDone(QString version);
    void onUpdate();
    void updateTimePos(double _time);
    void updateDuration(double _time);
    void playbackRestart();
    void fileLoaded();
    void brightness(int brightness);

private slots:
    void doUpdate();
    void handle_mpv_event(mpv_event *event);
};

#endif
