package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

func callClear() {
	cmd := exec.Command("clear")
	cmd.Stdout = os.Stdout
	cmd.Run()
}

func showAllLogs() {
	callClear()

	display := true

	go func() {
		var response string
		fmt.Scan(&response)
		display = false
	}()

	printing = true

	for display {
		time.Sleep(1 * time.Second)
	}

	printing = false

	callClear()
}

func printJobs() {
	callClear()

	display := true

	go func() {
		var response string
		fmt.Scan(&response)
		display = false
	}()

	for display {
		for i, job := range master.jobs {
			if !job.finished {
				fmt.Println("Job " + strconv.Itoa(i+1))
				l := len(job.logs) - 3
				if l < 0 {
					l = 0
				}
				logsToPrint := job.logs[l:]
				for _, log := range logsToPrint {
					fmt.Println("> " + log)
				}
				fmt.Println("Groups:")
				for j, group := range job.groups {
					fmt.Println("\t" + strconv.Itoa(j) + " Group from " + strconv.Itoa(group.source) + " (" + strconv.Itoa(group.quantity) + ")")
					fmt.Println("\t\tStatus: " + group.log)
				}
				fmt.Println("")
			}
		}
		time.Sleep(500 * time.Millisecond)
		callClear()
	}
}

func printFailures() {
	//fmt.Println(len(failures), " ", fresh)
	for i := len(failures) - fresh; i < len(failures); i++ {
		m := failures[i]

		switch m.element {
		case SWITCHTYPE: //switch will break
			fmt.Println("Switch ", m.id, " broken")
		case LINETYPE: //line will break
			fmt.Println("Line ", m.id, " broken")
		case TRAINTYPE: //train will break
			fmt.Println("Train ", m.id, " broken")
		}
	}
}

func showLogsFor(trainId int) {
	if trainId >= len(trains) || trainId < 0 {
		return
	}
	callClear()

	i := 0
	display := true

	go func() {
		var response string
		fmt.Scan(&response)
		display = false
	}()

	if trainId == 0 {
		for display {
			i = i%20 + 1
			fmt.Println(strings.Repeat("*", i))
			l := len(repairVehicle.logs) - 10
			if l < 0 {
				l = 0
			}
			logsToPrint := repairVehicle.logs[l:]
			for _, v := range logsToPrint {
				fmt.Println(v)
			}
			printFailures()

			time.Sleep(500 * time.Millisecond)
			callClear()
		}
	} else {

		for display {
			i = i%20 + 1
			fmt.Println(strings.Repeat("*", i))
			train := trains[trainId]
			l := len(train.logs) - 10
			if l < 0 {
				l = 0
			}
			logsToPrint := train.logs[l:]
			for _, v := range logsToPrint {
				fmt.Print("### Train ", v.trainId, " => ")
				if v.typeId == 0 {
					fmt.Print("switch ")
				} else if v.typeId == 1 {
					fmt.Print("line ")
				} else if v.typeId == 2 {
					fmt.Print("platform ")
				}
				fmt.Println(v.value)
			}
			printFailures()

			time.Sleep(500 * time.Millisecond)
			callClear()
		}

	}
}

func showLogsForTrains() {
	callClear()

	display := true

	go func() {
		var response string
		fmt.Scan(&response)
		display = false
	}()
	i := 0
	for display {
		i = i%20 + 1
		fmt.Println(strings.Repeat("*", i))

		for j, train := range trains {
			if j == 0 {
				continue
			}
			if len(train.logs) < 1 {
				fmt.Println("### Train ", j+1)
			} else {
				v := train.logs[len(train.logs)-1]

				fmt.Print("### Train ", v.trainId, " => ")
				if v.typeId == 0 {
					fmt.Print("switch ")
				} else if v.typeId == 1 {
					fmt.Print("line ")
				} else if v.typeId == 2 {
					fmt.Print("platform ")
				}
				fmt.Println(v.value)
			}
		}
		if FAILURESGEN {
			if len(repairVehicle.logs) > 0 {
				fmt.Println(repairVehicle.logs[len(repairVehicle.logs)-1])
			}
			printFailures()
		}
		time.Sleep(500 * time.Millisecond)
		callClear()
	}
}
