package main

import (
	"fmt"
	"sync"
)

func readData() {
	var waitingLineSwitch int32
	fmt.Scanln(&secPerHour)
	fmt.Scanln(&repairTime)
	fmt.Scanln(&numberOfSwitches)
	fmt.Scanln(&numberOfLines)
	fmt.Scanln(&numberOfPlatforms)
	fmt.Scanln(&numberOfStations)
	fmt.Scanln(&numberOfTrains)
	fmt.Scanln(&waitingLineSwitch)
	elements := numberOfLines + numberOfPlatforms
	switches = make([]Switch, numberOfSwitches+1)
	lines = make([]Line, numberOfLines+1)
	platforms = make([]Platform, numberOfPlatforms+1)
	stations = make([][]int, numberOfStations+1)
	trains = make([]Train, numberOfTrains+1)
	junctions = make([][][]int, elements+1)
	running = true
	printing = false

	var i int32
	for i = 0; i <= elements; i++ {
		junctions[i] = make([][]int, elements+1)
		var j int32
		for j = 0; j <= elements; j++ {
			junctions[i][j] = make([]int, 0)
		}
	}

	for i = 1; i <= numberOfSwitches; i++ {
		var minUT int
		fmt.Scanln(&minUT)
		switches[i] = Switch{c: make(chan Message), mu: sync.Mutex{}, minUsageTime: minUT, status: EMPTY, edges: make([]int32, 0), id: i, damaged: false}
	}

	fmt.Println("switches")
	fmt.Println(switches)

	lines[0] = Line{c: make(chan Message), mu: sync.Mutex{}, lenght: 0, maxSpeed: 10, status: EMPTY, id: 0, damaged: false}

	switches[waitingLineSwitch].edges = append(switches[waitingLineSwitch].edges, 0)

	for i = 1; i <= numberOfLines; i++ {
		var lenght, maxS int
		var a, b int32
		fmt.Scanln(&a, &b, &lenght, &maxS)
		lines[i] = Line{c: make(chan Message), mu: sync.Mutex{}, lenght: lenght, maxSpeed: maxS, status: EMPTY, id: i, damaged: false}
		switches[a].edges = append(switches[a].edges, i)
		switches[b].edges = append(switches[b].edges, i)
	}

	fmt.Println("lines")

	for i = 1; i <= numberOfPlatforms; i++ {
		var a, b int32
		var minUT, station int
		fmt.Scanln(&a, &b, &minUT, &station)
		platforms[i] = Platform{c: make(chan Message), mu: sync.Mutex{}, minLayTime: minUT, status: EMPTY, id: i + numberOfLines, damaged: false, station: station, workers: 20}

		switches[a].edges = append(switches[a].edges, i+numberOfLines)
		switches[b].edges = append(switches[b].edges, i+numberOfLines)
	}

	fmt.Println("platforms")

	for i = 1; i <= numberOfTrains; i++ {
		var maxS, maxC, k int
		fmt.Scanln(&maxS, &maxC)
		fmt.Scanln(&k)
		trains[i] = Train{id: i, maxSpeed: maxS, maxCapacity: maxC, route: make([]int, k), logs: make([]Log, 0), status: EMPTY, position: 0, damaged: false}
		var j int
		for j = 0; j < k; j++ {
			var x int
			fmt.Scanln(&x)
			trains[i].route[j] = x
			if x > int(numberOfLines) {
				fmt.Println(">> ", numberOfLines, " ", x, " ", x-int(numberOfLines))
				index := x - int(numberOfLines)
				trains[i].stations = append(trains[i].stations, platforms[index].station)
				fmt.Println("A")
				stations[platforms[index].station] = append(stations[platforms[index].station], int(i))
				fmt.Println("B")
			}
		}
		fmt.Println("TRASA POCIAGU ", trains[i].route)

	}
	fmt.Println("trains")

	var maxS int
	fmt.Scanln(&maxS)
	repairVehicle = RepairVehicle{
		messageChan: make(chan RepairMessage),
		maxSpeed:    maxS,
		route:       make([]int, 0),
		logs:        make([]string, 0),
		status:      EMPTY,
		position:    0}

	fmt.Println(switches, lines, platforms, trains)

	for j, s := range switches {
		for k := 0; k < len(s.edges); k++ {
			for l := k + 1; l < len(s.edges); l++ {
				junctions[s.edges[k]][s.edges[l]] = append(junctions[s.edges[k]][s.edges[l]], j)
				junctions[s.edges[l]][s.edges[k]] = append(junctions[s.edges[l]][s.edges[k]], j)
			}
		}
	}

        for index, row := range junctions {
            for index2, elem := range row {
                if index == index2 || len(elem) == 0 {
                    fmt.Print("-1 ")
                } else {
                    fmt.Print(elem[0])
                    fmt.Print(" ")
                }
            }
            fmt.Println("")
        }

	fmt.Println("Zwrotnice")
	fmt.Println(numberOfSwitches)
	fmt.Println(switches)
	fmt.Println("Tory")
	fmt.Println(numberOfLines)
	fmt.Println(lines)
	fmt.Println("Stacje")
	fmt.Println(numberOfPlatforms)
	fmt.Println(platforms)
	fmt.Println("Pociągi")
	fmt.Println(numberOfTrains)
	fmt.Println(trains)

	fmt.Println("Macierz")
	fmt.Println(junctions)

	fmt.Println()
	fmt.Println()

}
