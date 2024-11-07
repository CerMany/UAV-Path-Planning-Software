#include "AStar.h"
#include <cmath>
#include <algorithm>
#include <QDebug>
#include <unordered_map>
#include <unordered_set>
#include <set>

// Hàm băm cho pair
struct pair_hash {
    template <class T1, class T2>
    std::size_t operator() (const std::pair<T1, T2> &pair) const {
        return std::hash<T1>()(pair.first) ^ std::hash<T2>()(pair.second);
    }
};

Node::Node(QGeoCoordinate pos, Node* par, double g, double h)
    : position(pos), parent(par), gCost(g), hCost(h) {
    fCost = gCost + hCost;
}

bool Node::operator>(const Node& other) const {
    return fCost > other.fCost;
}

// Hàm tính khoảng cách Heuristic (Euclidean) từ điểm a đến b.
double AStar::calculateHeuristic(const QGeoCoordinate &a, const QGeoCoordinate &b) {
    double distance = a.distanceTo(b);
    qDebug() << "Heuristic distance: " << distance;
    return distance;
}

// Kiểm tra xem một điểm có nằm trong vùng vật cản hay không.
bool AStar::isInObstacle(double lat, double lon, double altitude, const QVariantList &obstacles) {
    for (const QVariant &obs : obstacles) {
        QVariantMap obstacle = obs.toMap();
        QGeoCoordinate center(obstacle["latitude"].toDouble(), obstacle["longitude"].toDouble());
        double radius = obstacle["radius"].toDouble();
        double obsHeight = obstacle["height"].toDouble();
        QGeoCoordinate point(lat, lon);

        if (center.distanceTo(point) <= radius && altitude <= obsHeight) {
            qDebug() << "Point (" << lat << ", " << lon << ", " << altitude << ") is in obstacle.";
            return true;
        }
    }
    return false;
}

// Lấy các điểm lân cận của vị trí hiện tại.
std::vector<QGeoCoordinate> AStar::getNeighbors(const QGeoCoordinate &position, const QGeoCoordinate &goal) {
    std::vector<QGeoCoordinate> neighbors;
    double stepSize;

    // Điều chỉnh stepSize dựa trên khoảng cách hiện tại đến đích.
    double distanceToGoal = position.distanceTo(goal);
    if (distanceToGoal > 10000) {
        stepSize = 0.0005;
    } else if (distanceToGoal >= 500 && distanceToGoal <= 10000) {
        stepSize = 0.00005;
    } else {
        stepSize = 0.00001;
    }

    const std::vector<std::pair<double, double>> directions = {
        {1, 0}, {-1, 0}, {0, 1}, {0, -1},
        {1, 1}, {1, -1}, {-1, 1}, {-1, -1}
    };

    for (const auto& dir : directions) {
        double newLat = position.latitude() + dir.first * stepSize;
        double newLon = position.longitude() + dir.second * stepSize;
        QGeoCoordinate newNeighbor(newLat, newLon);

        if (newNeighbor.distanceTo(goal) < position.distanceTo(goal)) {
            neighbors.emplace_back(newLat, newLon);
        }
    }

    return neighbors;
}

// Xây dựng đường đi từ node đích đến node bắt đầu.
QVariantList AStar::buildPath(Node* node) {
    QVariantList path;
    while (node != nullptr) {
        path.prepend(QVariant::fromValue(node->position));
        node = node->parent;
    }
    return path;
}

