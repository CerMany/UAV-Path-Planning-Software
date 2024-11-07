#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QSslSocket>
#include <QtDebug>
#include "ElevationReader.h"
#include "AStar.h"
#include "aco.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    qmlRegisterType<ElevationReader>("ElevationReader", 1, 0, "ElevationReader");
    qmlRegisterType<AStar>("AStar", 1, 0, "AStar");
    qmlRegisterType<ACO>("ACO", 1, 0, "ACO");

    if (!QSslSocket::supportsSsl()) {
        qWarning() << "SSL not support!";
        return -1;
    } else {
        qDebug() << "SSL support!";
    }

    app.setWindowIcon(QIcon(":/png/appIcon.png"));

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
