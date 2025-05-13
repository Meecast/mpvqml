#include "main.h"
#include <stdexcept>
#include <clocale>


#include <sailfishapp.h>
#include <QtQuick>
#include "settings.h"
#include "dbusadaptor.h"

namespace
{
void on_mpv_events(void *ctx)
{
    QMetaObject::invokeMethod((MpvObject*)ctx, "on_mpv_events", Qt::QueuedConnection);
}

void on_mpv_redraw(void *ctx)
{
    MpvObject::on_update(ctx);
}

static void *get_proc_address_mpv(void *ctx, const char *name)
{
    Q_UNUSED(ctx)

    QOpenGLContext *glctx = QOpenGLContext::currentContext();
    if (!glctx) return nullptr;

    return reinterpret_cast<void *>(glctx->getProcAddress(QByteArray(name)));
}

}

class MpvRenderer : public QQuickFramebufferObject::Renderer
{
    MpvObject *obj;

public:
    MpvRenderer(MpvObject *new_obj)
        : obj{new_obj}
    {
        obj->mpvversion_is_done = false;
        if (new_obj->objectName() == QString("renderer_about")){
            qDebug()<<"Init MpvRenderer in about page";
        }
        mpv_observe_property(obj->mpv, 0, "duration", MPV_FORMAT_DOUBLE);
        mpv_observe_property(obj->mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
        mpv_set_wakeup_callback(obj->mpv, on_mpv_events, obj);
    }

    virtual ~MpvRenderer()
    {}

    // This function is called when a new FBO is needed.
    // This happens on the initial frame.
    QOpenGLFramebufferObject * createFramebufferObject(const QSize &size)
    {
        // init mpv_gl:
        if (!obj->mpv_gl)
        {
            mpv_opengl_init_params gl_init_params[1] = {get_proc_address_mpv, nullptr};
            mpv_render_param params[]{
                {MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
                {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
                {MPV_RENDER_PARAM_INVALID, nullptr}
            };

            if (mpv_render_context_create(&obj->mpv_gl, obj->mpv, params) < 0)
                throw std::runtime_error("failed to initialize mpv GL context");
            mpv_render_context_set_update_callback(obj->mpv_gl, on_mpv_redraw, obj);
        }

        return QQuickFramebufferObject::Renderer::createFramebufferObject(size);
    }

    void render()
    {
        obj->window()->resetOpenGLState();

        QOpenGLFramebufferObject *fbo = framebufferObject();
        mpv_opengl_fbo mpfbo{.fbo = static_cast<int>(fbo->handle()), .w = fbo->width(), .h = fbo->height(), .internal_format = 0};
        int flip_y{0};

        mpv_render_param params[] = {
            // Specify the default framebuffer (0) as target. This will
            // render onto the entire screen. If you want to show the video
            // in a smaller rectangle or apply fancy transformations, you'll
            // need to render into a separate FBO and draw it manually.
            {MPV_RENDER_PARAM_OPENGL_FBO, &mpfbo},
            // Flip rendering (needed due to flipped GL coordinate system).
            {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
            {MPV_RENDER_PARAM_INVALID, nullptr}
        };
        // See render_gl.h on what OpenGL environment mpv expects, and
        // other API details.
        mpv_render_context_render(obj->mpv_gl, params);

        obj->window()->resetOpenGLState();
    }
};

MpvObject::MpvObject(QQuickItem * parent)
    : QQuickFramebufferObject(parent), mpv{mpv_create()}, mpv_gl(nullptr)
{
    if (!mpv)
        throw std::runtime_error("could not create mpv context");

    /* For about page */
    mpv_request_log_messages(mpv, "trace");
    mpv_set_option_string(mpv, "msg-level", "cplayer=v");
    //mpv_set_option_string(mpv, "msg-level", "all=trace");
    QDir cache_dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    //mpv_set_option_string(mpv, "msg-level", "all=debug");
    mpv_set_option_string(mpv, "terminal", "yes");
//    mpv_set_option_string(mpv, "terminal", "no");
    QString path = cache_dir.absolutePath() + "/watch_later";
    if (!QDir(path).exists()){
        QDir().mkpath(path);
    }
    mpv_set_option_string(mpv, "vo", "libmpv");
    // apply phone-optimized defaults
    //mpv_set_option_string(mpv, "opengl-es", "yes");
    mpv_set_option_string(mpv, "watch-later-directory", path.toLatin1());

    if (mpv_initialize(mpv) < 0)
        throw std::runtime_error("could not initialize mpv context");

    mpv_set_option_string(mpv, "profile", "fast");
    // Request hw decoding, just for testing.
    mpv::qt::set_option_variant(mpv, "hwdec", "auto");

    connect(this, &MpvObject::onUpdate, this, &MpvObject::doUpdate,
            Qt::QueuedConnection);
}

MpvObject::~MpvObject()
{
    if (mpv_gl) // only initialized if something got drawn
    {
        mpv_render_context_free(mpv_gl);
    }

    mpv_terminate_destroy(mpv);
    mpv = NULL;
}

void MpvObject::on_mpv_events()
{
    // Process all events, until the event queue is empty.
    while (mpv) {
        mpv_event *event = mpv_wait_event(mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) {
            break;
        }
        handle_mpv_event(event);
    }
}

void MpvObject::handle_mpv_event(mpv_event *event)
{
    //if (event->event_id != 2)
    //    fprintf(stderr, "Event %i\n",event->event_id);
    switch (event->event_id) {
    case MPV_EVENT_PLAYBACK_RESTART: {
        emit MpvObject::playbackRestart();
        break;
    }
    case MPV_EVENT_FILE_LOADED: {
        emit MpvObject::fileLoaded();
        break;
    }
    case MPV_EVENT_PROPERTY_CHANGE: {
        mpv_event_property *prop = (mpv_event_property *)event->data;
        if (strcmp(prop->name, "time-pos") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double time = *(double *)prop->data;
                emit MpvObject::updateTimePos(time);
            } else if (prop->format == MPV_FORMAT_NONE) {
                // The property is unavailable, which probably means playback
                // was stopped.
                emit MpvObject::updateTimePos(0);
            }
        }else{
            if (strcmp(prop->name, "duration") == 0) {
                if (prop->format == MPV_FORMAT_DOUBLE) {
                    double time = *(double *)prop->data;
                    emit MpvObject::updateDuration(time);
                } else if (prop->format == MPV_FORMAT_NONE) {
                    // The property is unavailable, which probably means playback
                    // was stopped.
                    emit MpvObject::updateDuration(0);
                }
            }
        }
        break;
    }
    case MPV_EVENT_LOG_MESSAGE: {
        struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
        if (!mpvversion_is_done && strcmp(msg->prefix, "cplayer") == 0 && strcmp(msg->level, "v") == 0) {
            QString add_text = QString(msg->text);
            mpvversion.append(add_text);
            if (add_text.startsWith("List of enabled features:")){
                mpvversion_is_done = true;
                emit mpvVersionIsDone(mpvversion);
            }
        }
        break;
    }

    default: ;
        // Ignore uninteresting or unknown events.
    }
}

void MpvObject::on_update(void *ctx)
{
    MpvObject *self = (MpvObject *)ctx;
    emit self->onUpdate();
}

// connected to onUpdate(); signal makes sure it runs on the GUI thread
void MpvObject::doUpdate()
{
    update();
}

void MpvObject::command(const QVariant& params)
{
    mpv::qt::command_variant(mpv, params);
}

void MpvObject::setProperty(const QString& name, const QVariant& value)
{
    mpv::qt::set_property_variant(mpv, name, value);
}

QVariant MpvObject::getProperty(const QString& name)
{
   return mpv::qt::get_property_variant(mpv, name);
}

QString MpvObject::getMpvVersion()
{
   return this->mpvversion;
}

QQuickFramebufferObject::Renderer *MpvObject::createRenderer() const
{
    window()->setPersistentOpenGLContext(true);
    window()->setPersistentSceneGraph(true);
    return new MpvRenderer(const_cast<MpvObject *>(this));
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(SailfishApp::application(argc, argv));
    //Some more speed & memory improvements
    setenv("QT_NO_FAST_MOVE", "0", 0);
    setenv("QT_NO_FT_CACHE","0",0);
    setenv("QT_NO_FAST_SCROLL","0",0);
    setenv("QT_NO_ANTIALIASING","1",1);
    setenv("QT_NO_FREE","0",0);
    setenv("QT_PREDICT_FUTURE", "1", 1);
    setenv("QT_NO_BUG", "1", 1);
    setenv("QT_NO_QT", "1", 1);
    // Taken from sailfish-browser
    setenv("USE_ASYNC", "1", 1);
    QQuickWindow::setDefaultAlphaBuffer(true);
    application->setOrganizationName(QStringLiteral("org.meecast"));
    application->setApplicationName(QStringLiteral("mpvqml"));
    std::setlocale(LC_NUMERIC, "C");
    QString filename;
    if (argc>1) {
        if (!QString(argv[1]).startsWith("/") && !QString(argv[1]).startsWith("http://") && !QString(argv[1]).startsWith("rtsp://")
                    && !QString(argv[1]).startsWith("mms://") && !QString(argv[1]).startsWith("file://") && !QString(argv[1]).startsWith("https://")) {
            QString pwd("");
            char * PWD;
            PWD = getenv ("PWD");
            pwd.append(PWD);
            filename = pwd + "/" + QString(argv[1]);
        }else{
            filename = QString(argv[1]);
        }
    }

    qmlRegisterType<MpvObject>("mpvobject", 1, 0, "MpvObject");
    qmlRegisterType<Settings>("org.meecast.mpvqml", 1, 0, "Settings");
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/main.qml")));
    DBusAdaptor dbusAdaptor(view.data());
    view->rootContext()->setContextProperty(QStringLiteral("dbusAdaptor"), &dbusAdaptor);

    QObject *object = view->rootObject();
    if (argc>1){
        QObject *qmlObject = object->findChild<QObject*>("mainpage");
        if (qmlObject){
            QMetaObject::invokeMethod(qmlObject, "openFile", Q_ARG(QVariant, filename));
        }else{
            qDebug()<<"mainpage not found";
        }
    }

    view->show();

    return application->exec();
}
