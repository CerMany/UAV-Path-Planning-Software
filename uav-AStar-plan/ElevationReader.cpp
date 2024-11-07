#include "ElevationReader.h"
#include <iostream>
#include <QFile>
#include <cmath>
#include <stdexcept>

ElevationReader::ElevationReader(QObject *parent) : QObject(parent) {}

QString ElevationReader::findMatchingFile(const QVariantList &fileNames, double latitude, double longitude) {
    for (const auto &file : fileNames) {
        QString filePath = file.toString();
        QString fileName = filePath.section("/", -1);
        int lat_tile = fileName.mid(1, 2).toInt();
        int lon_tile = fileName.mid(4, 3).toInt();
        if (fileName[0] == 'S') lat_tile = -lat_tile;
        if (fileName[3] == 'W') lon_tile = -lon_tile;

        if (latitude >= lat_tile && latitude <= lat_tile + 1 && longitude >= lon_tile && longitude <= lon_tile + 1) {
            return filePath;
        }
    }
    throw std::out_of_range("Coordinate out of range for all provided files.");
}

int16_t ElevationReader::readElevation(const QString &filePath, double latitude, double longitude) {
    QFile file(filePath); // Sử dụng QFile để mở tệp
    if (!file.open(QIODevice::ReadOnly)) {
        throw std::runtime_error("Cannot open HGT file.");
    }

    QByteArray fileData = file.readAll(); // Đọc toàn bộ nội dung tệp vào QByteArray
    file.close();

    QString fileName = filePath.section("/", -1);
    int lat_tile = fileName.mid(1, 2).toInt();
    int lon_tile = fileName.mid(4, 3).toInt();
    if (fileName[0] == 'S') lat_tile = -lat_tile;
    if (fileName[3] == 'W') lon_tile = -lon_tile;

    int row = static_cast<int>((lat_tile + 1 - latitude) * (SRTM_SIZE - 1));
    int col = static_cast<int>((longitude - lon_tile) * (SRTM_SIZE - 1));
    int offset = (row * SRTM_SIZE + col) * sizeof(int16_t);

    if (offset < 0 || offset + sizeof(int16_t) > fileData.size()) {
        throw std::runtime_error("Offset is out of bounds.");
    }

    int16_t elevation;
    memcpy(&elevation, fileData.constData() + offset, sizeof(int16_t)); // Đọc dữ liệu từ QByteArray
    elevation = (elevation << 8) | ((elevation >> 8) & 0xFF); // Chuyển đổi byte

    return elevation;
}

double ElevationReader::getElevation(double latitude, double longitude) {
    try {
        QString filePath = findMatchingFile(hgtFiles, latitude, longitude);
        return readElevation(filePath, latitude, longitude);
    } catch (const std::exception &e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return -1;
    }
}
