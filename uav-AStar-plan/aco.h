#ifndef ACO_H
#define ACO_H

#include <QObject>
#include <QVariantList>
#include <QGeoCoordinate>

class ACO : public QObject {
    Q_OBJECT
public:
    explicit ACO(QObject *parent = nullptr);
    ~ACO() {}

    Q_INVOKABLE QVariantList findPath(double startLat, double startLon, double goalLat, double goalLon, const QVariantList &obstacles, double uavAltitude);
    Q_PROPERTY(double shortestPathLength READ shortestPathLength NOTIFY shortestPathLengthChanged)
    double shortestPathLength() const {
        return mShortestPathLength;
    }
signals:
    void shortestPathLengthChanged();

private:
    struct Node {
        QGeoCoordinate position;
        Node* parent;
    };

    bool isInObstacle(double lat, double lon, double altitude, const QVariantList &obstacles);
    QVariantList buildPath(Node* node);
    double calculateHeuristic(const QGeoCoordinate &a, const QGeoCoordinate &b);
    Node* moveAnt(Node* currentNode, Node* startNode, const QGeoCoordinate &goal, double alpha, double beta, double pheromoneMatrix[500][500], const QVariantList &obstacles, const std::vector<QGeoCoordinate> &visitedNodes, double uavAltitude);
    void updatePheromoneMatrix(double pheromoneMatrix[500][500], const std::vector<Node*> &ants, Node* startNode, double evaporationRate, double pheromoneIntensity);
    double calculatePathLength(const QVariantList &path);
    QList<double> mData{};
    double mShortestPathLength;
};

#endif // ACO_H
