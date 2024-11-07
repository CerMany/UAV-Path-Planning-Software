#ifndef ELEVATIONREADER_H
#define ELEVATIONREADER_H

#include <QObject>
#include <QString>
#include <QVariantList>

class ElevationReader : public QObject {
    Q_OBJECT

public:
    explicit ElevationReader(QObject *parent = nullptr);
    Q_INVOKABLE double getElevation(double latitude, double longitude);

private:
    QString findMatchingFile(const QVariantList &fileNames, double latitude, double longitude);
    int16_t readElevation(const QString &filePath, double latitude, double longitude);

    const int SRTM_SIZE = 1201;
    const QVariantList hgtFiles = {
        ":/hgt-file/N20E105.hgt",
        ":/hgt-file/N20E106.hgt",
        ":/hgt-file/N21E105.hgt",
        ":/hgt-file/N21E106.hgt"
    };
};

#endif // ELEVATIONREADER_H
