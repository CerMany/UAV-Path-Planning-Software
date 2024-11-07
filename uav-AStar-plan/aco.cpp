#include "aco.h"
#include <cmath>
#include <algorithm>
#include <QGeoCoordinate>
#include <QVariantList>
#include <QVariantMap>
#include <QDebug>

const int gridSize = 500;
const int maxStepsPerAnt = 10000;
int numAnts = 1;
int maxIterations = 1;
double alpha = 1.0;
double beta = 2.0;
double evaporationRate = 0.5;
double pheromoneIntensity = 1.0;
double pheromoneMatrix[gridSize][gridSize];
double distanceThreshold = 1;

ACO::ACO(QObject *parent) : QObject(parent) {
    for (int i = 0; i < gridSize; ++i) {
        for (int j = 0; j < gridSize; ++j) {
            pheromoneMatrix[i][j] = 1.0;
        }
    }
}

QVariantList ACO::findPath(double startLat, double startLon, double goalLat, double goalLon, const QVariantList &obstacles, double uavAltitude) {
    std::vector<Node*> ants;
    Node* startNode = new Node{QGeoCoordinate(startLat, startLon), nullptr};
    Node* goalNode = new Node{QGeoCoordinate(goalLat, goalLon), nullptr};

    qDebug() << "Starting ACO pathfinding...\n";

    QVariantList shortestPath;
    double shortestPathLength = std::numeric_limits<double>::max();

    // Kiểm tra nếu điểm bắt đầu hoặc đích nằm trong vùng vật cản
    if (isInObstacle(startLat, startLon, uavAltitude, obstacles) ||
        isInObstacle(goalLat, goalLon, uavAltitude, obstacles)) {
        return QVariantList(); // Trả về danh sách rỗng nếu không tìm được đường
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

    // Nếu có thể bay thẳng tới đích, tạo đường thẳng, tính độ dài và trả về
     if (canFlyStraight) {
         qDebug() << "UAV altitude allows direct flight to goal.\n";
         QVariantList directPath;
         QVariantMap startPoint;
         startPoint["latitude"] = startLat;
         startPoint["longitude"] = startLon;
         directPath.append(startPoint);

         QVariantMap endPoint;
         endPoint["latitude"] = goalLat;
         endPoint["longitude"] = goalLon;
         directPath.append(endPoint);

         // Tính độ dài của đường bay thẳng
         QGeoCoordinate startCoord(startLat, startLon);
         QGeoCoordinate goalCoord(goalLat, goalLon);
         shortestPathLength = startCoord.distanceTo(goalCoord);
         mShortestPathLength = shortestPathLength;

         // Emit signal để truyền giá trị lên qml
         emit shortestPathLengthChanged();

         qDebug() << "Direct path length: " << shortestPathLength << "\n";
         return directPath;  // Trả về đường thẳng từ điểm bắt đầu đến điểm đích
     }

    for (int iteration = 0; iteration < maxIterations; iteration++) {
        qDebug() << "Iteration: " << iteration + 1 << "\n";
        for (int k = 0; k < numAnts; k++) {
            Node* currentNode = new Node{startNode->position, nullptr};
            ants.push_back(currentNode);

            std::vector<QGeoCoordinate> visitedNodes;
            visitedNodes.push_back(currentNode->position);

            while (currentNode->position.distanceTo(goalNode->position) > distanceThreshold) {
                Node* nextNode = moveAnt(currentNode, startNode, goalNode->position, alpha, beta, pheromoneMatrix, obstacles, visitedNodes, uavAltitude);
                if (nextNode == nullptr) {
                    qDebug() << "Ant " << k + 1 << " hit an obstacle or dead end.\n";
                    break;
                }

                qDebug() << "Ant " << k + 1 << " moved to (" << nextNode->position.latitude() << ", " << nextNode->position.longitude() << ")\n";
                nextNode->parent = currentNode;
                currentNode = nextNode;
                visitedNodes.push_back(currentNode->position);
                qDebug() << "Distance threshold: " << currentNode->position.distanceTo(goalNode->position) << "\n";

                if (currentNode->position.distanceTo(goalNode->position) <= distanceThreshold) {
                    QVariantList path = buildPath(currentNode);
                    double pathLength = calculatePathLength(path);
                    qDebug() << "Path found by ant " << k + 1 << " in iteration " << iteration + 1 << " length: " << pathLength << "\n";
                    mData.append(pathLength);
                    if (pathLength < shortestPathLength) {
                        shortestPath = path;
                        shortestPathLength = pathLength;
                        mShortestPathLength = pathLength;
                        // Emit signal để truyền giá trị lên qml
                        emit shortestPathLengthChanged();
                    }
                    break;
                }

                if (visitedNodes.size() > maxStepsPerAnt) {
                    qDebug() << "Ant " << k + 1 << " exceeded the maximum step limit.\n";
                    break;
                }
            }
        }
        updatePheromoneMatrix(pheromoneMatrix, ants, startNode, evaporationRate, pheromoneIntensity);

        for (Node* node : ants) {
            delete node;
        }
        ants.clear();
    }

    for(int i=0;i<mData.size(); i++)
    {
        qDebug()<< "data [" << i << "] : " << mData[i];
    }


    if (shortestPath.isEmpty()) {
        qDebug() << "Cannot find path after " << maxIterations << " iterations\n";
    }

    return shortestPath;
}

bool ACO::isInObstacle(double lat, double lon, double altitude, const QVariantList &obstacles) {
    for (const QVariant &obs : obstacles) {
        QVariantMap obstacle = obs.toMap();
        QGeoCoordinate center(obstacle["latitude"].toDouble(), obstacle["longitude"].toDouble());
        double radius = obstacle["radius"].toDouble();
        double obsHeight = obstacle["height"].toDouble();  // Lấy độ cao của vật cản
        QGeoCoordinate point(lat, lon);

        // Chỉ xem vật cản nếu UAV bay thấp hơn hoặc bằng độ cao của vật cản
        if (center.distanceTo(point) <= radius && altitude <= obsHeight) {
            qDebug() << "Point (" << lat << ", " << lon << ", " << altitude << ") is in obstacle at ("
                      << center.latitude() << ", " << center.longitude() << ") with radius "
                      << radius << " and height " << obsHeight << "\n";
            return true;
        }

    }
    return false;
}

QVariantList ACO::buildPath(Node* node) {
    QVariantList path;
    while (node) {
        QVariantMap point;
        point["latitude"] = node->position.latitude();
        point["longitude"] = node->position.longitude();
        path.prepend(point);
        node = node->parent;
    }
    return path;
}

double ACO::calculateHeuristic(const QGeoCoordinate &a, const QGeoCoordinate &b) {
    return a.distanceTo(b);
}

ACO::Node* ACO::moveAnt(Node* currentNode, Node* startNode, const QGeoCoordinate &goal, double alpha, double beta, double pheromoneMatrix[gridSize][gridSize], const QVariantList &obstacles, const std::vector<QGeoCoordinate> &visitedNodes, double uavAltitude) {
    std::vector<Node*> candidates;

    for (int i = 0; i < 8; i++) {
        double angle = i * M_PI / 4.0;
        // Tính khoảng cách từ vị trí hiện tại tới đích
        double distanceToGoal = currentNode->position.distanceTo(goal);

        // Điều chỉnh moveDistance dựa trên khoảng cách tới đích
        double moveDistance;
        if (distanceToGoal > 10000) {
            moveDistance = 0.0005; // Bước nhảy lớn hơn cho khoảng cách lớn.
        } else if (distanceToGoal >= 500 && distanceToGoal <= 10000) {
            moveDistance = 0.00005; // Bước nhảy trung bình cho khoảng cách vừa.
        } else {
            moveDistance = 0.00001; // Bước nhảy nhỏ hơn khi gần đích.
        }

        double lat = currentNode->position.latitude() + moveDistance * cos(angle);
        double lon = currentNode->position.longitude() + moveDistance * sin(angle);

        if (!isInObstacle(lat, lon, uavAltitude, obstacles)) {
            QGeoCoordinate newPosition(lat, lon);
            if (std::find(visitedNodes.begin(), visitedNodes.end(), newPosition) == visitedNodes.end()) {
                candidates.push_back(new Node{newPosition, currentNode});
            }
        }
    }

    // Nếu không có điểm hợp lệ trả về nullptr
    if (candidates.empty()) {
        qDebug() << "No valid candidates found.";
        return nullptr;
    }

    Node* bestNode = nullptr;
    double maxDesirability = -1;

    for (Node* node : candidates) {
        int latIndex = static_cast<int>((node->position.latitude() - startNode->position.latitude()) * gridSize);
        int lonIndex = static_cast<int>((node->position.longitude() - startNode->position.longitude()) * gridSize);
        // Đảm bảo rằng chỉ số nằm trong khoảng cho phép
        latIndex = std::max(0, std::min(gridSize - 1, latIndex));
        lonIndex = std::max(0, std::min(gridSize - 1, lonIndex));

        double pheromone = pheromoneMatrix[latIndex][lonIndex];
        double heuristic = calculateHeuristic(node->position, goal);
        double desirability = pow(pheromone, alpha) * pow(1.0 / heuristic, beta);

        qDebug() << "Pheromone: " << pheromone << '\n';
        qDebug() << "Heuristic: " << heuristic << '\n';
        qDebug() << "Desirability: " << desirability << '\n';

        if (desirability > maxDesirability) {
            maxDesirability = desirability;
            bestNode = node;
        }
    }

    for (Node* node : candidates) {
        if (node != bestNode) {
            delete node;
        }
    }
    qDebug() << "Best node: " << bestNode->position.latitude() << ", " << bestNode->position.longitude() << '\n';

    return bestNode;
}

void ACO::updatePheromoneMatrix(double pheromoneMatrix[gridSize][gridSize], const std::vector<Node*> &ants, Node* startNode, double evaporationRate, double pheromoneIntensity) {
    // Bay hơi pheromone trước
    for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
            pheromoneMatrix[i][j] *= (1.0 - evaporationRate);
        }
    }

    // Cập nhật pheromone dựa trên đường đi của từng con kiến
    for (Node* ant : ants) {
        if (ant->parent != nullptr) {
            QVariantList path = buildPath(ant);
            double pathLength = calculatePathLength(path);

            // Duyệt qua đường đi của con kiến và cập nhật pheromone
            Node* currentNode = ant;
            while (currentNode != nullptr && currentNode->parent != nullptr) {
                int latIndex = static_cast<int>((currentNode->position.latitude() - startNode->position.latitude()) * gridSize);
                int lonIndex = static_cast<int>((currentNode->position.longitude() - startNode->position.longitude()) * gridSize);

                // Đảm bảo chỉ số nằm trong khoảng cho phép
                latIndex = std::max(0, std::min(gridSize - 1, latIndex));
                lonIndex = std::max(0, std::min(gridSize - 1, lonIndex));

                // Cập nhật pheromone dựa trên độ dài đường đi
                pheromoneMatrix[latIndex][lonIndex] += pheromoneIntensity / pathLength;

                currentNode = currentNode->parent;
            }
        }
    }
}

double ACO::calculatePathLength(const QVariantList &path) {
    double length = 0;
    for (int i = 0; i < path.size() - 1; ++i) {
        QVariantMap pointA = path[i].toMap();
        QVariantMap pointB = path[i + 1].toMap();

        QGeoCoordinate coordA(pointA.value("latitude").toDouble(), pointA.value("longitude").toDouble());
        QGeoCoordinate coordB(pointB.value("latitude").toDouble(), pointB.value("longitude").toDouble());

        length += coordA.distanceTo(coordB);
    }
    return length;
}


