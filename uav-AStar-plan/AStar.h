#ifndef ASTAR_H
#define ASTAR_H

#include <vector>
#include <queue>
#include <unordered_map>
#include <QGeoCoordinate>
#include <QVariantList>
#include <QObject>

// Cấu trúc Node đại diện cho một điểm trên bản đồ
struct Node {
    QGeoCoordinate position;  // Vị trí của node
    Node* parent;             // Node cha (để xây dựng đường đi)
    double gCost;             // Chi phí từ điểm bắt đầu đến node này
    double hCost;             // Ước lượng chi phí từ node này đến đích
    double fCost;             // Tổng chi phí (gCost + hCost)

    Node(QGeoCoordinate pos, Node* par, double g, double h);

    bool operator>(const Node& other) const;  // So sánh để sử dụng trong hàng đợi ưu tiên
};

// Lớp AStar để thực hiện thuật toán A*
class AStar : public QObject {
    Q_OBJECT
public:
    // Constructor và Destructor
    explicit AStar(QObject* parent = nullptr) : QObject(parent) {}
    ~AStar() {}

    // Hàm tìm kiếm đường đi từ điểm bắt đầu đến đích
    Q_INVOKABLE QVariantList findPath(double startLat, double startLon, double goalLat, double goalLon,
                                       const QVariantList &obstacles, double uavAltitude);
    Q_PROPERTY(double pathLength READ pathLength NOTIFY pathLengthChanged)
    double pathLength() const {
        return mPathLength;
    }
signals:
    void pathLengthChanged();

private:
    // Heuristic: tính khoảng cách từ một điểm đến đích
    double calculateHeuristic(const QGeoCoordinate &a, const QGeoCoordinate &b);

    // Kiểm tra xem một điểm có nằm trong vùng vật cản hay không
    bool isInObstacle(double lat, double lon, double altitude, const QVariantList &obstacles);

    // Xây dựng đường đi từ node đích đến node bắt đầu
    QVariantList buildPath(Node* node);

    // Hàm để lấy các node lân cận
    std::vector<QGeoCoordinate> getNeighbors(const QGeoCoordinate &position, const QGeoCoordinate &goal);

     // Hàm để tính độ dài đường đi
    double calculatePathLength(const QVariantList &path);
    double mPathLength;
};

#endif // ASTAR_H
