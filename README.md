# Flutter Data Editor

This is a WIP sample data editor program written using the [Flutter Framework](https://flutter.dev/).

Presently I am working on an embedded file browser for this app. I intend to make the file browser reasonably well featured, so you can browse the app's files, system files, and make changes to them. Upon running the app, you can navigate to the file browser via the navigation drawer.

The file browser will eventually support an interface for selecting and editing data files stored on the local disk. My goal is to support JSON and SQLite as editable file types.

After that, I intend to create an interface to connect to at least one type of SQL database server to make basic operations on it. 

## Dependencies
Most of the dependencies for the project are provided by packages available on Pub.dev and are listed in the pubspec.yaml.

This project does rely on one custom dependency that I wrote, which I've dubbed 'spark_lib'. This project expects spark_lib to be in its parent directory. You can find my repository for spark_lib on GitHub, [here].

## Copyright
This repository and original code belongs to PhotonRayleigh. Only those who I grant express permission may directly edit this repository. You may, however, make a copy of the code in this repository and use it how you see fit.

Flutter and the other third party libraries/technologies used in this repository are governed by their own respective licenses. Refer to their respective documentation for details.