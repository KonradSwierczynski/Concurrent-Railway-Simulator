package main

/*  author: Konrad Świerczyński
*
 */

import (
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

const EMPTY int32 = -1
const BROKEN int32 = -2
const jobOnStationDuration int = 5

const FAILURESGEN bool = false
const JOBSGEN bool = true

var wg sync.WaitGroup

var (
	running           bool
	printing          bool
	secPerHour        int
	repairTime        int
	numberOfSwitches  int32
	numberOfLines     int32
	numberOfPlatforms int32
	numberOfStations  int
	numberOfTrains    int32
	switches          []Switch
	lines             []Line
	platforms         []Platform
	stations          [][]int
	trains            []Train
	junctions         [][][]int
	repairVehicle     RepairVehicle
	master            JobsMaster
	//wg                  sync.WaitGroup
)

func startSimulation() {
	readData()

	for i, line := range lines {
		if i > 0 {
			go taskLine(line)
		}
	}

	for i, platform := range platforms {
		if i > 0 {
			go taskPlatform(platform)
		}
	}

	for i, s := range switches {
		if i > 0 {
			go taskSwitch(s)
		}
	}

	for i, train := range trains {
		if i > 0 {
			wg.Add(1)
			go startTrain(i)
			fmt.Println(i, train)
		}
	}
	if FAILURESGEN {
		go taskRepairVehicle()
	}
	if JOBSGEN {
		go jobForWorkersGenerator()
	}
	wg.Done()
}

func UI() {
	for running {
		callClear()
		fmt.Println("----MENU----")
		fmt.Println("[1] Pokazuj wszystkie zdarzenia")
		fmt.Println("[2] Pokaż status pociagu nr")
		fmt.Println("[3] Pokaż status wsystkich pociągów")
		if JOBSGEN {
			fmt.Println("[4] Pokaż wszystkie odbywające się prace")
		}
		var option, arg int
		fmt.Scanln(&option)
		if option == 1 {
			showAllLogs()
		} else if option == 2 {
			fmt.Scanln(&arg)
			showLogsFor(arg)
		} else if option == 3 {
			showLogsForTrains()
		} else if option == 4 && JOBSGEN {
			printJobs()
		} else {
			fmt.Println("Press q to quit")
			var e string
			fmt.Scan(&e)
			if e == "q" || e == "Q" {
				//close simulator
				return
			}
		}
	}
}

func main() {
	sigs := make(chan os.Signal, 1)

	wg.Add(1)
	startSimulation()

	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		sig := <-sigs
		fmt.Println(sig)
		fmt.Println("Closing simulator...")
		running = false
	}()

	UI()

	running = false

	for running {
		time.Sleep(1 * time.Second)
	}

	fmt.Println("...")

}