// Hàm tìm đường đi từ điểm bắt đầu đến đích.
QVariantList AStar::findPath(double startLat, double startLon, double goalLat, double goalLon,
                             const QVariantList &obstacles, double uavAltitude) {

    QGeoCoordinate start(startLat, startLon);
    QGeoCoordinate goal(goalLat, goalLon);

    qDebug() << "Start: (" << startLat << ", " << startLon << "), Goal: (" << goalLat << ", " << goalLon << "), Altitude: " << uavAltitude;

    if (isInObstacle(startLat, startLon, uavAltitude, obstacles) || isInObstacle(goalLat, goalLon, uavAltitude, obstacles)) {
        qDebug() << "Start or goal is in an obstacle.";
        return QVariantList();
    }

    // Kiểm tra điều kiện: nếu độ cao của UAV lớn hơn tất cả các vật cản.
    bool canFlyStraight = true;
    for (const QVariant &obs : obstacles) {
        QVariantMap obstacle = obs.toMap();
        double obsHeight = obstacle["height"].toDouble();
        if (uavAltitude <= obsHeight) {
            canFlyStraight = false;
            break;
        }
    }

    // Nếu có thể bay thẳng đến đích.
    if (canFlyStraight) {
        qDebug() << "UAV altitude is higher than all obstacles. Flying straight to goal.";
        QVariantList path;
        path.append(QVariant::fromValue(start));
        path.append(QVariant::fromValue(goal));
        mPathLength = start.distanceTo(goal);
        emit pathLengthChanged();
        return path;
    }

    // Nếu không thể bay thẳng sử dụng A star để tìm đường
    std::set<std::pair<double, Node*>> openSet;
    std::unordered_map<std::pair<double, double>, Node*, pair_hash> allNodes;
    std::unordered_set<std::pair<double, double>, pair_hash> closedSet;

    Node* startNode = new Node(start, nullptr, 0.0, calculateHeuristic(start, goal));
    openSet.insert({startNode->fCost, startNode});
    allNodes[{startLat, startLon}] = startNode;

    int maxIterations = 100000;
    int iterations = 0;

    while (!openSet.empty() && iterations < maxIterations) {
        iterations++;

        Node* currentNode = openSet.begin()->second;
        openSet.erase(openSet.begin());

        if (closedSet.find({currentNode->position.latitude(), currentNode->position.longitude()}) != closedSet.end()) {
            continue;
        }

        closedSet.insert({currentNode->position.latitude(), currentNode->position.longitude()});

        if (currentNode->position.distanceTo(goal) <= 1.0) {
            QVariantList path = buildPath(currentNode);
            qDebug() << "Path found!";

            double pathLength = calculatePathLength(path);
            qDebug() << "Path length: " << pathLength;
            mPathLength = pathLength;

            emit pathLengthChanged();

            for (auto& pair : allNodes) {
                delete pair.second;
            }
            return path;
        }

        for (const auto& neighbor : getNeighbors(currentNode->position, goal)) {
            if (isInObstacle(neighbor.latitude(), neighbor.longitude(), uavAltitude, obstacles)) {
                continue;
            }

            std::pair<double, double> neighborKey = {neighbor.latitude(), neighbor.longitude()};

            if (closedSet.find(neighborKey) != closedSet.end()) {
                continue;
            }

            double newGCost = currentNode->gCost + currentNode->position.distanceTo(neighbor);
            Node* neighborNode = nullptr;

            if (allNodes.find(neighborKey) == allNodes.end()) {
                double heuristicWeight = 1.5;
                neighborNode = new Node(neighbor, currentNode, newGCost, heuristicWeight * calculateHeuristic(neighbor, goal));
                allNodes[neighborKey] = neighborNode;
                openSet.insert({neighborNode->fCost, neighborNode});
            } else {
                neighborNode = allNodes[neighborKey];
                if (newGCost < neighborNode->gCost) {
                    openSet.erase({neighborNode->fCost, neighborNode});
                    neighborNode->gCost = newGCost;
                    neighborNode->parent = currentNode;
                    neighborNode->fCost = neighborNode->gCost + neighborNode->hCost;
                    openSet.insert({neighborNode->fCost, neighborNode});
                }
            }
        }
    }

    for (auto& pair : allNodes) {
        delete pair.second;
    }
    qDebug() << "No path found. Exceeded maximum iterations.";
    return QVariantList();
}

// Hàm tính độ dài đường đi.
double AStar::calculatePathLength(const QVariantList &path) {
    double length = 0.0;
    for (int i = 0; i < path.size() - 1; ++i) {
        QGeoCoordinate pointA = path[i].value<QGeoCoordinate>();
        QGeoCoordinate pointB = path[i + 1].value<QGeoCoordinate>();
        length += pointA.distanceTo(pointB);
    }
    return length;
}
