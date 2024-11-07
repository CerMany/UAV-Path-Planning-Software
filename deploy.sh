#!/bin/bash
#Deploy config that can use common

CUR_DIR=`pwd`
BUILD_DIR=$CUR_DIR/build-uav-AStar-plan-Desktop_Qt_5_14_2_MinGW_64_bit-Release/release
TARGET_DIR=$CUR_DIR/deploy

if [[ "$OSTYPE" == "msys" ]]; then
    echo "Using Windows Git Bash/Msys"
    QT_BIN_DIR=/C/Qt/Qt5.14.2/5.14.2/mingw73_64/bin
    LIB_CAN_NOT_HANDLE="libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll"

    #copy executable file
    cp $BUILD_DIR/UAV-Path-Planning.exe $TARGET_DIR
    for lib in $LIB_CAN_NOT_HANDLE; do
        cp $QT_BIN_DIR/$lib $TARGET_DIR
    done
    #using windeployqt.exe to create app
    $QT_BIN_DIR/windeployqt.exe --qmldir $CUR_DIR/uav-AStar-plan $TARGET_DIR/UAV-Path-Planning.exe

    #create installer
    # cd $INSTALLER_DIR
    # $QT_IFW_DIR/binarycreator.exe -c $INSTALLER_DIR/$APP_NAME/config/config.xml -p $INSTALLER_DIR/$APP_NAME/packages $INSTALLER_DIR/$INSTALLER_NAME

    #remove data dir
    # rm -rf $DATA_DIR/*
fi
