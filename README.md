# Concurrent Railway Simulator
Project for Parallel Programming classes.

The program simulates the movement of trains on the railway network.
The network consists of tracks, switches, stations with platforms and trains.
Trains run on designated routes and people from the stations.
Elements of network can break down and repair team, which also moves along the tracks, can fix them.
The specification assumes one vehicle on the track at once, so break down can deadlock even all trains.

To run the program you have to run
```
go run *.go
```
and paste one of the sample data set containing informations about trains' routes, stations and switches.

Corresponding program was also written in Ada. To run ada version compile code with
```
gnatmake zadanie
```
run and paste sample data.



